from datetime import datetime
from airflow import DAG
from airflow.operators.bash import BashOperator

with DAG(
    dag_id="test_dag",
    schedule_interval="@daily",
    start_date=datetime(2026, 1, 1),
    catchup=False,
) as dag:

    task1 = BashOperator(
        task_id="print_hello",
        bash_command="echo 'Hello from Airflow!'",
    )