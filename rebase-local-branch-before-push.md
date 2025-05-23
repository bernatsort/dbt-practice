# Rebasing a Local Branch on Updated Master Before Pushing to Remote
Here's the **right approach** to get your local branch up-to-date with the latest changes from `master` (which now includes your colleague's work), **without losing your local work**:

---

### ✅ **Steps to Follow (Safe and Clean)**

Assuming your local branch is called `feature/my-branch`:

1. **Stash (optional but recommended):**
   If you have *unstaged* changes and want to be extra safe:

   ```bash
   git stash
   ```

2. **Fetch the latest from the remote:**

   ```bash
   git fetch origin
   ```

3. **Switch to `master` and update it:**

   ```bash
   git checkout master
   git pull origin master
   ```

4. **Switch back to your local branch:**

   ```bash
   git checkout feature/my-branch
   ```

5. **Rebase your branch on top of the latest master (preferred for clean history):**
    Rebased feature/elementary-config onto master — clean history, up to date.

   ```bash
   git rebase master
   ```

   > If there are conflicts, Git will pause and let you resolve them. After resolving each conflict:

   ```bash
   git add <resolved-files>
   git rebase --continue
   ```

   If you want to cancel the rebase midway for any reason:

   ```bash
   git rebase --abort
   ```

6. **Apply your stashed changes if you did step 1:**

   ```bash
   git stash pop
   ```

7. **Now you're ready to push your branch (first time, so use `--set-upstream`):**
    
    When you create a new local branch, Git doesn’t automatically know which remote branch it should link (track) it to — because that remote branch doesn’t exist yet.
    
    --set-upstream (or shorthand -u) does this:
    
    It tells Git: "Hey Git, from now on, when I run git pull or git push from this branch, I want you to link it to the remote branch origin/feature/elementary-config."
    
    Later on, you can just use:
        
        git push
        git pull

    No need to type origin feature/elementary-config every time.


   ```bash
   git add .
   git commit -m "your commit message"
   git push --set-upstream origin feature/my-branch
   ```

---

### ❓Why Rebase Instead of Merge?

Rebase is usually preferred when you're updating a feature branch before pushing it, especially if it's still local. It:

* Keeps the history clean and linear
* Applies your changes *on top of* the latest `master`

---

Let me know if you want a diagram or Git command explanation for any step!




### ✅ Git commands (assuming your branch is `my-feature-branch`):

```bash
# 1. Save any unstaged changes (optional but safe)
git stash

# 2. Download latest changes from Bitbucket
git fetch origin

# 3. Update your local master with the latest from Bitbucket
git checkout master
git pull origin master

# 4. Switch back to your local branch
git checkout my-feature-branch

# 5. Rebase your branch on top of the updated master
git rebase master

# 6. Apply your stashed changes, if any
git stash pop

# 7. Push your branch to Bitbucket for the first time
git push --set-upstream origin my-feature-branch
```

---
