# Model Monitoring Platform – Data Schemas

This document defines **all canonical and metrics schemas** used across the platform.
These schemas are **contractual**: producers and consumers must not diverge.

---

## 1. Canonical Ingestion Schema (MANDATORY)

### Table
`mca_ingestion.canonical_events`

### Purpose
Single source of truth for **all OpenTelemetry traces, logs, and metrics**.

### Schema
```json
{
  "event_id": "STRING",
  "model_id": "STRING",
  "model_type": "STRING",
  "event_type": "STRING",
  "event_time": "TIMESTAMP",
  "trace_id": "STRING",
  "span_id": "STRING",
  "attributes": "JSON",
  "metrics": "JSON",
  "logs": "JSON",
  "ingestion_time": "TIMESTAMP"
}
```

---

## 2. Generative Metrics Schema (MANDATORY)

### Table
`mca_metrics.generative_metrics`

### Schema
```json
{
  "prediction_id": "STRING",
  "model_id": "STRING",
  "model_version": "STRING",
  "event_time": "TIMESTAMP",
  "hallucination_score": "FLOAT",
  "safety_score": "FLOAT",
  "pii_leakage_score": "FLOAT",
  "rag_precision": "FLOAT",
  "rag_recall": "FLOAT",
  "rag_freshness_days": "INTEGER",
  "prompt_tokens": "INTEGER",
  "completion_tokens": "INTEGER",
  "tokens_per_second": "FLOAT",
  "ingestion_time": "TIMESTAMP"
}
```

---

## 3. Predictive Metrics Schema (MANDATORY)

### Table
`mca_metrics.predictive_metrics`

### Schema
```json
{
  "prediction_id": "STRING",
  "model_id": "STRING",
  "model_version": "STRING",
  "event_time": "TIMESTAMP",
  "prediction_value": "FLOAT",
  "actual_value": "FLOAT",
  "error": "FLOAT",
  "rmse": "FLOAT",
  "mae": "FLOAT",
  "accuracy": "FLOAT",
  "precision": "FLOAT",
  "recall": "FLOAT",
  "drift_score": "FLOAT",
  "data_quality_score": "FLOAT",
  "ingestion_time": "TIMESTAMP"
}
```

---

## 4. Agentic Metrics Schema (MANDATORY)

### Table
`mca_metrics.agentic_metrics`

### Schema
```json
{
  "agent_id": "STRING",
  "model_id": "STRING",
  "model_version": "STRING",
  "event_time": "TIMESTAMP",
  "goal_completion_time_seconds": "FLOAT",
  "tool_execution_latency_seconds": "FLOAT",
  "goal_success_rate": "FLOAT",
  "error_recovery_rate": "FLOAT",
  "human_intervention_rate": "FLOAT",
  "unauthorized_action_attempts": "INTEGER",
  "ingestion_time": "TIMESTAMP"
}
```

---

## Alerts Layer
Read-only. No tables written.

---

End of schema.
