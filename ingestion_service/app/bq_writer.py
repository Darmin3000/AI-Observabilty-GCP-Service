import os
from google.cloud import bigquery
from shared.schemas.canonical_event import CanonicalEvent


class CanonicalBQWriter:
    """
    Writes normalized CanonicalEvent rows into BigQuery.

    Table: <PROJECT>.mca_ingestion.canonical_events
    """

    def __init__(self):
        project_id = os.environ["GCP_PROJECT_ID"]
        dataset_id = os.environ.get("BQ_CANONICAL_DATASET", "mca_ingestion")
        table_id = os.environ.get("BQ_CANONICAL_TABLE", "canonical_events")

        self.client = bigquery.Client(project=project_id)
        self.table = f"{project_id}.{dataset_id}.{table_id}"

    def write(self, events: list[CanonicalEvent]) -> None:
        if not events:
            return

        rows = [event.model_dump(mode="json") for event in events]

        errors = self.client.insert_rows_json(self.table, rows)

        if errors:
            raise RuntimeError(f"BigQuery insert errors: {errors}")
