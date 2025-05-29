---

# 🔁 Rebasing an **Already Pushed Branch** on Updated Master (with Local Changes)

Here’s the **right approach** to update your already pushed feature branch (`feature/elementary-config`) with the latest changes from `master` — **without losing your local uncommitted work** and while keeping a **clean Git history**.

---

### 🧠 Situation:

* Your branch `feature/elementary-config` is **already pushed to Bitbucket** ✅
* You have **local uncommitted changes** (modified files, new files, etc.) ✅
* Someone **just merged into `master`**, and you want your branch to be up to date ✅

---

### ✅ **Steps to Follow (Safe, Clean, Real-World Tested)**

Assuming you're on `feature/elementary-config`:

---

#### 1. **Stash all local changes — including new files:**

```bash
git stash push --include-untracked -m "WIP before rebase"
```
or just: 
```bash
git stash --include-untracked
```
or:
```bash
git stash -u
```

> This safely stashes modified, staged, unstaged, and untracked (new) files.

---

#### 2. **Fetch the latest changes from remote:**

```bash
git fetch origin
```

---

#### 3. **Update your local master:**

```bash
git checkout master
git pull origin master
```

---

#### 4. **Switch back to your feature branch:**

```bash
git checkout feature/elementary-config
```

---

#### 5. **Rebase your branch onto updated master:**

```bash
git rebase master
```

> ⚠️ If conflicts occur, Git will pause:

```bash
git add <resolved-file>
git rebase --continue
```

> Or cancel if needed:

```bash
git rebase --abort
```

---

#### 6. **Apply your stashed changes:**

```bash
git stash pop
```

> ⚠️ You may get merge conflicts here too — resolve them and continue as normal.

---

#### 7. **Commit the restored changes (if needed):**

```bash
git add .
git commit -m "Continue work on feature/elementary-config"
```

> Only do this if `stash pop` brought back uncommitted changes you want to finalize.

---

#### 8. **Push your rebased branch — safely overwriting remote:**

```bash
git push origin feature/elementary-config --force-with-lease
```

> This is needed because the rebase rewrites history.
> `--force-with-lease` ensures no one else has pushed changes while you were rebasing.

---

### ❓ Why `rebase` and not `merge`?

Rebasing:

* Keeps a **linear**, clean commit history.
* Makes your feature branch look like it was created *after* the latest `master`.
* Is perfect when collaborating and reviewing via pull requests.

---

### ✅ Git commands (quick copy-paste):

```bash
# 1. Stash everything (tracked + untracked)
git stash push --include-untracked -m "WIP before rebase"

# 2. Get latest changes from remote
git fetch origin

# 3. Update local master
git checkout master
git pull origin master

# 4. Rebase your branch onto master
git checkout feature/elementary-config
git rebase master

# 5. Restore local changes
git stash pop

# 6. Commit if needed
git add .
git commit -m "Continue work on feature/elementary-config"

# 7. Push the rebased branch
git push --force-with-lease
```

---

Let me know if you'd like this as a printable cheatsheet or Git alias setup!
