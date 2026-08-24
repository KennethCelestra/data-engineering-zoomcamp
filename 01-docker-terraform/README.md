# Module 1: Docker & Postgres

## What this does
Ingests NYC Yellow Taxi trip data (January 2021) into a PostgreSQL database
running in Docker, using a Python script with chunked pandas ingestion.

## Prerequisites
- Docker
- Python 3.10+ with a virtual environment
- Dependencies: `pandas`, `sqlalchemy`, `psycopg2-binary`

## Setup

### 1. Start Postgres in Docker
```bash
docker run -d --name pg-database \
  -e POSTGRES_USER="root" \
  -e POSTGRES_PASSWORD="root" \
  -e POSTGRES_DB="ny_taxi" \
  -v $(pwd)/ny_taxi_postgres_data:/var/lib/postgresql/data \
  -p 5432:5432 \
  postgres:13
```

### 2. Download the dataset
```bash
wget https://github.com/DataTalksClub/nyc-tlc-data/releases/download/yellow/yellow_tripdata_2021-01.csv.gz -O data/yellow_tripdata_2021-01.csv.gz
```

### 3. Run the ingestion script
```bash
python ingest_data.py \
  --user=root \
  --password=root \
  --host=localhost \
  --port=5432 \
  --db=ny_taxi \
  --table_name=yellow_taxi_data \
  --csv_file=data/yellow_tripdata_2021-01.csv.gz
```

## Result
Loads ~1.37M taxi trip records into the `yellow_taxi_data` table, in chunks
of 100,000 rows at a time.

## Verify it worked
Connect with `pgcli` and check the row count:
```bash
pgcli -h localhost -p 5432 -u root -d ny_taxi
```
```sql
SELECT COUNT(*) FROM yellow_taxi_data;
```