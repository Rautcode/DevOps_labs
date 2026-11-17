# Module 13 · interview and final (sourced by lab.sh)
# helper: build the controller image, make an SSH key, start the two practice servers
ans_up() {
  docker image inspect devlab-ansible >/dev/null 2>&1 || docker build -q -f 13-ansible/Dockerfile.controller -t devlab-ansible 13-ansible >/dev/null 2>&1
  mkdir -p playground/ssh
  [ -f playground/ssh/id_lab ] || docker run --rm -v "$PWD/playground/ssh:/k" devlab-ansible ssh-keygen -t ed25519 -N "" -f /k/id_lab -q
  SSH_PUBKEY="$(cat playground/ssh/id_lab.pub)" ac up -d --build >/dev/null 2>&1; sleep 5
}

part "PART · INTERVIEW"

interview "Are my servers reachable?" "Interviewer: 'We just inherited two servers (the group web). Before changing anything, check that Ansible can reach ALL of them. Save the output of the check into playground/ping.txt. I will look for a reply from each server.'" "lab-ansible ansible web -m ping   (the ping module checks SSH and Python, it is not a network ping)." <<'X'
ans_up; rm -f playground/ping.txt
---
[ "$(grep -c pong playground/ping.txt)" -ge 2 ]
---
lab-ansible ansible web -m ping > playground/ping.txt 2>&1
X

interview "Install a package everywhere" "Interviewer: 'Write a playbook playground/exam-tree.yml that makes sure the package tree is installed on every server in the group web (it needs root: become). Run it. I will check both servers.'" "Shape:  - hosts: web   become: true   tasks:   - ansible.builtin.apt:   name: tree   state: present   update_cache: true  . Run it with  lab-ansible ansible-playbook ../playground/exam-tree.yml" <<'X'
rm -f playground/exam-tree.yml
---
ac exec -T web1 which tree >/dev/null 2>&1 && ac exec -T web2 which tree >/dev/null 2>&1
---
printf -- '- hosts: web\n  become: true\n  tasks:\n    - ansible.builtin.apt:\n        name: tree\n        state: present\n        update_cache: true\n' > playground/exam-tree.yml && lab-ansible ansible-playbook ../playground/exam-tree.yml >/dev/null 2>&1
X

part "PART · MODULE FINAL"

final "Prove it is idempotent" "Exam 1 of 3. Run your playbook a SECOND time and save its PLAY RECAP into playground/recap.txt. It must show changed=0 (nothing left to change)." "lab-ansible ansible-playbook ../playground/exam-tree.yml | grep -A3 RECAP > playground/recap.txt" <<'X'
rm -f playground/recap.txt
---
grep -q 'changed=0' playground/recap.txt && ! grep -qE 'changed=[1-9]' playground/recap.txt
---
lab-ansible ansible-playbook ../playground/exam-tree.yml 2>&1 | sed 's/\x1b\[[0-9;]*m//g' | grep -A4 RECAP > playground/recap.txt
X

final "Use a variable" "Exam 2 of 3. Write playground/exam-vars.yml: a playbook for the group web that sets a variable motto to ship-it and creates the file /tmp/motto.txt on every server containing exactly that value. Run it." "Use  vars:  motto: ship-it  and the copy module with  content: \"{{ motto }}\"  and  dest: /tmp/motto.txt" <<'X'
rm -f playground/exam-vars.yml
---
ac exec -T web1 grep -q '^ship-it' /tmp/motto.txt && ac exec -T web2 grep -q '^ship-it' /tmp/motto.txt
---
printf -- '- hosts: web\n  vars:\n    motto: ship-it\n  tasks:\n    - ansible.builtin.copy:\n        content: "{{ motto }}\\n"\n        dest: /tmp/motto.txt\n' > playground/exam-vars.yml && lab-ansible ansible-playbook ../playground/exam-vars.yml >/dev/null 2>&1
X

final "Repair drift" "Exam 3 of 3. Someone edited the managed config on web2 by hand (it now contains the word hacked). Bring the servers back to the desired state using the lesson playbook site.yml, without editing the file yourself." "lab-ansible ansible-playbook site.yml  puts every managed file back as the playbook says." <<'X'
lab-ansible ansible-playbook site.yml >/dev/null 2>&1; ac exec -T web2 sh -c 'echo hacked >> /opt/devlab/app.conf'
---
! ac exec -T web2 grep -q hacked /opt/devlab/app.conf
---
lab-ansible ansible-playbook site.yml >/dev/null 2>&1
---
ac down >/dev/null 2>&1
X
