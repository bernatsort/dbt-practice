
---

# 🧩 MWAA `startup.sh` Script Failure: Line Endings and Path Errors

## ✅ Summary

An error occurred in MWAA after updating the `startup.sh` script to install additional dependencies (`elementary-data`). The same script had worked before — but after the update and environment restart, all DAGs using `dbt` failed with:

```
/usr/bin/bash: line X: /usr/local/airflow/dbt_venv: No such file or directory
```

---

## 🔍 Root Cause

The issue was **not caused by the DAG code or the package installation**, but by **Windows-style line endings (`CRLF`)** introduced when editing `startup.sh` in VS Code or another Windows editor.

### What happened:

* After editing, each line ended with `\r\n` (carriage return + line feed).
* In Unix environments like MWAA, `\r` (carriage return) is treated **as a literal character**.
* This corrupted the value of environment variables like `DBT_VENV_PATH`.

### Example:

```bash
export DBT_VENV_PATH="/usr/local/airflow/dbt_venv"
```

becomes internally:

```bash
/usr/local/airflow/dbt_venv^M/bin/dbt
```

So `/bin/dbt` is **not found**, causing a **command not found** error.

---

## 🤔 Why It Worked Before

The script previously had **Unix line endings (`LF`)**, so MWAA interpreted all paths correctly. The breakage only occurred after editing and saving with **Windows line endings (`CRLF`)**.

Unless explicitly configured, VS Code on Windows defaults to `CRLF`.

---

## 🛠️ Solution

### ✅ Step-by-step Fix

1. **Open `startup.sh` in VS Code.**
2. Bottom-right corner → Click on `CRLF`.
3. Change to `LF` (Unix format).
4. Save the file.
5. Re-upload the file to your MWAA S3 bucket (same location).
6. In AWS Console:

   * Go to **MWAA → your environment**.
   * Click **Edit** (and save) or use **“Restart environment”** to reinitialize.

Once restarted (\~10–15 minutes), MWAA will interpret the script correctly and your DAGs will work again.

---

## ✅ How to Check for This Issue

You can use this command locally:

```bash
cat -A startup.sh
```

### Output Meaning:

* `^M$` at the end of each line = ❌ Windows-style (`CRLF`)
* `$` only = ✅ Unix-style (`LF`)

---

## 🧼 Best Practices

* Always save shell scripts with **LF line endings**.
* On Windows, configure VS Code:

  * Add to `.editorconfig` or settings:

    ```
    [*.sh]
    end_of_line = lf
    ```
* Use tools like `dos2unix` if needed:

  ```bash
  dos2unix startup.sh
  ```

---

## 🧪 Validation

Once fixed and deployed:

* Trigger any DAG that uses `${DBT_VENV_PATH}` in bash commands.
* Confirm that it runs and resolves paths like `/usr/local/airflow/dbt_venv/bin/dbt` without failure.

---

