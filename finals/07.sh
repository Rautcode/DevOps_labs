# Module 07 · interview and final (sourced by lab.sh)
part "PART · INTERVIEW"

interview "Promote with a new environment" "Interviewer: 'Production needs 4 web replicas and we do not touch the shared base. Create playground/exam-prod/kustomization.yaml that uses ../../06-kubernetes/base and sets the replicas of devlab-web to 4. Then kubectl kustomize must render replicas: 4.'" "Use a  replicas:  list with  - name: devlab-web  and  count: 4  . Compare with the playground/overlay-test file from lesson 07." <<'X'
rm -rf playground/exam-prod
---
kubectl kustomize playground/exam-prod 2>/dev/null | grep -q 'replicas: 4'
---
mkdir -p playground/exam-prod && printf 'apiVersion: kustomize.config.k8s.io/v1beta1\nkind: Kustomization\nresources:\n  - ../../06-kubernetes/base\nreplicas:\n  - name: devlab-web\n    count: 4\n' > playground/exam-prod/kustomization.yaml
X

interview "What differs between environments?" "Interviewer: 'In a pull request I want to see exactly what differs between dev and prod. Save the diff of the two rendered environments into playground/diff.txt.'" "diff <(kubectl kustomize 06-kubernetes/overlays/dev) <(kubectl kustomize 06-kubernetes/overlays/prod) > playground/diff.txt" <<'X'
rm -f playground/diff.txt
---
grep -q 'devlab-prod' playground/diff.txt && grep -q 'devlab-dev' playground/diff.txt
---
diff <(kubectl kustomize 06-kubernetes/overlays/dev) <(kubectl kustomize 06-kubernetes/overlays/prod) > playground/diff.txt; true
X

part "PART · MODULE FINAL"

final "Validate your overlay" "Exam 1 of 3. CI must reject invalid manifests. Render your playground/exam-prod overlay and validate it with kubeconform. Save the kubeconform summary line into playground/valid.txt. It must say there are 0 invalid resources." "kubectl kustomize playground/exam-prod | docker run --rm -i ghcr.io/yannh/kubeconform:latest -strict -summary - > playground/valid.txt" <<'X'
rm -f playground/valid.txt
---
grep -q 'Invalid: 0' playground/valid.txt && grep -qE 'Valid: [1-9]' playground/valid.txt
---
kubectl kustomize playground/exam-prod | docker run --rm -i ghcr.io/yannh/kubeconform:latest -strict -summary - > playground/valid.txt 2>&1; true
X

final "An Argo CD application" "Exam 2 of 3. Create playground/exam-app.yaml: an Argo CD Application named exam-app that deploys the path 06-kubernetes/overlays/dev and has automated sync with selfHeal turned on." "Start from 07-gitops/argocd-app.yaml. Change the name and keep path and syncPolicy (automated, prune, selfHeal)." <<'X'
rm -f playground/exam-app.yaml
---
grep -q 'name: exam-app' playground/exam-app.yaml && grep -q 'path: 06-kubernetes/overlays/dev' playground/exam-app.yaml && grep -q 'selfHeal: true' playground/exam-app.yaml
---
sed 's/name: devlab-dev/name: exam-app/' 07-gitops/argocd-app.yaml > playground/exam-app.yaml
X

final "Which image versions does prod use?" "Exam 3 of 3. Prod must run pinned image versions, never latest. Save the image lines of the rendered prod environment into playground/tags.txt. They must show v1.0.0." "kubectl kustomize 06-kubernetes/overlays/prod | grep image: > playground/tags.txt" <<'X'
rm -f playground/tags.txt
---
grep -q 'v1.0.0' playground/tags.txt && ! grep -q ':latest' playground/tags.txt
---
kubectl kustomize 06-kubernetes/overlays/prod | grep image: > playground/tags.txt
X
