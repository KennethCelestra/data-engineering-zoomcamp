from datetime import datetime
import pandas as pd
from sqlalchemy import create_engine
from airflow import DAG
from airflow.operators.python import PythonOperator


def ingest_data():
    engine = create_engine('postgresql://root:root@host.docker.internal:5432/ny_taxi')
    engine.connect()

    df_iter = pd.read_csv(
        '/opt/airflow/dags/data/yellow_tripdata_2021-01.csv.gz',
        iterator=True,
        chunksize=100000
    )

    df = next(df_iter)
    df.tpep_pickup_datetime = pd.to_datetime(df.tpep_pickup_datetime)
    df.tpep_dropoff_datetime = pd.to_datetime(df.tpep_dropoff_datetime)

    df.head(n=0).to_sql(name='yellow_taxi_data', con=engine, if_exists='replace')
    df.to_sql(name='yellow_taxi_data', con=engine, if_exists='append')

    while True:
        try:
            df = next(df_iter)
            df.tpep_pickup_datetime = pd.to_datetime(df.tpep_pickup_datetime)
            df.tpep_dropoff_datetime = pd.to_datetime(df.tpep_dropoff_datetime)
            df.to_sql(name='yellow_taxi_data', con=engine, if_exists='append')
        except StopIteration:
            print('finished ingesting all chunks')
            break


with DAG(
    dag_id="ingest_taxi_data",
    schedule_interval="@once",
    start_date=datetime(2026, 1, 1),
    catchup=False,
) as dag:

    ingest_task = PythonOperator(
        task_id="ingest_data_task",
        python_callable=ingest_data,
    )