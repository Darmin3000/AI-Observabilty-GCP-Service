# Model Monitoring Platform -- Full Technical Documentation

## Overview

The Model Monitoring Platform is a cloud‑native AI observability and
monitoring system designed to monitor Generative AI, Predictive ML
models, and Agentic AI systems using OpenTelemetry telemetry data.

The platform standardizes telemetry ingestion, computes model‑specific
metrics, and exposes monitoring signals for alerting.

Core technologies: - OpenTelemetry - Google Cloud Run - BigQuery -
Vertex AI - Evidently AI - Langfuse - Prometheus / Cloud Monitoring

Architecture pipeline:

OTEL SDKs → Ingestion Service → Canonical Events → Metrics Jobs →
Metrics Tables → Alerts

------------------------------------------------------------------------

# 1 Architecture Principles

Canonical‑first design.

All telemetry data must be normalized into a single canonical schema
before metrics computation.

Benefits: - auditability - schema stability - easy reprocessing -
decoupled metrics services

------------------------------------------------------------------------

# 2 BigQuery Data Infrastructure

Datasets:

mca_ingestion\
mca_metrics

Tables must exist before deployment.

------------------------------------------------------------------------

# 3 Canonical Events Table

Table:

mca_ingestion.canonical_events

Purpose:

Single source of truth for all OpenTelemetry traces, logs and metrics.

Fields:

event_id -- STRING\
Unique UUID for telemetry event.

model_id -- STRING\
Model identifier.

model_type -- STRING\
Values:

generative\
predictive\
agentic

event_type -- STRING\
trace\
log\
metric

event_time -- TIMESTAMP

trace_id -- STRING

span_id -- STRING

attributes -- JSON

metrics -- JSON

logs -- JSON

ingestion_time -- TIMESTAMP

------------------------------------------------------------------------

# 4 Ingestion Service

FastAPI service deployed to Cloud Run.

Responsibilities:

1 Accept OTEL JSON payloads\
2 Normalize to canonical schema\
3 Write to BigQuery

Pipeline:

OTEL → normalizer → canonical_event → BigQuery

No metrics computed here.

------------------------------------------------------------------------

# 5 Metrics Layer

Metrics are computed asynchronously using Cloud Run Jobs.

Services:

metrics_generative_service\
metrics_predictive_service\
metrics_agentic_service

Each service:

reads canonical_events\
computes metrics\
writes results to mca_metrics

------------------------------------------------------------------------

# 6 Generative Metrics

Table:

mca_metrics.generative_metrics

Fields:

prediction_id\
model_id\
model_version\
event_time\
hallucination_score\
safety_score\
pii_leakage_score\
rag_precision\
rag_recall\
rag_freshness_days\
prompt_tokens\
completion_tokens\
tokens_per_second\
ingestion_time

------------------------------------------------------------------------

## Hallucination Score

Computed via Vertex AI LLM‑as‑judge.

Judge receives:

retrieved context\
user prompt\
model response

Score range 0‑1.

------------------------------------------------------------------------

## Safety Score

LLM judge evaluates harmful content probability.

------------------------------------------------------------------------

## PII Leakage Score

LLM classification for presence of PII.

------------------------------------------------------------------------

## RAG Precision

Relevant information used / retrieved information.

------------------------------------------------------------------------

## RAG Recall

Retrieved relevant information / total relevant information.

------------------------------------------------------------------------

## RAG Freshness

current_time − gcs_blob_update_time

Stored in days.

------------------------------------------------------------------------

## Token Throughput

(prompt_tokens + completion_tokens) / latency_seconds

------------------------------------------------------------------------

# 7 Predictive Metrics

Table:

mca_metrics.predictive_metrics

Fields include:

prediction_value\
actual_value\
error\
rmse\
mae\
accuracy\
precision\
recall\
drift_score\
data_quality_score

------------------------------------------------------------------------

## Error

error = actual_value − prediction_value

------------------------------------------------------------------------

## RMSE

sqrt( (1/n) Σ (y_i − y_hat_i)\^2 )

Computed using Evidently RegressionPerformanceMetrics.

------------------------------------------------------------------------

## MAE

(1/n) Σ \|y_i − y_hat_i\|

------------------------------------------------------------------------

## Accuracy

correct_predictions / total_predictions

------------------------------------------------------------------------

## Precision

true_positive / (true_positive + false_positive)

------------------------------------------------------------------------

## Recall

true_positive / (true_positive + false_negative)

------------------------------------------------------------------------

## Drift Score

Computed using Evidently drift detection algorithms.

Methods:

Jensen‑Shannon distance\
Kolmogorov‑Smirnov test

------------------------------------------------------------------------

## Data Quality Score

Evidently data quality report measuring:

missing values\
feature distribution changes\
schema violations

------------------------------------------------------------------------

# 8 Agentic Metrics

Table:

mca_metrics.agentic_metrics

Fields:

goal_completion_time_seconds\
tool_execution_latency_seconds\
goal_success_rate\
error_recovery_rate\
human_intervention_rate\
unauthorized_action_attempts

------------------------------------------------------------------------

## Goal Completion Time

final_timestamp − start_timestamp

------------------------------------------------------------------------

## Tool Execution Latency

Average latency across tool spans.

------------------------------------------------------------------------

## Goal Success Rate

Binary evaluation comparing final response to intent attribute.

------------------------------------------------------------------------

## Error Recovery Rate

successful_retries / failed_actions

------------------------------------------------------------------------

## Human Intervention Rate

human_intervention_traces / total_traces

------------------------------------------------------------------------

## Unauthorized Actions

Regex detection for restricted tool calls.

------------------------------------------------------------------------

# 9 Alerts Layer

Reads metrics tables.

Exports metrics to:

Prometheus\
Cloud Monitoring

Triggers:

Email\
Teams\
PagerDuty

------------------------------------------------------------------------

# 10 CI/CD

Cloud Build builds and deploys services.

Common problems:

Context leakage when building from subdirectories.

Cloud Run port binding errors.

Insufficient IAM roles.

------------------------------------------------------------------------

# 11 Cloud Build Example

Build ingestion image.

Build generative metrics image.

Deploy ingestion service.

Deploy generative metrics job.

Options:

CLOUD_LOGGING_ONLY

Machine type:

E2_HIGHCPU_8

------------------------------------------------------------------------

# 12 Operational Guardrails

Fail‑open metrics philosophy.

Metrics services must never block ingestion.

Idempotent job execution.

Jobs check if prediction_id exists before writing metrics.
