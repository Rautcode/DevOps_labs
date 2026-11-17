# Kubernetes: run the app on a real cluster (about 3h)
title "Module 06 · Kubernetes"
explain "Kubernetes runs containers across machines and keeps them healthy: it restarts crashes, rolls out updates without downtime, and controls who can talk to whom. You will create a real cluster on your own computer (it runs inside one Docker container) and deploy the app."

part "PART A · Create the cluster and deploy"
learn "What Kubernetes does" "You declare the DESIRED state (for example: 2 copies of the web) and Kubernetes keeps reality matching it. A Pod runs your containers, a Deployment manages interchangeable pods, a StatefulSet manages pods that keep data, and a Service gives them a stable name. Kustomize overlays describe how dev and prod differ."
step "Make sure the app images exist" "Images listed (they were built in module 02)." <<'CMD'
docker image inspect devlab-api:lab devlab-web:lab >/dev/null 2>&1 || dc build 2>&1 | tail -2; docker images --format '{{.Repository}}:{{.Tag}}' | grep devlab
CMD
step "Create the cluster (about 30 seconds)" "'cluster ready'" <<'CMD'
bash 06-kubernetes/cluster.sh up 2>&1 | tail -2
CMD
step "Look at the cluster's node" "One node with status Ready." <<'CMD'
kubectl get nodes
CMD
step "Deploy the app (the 'dev' environment)" "A list of resources 'created': deployment, statefulset, services, networkpolicies..." <<'CMD'
kubectl apply -k 06-kubernetes/overlays/dev 2>&1 | tail -12
CMD
step "Wait until it is ready" "'successfully rolled out' for the web, and the api finished rolling out." <<'CMD'
kubectl -n devlab-dev rollout status deploy/devlab-web --timeout=120s; kubectl -n devlab-dev rollout status sts/devlab-api --timeout=120s
CMD
step "See everything that was created" "api pod (devlab-api-0), 2 web pods, services, a PVC (the disk), an autoscaler (hpa), a disruption budget (pdb), and network policies." <<'CMD'
kubectl -n devlab-dev get pods,svc,pvc,hpa,pdb,networkpolicy
CMD
step "Open the app" '{"ok":true}. The cluster publishes the web service on http://localhost:30080 (open it in your browser too).' <<'CMD'
curl -s localhost:30080/healthz
CMD

part "PART B · Self-healing and zero downtime"
learn "Self-healing" "Controllers constantly compare what you asked for with what exists and fix differences. Kill a pod and a new one appears. The new pod re-attaches the SAME disk (a PersistentVolumeClaim), so the data is still there. Probes tell Kubernetes when a pod is ready for traffic and when it must be restarted."
step "Create a lead, then count leads" "leads in database: 1" <<'CMD'
curl -s -X POST localhost:30080/api/inquiries -H "content-type: application/json" -d "{\"name\":\"K8s Test\",\"email\":\"k@example.com\"}" >/dev/null; kleads
CMD
step "Kill the API pod!" "pod deleted. Kubernetes notices and creates a new one." <<'CMD'
kubectl -n devlab-dev delete pod devlab-api-0 --wait=false; sleep 8; kubectl -n devlab-dev wait --for=condition=ready pod/devlab-api-0 --timeout=120s
CMD
step "Count leads again" "leads in database: 1. The new pod re-attached the SAME disk (PVC), so no data was lost." <<'CMD'
kleads
CMD
step "Restart the web pods with a rolling update" "'successfully rolled out'. Old pods are replaced one by one while the site keeps working (maxUnavailable: 0)." <<'CMD'
kubectl -n devlab-dev rollout restart deploy/devlab-web; kubectl -n devlab-dev rollout status deploy/devlab-web --timeout=120s
CMD

part "PART C · Network security"
explain "The namespace has a 'default deny' NetworkPolicy: pods cannot talk to each other unless a rule allows it. Only web may talk to the api."
step "A stranger pod (from another namespace) tries to reach the API" "It TIMES OUT: wget: download timed out. The policy blocked it." fail <<'CMD'
kubectl run probe --rm -i --restart=Never --image=busybox:1.36 -- wget -qO- -T3 http://devlab-api.devlab-dev.svc.cluster.local:5000/healthz
CMD
step "The web pod (allowed by the policy) reaches the API" '{"ok":true}' <<'CMD'
kubectl -n devlab-dev exec deploy/devlab-web -- wget -qO- -T3 http://devlab-api.devlab-dev.svc.cluster.local:5000/healthz
CMD
quiz "Why block pods from talking to each other by default?" "attack|spread|lateral|least|limit|compromis|secur|blast" "If one pod is hacked it cannot reach everything else (smaller blast radius). You then allow only the connections you need."

part "PART D · Hands-on and a deliberate mistake"
learn "Scaling" "Stateless programs (like the web server) can run as many copies as you like. A program that keeps its data in a local file (like the API with SQLite) cannot, because each copy would have its own file. To scale the API you move its data to a shared database (module 16)."
task "Scale the web to 4 copies" "Run: kubectl -n devlab-dev scale deploy/devlab-web --replicas=4   then wait until 4 are ready (kubectl -n devlab-dev get pods)." "Make sure you include -n devlab-dev (the namespace)." <<'X'
[ "$(kubectl -n devlab-dev get deploy devlab-web -o jsonpath='{.status.readyReplicas}')" = "4" ]
---
kubectl -n devlab-dev scale deploy/devlab-web --replicas=4 && kubectl -n devlab-dev rollout status deploy/devlab-web --timeout=120s
X
step "Scale web back to 2" "2 replicas." <<'CMD'
kubectl -n devlab-dev scale deploy/devlab-web --replicas=2; kubectl -n devlab-dev rollout status deploy/devlab-web --timeout=120s
CMD
step "Now the MISTAKE: scale the API (which uses SQLite) to 2" "Two api pods and TWO separate disks (data-devlab-api-0 and -1). Each has its OWN database. Leads would be split between them!" <<'CMD'
kubectl -n devlab-dev scale sts/devlab-api --replicas=2; sleep 25; kubectl -n devlab-dev get pods -l app.kubernetes.io/name=devlab-api; kubectl -n devlab-dev get pvc
CMD
step "Undo the mistake" "Back to 1 api pod." <<'CMD'
kubectl -n devlab-dev scale sts/devlab-api --replicas=1; sleep 10; kubectl -n devlab-dev get pods -l app.kubernetes.io/name=devlab-api
CMD
quiz "Why can the web scale to 4 but the API cannot? What would you change to scale the API?" "state|stateless|database|disk|sqlite|postgres|shared|volume|single" "The web is stateless so copies are interchangeable. The API keeps data in a local SQLite file, so copies would each have their own data. Move the data to a shared database such as Postgres."

part "PART E · Clean up"
step "Delete the cluster" "cluster removed" <<'CMD'
bash 06-kubernetes/cluster.sh down
CMD

explain "Done! Next: bash lab.sh 07"
