#!/usr/bin/env bash
# Run any Ansible command inside the controller container, on the same network as the practice servers.
#   bash 13-ansible/ansible.sh ansible web -m ping
#   bash 13-ansible/ansible.sh ansible-playbook site.yml
# The repo is mounted at /w (working dir /w/13-ansible, so inventory.ini is found automatically).
set -euo pipefail
export MSYS_NO_PATHCONV=1
cd "$(dirname "$0")/.."
# ssh refuses private keys that are readable by others, and files mounted from Windows look world-readable,
# so the key is copied inside the container and locked down first.
exec docker run --rm --network ansible_default \
  -v "$PWD:/w" -v "$PWD/playground/ssh:/keys:ro" -w /w/13-ansible \
  -e ANSIBLE_HOST_KEY_CHECKING=False -e ANSIBLE_NOCOWS=1 -e ANSIBLE_INVENTORY=/w/13-ansible/inventory.ini \
  devlab-ansible sh -c 'mkdir -p /root/.ssh && cp /keys/id_lab /root/.ssh/id_lab && chmod 600 /root/.ssh/id_lab && exec "$@"' -- "$@"
