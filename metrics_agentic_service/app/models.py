from typing import Optional
from datetime import datetime
from pydantic import BaseModel
from shared.schemas.metrics_base import MetricsBase
from shared.schemas.model_types import ModelType


class AgenticMetricsResult(MetricsBase):
    model_type: ModelType = "agentic"

    model_id: str
    agent_id: Optional[str]
    goal_id: str

    event_time: datetime

    goal_completion_time_seconds: Optional[float]
    avg_tool_latency_seconds: Optional[float]

    goal_success_rate: float
    error_recovery_rate: float
    human_intervention_rate: float
    unauthorized_action_attempts: int