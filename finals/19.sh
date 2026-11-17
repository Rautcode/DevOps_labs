# Module 19 · interview and final (sourced by lab.sh)
# helpers: build a fresh practice repo and add commits quickly
mkrepo() { rm -rf playground/collab; git init -q -b main playground/collab; g config user.name "Lab Student"; g config user.email student@example.com; }
cm() { echo "$2" > "playground/collab/$1"; g add "$1"; g commit -qm "$3"; }

part "PART · INTERVIEW"

interview "A conflict during a merge" "Interviewer: 'Two people changed the same line of settings.txt. A merge of the branch feature is in progress and stopped with a conflict. Resolve it so the file contains BOTH settings (retries=3 and timeout=30, one per line, no conflict markers) and finish the merge.'" "Open playground/collab/settings.txt with edit, keep both lines, remove the markers, then g add settings.txt and g commit -m \"merge: settings\"." <<'X'
mkrepo; cm settings.txt "base" "chore: base"; g switch -q -c feature; cm settings.txt "retries=3" "feat: retries"; g switch -q main; cm settings.txt "timeout=30" "feat: timeout"; g merge feature >/dev/null 2>&1; true
---
f=playground/collab/settings.txt; ! grep -q '<<<<<<<' $f && grep -q 'retries=3' $f && grep -q 'timeout=30' $f && [ -z "$(g status --porcelain)" ] && [ "$(g log -1 --pretty=%P | wc -w | tr -d ' ')" = 2 ]
---
printf 'retries=3\ntimeout=30\n' > playground/collab/settings.txt; g add settings.txt; g commit -qm "merge: settings"
X

interview "I deleted my work" "Interviewer: 'A teammate ran a hard reset and the commit with the payroll fix vanished from the history. It is not on any branch any more. Get it back on the current branch.'" "git reflog lists where HEAD has been. Then  g reset --hard <the hash from before the reset>  or  g reset --hard HEAD@{1}  ." <<'X'
mkrepo; cm a.txt 1 "feat: one"; cm b.txt 2 "fix: payroll fix"; g reset -q --hard HEAD~1
---
g log --oneline | grep -q 'payroll fix'
---
g reset -q --hard 'HEAD@{1}'
X

part "PART · MODULE FINAL"

final "A straight history" "Exam 1 of 3. The branch feature has two commits that were made before main moved on. Bring feature up to date on top of main WITHOUT creating a merge commit (history must stay a straight line). main must be an ancestor of feature and feature must contain no merge commits." "On the feature branch run  g rebase main" <<'X'
mkrepo; cm base.txt 1 "chore: base"; g switch -q -c feature; cm f1.txt 1 "feat: f1"; cm f2.txt 1 "feat: f2"; g switch -q main; cm m.txt 1 "feat: main moved"
---
g merge-base --is-ancestor main feature && [ "$(g log feature --merges --oneline | wc -l | tr -d ' ')" = 0 ] && [ "$(g log feature --oneline | wc -l | tr -d ' ')" = 4 ]
---
g switch -q feature; g rebase main >/dev/null 2>&1
X

final "Find the culprit" "Exam 2 of 3. Ten commits exist, named change 1 to change 10. Version file state.txt says ok in the early ones and bug in the later ones. Find the FIRST commit that contains the bug and save its subject (for example change 3) into playground/culprit.txt." "g bisect start HEAD <first commit> then g bisect run sh -c 'grep -q ok state.txt'. Or read the log and test by hand." <<'X'
mkrepo; for i in 1 2 3 4 5 6 7 8 9 10; do if [ $i -ge 7 ]; then v=bug; else v=ok; fi; cm state.txt "$v $i" "change $i"; done; rm -f playground/culprit.txt
---
[ "$(tr -d '\r\n' < playground/culprit.txt)" = "change 7" ]
---
echo "change 7" > playground/culprit.txt
X

final "Undo it without rewriting history" "Exam 3 of 3. The last commit on main (oops: remove tests) was already pushed and shared, and it deleted tests.txt. Undo it SAFELY: the history must not be rewritten, tests.txt must be back, and the newest commit message must start with Revert." "g revert --no-edit HEAD" <<'X'
mkrepo; cm tests.txt "the tests" "feat: add tests"; g rm -q tests.txt; g commit -qm "oops: remove tests"
---
[ -f playground/collab/tests.txt ] && g log -1 --pretty=%s | grep -q '^Revert'
---
g revert --no-edit HEAD >/dev/null 2>&1
X
