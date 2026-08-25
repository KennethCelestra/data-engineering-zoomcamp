FROM python:3.9

RUN apt-get install wget
RUN pip install --default-timeout=120 --retries=10 pandas sqlalchemy psycopg2-binary

WORKDIR /app
COPY ingest_data.py ingest_data.py

ENTRYPOINT [ "python", "ingest_data.py" ]