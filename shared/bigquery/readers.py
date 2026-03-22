from google.cloud import bigquery
from typing import List, Type, TypeVar, Optional, Any
from pydantic import BaseModel

T = TypeVar("T", bound=BaseModel)

class BigQueryReader:
    def __init__(self, *, project_id: str):
        self.client = bigquery.Client(project=project_id)

    def query_to_models(
        self, 
        query: str, 
        model_class: Type[T], 
        job_config: Optional[bigquery.QueryJobConfig] = None
    ) -> List[T]:
        """Executes a query and returns a list of Pydantic models."""
        query_job = self.client.query(query, job_config=job_config)
        results = query_job.result()
        
        # We convert row objects (which behave like dicts) into our Pydantic model
        return [model_class.model_validate(dict(row)) for row in results]

    def get_metrics_by_prediction_id(
        self, 
        table_path: str, 
        prediction_id: str, 
        model_class: Type[T]
    ) -> List[T]:
        """Helper for a common pattern: fetching metrics for a specific run."""
        query = f"SELECT * FROM `{table_path}` WHERE prediction_id = @prediction_id"
        job_config = bigquery.QueryJobConfig(
            query_parameters=[
                bigquery.ScalarQueryParameter("prediction_id", "STRING", prediction_id)
            ]
        )
        return self.query_to_models(query, model_class, job_config)