# airflow-img/Dockerfile
FROM apache/airflow:2.9.1-python3.10

# ---- OS packages you really need ------------------------------------------
USER root
RUN apt-get update \
    && apt-get install -y --no-install-recommends git \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# ---- Python packages (run as airflow, per official docs) ------------------
USER airflow
# Asegura que PATH esté bien
ENV PATH="/home/airflow/.local/bin:$PATH" 
RUN pip install --no-cache-dir \
        "dbt-core==1.9.4" \
        "dbt-postgres==1.9.0" \
        "elementary-data==0.18.3"

# FROM apache/airflow:2.9.1-python3.10
# USER root

# # Instala git
# RUN apt-get update && apt-get install -y git

# USER airflow

# # Asegura que PATH esté bien
# ENV PATH="/home/airflow/.local/bin:$PATH"

# # Instala dbt + elementary
# RUN pip install --no-cache-dir \
#     dbt-core \
#     dbt-postgres \
#     elementary-data

