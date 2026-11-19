# Helm and RBAC: package apps and control who can do what (about 2.5h)
title "Module 14 · Helm and RBAC"
mission "Installing the same app in dev, staging and production with copied YAML files is a mess, and everybody having admin rights is a risk. Your mission: package the app as a Helm chart and give each person only the access they need."
explain "Helm is the package manager for Kubernetes: one chart plus a few settings (values) installs a whole app, and upgrades and rollbacks are one command. RBAC decides who may do what in the cluster. Both appear in almost every real Kubernetes job."

part "PART A · Get a cluster and look at the chart"
learn "Helm: a package manager for Kubernetes" "A chart is a folder of templates. Values are the settings you pass in. A release is one installed copy of a chart, and every change creates a new revision you can roll back to. helm template shows the YAML a chart would create without installing anything."
say "What is Helm?" "Helm is the package manager for Kubernetes. A chart is a set of templated manifests, and values let me configure each install, for example per environment. I can install, upgrade and roll back a release with single commands, and Helm keeps a history of releases. It is great for third-party software and for packaging my own apps consistently."
art "Helm chart plus values" <<'ART'
   chart (templates)  +  values (your settings)
                |
                v
   helm install  ->  rendered Kubernetes YAML  ->  running app
   helm upgrade / helm rollback  = one command each
ART
why "docker image inspect::check the images|dc build::build them if needed" "The cluster needs the app images. Check first to avoid rebuilding."
step "Make sure the app images exist" "Images listed." ok 'devlab-api' <<'CMD'
docker image inspect devlab-api:lab devlab-web:lab >/dev/null 2>&1 || dc build 2>&1 | tail -2; docker images --format '{{.Repository}}:{{.Tag}}' | grep devlab
CMD
why "cluster.sh up::start a small practice Kubernetes cluster" "Helm installs software into a cluster, so we need a cluster first."
step "Create the cluster (about 30 seconds)" "cluster ready" ok 'cluster ready' <<'CMD'
bash 06-kubernetes/cluster.sh up 2>&1 | tail -2
CMD
why "lab-helm lint::run the Helm chart checker in a container" "Linting catches mistakes in the chart before you install it, such as bad YAML or missing values."
step "Lint the chart (like a spell-checker for charts)" "1 chart(s) linted, 0 chart(s) failed" ok '0 chart\(s\) failed' <<'CMD'
lab-helm lint 14-helm/devlab 2>&1 | tail -2
CMD
why "helm template::turn the templates into plain YAML, install nothing|grep ^kind::list the object types" "Charts are templates plus values. Rendering shows exactly what would be created, like a plan. You always want to see this before installing."
step "Render the chart WITHOUT installing: what would it create?" "Secret, 2 Services, Deployment, StatefulSet. 'helm template' turns chart + values into plain Kubernetes YAML." ok 'StatefulSet' <<'CMD'
lab-helm template devlab 14-helm/devlab -n devlab-helm | grep "^kind:" | sort | uniq -c
CMD
why "--set web.replicas=5::override one value from the command line|grep -m1::show the first matching line" "The same chart produces different YAML for different values. That is how one chart serves dev and prod."
step "Change a value and see the difference in the YAML" "replicas: 5. One setting changed the output. That is the whole idea of values." ok 'replicas: 5' <<'CMD'
lab-helm template devlab 14-helm/devlab -n devlab-helm --set web.replicas=5 | grep -m1 "replicas: 5"
CMD
quiz "What is the difference between a chart and its values?" "template|default|settings|setting|config|package|change|override" "The chart is the reusable template (the package). Values are the settings you pass in, so the same chart can install dev, staging and prod differently."

part "PART B · Install, upgrade, roll back"
why "helm install devlab::install a release named devlab|--create-namespace::create the namespace|--wait::wait until the pods are ready" "A release is one installed copy of a chart. Helm remembers it, so it can upgrade or roll back later."
step "Install the app with Helm" "STATUS: deployed. Helm waited until everything was ready (--wait)." ok 'STATUS: deployed' <<'CMD'
lab-helm install devlab 14-helm/devlab -n devlab-helm --create-namespace --wait --timeout 240s 2>&1 | grep -E "NAME:|STATUS:|REVISION:"
CMD
why "helm list::show the releases in this namespace" "Like a package manager list: what is installed, at which revision, and what its status is."
step "See what is installed" "A release called devlab at REVISION 1." ok 'devlab' <<'CMD'
lab-helm list -n devlab-helm
CMD
why "curl localhost:30080/healthz::ask the app" "Prove that what Helm installed actually works."
step "Use the app" '{"ok":true} through http://localhost:30080' ok '"ok":true' <<'CMD'
curl -s localhost:30080/healthz
CMD
why "helm upgrade::apply a change to the release|--set web.replicas=3::the new value" "An upgrade makes a new revision. Helm keeps the old ones, which is what makes rollback possible."
step "Upgrade: run 3 web copies" "REVISION 2. Helm changed only what differed." ok 'REVISION: 2' <<'CMD'
lab-helm upgrade devlab 14-helm/devlab -n devlab-helm --set web.replicas=3 --wait --timeout 240s 2>&1 | grep -E "STATUS:|REVISION:"; kubectl -n devlab-helm get deploy devlab-web
CMD
why "helm rollback devlab 1::go back to revision 1|helm history::list all revisions" "A bad release is fixed with one command. The history shows every revision, including the rollback itself."
step "Roll back to revision 1" "Rollback was a success. Helm remembers every revision, so undo is one command." ok 'Rollback was a success' <<'CMD'
lab-helm rollback devlab 1 -n devlab-helm --wait 2>&1 | tail -1; lab-helm history devlab -n devlab-helm
CMD
task "Upgrade to 4 web copies" "Run: bash 14-helm/helm.sh upgrade devlab 14-helm/devlab -n devlab-helm --set web.replicas=4 --wait   and wait until it finishes." "The check passes when 4 web pods are ready in the devlab-helm namespace." <<'X'
[ "$(kubectl -n devlab-helm get deploy devlab-web -o jsonpath='{.status.readyReplicas}')" = "4" ]
---
lab-helm upgrade devlab 14-helm/devlab -n devlab-helm --set web.replicas=4 --wait --timeout 240s
X
quiz "Why is 'helm rollback' safer than editing files by hand under pressure?" "revision|history|remember|one command|undo|known|previous|safe|fast" "Helm stores every revision of a release, so going back to a known-good state is one command instead of reconstructing old files."

part "PART C · RBAC: who may do what"
explain "By default a new Kubernetes account can do nothing. You grant exact permissions with a Role (what is allowed) and a RoleBinding (who gets it). Least privilege again."
learn "RBAC: who may do what" "By default a new account can do nothing. A Role lists allowed actions (verbs like get and list) on resources (like pods). A RoleBinding gives that Role to a user or ServiceAccount. Grant the smallest set that works (least privilege), and test it with kubectl auth can-i."
say "How does Kubernetes RBAC work?" "By default an account can do nothing. A Role lists allowed verbs on resources in a namespace, and a RoleBinding gives that role to a user or service account. ClusterRoles work cluster-wide. I follow least privilege, give each workload its own service account, and test permissions with kubectl auth can-i."
art "RBAC" <<'ART'
   WHO              CAN DO WHAT            WHERE
   [ServiceAccount] --RoleBinding--> [Role: get,list pods] in namespace dev
   default answer = NO. You add only what is needed (least privilege).
ART
mcq "What does RBAC do by default for a new account?" "Allows nothing until you grant it|Allows everything|Allows only reading|Asks the user" 1 "Deny by default, then grant the least privilege."
why "kubectl apply -f rbac.yaml::create a service account, a role and a binding" "RBAC is about who may do what. We make an account that can only read pods, following the rule of least privilege."
step "Create a 'viewer' account that may only read pods" "serviceaccount, role and rolebinding created." ok 'rolebinding' <<'CMD'
kubectl apply -n devlab-helm -f 14-helm/rbac.yaml
CMD
why "kubectl auth can-i list pods::ask whether an action is allowed|--as=...viewer::pretend to be that account" "can-i is a safe way to test permissions without logging in as the account. Expect yes."
step "Can the viewer LIST pods?" "yes" ok '^yes' <<'CMD'
kubectl auth can-i list pods -n devlab-helm --as=system:serviceaccount:devlab-helm:viewer
CMD
why "kubectl auth can-i delete pods::ask about deleting|--as=...viewer::as the viewer" "Expect no. The role gives only read access, so anything else is denied. Testing the no answers is as important as the yes."
step "Can the viewer DELETE pods?" "no. Reading is allowed, deleting is not." fail '^no' <<'CMD'
kubectl auth can-i delete pods -n devlab-helm --as=system:serviceaccount:devlab-helm:viewer
CMD
why "kubectl auth can-i get secrets::ask about reading secrets" "Expect no. Secrets must be reachable only by those who need them. Least privilege in practice."
step "Can the viewer read SECRETS?" "no. Secrets stay private to those who need them." fail '^no' <<'CMD'
kubectl auth can-i get secrets -n devlab-helm --as=system:serviceaccount:devlab-helm:viewer
CMD
why "can-i list pods -n default::ask in a different namespace" "Expect no. A Role is limited to one namespace, so the account has no power elsewhere."
step "Can the viewer list pods in ANOTHER namespace?" "no. A Role only works inside its own namespace." fail '^no' <<'CMD'
kubectl auth can-i list pods -n default --as=system:serviceaccount:devlab-helm:viewer
CMD
task "Let the viewer also read pod LOGS" "Reading logs is a separate permission (pods/log). Create playground/rbac-logs.yaml with a Role called log-reader (apiGroups [\"\"], resources [\"pods/log\"], verbs [\"get\"]) and a RoleBinding called viewer-logs that binds it to the ServiceAccount viewer, all in namespace devlab-helm. Apply it: kubectl apply -f playground/rbac-logs.yaml   Then check: kubectl auth can-i get pods --subresource=log -n devlab-helm --as=system:serviceaccount:devlab-helm:viewer" "Model it on 14-helm/rbac.yaml. Put 'namespace: devlab-helm' in each metadata block. The roleRef must name the Role log-reader." <<'X'
kubectl auth can-i get pods --subresource=log -n devlab-helm --as=system:serviceaccount:devlab-helm:viewer | grep -qx yes
---
printf 'apiVersion: rbac.authorization.k8s.io/v1\nkind: Role\nmetadata:\n  name: log-reader\n  namespace: devlab-helm\nrules:\n  - apiGroups: [""]\n    resources: ["pods/log"]\n    verbs: ["get"]\n---\napiVersion: rbac.authorization.k8s.io/v1\nkind: RoleBinding\nmetadata:\n  name: viewer-logs\n  namespace: devlab-helm\nsubjects:\n  - kind: ServiceAccount\n    name: viewer\n    namespace: devlab-helm\nroleRef:\n  kind: Role\n  name: log-reader\n  apiGroup: rbac.authorization.k8s.io\n' > playground/rbac-logs.yaml && kubectl apply -f playground/rbac-logs.yaml
X
why "jsonpath .data.JWT_SECRET::pick one field from the secret|base64 -d::decode it" "Anyone who can read the Secret object can decode it in one step. base64 is a format, not protection. Use RBAC, encryption at rest and a secret manager."
step "A reminder: Kubernetes Secrets are encoded, NOT encrypted" "The real JWT secret in plain text. base64 is just a format. Anyone with 'get secrets' permission can read it, which is why RBAC matters." ok 'lab-only-jwt' <<'CMD'
kubectl -n devlab-helm get secret devlab-secrets -o jsonpath='{.data.JWT_SECRET}' | base64 -d; echo
CMD
quiz "What is the difference between a Role and a RoleBinding?" "who|what|permission|bind|subject|account|grant|allowed" "A Role lists WHAT is allowed. A RoleBinding says WHO gets it. You need both."

part "PART D · Clean up"
why "helm uninstall::remove everything the release created|cluster.sh down::delete the practice cluster" "Clean up completely, so the next module starts fresh."
step "Uninstall the release and delete the cluster" "release uninstalled, cluster removed" ok 'cluster removed' <<'CMD'
lab-helm uninstall devlab -n devlab-helm 2>&1 | tail -1; bash 06-kubernetes/cluster.sh down
CMD

deeper "Kubernetes Zero to Hero (Abhishek Veeramalla)|https://github.com/iam-veeramalla/Kubernetes-Zero-to-Hero"
explain "Done! Next: bash lab.sh 15"
