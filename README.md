# Model Monitoring Platform (OTEL → Metrics → Alerts)

A cloud-native, OpenTelemetry-driven AI observability and model
monitoring platform for **Generative**, **Predictive**, and **Agentic AI
systems**.

This repository implements an end-to-end monitoring pipeline:

-   Ingests OpenTelemetry traces/logs/metrics
-   Normalizes them into a canonical schema
-   Computes model-specific metrics
-   Persists results to BigQuery
-   Exposes metrics for alerting via Prometheus / Cloud Monitoring

------------------------------------------------------------------------

## 📐 High-Level Architecture

    ┌───────────────┐
    │  OTEL SDKs    │
    │ (Apps/Models) │
    └───────┬───────┘
            │
            ▼
    ┌──────────────────────────┐
    │ Ingestion Service (API)  │
    │ FastAPI + OTEL JSON      │
    │                          │
    │ → CanonicalEvent         │
    │ → BigQuery               │
    └──────────┬───────────────┘
               │
               ▼
    ┌──────────────────────────────────────────┐
    │ Canonical Storage (BigQuery)              │
    │ mca_ingestion.canonical_events            │
    └──────────┬───────────────┬───────────────┘
               │               │
               ▼               ▼
    ┌─────────────────┐   ┌───────────────────┐  ┌───────────────────┐  
    │ Generative      │   │ Predictive        │  │ Agentic           │
    │ Metrics Service │   │ Metrics Service   │  │ Metrics Service   │
    │ (Langfuse +     │   │ (Evidently)       │  │ (Langfuse +       │
    │  Vertex AI)     │   │                   │  │  Vertex AI)       │
    └─────────┬───────┘   └─────────┬─────────┘  └─────────┬─────────┘
              │                     │                      │
              ▼                     ▼                      ▼
    ┌────────────────────────────────────────────────────────────────────────┐
    │ Metrics Storage (BigQuery)                                             │
    │ mca_metrics.*                                                          │
    └──────────┬───────────────┬─────────────────────────────────────────────┘
               │
               ▼
    ┌──────────────────────────┐
    │ Alerts Service           │
    │ Prometheus / Cloud Mon   │
    │ Email / Teams            │
    └──────────────────────────┘

------------------------------------------------------------------------

## 🗂 Repository Structure

    repo/
    ├── shared/                         # Shared libraries (internal package)
    │   ├── schemas/                    # Canonical + metrics schemas
    │   │   ├── canonical_event.py
    │   │   ├── model_types.py
    │   ├── bigquery/                   # Shared BQ readers/writers
    │   │   ├── readers.py
    │   │   └── writers.py
    │   └── utils/
    │       ├── time.py
    │       └── ids.py
    │
    ├── ingestion_service/              # OTEL → Canonical API
    │   ├── app/
    │   │   ├── main.py
    │   │   ├── api.py
    │   │   ├── normalizer.py
    │   │   └── bq_writer.py
    │   ├── Dockerfile
    │   └── requirements.txt
    │
    ├── metrics_generative_service/     # GenAI metrics (Langfuse + Vertex)
    │   ├── app/
    │   │   ├── main.py
    │   │   ├── metrics_runner.py
    │   │   ├── evaluators.py
    │   │   ├── gcs_client.py
    │   │   ├── langfuse_client.py
    │   │   └── bq_writer.py
    │   ├── Dockerfile
    │   └── requirements.txt
    │
    ├── metrics_predictive_service/     # Predictive metrics (Evidently)
    │   ├── app/
    │   │   ├── main.py
    │   │   ├── metrics_runner.py
    │   │   ├── evidently_runner.py
    │   │   └── bq_writer.py
    │   ├── Dockerfile
    │   └── requirements.txt
    │
    ├── metrics_agentic_service/        # Agentic AI metrics (Langfuse + Vertex)
    │   ├── app/
    │   │   ├── main.py
    │   │   ├── metrics_runner.py
    │   │   ├── evaluators.py
    │   │   └── langfuse_client.py
    │   ├── Dockerfile
    │   └── requirements.txt
    │
    ├── alerts_service/                 # Alerting / exporters
    │   ├── app/
    │   │   ├── poller.py
    │   │   └── exporters.py
    │   ├── Dockerfile
    │   └── requirements.txt
    │
    └── cloudbuild.yaml                 # CI/CD (Cloud Build + Cloud Run)

------------------------------------------------------------------------

## 🔁 Data Flow Overview

### 1️⃣ Ingestion Layer (MANDATORY)

**Purpose**\
Single source of truth for all OTEL data.

**Input**\
OTEL traces, logs, and metrics (JSON export)

**Output Table**

    mca_ingestion.canonical_events

**Key Characteristics**

-   Unified schema for all model types
-   No metrics computed here
-   Feeds all downstream services

------------------------------------------------------------------------

### 2️⃣ Metrics Layers (MANDATORY)

Each metrics service:

-   Reads from `canonical_events`
-   Computes metrics per model type
-   Writes results to BigQuery

#### Generative Metrics

    mca_metrics.generative_metrics

Metrics include:

-   Hallucination
-   Safety
-   PII leakage
-   RAG precision / recall / freshness
-   Token throughput
-   Langfuse traces + scores

#### Predictive Metrics

    mca_metrics.predictive_metrics

Metrics include:

-   RMSE, MAE, accuracy, precision, recall
-   Drift & data quality (Evidently)
-   Predictions from OTEL
-   Actuals from GCS (linked by `model_id`)

#### Agentic Metrics

    mca_metrics.agentic_metrics

Metrics include:

-   Goal completion time
-   Tool execution latency
-   Goal success rate
-   Error recovery rate
-   Human-in-the-loop rate
-   Unauthorized action attempts

------------------------------------------------------------------------

### 3️⃣ Alerts Layer (READ-ONLY)

Reads from:

-   `mca_metrics.generative_metrics`
-   `mca_metrics.predictive_metrics`
-   `mca_metrics.agentic_metrics`

Exports:

-   Prometheus endpoints\
    **or**
-   Cloud Monitoring custom metrics

Triggers:

-   Microsoft Outlook Email
-   Microsoft Teams

🚫 Does **not write to BigQuery**

------------------------------------------------------------------------

## 🗄 Required BigQuery Tables

⚠️ BigQuery tables must exist **before services run**

### Datasets

    mca_ingestion
    mca_metrics

### Tables

    mca_ingestion.canonical_events
    mca_metrics.generative_metrics
    mca_metrics.predictive_metrics
    mca_metrics.agentic_metrics

------------------------------------------------------------------------

## ☁️ GCP Services Required

-   Cloud Run (Services + Jobs)
-   Cloud Build
-   Artifact Registry
-   BigQuery
-   Cloud Storage (RAG + Actuals)
-   Cloud Logging
-   Cloud Monitoring
-   Vertex AI (LLM judge)
-   Langfuse (external)

------------------------------------------------------------------------

## 🚀 Deployment

All services are built and deployed via **Cloud Build**:

    gcloud builds submit --config cloudbuild.yaml

Deployment strategy:

-   **Ingestion → Cloud Run Service**
-   **Metrics → Cloud Run Jobs**
-   **Alerts → Cloud Run Job or Service**

------------------------------------------------------------------------

## 🔐 Environment Variables

### Common

    GCP_PROJECT_ID

### Ingestion

    BQ_CANONICAL_DATASET=mca_ingestion

### Generative / Agentic

    GENAI_RAG_BUCKET
    LANGFUSE_PUBLIC_KEY
    LANGFUSE_SECRET_KEY
    LANGFUSE_HOST

------------------------------------------------------------------------

## 🧪 Development & Testing

Services can be run locally with:

    docker build .
    docker run -e GCP_PROJECT_ID=...

Additional notes:

-   OTEL payloads can be mocked as JSON
-   Metrics jobs are idempotent
-   Fail-open philosophy (metrics must not crash pipelines)

------------------------------------------------------------------------

## 🧭 Design Principles

-   Canonical first (single source of truth)
-   Model-type isolation
-   Fail-open metrics
-   Schema-driven
-   Cloud-native
-   Auditable
