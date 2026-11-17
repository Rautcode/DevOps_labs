# Kubernetes advanced: Jobs, config, resource limits, autoscaling, ingress (about 3h)
title "Module 21 · Kubernetes advanced"
explain "Module 06 taught you to run an app on Kubernetes. Real clusters also run batch work on a schedule, keep configuration out of images, protect themselves from greedy containers, scale automatically with load, and route outside traffic by host name. You will meet each of those on a real cluster. This cluster keeps k3s's built-in metrics-server and Traefik ingress controller, which are switched off in module 06."

part "PART A · A cluster with the extras"
learn "Two add-ons" "metrics-server collects CPU and memory usage from every node and pod, and answers kubectl top. The autoscaler depends on it. Traefik is an ingress controller: a program that reads Ingress rules and routes outside HTTP traffic to the right Service. Both are normal pods in the kube-system namespace."
step "Make sure the app images exist" "devlab-api and devlab-web listed." ok 'devlab-web' <<'CMD'
docker image inspect devlab-api:lab devlab-web:lab >/dev/null 2>&1 || dc build 2>&1 | tail -2; docker images --format '{{.Repository}}:{{.Tag}}' | grep devlab
CMD
step "Create a cluster WITH the add-ons (any older lab cluster is replaced; about a minute)" "cluster ready" ok 'cluster ready' <<'CMD'
bash 06-kubernetes/cluster.sh down >/dev/null 2>&1; K3S_ADDONS=1 bash 06-kubernetes/cluster.sh up 2>&1 | tail -2
CMD
step "Wait until the metrics-server answers" "A table with CPU and MEMORY of the node. kubectl top works only when metrics-server runs." ok 'CPU' <<'CMD'
for i in $(seq 1 40); do kubectl top nodes 2>/dev/null | grep -q CPU && break; sleep 5; done; kubectl top nodes
CMD
step "See the system pods" "metrics-server and traefik (plus coredns and storage) Running in kube-system." ok 'traefik' <<'CMD'
sleep 20; kubectl get pods -n kube-system --no-headers | awk '{print $1, $3}'
CMD

part "PART B · Jobs and CronJobs"
learn "Batch work" "A Deployment keeps something running forever. A Job runs a task until it succeeds, retries on failure (backoffLimit), and then stops. A CronJob creates a Job on a schedule written like cron. Use them for database backups, reports, cleanups and one-off migrations."
step "Read the Job manifest" "kind: Job, restartPolicy: Never, backoffLimit: 2." ok 'kind: Job' <<'CMD'
cat 21-k8s-advanced/job.yaml
CMD
step "Run the Job" "job.batch/hello-job created" ok 'created' <<'CMD'
kubectl apply -f 21-k8s-advanced/job.yaml
CMD
step "Wait until it completes and read its output" "hello from a job. The pod ran, finished and stopped." ok 'hello from a job' <<'CMD'
kubectl wait --for=condition=complete job/hello-job --timeout=120s; kubectl logs job/hello-job
CMD
step "Schedule a CronJob that runs every minute" "cronjob.batch/hello-cron created" ok 'created' <<'CMD'
kubectl apply -f 21-k8s-advanced/cronjob.yaml
CMD
step "Wait for the CronJob to create its first Job (up to 2 minutes)" "A job whose name starts with hello-cron. Nobody started it: the schedule did." ok 'hello-cron' <<'CMD'
for i in $(seq 1 30); do kubectl get jobs --no-headers | grep -q hello-cron && break; sleep 5; done; kubectl get jobs
CMD

part "PART C · Configuration outside the image"
learn "ConfigMaps and Secrets" "A ConfigMap holds non-secret settings and a Secret holds sensitive ones. A pod can read them as environment variables (fixed when the pod starts) or as files in a mounted volume (updated in place a little later when the ConfigMap changes). The image stays the same in dev, test and production; only the configuration differs."
step "Create the ConfigMap and a pod that uses it" "configmap/app-config created and pod/config-demo created." ok 'config-demo' <<'CMD'
kubectl apply -f 21-k8s-advanced/config-demo.yaml; kubectl wait --for=condition=ready pod/config-demo --timeout=120s
CMD
step "Read the setting as a FILE inside the pod" "hello from configmap" ok 'hello from configmap' <<'CMD'
kubectl exec config-demo -- cat /etc/app/greeting
CMD
step "Read another setting as an ENVIRONMENT VARIABLE" "learning" ok 'learning' <<'CMD'
kubectl exec config-demo -- printenv APP_MODE
CMD
quiz "Why keep configuration in a ConfigMap instead of baking it into the image?" "same image|rebuild|environment|differ|change|without|promote|portable" "The same image can run everywhere unchanged, and you change behaviour by changing configuration, with no rebuild. That is how a tested image is promoted from dev to production."

part "PART D · Requests, limits and OOMKilled"
learn "Requests and limits" "A request is what the scheduler reserves for the container. A limit is the most it may use. Go over a CPU limit and the container is slowed down (throttled). Go over a MEMORY limit and the kernel kills it: that is OOMKilled (out of memory), and Kubernetes restarts it, so you see a crash loop. Always set both, and look at the real usage with kubectl top."
step "Run a pod that needs 100 MB but may only use 20 MB" "pod/oom-demo created" ok 'created' <<'CMD'
kubectl apply -f 21-k8s-advanced/oom.yaml
CMD
step "Wait for the kernel to kill it and read the reason" "reason: OOMKilled. This is the reason you must know when a pod restarts again and again." ok 'OOMKilled' <<'CMD'
for i in $(seq 1 30); do r=$(kubectl get pod oom-demo -o jsonpath='{.status.containerStatuses[0].lastState.terminated.reason}{.status.containerStatuses[0].state.terminated.reason}' 2>/dev/null); [ -n "$r" ] && break; sleep 5; done; echo "reason: $r"
CMD
step "Describe the pod to see where Kubernetes tells you" "State/Last State: Terminated, Reason: OOMKilled, Exit Code: 137." ok 'OOMKilled' <<'CMD'
kubectl describe pod oom-demo | grep -E "Reason|Exit Code|Limits|memory"
CMD
quiz "A pod restarts again and again with Exit Code 137. What is the most likely cause?" "oom|memory|killed|limit" "It was killed for using more memory than its limit (OOMKilled), or by SIGKILL. Check kubectl describe pod, raise the limit if the app really needs it, or fix the memory leak."

part "PART E · Autoscaling"
learn "Horizontal Pod Autoscaler" "The HPA watches usage from metrics-server and changes the replica count between a minimum and a maximum to keep the average near your target. The target is a percentage of the CPU REQUEST, so the request must be set. Scaling up is quick; scaling down is deliberately slow so a short dip does not remove capacity you still need."
step "Deploy a CPU burner and an autoscaler for it" "deployment.apps/burner and horizontalpodautoscaler.autoscaling/burner created." ok 'burner' <<'CMD'
kubectl apply -f 21-k8s-advanced/hpa-demo.yaml
CMD
step "Wait for the autoscaler to add copies (up to about 3 minutes)" "replicas: 2 or more. The burner uses 200% of its request, so the HPA scales it up." ok 'replicas: [2-9]' <<'CMD'
for i in $(seq 1 45); do n=$(kubectl get deploy burner -o jsonpath='{.spec.replicas}'); [ "$n" -gt 1 ] && break; sleep 5; done; echo "replicas: $n"
CMD
step "Look at the autoscaler's view" "TARGETS above 50%, REPLICAS growing toward MAXPODS 4." ok 'burner' <<'CMD'
kubectl get hpa burner
CMD

part "PART F · Ingress"
learn "Ingress" "A Service gives pods a stable address INSIDE the cluster. An Ingress is a set of HTTP routing rules for traffic coming from OUTSIDE: send host a.example.com to service A and host b.example.com to service B, on one shared entry point (one load balancer, one certificate). The Ingress object holds the rules; the ingress controller (Traefik here) enforces them."
step "Deploy the app (the dev environment) again on this cluster" "deployments created." ok 'devlab' <<'CMD'
kubectl apply -k 06-kubernetes/overlays/dev | tail -3; kubectl -n devlab-dev rollout status deploy/devlab-web --timeout=150s; kubectl -n devlab-dev rollout status sts/devlab-api --timeout=150s
CMD
step "Create the Ingress rule for devlab.localhost" "ingress.networking.k8s.io/devlab created" ok 'created' <<'CMD'
kubectl apply -f 21-k8s-advanced/ingress.yaml
CMD
step "Call the cluster entry point and ask for that host name" '{"ok":true}. Traefik read your rule and routed the request to the web service.' ok '"ok":true' <<'CMD'
for i in $(seq 1 20); do curl -s -H 'Host: devlab.localhost' localhost:8081/healthz | grep -q '"ok":true' && break; sleep 3; done; curl -s -H 'Host: devlab.localhost' localhost:8081/healthz
CMD
step "Ask for a host nobody configured" "404. No rule matches, so Traefik answers not found." ok '404' <<'CMD'
curl -s -w '\n%{http_code}' -H 'Host: unknown.localhost' localhost:8081/ | tail -1
CMD
quiz "What is the difference between a Service and an Ingress?" "outside|external|http|host|path|route|rules|inside|stable" "A Service is a stable in-cluster address for a set of pods. An Ingress is HTTP routing for outside traffic (by host name and path) to Services, enforced by an ingress controller."

part "PART G · Clean up"
step "Delete the cluster" "cluster removed" ok 'cluster removed' <<'CMD'
bash 06-kubernetes/cluster.sh down
CMD

explain "Done! Next: bash lab.sh 22"
