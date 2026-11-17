# Module 18 · interview and final (sourced by lab.sh)
part "PART · INTERVIEW"

interview "Share a file with exactly one person" "Interviewer: 'On the practice server, the file /srv/secret/plan.txt is only readable by root. The user dave must be able to read it, but nobody else may (not even the user nobody). Do not make it world-readable. Show me.'" "Use a group: create one, put dave in it, make the folder and file belong to that group and give the group read access (750 on the folder, 640 on the file). Test as dave with: lx runuser -u dave -- cat /srv/secret/plan.txt" <<'X'
docker image inspect devlab-linux >/dev/null 2>&1 || docker build -q -t devlab-linux 18-linux >/dev/null 2>&1; docker rm -f lab-linux >/dev/null 2>&1; docker run -d --name lab-linux devlab-linux >/dev/null 2>&1; sleep 2; lx bash -c 'useradd -m dave; mkdir -p /srv/secret; echo top > /srv/secret/plan.txt; chown root:root /srv/secret /srv/secret/plan.txt; chmod 700 /srv/secret; chmod 600 /srv/secret/plan.txt'
---
lx runuser -u dave -- cat /srv/secret/plan.txt 2>/dev/null | grep -q top && ! lx runuser -u nobody -- cat /srv/secret/plan.txt >/dev/null 2>&1
---
lx bash -c 'groupadd -f secretaries; usermod -aG secretaries dave; chgrp secretaries /srv/secret /srv/secret/plan.txt; chmod 750 /srv/secret; chmod 640 /srv/secret/plan.txt'
X

interview "Find the disk hog" "Interviewer: 'The server disk is filling up and somebody hid a big file somewhere under /var/tmp. Find the LARGEST file there and save its full path into playground/hog.txt.'" "find /var/tmp -type f -printf '%s %p\n' | sort -n | tail -1  prints the biggest file last (size first, then path)." <<'X'
lx bash -c 'mkdir -p /var/tmp/.cache/x; fallocate -l 60M /var/tmp/.cache/x/hog.bin; echo small > /var/tmp/note.txt'; rm -f playground/hog.txt
---
[ "$(tr -d '[:space:]' < playground/hog.txt)" = "/var/tmp/.cache/x/hog.bin" ]
---
lx bash -c "find /var/tmp -type f -printf '%s %p\n' | sort -n | tail -1 | cut -d' ' -f2" > playground/hog.txt
X

part "PART · MODULE FINAL"

final "Stop the runaway process" "Exam 1 of 3. A process (sleep 9999) is eating the server in the background. Stop it GRACEFULLY, with a polite signal, not by force. I will check that it is gone." "pkill -TERM -f 'sleep 9999'  (run it through lx). First find it with lx ps aux." <<'X'
lx bash -c 'nohup sleep 9999 >/dev/null 2>&1 &'; sleep 1
---
! lx pgrep -f 'sleep 9999' >/dev/null 2>&1
---
lx pkill -TERM -f 'sleep 9999'; sleep 1
X

final "Write a service" "Exam 2 of 3. Write the systemd unit file playground/exam.service for a service that runs /usr/bin/sleep 120 as the user nobody and restarts only when it fails. It must pass systemd-analyze verify." "Sections: [Unit] Description=..., [Service] ExecStart=/usr/bin/sleep 120, User=nobody, Restart=on-failure, [Install] WantedBy=multi-user.target. Copy it into the server with docker cp and verify with lx systemd-analyze verify." <<'X'
rm -f playground/exam.service
---
[ -f playground/exam.service ] && grep -q 'Restart=on-failure' playground/exam.service && grep -q 'User=nobody' playground/exam.service && grep -q 'ExecStart=/usr/bin/sleep 120' playground/exam.service && docker cp playground/exam.service lab-linux:/etc/systemd/system/exam.service >/dev/null 2>&1 && lx systemd-analyze verify /etc/systemd/system/exam.service >/dev/null 2>&1
---
printf '[Unit]\nDescription=Exam service\n\n[Service]\nExecStart=/usr/bin/sleep 120\nUser=nobody\nRestart=on-failure\n\n[Install]\nWantedBy=multi-user.target\n' > playground/exam.service
X

final "Fix the SSH key permissions" "Exam 3 of 3. The user erin cannot use SSH: her .ssh folder and private key are readable by everybody, so SSH refuses the key. Fix the permissions the way SSH requires (folder 700, private key 600)." "chmod 700 /home/erin/.ssh  and  chmod 600 /home/erin/.ssh/id_ed25519  (run through lx)" <<'X'
lx bash -c 'useradd -m -s /bin/bash erin; mkdir -p /home/erin/.ssh; ssh-keygen -t ed25519 -N "" -f /home/erin/.ssh/id_ed25519 -q; chown -R erin:erin /home/erin/.ssh; chmod 777 /home/erin/.ssh; chmod 666 /home/erin/.ssh/id_ed25519'
---
[ "$(lx stat -c %a /home/erin/.ssh | tr -d '\r\n ')" = 700 ] && [ "$(lx stat -c %a /home/erin/.ssh/id_ed25519 | tr -d '\r\n ')" = 600 ]
---
lx bash -c 'chmod 700 /home/erin/.ssh; chmod 600 /home/erin/.ssh/id_ed25519'
---
docker rm -f lab-linux >/dev/null 2>&1
X
