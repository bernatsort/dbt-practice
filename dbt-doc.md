dbt docs generate
Then launch the docs UI:
dbt docs serve --port 8088 (as localhost is already in use by airflow)

dbt docs generate: builds a manifest.json and catalog.json in the target/ folder, containing model metadata, tests, column descriptions, lineage, etc.

dbt docs serve: starts a local web server at http://localhost:8080 (or similar), where you can browse all your models interactively.

in airflow: 
dbt docs generate updates the target/catalog.json and manifest.json, which is used by both dbt docs serve and Elementary.

Serving docs (i.e., dbt docs serve) is not needed inside Airflow — it’s a local dev tool. In production, you could host the artifacts elsewhere (like S3 + static site).

Although your Airflow DAG now generates the documentation with dbt docs generate, Airflow does not host or display the docs UI (i.e., the nice searchable web interface). The dbt docs generate step only creates the artifacts locally inside the container