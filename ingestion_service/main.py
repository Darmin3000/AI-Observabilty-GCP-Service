import base64
import json
import logging
import os
import smtplib
from datetime import datetime, timezone
from typing import Dict, Any, List
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText

import functions_framework
import requests
from google.cloud import secretmanager

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


# ==========================================================
# Secret Manager
# ==========================================================
def get_secret(secret_id: str, project_id: str) -> str:
    client = secretmanager.SecretManagerServiceClient()
    name = f"projects/{project_id}/secrets/{secret_id}/versions/latest"
    response = client.access_secret_version(request={"name": name})
    return response.payload.data.decode("UTF-8")


# ==========================================================
# Payload Normalization
# ==========================================================
def normalize_payload(raw_payload: Dict[str, Any]) -> Dict[str, Any]:
    version = str(raw_payload.get("version", ""))

    if version == "4":
        return raw_payload

    if version == "1.2":
        incident = raw_payload.get("incident", {})

        if incident.get("state") != "open":
            return {"version": "4", "alerts": []}

        user_labels = incident.get("policy_user_labels", {})
        resource_labels = incident.get("resource", {}).get("labels", {})
        metric_labels = incident.get("metric", {}).get("labels", {})
        
        alertname = user_labels.get("alertname") or incident.get(
            "condition_name", incident.get("policy_name", "UnknownAlert")
        )

        severity = user_labels.get("severity", "warning")
        category = user_labels.get("category", "platform")

        # FIX: Extract model name from various possible label locations
        model_name = (
            user_labels.get("model_id") or 
            metric_labels.get("model_id") or 
            resource_labels.get("task_id") or 
            "Unknown Model"
        )

        annotations = {}
        if incident.get("summary"):
            annotations["summary"] = incident["summary"]

        doc = incident.get("documentation", {})
        if doc.get("content"):
            annotations["description"] = doc["content"]

        for link in doc.get("links", []):
            if link.get("url"):
                annotations["runbook_url"] = link["url"]
                break

        if incident.get("url"):
            annotations["dashboard_url"] = incident["url"]

        starts_at = ""
        if incident.get("started_at"):
            starts_at = datetime.fromtimestamp(
                incident["started_at"], tz=timezone.utc
            ).isoformat()

        alert = {
            "status": "firing",
            "labels": {
                "alertname": alertname,
                "severity": severity,
                "category": category,
                "model_name": model_name,  # FIX: Save model name into normalized labels
            },
            "annotations": annotations,
            "startsAt": starts_at,
        }

        return {
            "version": "4",
            "status": "firing",
            "groupLabels": {"alertname": alertname},
            "commonLabels": alert["labels"],
            "commonAnnotations": annotations,
            "alerts": [alert],
        }

    return raw_payload


# ==========================================================
# TEAMS – Adaptive Card
# ==========================================================
def format_teams_card(alerts: List[Dict[str, Any]]) -> Dict[str, Any]:
    first = alerts[0]
    labels = first.get("labels", {})
    annotations = first.get("annotations", {})

    severity = labels.get("severity", "unknown")
    alert_name = labels.get("alertname", "Unknown Alert")
    model_name = labels.get("model_name", "Unknown Model")  # FIX: Retrieve model name

    sev_color = {
        "critical": "attention",
        "warning": "warning",
        "info": "accent",
    }.get(severity.lower(), "default")

    facts = [
        {"title": "Model", "value": model_name},  # FIX: Add Model to the FactSet
        {"title": "Severity", "value": severity.upper()},
        {"title": "Alert Count", "value": str(len(alerts))},
    ]

    if labels.get("category"):
        facts.append({"title": "Category", "value": labels["category"]})

    body = [
        {
            "type": "TextBlock",
            "text": alert_name,
            "size": "Large",
            "weight": "Bolder",
            "color": sev_color,
        },
        # FIX: The unappealing summary block has been entirely removed from here.
        {"type": "FactSet", "facts": facts},
    ]

    if annotations.get("description"):
        body.append({
            "type": "TextBlock",
            "text": annotations["description"],
            "wrap": True,
            "spacing": "Medium"
        })

    actions = []
    if annotations.get("runbook_url"):
        actions.append({
            "type": "Action.OpenUrl",
            "title": "View Runbook",
            "url": annotations["runbook_url"],
        })

    if annotations.get("dashboard_url"):
        actions.append({
            "type": "Action.OpenUrl",
            "title": "View Dashboard",
            "url": annotations["dashboard_url"],
        })

    adaptive_card = {
        "$schema": "http://adaptivecards.io/schemas/adaptive-card.json",
        "type": "AdaptiveCard",
        "version": "1.4",
        "body": body,
    }

    if actions:
        adaptive_card["actions"] = actions

    return {
        "type": "message",
        "attachments": [
            {
                "contentType": "application/vnd.microsoft.card.adaptive",
                "content": adaptive_card,
            }
        ],
    }


def send_teams(webhook_url: str, card: Dict[str, Any]):
    response = requests.post(webhook_url, json=card, timeout=10)
    response.raise_for_status()
    logger.info("Teams alert sent")


# ==========================================================
# SMTP EMAIL
# ==========================================================
def get_recipients(severity: str) -> List[str]:
    recipients = ["mlops-team@bhsf.com"]

    if severity.lower() == "critical":
        recipients.append("mlops-oncall@bhsf.com")

    return list(set(recipients))


def format_email_html(alerts: List[Dict[str, Any]]) -> str:
    first = alerts[0]
    labels = first.get("labels", {})
    annotations = first.get("annotations", {})
    model_name = labels.get("model_name", "Unknown Model")

    # FIX: Added the Model name to the email and removed the messy summary
    return f"""
    <h2>🚨 {labels.get('alertname')}</h2>
    <p><strong>Model:</strong> {model_name}</p>
    <p><strong>Severity:</strong> {labels.get('severity')}</p>
    <p>{annotations.get('description','')}</p>
    """


def send_email_smtp(
    smtp_host: str,
    smtp_port: int,
    smtp_user: str,
    smtp_pass: str,
    alerts: List[Dict[str, Any]]
):
    first = alerts[0]
    severity = first.get("labels", {}).get("severity", "warning")
    alert_name = first.get("labels", {}).get("alertname", "Alert")

    recipients = get_recipients(severity)
    subject = f"[{severity.upper()}] {alert_name}"

    msg = MIMEMultipart("alternative")
    msg["Subject"] = subject
    msg["From"] = smtp_user
    msg["To"] = ", ".join(recipients)

    html = format_email_html(alerts)
    msg.attach(MIMEText(html, "html"))

    with smtplib.SMTP(smtp_host, smtp_port) as server:
        server.starttls()
        server.login(smtp_user, smtp_pass)
        server.sendmail(smtp_user, recipients, msg.as_string())

    logger.info("SMTP email sent")


# ==========================================================
# ENTRY POINT
# ==========================================================
@functions_framework.cloud_event
def handle_alert(cloud_event):

    project_id = os.environ.get("GCP_PROJECT")
    if not project_id:
        raise RuntimeError("Missing GCP_PROJECT")

    message_data = base64.b64decode(
        cloud_event.data["message"]["data"]
    ).decode()

    raw_payload = json.loads(message_data)
    payload = normalize_payload(raw_payload)

    firing_alerts = [
        a for a in payload.get("alerts", [])
        if a.get("status") == "firing"
    ]

    if not firing_alerts:
        logger.info("No firing alerts")
        return

    # Secrets
    teams_webhook = get_secret("emms-teams-webhook-url", project_id)
    smtp_user = get_secret("smtp-username", project_id)
    smtp_pass = get_secret("smtp-password", project_id)

    smtp_host = os.environ.get("SMTP_HOST", "smtp.office365.com")
    smtp_port = int(os.environ.get("SMTP_PORT", "587"))

    # Send Teams
    card = format_teams_card(firing_alerts)
    send_teams(teams_webhook, card)

    # Send Email via SMTP
    send_email_smtp(
        smtp_host,
        smtp_port,
        smtp_user,
        smtp_pass,
        firing_alerts
    )

    logger.info("All notifications sent successfully")
