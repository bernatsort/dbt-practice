# dags/dbt_pipeline.py
from airflow import DAG
from airflow.operators.bash import BashOperator
from airflow.utils.trigger_rule import TriggerRule
from datetime import datetime, timedelta
import os

# --------------------------------------------------------------------------- #
# Constants                                                                   #
# --------------------------------------------------------------------------- #
DBT_PROJECT_DIR = "/opt/dbt_project"            

default_args = {
    "retries": 0,
    "retry_delay": timedelta(minutes=5),
}

# --------------------------------------------------------------------------- #
# DAG definition                                                              #
# --------------------------------------------------------------------------- #
with DAG(
    dag_id="dbt_pipeline",
    description="Seed ➜ snapshot ➜ build ➜ Elementary report",
    start_date=datetime(2024, 1, 1),
    schedule_interval=None,                     # change to '@daily' etc. in prod
    catchup=False,
    tags=["dbt", "elementary", "local"],
    default_args=default_args,
) as dag:

    env = {
    "DBT_PROJECT_DIR": DBT_PROJECT_DIR,
    "PATH": "/home/airflow/.local/bin:/usr/local/bin:/usr/bin:/bin",
    "DBT_HOST": "postgres",  #  profiles.yml: override solo para Airflow (localhost en local). # keep or move to compose.yml – your call
    }

    dbt_seed = BashOperator(
        task_id="dbt_seed",
        bash_command=(
            "cd $DBT_PROJECT_DIR && "
            "dbt seed --select path:seeds/customers_data/*"
        ),
        env=env,
    )

    # dbt_snapshot = BashOperator(
    #     task_id="dbt_snapshot",
    #     bash_command="cd $DBT_PROJECT_DIR && dbt snapshot",
    #     env=env,
    # )
    
    # dbt build also run snapsbots
    dbt_build = BashOperator(
        task_id="dbt_build",
        bash_command="cd $DBT_PROJECT_DIR && dbt build --exclude tag:wip",
        env=env,
    )

    dbt_docs_generate = BashOperator(
        task_id="dbt_docs_generate",
        bash_command="cd $DBT_PROJECT_DIR && dbt docs generate",
        trigger_rule=TriggerRule.ALL_DONE,
        env=env,
    )

    edr_report = BashOperator(
        task_id="edr_report",
        bash_command="cd $DBT_PROJECT_DIR && edr report",
        trigger_rule=TriggerRule.ALL_DONE,  #  se ejecuta incluso si dbt_build falló. Esto garantiza que edr_report siempre se ejecute, incluso si dbt_build falla por tests.
        env=env,
    )
    # Although your Airflow DAG now generates the documentation with dbt docs generate, 
    # Airflow does not host or display the docs UI (i.e., the nice searchable web interface). 
    # The dbt docs generate step only creates the artifacts locally inside the container.
    # Same with the edr report. 

    # Orchestration
    dbt_seed >> dbt_build >> dbt_docs_generate >> edr_report
