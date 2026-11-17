# 06 · Kubernetes (Intermediate to Advanced, ~8h)

> **Guided version:** run `bash lab.sh 06` from the repo root. It explains each step, has you type the commands yourself, and checks your hands-on tasks. This page is the reference.

**Goal:** run the app on a real cluster with probes, limits, autoscaling, zero-downtime rollouts and network isolation.

| Path | What |
|---|---|
| [cluster.sh](cluster.sh) | local cluster using only Docker (k3s). Alternative: [kind-config.yaml](kind-config.yaml) |
| [base/](base) | environment-agnostic manifests (Kustomize) |
| [overlays/dev](overlays/dev), [overlays/prod](overlays/prod) | per-environment differences only |

## Do it (from the repo root; build images first, modules 02/03)
```bash
bash 06-kubernetes/cluster.sh up
export KUBECONFIG="$(pwd -W 2>/dev/null || pwd)/.kube/config"
kubectl apply -k 06-kubernetes/overlays/dev
kubectl -n devlab-dev get pods -w                     # wait for Running 1/1, Ctrl-C
curl localhost:30080/healthz                        # {"ok":true} via the NodePort
bash 06-kubernetes/cluster.sh down              # when finished
```
**Check:** `devlab-api-0` and two `devlab-web-*` pods are `Running`, and the site opens at http://localhost:30080.

## Verified behaviours: try each one
```bash
kubectl -n devlab-dev get all,pvc,hpa,pdb,networkpolicy
kubectl -n devlab-dev logs devlab-api-0
kubectl -n devlab-dev delete pod devlab-api-0            # StatefulSet recreates it; the PVC (your data) survives
kubectl -n devlab-dev rollout restart deploy/devlab-web  # maxUnavailable: 0 -> zero-downtime
kubectl -n devlab-dev rollout status deploy/devlab-web
kubectl run probe --rm -it --restart=Never --image=busybox:1.36 -- wget -qO- -T3 http://devlab-api.devlab-dev.svc.cluster.local:5000/healthz
#   ^ a pod from ANOTHER namespace is blocked by the NetworkPolicy: it times out (wget: download timed out)
```

## What each manifest teaches
| Concept | Where |
|---|---|
| **StatefulSet + PVC** for a stateful single-writer DB | [base/api.yaml](base/api.yaml) |
| **Probes**: startup, readiness (gets traffic), liveness (gets restarted) | both workloads |
| **requests vs limits** | `resources:` |
| **Secure by default**: non-root, read-only root fs, dropped capabilities, seccomp | `securityContext:` |
| **Rolling update**, **HPA**, **PDB**, **topology spread** | [base/web.yaml](base/web.yaml) |
| **NetworkPolicy**: default-deny, then allow web→api only | [base/networkpolicy.yaml](base/networkpolicy.yaml) |
| **Kustomize** overlays, generators, patches | [overlays/](overlays) |
| **Pod Security Admission** (`restricted`) on the namespace | [overlays/dev/namespace.yaml](overlays/dev/namespace.yaml) |

## Lessons learned the hard way (all real bugs hit while building this lab)
1. nginx resolved the API at startup and **crash-looped** until the API existed → resolve per request (module 02).
2. nginx's `resolver` ignores Kubernetes DNS search domains, so `devlab-api` fails but `devlab-api.<namespace>.svc.cluster.local` works → see the `API_UPSTREAM` env in [web.yaml](base/web.yaml).
3. A `readOnlyRootFilesystem` nginx needs `emptyDir` mounts for `/tmp`, cache and `conf.d`.

## Exercises
1. `kubectl scale sts/devlab-api --replicas=3`. Submit the form on the site several times, then list leads with the admin API (`GET /api/inquiries`): why is the data inconsistent between requests? (Each replica has its **own** SQLite file.) What are the real fixes? (Single replica now; Postgres later; Litestream for replication.)
2. Install metrics-server, generate load (`hey` or a busybox loop) and watch the HPA scale `devlab-web` to 6.
3. Break the readiness path (`/nope`). Observe: pod `Running` but `0/1 Ready`, receives no traffic: this is how bad deploys are contained.
4. Render prod: `kubectl kustomize 06-kubernetes/overlays/prod`. What differs from dev? Why is there **no** Secret?
5. **Expert:** Write a Helm chart for the same app and compare to Kustomize. When would you pick each?

## Industry notes
- Declarative manifests live in git. Nobody runs `kubectl edit` in prod (module 07 enforces this).
- Secrets: External Secrets Operator / Sealed Secrets / SOPS: never literals in git (the dev overlay uses literals **for the lab only**).
- Use immutable image **digests** in prod and a registry you control.

**Next:** [07 · GitOps](../07-gitops/README.md)
