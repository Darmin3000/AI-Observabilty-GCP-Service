# AI Observability Pipeline & ETL Transformation

A production-grade, cloud-native observability and model monitoring platform for **Generative AI**, **Predictive ML**, and **Agentic AI** systems. This repository implements an end-to-end pipeline that ingests OpenTelemetry traces and metrics, normalizes them into canonical schemas, computes model-specific performance metrics, and exposes observability data via BigQuery and Prometheus for alerting and compliance.

---

## 📋 Quick Overview

**What this does:**
- Ingests OpenTelemetry traces, logs, and metrics from AI applications
- Normalizes heterogeneous telemetry into a canonical schema stored in BigQuery
- Computes domain-specific metrics (hallucination, drift, safety, RAG precision, agentic goal completion)
- Exports metrics to Prometheus / Cloud Monitoring for real-time alerting
- Routes alerts via Microsoft Teams and Email (SMTP)
- Provides structured analytics for compliance, governance, and engineering teams

**Key Technologies:**
- **Languages:** Python (49%), SQL/PLpgSQL (17%), PowerShell (17%), Jupyter (15%)
- **Runtime:** FastAPI, Google Cloud Run, Cloud Build
- **Data:** BigQuery, Cloud Storage, Cloud SQL
- **AI/ML:** Langfuse, Vertex AI (LLM Judge), Google Cloud DLP, Evidently

---

## 🏗 Repository Structure

```
repo/
├── ingestion_service/               # OTEL → Canonical API (FastAPI on Cloud Run)
│   ├── app/
│   ├── main.py                      # Alert handler (Pub/Sub → Teams/Email)
│   ├── email_alerts.py              # SMTP email delivery
│   ├── teams_alerts.py              # Microsoft Teams webhook integration
│   ├── Dockerfile
│   └── requirements.txt
│
├── metrics_generative_service/      # GenAI metrics (Langfuse + Vertex AI)
│   ├── app/
│   │   ├── metrics_runner.py        # Langfuse trace fetcher + evaluator
│   │   ├── evaluators.py            # Hallucination, safety, PII detection
│   │   ├── gcs_client.py            # GCS integration
│   │   └── langfuse_client.py       # Langfuse API client
│   ├── Dockerfile
│   └── requirements.txt
│
├── metrics_predictive_service/      # Predictive metrics (Evidently)
│   ├── app/
│   │   ├── metrics_runner.py        # Evidently drift/quality checks
│   │   └── bq_writer.py             # BigQuery writer
│   ├── Dockerfile
│   └── requirements.txt
│
├── metrics_agentic_service/         # Agentic AI metrics (Langfuse + Vertex)
│   ├── app/
│   │   ├── metrics_runner.py        # Agent trace processor
│   │   ├── evaluators.py            # Goal completion, tool latency
│   │   └── langfuse_client.py
│   ├── Dockerfile
│   └── requirements.txt
│
├── alerts_service/                  # Alert poller & exporters
│   ├── app/
│   │   ├── poller.py                # Reads metrics from BigQuery
│   │   └── exporters.py             # Prometheus + Cloud Monitoring exporter
│   ├── Dockerfile
│   └── requirements.txt
│
├── shared/                          # Internal Python package
│   ├── schemas/                     # Canonical + metrics schemas
│   ├── bigquery/                    # Shared BQ readers/writers
│   ├── llm/                         # LLM evaluator utilities
│   ├── ml/                          # Predictive ML utilities
│   └── utils/                       # Time, IDs, logging
│
├── metrics-etl/                     # Audience-specific analytics ETL
│   ├── metrics_extraction/          # Raw telemetry processing
│   ├── audience_transforms/         # Executive, Governance, Engineering views
│   ├── pipeline/                    # Orchestration
│   ├── schemas/                     # Derived table schemas
│   ├── config/                      # Configuration management
│   └── etl_readme.md                # Detailed ETL documentation
│
├── etl-langfuse/                    # Langfuse ETL (Cloud Function)
│   └── requirements.txt
│
├── langfuse-sql/                    # SQL utilities for Langfuse data
│
├── otel_end_to_end_full.ipynb       # End-to-end demo notebook
├── schemas.md                       # Data schema documentation
├── cloudbuild.yaml                  # CI/CD orchestration (Cloud Build)
├── pytest.ini                       # Testing configuration
└── requirements.txt                 # Root dependencies

```

---

## 🔄 Data Flow & Architecture

```
┌───────────────────────────────────────────────────────────────┐
│                     DATA INGESTION LAYER                       │
├───────────────────────────────────────────────────────────────┤
│
│  OpenTelemetry SDKs (Apps/Models)
│         │
│         │ (OTEL traces/logs/metrics as JSON)
│         ▼
│  Ingestion Service (FastAPI on Cloud Run)
│  ├─► Normalizes to CanonicalEvent
│  └─► Writes to mca_ingestion.canonical_events
│
├───────────────────────────────────────────────────────────────┤
│                   METRICS COMPUTATION LAYER                    │
├───────────────────────────────────────────────────────────────┤
│
│  Canonical Events (BigQuery)
│         │
│    ┌────┴────┬──────────────┬─────────────┐
│    │          │              │             │
│    ▼          ▼              ▼             ▼
│  Generative  Predictive    Agentic      ETL
│  Metrics     Metrics       Metrics      Transforms
│  Service     Service       Service      (Analytics)
│  (Langfuse)  (Evidently)   (Langfuse)
│    │          │              │             │
│    └────┬────┬──────────────┬─────────────┘
│         ▼    ▼              ▼
│    BigQuery Metrics Tables
│    ├─ generative_metrics
│    ├─ predictive_metrics
│    ├─ agentic_metrics
│    └─ analytics.* (executive, governance, engineering)
│
├───────────────────────────────────────────────────────────────┤
│                    ALERTING & EXPOSURE LAYER                   │
├───────────────────────────────────────────────────────────────┤
│
│  Alerts Service (Cloud Run Job)
│         │
│    ┌─���──┴────────┐
│    │             │
│    ▼             ▼
│ Prometheus    Cloud Monitoring
│ Scrape        Custom Metrics
│    │             │
│    ▼             ▼
│  ┌──────────────────────┐
│  │ Alert Policies       │
│  │ (Thresholds, Rules)  │
│  └──────────────────────┘
│         │
│         ▼
│    Pub/Sub Topic
│         │
│         ▼
│   Ingestion Service (Alert Handler)
│         │
│    ┌────┴────────────┐
│    │                 │
│    ▼                 ▼
│ Microsoft Teams   Email (SMTP)
│ Webhooks          Notifications
│
└───────────────────────────────────────────────────────────────┘
```

---

## 📊 Required BigQuery Tables

All tables **must exist before services run**. Use provided schema definitions to create them.

### Ingestion Dataset: `mca_ingestion`

| Table | Purpose | Key Columns |
|-------|---------|------------|
| `canonical_events` | Single source of truth for all OTEL telemetry | `event_id`, `model_id`, `model_type`, `trace_id`, `attributes`, `metrics`, `logs` |

### Metrics Datasets: `mca_metrics`

| Table | Purpose | Key Metrics |
|-------|---------|------------|
| `generative_metrics` | LLM output quality | hallucination_score, safety_score, pii_leakage_score, rag_precision/recall |
| `predictive_metrics` | Model performance & drift | accuracy, rmse, mae, drift_score, data_quality_score |
| `agentic_metrics` | Agent workflow performance | goal_completion_time, tool_latency, goal_success_rate, error_recovery_rate |

### Analytics Datasets: `analytics`

| Table | Audience | Key Metrics |
|-------|----------|------------|
| `executive_ai_summary` | C-suite, Finance | Cost (USD), Usage, Health Status, Latency |
| `ai_governance_summary` | Compliance, Risk | Drift, Hallucination, PII Risk, Policy Violations |
| `ai_engineering_metrics` | Engineering, DevOps | Throughput, Latency, Error Rates, System Health |

See [`schemas.md`](./schemas.md) for complete schema definitions.

---

## 🚀 Deployment

### Prerequisites

```bash
# GCP Setup
gcloud init
gcloud auth application-default login
gcloud config set project YOUR_PROJECT_ID

# Enable APIs
gcloud services enable \
  run.googleapis.com \
  build.googleapis.com \
  bigquery.googleapis.com \
  artifactregistry.googleapis.com \
  aiplatform.googleapis.com \
  logging.googleapis.com \
  monitoring.googleapis.com

# Create BigQuery datasets and tables
# (Use schemas.md as reference)
```

### Deploy via Cloud Build

```bash
# Deploy all services (Ingestion, Metrics, Alerts)
gcloud builds submit --config cloudbuild.yaml --project=YOUR_PROJECT_ID

# Or deploy individual services
gcloud builds submit \
  --config cloudbuild.yaml \
  --substitutions=_SERVICE=ingestion \
  --project=YOUR_PROJECT_ID
```

The `cloudbuild.yaml` orchestrates:
1. **Ingestion Service** → Cloud Run Service (API, port 8080)
2. **Generative Metrics** → Cloud Run Job (scheduled, idempotent)
3. **Predictive Metrics** → Cloud Run Job (scheduled, idempotent)
4. **Agentic Metrics** → Cloud Run Job (scheduled, idempotent)
5. **Alerts Service** → Cloud Run Job (polling + export)

### Local Development

```bash
# Set up Python environment
python -m venv venv
source venv/bin/activate

# Install root dependencies
pip install -r requirements.txt

# Run ingestion service locally
cd ingestion_service
pip install -r requirements.txt
functions-framework --target=handle_alert --debug --port=8080

# Test health endpoint
curl http://localhost:8080/health

# Send test alert payload
curl -X POST http://localhost:8080/ingest \
  -H "Content-Type: application/json" \
  -d @payload.json
```

---

## 🔐 Environment Variables & Secrets

### Common

| Variable | Required | Description |
|----------|----------|-------------|
| `GCP_PROJECT_ID` | ✅ | GCP Project ID |
| `BQ_CANONICAL_DATASET` | ✅ | BigQuery dataset (default: `mca_ingestion`) |

### Ingestion Service

| Variable | Required | Description |
|----------|----------|-------------|
| `GCP_PROJECT` | ✅ | GCP Project ID (Cloud Function) |
| `SMTP_HOST` | ✅ | SMTP server (default: `smtp.office365.com`) |
| `SMTP_PORT` | ✅ | SMTP port (default: `587`) |

### Generative / Agentic Services

| Variable | Required | Description |
|----------|----------|-------------|
| `GENAI_RAG_BUCKET` | ✅ | Cloud Storage bucket for RAG docs |
| `LANGFUSE_PUBLIC_KEY` | ✅ | Langfuse API key |
| `LANGFUSE_SECRET_KEY` | ✅ | Langfuse secret key |
| `LANGFUSE_HOST` | ⚠️ | Langfuse host (if self-hosted) |

### Secrets Manager

Store these securely in **Google Cloud Secret Manager**:

| Secret | Used By | Purpose |
|--------|---------|---------|
| `emms-teams-webhook-url` | Alert Handler | Microsoft Teams webhook |
| `smtp-username` | Alert Handler | SMTP authentication |
| `smtp-password` | Alert Handler | SMTP password |
| `db-password` | All Services | Cloud SQL password (if routing alerts) |

Access via:
```python
from google.cloud import secretmanager

client = secretmanager.SecretManagerServiceClient()
name = f"projects/{project_id}/secrets/{secret_id}/versions/latest"
response = client.access_secret_version(request={"name": name})
secret_value = response.payload.data.decode("UTF-8")
```

---

## 📈 Key Features by Service

### 1. Ingestion Service (FastAPI)

- ✅ Accepts OpenTelemetry traces/logs/metrics (JSON over HTTP)
- ✅ Normalizes multiple OTEL versions (v1.2, v4) to canonical schema
- ✅ Writes to BigQuery for downstream consumption
- ✅ Health check endpoint (`/health`)
- ✅ Idempotent ingestion (no duplicates on retry)

### 2. Generative Metrics (Langfuse + Vertex AI)

Evaluates LLM output quality:

- **Hallucination Score** — LLM judge probability (0-1)
- **Safety Score** — Policy violation detection (0-1)
- **PII Leakage Score** — Sensitive data detection via Cloud DLP (0-1)
- **RAG Precision/Recall** — Retrieval quality (0-1 scale)
- **Token Throughput** — Generation speed (tokens/sec)

### 3. Predictive Metrics (Evidently)

Monitors classical ML performance:

- **Accuracy, Precision, Recall** — Classification metrics
- **RMSE, MAE, R²** — Regression metrics
- **Drift Score** — Dataset shift detection (Evidently)
- **Data Quality Score** — Missing values, outliers
- **Feature-level Drift** — Per-feature drift ratio

### 4. Agentic Metrics

Tracks autonomous agent behavior:

- **Goal Completion Time** — Duration (seconds)
- **Tool Execution Latency** — Average tool call time (seconds)
- **Goal Success Rate** — LLM-judged success (0-1)
- **Error Recovery Rate** — Fraction of errors auto-resolved (0-1)
- **Human Intervention Rate** — Manual overrides (0-1)
- **Unauthorized Actions** — Policy violations (count)

### 5. Alerting & Notifications

Multi-channel alert routing:

- ✅ **Microsoft Teams** — Adaptive Cards with links to dashboards
- ✅ **Email (SMTP)** — HTML formatted alerts to distribution lists
- ✅ **Severity-based routing** — Critical alerts escalate to on-call
- ✅ **BigQuery logging** — All alerts audit-logged
- ✅ **Prometheus export** — Real-time metric scraping

---

## 📚 Documentation

- **[`schemas.md`](./schemas.md)** — Canonical and metrics table schemas
- **[`metrics-etl/etl_readme.md`](./metrics-etl/etl_readme.md)** — Audience-specific ETL transformations
- **[`shared/complete.md`](./shared/complete.md)** — Comprehensive system documentation (alerting, LLM evaluation, predictive monitoring)
- **[`otel_end_to_end_full.ipynb`](./otel_end_to_end_full.ipynb)** — Interactive demo (generate sample OTEL payloads, run pipeline locally)

---

## 🧪 Testing

```bash
# Run pytest suite
pytest

# Run with coverage
pytest --cov=ingestion_service

# Run specific test file
pytest tests/test_ingestion.py -v

# Mock OTEL payloads for local testing
python scripts/mock_otel_payload.py | curl -X POST http://localhost:8080/ingest -d @-
```

---

## 🎯 Design Principles

1. **Canonical First** — All telemetry normalized to a single schema before downstream processing
2. **Model-Type Isolation** — Separate services for generative, predictive, agentic metrics (independent scaling)
3. **Fail-Open** — Metrics computation failures don't crash ingestion pipeline
4. **Schema-Driven** — All data structures defined in `shared/schemas/`, enforced via Pydantic
5. **Cloud-Native** — Serverless (Cloud Run), managed data (BigQuery), async (Cloud Tasks/Pub/Sub)
6. **Idempotent** — All metric jobs can be safely re-run without duplication
7. **Auditable** — All alerts, ingestions, and transformations logged to BigQuery with timestamps

---

## 🔗 Integration Points

### Sending Telemetry to Ingestion Service

```python
# Client application using OpenTelemetry SDK

from opentelemetry import trace, metrics
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.exporter.otlp.proto.http.trace_exporter import OTLPSpanExporter
from opentelemetry.sdk.trace.export import BatchSpanProcessor

exporter = OTLPSpanExporter(
    endpoint="https://YOUR_INGESTION_SERVICE/v1/traces"
)
trace.set_tracer_provider(TracerProvider())
trace.get_tracer_provider().add_span_processor(
    BatchSpanProcessor(exporter)
)

tracer = trace.get_tracer(__name__)
with tracer.start_as_current_span("generate_response"):
    response = model.generate(prompt)
    # Span auto-exported to ingestion service
```

### Consuming Metrics from BigQuery

```sql
-- Executive dashboard: AI costs by model
SELECT
  model_id,
  ROUND(SUM(prompt_tokens + completion_tokens) / 1000 * 0.002, 2) as monthly_cost_usd,
  ROUND(AVG(tokens_per_second), 2) as avg_throughput,
  ROUND(AVG(hallucination_score), 4) as avg_hallucination
FROM mca_metrics.generative_metrics
WHERE DATE(event_time) >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)
GROUP BY model_id
ORDER BY monthly_cost_usd DESC;
```

### Setting Up Alerts in Cloud Monitoring

```python
# Generate alert policies programmatically

from google.cloud import monitoring_v3

client = monitoring_v3.AlertPolicyServiceClient()
project_name = f"projects/{project_id}"

policy = monitoring_v3.AlertPolicy(
    display_name="Hallucination Score Alert",
    conditions=[
        monitoring_v3.AlertPolicy.Condition(
            display_name="Hallucination > 0.3",
            condition_threshold=monitoring_v3.AlertPolicy.Condition.MetricThreshold(
                filter='metric.type="custom.googleapis.com/generative/hallucination_score"',
                comparison=monitoring_v3.ComparisonType.COMPARISON_GT,
                threshold_value=0.3,
                duration={"seconds": 300}
            )
        )
    ],
    notification_channels=[pubsub_channel_id]
)

created_policy = client.create_alert_policy(
    name=project_name,
    alert_policy=policy
)
```

---

## 🛠 Troubleshooting

### Ingestion Service Not Receiving Data

1. Check Cloud Run service is deployed and healthy:
   ```bash
   gcloud run services describe ingestion-service --region=us-east1
   curl https://ingestion-service-URL/health
   ```

2. Verify OTEL client is configured with correct endpoint:
   ```python
   print(exporter.endpoint)  # Should match service URL + /v1/traces
   ```

3. Check Cloud Logging for errors:
   ```bash
   gcloud logging read "resource.type=cloud_run_revision AND resource.labels.service_name=ingestion-service" --limit 50
   ```

### Metrics Not Appearing in BigQuery

1. Verify canonical events were ingested:
   ```sql
   SELECT COUNT(*) FROM mca_ingestion.canonical_events
   WHERE event_time > TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 1 HOUR);
   ```

2. Check metrics service job logs:
   ```bash
   gcloud logging read "resource.type=cloud_run_job AND resource.labels.job_name=metrics-generative-job" --limit 50
   ```

3. Ensure required BigQuery tables exist:
   ```bash
   bq ls mca_metrics
   ```

### Alerts Not Reaching Teams/Email

1. Verify Pub/Sub topic has messages:
   ```bash
   gcloud pubsub subscriptions pull alert-subscription --auto-ack --limit=5
   ```

2. Check Secret Manager credentials:
   ```bash
   gcloud secrets versions access latest --secret="emms-teams-webhook-url"
   ```

3. Review Cloud Function logs:
   ```bash
   gcloud functions describe handle_alert --runtime python39
   gcloud logging read "resource.type=cloud_function AND resource.labels.function_name=handle_alert" --limit 20
   ```

---

## 📊 Monitoring the Platform

### Key Metrics to Watch

```sql
-- Ingestion health
SELECT
  DATE(ingestion_time) as date,
  model_type,
  COUNT(*) as event_count
FROM mca_ingestion.canonical_events
GROUP BY date, model_type
ORDER BY date DESC, event_count DESC;

-- Metric quality
SELECT
  model_id,
  COUNT(*) as eval_count,
  COUNTIF(hallucination_score > 0.5) as high_hallucination,
  AVG(safety_score) as avg_safety
FROM mca_metrics.generative_metrics
GROUP BY model_id;

-- Alert volume
SELECT
  severity,
  COUNT(*) as alert_count
FROM alerts_log
WHERE DATE(alert_time) >= DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY)
GROUP BY severity;
```

---

## 🤝 Contributing

1. Create a branch from `main`
2. Make changes in your service's directory
3. Run tests: `pytest`
4. Submit PR with description of changes
5. All services must pass Cloud Build before merge

### Code Style

- **Python:** PEP 8, formatted with `black`
- **SQL:** BigQuery dialect, formatted with `sqlformat`
- **YAML:** 2-space indentation

---

## 📄 License

This project is provided as-is for internal use. Refer to your organization's license terms.

---

## 🚦 Roadmap

- [ ] Support for OpenTelemetry Protocol (OTLP) gRPC export
- [ ] Enhanced drift detection with statistical testing
- [ ] Custom metric plugins (user-defined evaluation functions)
- [ ] Multi-tenant support with organization isolation
- [ ] Real-time alerting via webhook chains
- [ ] Model baseline versioning and SLA management
- [ ] A/B testing framework for model comparisons

---

## 📞 Support & Questions

- **Documentation:** See [`shared/complete.md`](./shared/complete.md) for detailed component docs
- **Issues:** File GitHub issues with reproduction steps and logs
- **Slack/Teams:** Reach out to the ML Platform team

---

**Built for production AI/ML observability. Deploy with confidence.**
