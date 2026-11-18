# Ansible: configure servers with code (about 2h)
title "Module 13 · Ansible"
mission "You have ten servers to set up exactly the same way, and typing the same commands ten times is how mistakes happen. Your mission: write the setup once as a playbook, run it on all of them, and fix drift when someone changes a server by hand."
explain "Terraform creates infrastructure. Ansible CONFIGURES it: packages, files, users, services. You describe the desired state in a 'playbook' and Ansible makes each server match, over SSH, without installing anything on the servers. Running it twice changes nothing the second time (idempotent). You will manage two practice servers."

part "PART A · Build the practice servers"
learn "Configuration management" "Terraform creates machines; Ansible configures what runs on them. The inventory lists your servers, modules do one job each (install a package, copy a file), and a playbook is a list of tasks describing the DESIRED STATE. Ansible logs in over SSH and needs nothing installed on the servers."
say "What is configuration management, and where does Ansible fit?" "Terraform creates infrastructure, and a configuration management tool like Ansible configures what runs on it: packages, files, users and services. I describe the desired state in a playbook and Ansible makes each server match, over SSH with no agent. It makes servers consistent, repeatable and documented, instead of hand-configured."
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
say "What is the difference between an ad-hoc command and a playbook?" "An ad-hoc command runs one module on many servers right now, which is good for quick checks like ping. A playbook is a saved, repeatable, reviewable list of tasks that describes the desired state. For anything that changes servers permanently I use a playbook kept in Git."
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
say "What does idempotent mean?" "Running it once or many times gives the same result. Ansible tasks describe a state, like package present, and Ansible changes things only if the server differs. The second run reports no changes. That makes the automation safe to re-run, and I can use it to continuously enforce the desired state."
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
say "What is configuration drift?" "Drift is when a server no longer matches its desired state, usually because someone changed it by hand. Re-running the playbook detects the difference and repairs it. To prevent drift I restrict manual changes, keep everything in code and run the automation regularly. In my lab I edited a config by hand and Ansible put it back."
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

part "PART E · Roles: reusable building blocks"
learn "Roles" "A playbook that grows becomes hard to read and reuse. A ROLE packages one job (install and configure nginx, set up users, create a banner) in a standard folder layout: tasks (what to do), defaults (variables anyone can override), templates (files with variables), handlers and more. A playbook then uses the role in one line, and the same role works for every project. Ansible Galaxy is a public library of ready-made roles."
say "What are Ansible roles?" "A role packages one job in a standard folder structure with tasks, defaults, templates and handlers, so it can be reused across playbooks and projects. A playbook then just lists the roles to apply. Defaults can be overridden with variables, and Ansible Galaxy shares community roles. Roles keep large automation organised and testable."
art "The layout of a role" <<'ART'
   roles/banner/
     defaults/main.yml      variables with default values (easy to override)
     tasks/main.yml         the work to do
     templates/banner.txt.j2   a file with {{ variables }}
   playbook:  roles: [ banner ]     <- one line uses all of it
ART
step "Look at the files that make up the role" "defaults/main.yml, tasks/main.yml and templates/banner.txt.j2 under 13-ansible/roles/banner." ok 'tasks/main.yml' <<'CMD'
find 13-ansible/roles -type f | sort
CMD
step "Read the role's defaults and tasks" "A default banner_text, and two tasks: create the directory and render the template." ok 'banner_text' <<'CMD'
cat 13-ansible/roles/banner/defaults/main.yml 13-ansible/roles/banner/tasks/main.yml
CMD
step "Read the playbook that uses the role" "Only the list of roles: banner. Everything else lives in the role." ok 'banner' <<'CMD'
cat 13-ansible/roles-demo.yml
CMD
step "Apply the role to both servers" "PLAY RECAP with failed=0 and changed=2 for each server (the first time)." ok 'failed=0' <<'CMD'
lab-ansible ansible-playbook roles-demo.yml 2>&1 | sed 's/\x1b\[[0-9;]*m//g' | grep -E "^PLAY RECAP|changed="
CMD
step "Read the result on web1" "The default banner and host: web1. The template filled in the variable inventory_hostname." ok 'host: web1' <<'CMD'
ac exec -T web1 cat /opt/devlab/banner.txt
CMD
task "Override a role variable" "Apply the role again, but change the banner text from the command line:  bash 13-ansible/ansible.sh ansible-playbook roles-demo.yml -e \"banner_text='Maintenance tonight'\"   Then look at the banner on web2: it must say Maintenance tonight." "-e sets extra variables, which beat the role's defaults. Check with: ac exec -T web2 cat /opt/devlab/banner.txt" <<'X'
ac exec -T web2 grep -q 'Maintenance tonight' /opt/devlab/banner.txt
---
lab-ansible ansible-playbook roles-demo.yml -e "banner_text='Maintenance tonight'"
X

part "PART F · Ansible Vault: secrets in the repository, safely"
learn "Ansible Vault" "Playbooks often need secrets: database passwords, API keys. Ansible Vault encrypts a variables file with a password, so the encrypted file can be committed to Git while the password is kept elsewhere (a secret manager, a CI secret). Ansible decrypts it in memory when you run a playbook and give it the vault password. Add no_log: true to tasks that handle secrets so Ansible never prints them. In this lab the wrapper copies your playground/vault-pass.txt to /root/.vault-pass inside the Ansible container (and locks its permissions), so that is the password file you name on the command line. Vault protects secrets at rest; for rotation and access control use a secret manager (module 20)."
say "How do you manage secrets in Ansible?" "I encrypt secret variable files with Ansible Vault, so the encrypted file can be committed to Git while the vault password is stored elsewhere, like a CI secret or a password manager. Playbooks decrypt it in memory, and I set no_log on tasks that handle secrets. For rotation and access control I would use a secrets manager such as HashiCorp Vault."
art "Vault: what is stored where" <<'ART'
   secrets.yml (ENCRYPTED)  ---> committed to Git, safe to read for anyone
   vault password           ---> NEVER in Git (CI secret / password manager)
   playbook run + password  ---> secret decrypted in memory, copied to the server (mode 0600)
ART
step "Create a plain secrets file and a vault password file" "The file shows the secret in plain text, for now." ok 's3cr3t' <<'CMD'
printf 'lab-vault-password\n' > playground/vault-pass.txt; printf 'db_password: s3cr3t-value\n' > playground/secrets.yml; cat playground/secrets.yml
CMD
step "Encrypt it with ansible-vault" "encrypted OK. ansible-vault prints nothing when it works, so the lab adds the message; the next step shows the result." ok 'encrypted OK' <<'CMD'
lab-ansible ansible-vault encrypt ../playground/secrets.yml --vault-password-file /root/.vault-pass 2>&1 && echo "encrypted OK"
CMD
step "Look at the file now" "Unreadable: it starts with \$ANSIBLE_VAULT;1.1;AES256 followed by hex. This file is safe to commit." ok 'ANSIBLE_VAULT' <<'CMD'
head -3 playground/secrets.yml
CMD
step "Count the plain-text copies of the secret in that file" "secret copies in the file: 0." ok 'file: 0' <<'CMD'
echo "secret copies in the file: $(grep -c s3cr3t playground/secrets.yml || true)"
CMD
step "With the password, Ansible can still read it" "db_password: s3cr3t-value." ok 's3cr3t-value' <<'CMD'
lab-ansible ansible-vault view ../playground/secrets.yml --vault-password-file /root/.vault-pass
CMD
step "Read the playbook that uses the encrypted file" "vars_files points at the encrypted file, and the copy task has no_log: true." ok 'no_log' <<'CMD'
cat 13-ansible/vault-demo.yml
CMD
step "Run it with the vault password" "PLAY RECAP with failed=0: the secret was decrypted and copied to both servers." ok 'failed=0' <<'CMD'
lab-ansible ansible-playbook vault-demo.yml --vault-password-file /root/.vault-pass 2>&1 | sed 's/\x1b\[[0-9;]*m//g' | grep -E "^PLAY RECAP|changed="
CMD
step "Check the secret file on the server: permissions and owner" "600 root: only root can read it." ok '600 root' <<'CMD'
ac exec -T web1 stat -c '%a %U %n' /opt/devlab/db_password
CMD
quiz "Why is it safe to commit an Ansible Vault file to Git, but never the vault password?" "password|key|encrypt|decrypt|unreadable|without|separate|secret|anyone|access" "The file is encrypted, so without the password it is just noise. The password is the key: anyone who has both can read the secrets, so the two must live in different places."

part "PART G · Clean up"
step "Remove the practice servers" "web1 and web2 removed." ok 'Removed|removed' <<'CMD'
ac down 2>&1 | tail -4
CMD

deeper "Ansible Zero to Hero (Abhishek Veeramalla)|https://github.com/iam-veeramalla/ansible-zero-to-hero"
explain "Done! Next: bash lab.sh 14"
