# GitOps: git is the source of truth (about 1.5h)
title "Module 07 · GitOps"
explain "GitOps: you never change the cluster by hand. You change files in git, and a controller (Argo CD) makes the cluster match. Every change is reviewed, recorded, and can be undone with git revert. This lesson shows the pieces locally; the optional last part installs Argo CD itself."

part "PART A · Environments are just folders"
step "Render the DEV environment and count what it contains" "A list of resource kinds (Deployment, StatefulSet, Service, NetworkPolicy...). Kustomize combines the base plus the dev changes." <<'CMD'
kubectl kustomize 06-kubernetes/overlays/dev | grep "^kind:" | sort | uniq -c
CMD
step "What is DIFFERENT between dev and prod?" "Lines starting with < are dev, > are prod: namespace, image tags, replicas, disk size. Promotion between environments is a pull request on these files." <<'CMD'
diff <(kubectl kustomize 06-kubernetes/overlays/dev) <(kubectl kustomize 06-kubernetes/overlays/prod) | head -40 || true
CMD
step "Validate the manifests against the Kubernetes schema" "Valid: 11, Invalid: 0. CI can run this on every pull request." <<'CMD'
kubectl kustomize 06-kubernetes/overlays/dev | docker run --rm -i ghcr.io/yannh/kubeconform:latest -strict -summary -
CMD

part "PART B · The Argo CD application"
step "Read the file that tells Argo CD what to watch" "repoURL (your GitHub repo), path (06-kubernetes/overlays/dev), and syncPolicy with prune and selfHeal." <<'CMD'
cat 07-gitops/argocd-app.yaml
CMD
quiz "With selfHeal on, what does Argo CD do if someone runs 'kubectl scale' by hand?" "revert|undo|heal|reset|overwrit|back|match|git" "It reverts the change, because the cluster must match what is in git. Manual changes do not stick."

part "PART C · Hands-on: make a change the GitOps way"
task "Create an overlay that runs 5 web replicas" "Create playground/overlay-test/kustomization.yaml that uses the base (resources: ../../06-kubernetes/base) and sets the devlab-web replicas to 5 using a 'replicas:' list (name: devlab-web, count: 5). Check it with: kubectl kustomize playground/overlay-test | grep replicas" "Format:  replicas:  then  - name: devlab-web  then  count: 5" <<'X'
kubectl kustomize playground/overlay-test | grep -q "replicas: 5"
---
mkdir -p playground/overlay-test && printf 'apiVersion: kustomize.config.k8s.io/v1beta1\nkind: Kustomization\nresources:\n  - ../../06-kubernetes/base\nreplicas:\n  - name: devlab-web\n    count: 5\n' > playground/overlay-test/kustomization.yaml
X
quiz "How do you roll back a bad deployment in GitOps?" "revert|git|previous|commit|undo" "git revert the commit (or merge a fix). Argo CD syncs the cluster back. Your git history is the audit trail."

explain "OPTIONAL (needs your repo pushed to GitHub): install Argo CD on the cluster from module 06 with these commands:"
explain "  bash 06-kubernetes/cluster.sh up && export KUBECONFIG=\$(pwd -W 2>/dev/null || pwd)/.kube/config"
explain "  kubectl create namespace argocd"
explain "  kubectl apply -n argocd --server-side -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml"
explain "  kubectl apply -f 07-gitops/argocd-app.yaml"
explain "Then change replicas in an overlay, push, and watch Argo CD update the cluster (about 3 minutes). Details: 07-gitops/README.md"
explain "Done! Next: bash lab.sh 08"
