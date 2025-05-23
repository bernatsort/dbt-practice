# airflow-img/Dockerfile

FROM apache/airflow:2.9.1-python3.10

USER root

# Instala git
RUN apt-get update && apt-get install -y git

USER airflow

# Asegura que PATH esté bien
ENV PATH="/home/airflow/.local/bin:$PATH"

# Instala dbt + elementary
RUN pip install --no-cache-dir \
    dbt-core \
    dbt-postgres \
    elementary-data

