# Ansible: configure servers with code (about 2h)
title "Module 13 · Ansible"
mission "You have ten servers to set up exactly the same way, and typing the same commands ten times is how mistakes happen. Your mission: write the setup once as a playbook, run it on all of them, and fix drift when someone changes a server by hand."
explain "Terraform creates infrastructure. Ansible CONFIGURES it: packages, files, users, services. You describe the desired state in a 'playbook' and Ansible makes each server match, over SSH, without installing anything on the servers. Running it twice changes nothing the second time (idempotent). You will manage two practice servers."

part "PART A · Build the practice servers"
learn "Configuration management" "Terraform creates machines; Ansible configures what runs on them. The inventory lists your servers, modules do one job each (install a package, copy a file), and a playbook is a list of tasks describing the DESIRED STATE. Ansible logs in over SSH and needs nothing installed on the servers."
step "Build the Ansible control image (first time takes a minute or two)" "Successfully built, or the image devlab-ansible is listed." ok 'devlab-ansible' <<'CMD'
docker build -q -f 13-ansible/Dockerfile.controller -t devlab-ansible 13-ansible >/dev/null && docker images --format '{{.Repository}}:{{.Tag}}' | grep devlab-ansible
CMD
step "Create an SSH key pair (Ansible logs in with a key, not a password)" "id_lab (private, secret) and id_lab.pub (public, shared with the servers)." ok 'id_lab.pub' <<'CMD'
mkdir -p playground/ssh; rm -f playground/ssh/id_lab playground/ssh/id_lab.pub; docker run --rm -v "$PWD/playground/ssh:/k" devlab-ansible ssh-keygen -t ed25519 -N "" -f /k/id_lab -q; ls playground/ssh
CMD
step "Start two practice servers (web1 and web2) that accept that key" "Containers ansible-web1-1 and ansible-web2-1 Started." ok 'web2' <<'CMD'
SSH_PUBKEY="$(cat playground/ssh/id_lab.pub)" ac up -d --build 2>&1 | tail -4; sleep 4
CMD
quiz "Why does Ansible use SSH keys instead of passwords?" "secur|safe|password|guess|automat|steal|no prompt|brute" "Keys cannot be guessed like passwords and let automation log in without a human typing anything. Only the matching private key opens the door."

part "PART B · Talk to the servers"
learn "Ad-hoc commands and playbooks" "An ad-hoc command runs one module on many servers right now, good for quick checks. A playbook is saved, repeatable and reviewable, which is what you want for real changes."
step "Ad-hoc command: are the servers reachable? (ansible -m ping)" "web1 | SUCCESS and web2 | SUCCESS, each with \"ping\": \"pong\". Ansible reached both over SSH." ok 'pong' <<'CMD'
lab-ansible ansible web -m ping
CMD
step "Run a one-off command on every server" "Both servers report Debian 12. One command, many machines." ok 'Debian' <<'CMD'
lab-ansible ansible web -m command -a "grep PRETTY_NAME /etc/os-release"
CMD
step "Is curl installed yet?" "command not found / non-zero exit on both servers. Nothing is configured yet." fail 'FAILED|non-zero|rc=1|not found|No such' <<'CMD'
lab-ansible ansible web -m command -a "curl --version"
CMD

part "PART C · A playbook: desired state"
step "Read the playbook" "Tasks: install packages, create a directory, render a template, add a motd line, plus a handler that runs only on change." ok 'Install packages' <<'CMD'
cat 13-ansible/site.yml
CMD
learn "Idempotence" "A task says what state you want (package present), not which command to run. Ansible checks first and changes only if needed. So running the playbook twice gives the same result, and the second run reports changed=0. That makes re-running always safe."
predict "You run the same playbook twice. What does the second run report?" "ok, nothing changed|It repeats every change|It fails because the work exists|It deletes the work" 1 "Idempotent means safe to repeat: tasks describe a state, and Ansible changes only what does not match yet."
step "Run the playbook (first run: apt downloads packages, about a minute)" "PLAY RECAP with changed=3 or 4 and failed=0 for web1 and web2. Yellow 'changed' tasks mean Ansible fixed something." ok 'failed=0' <<'CMD'
lab-ansible ansible-playbook site.yml 2>&1 | sed 's/\x1b\[[0-9;]*m//g' | grep -E "^TASK|^PLAY RECAP|changed=|RUNNING HANDLER"
CMD
step "Run it AGAIN: this is idempotence" "changed=0 everywhere. The servers already match the desired state, so Ansible does nothing. This makes running it again always safe." ok 'changed=0.*failed=0' <<'CMD'
lab-ansible ansible-playbook site.yml 2>&1 | sed 's/\x1b\[[0-9;]*m//g' | grep -E "^PLAY RECAP|changed="
CMD
step "Look at the file Ansible created on a server" "A config rendered from the template: app=devlab, host=web1, greeting=Hello from Ansible." ok 'managed by ansible' <<'CMD'
ac exec -T web1 cat /opt/devlab/app.conf
CMD
quiz "What does 'idempotent' mean for a configuration tool?" "same|again|twice|repeat|no change|safe|nothing|result" "Running it once or many times gives the same result. If a server is already correct nothing changes, so you can re-run it any time without fear."

part "PART D · Drift and variables"
explain "Drift = someone changes a server by hand. Ansible notices on the next run and puts it back."
learn "Drift" "Drift is when a server no longer matches its desired state, usually because someone changed it by hand. Re-running the playbook finds the difference and repairs it. The managed file says do not edit by hand for exactly this reason."
step "Someone edits the config by hand on web1 (drift)" "The file now has an extra 'hacked' line." ok 'hacked' <<'CMD'
ac exec -T web1 sh -c 'echo "hacked by hand" >> /opt/devlab/app.conf'; ac exec -T web1 cat /opt/devlab/app.conf
CMD
step "Run the playbook: Ansible repairs it" "web1 shows changed=1 (the template task), web2 changed=0. Config handler announces the change." ok 'changed=1' <<'CMD'
lab-ansible ansible-playbook site.yml 2>&1 | sed 's/\x1b\[[0-9;]*m//g' | grep -E "^PLAY RECAP|changed=|app.conf changed"
CMD
step "Confirm the hack is gone" "hacked lines remaining: 0" ok 'remaining: 0' <<'CMD'
echo "hacked lines remaining: $(ac exec -T web1 grep -c hacked /opt/devlab/app.conf || true)"
CMD
task "Change a variable and apply it to both servers" "Run the playbook again but override the greeting variable on the command line:  bash 13-ansible/ansible.sh ansible-playbook site.yml -e \"greeting='Hi from me'\"   Then look at the config on web2:  docker compose -f 13-ansible/compose.yml exec -T web2 cat /opt/devlab/app.conf" "The check passes when web1 AND web2 both contain greeting=Hi from me." <<'X'
ac exec -T web1 grep -q 'greeting=Hi from me' /opt/devlab/app.conf && ac exec -T web2 grep -q 'greeting=Hi from me' /opt/devlab/app.conf
---
lab-ansible ansible-playbook site.yml -e "greeting='Hi from me'"
X
task "Write your own playbook" "Create playground/hello.yml that creates the file /tmp/hello.txt containing the text hello from ansible on every server in the group 'web' (use the copy module with content and dest). Run it:  bash 13-ansible/ansible.sh ansible-playbook ../playground/hello.yml" "Start with:  - hosts: web   then  tasks:  then  - ansible.builtin.copy: with content: and dest:. No 'become' is needed for /tmp." <<'X'
ac exec -T web1 grep -q 'hello from ansible' /tmp/hello.txt && ac exec -T web2 grep -q 'hello from ansible' /tmp/hello.txt
---
printf -- '- hosts: web\n  tasks:\n    - ansible.builtin.copy:\n        content: "hello from ansible\\n"\n        dest: /tmp/hello.txt\n' > playground/hello.yml && lab-ansible ansible-playbook ../playground/hello.yml
X
quiz "Ansible vs Terraform: what is each one mainly for?" "terraform.*(create|provision|infra)|ansible.*(config|install|package|server)|create|configure|provision" "Terraform creates and changes infrastructure (networks, servers, buckets). Ansible configures what runs on it (packages, files, services). They are often used together."

part "PART E · Clean up"
step "Remove the practice servers" "web1 and web2 removed." ok 'Removed|removed' <<'CMD'
ac down 2>&1 | tail -4
CMD

deeper "Ansible Zero to Hero (Abhishek Veeramalla)|https://github.com/iam-veeramalla/ansible-zero-to-hero"
explain "Done! Next: bash lab.sh 14"
