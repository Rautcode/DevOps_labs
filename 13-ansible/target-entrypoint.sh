#!/bin/sh
# Install the public key that was passed in, then run the SSH server in the foreground.
set -e
mkdir -p /home/deploy/.ssh /run/sshd
printf '%s\n' "$SSH_PUBKEY" > /home/deploy/.ssh/authorized_keys
chown -R deploy:deploy /home/deploy/.ssh
chmod 700 /home/deploy/.ssh
chmod 600 /home/deploy/.ssh/authorized_keys
ssh-keygen -A >/dev/null
exec /usr/sbin/sshd -D -e
