# Kubernetes: run the app on a real cluster (about 3h)
title "Module 06 · Kubernetes"
mission "One container is a toy. Production needs copies that restart when they crash, update without downtime, and talk only to who they should. Your mission: run the app on a real Kubernetes cluster and break it on purpose to watch it heal."
explain "Kubernetes runs containers across machines and keeps them healthy: it restarts crashes, rolls out updates without downtime, and controls who can talk to whom. You will create a real cluster on your own computer (it runs inside one Docker container) and deploy the app."

part "PART A · Create the cluster and deploy"
learn "What Kubernetes does" "You declare the DESIRED state (for example: 2 copies of the web) and Kubernetes keeps reality matching it. A Pod runs your containers, a Deployment manages interchangeable pods, a StatefulSet manages pods that keep data, and a Service gives them a stable name. Kustomize overlays describe how dev and prod differ."
say "What does Kubernetes do?" "Kubernetes runs containers across machines and keeps them in the state I declare. I describe what I want, for example two copies of the web service, and controllers keep making reality match. It restarts crashed containers, rolls out updates without downtime, balances traffic through Services and enforces resource and network rules. The main objects are pods, deployments, services and config."
art "Kubernetes architecture (simplified)" <<'ART'
   you: kubectl apply -f ...            CLUSTER
          |                    +------------------------+
          v                    |  control plane         |
   [ API server ] ------------>|  (decides)             |
                               +-----------+------------+
                                           |
                       +-------------------+------------------+
                       |  node 1           |  node 2          |
                       |  [pod][pod]       |  [pod]           |
                       +-------------------+------------------+
ART
mcq "What do you give Kubernetes?" "The DESIRED state, and it keeps reality matching it|A list of commands to run once|Only container images|A server to log into" 1 "Kubernetes is declarative: you say what you want and controllers keep working until it is true."
why "docker image inspect::check that images exist locally|dc build::build them if they do not" "The cluster needs the app images, and the earlier modules may already have built them. Checking first saves a rebuild."
step "Make sure the app images exist" "Images listed (they were built in module 02)." <<'CMD'
docker image inspect devlab-api:lab devlab-web:lab >/dev/null 2>&1 || dc build 2>&1 | tail -2; docker images --format '{{.Repository}}:{{.Tag}}' | grep devlab
CMD
why "cluster.sh up::start a small Kubernetes cluster inside Docker" "A real cluster is many machines. This lab starts a tiny one (k3s) in a container, so you can learn the real commands on your laptop."
step "Create the cluster (about 30 seconds)" "'cluster ready'" <<'CMD'
bash 06-kubernetes/cluster.sh up 2>&1 | tail -2
CMD
why "kubectl::the Kubernetes command-line tool|get nodes::list the machines in the cluster" "A node is a machine that runs containers. Status Ready means the cluster is healthy and can accept work."
step "Look at the cluster's node" "One node with status Ready." <<'CMD'
kubectl get nodes
CMD
why "kubectl apply::send a description of what I want to the cluster|-k::use Kustomize to build the files|overlays/dev::the dev flavour of the app" "You do not tell Kubernetes what to do step by step. You describe the end result, and it makes it happen. Overlays let dev and prod share most settings."
step "Deploy the app (the 'dev' environment)" "A list of resources 'created': deployment, statefulset, services, networkpolicies..." <<'CMD'
kubectl apply -k 06-kubernetes/overlays/dev 2>&1 | tail -12
CMD
why "rollout status::wait until a deployment finishes starting|deploy/devlab-web::the web service|sts/devlab-api::the API (a StatefulSet)|--timeout=120s::give up after two minutes" "Pods take a moment to start and pass their health checks. Waiting for a rollout to finish is how you know it is safe to continue."
step "Wait until it is ready" "'successfully rolled out' for the web, and the api finished rolling out." <<'CMD'
kubectl -n devlab-dev rollout status deploy/devlab-web --timeout=120s; kubectl -n devlab-dev rollout status sts/devlab-api --timeout=120s
CMD
why "get pods,svc,pvc,hpa,pdb,networkpolicy::list several kinds of object at once|-n devlab-dev::in this namespace" "One apply created many objects: pods run the containers, services give them stable addresses, pvc is storage, hpa scales, pdb protects during updates, networkpolicy controls who may talk."
step "See everything that was created" "api pod (devlab-api-0), 2 web pods, services, a PVC (the disk), an autoscaler (hpa), a disruption budget (pdb), and network policies." <<'CMD'
kubectl -n devlab-dev get pods,svc,pvc,hpa,pdb,networkpolicy
CMD
why "curl localhost:30080/healthz::ask the app, through the port the cluster opened to your computer" "ok true proves the whole chain works: your request, the cluster, the web pod, the API pod."
step "Open the app" '{"ok":true}. The cluster publishes the web service on http://localhost:30080 (open it in your browser too).' <<'CMD'
curl -s localhost:30080/healthz
CMD

part "PART B · Self-healing and zero downtime"
learn "Self-healing" "Controllers constantly compare what you asked for with what exists and fix differences. Kill a pod and a new one appears. The new pod re-attaches the SAME disk (a PersistentVolumeClaim), so the data is still there. Probes tell Kubernetes when a pod is ready for traffic and when it must be restarted."
say "How does Kubernetes self-heal?" "Controllers continuously compare the desired state with the actual state. If a pod dies, the Deployment creates a replacement. Liveness probes restart containers that hang, readiness probes keep traffic away from pods that are not ready, and the pods of a failed node are rescheduled elsewhere. I demonstrated it by deleting a pod and watching a new one appear within seconds."
art "The control loop" <<'ART'
   desired: 2 pods  --+
                       +--> controller compares --> different? --> create or delete pods
   actual:  1 pod   --+                                      |
        ^                                                    |
        +----------------- checks again, forever <-----------+
ART
predict "You delete one pod of a Deployment that wants 2 copies. What happens in a few seconds?" "Nothing, it stays at 1|A new pod is created automatically|The Deployment is deleted too|Kubernetes asks you" 2 "The Deployment controller notices 1 pod is missing and creates a new one. That is self-healing."
why "curl -X POST::save a record through the API|kleads::the lab shortcut that counts leads in the cluster database" "You create real data first, so the next step can prove it survives a failure."
step "Create a lead, then count leads" "leads in database: 1" <<'CMD'
curl -s -X POST localhost:30080/api/inquiries -H "content-type: application/json" -d "{\"name\":\"K8s Test\",\"email\":\"k@example.com\"}" >/dev/null; kleads
CMD
why "kubectl delete pod::remove the running API pod|wait --for=condition=ready::wait until the replacement is ready" "We break it on purpose. Kubernetes notices that fewer pods exist than you asked for and creates a new one. This is self-healing."
step "Kill the API pod!" "pod deleted. Kubernetes notices and creates a new one." <<'CMD'
kubectl -n devlab-dev delete pod devlab-api-0 --wait=false; sleep 8; kubectl -n devlab-dev wait --for=condition=ready pod/devlab-api-0 --timeout=120s
CMD
why "kleads::count the leads again" "The data is still there. The pod was replaced, but its storage (a volume) stayed. Stateful apps need persistent storage to survive failures."
step "Count leads again" "leads in database: 1. The new pod re-attached the SAME disk (PVC), so no data was lost." <<'CMD'
kleads
CMD
why "rollout restart::replace the pods one by one|rollout status::wait until done" "A rolling update starts a new pod before stopping an old one, so users never see downtime. It is how every release should work."
step "Restart the web pods with a rolling update" "'successfully rolled out'. Old pods are replaced one by one while the site keeps working (maxUnavailable: 0)." <<'CMD'
kubectl -n devlab-dev rollout restart deploy/devlab-web; kubectl -n devlab-dev rollout status deploy/devlab-web --timeout=120s
CMD

part "PART C · Network security"
explain "The namespace has a 'default deny' NetworkPolicy: pods cannot talk to each other unless a rule allows it. Only web may talk to the api."
why "kubectl run probe --rm -i::start a temporary pod|busybox wget::a small web client|-T3::give up after 3 seconds" "A network policy allows only the web pod to talk to the API. The stranger should time out: that proves the rule works. The default in Kubernetes is that every pod can reach every other pod, which is why policies matter."
step "A stranger pod (from another namespace) tries to reach the API" "It TIMES OUT: wget: download timed out. The policy blocked it." fail <<'CMD'
kubectl run probe --rm -i --restart=Never --image=busybox:1.36 -- wget -qO- -T3 http://devlab-api.devlab-dev.svc.cluster.local:5000/healthz
CMD
why "kubectl exec deploy/devlab-web::run a command inside the web pod|wget::call the API address" "The same request from the allowed pod succeeds. Together with the previous step you have tested both sides of the rule."
step "The web pod (allowed by the policy) reaches the API" '{"ok":true}' <<'CMD'
kubectl -n devlab-dev exec deploy/devlab-web -- wget -qO- -T3 http://devlab-api.devlab-dev.svc.cluster.local:5000/healthz
CMD
quiz "Why block pods from talking to each other by default?" "attack|spread|lateral|least|limit|compromis|secur|blast" "If one pod is hacked it cannot reach everything else (smaller blast radius). You then allow only the connections you need."

part "PART D · Hands-on and a deliberate mistake"
learn "Scaling" "Stateless programs (like the web server) can run as many copies as you like. A program that keeps its data in a local file (like the API with SQLite) cannot, because each copy would have its own file. To scale the API you move its data to a shared database (module 16)."
say "How do you scale an application on Kubernetes?" "Stateless apps scale horizontally by changing the replica count, manually with kubectl scale or automatically with a Horizontal Pod Autoscaler based on CPU or other metrics. Requests and limits matter so the scheduler places pods sensibly. Stateful services like databases need more care, usually a StatefulSet with persistent volumes, or a managed database."
art "Scaling out" <<'ART'
   1 pod                     replicas: 3                      HPA decides
   [web]        -->    [web] [web] [web]     <--  CPU 80% -> add a copy, 20% -> remove one
   a Service spreads requests across all of them
ART
task "Scale the web to 4 copies" "Run: kubectl -n devlab-dev scale deploy/devlab-web --replicas=4   then wait until 4 are ready (kubectl -n devlab-dev get pods)." "Make sure you include -n devlab-dev (the namespace)." <<'X'
[ "$(kubectl -n devlab-dev get deploy devlab-web -o jsonpath='{.status.readyReplicas}')" = "4" ]
---
kubectl -n devlab-dev scale deploy/devlab-web --replicas=4 && kubectl -n devlab-dev rollout status deploy/devlab-web --timeout=120s
X
why "kubectl scale::change the number of copies|--replicas=2::two copies" "Scaling a stateless service is one command. Two copies also means one can fail without users noticing."
step "Scale web back to 2" "2 replicas." <<'CMD'
kubectl -n devlab-dev scale deploy/devlab-web --replicas=2; kubectl -n devlab-dev rollout status deploy/devlab-web --timeout=120s
CMD
why "scale sts/devlab-api --replicas=2::ask for two API pods|get pods and pvc::look at the result" "This breaks a rule on purpose. SQLite is a file that only one process may own, so a second copy cannot share it. The lesson: only stateless services scale this way."
step "Now the MISTAKE: scale the API (which uses SQLite) to 2" "Two api pods and TWO separate disks (data-devlab-api-0 and -1). Each has its OWN database. Leads would be split between them!" <<'CMD'
kubectl -n devlab-dev scale sts/devlab-api --replicas=2; sleep 25; kubectl -n devlab-dev get pods -l app.kubernetes.io/name=devlab-api; kubectl -n devlab-dev get pvc
CMD
why "scale ... --replicas=1::back to one copy" "In Kubernetes fixing a mistake is often one command, because the desired state is just a number you change."
step "Undo the mistake" "Back to 1 api pod." <<'CMD'
kubectl -n devlab-dev scale sts/devlab-api --replicas=1; sleep 10; kubectl -n devlab-dev get pods -l app.kubernetes.io/name=devlab-api
CMD
quiz "Why can the web scale to 4 but the API cannot? What would you change to scale the API?" "state|stateless|database|disk|sqlite|postgres|shared|volume|single" "The web is stateless so copies are interchangeable. The API keeps data in a local SQLite file, so copies would each have their own data. Move the data to a shared database such as Postgres."

part "PART E · Clean up"
why "cluster.sh down::remove the practice cluster" "Clean up so the next module starts fresh and your computer gets its memory back."
step "Delete the cluster" "cluster removed" <<'CMD'
bash 06-kubernetes/cluster.sh down
CMD

deeper "Kubernetes Zero to Hero (Abhishek Veeramalla)|https://github.com/iam-veeramalla/Kubernetes-Zero-to-Hero" "kubestarter (Shubham Londhe)|https://github.com/LondheShubham153/kubestarter" "Kubernetes on AWS EKS course (StackSimplify)|https://github.com/stacksimplify/aws-eks-kubernetes-masterclass"
explain "Done! Next: bash lab.sh 07"
