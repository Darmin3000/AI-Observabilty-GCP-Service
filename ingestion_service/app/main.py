from fastapi import FastAPI
from ingestion_service.app.api import router

app = FastAPI(
    title="Model Monitoring Ingestion Service",
    version="1.0.0",
)

app.include_router(router)


@app.get("/health")
def health():
    return {"status": "ok"}