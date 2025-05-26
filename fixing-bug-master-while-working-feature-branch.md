
---

# 🔧 Fixing a Bug in Master While Working on a Feature Branch (With Local Changes)

Here’s the **right approach** to fix a bug in the `master` branch **without losing or mixing up** your current work in `feature/elementary-config`, which contains **uncommitted and untracked changes**.

---

### 🧠 Situation:

* You’re working on `feature/elementary-config` with **local uncommitted + untracked changes** ✅
* You need to **quickly fix a bug in `master`** and push it as a new branch ✅
* After that, you want to come back and **continue work on your feature branch** ✅

---

### ✅ **Steps to Follow (Clean and Professional)**

Assuming you’re on `feature/elementary-config`:

---

#### 1. **Stash all current work, including new (untracked) files:**

```bash
git stash push --include-untracked -m "WIP on elementary-config"
```

---

#### 2. **Fetch latest changes and update your local `master`:**

```bash
git fetch origin
git checkout master
git pull origin master
```

---

#### 3. **Create a new branch from `master` to fix the bug:**

```bash
git checkout -b feature/excel-fix
```

---

#### 4. **Fix the bug, then commit your changes:**

```bash
git add .
git commit -m "Fix uc_ra_global_rmp_fr_timelines column line break"
```

---

#### 5. **Push the bugfix branch and create a pull request:**

```bash
git push --set-upstream origin feature/excel-fix
```

> 🎯 Now open a pull request to merge `feature/excel-fix` into `master`.

---

### ✅ After the Bugfix is Merged into Master

---

#### 6. **Update your local `master` again:**

```bash
git checkout master
git pull origin master
```

---

#### 7. **Switch back to your feature branch:**

```bash
git checkout feature/elementary-config
```

---

#### 8. **Rebase your feature branch on top of the updated `master`:**

```bash
git rebase master
```

> ⚠️ If conflicts occur:

```bash
git add <resolved-file>
git rebase --continue
```

> ❌ To cancel the rebase:

```bash
git rebase --abort
```

---

#### 9. **Apply your previously stashed changes:**

```bash
git stash pop
```

> 🛠️ Resolve any conflicts, stage, and commit if needed.


Common message after git stash pop:
```bash
Your branch and 'origin/feature/elementary-config' have diverged,
and have 6 and 1 different commits each, respectively.
```

This means:

* Your **local branch** has **6 commits** (the ones after your rebase).
* The **remote branch** (`origin/feature/elementary-config`) has **1 commit** that your local branch no longer contains (the old commit before the rebase).
* Git sees that the histories don’t match.

---

This is **exactly** what happens after a rebase on a pushed branch.

It’s not an error — it’s just Git saying:

> “Hey, your local and remote histories are different. Are you *sure* you want to push?”

And you respond confidently with:

```bash
git push --force-with-lease
```

Which means:

> “Yes, I know I rebased — please update the remote branch to match my local one, **but only if no one else has changed it**.”

---

🚨 What would cause problems?

Only if:

* Someone else pushed new commits to the remote **after your last fetch** and you blindly did `git push --force` (without `--with-lease`) — then you might overwrite their work.

But `--force-with-lease` protects you from that.

---

#### 10. **Continue working or push your updated feature branch:**

```bash
git add .
git commit -m "Continue work on feature/elementary-config"
git push --force-with-lease
```

> Use `--force-with-lease` only if you previously rebased and already pushed the branch.
> Safely overwrites the remote with your rebased version. But protects you if someone else pushed to the same branch while you were rebasing. So it’s like saying: “Only force-push if no one else has changed this branch since I last fetched.”
> “Yes, I know I rebased — please update the remote branch to match my local one, but only if no one else has changed it.”


❌ Why not git push?
- A normal git push will fail here because of the diverged history.
- It will tell you to pull first — but you shouldn’t pull after a rebase (that would mess up your clean history).

❌ Why not --force?
- git push --force will overwrite the remote no matter what, even if someone else pushed changes in the meantime.
- It’s dangerous in team environments.
---

### ✅ Git Commands Summary (Copy-Paste Version):

```bash
# Save current feature work
git stash push --include-untracked -m "WIP on elementary-config"

# Create and push bugfix branch
git fetch origin
git checkout master
git pull origin master
git checkout -b feature/excel-fix
git add .
git commit -m "Fix uc_ra_global_rmp_fr_timelines column line break"
git push --set-upstream origin feature/excel-fix

# After merging bugfix PR
git checkout master
git pull origin master
git checkout feature/elementary-config
git rebase master
git stash pop
git add .
git commit -m "Continue work on feature/elementary-config"
git push --force-with-lease
```

---

### 💡 Why This Is Best Practice

* Keeps bugfix **isolated and easy to review**
* Avoids mixing half-done work with urgent hotfixes
* Maintains a **clean, linear history**
* Safeguards your local changes with `stash`

---