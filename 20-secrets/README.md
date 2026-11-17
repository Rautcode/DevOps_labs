# 20 · Secrets management with Vault (Extra, ~2h)

> **Guided version:** run `bash lab.sh 20` from the repo root. It explains each step, has you type the commands yourself, and checks your hands-on tasks. This page is the reference. **Unlocks after module 03.**

**Goal:** keep secrets out of git and images: store them in HashiCorp Vault, grant least-privilege access with policies and short-lived tokens, rotate them, deploy an app with secrets pulled at deploy time, and revoke a leaked token.

The shortcut `vlt CMD` runs the `vault` CLI inside the practice Vault container (`lab-vault`, dev mode, root token `lab-root`). `VAULT_TOKEN_LAB=<token> vlt ...` runs a command as a different token.

> Dev mode keeps everything in memory and uses a known root token. It is for learning only. Production Vault needs storage, unsealing, TLS, auth methods and audit logging.

## Cheat sheet
| Task | Command |
|---|---|
| Store / read | `vlt kv put secret/app key=value`, `vlt kv get -field=key secret/app` |
| Older version | `vlt kv get -version=1 secret/app` |
| Policy | `printf 'path "secret/data/app/*" {\n  capabilities = ["read"]\n}\n' \| vlt policy write app-ro -` |
| Token for a policy | `vlt token create -policy=app-ro -ttl=1h -field=token` |
| Revoke | `vlt token revoke <token>` |

Note: in KV v2 the policy path has an extra `data/` (`secret/data/app/*`) while the CLI path does not.

## Concepts
- **Why not `.env` in git:** history is permanent and copied to every clone; a committed secret is a leaked secret and must be rotated.
- **Policies and tokens** give each application only the paths it needs, and tokens expire and can be revoked.
- **Injection at deploy time:** the deploy script fetches values and passes them as environment variables. Remember `docker inspect` shows them, so high-security setups use mounted files or a Vault agent.
- **Kubernetes:** Secrets are only base64. Use External Secrets Operator, the Secrets Store CSI driver, Sealed Secrets or SOPS, and restrict who may read Secrets with RBAC (module 14).

## Break it
1. Use the read-only token to write and read the exact error.
2. Revoke the token while the app still runs: what keeps working, and what fails on the next restart?
3. Delete a secret version and try to read it.

## Industry notes
Prefer short-lived dynamic credentials (database users created on demand), audit every read, rotate regularly, and keep break-glass access tightly controlled. Cloud alternatives: AWS Secrets Manager, Azure Key Vault, GCP Secret Manager.
