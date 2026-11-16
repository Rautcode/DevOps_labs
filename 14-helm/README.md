# 14 · Helm and RBAC (Specialist, ~2.5h)

> **Guided version:** run `bash lab.sh 14` from the repo root. It explains each step, runs it for you, and checks your hands-on tasks. This page is the reference.

**Goal:** package the app as a Helm chart (install, upgrade, roll back) and control access with Kubernetes RBAC.

| File | What it is |
|---|---|
| [devlab/](devlab) | the Helm chart: `Chart.yaml`, `values.yaml`, templates for the API, web and secret |
| [helm.sh](helm.sh) | runs Helm in Docker; it joins the lab cluster's network so it can reach the cluster |
| [rbac.yaml](rbac.yaml) | a read-only `viewer` ServiceAccount: Role + RoleBinding |

## Helm
```bash
bash 06-kubernetes/cluster.sh up
bash 14-helm/helm.sh lint 14-helm/devlab
bash 14-helm/helm.sh template devlab 14-helm/devlab -n devlab-helm | less            # what would be created
bash 14-helm/helm.sh install devlab 14-helm/devlab -n devlab-helm --create-namespace --wait
bash 14-helm/helm.sh upgrade devlab 14-helm/devlab -n devlab-helm --set web.replicas=3 --wait
bash 14-helm/helm.sh rollback devlab 1 -n devlab-helm --wait
```
- **Chart** = reusable template package. **Values** = the settings you pass. **Release** = one installed instance. **Revision** = each change, kept so you can roll back.
- The API template carries a `checksum/secret` annotation: change the secret and the pod rolls automatically.
- **Helm vs Kustomize** (module 06): Kustomize patches plain YAML (simple, no templating); Helm templates and packages (powerful, shareable, more moving parts). Many teams use both.

## RBAC
```bash
kubectl apply -n devlab-helm -f 14-helm/rbac.yaml
kubectl auth can-i list pods   -n devlab-helm --as=system:serviceaccount:devlab-helm:viewer   # yes
kubectl auth can-i delete pods -n devlab-helm --as=system:serviceaccount:devlab-helm:viewer   # no
```
- **Role** = what is allowed. **RoleBinding** = who gets it. A Role works only inside its namespace (use ClusterRole for cluster-wide).
- Kubernetes Secrets are base64-encoded, **not encrypted**. Anyone allowed to `get secrets` can read them, so RBAC is the real protection (plus encryption at rest and an external secret manager).

## Break it
1. Add a `delete` verb to the Role and re-check `can-i`.
2. `helm upgrade --set web.replicas=abc` and read the error. Add a `values.schema.json` so Helm rejects bad values before deploying.
3. Remove the `pods/log` permission from a role and try `kubectl logs --as=...`.

## Industry notes
- Pin chart versions and store charts in an OCI registry; render with `helm template` in CI and validate with kubeconform (as module 07 does for Kustomize).
- Bind RBAC to **groups** from your identity provider, not to individuals; audit with `kubectl auth can-i --list`.
- Never grant `cluster-admin` to apps or pipelines.

**Next:** [15 · Logging and tracing](../15-logging/README.md)
