# Linux administration: users, permissions, processes, disk, cron, systemd (about 3h)
title "Module 18 · Linux administration"
mission "Almost every incident ends on a Linux server. Your mission: on a throwaway server, practise the daily skills: who owns which file, what is eating the CPU or the disk, why a service will not start."
explain "Almost every DevOps interview and almost every incident ends up on a Linux machine. You will practise the daily skills of a sysadmin on a throwaway Linux server (a container you can break freely): users and permissions, processes and signals, disk and memory, logs, scheduled jobs, systemd services, SSH keys and sudo. The shortcut lx runs a command inside that server."

part "PART A · The practice server"
learn "Your practice server" "lx stands for docker exec on a container named lab-linux. Whatever you run after lx runs INSIDE that little Debian server, as root. Pipes and redirects written after lx run on YOUR side, so for anything complex write it as lx bash -c followed by the command in quotes."
step "Build the practice server image (about a minute the first time)" "A sha256 image id." ok 'sha256' <<'CMD'
docker build -q -t devlab-linux 18-linux
CMD
step "Start the server" "A container id." ok '[0-9a-f]{12}' <<'CMD'
docker rm -f lab-linux >/dev/null 2>&1; docker run -d --name lab-linux devlab-linux
CMD
step "Look around: which Linux is it, and who are you?" "Debian GNU/Linux 12 and uid=0(root)." ok 'Debian' <<'CMD'
lx bash -c 'grep PRETTY_NAME /etc/os-release; id'
CMD

part "PART B · Users, groups and permissions"
learn "Who may do what to a file" "Every file has an owner, a group and three sets of permission bits: owner, group, others. Each set can have r (read=4), w (write=2) and x (execute=1). So 750 means: owner can do everything (7=4+2+1), group can read and enter (5=4+1), others get nothing (0). A directory needs x to be entered. Files are protected by these bits, not by hiding them."
art "Reading permissions: -rwxr-x---" <<'ART'
   -   rwx    r-x    ---
   |    |      |      |
 type owner  group  others   r=read(4) w=write(2) x=execute(1)
   chmod 750 file  =  rwx r-x ---
ART
mcq "What does chmod 640 give?" "Owner read and write, group read, others nothing|Everyone full access|Owner nothing|Only the group can write" 1 "6=rw- (4+2), 4=r--, 0=---."
step "Create a user called alice" "No output means success." <<'CMD'
lx useradd -m alice
CMD
step "Check the account" "uid=1001(alice) gid=1001(alice) groups=1001(alice)" ok 'uid=[0-9]+\(alice\)' <<'CMD'
lx id alice
CMD
step "Make a directory only alice can use" "drwx------ alice alice: the owner has everything, nobody else has anything." ok 'drwx------.*alice' <<'CMD'
lx bash -c 'mkdir -p /srv/alice && chown alice:alice /srv/alice && chmod 700 /srv/alice && ls -ld /srv/alice'
CMD
step "Create bob and let him try to read alice's directory" "Permission denied. The permission bits did their job." fail 'Permission denied' <<'CMD'
lx useradd -m bob; lx runuser -u bob -- ls /srv/alice
CMD
step "Read permissions in a precise way" "drwx------ alice:alice /srv/alice" ok 'drwx------ alice:alice' <<'CMD'
lx stat -c '%A %U:%G %n' /srv/alice
CMD
task "Give bob read access the RIGHT way: with a group" "Create a group called team, add BOTH alice and bob to it, make the group own /srv/alice, and set the permissions to 750 so the group can read and enter but others still cannot. Then bob must be able to list /srv/alice. Use lx bash -c 'command1; command2' to run several commands at once." "Commands to combine: groupadd team ; usermod -aG team alice ; usermod -aG team bob ; chgrp team /srv/alice ; chmod 750 /srv/alice" <<'X'
lx runuser -u bob -- ls /srv/alice >/dev/null 2>&1
---
lx bash -c 'groupadd team; usermod -aG team alice; usermod -aG team bob; chgrp team /srv/alice; chmod 750 /srv/alice'
X
quiz "In your own words: what does chmod 640 on a file mean?" "owner.*(read|write|rw)|group.*read|others?.*(nothing|no |none|cannot)" "The owner can read and write (6), the group can only read (4), everybody else has no access (0)."

part "PART C · Processes and signals"
learn "Processes and signals" "Every running program is a process with a number (PID). You talk to a process with signals. SIGTERM (15) politely asks it to finish and clean up, and is the default for kill. SIGKILL (9) removes it instantly with no cleanup, so use it only as a last resort. ps and pgrep find processes; pkill sends a signal by name."
step "Start a long-running background process" "started" ok 'started' <<'CMD'
lx bash -c 'nohup sleep 600 >/dev/null 2>&1 & echo started'
CMD
step "Find it" "A line with sleep 600 and its PID in the second column." ok 'sleep 600' <<'CMD'
lx ps aux | grep '[s]leep 600'
CMD
step "Ask it to stop politely (SIGTERM) and confirm it is gone" "gone" ok 'gone' <<'CMD'
lx pkill -TERM -f 'sleep 600'; sleep 1; lx pgrep -f 'sleep 600' || echo gone
CMD
quiz "Why try SIGTERM before SIGKILL?" "clean|graceful|polite|save|flush|finish|shutdown|cleanup|data" "SIGTERM lets the program close files, finish requests and clean up. SIGKILL cannot be caught, so the program may leave half-written data behind."

part "PART D · Disk, memory and CPU"
learn "The USE method" "When a machine is slow, check three resources in order: Utilisation (how busy), Saturation (is work queueing), Errors. For disk use df (free space) and du (what uses it). For memory use free. For CPU use top or ps. Disks that fill up are one of the most common causes of outages, because logs and temp files grow quietly."
step "How full are the disks, and how much memory is free?" "A table of file systems with Use% and a memory table." ok 'Mem:' <<'CMD'
lx bash -c 'df -h / | tail -2; free -m'
CMD
step "Create a 50 MB file to hunt for" "A 50M file." ok '50M' <<'CMD'
lx bash -c 'fallocate -l 50M /tmp/big.bin && ls -lh /tmp/big.bin'
CMD
step "Find every file bigger than 40 MB" "/tmp/big.bin. find with -size is how you hunt a disk hog." ok 'big.bin' <<'CMD'
lx find / -xdev -size +40M
CMD
task "Which top-level folder under /usr is the biggest?" "Find the biggest directory directly under /usr (use du -s and sort -n) and save only its full path into playground/biggest.txt." "du -s /usr/* | sort -n | tail -1 shows it. Keep only the path (the second column) with cut -f2." <<'X'
[ -s playground/biggest.txt ] && [ "$(tr -d '[:space:]' < playground/biggest.txt)" = "$(lx bash -c 'du -s /usr/* | sort -n | tail -1 | cut -f2' | tr -d '[:space:]')" ]
---
lx bash -c 'du -s /usr/* | sort -n | tail -1 | cut -f2' > playground/biggest.txt
X

part "PART E · Logs and scheduled jobs"
learn "Logs and cron" "Programs write logs; you read them with tail, grep and less. Searching for the word ERROR is the first move in most investigations. cron runs commands on a schedule. A schedule has five fields: minute hour day-of-month month day-of-week. Five stars mean every minute. Files in /etc/cron.d also name the user to run as."
step "Write two log lines and read them back" "Two lines, one containing ERROR." ok 'ERROR' <<'CMD'
lx bash -c 'echo "$(date) app started" >> /var/log/lab.log; echo "$(date) ERROR disk almost full" >> /var/log/lab.log; tail -n 2 /var/log/lab.log'
CMD
step "Count the error lines" "1" ok '^[1-9]' <<'CMD'
lx grep -c ERROR /var/log/lab.log
CMD
step "Install a cron job that runs every minute" "cron job installed" ok 'installed' <<'CMD'
lx bash -c 'printf "* * * * * root date >> /tmp/cron.log\n" > /etc/cron.d/lab && chmod 644 /etc/cron.d/lab && cron && echo "cron job installed"'
CMD
step "Wait a minute, then read what the job wrote" "A date and time line written by cron, with no human involved." ok '[0-9]{4}' <<'CMD'
sleep 70; lx tail -n 2 /tmp/cron.log
CMD
quiz "What does the schedule */5 * * * * mean?" "every 5|five minutes|each 5" "Run every 5 minutes (the first field is the minute, */5 means every fifth minute)."

part "PART F · systemd services"
learn "systemd units" "On most Linux servers systemd starts and supervises services. A service is described in a unit file: ExecStart is the command, User the account it runs as, Restart=on-failure brings it back if it crashes, and WantedBy decides when it starts at boot. systemctl enable, start, status and journalctl are the commands you will use daily. Here we write and validate unit files (a container does not run systemd as its init)."
step "Write a unit file" "A unit with ExecStart, Restart=on-failure and User=nobody." ok 'Restart=on-failure' <<'CMD'
lx bash -c 'printf "[Unit]\nDescription=Lab hello\n\n[Service]\nExecStart=/usr/bin/sleep 300\nRestart=on-failure\nUser=nobody\n\n[Install]\nWantedBy=multi-user.target\n" > /etc/systemd/system/hello.service && cat /etc/systemd/system/hello.service'
CMD
step "Validate it like a reviewer would" "unit is valid. systemd-analyze verify catches mistakes before deployment." ok 'valid' <<'CMD'
lx bash -c 'systemd-analyze verify /etc/systemd/system/hello.service && echo "unit is valid"'
CMD
quiz "What does Restart=on-failure do?" "restart|start again|crash|fail|come back|bring" "If the service exits with an error or is killed, systemd starts it again (it does not restart after a clean stop)."

part "PART G · SSH keys and sudo"
learn "SSH keys and sudo" "A key pair has a private key (secret, never shared) and a public key (given to servers). SSH refuses a private key that others can read, so the key must be 600 and the .ssh folder 700. sudo lets a normal user run chosen commands as root; the rules live in /etc/sudoers.d, and visudo -c checks them, because a broken sudoers file can lock everyone out."
step "Create an SSH key pair for alice" "id_ed25519 (private) and id_ed25519.pub (public)." ok 'id_ed25519' <<'CMD'
lx bash -c 'runuser -u alice -- ssh-keygen -t ed25519 -N "" -f /home/alice/.ssh/id_ed25519 -q; ls -l /home/alice/.ssh'
CMD
step "Check the permissions SSH insists on" "700 for the .ssh folder and 600 for the private key." ok '700.*\.ssh' <<'CMD'
lx stat -c '%a %n' /home/alice/.ssh /home/alice/.ssh/id_ed25519
CMD
step "Give alice one specific sudo right and validate the file" "parsed OK. visudo -c checks the syntax before it can lock you out." ok 'parsed OK' <<'CMD'
lx bash -c 'echo "alice ALL=(ALL) NOPASSWD:/usr/bin/systemctl" > /etc/sudoers.d/alice && chmod 440 /etc/sudoers.d/alice && visudo -cf /etc/sudoers.d/alice'
CMD
quiz "Why must a private SSH key be 600?" "others|secret|private|read|refuse|insecure|only (the )?owner" "If other users can read it they could steal your identity, so SSH refuses to use a key that is readable by anyone but the owner."

part "PART H · Network tools and tidy up"
step "Which network addresses does the server have, and what is listening?" "An eth0 address, and a table of listening sockets (probably empty here)." ok 'eth0|UP' <<'CMD'
lx bash -c 'ip -br addr; ss -tln'
CMD
step "Remove the practice server" "lab-linux" ok 'lab-linux' <<'CMD'
docker rm -f lab-linux
CMD

deeper "Ultimate Linux guide (Abhishek Veeramalla)|https://github.com/iam-veeramalla/ultimate-linux-guide"
explain "Done! This module gives you the Linux skills interviewers test most. Next in the list: bash lab.sh 19"
