# 19 · Git collaboration (Extra, ~2.5h)

> **Guided version:** run `bash lab.sh 19` from the repo root. It explains each step, has you type the commands yourself, and checks your hands-on tasks. This page is the reference. **Unlocks after module 01.**

**Goal:** work in a team: branches, pull requests, merge conflicts, rebase, recovering lost work, finding which commit broke something, and reviewing a risky change.

| File | What it is |
|---|---|
| [risky.diff](risky.diff) | a deliberately bad pull request to review (hard-coded password, SQL built from a string, no tests) |

The shortcut `g CMD` runs `git CMD` inside the throwaway repo `playground/collab`, so the lab's own history is never touched.

## Cheat sheet
| Situation | Command |
|---|---|
| New line of work | `git switch -c feature/x` |
| Merge keeping a merge commit | `git merge --no-ff feature/x` |
| Conflict | edit the file, remove `<<<<<<<`, `=======`, `>>>>>>>`, then `git add` and `git commit` |
| Straight history | `git rebase main` (only for branches nobody else uses) |
| Park unfinished work | `git stash`, `git stash pop` |
| Copy one commit | `git cherry-pick <hash>` |
| I lost a commit | `git reflog`, then `git reset --hard <hash>` |
| Undo a shared commit safely | `git revert <hash>` |
| Which commit broke it | `git bisect start <bad> <good>` then `git bisect run <test>` |

## Reviewing a pull request
Check: does it do what it says, is it tested, small enough to understand, any secret or injection risk, can it be rolled back, is it clearly named? Comment on the code, not the person: say what, why and a suggestion. Security problems are always blocking.

## Break it
1. Create the same conflict three times until resolving it feels routine.
2. `git reset --hard HEAD~3` on purpose, then recover everything with the reflog.
3. Rebase a branch that you already pushed, and think about what it would do to a teammate.

## Industry notes
Use short-lived branches, small pull requests, Conventional Commits (`feat:`, `fix:`) and branch protection on main (required review and passing checks, no force pushes). Never rewrite shared history.
