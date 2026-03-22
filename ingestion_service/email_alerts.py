import base64
import json
import logging
import os
import smtplib
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from datetime import datetime, timezone

import functions_framework
from google.cloud import bigquery
from sqlalchemy import create_engine, text

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def write_to_bigquery(alert_data: dict):
    """Logs the alert event to BigQuery for auditing."""
    client = bigquery.Client()
    table_id = os.getenv("BQ_ALERTS_TABLE") # e.g. "project.dataset.alerts_history"
    
    row_to_insert = [{
        "event_timestamp": datetime.now(timezone.utc).isoformat(),
        "model_id": alert_data.get("model_id"),
        "metric": alert_data.get("metric"),
        "value": float(alert_data.get("value", 0)),
        "severity": alert_data.get("severity"),
        "channel": "email"
    }]
    
    errors = client.insert_rows_json(table_id, row_to_insert)
    if errors:
        logger.error(f"BigQuery Insert Error: {errors}")
    else:
        logger.info("Alert logged to BigQuery.")

def get_recipient_info(model_id: str):
    db_url = f"postgresql+pg8000://{os.getenv('DB_USER')}:{os.getenv('DB_PASS')}@{os.getenv('DB_HOST')}/{os.getenv('DB_NAME')}"
    engine = create_engine(db_url)
    with engine.connect() as conn:
        query = text("SELECT recipient_email FROM model_notifications WHERE model_id = :model_id")
        result = conn.execute(query, {"model_id": model_id}).fetchone()
        return result[0] if result else None

@functions_framework.cloud_event
def handle_email_alert(cloud_event):
    try:
        # Decode Pub/Sub message
        data = base64.b64decode(cloud_event.data["message"]["data"]).decode()
        payload = json.loads(data)
        
        # 1. Audit to BigQuery
        write_to_bigquery(payload)

        # 2. Fetch Routing
        recipient = get_recipient_info(payload.get("model_id"))
        if not recipient:
            logger.warning(f"No recipient for {payload.get('model_id')}")
            return

        # 3. Send Email (Updated to include model name prominently)
        model_name = payload.get('model_id', 'Unknown')
        msg = MIMEMultipart('alternative')
        msg['Subject'] = f"[{payload.get('severity').upper()}] Alert: {payload.get('metric')} on {model_name}"
        msg['From'] = os.getenv("OUTLOOK_SENDER_EMAIL")
        msg['To'] = recipient
        
        body = f"Model: {model_name}\nMetric Triggered: {payload.get('metric')}\nValue: {payload.get('value')}"
        msg.attach(MIMEText(body, 'plain'))

        with smtplib.SMTP("smtp.office365.com", 587) as server:
            server.starttls()
            server.login(os.getenv("OUTLOOK_SENDER_EMAIL"), os.getenv("OUTLOOK_APP_PASSWORD"))
            server.sendmail(msg['From'], [recipient], msg.as_string())
            
        logger.info(f"Email sent to {recipient}. Status: 200")
    except Exception as e:
        logger.error(f"Email failure: {e}")
