---

````markdown
# Resolving a Git Merge Conflict After `stash pop`

## 📘 Context

When working on a feature branch (e.g., `feature/elementary-config`), you might stash your changes, update your `master` branch, and then rebase your feature branch onto it. After doing a `git stash pop`, a **merge conflict** may occur in files that were modified both upstream and in your stash (e.g., `dbt_profile.yml`).

This document explains how to identify and resolve such a conflict.

---

## 🔄 Typical Scenario

```bash
# Save current changes (including untracked files)
git stash -u

# Update master
git checkout master
git pull origin master

# Rebase feature branch
git checkout feature/elementary-config
git rebase master

# Apply stash
git stash pop
````

After `git stash pop`, you might see something like:

```
Auto-merging dbt_profile.yml
CONFLICT (content): Merge conflict in dbt_profile.yml
```

---

## ⚠️ The Problem

Git has detected a conflict in `dbt_profile.yml` because both the upstream version and your stashed changes modified the same line:

```diff
<<<<<<< Updated upstream
warehouse: DEV_OMACL_VDW_ETL
=======
warehouse: PROD_OMACL_VDW_ETL
>>>>>>> Stashed changes
```

---

## ✅ How to Resolve

1. **Open the conflicted file** (e.g., `dbt_profile.yml`) in your editor (e.g., VS Code).

2. **Manually edit the file**:

   * Choose the correct value (e.g., `PROD_OMACL_VDW_ETL` for the `prod` environment).
   * Delete the conflict markers:

     ```diff
     <<<<<<< Updated upstream
     =======
     >>>>>>> Stashed changes
     ```

   ✅ Resulting line:

   ```yaml
   warehouse: PROD_OMACL_VDW_ETL
   ```

3. **Save the file** after editing.

4. **Mark the conflict as resolved** by staging the file:

   ```bash
   git add ../dbt_profile.yml
   ```

   Or, in VS Code, click the `+` next to the file in the Source Control panel under “Merge Changes”.

5. **Commit the resolution**:

   ```bash
   git commit -m "Resolve merge conflict in dbt_profile.yml"
   ```

---

## ✅ Final Check

Run `git status`. You should no longer see any merge conflicts, and your working tree should be clean.

---

## 📝 Summary

| Step               | Command / Action             |
| ------------------ | ---------------------------- |
| Stash changes      | `git stash -u`               |
| Rebase onto master | `git rebase master`          |
| Apply stash        | `git stash pop`              |
| Resolve conflicts  | Manually edit + `git add`    |
| Commit resolution  | `git commit -m "Resolve..."` |

---

## 📎 Tips

* Always review the context of the change before choosing which version to keep.
* Use your IDE’s conflict resolution tools (e.g., VS Code’s side-by-side view).
* You can always keep the stash (`stash pop` won't delete it if conflicts happen), so you can reapply it later if needed.

---
