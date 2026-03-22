FROM python:3.11-slim

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV PYTHONPATH="/app"

WORKDIR /app

COPY metrics_predictive_service/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY shared /app/shared
COPY metrics_predictive_service /app/metrics_predictive_service

CMD ["python", "-m", "metrics_predictive_service.app.main"]
