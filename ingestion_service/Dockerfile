FROM python:3.11-slim

# 1. System setup
WORKDIR /app
ENV PYTHONUNBUFFERED=1
ENV PYTHONPATH=/app

# 2. INSTALL DEPENDENCIES FIRST (Crucial for caching)
# We copy only the requirement file to keep the build light
COPY ingestion_service/requirements.txt /app/ingestion_service/requirements.txt
RUN pip install --no-cache-dir -r /app/ingestion_service/requirements.txt

# 3. COPY SHARED + SERVICE CODE (After pip install)
COPY shared /app/shared
COPY ingestion_service /app/ingestion_service

# 4. Cloud Run entrypoint
# This matches your Repo/ingestion_service/app/main.py structure
CMD ["uvicorn", "ingestion_service.app.main:app", "--host", "0.0.0.0", "--port", "8080"]
