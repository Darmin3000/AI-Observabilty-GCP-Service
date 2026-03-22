import os
from .runner import PredictiveMetricsRunner


def main():
    project_id = os.environ["GCP_PROJECT_ID"]
    model_id = os.environ["MODEL_ID"]

    runner = PredictiveMetricsRunner(project_id=project_id)
    runner.run(model_id=model_id)

    print(f"Predictive metrics computed for model_id={model_id}")


if __name__ == "__main__":
    main()
