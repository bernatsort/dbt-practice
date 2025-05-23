# Documentation: Setting Up and Debugging Elementary in a Windows dbt Project

---

### 1. Initial `packages.yml` Configuration

```yaml
dependencies:
  - package: elementary-data/elementary
    version: 0.18.3
    # Docs: https://docs.elementary-data.com
  - package: dbt-labs/dbt_utils
    version: 1.3.0
    # Docs: https://hub.getdbt.com/dbt-labs/dbt_utils/latest/
  - package: metaplane/dbt_expectations
    version: 0.10.8
    # Docs: https://hub.getdbt.com/calogica/dbt_expectations/latest/
```

Running `dbt deps` from the project directory correctly installs all packages, including a dependency from Elementary (dbt-utils\@0.8.6).

---

### 2. Initial Error on `edr report --env dev`

Running:

```bash
edr report --env dev
```

produces an error:

```
FileNotFoundError: No such file or directory: 'dbt_packages\\dbt-utils-0.8.6\\integration_tests\\...'
```

**Root cause:** Windows has a maximum path length (260 chars) unless explicitly configured otherwise. dbt attempts to extract long-path files into a nested Elementary dbt project, hitting this limit.

---

### 3. Fix: Enable Long Paths in Windows

**Recommended fix:**
Open **PowerShell as Administrator** and run:

```powershell
Set-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem -Name LongPathsEnabled -Type DWord -Value 1
```

Then **reboot** Windows (preferred) to apply changes system-wide.

(Optional verification after reboot):

```powershell
Get-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem -Name LongPathsEnabled
```

Output should confirm:

```
LongPathsEnabled : 1
```

---

### 4. Second Error: dbt profile 'elementary' missing target `dev`

New error:

```
The profile 'elementary' does not have a target named 'dev'. Valid targets: - default
```

**Explanation:** The Elementary CLI uses the `elementary` profile. The profile existed, but only included an output named `default`, not `dev`.

**Fix:** Update `~/.dbt/profiles.yml`:

```yaml
elementary:
  target: dev
  outputs:
    dev:  # was "default"
      type: snowflake
      account: BI-EMEA
      user: BERNAT.SORT_RUFAT.EXT@EMAIL.COM
      role: BI-AS-ATLASSIAN-P-OMACL-TEAM
      authenticator: externalbrowser
      database: DEV_OMACL_DB
      warehouse: DEV_OMACL_VDW_ETL
      schema: LANDING_OMACL_SCHEMA
      threads: 4
```

Now, `edr report --env dev` runs successfully using the `dev` target.

---

### 5. Version Warning

At runtime:

```
You are using incompatible versions between edr (0.18.3) and Elementary's dbt package (0.16.4)
```

**Recommended fix:**
Update `packages.yml` to match the `edr` CLI version:

```yaml
- package: elementary-data/elementary
  version: 0.18.3
```

Then run:

```bash
dbt deps && dbt run --select elementary
```

---

### 6. Final Status

After the above changes:

* Long paths are supported in Windows
* dbt packages install successfully
* dbt profile matches Elementary's expected target
* `edr report --env dev` executes without file system or configuration errors

---

### 7. Notes

* If `edr report` still fails, try shortening the project path (e.g. move to `C:\dbt-project`) or use WSL.
* For enterprise setups, confirm no Group Policies reset `LongPathsEnabled`.

---

**Conclusion:**
This document walks through diagnosing and resolving Elementary setup issues in a Windows-based dbt project, including path limitations, dbt profile configuration, and version compatibility.


# Setting Up Elementary in a Windows Environment (with dbt + Snowflake)

This document summarizes a troubleshooting session for setting up [Elementary](https://docs.elementary-data.com) with dbt in a Windows machine. It covers initial configuration, resolving Windows path length issues, and fixing profile mismatches.

---

## `packages.yml` Configuration

```yaml
dependencies:
  - package: elementary-data/elementary
    version: 0.18.3
  - package: dbt-labs/dbt_utils
    version: 1.3.0
  - package: metaplane/dbt_expectations
    version: 0.10.8
```

## `dbt deps` Output (Successful)

```shell
$ dbt deps
Running with dbt=1.9.2
...
Installed elementary-data/elementary 0.18.3
Installed dbt-labs/dbt_utils 1.3.0
Installed metaplane/dbt_expectations 0.10.8
Installed godatadriven/dbt_date 0.13.0
```

## `edr report --env dev` Failure — Windows Path Limit Error

Elementary tried to run internal `dbt deps` under:

```
Lib\site-packages\elementary\monitor\dbt_project\dbt_packages
```

This led to:

```
FileNotFoundError: No such file or directory: '...dbt-utils-0.8.6\integration_tests\data\schema_tests\data_test_mutually_exclusive_ranges_no_gaps.csv'
```

### Cause

The full path exceeded the Windows MAX\_PATH limit of 260 characters.

### Fix (Enable Long Paths)

Open PowerShell **as Administrator** and run:

```powershell
Set-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem -Name LongPathsEnabled -Type DWord -Value 1
```

Then reboot your computer.

### Verification (optional)

```powershell
Get-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem -Name LongPathsEnabled
```

Should return:

```yaml
LongPathsEnabled : 1
```

## `edr report --env dev` New Failure — Missing Target "dev" in `profiles.yml`

```
Runtime Error:
The profile 'elementary' does not have a target named 'dev'.
Valid target names:
  - default
```

### Cause

In `profiles.yml`, the `elementary` profile had:

```yaml
elementary:
  target: dev
  outputs:
    default: ...
```

But `dev` target didn’t exist.

### Fix — Option A (Recommended)

Rename the `default` target to `dev`:

```yaml
elementary:
  target: dev
  outputs:
    dev:
      type: snowflake
      account: BI-EMEA
      user: BERNAT.SORT_RUFAT.EXT@EMAIL.COM
      role: BI-AS-ATLASSIAN-P-OMACL-TEAM
      authenticator: externalbrowser
      database: DEV_OMACL_DB
      warehouse: DEV_OMACL_VDW_ETL
      schema: LANDING_OMACL_SCHEMA
      threads: 4
```

Alternatively, use:

```bash
edr report --env dev -t default
```

## Success 🎉

After renaming the output to `dev` and running:

```bash
edr report --env dev
```

Elementary was able to:

* Install internal dbt packages
* Run macros like `get_latest_invocation`, `get_test_results`, `get_source_freshness_results`, `get_seeds`

✅ Path error resolved via long-paths
✅ Profile/target resolved via `profiles.yml` fix

## Final Note: Version Warning

You may see:

```
WARNING: You are using incompatible versions between edr (0.18.3) and Elementary's dbt package (0.16.4)
To fix please update your packages.yml and run: dbt deps && dbt run --select elementary
```

Update `packages.yml` to match `edr` version:

```yaml
- package: elementary-data/elementary
  version: 0.18.3  # Match your CLI version
```

Then run:

```bash
dbt deps && dbt run --select elementary
```

---

Let me know if any issues remain or if you'd like to further document version upgrades or schema overrides.
