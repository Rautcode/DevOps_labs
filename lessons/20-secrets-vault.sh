# Secrets management with Vault (about 2h)
title "Module 20 · Secrets management"
mission "Someone committed a password to Git, and it is now in the history forever. Your mission: keep secrets in one protected place with a manager that hands each service only what it needs, and rotate them safely."
explain "Passwords and keys in .env files and git history are one of the most common causes of breaches. A secret manager keeps secrets in ONE protected place, gives each application only the secrets it needs, can revoke access instantly and records who read what. You will run a real HashiCorp Vault server (in development mode, for learning), store secrets, limit access with a policy, rotate a secret and deploy the API with secrets pulled from Vault. The shortcut vlt runs the vault command line."

part "PART A · Start Vault"
learn "Why a secret manager?" "A .env file is plain text on disk, easy to copy and easy to commit by mistake. A secret manager gives you central storage, access policies (who may read what), audit logs, easy rotation, and short-lived tokens that can be revoked. Dev mode keeps everything in memory with a known root token (lab-root), which is fine for learning and never acceptable in production."
art "Secrets flow with Vault" <<'ART'
   app starts -> asks Vault: "token please, give me secret/devlab"
                 Vault checks the POLICY -> returns ONLY what that app may read
   The secret is never in Git, never in the image, never in a file.
ART
mcq "Where should a production password live?" "In a secret manager, injected at deploy time|In the Git repo|In the Docker image|In the README" 1 "Anything in Git or an image can be copied by anyone who can read it."
step "Start a Vault dev server (the first time downloads the image)" "A container id." ok '[0-9a-f]{12}' <<'CMD'
docker rm -f lab-vault >/dev/null 2>&1; docker run -d --name lab-vault --cap-add=IPC_LOCK -p 8200:8200 -e VAULT_DEV_ROOT_TOKEN_ID=lab-root -e VAULT_DEV_LISTEN_ADDRESS=0.0.0.0:8200 hashicorp/vault:1.17; sleep 5
CMD
step "Ask Vault how it is" "Initialized true and Sealed false: it is ready to use." ok 'Sealed +false' <<'CMD'
vlt status
CMD

part "PART B · Store and read secrets"
learn "The key-value engine" "Vault's KV engine stores secrets at paths such as secret/devlab/api. Version 2 keeps every previous version, so you can look back or roll back. Writing is kv put, reading is kv get, and -field=name prints just one value, which is handy in scripts."
step "Store the API's secrets" "A new version created at secret/data/devlab/api." ok 'devlab/api' <<'CMD'
vlt kv put secret/devlab/api jwt_secret=lab-from-vault-1234567890abcdef12345 admin_password=vault-admin-pass
CMD
step "Read them back" "Both keys and their values, plus metadata (version 1)." ok 'jwt_secret' <<'CMD'
vlt kv get secret/devlab/api
CMD
step "Read just one value, as a script would" "Only the value: lab-from-vault-..." ok 'lab-from-vault' <<'CMD'
vlt kv get -field=jwt_secret secret/devlab/api
CMD

part "PART C · Least privilege: policies and tokens"
learn "Policies and tokens" "A policy lists paths and what may be done on them (read, create, update, delete, list). A token carries one or more policies and can expire. Give each application its own token with only the paths it needs. If one leaks, you revoke just that token and nothing else breaks."
step "Write a policy that can only READ the devlab secrets" "Success! Uploaded policy: devlab-read" ok 'Success' <<'CMD'
printf 'path "secret/data/devlab/*" {\n  capabilities = ["read"]\n}\n' | vlt policy write devlab-read -
CMD
step "Create a token that has only that policy (valid for 1 hour)" "A number of characters: the token was saved into playground/app-token.txt." ok '[0-9]+' <<'CMD'
vlt token create -policy=devlab-read -ttl=1h -field=token > playground/app-token.txt; wc -c < playground/app-token.txt
CMD
step "Use the limited token to READ (allowed)" "vault-admin-pass" ok 'vault-admin-pass' <<'CMD'
VAULT_TOKEN_LAB=$(cat playground/app-token.txt) vlt kv get -field=admin_password secret/devlab/api
CMD
step "Use the same token to WRITE (not allowed)" "permission denied. The policy only allows reading." fail 'permission denied' <<'CMD'
VAULT_TOKEN_LAB=$(cat playground/app-token.txt) vlt kv put secret/devlab/api jwt_secret=hacked
CMD
task "Rotate the JWT secret" "Secrets must be changed regularly. Write a NEW jwt_secret (at least 32 characters, keep the same admin_password) to secret/devlab/api. Vault keeps the old one as version 1. Then save the current version number (it should be 2) into playground/version.txt. Hint for reading it:  vlt kv metadata get secret/devlab/api" "vlt kv put secret/devlab/api jwt_secret=<40 chars> admin_password=vault-admin-pass   then   vlt kv metadata get secret/devlab/api | grep current_version" <<'X'
[ "$(tr -d '[:space:]' < playground/version.txt)" = "2" ] && [ "$(vlt kv metadata get secret/devlab/api | grep current_version | awk '{print $2}' | tr -d '\r\n ')" = "2" ] && [ "$(vlt kv get -field=jwt_secret secret/devlab/api | tr -d '\r\n' | wc -c | tr -d ' ')" -ge 32 ]
---
vlt kv put secret/devlab/api jwt_secret=rotated-secret-abcdefghijklmnopqrstuvwxyz-12345 admin_password=vault-admin-pass >/dev/null; vlt kv metadata get secret/devlab/api | grep current_version | awk '{print $2}' | tr -d '\r\n ' > playground/version.txt
X
step "Read the OLD version: nothing is lost" "The version 1 secret (lab-from-vault-...). Rotation is reversible." ok 'lab-from-vault' <<'CMD'
vlt kv get -version=1 -field=jwt_secret secret/devlab/api
CMD

part "PART D · Deploy the API with secrets from Vault"
learn "Inject secrets at deploy time" "The secret never lives in git, in the image or in a file you maintain. The deploy script asks Vault for the values and hands them to the container as environment variables. Know the limit: anyone who can run docker inspect on the host can see environment variables, so high-security setups use mounted files or a Vault agent instead."
step "Make sure the API image exists" "devlab-api:lab listed." ok 'devlab-api' <<'CMD'
docker image inspect devlab-api:lab >/dev/null 2>&1 || docker build -q -f 02-containers/Dockerfile.api -t devlab-api:lab app/api; docker images --format '{{.Repository}}:{{.Tag}}' | grep devlab-api
CMD
step "Start the API with its secrets taken from Vault" "A container id. The command asked Vault for both values." ok '[0-9a-f]{12}' <<'CMD'
docker rm -f vault-api >/dev/null 2>&1; docker run -d --name vault-api -p 5003:5000 -e JWT_SECRET="$(vlt kv get -field=jwt_secret secret/devlab/api)" -e ADMIN_PASSWORD="$(vlt kv get -field=admin_password secret/devlab/api)" devlab-api:lab
CMD
step "Is it healthy?" '{"ok":true}. It started, so the secret passed its length check.' ok '"ok":true' <<'CMD'
sleep 22; curl -s localhost:5003/healthz
CMD
step "See what an operator with docker access can see" "1: the variable is visible in docker inspect. Environment variables are convenient but not invisible." ok '^1' <<'CMD'
docker inspect -f '{{range .Config.Env}}{{println .}}{{end}}' vault-api | grep -c '^JWT_SECRET'
CMD
quiz "Why should the .env file with real secrets never be committed to git?" "history|forever|leak|public|clone|rotate|anyone|exposed|visible" "Git history is permanent and copied to every clone and fork. A committed secret is leaked, and must be rotated, not just deleted."

part "PART E · Revoke and clean up"
step "A token leaked: revoke it" "Success! Revoked token." ok 'Success' <<'CMD'
vlt token revoke "$(cat playground/app-token.txt)"
CMD
step "The revoked token is now useless" "permission denied or invalid token." fail 'denied|invalid' <<'CMD'
VAULT_TOKEN_LAB=$(cat playground/app-token.txt) vlt kv get secret/devlab/api
CMD
learn "Secrets in Kubernetes" "A Kubernetes Secret is only base64-encoded (module 14 showed you can decode it in one command). For real protection use an external secret store: the External Secrets Operator or the Secrets Store CSI driver sync values from Vault or a cloud secret manager, or encrypt secrets before they enter git with Sealed Secrets or SOPS. RBAC decides who may read Secrets at all."
quiz "How is a secret manager better than an encrypted .env file in git?" "central|audit|rotat|revoke|policy|access|short|expire|dynamic|who" "It gives central control: per-app policies, audit logs of every read, rotation, short-lived revocable tokens. An encrypted file is one static key: if that key leaks, everything leaks, and you cannot see who used what."
step "Stop everything from this module" "removed" ok 'vault' <<'CMD'
docker rm -f vault-api lab-vault
CMD

explain "Done! Next: bash lab.sh 21"
