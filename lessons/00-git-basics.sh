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
why "git::the program|--version::ask it to print its version number" "Before anything else, make sure the tool exists. If you see a version number, Git is installed and ready. If you see an error, nothing else in this module will work, so it is the cheapest check you can do."
step "Check that Git is installed" "git version 2.something. If you see this, Git is ready." ok 'git version' <<'CMD'
git --version
CMD

part "PART B · Your first repository"
learn "A repository is just a folder Git is watching" "A repository (repo) is an ordinary folder with a hidden .git folder inside, where Git keeps its memory. git init creates it. The shortcut g in this lab means git inside the practice folder playground/collab, so nothing you do here can touch the lab itself."
say "What is a repository, and what does git init do?" "A repository is a normal project folder that Git is tracking. It has a hidden .git folder where Git keeps the whole history. git init creates it, and from then on I use git status, add and commit to record changes. The three places to remember are the working folder, the staging area and the commit history."
why "git init::start tracking a folder|-b main::name the first branch main|playground/collab::the folder to turn into a repository" "A normal folder is just files. git init adds a hidden .git folder inside it, which is where Git keeps its memory. After this, Git can remember every change you make in that folder. You do it once per project. (If you see Reinitialized, the folder already was a repository. That is harmless.)"
step "Turn a new folder into a repository" "Initialized empty Git repository. The folder playground/collab now has a hidden .git folder." ok 'nitialized' <<'CMD'
git init -b main playground/collab
CMD
why "g::this lab's shortcut for git, run inside the practice folder|config::change a Git setting|user.name::the setting: the name Git writes on your work|\"Lab Student\"::the value (quotes because it has a space)" "Think of signing your name on every page you write. Each snapshot you save (a commit) is stamped with who made it, so Git has to know your name first. It prints nothing when it works. Here it is set only for the practice folder; adding --global would set it for every project on your computer."
step "Tell Git who you are (your name)" "No output means it worked. Every snapshot records who made it." <<'CMD'
g config user.name "Lab Student"
CMD
say "What does git config user.name do, and why does it matter?" "It sets the author name Git records in every commit, together with the email. I set it once globally on my machine, or per repository if I use different identities, like work and personal. It matters because history shows who changed what and when, which gives accountability, makes code review easier, and lets me trace any change back to its author."
why "g config::change a Git setting|user.email::the setting: the email Git writes next to your name|student@example.com::a made-up practice address (example.com cannot belong to anyone)" "Your name says who you are and your email says how to reach you. Together they are the signature on every commit. On a real project, GitHub matches the email to your account, so your work is credited to you. It prints nothing when it works. A fake address is fine here because the practice folder never leaves your computer."
step "Tell Git your email" "No output again. Use any email for practice." <<'CMD'
g config user.email student@example.com
CMD
say "Why does Git need your email as well as your name, and what happens if it is wrong?" "Git stores the author name and email in every commit. The name tells people who made the change and the email lets them contact me. Platforms like GitHub also use the email to link commits to my account, so a wrong one means my work is not credited to me. I check which email is set before committing, and I use a no-reply address if I do not want to publish my real one, because it stays in the history permanently."
why "g status::show the state of the folder: what is new, changed or waiting to be saved" "git status is the command you will type most. It answers three questions: which branch am I on, what has changed, and what is ready to be saved. Use it before and after almost everything so you never have to guess."
step "Ask Git what is going on" "On branch main, No commits yet, and nothing to commit. A new repo is empty." ok 'No commits yet' <<'CMD'
g status
CMD
predict "You are about to create a file called hello.txt. What will git status say about it?" "It will not notice the file|It lists it as untracked: new, and not watched yet|It saves the file automatically|It shows an error" 2 "Git does not watch a new file until you add it. That is on purpose: you choose what goes into a snapshot."
why "echo \"Hello Git\"::print the text Hello Git|>::send that text into a file instead of the screen|playground/collab/hello.txt::the file to create inside the practice folder" "Git needs something to track, so we make a small file. This is an ordinary shell command, not a Git command. Notice that Git does not notice the file by itself: you will see that next."
step "Create a file" "No output. A file called hello.txt now exists in the practice folder." <<'CMD'
echo "Hello Git" > playground/collab/hello.txt
CMD
why "g status::show the state of the folder" "Now Git sees a file it does not know yet and calls it untracked. That is on purpose: Git never saves a file until you choose to. You decide exactly what goes into each snapshot."
step "Ask Git again" "Untracked files: hello.txt. Git sees it, but is not watching it yet." ok 'Untracked' <<'CMD'
g status
CMD
why "g add hello.txt::put this file in the staging area|;::then run the next command|g status::check the result" "Saving in Git takes two steps: first pick what goes into the snapshot (add), then save it (commit). The staging area is the tray where you place the files for the next snapshot. It lets you commit only the files that belong together, even if you changed many."
step "Get the file ready for a snapshot (stage it), then check" "Changes to be committed: new file: hello.txt. It is now in the staging area." ok 'new file' <<'CMD'
g add hello.txt; g status
CMD
why "g commit::save a snapshot of everything in the staging area|-m::attach a message|\"Add hello file\"::the message, a short note saying what this snapshot is" "This is the save button. The snapshot keeps the exact state of your staged files, plus your name, the time and your message. Write messages that tell your future self what changed and why, because the message is how you find things later."
step "Take the snapshot (commit)" "1 file changed, with your message Add hello file. Your first commit!" ok 'Add hello file' <<'CMD'
g commit -m "Add hello file"
CMD
why "g log::show the list of past snapshots|--oneline::one short line per snapshot" "The log is the time machine view: every snapshot you saved, newest first. The short code at the start of each line is the snapshot's id. With --oneline you get the id and the message, which is usually all you need."
step "Look at the history" "One line: a short code (the commit id) and your message." ok 'Add hello file' <<'CMD'
g log --oneline
CMD

part "PART C · Seeing what changed"
learn "Change, look, commit" "The everyday loop is: edit files, look at what changed with git diff, then commit. git diff shows lines that were added (starting with +) and removed (starting with -). Small commits with clear messages make history easy to read and easy to undo."
say "What does your everyday Git workflow look like?" "I edit files, check what changed with git status and git diff, stage only what belongs together with git add, and commit with a clear message that says what and why. I keep commits small, so the history is easy to read, easy to review and easy to undo if one of them turns out to be wrong."
why "echo \"A second line\" >> ...::add text to the END of the file (>> adds, > would replace)|g diff::show exactly what changed since the last snapshot" "Before you save a change, look at it. A line starting with + was added and a line starting with - was removed. Reading the diff catches mistakes while they are still small, and it is the habit reviewers expect before a commit."
step "Add a line to the file and look at the difference" "A green-style line starting with + : +A second line. That is the change Git sees." ok '\+A second line' <<'CMD'
echo "A second line" >> playground/collab/hello.txt; g diff
CMD
mcq "In a diff, what does a line starting with + mean?" "The line was added|The line was removed|The line is a comment|Something went wrong" 1 "Plus means added, minus means removed."
why "g commit::save a snapshot|-a::include every tracked file I changed, so no separate add is needed|-m \"...\"::the message" "-a is a shortcut for files Git already tracks: it stages and commits their changes in one go. It does not pick up brand-new files, which still need git add. Small commits like this make history easy to read and easy to undo."
step "Commit the change (-a means: include every tracked file I edited)" "Your second commit." ok 'second line' <<'CMD'
g commit -am "Add a second line"
CMD
why "g log --oneline::the list of snapshots, short form" "Check that the new snapshot is there. You should now see two, with the newest on top. Looking at the log after a commit is a quick way to confirm it really was saved."
step "Look at the history again" "Two commits, newest on top." ok 'second line' <<'CMD'
g log --oneline
CMD

part "PART D · Undo a mistake"
learn "Nobody is afraid of mistakes in Git" "Because every snapshot is saved, an unwanted edit can be thrown away. git restore file puts a file back to its last saved version. (Later you will also meet git revert, which undoes a saved commit safely, and git reflog, which finds commits you thought you lost.)"
say "How do you undo a mistake in Git?" "It depends where the mistake is. For an unsaved edit I use git restore to bring a file back to the last commit. If a bad commit is already shared, I use git revert, which adds a new commit that undoes it, so history is not rewritten. And if I think I lost work, git reflog usually shows where it went."
why "echo \"oops\" > ...::REPLACE the whole file with the word oops|cat::print the file" "We damage the file on purpose so you can practise the fix. The single > replaces everything in the file, which is how real accidents happen. Do not worry: the good version is safe in your last snapshot."
step "Make a mess on purpose" "The file now only says oops." ok 'oops' <<'CMD'
echo "oops" > playground/collab/hello.txt; cat playground/collab/hello.txt
CMD
why "g status --short::the state of the folder in a compact form|M::means Modified: a tracked file was changed" "Git compares the folder with the last snapshot and tells you which files differ. This is how you notice an accident quickly, before you commit it."
step "Ask Git what changed" "M hello.txt: modified. Git noticed." ok 'M hello.txt' <<'CMD'
g status --short
CMD
predict "What will git restore hello.txt do?" "Delete the file|Put the file back to its last saved version|Commit the mess|Nothing" 2 "restore throws away your unsaved edits and brings back the last commit's version."
why "g restore hello.txt::throw away my unsaved changes and bring back the last saved version of this file" "This is the undo for edits you have not committed. Because every snapshot is saved, nothing is lost. Be careful with it: restore throws your unsaved edits away, so use it only when you really want them gone."
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
why "g switch::move to another branch|-c idea::create it first, and call it idea" "A branch is a safe copy of your line of work. Try ideas there and the main line stays untouched. If the idea is bad you delete the branch; if it is good you merge it back. Teams make one branch per feature or fix."
step "Create a branch called idea and move onto it" "Switched to a new branch idea." ok 'idea' <<'CMD'
g switch -c idea
CMD
why "echo ... > idea.txt::create a new file|g add idea.txt::stage it|g commit -m \"...\"::save it" "This is the same create, add, commit routine, but now the snapshot belongs to the idea branch only. The main branch does not know about it yet."
step "Add a file and commit it on this branch" "Your commit Add my idea, on the idea branch." ok 'Add my idea' <<'CMD'
echo "My idea" > playground/collab/idea.txt; g add idea.txt; g commit -m "Add my idea"
CMD
predict "You switch back to main. Will idea.txt still be in the folder?" "Yes, always|No: it only exists on the idea branch|It gets deleted forever|Git asks you" 2 "Switching branches changes the files in your folder to match that branch. The file is safe on the idea branch."
why "g switch main::move back to the main branch|ls::list the files in the folder" "Switching branches changes the files in your folder to match the branch. idea.txt seems to vanish, but it is safe on the idea branch. This is how one folder can hold several parallel versions of your work."
step "Go back to main and look at the folder" "hello.txt only. idea.txt has vanished from view (it is safe on the idea branch)." ok 'hello.txt' <<'CMD'
g switch main; ls playground/collab
CMD
why "g merge idea::bring the changes of the idea branch into the branch I am on (main)|ls::list the files again" "Merging joins the finished work back into main. Here it is a fast-forward: Git just moves main forward to the idea snapshot, because main had not changed. Real teams merge through a pull request so someone reviews the change first."
step "Merge the idea into main" "Fast-forward: Git simply moved main forward. Now idea.txt is in the folder." ok 'idea.txt' <<'CMD'
g merge idea; ls playground/collab
CMD

part "PART F · Keep secrets out of Git"
learn "The .gitignore file" "Some files must never be committed: passwords, keys, .env files, huge downloads, build output. A file called .gitignore lists patterns Git should pretend not to see. Anything committed once stays in history forever, so set up .gitignore BEFORE you create secrets."
say "How do you keep secrets and build files out of Git?" "I list them in a .gitignore file before I create them, for example .env files, keys, node_modules and build output. The important point is that anything committed once stays in the history, so ignoring it afterwards is too late. If a secret is ever committed, I treat it as leaked and rotate it, rather than just deleting the file."
why "secret.env::a pretend password file|.gitignore::a list of file names Git should pretend not to see|g status --short::check what Git sees" "Passwords and keys must never be committed, because anything saved in Git stays in its history forever. Listing a file in .gitignore tells Git to leave it alone. Do this before you create real secrets. Notice that secret.env does not show up in the status."
step "Create a fake secret and an ignore list, then check status" "Only .gitignore is listed. secret.env is invisible to Git: ignored." ok '\.gitignore' <<'CMD'
echo "PASSWORD=hunter2" > playground/collab/secret.env; echo "secret.env" > playground/collab/.gitignore; g status --short
CMD
why "g add .gitignore::stage the ignore list|g commit -m \"...\"::save it" "The ignore list is part of the project, so teammates need it too. Committing it means everybody ignores the same files. The secret file itself is not committed."
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
why "git remote::the list of other copies of this repository|-v::verbose: show the web addresses" "A remote is a copy of the repository on a server, usually GitHub. origin is the default name for it. This command only looks; it changes nothing. It is how you check where your push and pull go."
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
