# Module 14 · interview and final (sourced by lab.sh)
part "PART · INTERVIEW"

interview "Scale a release with Helm" "Interviewer: 'The Helm release devlab (namespace devlab-helm) is live. Black Friday: change the release so the web runs 3 replicas, using Helm (not kubectl scale), and wait until all 3 are ready.'" "lab-helm upgrade devlab 14-helm/devlab -n devlab-helm --set web.replicas=3 --wait" <<'X'
bash 06-kubernetes/cluster.sh up >/dev/null 2>&1; lab-helm install devlab 14-helm/devlab -n devlab-helm --create-namespace --wait --timeout 240s >/dev/null 2>&1
---
[ "$(kubectl -n devlab-helm get deploy devlab-web -o jsonpath='{.status.readyReplicas}')" = "3" ]
---
lab-helm upgrade devlab 14-helm/devlab -n devlab-helm --set web.replicas=3 --wait --timeout 240s >/dev/null 2>&1
X

interview "Undo it" "Interviewer: 'The traffic spike is over, and the upgrade caused a problem. Roll the release back to revision 1 with Helm. I will check the web is back to its original size.'" "lab-helm history devlab -n devlab-helm  shows revisions. lab-helm rollback devlab 1 -n devlab-helm --wait" <<'X'
true
---
[ "$(kubectl -n devlab-helm get deploy devlab-web -o jsonpath='{.spec.replicas}')" = "2" ]
---
lab-helm rollback devlab 1 -n devlab-helm --wait >/dev/null 2>&1
X

part "PART · MODULE FINAL"

final "Render without installing" "Exam 1 of 3. A reviewer wants to see what the chart would create with 5 web replicas, WITHOUT installing anything. Render it and save the replicas line into playground/render.txt." "lab-helm template devlab 14-helm/devlab --set web.replicas=5 | grep replicas" <<'X'
rm -f playground/render.txt
---
grep -q 'replicas: 5' playground/render.txt
---
lab-helm template devlab 14-helm/devlab -n devlab-helm --set web.replicas=5 | grep -m1 'replicas: 5' > playground/render.txt
X

final "A least-privilege deployer" "Exam 2 of 3. Create a ServiceAccount named deployer in the namespace devlab-helm that may create and delete DEPLOYMENTS (apiGroup apps) in that namespace, and nothing else. Save your YAML as playground/exam-rbac.yaml and apply it. I will ask the cluster what deployer may do." "Three objects: ServiceAccount deployer, Role (apiGroups [apps], resources [deployments], verbs [create, delete]), RoleBinding. Model it on 14-helm/rbac.yaml. Apply with kubectl apply -f playground/exam-rbac.yaml" <<'X'
kubectl -n devlab-helm delete rolebinding deployer-binding >/dev/null 2>&1; kubectl -n devlab-helm delete role deployer-role >/dev/null 2>&1; kubectl -n devlab-helm delete sa deployer >/dev/null 2>&1; rm -f playground/exam-rbac.yaml
---
S="--as=system:serviceaccount:devlab-helm:deployer"; [ "$(kubectl auth can-i create deployments.apps -n devlab-helm $S)" = yes ] && [ "$(kubectl auth can-i delete deployments.apps -n devlab-helm $S)" = yes ] && [ "$(kubectl auth can-i delete pods -n devlab-helm $S)" = no ] && [ "$(kubectl auth can-i get secrets -n devlab-helm $S)" = no ]
---
printf 'apiVersion: v1\nkind: ServiceAccount\nmetadata:\n  name: deployer\n  namespace: devlab-helm\n---\napiVersion: rbac.authorization.k8s.io/v1\nkind: Role\nmetadata:\n  name: deployer-role\n  namespace: devlab-helm\nrules:\n  - apiGroups: ["apps"]\n    resources: ["deployments"]\n    verbs: ["create", "delete"]\n---\napiVersion: rbac.authorization.k8s.io/v1\nkind: RoleBinding\nmetadata:\n  name: deployer-binding\n  namespace: devlab-helm\nsubjects:\n  - kind: ServiceAccount\n    name: deployer\n    namespace: devlab-helm\nroleRef:\n  kind: Role\n  name: deployer-role\n  apiGroup: rbac.authorization.k8s.io\n' > playground/exam-rbac.yaml && kubectl apply -f playground/exam-rbac.yaml >/dev/null 2>&1
X

final "Secrets are only encoded" "Exam 3 of 3. Prove that a Kubernetes Secret is merely encoded, not encrypted: read the JWT_SECRET from the secret devlab-secrets in devlab-helm, decode it, and save the plain text into playground/secret.txt." "kubectl -n devlab-helm get secret devlab-secrets -o jsonpath='{.data.JWT_SECRET}' | base64 -d > playground/secret.txt" <<'X'
rm -f playground/secret.txt
---
grep -q '^lab-only' playground/secret.txt
---
kubectl -n devlab-helm get secret devlab-secrets -o jsonpath='{.data.JWT_SECRET}' | base64 -d > playground/secret.txt
---
lab-helm uninstall devlab -n devlab-helm >/dev/null 2>&1; bash 06-kubernetes/cluster.sh down >/dev/null 2>&1
X
