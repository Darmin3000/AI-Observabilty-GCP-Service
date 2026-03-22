from typing import Optional
from datetime import datetime
from pydantic import BaseModel
from shared.schemas.metrics_base import MetricsBase
from shared.schemas.model_types import ModelType


class PredictiveMetricsResult(MetricsBase):
    """
    Final metrics written to BigQuery.
    """
    model_type: ModelType = "predictive"

    rmse: Optional[float] = None
    mae: Optional[float] = None
    accuracy: Optional[float] = None
    precision: Optional[float] = None
    recall: Optional[float] = None
