FROM python:3.11-slim

ENV PYTHONUNBUFFERED=1
ENV PYTHONPATH="/app"

WORKDIR /app

COPY metrics_agentic_service/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY shared /app/shared
COPY metrics_agentic_service /app/metrics_agentic_service

CMD ["python", "-m", "metrics_agentic_service.app.main"]