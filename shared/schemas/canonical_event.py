from typing import Dict, Any, Optional
from datetime import datetime
from uuid import UUID, uuid4
from pydantic import BaseModel, Field
from .model_types import ModelType, OtelSignal, SourceSystem


class CanonicalEvent(BaseModel):
    event_id: UUID = Field(default_factory=uuid4)

    otel_signal: OtelSignal
    source_system: SourceSystem

    model_type: ModelType
    model_id: str
    model_version: Optional[str]

    trace_id: Optional[str]
    span_id: Optional[str]
    request_id: Optional[str]
    prediction_id: Optional[str]

    event_time: datetime
    ingestion_time: datetime = Field(default_factory=datetime.utcnow)

    attributes: Dict[str, Any] = Field(default_factory=dict)
    metrics: Optional[Dict[str, float]] = None
    logs: Optional[Dict[str, Any]] = None
