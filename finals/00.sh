# Module 00 · interview and final (sourced by lab.sh)
mkrepo() { rm -rf playground/collab; git init -q -b main playground/collab; g config user.name "Lab Student"; g config user.email student@example.com; }
cm() { echo "$2" > "playground/collab/$1"; g add "$1"; g commit -qm "$3"; }

part "PART · INTERVIEW"

interview "Your first snapshot" "Interviewer: 'Welcome. Let us start simple. There is an empty practice repository. Create a file called notes.txt with any text in it, and save it as a commit with the message first notes. Then Git must report that nothing is left uncommitted.'" "Three steps: create the file, g add notes.txt, g commit -m \"first notes\" . Use g, which means git inside the practice repo." <<'X'
mkrepo
---
g log --oneline | grep -q "first notes" && g ls-files | grep -qx notes.txt && [ -z "$(g status --porcelain)" ]
---
echo "my notes" > playground/collab/notes.txt; g add notes.txt; g commit -qm "first notes"
X

interview "Rescue an overwritten file" "Interviewer: 'A teammate's editor just overwrote todo.txt with garbage. The good version was already committed. Get it back, without making a new commit and without losing any history.'" "git restore <file> brings back the last saved version. Use g restore todo.txt" <<'X'
mkrepo; cm todo.txt "buy milk" "add todo"; echo "DELETE EVERYTHING" > playground/collab/todo.txt
---
grep -q "buy milk" playground/collab/todo.txt && [ -z "$(g status --porcelain)" ] && [ "$(g rev-list --count HEAD)" = 1 ]
---
g restore todo.txt
X

part "PART · MODULE FINAL"

final "Work on a branch" "Exam 1 of 3. Create a branch called feature-login. On that branch create the file login.txt and commit it. The main branch must NOT contain login.txt." "g switch -c feature-login, create the file, g add, g commit. Then g switch main to see it vanish." <<'X'
mkrepo; cm base.txt 1 "chore: base"
---
g ls-tree -r --name-only feature-login 2>/dev/null | grep -qx login.txt && ! g ls-tree -r --name-only main | grep -qx login.txt
---
g switch -q -c feature-login; echo "login" > playground/collab/login.txt; g add login.txt; g commit -qm "feat: login"; g switch -q main
X

final "Keep the secret out" "Exam 2 of 3. The folder contains app.txt and a secret file .env. Make sure .env can NEVER be committed (tell Git to ignore it), and commit app.txt and the ignore list. Afterwards .env must not be tracked, and Git must report it as ignored." "Put the line .env in a file called .gitignore, then add .gitignore and app.txt and commit. Check with: g check-ignore .env" <<'X'
mkrepo; echo "hello" > playground/collab/app.txt; echo "TOKEN=abc123" > playground/collab/.env
---
g check-ignore .env >/dev/null 2>&1 && ! g ls-files | grep -qx .env && g ls-files | grep -qx app.txt && g ls-files | grep -qx .gitignore
---
echo ".env" > playground/collab/.gitignore; g add .gitignore app.txt; g commit -qm "feat: app and ignore"
X

final "Read the history" "Exam 3 of 3. The repository has three commits. Find the message of the very FIRST (oldest) commit and save only that message into playground/first.txt." "g log --oneline shows newest first, so the oldest is at the bottom. g log --format=%s prints just the messages." <<'X'
mkrepo; cm a.txt 1 "start of the project"; cm b.txt 2 "second change"; cm c.txt 3 "third change"; rm -f playground/first.txt
---
[ "$(tr -d '\r\n' < playground/first.txt)" = "start of the project" ]
---
g log --format=%s | tail -1 > playground/first.txt
X
