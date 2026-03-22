from google.cloud import bigquery
from typing import List
from pydantic import BaseModel


class BigQueryWriter:
    def __init__(self, *, project_id: str, dataset: str, table: str):
        self.client = bigquery.Client(project=project_id)
        self.table = f"{project_id}.{dataset}.{table}"

    def write_models(self, rows: List[BaseModel]):
        payload = [row.model_dump() for row in rows]
        errors = self.client.insert_rows_json(self.table, payload)
        if errors:
            raise RuntimeError(f"BigQuery insert failed: {errors}")