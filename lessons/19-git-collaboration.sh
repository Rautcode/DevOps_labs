# Git collaboration: conflicts, rebase, recovery, bisect and code review (about 2.5h)
title "Module 19 · Git collaboration"
mission "Real teams have many people changing the same code. Your mission: handle the situations that happen every week: a merge conflict, a messy history, a lost commit, and a bug that appeared sometime last week."
explain "Working in a team means branches, pull requests, reviews and the occasional mess. You will practise the situations that happen every week: merge conflicts, rebasing, losing a commit and getting it back, finding which commit broke something, and reviewing a risky change. Everything happens in a throwaway practice repository (playground/collab); the shortcut g means git inside it."

part "PART A · A practice repository"
learn "Your practice repo" "g is a shortcut for git -C playground/collab, so every g command runs inside the practice repository and cannot touch the lab itself. The practice repo has its own throwaway identity, so nothing you do here appears in your real history."
say "How do you practise risky Git operations safely?" "I use a throwaway repository, so I can try conflicts, rebases, resets and bisects without risking real work. Because everything is recorded in the reflog, I can also recover from my own mistakes, which builds confidence before I do the same on a shared repository."
step "Create the practice repository" "Initialized empty Git repository." ok 'nitialized' <<'CMD'
rm -rf playground/collab; git init -b main playground/collab
CMD
step "Give it a throwaway identity" "No output means success." <<'CMD'
g config user.name "Lab Student"; g config user.email student@example.com
CMD
step "Make the first commit" "A log with one commit: feat: first version." ok 'first version' <<'CMD'
echo v1 > playground/collab/app.txt; g add app.txt; g commit -qm "feat: first version"; g log --oneline
CMD

part "PART B · Branches and pull requests"
learn "Branches and pull requests" "A branch is an independent line of work, so experiments never disturb main. A pull request (PR) is a proposal to merge a branch, with a place for review and automatic checks. Good PRs are small, have a clear title and describe why. A merge commit (--no-ff) records that a branch was merged."
say "Describe your pull request workflow." "I create a branch from main, make small focused commits, push it and open a pull request. CI runs tests and scans, a teammate reviews, I address the feedback, and then it is merged, often with a squash. Branch protection on main requires passing checks and an approval, so nothing unreviewed or broken reaches it."
step "Start a feature branch and commit on it" "A graph with the feature commit on top of the first commit." ok 'greeting' <<'CMD'
g switch -c feature/greeting; echo hello >> playground/collab/app.txt; g commit -qam "feat: greeting"; g log --oneline --graph --all
CMD
step "Merge it back, keeping a merge commit" "Merge made by the 'ort' strategy." ok 'Merge made' <<'CMD'
g switch main; g merge --no-ff feature/greeting -m "merge: greeting"
CMD

part "PART C · Merge conflicts"
learn "Merge conflicts" "A conflict happens when two branches changed the SAME lines. Git cannot guess which you want, so it stops and writes both versions into the file between <<<<<<< and >>>>>>> markers. Your job: edit the file to the final text you want, remove every marker, git add the file and commit. Conflicts are normal, not an error in yourself."
say "How do you resolve a merge conflict?" "A conflict happens when two branches changed the same lines. Git marks the file with conflict markers; I open it, decide what the final content should be, remove the markers, stage the file and continue the merge or rebase. I run the tests afterwards, and for tricky conflicts I talk to the author of the other change."
step "Prepare two branches that disagree about conf.txt" "Two commits that both write conf.txt." ok 'feat: main' <<'CMD'
g switch -c feature/a; echo "A line" > playground/collab/conf.txt; g add conf.txt; g commit -qm "feat: a"; g switch main; echo "MAIN line" > playground/collab/conf.txt; g add conf.txt; g commit -qm "feat: main"; g log --oneline -2
CMD
step "Merge them: this is the conflict" "CONFLICT (add/add): Merge conflict in conf.txt. Git stops and waits for you." fail 'CONFLICT' <<'CMD'
g merge feature/a
CMD
step "Look at what Git wrote into the file" "<<<<<<< HEAD, your line, =======, the other line, >>>>>>> feature/a" ok '<<<<<<<' <<'CMD'
cat playground/collab/conf.txt
CMD
task "Resolve the conflict and finish the merge" "Make playground/collab/conf.txt contain BOTH lines (A line and MAIN line) with NO conflict markers. Then add it and commit the merge. Open the file with  edit playground/collab/conf.txt  . After saving run  g add conf.txt  and  g commit -m 'merge: resolve conflict' ." "The file should simply be two lines: A line and MAIN line. Then: g add conf.txt, then g commit -m \"merge: resolve conflict\". Check with g status (it must be clean)." <<'X'
! grep -q '<<<<<<<' playground/collab/conf.txt && grep -q 'A line' playground/collab/conf.txt && grep -q 'MAIN line' playground/collab/conf.txt && [ -z "$(g status --porcelain)" ] && [ "$(g log -1 --pretty=%P | wc -w | tr -d ' ')" = 2 ]
---
printf 'A line\nMAIN line\n' > playground/collab/conf.txt; g add conf.txt; g commit -qm "merge: resolve conflict"
X

part "PART D · Rebase"
learn "Merge versus rebase" "Merge keeps the true history and adds a merge commit. Rebase REPLAYS your commits on top of the latest main so history becomes a straight line, which is easier to read. The golden rule: never rebase a branch other people already use, because rebase rewrites commits. Rebase your own unpublished work only."
say "What is the difference between merge and rebase?" "Merge keeps the true history and adds a merge commit. Rebase replays my commits on top of the new base, which gives a straight, clean history but new commit IDs. So I rebase only my own unshared branches to tidy them, and I never rebase commits others already use, because rewriting shared history causes problems."
art "Merge vs rebase" <<'ART'
   MERGE   keeps the true history:   o--o--o----M      (M = merge commit)
                                         \    /
                                          o--o
   REBASE  replays your commits:     o--o--o--o'--o'   (straight line, new ids)
   Never rebase commits other people already have.
ART
mcq "When is it safe to rebase?" "On your own, not-yet-shared branch|On main|On a branch your teammates pulled|Never" 1 "Rebase rewrites commits, so only do it on work nobody else has."
step "Create a diverged feature branch" "A feature branch with one commit, while main moved on." ok 'feature/rebase' <<'CMD'
g switch -c feature/rebase; echo r1 > playground/collab/r.txt; g add r.txt; g commit -qm "feat: r1"; g switch main; echo m2 > playground/collab/m.txt; g add m.txt; g commit -qm "feat: m2"; g switch feature/rebase; g log --oneline --graph --all | head -6
CMD
step "Rebase the feature onto the new main" "Successfully rebased and updated refs/heads/feature/rebase." ok 'Successfully rebased' <<'CMD'
g rebase main
CMD
step "See the straight line" "No merge bubble: your commit now sits on top of main's newest commit." ok 'feat: r1' <<'CMD'
g log --oneline -4
CMD

part "PART E · Stash, cherry-pick and getting out of trouble"
learn "Stash, cherry-pick, reflog" "git stash parks unfinished work so you can switch branches, and stash pop brings it back. cherry-pick copies ONE commit onto another branch. And when you think you have destroyed work: git reflog lists every place HEAD has been, so a commit reset away is almost always recoverable."
say "What are stash, cherry-pick and reflog for?" "git stash parks unfinished work so I can switch branches. cherry-pick copies one specific commit onto another branch, which is handy for hotfixes. reflog records where HEAD has been, so even after a bad reset or a deleted branch I can find the old commit and recover it. Together they make me comfortable fixing mistakes."
step "Stash and restore unfinished work" "M app.txt appears, disappears while stashed, and comes back." ok 'M app.txt' <<'CMD'
g switch -q main; echo wip >> playground/collab/app.txt; g stash -q; g status --short; echo "--- after stash pop:"; g stash pop -q; g status --short
CMD
step "Cherry-pick one commit from another branch" "feat: r1 is now on main too." ok 'r1' <<'CMD'
g cherry-pick feature/rebase; g log --oneline -2
CMD
step "Break something on purpose and recover it" "The commit is back: same hash before and after. Nothing is lost while it is in the reflog." ok 'recovered' <<'CMD'
X=$(g rev-parse HEAD); g reset -q --hard HEAD~1; echo "after reset: $(g rev-parse --short HEAD)"; g reset -q --hard "$X"; echo "recovered: $(g rev-parse --short HEAD)"
CMD

part "PART F · Find the commit that broke it"
learn "git bisect" "When something that worked yesterday is broken today and there are many commits in between, do not read them all. git bisect does a binary search: you mark a good and a bad commit, Git checks out the middle, you test, and in about log2(n) steps it names the guilty commit. Give it a test script and it does everything automatically."
say "How do you find which commit introduced a bug?" "I use git bisect. I mark a known bad commit and a known good one, and Git checks out the middle commit; I test it and tell Git good or bad, and it halves the range each time. With a few hundred commits I find the culprit in about eight steps, and I can automate it with a test script."
step "Make 8 commits where a bug appears at commit 5" "Eight commits named change 1 to change 8." ok 'change 8' <<'CMD'
g switch -q -c bisect-demo; for i in 1 2 3 4 5 6 7 8; do if [ $i -ge 5 ]; then echo "bug $i" > playground/collab/state.txt; else echo "ok $i" > playground/collab/state.txt; fi; g add state.txt; g commit -qm "change $i"; done; g log --oneline | head -3
CMD
step "Let git bisect find the first bad commit automatically" "<hash> is the first bad commit: change 5. The test script says good when state.txt contains ok." ok 'first bad commit' <<'CMD'
g bisect start HEAD HEAD~7; g bisect run sh -c 'grep -q ok state.txt'
CMD
step "Leave bisect mode" "Back on the branch." <<'CMD'
g bisect reset
CMD
task "Report the guilty commit" "Run the bisect again (or read its output) and save ONLY the subject line of the first bad commit (for example change 3) into playground/bad.txt." "git log --format=%s -1 <hash> prints a commit's subject. The bisect output shows the hash." <<'X'
[ "$(tr -d '\r\n' < playground/bad.txt)" = "change 5" ]
---
echo "change 5" > playground/bad.txt
X

part "PART G · Reviewing someone else's change"
learn "How to review a pull request" "A good review checks: does it do what it says, is it tested, is it small enough to understand, does it expose a secret, can it be rolled back, is the naming clear? Comment on the code, not the person. Say what is wrong, why it matters and what you suggest. Security problems such as secrets and SQL built from strings are always blocking."
say "How do you review a pull request?" "I check that it does what the description says, that it is small and understandable, has tests, handles errors and security concerns like secrets or input validation, and fits the existing design. I give specific, kind, actionable comments, separate must-fix items from suggestions, and approve when I would be comfortable owning that code."
step "Read a risky change" "A diff that hard-codes a database password and builds SQL with string concatenation." ok 'password' <<'CMD'
cat 19-git/risky.diff
CMD
task "Write your review" "Create playground/review.md with your review comments. A strong review of this diff mentions the hard-coded password/secret, the SQL injection risk from building the query with a string, and the missing tests. Use  edit playground/review.md  ." "Words a reviewer would use: password, secret, environment variable, SQL injection, parameterised query, tests." <<'X'
f=playground/review.md; [ -f $f ] && grep -qiE 'password|secret|credential' $f && grep -qiE 'injection|parameter|concatenat' $f && grep -qi 'test' $f
---
printf '# Review\n- Blocking: the database password is hard-coded. Move the secret to an environment variable or a secret manager and rotate this password.\n- Blocking: the DELETE query is built with string concatenation, which allows SQL injection. Use a parameterised query.\n- Please add tests for cancel().\n' > playground/review.md
X
quiz "What does branch protection on main usually enforce?" "review|approv|status check|ci|no direct push|pull request|force" "It blocks direct pushes and force pushes to main and requires a pull request with passing checks and at least one approving review before merging."
quiz "Why write commit messages like feat: ... or fix: ... (Conventional Commits)?" "changelog|release|version|semantic|automat|readab|history|scan|categor" "A consistent prefix makes history easy to scan and lets tools generate changelogs and choose version numbers (feat = minor, fix = patch) automatically."

deeper "90 Days of DevOps (Shubham Londhe)|https://github.com/LondheShubham153/90DaysOfDevOps"
explain "Done! Git collaboration is what you do in every job, every day. Next: bash lab.sh 20"
