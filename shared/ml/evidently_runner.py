from typing import List
import math


class EvidentlyRunner:
    """
    Minimal Evidently-style metrics engine.
    Actual Evidently SDK can replace this later.
    """

    @staticmethod
    def rmse(y_true: List[float], y_pred: List[float]) -> float:
        return math.sqrt(
            sum((p - t) ** 2 for p, t in zip(y_pred, y_true)) / len(y_true)
        )

    @staticmethod
    def mae(y_true: List[float], y_pred: List[float]) -> float:
        return sum(abs(p - t) for p, t in zip(y_pred, y_true)) / len(y_true)