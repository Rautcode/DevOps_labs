# 07 · GitOps with Argo CD (Advanced, ~4h)

> **Guided version:** run `bash lab.sh 07` from the repo root. It explains each step, has you type the commands yourself, and checks your hands-on tasks. This page is the reference.

**Goal:** git becomes the only way to change the cluster. A controller continuously reconciles the cluster to what is in git, reverting any manual change.

| File | Purpose |
|---|---|
| [argocd-app.yaml](argocd-app.yaml) | an Argo CD `Application` pointing at `06-kubernetes/overlays/dev` with auto-sync, prune and self-heal |

> Status: the manifest it deploys was verified on a real cluster (module 06). The Argo CD install and sync loop are **not** run by the lab author; follow the steps and report anything that differs.

## Do it
You need your repo pushed to GitHub (the `repoURL` in the file points to this repo; change it if you forked).
```bash
bash 06-kubernetes/cluster.sh up && export KUBECONFIG="$(pwd -W 2>/dev/null || pwd)/.kube/config"
kubectl create namespace argocd
kubectl apply -n argocd --server-side -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl -n argocd rollout status deploy/argocd-server
kubectl apply -f 07-gitops/argocd-app.yaml
kubectl -n argocd port-forward svc/argocd-server 8443:443        # https://localhost:8443  (user: admin)
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d
```
Images are local (`devlab-*:lab`), loaded by `cluster.sh`, so the Application can sync without a registry.

## Experiments (this is the whole point)
1. **Git drives the cluster.** Edit `replicas` in an overlay patch, commit, push. Within ~3 minutes the Application syncs. Check the UI.
2. **Self-heal.** `kubectl -n devlab-dev scale deploy/devlab-web --replicas=5`. Argo CD reverts it. Manual changes do not stick.
3. **Prune.** Delete a manifest from git: the object is removed from the cluster.
4. **Rollback = `git revert`.** The audit trail is your git history.
5. **Expert:** app-of-apps (one Application that creates the `dev` and `prod` Applications), `ApplicationSet` per environment, Argo Rollouts for canary, an image-updater that opens PRs when CI publishes a new tag.

## Concepts
- **Pull vs push deployment.** CI never needs cluster credentials: smaller blast radius. The cluster pulls.
- **Drift detection and self-healing** replace "who changed prod?".
- **Environments are folders**, promotion is a PR.

**Next:** [08 · Observability](../08-observability/README.md)
