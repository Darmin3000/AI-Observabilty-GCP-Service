from datetime import datetime, timezone
from enum import Enum
from typing import Dict, List, Tuple

from shared.bigquery.readers import BigQueryReader
from shared.bigquery.writers import BigQueryWriter
from .evidently_runner import EvidentlyRunner
from .models import PredictiveMetricsResult


class ModelTaskType(str, Enum):
    REGRESSION = "regression"
    CLASSIFICATION = "classification"
    TIME_SERIES = "time_series"


class PredictiveMetricsRunner:
    """
    Computes offline predictive metrics for a given model_id.
    Supports regression, classification, and time-series models.
    """

    def __init__(self, *, project_id: str):
        self.reader = BigQueryReader(project_id=project_id)
        self.writer = BigQueryWriter(
            project_id=project_id,
            dataset="mca_metrics",
            table="predictive_metrics",
        )
        self.evidently = EvidentlyRunner()

    # ---------------------------------------------------------------------
    # Public API
    # ---------------------------------------------------------------------

    def run(
        self,
        *,
        model_id: str,
        task_type: ModelTaskType,
        start_time: datetime | None = None,
        end_time: datetime | None = None,
    ):
        """
        Entry point for predictive metric computation.
        """

        rows = self._load_predictions_and_actuals(
            model_id=model_id,
            start_time=start_time,
            end_time=end_time,
        )

        if not rows:
            self._write_empty_result(model_id)
            return

        if task_type == ModelTaskType.REGRESSION:
            metrics = self._run_regression(rows)

        elif task_type == ModelTaskType.CLASSIFICATION:
            metrics = self._run_classification(rows)

        elif task_type == ModelTaskType.TIME_SERIES:
            metrics = self._run_time_series(rows)

        else:
            raise ValueError(f"Unsupported task type: {task_type}")

        result = PredictiveMetricsResult(
            model_id=model_id,
            event_time=datetime.now(timezone.utc),
            **metrics,
        )

        self.writer.write_models([result])

    # ---------------------------------------------------------------------
    # Metric runners
    # ---------------------------------------------------------------------

    def _run_regression(self, rows: List[Dict]) -> Dict[str, float]:
        y_true, y_pred = self._extract_labels(rows)

        return self.evidently.regression_metrics(
            y_true=y_true,
            y_pred=y_pred,
        )

    def _run_classification(self, rows: List[Dict]) -> Dict[str, float]:
        y_true, y_pred = self._extract_labels(rows)

        return self.evidently.classification_metrics(
            y_true=y_true,
            y_pred=y_pred,
        )

    def _run_time_series(self, rows: List[Dict]) -> Dict[str, float]:
        """
        Time-series metrics are regression metrics computed over
        timestamped data.
        """
        y_true, y_pred = self._extract_labels(rows)

        return self.evidently.time_series_metrics(
            y_true=y_true,
            y_pred=y_pred,
        )

    # ---------------------------------------------------------------------
    # Data loading & preparation
    # ---------------------------------------------------------------------

    def _load_predictions_and_actuals(
        self,
        *,
        model_id: str,
        start_time: datetime | None,
        end_time: datetime | None,
    ) -> List[Dict]:
        """
        Loads and aligns predictions and actuals from BigQuery.
        """

        time_filter = ""
        if start_time and end_time:
            time_filter = """
            AND p.event_time BETWEEN @start_time AND @end_time
            """

        query = f"""
        SELECT
            p.prediction_id,
            p.prediction,
            a.actual
        FROM `mca_ingestion.predictions` p
        JOIN `mca_actuals.actuals` a
          ON p.prediction_id = a.prediction_id
        WHERE p.model_id = @model_id
        {time_filter}
        """

        job_config = self._param_config(
            model_id=model_id,
            start_time=start_time,
            end_time=end_time,
        )

        rows = self.reader.client.query(query, job_config=job_config).result()

        return [
            {
                "prediction": row["prediction"],
                "actual": row["actual"],
            }
            for row in rows
            if row["prediction"] is not None and row["actual"] is not None
        ]

    @staticmethod
    def _extract_labels(rows: List[Dict]) -> Tuple[List, List]:
        y_true = [r["actual"] for r in rows]
        y_pred = [r["prediction"] for r in rows]
        return y_true, y_pred

    # ---------------------------------------------------------------------
    # Failure / edge handling
    # ---------------------------------------------------------------------

    def _write_empty_result(self, model_id: str):
        """
        Writes a placeholder row when no data is available.
        """
        result = PredictiveMetricsResult(
            model_id=model_id,
            event_time=datetime.now(timezone.utc),
            rmse=None,
            mae=None,
            r2=None,
            accuracy=None,
            precision=None,
            recall=None,
        )
        self.writer.write_models([result])

    # ---------------------------------------------------------------------
    # BigQuery helpers
    # ---------------------------------------------------------------------

    @staticmethod
    def _param_config(
        *,
        model_id: str,
        start_time: datetime | None,
        end_time: datetime | None,
    ):
        from google.cloud import bigquery

        params = [
            bigquery.ScalarQueryParameter("model_id", "STRING", model_id)
        ]

        if start_time and end_time:
            params.extend([
                bigquery.ScalarQueryParameter("start_time", "TIMESTAMP", start_time),
                bigquery.ScalarQueryParameter("end_time", "TIMESTAMP", end_time),
            ])

        return bigquery.QueryJobConfig(query_parameters=params)