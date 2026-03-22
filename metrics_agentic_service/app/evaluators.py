from shared.schemas.canonical_event import CanonicalEvent
from shared.llm.vertex_client import VertexLLMEvaluator

_vertex = None

def _vertex_client():
    global _vertex
    if _vertex is None:
        _vertex = VertexLLMEvaluator()
    return _vertex


def goal_completion_time(events: list[CanonicalEvent]) -> float | None:
    if len(events) < 2:
        return None
    return (events[-1].event_time - events[0].event_time).total_seconds()


def tool_latency(events: list[CanonicalEvent]) -> float | None:
    durations = [
        e.attributes.get("latency_ms")
        for e in events
        if e.event_type == "tool_call"
    ]
    durations = [d for d in durations if d is not None]
    return sum(durations) / len(durations) / 1000 if durations else None


def goal_success(events: list[CanonicalEvent], policy: str) -> float:
    summary = "\n".join(
        e.attributes.get("summary", "") for e in events
    )
    return _vertex_client().judge_agent_goal(
        steps=summary,
        policy=policy,
    )


def error_recovery_rate(events: list[CanonicalEvent]) -> float:
    errors = [e for e in events if e.event_type == "error"]
    recovered = [e for e in errors if e.attributes.get("recovered")]
    return len(recovered) / len(errors) if errors else 1.0


def human_intervention_rate(events: list[CanonicalEvent]) -> float:
    return (
        len([e for e in events if e.event_type == "human_intervention"])
        / len(events)
    )


def unauthorized_actions(events: list[CanonicalEvent]) -> int:
    return len([
        e for e in events
        if e.attributes.get("policy_violation")
    ])