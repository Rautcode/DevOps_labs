# Module 20 · interview and final (sourced by lab.sh)
part "PART · INTERVIEW"

interview "Least privilege for an app" "Interviewer: 'A new service needs to read ONLY the secrets under secret/exam/. Create a Vault policy called exam-ro for that, create a token with only that policy and save the token into playground/exam-token.txt. I will test two things: the token can read secret/exam/db, and it can NOT read secret/devlab/api.'" "Policy path: secret/data/exam/* with capabilities [\"read\"]  (note the extra data/ in KV v2 paths). Then: vlt token create -policy=exam-ro -field=token > playground/exam-token.txt" <<'X'
docker rm -f lab-vault >/dev/null 2>&1; docker run -d --name lab-vault --cap-add=IPC_LOCK -p 8200:8200 -e VAULT_DEV_ROOT_TOKEN_ID=lab-root -e VAULT_DEV_LISTEN_ADDRESS=0.0.0.0:8200 hashicorp/vault:1.17 >/dev/null 2>&1; sleep 6; vlt kv put secret/devlab/api jwt_secret=lab-from-vault-1234567890abcdef12345 admin_password=vault-admin-pass >/dev/null 2>&1; vlt kv put secret/exam/db password=exam-db-pass >/dev/null 2>&1; rm -f playground/exam-token.txt
---
[ -s playground/exam-token.txt ] && [ "$(VAULT_TOKEN_LAB=$(cat playground/exam-token.txt) vlt kv get -field=password secret/exam/db | tr -d '\r\n ')" = "exam-db-pass" ] && ! VAULT_TOKEN_LAB=$(cat playground/exam-token.txt) vlt kv get secret/devlab/api >/dev/null 2>&1
---
printf 'path "secret/data/exam/*" {\n  capabilities = ["read"]\n}\n' | vlt policy write exam-ro - >/dev/null 2>&1; vlt token create -policy=exam-ro -field=token > playground/exam-token.txt
X

interview "Rotate a leaked password" "Interviewer: 'The database password stored at secret/exam/db was pasted into a chat. Rotate it: set a NEW password with the value rotated-pass. Afterwards the current version of the secret must be 2.'" "vlt kv put secret/exam/db password=rotated-pass  creates version 2." <<'X'
true
---
[ "$(vlt kv get -field=password secret/exam/db | tr -d '\r\n ')" = "rotated-pass" ] && [ "$(vlt kv metadata get secret/exam/db | grep current_version | awk '{print $2}' | tr -d '\r\n ')" = "2" ]
---
vlt kv put secret/exam/db password=rotated-pass >/dev/null 2>&1
X

part "PART · MODULE FINAL"

final "Deploy with secrets from Vault only" "Exam 1 of 3. Run the API image devlab-api:lab as a container named exam-vault-api on host port 5004 whose JWT_SECRET comes FROM VAULT (the value of secret/devlab/api field jwt_secret) and whose ADMIN_PASSWORD is the field admin_password. It must become healthy." "docker run -d --name exam-vault-api -p 5004:5000 -e JWT_SECRET=\"\$(vlt kv get -field=jwt_secret secret/devlab/api)\" -e ADMIN_PASSWORD=\"\$(vlt kv get -field=admin_password secret/devlab/api)\" devlab-api:lab" <<'X'
docker image inspect devlab-api:lab >/dev/null 2>&1 || docker build -q -f 02-containers/Dockerfile.api -t devlab-api:lab app/api >/dev/null 2>&1; docker rm -f exam-vault-api >/dev/null 2>&1
---
[ "$(docker inspect -f '{{.State.Health.Status}}' exam-vault-api 2>/dev/null)" = healthy ] && docker inspect -f '{{range .Config.Env}}{{println .}}{{end}}' exam-vault-api | grep -q "^JWT_SECRET=$(vlt kv get -field=jwt_secret secret/devlab/api | tr -d '\r\n')"
---
docker run -d --name exam-vault-api -p 5004:5000 -e JWT_SECRET="$(vlt kv get -field=jwt_secret secret/devlab/api)" -e ADMIN_PASSWORD="$(vlt kv get -field=admin_password secret/devlab/api)" devlab-api:lab >/dev/null 2>&1; sleep 28
---
docker rm -f exam-vault-api >/dev/null 2>&1
X

final "Look back in time" "Exam 2 of 3. You just rotated secret/exam/db. Retrieve the OLD password (version 1) and save only its value into playground/old.txt." "vlt kv get -version=1 -field=password secret/exam/db" <<'X'
rm -f playground/old.txt
---
[ "$(tr -d '[:space:]' < playground/old.txt)" = "exam-db-pass" ]
---
vlt kv get -version=1 -field=password secret/exam/db > playground/old.txt
X

final "Revoke a leaked token" "Exam 3 of 3. The token saved in playground/leaked.txt was found in a public paste. Revoke it NOW, so it can no longer read anything." "vlt token revoke \"\$(cat playground/leaked.txt)\"" <<'X'
vlt token create -policy=exam-ro -field=token > playground/leaked.txt
---
! VAULT_TOKEN_LAB=$(cat playground/leaked.txt) vlt kv get secret/exam/db >/dev/null 2>&1
---
vlt token revoke "$(cat playground/leaked.txt)" >/dev/null 2>&1
---
docker rm -f lab-vault exam-vault-api >/dev/null 2>&1
X
