# Git from zero: save, undo and share your work (about 1.5h)
title "Module 00 · Git from zero"
mission "Day 1 on the team. Everyone here keeps their work in Git: it remembers every change, lets you undo mistakes, and lets many people work on one project without overwriting each other. Before you touch a single server, you learn it, one tiny step at a time. No experience needed."
rm -rf playground/collab

part "PART A · What is Git?"
learn "Git is a time machine for your files" "Imagine saving a document under new names: report-final, report-final2, report-REALLY-final. Git does that properly. Every time you say save, it takes a SNAPSHOT of your project (called a commit), with a message and a date. You can look at any old snapshot, compare versions, and go back. Teams use it so ten people can change one project safely."
say "What is Git and why do teams use it?" "Git is a version control system. Every time I commit, it saves a snapshot of the project with a message and an author, so I can see what changed, compare versions and go back if something breaks. Teams use it because many people can work on the same code at once, on separate branches, without overwriting each other, and every change can be reviewed."
art "Git has three places your files can be" <<'ART'
   YOUR FOLDER           STAGING AREA           THE HISTORY
   (files you edit)      (ready for the         (saved snapshots,
                          next snapshot)         called commits)

  +-------------+       +-------------+       +----------------+
  |  hello.txt  | ----> |  hello.txt  | ----> |  snapshot  #1  |
  |  (edited)   | git   |  (waiting)  | git   |  snapshot  #2  |
  +-------------+ add   +-------------+ commit|  snapshot  #3  |
                                              +----------------+
ART
mcq "Which command saves a snapshot into the history?" "git add|git commit|git status|git init" 2 "git add only gets files ready. git commit is the save button."
step "Check that Git is installed" "git version 2.something. If you see this, Git is ready." ok 'git version' <<'CMD'
git --version
CMD

part "PART B · Your first repository"
learn "A repository is just a folder Git is watching" "A repository (repo) is an ordinary folder with a hidden .git folder inside, where Git keeps its memory. git init creates it. The shortcut g in this lab means git inside the practice folder playground/collab, so nothing you do here can touch the lab itself."
say "What is a repository, and what does git init do?" "A repository is a normal project folder that Git is tracking. It has a hidden .git folder where Git keeps the whole history. git init creates it, and from then on I use git status, add and commit to record changes. The three places to remember are the working folder, the staging area and the commit history."
step "Turn a new folder into a repository" "Initialized empty Git repository. The folder playground/collab now has a hidden .git folder." ok 'nitialized' <<'CMD'
git init -b main playground/collab
CMD
step "Tell Git who you are (your name)" "No output means it worked. Every snapshot records who made it." <<'CMD'
g config user.name "Lab Student"
CMD
step "Tell Git your email" "No output again. Use any email for practice." <<'CMD'
g config user.email student@example.com
CMD
step "Ask Git what is going on" "On branch main, No commits yet, and nothing to commit. A new repo is empty." ok 'No commits yet' <<'CMD'
g status
CMD
predict "You are about to create a file called hello.txt. What will git status say about it?" "It will not notice the file|It lists it as untracked: new, and not watched yet|It saves the file automatically|It shows an error" 2 "Git does not watch a new file until you add it. That is on purpose: you choose what goes into a snapshot."
step "Create a file" "No output. A file called hello.txt now exists in the practice folder." <<'CMD'
echo "Hello Git" > playground/collab/hello.txt
CMD
step "Ask Git again" "Untracked files: hello.txt. Git sees it, but is not watching it yet." ok 'Untracked' <<'CMD'
g status
CMD
step "Get the file ready for a snapshot (stage it), then check" "Changes to be committed: new file: hello.txt. It is now in the staging area." ok 'new file' <<'CMD'
g add hello.txt; g status
CMD
step "Take the snapshot (commit)" "1 file changed, with your message Add hello file. Your first commit!" ok 'Add hello file' <<'CMD'
g commit -m "Add hello file"
CMD
step "Look at the history" "One line: a short code (the commit id) and your message." ok 'Add hello file' <<'CMD'
g log --oneline
CMD

part "PART C · Seeing what changed"
learn "Change, look, commit" "The everyday loop is: edit files, look at what changed with git diff, then commit. git diff shows lines that were added (starting with +) and removed (starting with -). Small commits with clear messages make history easy to read and easy to undo."
say "What does your everyday Git workflow look like?" "I edit files, check what changed with git status and git diff, stage only what belongs together with git add, and commit with a clear message that says what and why. I keep commits small, so the history is easy to read, easy to review and easy to undo if one of them turns out to be wrong."
step "Add a line to the file and look at the difference" "A green-style line starting with + : +A second line. That is the change Git sees." ok '\+A second line' <<'CMD'
echo "A second line" >> playground/collab/hello.txt; g diff
CMD
mcq "In a diff, what does a line starting with + mean?" "The line was added|The line was removed|The line is a comment|Something went wrong" 1 "Plus means added, minus means removed."
step "Commit the change (-a means: include every tracked file I edited)" "Your second commit." ok 'second line' <<'CMD'
g commit -am "Add a second line"
CMD
step "Look at the history again" "Two commits, newest on top." ok 'second line' <<'CMD'
g log --oneline
CMD

part "PART D · Undo a mistake"
learn "Nobody is afraid of mistakes in Git" "Because every snapshot is saved, an unwanted edit can be thrown away. git restore file puts a file back to its last saved version. (Later you will also meet git revert, which undoes a saved commit safely, and git reflog, which finds commits you thought you lost.)"
say "How do you undo a mistake in Git?" "It depends where the mistake is. For an unsaved edit I use git restore to bring a file back to the last commit. If a bad commit is already shared, I use git revert, which adds a new commit that undoes it, so history is not rewritten. And if I think I lost work, git reflog usually shows where it went."
step "Make a mess on purpose" "The file now only says oops." ok 'oops' <<'CMD'
echo "oops" > playground/collab/hello.txt; cat playground/collab/hello.txt
CMD
step "Ask Git what changed" "M hello.txt: modified. Git noticed." ok 'M hello.txt' <<'CMD'
g status --short
CMD
predict "What will git restore hello.txt do?" "Delete the file|Put the file back to its last saved version|Commit the mess|Nothing" 2 "restore throws away your unsaved edits and brings back the last commit's version."
step "Undo the mess" "Back to two lines: Hello Git and A second line." ok 'A second line' <<'CMD'
g restore hello.txt; cat playground/collab/hello.txt
CMD

part "PART E · Branches: safe places to try ideas"
learn "A branch is a parallel timeline" "A branch lets you try something without disturbing the main line of work. If the idea is good you merge it into main; if not you throw the branch away. Teams use one branch per feature or fix. main is the stable, shared line."
say "What is a branch, and why use one?" "A branch is a separate line of work. I create one per feature or fix with git switch -c, commit there without disturbing main, and merge it back when it is reviewed and ready. If the idea does not work out, I just delete the branch. It keeps main stable and lets several people work in parallel."
art "Branch and merge" <<'ART'
   main:   o-----o-----o-----------o      <- main now has the idea
                       \           /
   idea:                o----o----        <- you worked safely here
ART
step "Create a branch called idea and move onto it" "Switched to a new branch idea." ok 'idea' <<'CMD'
g switch -c idea
CMD
step "Add a file and commit it on this branch" "Your commit Add my idea, on the idea branch." ok 'Add my idea' <<'CMD'
echo "My idea" > playground/collab/idea.txt; g add idea.txt; g commit -m "Add my idea"
CMD
predict "You switch back to main. Will idea.txt still be in the folder?" "Yes, always|No: it only exists on the idea branch|It gets deleted forever|Git asks you" 2 "Switching branches changes the files in your folder to match that branch. The file is safe on the idea branch."
step "Go back to main and look at the folder" "hello.txt only. idea.txt has vanished from view (it is safe on the idea branch)." ok 'hello.txt' <<'CMD'
g switch main; ls playground/collab
CMD
step "Merge the idea into main" "Fast-forward: Git simply moved main forward. Now idea.txt is in the folder." ok 'idea.txt' <<'CMD'
g merge idea; ls playground/collab
CMD

part "PART F · Keep secrets out of Git"
learn "The .gitignore file" "Some files must never be committed: passwords, keys, .env files, huge downloads, build output. A file called .gitignore lists patterns Git should pretend not to see. Anything committed once stays in history forever, so set up .gitignore BEFORE you create secrets."
say "How do you keep secrets and build files out of Git?" "I list them in a .gitignore file before I create them, for example .env files, keys, node_modules and build output. The important point is that anything committed once stays in the history, so ignoring it afterwards is too late. If a secret is ever committed, I treat it as leaked and rotate it, rather than just deleting the file."
step "Create a fake secret and an ignore list, then check status" "Only .gitignore is listed. secret.env is invisible to Git: ignored." ok '\.gitignore' <<'CMD'
echo "PASSWORD=hunter2" > playground/collab/secret.env; echo "secret.env" > playground/collab/.gitignore; g status --short
CMD
step "Commit the ignore list itself" "Your commit Ignore secret.env. The secret itself is NOT committed." ok 'Ignore secret' <<'CMD'
g add .gitignore; g commit -m "Ignore secret.env"
CMD

part "PART G · Sharing: GitHub"
learn "Remotes, push and pull" "A remote is a copy of the repository on a server, usually GitHub. git clone downloads a repository the first time. git push sends your commits to it. git pull brings other people's commits to you. A pull request is a proposal on GitHub to merge your branch, with a place for review."
say "What is the difference between clone, push and pull?" "A remote, usually on GitHub, is a shared copy of the repository. git clone downloads it the first time. git push sends my commits to it, and git pull brings other people's commits to me. For team work I push a branch and open a pull request, so the change is reviewed before it is merged into main."
art "Sharing with a team" <<'ART'
   your laptop                GitHub                 teammate's laptop
  +-----------+   git push  +----------+   git pull  +-----------+
  | your repo | ----------> |  origin  | ----------> | their repo|
  +-----------+             +----------+             +-----------+
        ^                                                  |
        +---------------- git pull <-----------------------+
ART
step "This lab itself is a Git repository connected to GitHub. See where" "origin followed by a github.com address (fetch) and (push)." ok 'origin' <<'CMD'
git remote -v
CMD
mcq "Which command downloads a repository from GitHub for the first time?" "git push|git clone|git commit|git branch" 2 "clone copies the whole repository. push sends YOUR commits up."
mcq "Which command sends your commits to GitHub?" "git pull|git add|git push|git log" 3 "push uploads. pull downloads other people's work."

part "PART H · Your turn"
task "Make your own commit" "Create a file me.txt inside playground/collab that contains your name, stage it, and commit it with the message Add me. Type these three commands:  echo \"Your Name\" > playground/collab/me.txt   then   g add me.txt   then   g commit -m \"Add me\"  . Then type check." "Remember: create, add, commit. Use g (not git) so it runs in the practice repo." <<'X'
g log --oneline | grep -q "Add me" && g ls-files | grep -qx me.txt
---
echo "Lab Student" > playground/collab/me.txt; g add me.txt; g commit -qm "Add me"
X
task "Ignore every log file" "Make Git ignore ALL files ending in .log. Add the line *.log to the .gitignore file (use  edit playground/collab/.gitignore  or  echo \"*.log\" >> playground/collab/.gitignore ), create a file debug.log, commit the .gitignore, and git status must be clean (nothing to commit)." "After echo to .gitignore: g add .gitignore, g commit -m \"Ignore logs\". Then create debug.log. g status --short should print nothing." <<'X'
grep -q '\*.log' playground/collab/.gitignore && [ -f playground/collab/debug.log ] && [ -z "$(g status --porcelain)" ]
---
echo "*.log" >> playground/collab/.gitignore; g add .gitignore; g commit -qm "Ignore logs"; echo "x" > playground/collab/debug.log
X
quiz "Why is a clear commit message (like Add login page) better than a vague one (like stuff)?" "history|understand|find|later|team|read|why|what|search|review|undo" "Six months later, the message is the only explanation of why the change exists. Clear messages make history searchable and reviews faster."

deeper "90 Days of DevOps: Git days (Shubham Londhe)|https://github.com/LondheShubham153/90DaysOfDevOps"
explain "You can now save, inspect, undo, branch, merge and ignore, which covers most of daily Git. Next: the interview and final for this module, then module 01 (Linux, containers and HTTP). Git collaboration (conflicts, rebase, reviews) opens right after this module as module 19."
