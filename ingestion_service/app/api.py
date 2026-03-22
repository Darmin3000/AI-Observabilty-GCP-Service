from fastapi import APIRouter, HTTPException
from ingestion_service.app.normalizer import normalize_event
from ingestion_service.app.bq_writer import CanonicalBQWriter

router = APIRouter(prefix="/ingest/otel", tags=["ingestion"])


@router.post("")
def ingest_otel(payload: dict):
    """
    Receives OTEL-exported JSON and normalizes it into CanonicalEvent rows.

    Expected payload shape:
    {
        "events": [ { ... }, { ... } ]
    }
    """

    if "events" not in payload or not isinstance(payload["events"], list):
        raise HTTPException(
            status_code=400,
            detail="Payload must contain an 'events' array",
        )

    canonical_events = []

    for raw_event in payload["events"]:
        try:
            canonical = normalize_event(raw_event)
            canonical_events.append(canonical)
        except Exception as exc:
            raise HTTPException(
                status_code=400,
                detail=f"Failed to normalize event: {exc}",
            )

    writer = CanonicalBQWriter()  # ✅ SAFE: instantiated per request
    writer.write(canonical_events)

    return {
        "ingested": len(canonical_events),
        "status": "success",
    }
