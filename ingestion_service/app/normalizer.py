from datetime import datetime
from shared.schemas.canonical_event import CanonicalEvent


def normalize_event(
    raw: dict,
    *,
    otel_signal: str,
    source_system: str,
) -> CanonicalEvent:
    """
    OTEL → Canonical normalization.
    ONE place. ONE format.
    """

    return CanonicalEvent(
        otel_signal=otel_signal,
        source_system=source_system,
        model_type=raw["model_type"],
        model_id=raw["model_id"],
        model_version=raw.get("model_version"),
        trace_id=raw.get("trace_id"),
        span_id=raw.get("span_id"),
        request_id=raw.get("request_id"),
        prediction_id=raw.get("prediction_id"),
        event_time=datetime.fromisoformat(raw["event_time"]),
        attributes=raw.get("attributes", {}),
        metrics=raw.get("metrics"),
        logs=raw.get("logs"),
    )