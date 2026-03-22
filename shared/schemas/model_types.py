from typing import Literal

ModelType = Literal["generative", "predictive", "agentic"]
PredictionType = Literal["classification", "regression"]
OtelSignal = Literal["traces", "logs", "metrics"]
SourceSystem = Literal["cloud_trace", "cloud_logging", "cloud_monitoring"]