from typing import List
import math


class EvidentlyRunner:
    """
    Lightweight metric computations.
    Replace internals with Evidently later if needed.
    """

    def rmse(self, y_true: List[float], y_pred: List[float]) -> float | None:
        if not y_true or not y_pred or len(y_true) != len(y_pred):
            return None
        return math.sqrt(
            sum((a - p) ** 2 for a, p in zip(y_true, y_pred)) / len(y_true)
        )

    def mae(self, y_true: List[float], y_pred: List[float]) -> float | None:
        if not y_true or not y_pred or len(y_true) != len(y_pred):
            return None
        return sum(abs(a - p) for a, p in zip(y_true, y_pred)) / len(y_true)
