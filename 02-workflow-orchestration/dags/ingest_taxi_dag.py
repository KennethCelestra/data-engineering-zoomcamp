from datetime import datetime
import os
import pandas as pd
from sqlalchemy import create_engine
from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.operators.bash import BashOperator

URL_PREFIX = 'https://github.com/DataTalksClub/nyc-tlc-data/releases/download/yellow'
AIRFLOW_HOME = os.environ.get("AIRFLOW_HOME", "/opt/airflow")

# Templated paths - Airflow fills in {{ ... }} before the command/function runs
CSV_FILE_TEMPLATE = AIRFLOW_HOME + '/dags/data/yellow_tripdata_{{ execution_date.strftime("%Y-%m") }}.csv.gz'
URL_TEMPLATE = URL_PREFIX + '/yellow_tripdata_{{ execution_date.strftime("%Y-%m") }}.csv.gz'


def ingest_data(csv_file, year_month):
    table_name = f'yellow_taxi_{year_month.replace("-", "_")}'

    engine = create_engine('postgresql://root:root@host.docker.internal:5432/ny_taxi')
    engine.connect()

    df_iter = pd.read_csv(csv_file, iterator=True, chunksize=100000)

    df = next(df_iter)
    df.tpep_pickup_datetime = pd.to_datetime(df.tpep_pickup_datetime)
    df.tpep_dropoff_datetime = pd.to_datetime(df.tpep_dropoff_datetime)

    df.head(n=0).to_sql(name=table_name, con=engine, if_exists='replace')
    df.to_sql(name=table_name, con=engine, if_exists='append')

    while True:
        try:
            df = next(df_iter)
            df.tpep_pickup_datetime = pd.to_datetime(df.tpep_pickup_datetime)
            df.tpep_dropoff_datetime = pd.to_datetime(df.tpep_dropoff_datetime)
            df.to_sql(name=table_name, con=engine, if_exists='append')
        except StopIteration:
            print(f'finished ingesting {table_name}')
            break


with DAG(
    dag_id="ingest_taxi_data_parameterized",
    schedule_interval="@monthly",
    start_date=datetime(2021, 1, 1),
    end_date=datetime(2021, 3, 1),
    catchup=True,
    max_active_runs=1,
) as dag:

    download_task = BashOperator(
        task_id="download_task",
        bash_command=f'curl -sSL {URL_TEMPLATE} -o {CSV_FILE_TEMPLATE}',
    )

    ingest_task = PythonOperator(
        task_id="ingest_task",
        python_callable=ingest_data,
        op_kwargs={
            "csv_file": CSV_FILE_TEMPLATE,
            "year_month": '{{ execution_date.strftime("%Y-%m") }}',
        },
    )

    download_task >> ingest_task