# 13 · Ansible (Specialist, ~2h)

> **Guided version:** run `bash lab.sh 13` from the repo root. It explains each step, runs it for you, and checks your hands-on tasks. This page is the reference.

**Goal:** configure servers with code. Terraform *creates* infrastructure; Ansible *configures* what runs on it. You describe the desired state and Ansible makes each machine match, over plain SSH, with nothing installed on the servers.

| File | What it is |
|---|---|
| [inventory.ini](inventory.ini) | which servers exist (group `web`: web1, web2) and how to log in |
| [site.yml](site.yml) | the playbook: packages, a directory, a templated config, a motd line, a handler |
| [templates/app.conf.j2](templates/app.conf.j2) | a Jinja2 template filled with variables |
| [Dockerfile.target](Dockerfile.target), [compose.yml](compose.yml) | two practice servers (Debian + SSH, key-only login) |
| [Dockerfile.controller](Dockerfile.controller) | the machine Ansible runs from |
| [ansible.sh](ansible.sh) | runs any Ansible command in the controller container |

## Try it (from the repo root)
```bash
docker build -f 13-ansible/Dockerfile.controller -t devlab-ansible 13-ansible
mkdir -p playground/ssh && docker run --rm -v "$PWD/playground/ssh:/k" devlab-ansible ssh-keygen -t ed25519 -N "" -f /k/id_lab -q
SSH_PUBKEY="$(cat playground/ssh/id_lab.pub)" docker compose -f 13-ansible/compose.yml up -d --build
bash 13-ansible/ansible.sh ansible web -m ping                  # pong from web1 and web2
bash 13-ansible/ansible.sh ansible-playbook site.yml            # changed=4
bash 13-ansible/ansible.sh ansible-playbook site.yml            # changed=0  (idempotent!)
docker compose -f 13-ansible/compose.yml down
```

## Concepts
- **Idempotent:** run it once or ten times, same result. Already-correct servers are left alone.
- **Declarative tasks:** "package X is present", not "run apt install X".
- **Handlers** run only when something changed (restart a service only if its config changed).
- **Drift:** change a file by hand, run the playbook, and it is put back (verified in the lesson).
- **Inventory + variables** let one playbook serve many environments.

## Break it
1. Edit a managed file on a server by hand, then run the playbook: watch it repair the drift on that server only.
2. Break the template (use an undefined variable) and read the error.
3. Add a third server `web3` to the compose file and inventory and run the playbook.

## Industry notes
- Use **roles** and **collections** to organise large playbooks; keep secrets in **Ansible Vault** or a secret manager.
- Run `ansible-lint` in CI; use `--check --diff` (dry run) before applying to production.
- In containers and Kubernetes, you bake config into images instead; Ansible shines for VMs, bare metal and network devices.

**Next:** [14 · Helm and RBAC](../14-helm/README.md)
