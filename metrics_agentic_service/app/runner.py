from datetime import datetime, timezone
from collections import defaultdict

from shared.bigquery.writers import BigQueryWriter
from shared.schemas.canonical_event import CanonicalEvent
from .models import AgenticMetricsResult
from .gcs_client import GCSAgentPolicyClient
from .langfuse_client import LangfuseClient
from .cloudsql_client import AgenticConfigClient
from . import evaluators


class AgenticMetricsRunner:
    def __init__(self, *, project_id: str, policy_bucket: str):
        self.writer = BigQueryWriter(
            project_id=project_id,
            dataset="mca_metrics",
            table="agentic_metrics",
        )
        self.policy = GCSAgentPolicyClient(
            project_id=project_id,
            bucket_name=policy_bucket,
        )
        self.langfuse = LangfuseClient()
        self.config = AgenticConfigClient(project_id=project_id)

    def run_batch(self, events: list[CanonicalEvent]) -> None:
        grouped = defaultdict(list)
        for e in events:
            grouped[e.trace_id].append(e)

        results = []

        for trace_id, trace_events in grouped.items():
            results.append(self._process_trace(trace_id, trace_events))

        self.writer.write_models(results)

    def _process_trace(
        self,
        trace_id: str,
        events: list[CanonicalEvent],
    ) -> AgenticMetricsResult:

        events.sort(key=lambda e: e.event_time)
        start = events[0]
        end = events[-1]

        policy_text, _ = self.policy.get_policy(start.model_id)
        cfg = self.config.get_model_config(start.model_id)

        trace = self.langfuse.create_trace(
            name="agentic_metrics",
            input=start.attributes.get("goal"),
            output=end.attributes.get("final_output", ""),
            metadata={
                "model_id": start.model_id,
                "agent_id": start.attributes.get("agent_id"),
            },
        )

        goal_time = evaluators.goal_completion_time(events)
        tool_latency = evaluators.tool_latency(events)
        success = evaluators.goal_success(events, policy_text)
        recovery = evaluators.error_recovery_rate(events)
        human_rate = evaluators.human_intervention_rate(events)
        violations = evaluators.unauthorized_actions(events)

        if trace:
            self.langfuse.score(trace.id, "goal_success", success)
            self.langfuse.score(trace.id, "error_recovery", recovery)

        return AgenticMetricsResult(
            model_id=start.model_id,
            agent_id=start.attributes.get("agent_id"),
            goal_id=start.trace_id,
            event_time=end.event_time,
            goal_completion_time_seconds=goal_time,
            avg_tool_latency_seconds=tool_latency,
            goal_success_rate=success,
            error_recovery_rate=recovery,
            human_intervention_rate=human_rate,
            unauthorized_action_attempts=violations,
        )