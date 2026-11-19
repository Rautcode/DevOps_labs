# Secrets management with Vault (about 2h)
title "Module 20 · Secrets management"
mission "Someone committed a password to Git, and it is now in the history forever. Your mission: keep secrets in one protected place with a manager that hands each service only what it needs, and rotate them safely."
explain "Passwords and keys in .env files and git history are one of the most common causes of breaches. A secret manager keeps secrets in ONE protected place, gives each application only the secrets it needs, can revoke access instantly and records who read what. You will run a real HashiCorp Vault server (in development mode, for learning), store secrets, limit access with a policy, rotate a secret and deploy the API with secrets pulled from Vault. The shortcut vlt runs the vault command line."

part "PART A · Start Vault"
learn "Why a secret manager?" "A .env file is plain text on disk, easy to copy and easy to commit by mistake. A secret manager gives you central storage, access policies (who may read what), audit logs, easy rotation, and short-lived tokens that can be revoked. Dev mode keeps everything in memory with a known root token (lab-root), which is fine for learning and never acceptable in production."
say "Why use a secrets manager instead of environment files?" "A .env file is plain text that is easy to copy and commit. A secret manager like HashiCorp Vault stores secrets centrally and encrypted, with access control, audit logs, rotation and short-lived credentials. Applications authenticate and fetch only what they need at runtime, so secrets are never in Git, images or CI logs."
art "Secrets flow with Vault" <<'ART'
   app starts -> asks Vault: "token please, give me secret/devlab"
                 Vault checks the POLICY -> returns ONLY what that app may read
   The secret is never in Git, never in the image, never in a file.
ART
mcq "Where should a production password live?" "In a secret manager, injected at deploy time|In the Git repo|In the Docker image|In the README" 1 "Anything in Git or an image can be copied by anyone who can read it."
why "docker run -d::start in the background|--cap-add=IPC_LOCK::allow Vault to lock memory|-p 8200:8200::its web port|VAULT_DEV_ROOT_TOKEN_ID::a fixed practice token" "Vault dev mode is a practice server that starts unlocked, in memory. Never use dev mode for real secrets."
step "Start a Vault dev server (the first time downloads the image)" "A container id." ok '[0-9a-f]{12}' <<'CMD'
docker rm -f lab-vault >/dev/null 2>&1; docker run -d --name lab-vault --cap-add=IPC_LOCK -p 8200:8200 -e VAULT_DEV_ROOT_TOKEN_ID=lab-root -e VAULT_DEV_LISTEN_ADDRESS=0.0.0.0:8200 hashicorp/vault:1.17; sleep 5
CMD
why "vlt status::the lab shortcut for the Vault command line, asking for status" "Sealed false means Vault is unlocked and ready. In production Vault starts sealed until enough people provide key pieces."
step "Ask Vault how it is" "Initialized true and Sealed false: it is ready to use." ok 'Sealed +false' <<'CMD'
vlt status
CMD

part "PART B · Store and read secrets"
learn "The key-value engine" "Vault's KV engine stores secrets at paths such as secret/devlab/api. Version 2 keeps every previous version, so you can look back or roll back. Writing is kv put, reading is kv get, and -field=name prints just one value, which is handy in scripts."
say "How does Vault store secrets?" "The key-value secrets engine stores secrets at paths, such as secret/devlab/api, with versioning, so I can read an earlier version or see what changed. Access is controlled by path through policies. I write and read secrets with the CLI or the API, and the data is encrypted at rest."
art "Secrets as paths" <<'ART'
   secret/
     `-- devlab/
          `-- api   jwt_secret=...  admin_password=...   (version 1, 2, 3 ...)
   policies decide who may read which path; every read is logged
ART
why "vlt kv put::write a secret|secret/devlab/api::the path, like a folder|jwt_secret=... admin_password=...::the key and value pairs" "Secrets live in one protected place, at a path. Each write creates a new version."
step "Store the API's secrets" "A new version created at secret/data/devlab/api." ok 'devlab/api' <<'CMD'
vlt kv put secret/devlab/api jwt_secret=lab-from-vault-1234567890abcdef12345 admin_password=vault-admin-pass
CMD
why "vlt kv get::read the secret at that path" "You see the values and the metadata, such as the version. Reading is controlled by policies and logged."
step "Read them back" "Both keys and their values, plus metadata (version 1)." ok 'jwt_secret' <<'CMD'
vlt kv get secret/devlab/api
CMD
why "-field=jwt_secret::print only that one value" "Scripts need one clean value with nothing extra, so -field gives exactly that."
step "Read just one value, as a script would" "Only the value: lab-from-vault-..." ok 'lab-from-vault' <<'CMD'
vlt kv get -field=jwt_secret secret/devlab/api
CMD

part "PART C · Least privilege: policies and tokens"
learn "Policies and tokens" "A policy lists paths and what may be done on them (read, create, update, delete, list). A token carries one or more policies and can expire. Give each application its own token with only the paths it needs. If one leaks, you revoke just that token and nothing else breaks."
say "How do you control access in Vault?" "With policies that list paths and allowed capabilities, like read or create, attached to tokens or auth methods. I follow least privilege: each application gets a policy for only its own path and a short-lived token. Revoking the token cuts access immediately, and the audit log shows who read what."
art "Least privilege with Vault" <<'ART'
   app --token--> Vault --policy check--> path allowed? read yes, write no
   token: short-lived (1h), revocable at once, tied to one policy
ART
why "path secret/data/devlab/*::which secrets|capabilities = [read]::only reading is allowed|vlt policy write::save the policy" "A policy is a rule of least privilege. The application gets this policy, never the all-powerful root token."
step "Write a policy that can only READ the devlab secrets" "Success! Uploaded policy: devlab-read" ok 'Success' <<'CMD'
printf 'path "secret/data/devlab/*" {\n  capabilities = ["read"]\n}\n' | vlt policy write devlab-read -
CMD
why "vlt token create::make a new access token|-policy=devlab-read::with that policy only|-ttl=1h::it expires after one hour" "Short-lived tokens limit the damage if one leaks. The token is saved to a file, and we print only its length, not the secret itself."
step "Create a token that has only that policy (valid for 1 hour)" "A number of characters: the token was saved into playground/app-token.txt." ok '[0-9]+' <<'CMD'
vlt token create -policy=devlab-read -ttl=1h -field=token > playground/app-token.txt; wc -c < playground/app-token.txt
CMD
why "VAULT_TOKEN_LAB::use this token instead of root|vlt kv get -field=admin_password::read one value" "The token can do what its policy says: read. This is the access the application needs."
step "Use the limited token to READ (allowed)" "vault-admin-pass" ok 'vault-admin-pass' <<'CMD'
VAULT_TOKEN_LAB=$(cat playground/app-token.txt) vlt kv get -field=admin_password secret/devlab/api
CMD
why "vlt kv put::try to change a secret with the limited token" "Permission denied is the correct and desired result. A token that can only read cannot overwrite or delete anything."
step "Use the same token to WRITE (not allowed)" "permission denied. The policy only allows reading." fail 'permission denied' <<'CMD'
VAULT_TOKEN_LAB=$(cat playground/app-token.txt) vlt kv put secret/devlab/api jwt_secret=hacked
CMD
task "Rotate the JWT secret" "Secrets must be changed regularly. Write a NEW jwt_secret (at least 32 characters, keep the same admin_password) to secret/devlab/api. Vault keeps the old one as version 1. Then save the current version number (it should be 2) into playground/version.txt. Hint for reading it:  vlt kv metadata get secret/devlab/api" "vlt kv put secret/devlab/api jwt_secret=<40 chars> admin_password=vault-admin-pass   then   vlt kv metadata get secret/devlab/api | grep current_version" <<'X'
[ "$(tr -d '[:space:]' < playground/version.txt)" = "2" ] && [ "$(vlt kv metadata get secret/devlab/api | grep current_version | awk '{print $2}' | tr -d '\r\n ')" = "2" ] && [ "$(vlt kv get -field=jwt_secret secret/devlab/api | tr -d '\r\n' | wc -c | tr -d ' ')" -ge 32 ]
---
vlt kv put secret/devlab/api jwt_secret=rotated-secret-abcdefghijklmnopqrstuvwxyz-12345 admin_password=vault-admin-pass >/dev/null; vlt kv metadata get secret/devlab/api | grep current_version | awk '{print $2}' | tr -d '\r\n ' > playground/version.txt
X
why "-version=1::ask for the first version of the secret" "Vault keeps old versions. If a rotation breaks something, you can see the previous value and roll back."
step "Read the OLD version: nothing is lost" "The version 1 secret (lab-from-vault-...). Rotation is reversible." ok 'lab-from-vault' <<'CMD'
vlt kv get -version=1 -field=jwt_secret secret/devlab/api
CMD

part "PART D · Deploy the API with secrets from Vault"
learn "Inject secrets at deploy time" "The secret never lives in git, in the image or in a file you maintain. The deploy script asks Vault for the values and hands them to the container as environment variables. Know the limit: anyone who can run docker inspect on the host can see environment variables, so high-security setups use mounted files or a Vault agent instead."
say "How do secrets get from a secret manager into a running app?" "At deploy or start time the platform authenticates, fetches the secret and injects it as an environment variable or a file in memory, using an agent, an init step or the CSI driver. The secret never lives in Git, in the image or in a file in the repo, and rotating it does not need a rebuild."
art "Where the secret travels" <<'ART'
   Vault --fetch at start--> deploy step --env var or in-memory file--> running app
   never: Git, the image, a committed file, a CI log
ART
why "docker image inspect::check the image|docker build::build it if missing" "The next step runs the API container, so its image must exist."
step "Make sure the API image exists" "devlab-api:lab listed." ok 'devlab-api' <<'CMD'
docker image inspect devlab-api:lab >/dev/null 2>&1 || docker build -q -f 02-containers/Dockerfile.api -t devlab-api:lab app/api; docker images --format '{{.Repository}}:{{.Tag}}' | grep devlab-api
CMD
why "-e JWT_SECRET=...::set a variable for the app|vlt kv get -field::fetch the value from Vault at start time" "The secret is fetched at deploy time and passed in memory. It is not written in Git, not in the image and not in a file."
step "Start the API with its secrets taken from Vault" "A container id. The command asked Vault for both values." ok '[0-9a-f]{12}' <<'CMD'
docker rm -f vault-api >/dev/null 2>&1; docker run -d --name vault-api -p 5003:5000 -e JWT_SECRET="$(vlt kv get -field=jwt_secret secret/devlab/api)" -e ADMIN_PASSWORD="$(vlt kv get -field=admin_password secret/devlab/api)" devlab-api:lab
CMD
why "curl localhost:5003/healthz::the health page" "The API accepted the secret it got from Vault and started. A healthy answer proves the whole flow worked."
step "Is it healthy?" '{"ok":true}. It started, so the secret passed its length check.' ok '"ok":true' <<'CMD'
sleep 22; curl -s localhost:5003/healthz
CMD
why "docker inspect::show the container configuration|grep -c ^JWT_SECRET::count the secret lines" "A secret passed as an environment variable can be read by anyone with Docker access. That is a limit of this simple method. Production uses files in memory or the Vault agent."
step "See what an operator with docker access can see" "1: the variable is visible in docker inspect. Environment variables are convenient but not invisible." ok '^1' <<'CMD'
docker inspect -f '{{range .Config.Env}}{{println .}}{{end}}' vault-api | grep -c '^JWT_SECRET'
CMD
quiz "Why should the .env file with real secrets never be committed to git?" "history|forever|leak|public|clone|rotate|anyone|exposed|visible" "Git history is permanent and copied to every clone and fork. A committed secret is leaked, and must be rotated, not just deleted."

part "PART E · Revoke and clean up"
why "vlt token revoke::cancel the token immediately" "If a token leaks, you cancel it. Short life and instant revocation are the reasons to use tokens instead of long-lived passwords."
step "A token leaked: revoke it" "Success! Revoked token." ok 'Success' <<'CMD'
vlt token revoke "$(cat playground/app-token.txt)"
CMD
why "vlt kv get with the old token::try to read again" "Permission denied again, even for reading. This proves revocation works."
step "The revoked token is now useless" "permission denied or invalid token." fail 'denied|invalid' <<'CMD'
VAULT_TOKEN_LAB=$(cat playground/app-token.txt) vlt kv get secret/devlab/api
CMD
learn "Secrets in Kubernetes" "A Kubernetes Secret is only base64-encoded (module 14 showed you can decode it in one command). For real protection use an external secret store: the External Secrets Operator or the Secrets Store CSI driver sync values from Vault or a cloud secret manager, or encrypt secrets before they enter git with Sealed Secrets or SOPS. RBAC decides who may read Secrets at all."
say "Are Kubernetes Secrets secure?" "By default a Secret is only base64-encoded, not encrypted, so anyone who can read it, or read etcd, can decode it. I restrict access with RBAC, enable encryption at rest, and prefer an external secret manager synced into the cluster. And I never commit secret manifests to Git unencrypted."
art "base64 is not encryption" <<'ART'
   Secret value:  bGFiLXNlY3JldA==   --- base64 -d --->   lab-secret
   anyone who can read the Secret object can decode it
   protect with: RBAC, encryption at rest, an external secret manager
ART
quiz "How is a secret manager better than an encrypted .env file in git?" "central|audit|rotat|revoke|policy|access|short|expire|dynamic|who" "It gives central control: per-app policies, audit logs of every read, rotation, short-lived revocable tokens. An encrypted file is one static key: if that key leaks, everything leaks, and you cannot see who used what."
why "docker rm -f vault-api lab-vault::remove both containers" "Clean up. The dev Vault kept everything in memory, so the secrets are gone."
step "Stop everything from this module" "removed" ok 'vault' <<'CMD'
docker rm -f vault-api lab-vault
CMD

explain "Done! Next: bash lab.sh 21"
