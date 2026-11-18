# 00 · Git from zero (Start here, ~1.5h)

> **Guided version:** run `bash lab.sh` (it starts here). It teaches in tiny steps, with diagrams and one-key questions. This page is the reference.

**Goal:** save, inspect, undo, branch, merge and ignore, which covers most of daily Git. Everything happens in a throwaway repository (`playground/collab`), so you cannot hurt anything. The shortcut `g` means `git` inside it.

## The three places
```
your folder  --git add-->  staging area  --git commit-->  history (commits)
```

## Cheat sheet
| I want to... | Command |
|---|---|
| start a repo | `git init` |
| see what is going on | `git status` |
| get a file ready | `git add file` |
| save a snapshot | `git commit -m "message"` |
| see the history | `git log --oneline` |
| see my edits | `git diff` |
| throw away an unsaved edit | `git restore file` |
| try an idea safely | `git switch -c idea`, later `git merge idea` |
| keep a file out of Git | put its name in `.gitignore` |
| download / upload | `git clone url`, `git push`, `git pull` |

## Next
Module 01 (Linux, containers, HTTP) opens when you pass this module. Git collaboration (conflicts, rebase, bisect, code review) is module **19** and also opens right after this one.
