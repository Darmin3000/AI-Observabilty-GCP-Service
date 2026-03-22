-- =============================================================================
-- Langfuse LLM Monitoring Dashboards — Seed Script
-- =============================================================================
-- Creates 3 EMMS-specific dashboards with widgets for LLM monitoring.
-- Idempotent: skips widgets/dashboards that already exist (by ID).
--
-- Target: Langfuse v3 PostgreSQL (Cloud SQL)
-- Project: EMMS (resolved via subquery)
-- =============================================================================

BEGIN;

-- =========================================================================
-- DASHBOARD 1 WIDGETS: EMMS LLM Operations Overview
-- =========================================================================

INSERT INTO dashboard_widgets (id, project_id, name, description, view, dimensions, metrics, filters, chart_type, chart_config)
SELECT 'emms-llm-ops-total-traces', p.id,
       'Total Traces', 'Total number of LLM traces ingested',
       'TRACES', '[]'::jsonb,
       '[{"agg": "count", "measure": "count"}]'::jsonb,
       '[]'::jsonb, 'NUMBER', '{"type": "NUMBER", "row_limit": 100}'::jsonb
FROM projects p WHERE p.name = 'EMMS'
AND NOT EXISTS (SELECT 1 FROM dashboard_widgets WHERE id = 'emms-llm-ops-total-traces');

INSERT INTO dashboard_widgets (id, project_id, name, description, view, dimensions, metrics, filters, chart_type, chart_config)
SELECT 'emms-llm-ops-trace-volume', p.id,
       'Trace Volume Over Time', 'Number of traces over time',
       'TRACES', '[]'::jsonb,
       '[{"agg": "count", "measure": "count"}]'::jsonb,
       '[]'::jsonb, 'BAR_TIME_SERIES', '{"type": "BAR_TIME_SERIES"}'::jsonb
FROM projects p WHERE p.name = 'EMMS'
AND NOT EXISTS (SELECT 1 FROM dashboard_widgets WHERE id = 'emms-llm-ops-trace-volume');

INSERT INTO dashboard_widgets (id, project_id, name, description, view, dimensions, metrics, filters, chart_type, chart_config)
SELECT 'emms-llm-ops-avg-latency', p.id,
       'Average Latency', 'Mean trace latency across all LLM operations',
       'TRACES', '[]'::jsonb,
       '[{"agg": "avg", "measure": "latency"}]'::jsonb,
       '[]'::jsonb, 'NUMBER', '{"type": "NUMBER", "row_limit": 100}'::jsonb
FROM projects p WHERE p.name = 'EMMS'
AND NOT EXISTS (SELECT 1 FROM dashboard_widgets WHERE id = 'emms-llm-ops-avg-latency');

INSERT INTO dashboard_widgets (id, project_id, name, description, view, dimensions, metrics, filters, chart_type, chart_config)
SELECT 'emms-llm-ops-latency-p95', p.id,
       'Latency P95 Over Time', '95th percentile trace latency trend',
       'TRACES', '[]'::jsonb,
       '[{"agg": "p95", "measure": "latency"}]'::jsonb,
       '[]'::jsonb, 'LINE_TIME_SERIES', '{"type": "LINE_TIME_SERIES"}'::jsonb
FROM projects p WHERE p.name = 'EMMS'
AND NOT EXISTS (SELECT 1 FROM dashboard_widgets WHERE id = 'emms-llm-ops-latency-p95');

INSERT INTO dashboard_widgets (id, project_id, name, description, view, dimensions, metrics, filters, chart_type, chart_config)
SELECT 'emms-llm-ops-total-tokens', p.id,
       'Total Tokens', 'Sum of all tokens consumed across LLM traces',
       'TRACES', '[]'::jsonb,
       '[{"agg": "sum", "measure": "totalTokens"}]'::jsonb,
       '[]'::jsonb, 'NUMBER', '{"type": "NUMBER", "row_limit": 100}'::jsonb
FROM projects p WHERE p.name = 'EMMS'
AND NOT EXISTS (SELECT 1 FROM dashboard_widgets WHERE id = 'emms-llm-ops-total-tokens');

INSERT INTO dashboard_widgets (id, project_id, name, description, view, dimensions, metrics, filters, chart_type, chart_config)
SELECT 'emms-llm-ops-total-cost', p.id,
       'Total Cost', 'Cumulative LLM cost across all traces',
       'TRACES', '[]'::jsonb,
       '[{"agg": "sum", "measure": "totalCost"}]'::jsonb,
       '[]'::jsonb, 'NUMBER', '{"type": "NUMBER", "row_limit": 100}'::jsonb
FROM projects p WHERE p.name = 'EMMS'
AND NOT EXISTS (SELECT 1 FROM dashboard_widgets WHERE id = 'emms-llm-ops-total-cost');

INSERT INTO dashboard_widgets (id, project_id, name, description, view, dimensions, metrics, filters, chart_type, chart_config)
SELECT 'emms-llm-ops-traces-by-name', p.id,
       'Traces by Name', 'Trace count grouped by operation name',
       'TRACES', '[{"field": "name"}]'::jsonb,
       '[{"agg": "count", "measure": "count"}]'::jsonb,
       '[]'::jsonb, 'HORIZONTAL_BAR', '{"type": "HORIZONTAL_BAR", "row_limit": 20}'::jsonb
FROM projects p WHERE p.name = 'EMMS'
AND NOT EXISTS (SELECT 1 FROM dashboard_widgets WHERE id = 'emms-llm-ops-traces-by-name');

INSERT INTO dashboard_widgets (id, project_id, name, description, view, dimensions, metrics, filters, chart_type, chart_config)
SELECT 'emms-llm-ops-cost-trend', p.id,
       'Cost Over Time', 'Total LLM cost trend over time',
       'TRACES', '[]'::jsonb,
       '[{"agg": "sum", "measure": "totalCost"}]'::jsonb,
       '[]'::jsonb, 'LINE_TIME_SERIES', '{"type": "LINE_TIME_SERIES"}'::jsonb
FROM projects p WHERE p.name = 'EMMS'
AND NOT EXISTS (SELECT 1 FROM dashboard_widgets WHERE id = 'emms-llm-ops-cost-trend');

-- Dashboard 1
INSERT INTO dashboards (id, project_id, name, description, definition, filters)
SELECT 'emms-dashboard-llm-ops', p.id,
       'EMMS LLM Operations Overview',
       'Primary operational dashboard for LLM monitoring — trace volume, latency, tokens, and cost.',
       '{"widgets": [{"id": "d1w1", "type": "widget", "widgetId": "emms-llm-ops-total-traces", "x": 0, "y": 0, "x_size": 3, "y_size": 4}, {"id": "d1w2", "type": "widget", "widgetId": "emms-llm-ops-avg-latency", "x": 3, "y": 0, "x_size": 3, "y_size": 4}, {"id": "d1w3", "type": "widget", "widgetId": "emms-llm-ops-total-tokens", "x": 6, "y": 0, "x_size": 3, "y_size": 4}, {"id": "d1w4", "type": "widget", "widgetId": "emms-llm-ops-total-cost", "x": 9, "y": 0, "x_size": 3, "y_size": 4}, {"id": "d1w5", "type": "widget", "widgetId": "emms-llm-ops-trace-volume", "x": 0, "y": 4, "x_size": 6, "y_size": 5}, {"id": "d1w6", "type": "widget", "widgetId": "emms-llm-ops-latency-p95", "x": 6, "y": 4, "x_size": 6, "y_size": 5}, {"id": "d1w7", "type": "widget", "widgetId": "emms-llm-ops-traces-by-name", "x": 0, "y": 9, "x_size": 6, "y_size": 5}, {"id": "d1w8", "type": "widget", "widgetId": "emms-llm-ops-cost-trend", "x": 6, "y": 9, "x_size": 6, "y_size": 5}]}'::jsonb,
       '[]'::jsonb
FROM projects p WHERE p.name = 'EMMS'
AND NOT EXISTS (SELECT 1 FROM dashboards WHERE id = 'emms-dashboard-llm-ops');

-- =========================================================================
-- DASHBOARD 2 WIDGETS: AI Ops Agent Performance
-- =========================================================================

INSERT INTO dashboard_widgets (id, project_id, name, description, view, dimensions, metrics, filters, chart_type, chart_config)
SELECT 'emms-aiops-total-diagnoses', p.id,
       'Total Diagnoses', 'Number of AI Ops Agent diagnosis traces',
       'TRACES', '[]'::jsonb,
       '[{"agg": "count", "measure": "count"}]'::jsonb,
       '[]'::jsonb,
       'NUMBER', '{"type": "NUMBER", "row_limit": 100}'::jsonb
FROM projects p WHERE p.name = 'EMMS'
AND NOT EXISTS (SELECT 1 FROM dashboard_widgets WHERE id = 'emms-aiops-total-diagnoses');

INSERT INTO dashboard_widgets (id, project_id, name, description, view, dimensions, metrics, filters, chart_type, chart_config)
SELECT 'emms-aiops-latency-trend', p.id,
       'Diagnosis Latency P95', 'AI Ops Agent diagnosis latency trend (95th percentile)',
       'TRACES', '[]'::jsonb,
       '[{"agg": "p95", "measure": "latency"}]'::jsonb,
       '[]'::jsonb,
       'LINE_TIME_SERIES', '{"type": "LINE_TIME_SERIES"}'::jsonb
FROM projects p WHERE p.name = 'EMMS'
AND NOT EXISTS (SELECT 1 FROM dashboard_widgets WHERE id = 'emms-aiops-latency-trend');

INSERT INTO dashboard_widgets (id, project_id, name, description, view, dimensions, metrics, filters, chart_type, chart_config)
SELECT 'emms-aiops-tokens-trend', p.id,
       'Tokens Per Diagnosis', 'Average token usage per AI Ops Agent diagnosis over time',
       'TRACES', '[]'::jsonb,
       '[{"agg": "avg", "measure": "totalTokens"}]'::jsonb,
       '[]'::jsonb,
       'LINE_TIME_SERIES', '{"type": "LINE_TIME_SERIES"}'::jsonb
FROM projects p WHERE p.name = 'EMMS'
AND NOT EXISTS (SELECT 1 FROM dashboard_widgets WHERE id = 'emms-aiops-tokens-trend');

INSERT INTO dashboard_widgets (id, project_id, name, description, view, dimensions, metrics, filters, chart_type, chart_config)
SELECT 'emms-aiops-cost-trend', p.id,
       'Cost Per Diagnosis', 'Average cost per AI Ops Agent diagnosis over time',
       'TRACES', '[]'::jsonb,
       '[{"agg": "avg", "measure": "totalCost"}]'::jsonb,
       '[]'::jsonb,
       'LINE_TIME_SERIES', '{"type": "LINE_TIME_SERIES"}'::jsonb
FROM projects p WHERE p.name = 'EMMS'
AND NOT EXISTS (SELECT 1 FROM dashboard_widgets WHERE id = 'emms-aiops-cost-trend');

INSERT INTO dashboard_widgets (id, project_id, name, description, view, dimensions, metrics, filters, chart_type, chart_config)
SELECT 'emms-aiops-by-model', p.id,
       'Diagnoses by Model', 'Observation count grouped by model name',
       'OBSERVATIONS', '[{"field": "providedModelName"}]'::jsonb,
       '[{"agg": "count", "measure": "count"}]'::jsonb,
       '[]'::jsonb, 'HORIZONTAL_BAR', '{"type": "HORIZONTAL_BAR", "row_limit": 10}'::jsonb
FROM projects p WHERE p.name = 'EMMS'
AND NOT EXISTS (SELECT 1 FROM dashboard_widgets WHERE id = 'emms-aiops-by-model');

INSERT INTO dashboard_widgets (id, project_id, name, description, view, dimensions, metrics, filters, chart_type, chart_config)
SELECT 'emms-aiops-model-latency', p.id,
       'Latency by Model', 'P95 observation latency broken down by model',
       'OBSERVATIONS', '[{"field": "providedModelName"}]'::jsonb,
       '[{"agg": "p95", "measure": "latency"}]'::jsonb,
       '[]'::jsonb, 'VERTICAL_BAR', '{"type": "VERTICAL_BAR", "row_limit": 10}'::jsonb
FROM projects p WHERE p.name = 'EMMS'
AND NOT EXISTS (SELECT 1 FROM dashboard_widgets WHERE id = 'emms-aiops-model-latency');

-- Dashboard 2
INSERT INTO dashboards (id, project_id, name, description, definition, filters)
SELECT 'emms-dashboard-aiops', p.id,
       'AI Ops Agent Performance',
       'Monitors the AI Ops Agent — Gemini diagnosis traces, latency, token usage, and cost per diagnosis.',
       '{"widgets": [{"id": "d2w1", "type": "widget", "widgetId": "emms-aiops-total-diagnoses", "x": 0, "y": 0, "x_size": 4, "y_size": 4}, {"id": "d2w2", "type": "widget", "widgetId": "emms-aiops-by-model", "x": 4, "y": 0, "x_size": 4, "y_size": 4}, {"id": "d2w3", "type": "widget", "widgetId": "emms-aiops-model-latency", "x": 8, "y": 0, "x_size": 4, "y_size": 4}, {"id": "d2w4", "type": "widget", "widgetId": "emms-aiops-latency-trend", "x": 0, "y": 4, "x_size": 6, "y_size": 5}, {"id": "d2w5", "type": "widget", "widgetId": "emms-aiops-tokens-trend", "x": 6, "y": 4, "x_size": 6, "y_size": 5}, {"id": "d2w6", "type": "widget", "widgetId": "emms-aiops-cost-trend", "x": 0, "y": 9, "x_size": 12, "y_size": 5}]}'::jsonb,
       '[]'::jsonb
FROM projects p WHERE p.name = 'EMMS'
AND NOT EXISTS (SELECT 1 FROM dashboards WHERE id = 'emms-dashboard-aiops');

-- =========================================================================
-- DASHBOARD 3 WIDGETS: Token & Cost Analysis
-- =========================================================================

INSERT INTO dashboard_widgets (id, project_id, name, description, view, dimensions, metrics, filters, chart_type, chart_config)
SELECT 'emms-cost-total-tokens', p.id,
       'Total Tokens Consumed', 'Sum of all tokens across all LLM operations',
       'TRACES', '[]'::jsonb,
       '[{"agg": "sum", "measure": "totalTokens"}]'::jsonb,
       '[]'::jsonb, 'NUMBER', '{"type": "NUMBER", "row_limit": 100}'::jsonb
FROM projects p WHERE p.name = 'EMMS'
AND NOT EXISTS (SELECT 1 FROM dashboard_widgets WHERE id = 'emms-cost-total-tokens');

INSERT INTO dashboard_widgets (id, project_id, name, description, view, dimensions, metrics, filters, chart_type, chart_config)
SELECT 'emms-cost-total-cost', p.id,
       'Total LLM Cost', 'Cumulative cost of all LLM operations',
       'TRACES', '[]'::jsonb,
       '[{"agg": "sum", "measure": "totalCost"}]'::jsonb,
       '[]'::jsonb, 'NUMBER', '{"type": "NUMBER", "row_limit": 100}'::jsonb
FROM projects p WHERE p.name = 'EMMS'
AND NOT EXISTS (SELECT 1 FROM dashboard_widgets WHERE id = 'emms-cost-total-cost');

INSERT INTO dashboard_widgets (id, project_id, name, description, view, dimensions, metrics, filters, chart_type, chart_config)
SELECT 'emms-cost-token-trend', p.id,
       'Token Usage Over Time', 'Total token consumption trend',
       'TRACES', '[]'::jsonb,
       '[{"agg": "sum", "measure": "totalTokens"}]'::jsonb,
       '[]'::jsonb, 'LINE_TIME_SERIES', '{"type": "LINE_TIME_SERIES"}'::jsonb
FROM projects p WHERE p.name = 'EMMS'
AND NOT EXISTS (SELECT 1 FROM dashboard_widgets WHERE id = 'emms-cost-token-trend');

INSERT INTO dashboard_widgets (id, project_id, name, description, view, dimensions, metrics, filters, chart_type, chart_config)
SELECT 'emms-cost-by-model', p.id,
       'Cost by Model', 'LLM cost breakdown by model name',
       'OBSERVATIONS', '[{"field": "providedModelName"}]'::jsonb,
       '[{"agg": "sum", "measure": "totalCost"}]'::jsonb,
       '[]'::jsonb, 'HORIZONTAL_BAR', '{"type": "HORIZONTAL_BAR", "row_limit": 10}'::jsonb
FROM projects p WHERE p.name = 'EMMS'
AND NOT EXISTS (SELECT 1 FROM dashboard_widgets WHERE id = 'emms-cost-by-model');

INSERT INTO dashboard_widgets (id, project_id, name, description, view, dimensions, metrics, filters, chart_type, chart_config)
SELECT 'emms-cost-trend', p.id,
       'Cost Trend', 'LLM cost over time',
       'TRACES', '[]'::jsonb,
       '[{"agg": "sum", "measure": "totalCost"}]'::jsonb,
       '[]'::jsonb, 'LINE_TIME_SERIES', '{"type": "LINE_TIME_SERIES"}'::jsonb
FROM projects p WHERE p.name = 'EMMS'
AND NOT EXISTS (SELECT 1 FROM dashboard_widgets WHERE id = 'emms-cost-trend');

INSERT INTO dashboard_widgets (id, project_id, name, description, view, dimensions, metrics, filters, chart_type, chart_config)
SELECT 'emms-cost-top-traces', p.id,
       'Top Traces by Cost', 'Most expensive trace types',
       'TRACES', '[{"field": "name"}]'::jsonb,
       '[{"agg": "sum", "measure": "totalCost"}]'::jsonb,
       '[]'::jsonb, 'HORIZONTAL_BAR', '{"type": "HORIZONTAL_BAR", "row_limit": 20}'::jsonb
FROM projects p WHERE p.name = 'EMMS'
AND NOT EXISTS (SELECT 1 FROM dashboard_widgets WHERE id = 'emms-cost-top-traces');

INSERT INTO dashboard_widgets (id, project_id, name, description, view, dimensions, metrics, filters, chart_type, chart_config)
SELECT 'emms-cost-tokens-pie', p.id,
       'Token Distribution by Trace', 'Proportion of token usage by trace type',
       'TRACES', '[{"field": "name"}]'::jsonb,
       '[{"agg": "sum", "measure": "totalTokens"}]'::jsonb,
       '[]'::jsonb, 'PIE', '{"type": "PIE", "row_limit": 10}'::jsonb
FROM projects p WHERE p.name = 'EMMS'
AND NOT EXISTS (SELECT 1 FROM dashboard_widgets WHERE id = 'emms-cost-tokens-pie');

-- Dashboard 3
INSERT INTO dashboards (id, project_id, name, description, definition, filters)
SELECT 'emms-dashboard-cost', p.id,
       'Token & Cost Analysis',
       'Deep dive into LLM token usage and cost patterns — model breakdown, cost trends, and top consumers.',
       '{"widgets": [{"id": "d3w1", "type": "widget", "widgetId": "emms-cost-total-tokens", "x": 0, "y": 0, "x_size": 6, "y_size": 4}, {"id": "d3w2", "type": "widget", "widgetId": "emms-cost-total-cost", "x": 6, "y": 0, "x_size": 6, "y_size": 4}, {"id": "d3w3", "type": "widget", "widgetId": "emms-cost-token-trend", "x": 0, "y": 4, "x_size": 6, "y_size": 5}, {"id": "d3w4", "type": "widget", "widgetId": "emms-cost-trend", "x": 6, "y": 4, "x_size": 6, "y_size": 5}, {"id": "d3w5", "type": "widget", "widgetId": "emms-cost-by-model", "x": 0, "y": 9, "x_size": 4, "y_size": 5}, {"id": "d3w6", "type": "widget", "widgetId": "emms-cost-top-traces", "x": 4, "y": 9, "x_size": 4, "y_size": 5}, {"id": "d3w7", "type": "widget", "widgetId": "emms-cost-tokens-pie", "x": 8, "y": 9, "x_size": 4, "y_size": 5}]}'::jsonb,
       '[]'::jsonb
FROM projects p WHERE p.name = 'EMMS'
AND NOT EXISTS (SELECT 1 FROM dashboards WHERE id = 'emms-dashboard-cost');

-- =============================================================================
-- DASHBOARD 4 WIDGETS: Complete GenAI & Agentic AI Metrics
-- =============================================================================

-- ==============================
-- GENAI QUALITY METRICS (Scores)
-- ==============================

INSERT INTO dashboard_widgets (id, project_id, name, description, view, dimensions, metrics, filters, chart_type, chart_config)
SELECT 'emms-genai-hallucination', p.id,
       'Hallucination Score', 'Average hallucination score across generated outputs',
       'OBSERVATIONS', '[]'::jsonb,
       '[{"agg": "avg", "measure": "hallucination_score"}]'::jsonb,
       '[]'::jsonb, 'NUMBER', '{"type": "NUMBER"}'::jsonb
FROM projects p WHERE p.name = 'EMMS'
AND NOT EXISTS (SELECT 1 FROM dashboard_widgets WHERE id = 'emms-genai-hallucination');

INSERT INTO dashboard_widgets (id, project_id, name, description, view, dimensions, metrics, filters, chart_type, chart_config)
SELECT 'emms-genai-safety', p.id,
       'Safety Risk Score', 'Average safety risk score of generated outputs',
       'OBSERVATIONS', '[]'::jsonb,
       '[{"agg": "avg", "measure": "safety_score"}]'::jsonb,
       '[]'::jsonb, 'NUMBER', '{"type": "NUMBER"}'::jsonb
FROM projects p WHERE p.name = 'EMMS'
AND NOT EXISTS (SELECT 1 FROM dashboard_widgets WHERE id = 'emms-genai-safety');

INSERT INTO dashboard_widgets (id, project_id, name, description, view, dimensions, metrics, filters, chart_type, chart_config)
SELECT 'emms-genai-pii-leakage', p.id,
       'PII Leakage Score', 'Probability of PII leakage in responses',
       'OBSERVATIONS', '[]'::jsonb,
       '[{"agg": "avg", "measure": "pii_leakage_score"}]'::jsonb,
       '[]'::jsonb, 'NUMBER', '{"type": "NUMBER"}'::jsonb
FROM projects p WHERE p.name = 'EMMS'
AND NOT EXISTS (SELECT 1 FROM dashboard_widgets WHERE id = 'emms-genai-pii-leakage');

-- ==============================
-- RAG METRICS
-- ==============================

INSERT INTO dashboard_widgets (id, project_id, name, description, view, dimensions, metrics, filters, chart_type, chart_config)
SELECT 'emms-rag-precision', p.id,
       'RAG Precision', 'Retrieval precision of RAG pipeline',
       'OBSERVATIONS', '[]'::jsonb,
       '[{"agg": "avg", "measure": "rag_precision"}]'::jsonb,
       '[]'::jsonb, 'NUMBER', '{"type": "NUMBER"}'::jsonb
FROM projects p WHERE p.name = 'EMMS'
AND NOT EXISTS (SELECT 1 FROM dashboard_widgets WHERE id = 'emms-rag-precision');

INSERT INTO dashboard_widgets (id, project_id, name, description, view, dimensions, metrics, filters, chart_type, chart_config)
SELECT 'emms-rag-recall', p.id,
       'RAG Recall', 'Retrieval recall of RAG pipeline',
       'OBSERVATIONS', '[]'::jsonb,
       '[{"agg": "avg", "measure": "rag_recall"}]'::jsonb,
       '[]'::jsonb, 'NUMBER', '{"type": "NUMBER"}'::jsonb
FROM projects p WHERE p.name = 'EMMS'
AND NOT EXISTS (SELECT 1 FROM dashboard_widgets WHERE id = 'emms-rag-recall');

INSERT INTO dashboard_widgets (id, project_id, name, description, view, dimensions, metrics, filters, chart_type, chart_config)
SELECT 'emms-rag-freshness', p.id,
       'RAG Data Freshness', 'Average age of retrieved documents',
       'OBSERVATIONS', '[]'::jsonb,
       '[{"agg": "avg", "measure": "rag_freshness_days"}]'::jsonb,
       '[]'::jsonb, 'NUMBER', '{"type": "NUMBER"}'::jsonb
FROM projects p WHERE p.name = 'EMMS'
AND NOT EXISTS (SELECT 1 FROM dashboard_widgets WHERE id = 'emms-rag-freshness');

-- ==============================
-- TOKEN METRICS (Fixed View)
-- ==============================

INSERT INTO dashboard_widgets (id, project_id, name, description, view, dimensions, metrics, filters, chart_type, chart_config)
SELECT 'emms-genai-prompt-tokens', p.id,
       'Avg Prompt Tokens', 'Average prompt tokens used per generation',
       'OBSERVATIONS', '[]'::jsonb,
       '[{"agg": "avg", "measure": "promptTokens"}]'::jsonb,
       '[]'::jsonb, 'NUMBER', '{"type": "NUMBER"}'::jsonb
FROM projects p WHERE p.name = 'EMMS'
AND NOT EXISTS (SELECT 1 FROM dashboard_widgets WHERE id = 'emms-genai-prompt-tokens');

INSERT INTO dashboard_widgets (id, project_id, name, description, view, dimensions, metrics, filters, chart_type, chart_config)
SELECT 'emms-genai-completion-tokens', p.id,
       'Avg Completion Tokens', 'Average completion tokens used per generation',
       'OBSERVATIONS', '[]'::jsonb,
       '[{"agg": "avg", "measure": "completionTokens"}]'::jsonb,
       '[]'::jsonb, 'NUMBER', '{"type": "NUMBER"}'::jsonb
FROM projects p WHERE p.name = 'EMMS'
AND NOT EXISTS (SELECT 1 FROM dashboard_widgets WHERE id = 'emms-genai-completion-tokens');

INSERT INTO dashboard_widgets (id, project_id, name, description, view, dimensions, metrics, filters, chart_type, chart_config)
SELECT 'emms-genai-total-tokens', p.id,
       'Total Tokens', 'Cumulative tokens consumed across EMMS',
       'TRACES', '[]'::jsonb,
       '[{"agg": "sum", "measure": "totalTokens"}]'::jsonb,
       '[]'::jsonb, 'NUMBER', '{"type": "NUMBER"}'::jsonb
FROM projects p WHERE p.name = 'EMMS'
AND NOT EXISTS (SELECT 1 FROM dashboard_widgets WHERE id = 'emms-genai-total-tokens');

-- ==============================
-- AGENTIC AI METRICS
-- ==============================

INSERT INTO dashboard_widgets (id, project_id, name, description, view, dimensions, metrics, filters, chart_type, chart_config)
SELECT 'emms-agent-goal-success', p.id,
       'Agent Goal Success Rate', 'Percentage of goals successfully completed',
       'OBSERVATIONS', '[]'::jsonb,
       '[{"agg": "avg", "measure": "goal_success_rate"}]'::jsonb,
       '[]'::jsonb, 'NUMBER', '{"type": "NUMBER"}'::jsonb
FROM projects p WHERE p.name = 'EMMS'
AND NOT EXISTS (SELECT 1 FROM dashboard_widgets WHERE id = 'emms-agent-goal-success');

INSERT INTO dashboard_widgets (id, project_id, name, description, view, dimensions, metrics, filters, chart_type, chart_config)
SELECT 'emms-agent-goal-time', p.id,
       'Goal Completion Time', 'Average time required for agent goal completion',
       'OBSERVATIONS', '[]'::jsonb,
       '[{"agg": "avg", "measure": "goal_completion_time_seconds"}]'::jsonb,
       '[]'::jsonb, 'NUMBER', '{"type": "NUMBER"}'::jsonb
FROM projects p WHERE p.name = 'EMMS'
AND NOT EXISTS (SELECT 1 FROM dashboard_widgets WHERE id = 'emms-agent-goal-time');

INSERT INTO dashboard_widgets (id, project_id, name, description, view, dimensions, metrics, filters, chart_type, chart_config)
SELECT 'emms-agent-tool-latency', p.id,
       'Tool Execution Latency', 'Average latency of agent tool execution',
       'OBSERVATIONS', '[]'::jsonb,
       '[{"agg": "avg", "measure": "latency"}]'::jsonb,
       '[]'::jsonb, 'NUMBER', '{"type": "NUMBER"}'::jsonb
FROM projects p WHERE p.name = 'EMMS'
AND NOT EXISTS (SELECT 1 FROM dashboard_widgets WHERE id = 'emms-agent-tool-latency');

INSERT INTO dashboard_widgets (id, project_id, name, description, view, dimensions, metrics, filters, chart_type, chart_config)
SELECT 'emms-agent-human-intervention', p.id,
       'Human Intervention Rate', 'Frequency of human intervention during agent tasks',
       'OBSERVATIONS', '[]'::jsonb,
       '[{"agg": "avg", "measure": "human_intervention_rate"}]'::jsonb,
       '[]'::jsonb, 'NUMBER', '{"type": "NUMBER"}'::jsonb
FROM projects p WHERE p.name = 'EMMS'
AND NOT EXISTS (SELECT 1 FROM dashboard_widgets WHERE id = 'emms-agent-human-intervention');

INSERT INTO dashboard_widgets (id, project_id, name, description, view, dimensions, metrics, filters, chart_type, chart_config)
SELECT 'emms-agent-error-recovery', p.id,
       'Error Recovery Rate', 'Percentage of agent errors successfully recovered',
       'OBSERVATIONS', '[]'::jsonb,
       '[{"agg": "avg", "measure": "error_recovery_rate"}]'::jsonb,
       '[]'::jsonb, 'NUMBER', '{"type": "NUMBER"}'::jsonb
FROM projects p WHERE p.name = 'EMMS'
AND NOT EXISTS (SELECT 1 FROM dashboard_widgets WHERE id = 'emms-agent-error-recovery');

INSERT INTO dashboard_widgets (id, project_id, name, description, view, dimensions, metrics, filters, chart_type, chart_config)
SELECT 'emms-agent-unauthorized-actions', p.id,
       'Unauthorized Action Attempts', 'Count of agent attempts to perform unauthorized actions',
       'OBSERVATIONS', '[]'::jsonb,
       '[{"agg": "sum", "measure": "unauthorized_action_attempts"}]'::jsonb,
       '[]'::jsonb, 'NUMBER', '{"type": "NUMBER"}'::jsonb
FROM projects p WHERE p.name = 'EMMS'
AND NOT EXISTS (SELECT 1 FROM dashboard_widgets WHERE id = 'emms-agent-unauthorized-actions');

INSERT INTO dashboard_widgets (id, project_id, name, description, view, dimensions, metrics, filters, chart_type, chart_config)
SELECT 'emms-agent-tool-call-count', p.id,
       'Tool Call Count', 'Number of tools invoked by agents',
       'OBSERVATIONS', '[]'::jsonb,
       '[{"agg": "sum", "measure": "count"}]'::jsonb,
       '[]'::jsonb, 'NUMBER', '{"type": "NUMBER"}'::jsonb
FROM projects p WHERE p.name = 'EMMS'
AND NOT EXISTS (SELECT 1 FROM dashboard_widgets WHERE id = 'emms-agent-tool-call-count');

-- =========================================================================
-- Dashboard 4: Final Definition (Fixed ID sequence)
-- =========================================================================

INSERT INTO dashboards (id, project_id, name, description, definition, filters)
SELECT 'emms-dashboard-genai-agentic-complete', p.id,
       'Complete GenAI & Agentic AI Metrics',
       'Comprehensive monitoring of generative AI quality, RAG performance, and autonomous agent operations.',
       '{
         "widgets": [
           {"id": "d4w1", "type": "widget", "widgetId": "emms-genai-hallucination", "x": 0, "y": 0, "x_size": 3, "y_size": 4},
           {"id": "d4w2", "type": "widget", "widgetId": "emms-genai-safety", "x": 3, "y": 0, "x_size": 3, "y_size": 4},
           {"id": "d4w3", "type": "widget", "widgetId": "emms-genai-pii-leakage", "x": 6, "y": 0, "x_size": 3, "y_size": 4},
           {"id": "d4w4", "type": "widget", "widgetId": "emms-agent-goal-success", "x": 9, "y": 0, "x_size": 3, "y_size": 4},

           {"id": "d4w5", "type": "widget", "widgetId": "emms-rag-precision", "x": 0, "y": 4, "x_size": 3, "y_size": 4},
           {"id": "d4w6", "type": "widget", "widgetId": "emms-rag-recall", "x": 3, "y": 4, "x_size": 3, "y_size": 4},
           {"id": "d4w7", "type": "widget", "widgetId": "emms-rag-freshness", "x": 6, "y": 4, "x_size": 3, "y_size": 4},
           {"id": "d4w8", "type": "widget", "widgetId": "emms-agent-goal-time", "x": 9, "y": 4, "x_size": 3, "y_size": 4},

           {"id": "d4w9", "type": "widget", "widgetId": "emms-genai-prompt-tokens", "x": 0, "y": 8, "x_size": 3, "y_size": 4},
           {"id": "d4w10", "type": "widget", "widgetId": "emms-genai-completion-tokens", "x": 3, "y": 8, "x_size": 3, "y_size": 4},
           {"id": "d4w11", "type": "widget", "widgetId": "emms-genai-total-tokens", "x": 6, "y": 8, "x_size": 3, "y_size": 4},
           {"id": "d4w12", "type": "widget", "widgetId": "emms-agent-tool-latency", "x": 9, "y": 8, "x_size": 3, "y_size": 4},

           {"id": "d4w13", "type": "widget", "widgetId": "emms-agent-human-intervention", "x": 0, "y": 12, "x_size": 3, "y_size": 4},
           {"id": "d4w14", "type": "widget", "widgetId": "emms-agent-error-recovery", "x": 3, "y": 12, "x_size": 3, "y_size": 4},
           {"id": "d4w15", "type": "widget", "widgetId": "emms-agent-unauthorized-actions", "x": 6, "y": 12, "x_size": 3, "y_size": 4},
           {"id": "d4w16", "type": "widget", "widgetId": "emms-agent-tool-call-count", "x": 9, "y": 12, "x_size": 3, "y_size": 4}
         ]
       }'::jsonb,
       '[]'::jsonb
FROM projects p WHERE p.name = 'EMMS'
AND NOT EXISTS (SELECT 1 FROM dashboards WHERE id = 'emms-dashboard-genai-agentic-complete');
