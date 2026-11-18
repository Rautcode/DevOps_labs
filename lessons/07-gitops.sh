# GitOps: git is the source of truth (about 1.5h)
title "Module 07 · GitOps"
mission "A colleague changed the live cluster by hand at 2am and nobody knows what they did. Your mission: make Git the only way to change the cluster, so every change is reviewed, recorded and reversible."
explain "GitOps: you never change the cluster by hand. You change files in git, and a controller (Argo CD) makes the cluster match. Every change is reviewed, recorded, and can be undone with git revert. This lesson shows the pieces locally; the optional last part installs Argo CD itself."

part "PART A · Environments are just folders"
learn "Kustomize: base plus overlays" "A base holds what all environments share. An overlay for dev or prod patches only the differences (namespace, image tags, replicas). kubectl kustomize renders the final YAML so you can review it and validate it before anything is applied."
say "How do you manage config for several environments in Kubernetes?" "With Kustomize I keep a base with the manifests all environments share, and an overlay per environment, such as dev and prod, that patches only the differences, like replicas, image tags or resources. It is plain YAML without templating and is built into kubectl, and it keeps environments consistent. Helm is the alternative when I want templated, packaged charts."
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
learn "Argo CD" "Argo CD runs inside the cluster and watches a git repository. When git changes it applies the change (pull model, so CI needs no cluster password). With selfHeal on it undoes manual changes, and with prune on it removes things you deleted from git."
say "What is GitOps, and how does Argo CD work?" "GitOps means Git is the single source of truth for what runs in the cluster. Argo CD runs in the cluster, watches a Git repository and keeps the cluster in sync with it. If someone changes the cluster by hand, it detects the drift and can revert it. Every change is reviewed in a pull request and recorded in the history."
art "The GitOps loop" <<'ART'
   you change a file  ->  Git (source of truth)
                              ^        |
                              |        v
                         Argo CD compares git with the cluster
                              |
                              v
                      cluster is changed to MATCH git
ART
mcq "In GitOps, how do you change the live cluster?" "By editing files in Git and letting a controller apply them|By running kubectl edit on the server|By logging into the node|By restarting Argo CD" 1 "Git is the only door. That gives review, history and an easy rollback (git revert)."
step "Read the file that tells Argo CD what to watch" "repoURL (your GitHub repo), path (06-kubernetes/overlays/dev), and syncPolicy with prune and selfHeal." <<'CMD'
cat 07-gitops/argocd-app.yaml
CMD
quiz "With selfHeal on, what does Argo CD do if someone runs 'kubectl scale' by hand?" "revert|undo|heal|reset|overwrit|back|match|git" "It reverts the change, because the cluster must match what is in git. Manual changes do not stick."

part "PART C · Hands-on: make a change the GitOps way"
learn "Changes go through git" "In GitOps nobody edits the live cluster. You change files, open a pull request, a colleague reviews, the merge happens, and the cluster follows. Rolling back is git revert. Your git history becomes the audit log."
say "How do you roll back a bad release with GitOps?" "I revert the commit in Git and let the controller apply it. Nobody edits the live cluster by hand, so the history shows exactly what changed and who approved it, and a rollback is just another reviewed commit. It is auditable and repeatable, which is the whole point of GitOps."
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
deeper "argocd-in-one-shot (Shubham Londhe)|https://github.com/LondheShubham153/argocd-in-one-shot" "Jenkins + Argo CD GitOps (Abhishek Veeramalla)|https://github.com/iam-veeramalla/Jenkins-Zero-To-Hero"
explain "Done! Next: bash lab.sh 08"
