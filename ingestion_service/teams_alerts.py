import base64
import json
import logging
import os
import requests
from datetime import datetime, timezone

import functions_framework
from google.cloud import bigquery
from sqlalchemy import create_engine, text

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def write_to_bigquery(alert_data: dict):
    client = bigquery.Client()
    table_id = os.getenv("BQ_ALERTS_TABLE")
    row_to_insert = [{
        "event_timestamp": datetime.now(timezone.utc).isoformat(),
        "model_id": alert_data.get("model_id"),
        "metric": alert_data.get("metric"),
        "value": float(alert_data.get("value", 0)),
        "severity": alert_data.get("severity"),
        "channel": "teams"
    }]
    client.insert_rows_json(table_id, row_to_insert)

@functions_framework.cloud_event
def handle_teams_alert(cloud_event):
    try:
        data = base64.b64decode(cloud_event.data["message"]["data"]).decode()
        payload = json.loads(data)
        
        write_to_bigquery(payload)

        # SQL Lookup for Webhook
        db_url = f"postgresql+pg8000://{os.getenv('DB_USER')}:{os.getenv('DB_PASS')}@{os.getenv('DB_HOST')}/{os.getenv('DB_NAME')}"
        engine = create_engine(db_url)
        with engine.connect() as conn:
            webhook_url = conn.execute(text("SELECT teams_webhook_url FROM model_notifications WHERE model_id = :m"), {"m": payload.get("model_id")}).fetchone()
        
        if not webhook_url: return

        # Adaptive Card (Updated to include Model Name)
        card = {
            "type": "message",
            "attachments": [{
                "contentType": "application/vnd.microsoft.card.adaptive",
                "content": {
                    "type": "AdaptiveCard", "version": "1.4",
                    "body": [
                        {"type": "TextBlock", "text": f"🚨 Alert: {payload.get('metric')}", "weight": "Bolder", "size": "Large"},
                        {"type": "TextBlock", "text": f"**Model:** {payload.get('model_id', 'Unknown')}", "wrap": True}
                    ]
                }
            }]
        }

        requests.post(webhook_url[0], json=card, timeout=10).raise_for_status()
        logger.info("Teams message posted. Status: 200")
    except Exception as e:
        logger.error(f"Teams failure: {e}")
