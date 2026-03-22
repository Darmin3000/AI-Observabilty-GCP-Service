from google.cloud import storage
from datetime import datetime
from typing import Tuple

class GCSAgentPolicyClient:
    def __init__(self, *, project_id: str, bucket_name: str):
        self.client = storage.Client(project=project_id)
        self.bucket = self.client.bucket(bucket_name)

    def get_policy(self, model_id: str) -> Tuple[str, datetime | None]:
        blob = self.bucket.blob(f"agentic/{model_id}/policy.txt")
        if not blob.exists():
            return "", None
        return blob.download_as_text(), blob.updated