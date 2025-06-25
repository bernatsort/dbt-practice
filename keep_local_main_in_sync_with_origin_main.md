## 🧾 Keeping Your Local `main` in Sync with `origin/main` (CodeCommit)

### 🧠 Objective:

Keep your local `main` branch fully up to date with `origin/main` from AWS CodeCommit, especially when you haven’t made any local changes.

---

## 🔍 When to Use This

You should follow this guide if:

* You haven’t made any local changes or commits.
* You want to work with the latest version of the code from CodeCommit.
* You want to avoid unnecessary merge commits or confusion.

---

## ✅ Preferred Approach: `git pull origin main`

```bash
git checkout main
git pull origin main
```

### What it does:

* Fetches the latest changes from the remote (`origin/main`).
* Fast-forwards your local `main` to match.
* Safe to run, even if you *accidentally* have local commits — Git will merge or prompt you.

### When to use:

* ✅ Recommended if you're not 100% sure whether you have local changes.
* ✅ Safer for day-to-day use.

---

## 🔄 Alternative Approach: `git reset --hard origin/main`

```bash
git fetch origin
git reset --hard origin/main
```

### What it does:

* Fetches the latest changes from the remote.
* Forcefully makes your local `main` **exactly** like `origin/main`.
* Deletes any local commits or uncommitted changes.

### When to use:

* ⚠️ Only if you are **absolutely sure** you have no local changes or commits.
* ✅ Very clean and direct when you want to mirror the remote branch.

---

## ✅ How to Check Before Resetting

```bash
git status
```

If it says:

```
On branch main
nothing to commit, working tree clean
Your branch is behind 'origin/main' by X commits, and can be fast-forwarded.
```

Then it's safe to use **either** method.

---

## 💬 TL;DR

| Situation                          | Recommended Command                                |
| ---------------------------------- | -------------------------------------------------- |
| No local changes, want latest code | `git pull origin main`                             |
| Want a clean mirror of origin/main | `git fetch origin && git reset --hard origin/main` |
| Not sure if local changes exist    | `git pull origin main` (safer)                     |

---

## 🛡️ Extra Tip: Create a Git Alias for Fast Sync

```bash
git config --global alias.sync '!git fetch origin && git reset --hard origin/main'
```

Then use:

```bash
git sync
```

To quickly update your local `main` to match the remote.

