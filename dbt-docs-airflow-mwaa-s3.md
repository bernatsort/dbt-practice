
---

# 🧾 MWAA DBT Docs Upload: Problem & Solution

## ❗ Problem

We needed to run a DAG in **Amazon MWAA (Managed Workflows for Apache Airflow)** that:

1. Generates **DBT documentation** (`dbt docs generate`)
2. Uploads the output files to an **S3 bucket**
3. Uses **Snowflake** credentials via Airflow Connections
4. Does **not hardcode AWS credentials** or store them in Airflow Connections

However, initial attempts to run the DAG failed with the following error when trying to upload files:

```
Unable to locate credentials
```

This occurred because the environment running the `aws s3 cp` command had **no access to AWS credentials** — even though MWAA itself has an IAM execution role.

---

## ✅ Root Cause

* While **MWAA’s execution role** is properly set up with access to S3, the **`aws` CLI inside BashOperators** does not automatically pick up that role.
* The environment of BashOperator **needs explicit credentials**, either via:

  * hardcoded AWS keys (❌ bad practice)
  * or **temporary credentials** injected via `boto3` session (✅ preferred)

---

## ✅ Solution

We generated temporary AWS credentials from the MWAA environment using `boto3`, then injected them into the environment of the Bash tasks using the `env` parameter.

### ✅ Code Fix (Python)

```python
import boto3

session = boto3.session.Session()
credentials = session.get_credentials().get_frozen_credentials()

aws_env = {
    "AWS_ACCESS_KEY_ID": credentials.access_key,
    "AWS_SECRET_ACCESS_KEY": credentials.secret_key,
    "AWS_SESSION_TOKEN": credentials.token,
}

my_env = {
   "PRIVATE_KEY": extra_conf_content,
   "PASSPHRASE": private_key,
   **aws_env,  # injects temporary AWS credentials
}
```

This `my_env` was then passed to `BashOperator` tasks that use `aws s3` commands.

---

## ✅ Additional Improvements

* Added `TriggerRule.ALL_DONE` to:

  * `dbt_remove` — so cleanup runs even if docs generation fails
  * `test_aws_ls` — to help debug S3 state after uploads
* Confirmed that this works seamlessly in **dev, QA, and prod** accounts because the credentials are tied to the **current environment’s IAM role**.

---

## ✅ Benefits of This Approach

* No AWS credentials in Airflow Connections (safer, easier to rotate)
* Fully works with MWAA's built-in role assumption model
* Portable across environments (dev/QA/prod)
* Aligned with AWS and Airflow best practices

---

## ✅ Outcome

* DBT docs are generated
* Uploaded to S3 successfully
* Verified with an `aws s3 ls` task
* Temporary files are removed after run

---


---

# 📄 Summary of `wf_dbt_docs` DAG Implementation Attempts

This document summarizes the three implementation attempts for the `wf_dbt_docs` Airflow DAG, detailing why Option 1 and Option 2 failed and why Option 3 succeeded. The DAG's purpose is to generate dbt documentation and upload it to S3.

---

## ✅ Option 3 — **Success**

### Description

* Generates the dbt docs (`manifest.json`, `catalog.json`, `index.html`, `static_index.html`) using a `BashOperator`.
* Uploads the files to S3 **within the same `bash_command`** using `aws s3 cp`.
* Injects **temporary AWS credentials** using `boto3.session.Session().get_credentials()`.
* Adds `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, and `AWS_SESSION_TOKEN` to `env`.

### Why It Worked

* ✅ Temporary credentials are injected and exported to the Bash environment, enabling `aws s3 cp` commands to authenticate.
* ✅ File generation and upload occur **in the same task**, ensuring files are still present in `/tmp` when the upload happens.
* ✅ No reliance on `LocalFilesystemToS3Operator`, avoiding dependency on AWS connection objects or filesystem race conditions.

---

## ❌ Option 1 — **Failed**

### Description

* Generates dbt docs and uploads them to S3 using Bash (`aws s3 cp`) in a single `BashOperator` task.

### Why It Failed

* ❌ The `aws s3 cp` command failed with:

  > `Unable to locate credentials`

* 🧠 **Root Cause**: The Bash environment did **not have AWS credentials**, so `aws s3 cp` could not authenticate with S3.

* ❌ No AWS environment variables (`AWS_ACCESS_KEY_ID`, etc.) were exported into `env` for the task.

* ❌ No Airflow connection (`aws_connection`) was used either.

---

## ❌ Option 2 — **Partially Failed**

### Description

* dbt docs are generated in one task.
* Each output file is uploaded to S3 **in separate tasks** using `LocalFilesystemToS3Operator`.

### Why It Partially Failed

* ✅ The `dbt_docs_generate_RA_dbt` task succeeded (docs were generated correctly).

* ❌ Only `upload_index.html` succeeded. The other upload tasks failed with:

  > `FileNotFoundError: No such file or directory: '/tmp/wf_dbt_ra_docs/...`

* 🧠 **Root Causes**:

  * ❌ The `/tmp` directory is **ephemeral per task execution** in MWAA. Once the `dbt_docs_generate_RA_dbt` task finished, the generated files in `/tmp` were gone for the subsequent tasks.
  * ❌ The `aws_connection` used in `LocalFilesystemToS3Operator` was **not configured** or **not passed correctly**, triggering fallback to default `boto3` session without proper credentials.

---

## ✅ Recommendation

Use **Option 3** in production:

* It is the only option that reliably handles **temporary credentials**, file **persistence**, and avoids dependency on shared volumes or Airflow AWS connections.
* Ensures end-to-end execution in one task with robust Bash control.

---


## 🔍 Key Distinctions Between Options

| Factor                                | Option 1 (❌)                            | Option 2 (❌)                                                          | Option 3 (✅)                                         |
| ------------------------------------- | --------------------------------------- | --------------------------------------------------------------------- | ---------------------------------------------------- |
| **AWS Credentials Available**         | ❌ Not injected or passed to env         | ⚠️ Possibly available via Airflow `aws_connection`, but not effective | ✅ Injected programmatically and exported to Bash env |
| **File Persistence Across Tasks**     | ✅ Same task, files available            | ❌ Files not shared across tasks in MWAA                               | ✅ Same task, files available                         |
| **Upload Method**                     | `aws s3 cp` in Bash without credentials | `LocalFilesystemToS3Operator` using `aws_connection`                  | `aws s3 cp` in Bash with credentials injected        |
| **Tasks Separation**                  | Single task                             | Multiple tasks (one per file)                                         | Single task                                          |
| **Dependency on Airflow Connections** | ❌ None used                             | ✅ Used but ineffective                                                | ❌ Not needed — manual credentials injection worked   |

---

### ✅ What Helped Option 3 Succeed

* Files were **not lost between tasks** since both generation and upload were performed in the same Bash task.
* `boto3` was used to **retrieve temporary credentials** dynamically, which were then **exported into the Bash environment**.
* Avoided reliance on Airflow's `LocalFilesystemToS3Operator` or pre-configured AWS connections.

---

### ❌ Why Options 1 and 2 Failed

* **Option 1**: Failed due to **missing credentials** — `aws s3 cp` could not authenticate.
* **Option 2**: Failed due to **loss of files** across separate tasks and likely **incomplete AWS connection setup**.

---

