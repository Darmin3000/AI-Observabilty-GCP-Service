import sqlalchemy
import os

class AgenticConfigClient:
    def __init__(self, *, project_id: str):
        self.engine = sqlalchemy.create_engine(
            os.environ["CLOUDSQL_URL"]
        )

    def get_model_config(self, model_id: str) -> dict:
        with self.engine.connect() as conn:
            row = conn.execute(
                sqlalchemy.text(
                    "SELECT * FROM model_config WHERE model_id=:id"
                ),
                {"id": model_id},
            ).fetchone()
        return dict(row) if row else {}