import os
from langfuse import Langfuse

class LangfuseClient:
    def __init__(self):
        self._client = None

    def _get(self):
        if self._client:
            return self._client
        try:
            self._client = Langfuse(
                public_key=os.environ["LANGFUSE_PUBLIC_KEY"],
                secret_key=os.environ["LANGFUSE_SECRET_KEY"],
                host=os.environ.get("LANGFUSE_HOST"),
            )
        except KeyError:
            self._client = None
        return self._client

    def create_trace(self, **kwargs):
        c = self._get()
        return c.trace(**kwargs) if c else None

    def score(self, trace_id: str, name: str, value: float):
        c = self._get()
        if c:
            c.score(trace_id=trace_id, name=name, value=value)