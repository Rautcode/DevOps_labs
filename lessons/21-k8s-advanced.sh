# Kubernetes advanced: Jobs, config, resource limits, autoscaling, ingress (about 3h)
title "Module 21 · Kubernetes advanced"
mission "The cluster must also run nightly jobs, keep settings out of images, stop one greedy app from starving the rest, add copies when load rises, and take outside traffic. Your mission: add these production features one by one."
explain "Module 06 taught you to run an app on Kubernetes. Real clusters also run batch work on a schedule, keep configuration out of images, protect themselves from greedy containers, scale automatically with load, and route outside traffic by host name. You will meet each of those on a real cluster. This cluster keeps k3s's built-in metrics-server and Traefik ingress controller, which are switched off in module 06."

part "PART A · A cluster with the extras"
learn "Two add-ons" "metrics-server collects CPU and memory usage from every node and pod, and answers kubectl top. The autoscaler depends on it. Traefik is an ingress controller: a program that reads Ingress rules and routes outside HTTP traffic to the right Service. Both are normal pods in the kube-system namespace."
say "What do metrics-server and an ingress controller do?" "metrics-server collects CPU and memory usage from nodes and pods, and it is what kubectl top and the Horizontal Pod Autoscaler use. An ingress controller, such as Traefik or nginx, is the program that reads Ingress rules and routes outside HTTP traffic to the right service. Without either of them, autoscaling and external routing do not work."
why "docker image inspect::check the images|dc build::build them if missing" "The cluster needs the app images before it can run anything."
step "Make sure the app images exist" "devlab-api and devlab-web listed." ok 'devlab-web' <<'CMD'
docker image inspect devlab-api:lab devlab-web:lab >/dev/null 2>&1 || dc build 2>&1 | tail -2; docker images --format '{{.Repository}}:{{.Tag}}' | grep devlab
CMD
why "cluster.sh down then up::replace the old cluster|K3S_ADDONS=1::also install metrics-server and the Traefik ingress controller" "Autoscaling and ingress need two extra programs. We recreate the cluster with them included."
step "Create a cluster WITH the add-ons (any older lab cluster is replaced; about a minute)" "cluster ready" ok 'cluster ready' <<'CMD'
bash 06-kubernetes/cluster.sh down >/dev/null 2>&1; K3S_ADDONS=1 bash 06-kubernetes/cluster.sh up 2>&1 | tail -2
CMD
why "kubectl top nodes::show CPU and memory use of each node|for ...; do ...; done::retry until it works" "metrics-server needs a minute before it has numbers. The autoscaler depends on exactly this data."
step "Wait until the metrics-server answers" "A table with CPU and MEMORY of the node. kubectl top works only when metrics-server runs." ok 'CPU' <<'CMD'
for i in $(seq 1 40); do kubectl top nodes 2>/dev/null | grep -q CPU && break; sleep 5; done; kubectl top nodes
CMD
why "kubectl get pods -n kube-system::the pods of the cluster itself|awk::print name and status" "The cluster runs its own helpers as pods too. You should see metrics-server and traefik Running."
step "See the system pods" "metrics-server and traefik (plus coredns and storage) Running in kube-system." ok 'traefik' <<'CMD'
sleep 20; kubectl get pods -n kube-system --no-headers | awk '{print $1, $3}'
CMD

part "PART B · Jobs and CronJobs"
learn "Batch work" "A Deployment keeps something running forever. A Job runs a task until it succeeds, retries on failure (backoffLimit), and then stops. A CronJob creates a Job on a schedule written like cron. Use them for database backups, reports, cleanups and one-off migrations."
say "How do you run batch or scheduled work in Kubernetes?" "A Job runs a pod until it completes successfully, with retries controlled by backoffLimit. A CronJob creates Jobs on a cron schedule. I use them for backups, reports and cleanups, and I make them idempotent because a job can run twice. A Deployment is for things that should run forever."
art "Job and CronJob" <<'ART'
   Deployment:  run forever, keep N copies
   Job:         run a pod until it succeeds, retry up to backoffLimit, then stop
   CronJob:     create a Job on a schedule  (0 2 * * *  = every night at 02:00)
ART
why "cat job.yaml::print the file|kind: Job::run once until it succeeds|backoffLimit::how many retries" "A Job runs a task to completion, then stops. It is the right shape for backups, reports and migrations."
step "Read the Job manifest" "kind: Job, restartPolicy: Never, backoffLimit: 2." ok 'kind: Job' <<'CMD'
cat 21-k8s-advanced/job.yaml
CMD
why "kubectl apply -f job.yaml::create the Job" "Kubernetes starts a pod, runs the task and records the result."
step "Run the Job" "job.batch/hello-job created" ok 'created' <<'CMD'
kubectl apply -f 21-k8s-advanced/job.yaml
CMD
why "kubectl wait --for=condition=complete::wait for success|kubectl logs job/hello-job::read what it printed" "You wait for the real condition instead of guessing a time. Then the logs prove the work was done."
step "Wait until it completes and read its output" "hello from a job. The pod ran, finished and stopped." ok 'hello from a job' <<'CMD'
kubectl wait --for=condition=complete job/hello-job --timeout=120s; kubectl logs job/hello-job
CMD
why "cronjob.yaml::a Job that Kubernetes creates on a schedule" "A CronJob uses the same schedule format as Linux cron. It is how nightly tasks run in a cluster."
step "Schedule a CronJob that runs every minute" "cronjob.batch/hello-cron created" ok 'created' <<'CMD'
kubectl apply -f 21-k8s-advanced/cronjob.yaml
CMD
why "kubectl get jobs::list the Jobs|grep hello-cron::find the one made by the schedule" "Nobody started this Job. The schedule did. Remember to delete CronJobs you do not need."
step "Wait for the CronJob to create its first Job (up to 2 minutes)" "A job whose name starts with hello-cron. Nobody started it: the schedule did." ok 'hello-cron' <<'CMD'
for i in $(seq 1 30); do kubectl get jobs --no-headers | grep -q hello-cron && break; sleep 5; done; kubectl get jobs
CMD

part "PART C · Configuration outside the image"
learn "ConfigMaps and Secrets" "A ConfigMap holds non-secret settings and a Secret holds sensitive ones. A pod can read them as environment variables (fixed when the pod starts) or as files in a mounted volume (updated in place a little later when the ConfigMap changes). The image stays the same in dev, test and production; only the configuration differs."
say "How do you configure apps in Kubernetes?" "I keep configuration out of the image: a ConfigMap holds non-secret settings and a Secret holds sensitive values, injected as environment variables or mounted files. That way the same image runs in every environment with different config. Secrets still need protection with RBAC and ideally an external secret store."
art "Config outside the image" <<'ART'
   same image  +  ConfigMap (settings)  +  Secret (sensitive)   -->  dev, staging or prod pod
   delivered as environment variables or mounted files; no rebuild to change a setting
ART
why "config-demo.yaml::a ConfigMap (settings) and a pod that reads them|kubectl wait ... ready::wait for the pod" "Settings live outside the image, in a ConfigMap. The same image can run anywhere with different settings."
step "Create the ConfigMap and a pod that uses it" "configmap/app-config created and pod/config-demo created." ok 'config-demo' <<'CMD'
kubectl apply -f 21-k8s-advanced/config-demo.yaml; kubectl wait --for=condition=ready pod/config-demo --timeout=120s
CMD
why "kubectl exec config-demo -- cat /etc/app/greeting::read the file the ConfigMap created" "A ConfigMap can be mounted as files. Apps that read config files need no change."
step "Read the setting as a FILE inside the pod" "hello from configmap" ok 'hello from configmap' <<'CMD'
kubectl exec config-demo -- cat /etc/app/greeting
CMD
why "kubectl exec ... printenv APP_MODE::print one environment variable" "The same ConfigMap can also provide environment variables. Choose whichever form your app expects."
step "Read another setting as an ENVIRONMENT VARIABLE" "learning" ok 'learning' <<'CMD'
kubectl exec config-demo -- printenv APP_MODE
CMD
quiz "Why keep configuration in a ConfigMap instead of baking it into the image?" "same image|rebuild|environment|differ|change|without|promote|portable" "The same image can run everywhere unchanged, and you change behaviour by changing configuration, with no rebuild. That is how a tested image is promoted from dev to production."

part "PART D · Requests, limits and OOMKilled"
learn "Requests and limits" "A request is what the scheduler reserves for the container. A limit is the most it may use. Go over a CPU limit and the container is slowed down (throttled). Go over a MEMORY limit and the kernel kills it: that is OOMKilled (out of memory), and Kubernetes restarts it, so you see a crash loop. Always set both, and look at the real usage with kubectl top."
say "What are resource requests and limits?" "A request is what the scheduler reserves for a container; a limit is the most it may use. If a container exceeds its memory limit it is killed with OOMKilled, exit code 137, while exceeding the CPU limit just throttles it. I set both from measured usage, so pods are placed sensibly and one greedy app cannot starve the others."
art "Requests and limits" <<'ART'
   request = what the scheduler RESERVES for the pod   (a seat at the table)
   limit   = the most it may USE                       (over memory => killed)
ART
mcq "A container uses more memory than its limit. What happens?" "It is killed (OOMKilled) and restarted|It slows down|Kubernetes adds memory|Nothing" 1 "Memory over the limit cannot be throttled, so the process is killed."
why "oom.yaml::a pod with a 20 MB memory limit that tries to use 100 MB" "We cause an out-of-memory failure on purpose. Limits protect the node from one greedy pod."
step "Run a pod that needs 100 MB but may only use 20 MB" "pod/oom-demo created" ok 'created' <<'CMD'
kubectl apply -f 21-k8s-advanced/oom.yaml
CMD
why "jsonpath lastState.terminated.reason::read the termination reason" "The reason is OOMKilled. It means the container used more memory than its limit and the kernel stopped it. Exit code 137 also means this."
step "Wait for the kernel to kill it and read the reason" "reason: OOMKilled. This is the reason you must know when a pod restarts again and again." ok 'OOMKilled' <<'CMD'
for i in $(seq 1 30); do r=$(kubectl get pod oom-demo -o jsonpath='{.status.containerStatuses[0].lastState.terminated.reason}{.status.containerStatuses[0].state.terminated.reason}' 2>/dev/null); [ -n "$r" ] && break; sleep 5; done; echo "reason: $r"
CMD
why "kubectl describe pod::the full story of the pod|grep -E::keep Reason, Exit Code and limits" "describe is the first command when a pod misbehaves. The events at the bottom explain most problems."
step "Describe the pod to see where Kubernetes tells you" "State/Last State: Terminated, Reason: OOMKilled, Exit Code: 137." ok 'OOMKilled' <<'CMD'
kubectl describe pod oom-demo | grep -E "Reason|Exit Code|Limits|memory"
CMD
quiz "A pod restarts again and again with Exit Code 137. What is the most likely cause?" "oom|memory|killed|limit" "It was killed for using more memory than its limit (OOMKilled), or by SIGKILL. Check kubectl describe pod, raise the limit if the app really needs it, or fix the memory leak."

part "PART E · Autoscaling"
learn "Horizontal Pod Autoscaler" "The HPA watches usage from metrics-server and changes the replica count between a minimum and a maximum to keep the average near your target. The target is a percentage of the CPU REQUEST, so the request must be set. Scaling up is quick; scaling down is deliberately slow so a short dip does not remove capacity you still need."
say "How does the Horizontal Pod Autoscaler work?" "It reads metrics from metrics-server, such as average CPU, compares them with a target and changes the replica count between a minimum and a maximum. It needs resource requests to be set, and a stabilisation window prevents flapping. It scales pods; to scale nodes I would also need a cluster autoscaler."
art "The autoscaler loop" <<'ART'
   metrics-server --> CPU 90% of the request --> HPA target 50% --> more replicas (up to max)
   load drops --> CPU 20% --> waits a few minutes --> fewer replicas (down to min)
ART
why "hpa-demo.yaml::a deployment that uses CPU and a HorizontalPodAutoscaler" "The autoscaler watches CPU use and changes the number of pods to keep it near a target. This is automatic scaling."
step "Deploy a CPU burner and an autoscaler for it" "deployment.apps/burner and horizontalpodautoscaler.autoscaling/burner created." ok 'burner' <<'CMD'
kubectl apply -f 21-k8s-advanced/hpa-demo.yaml
CMD
why "kubectl get deploy burner -o jsonpath::read the replica count|retry loop::until it is above 1" "Autoscaling takes time, because metrics are averaged and changes are made carefully to avoid flapping."
step "Wait for the autoscaler to add copies (up to about 3 minutes)" "replicas: 2 or more. The burner uses 200% of its request, so the HPA scales it up." ok 'replicas: [2-9]' <<'CMD'
for i in $(seq 1 45); do n=$(kubectl get deploy burner -o jsonpath='{.spec.replicas}'); [ "$n" -gt 1 ] && break; sleep 5; done; echo "replicas: $n"
CMD
why "kubectl get hpa burner::show the target, the current use and the replica count" "You see the CPU number it is reacting to and the minimum and maximum copies it may use."
step "Look at the autoscaler's view" "TARGETS above 50%, REPLICAS growing toward MAXPODS 4." ok 'burner' <<'CMD'
kubectl get hpa burner
CMD

part "PART F · Ingress"
learn "Ingress" "A Service gives pods a stable address INSIDE the cluster. An Ingress is a set of HTTP routing rules for traffic coming from OUTSIDE: send host a.example.com to service A and host b.example.com to service B, on one shared entry point (one load balancer, one certificate). The Ingress object holds the rules; the ingress controller (Traefik here) enforces them."
say "What is the difference between a Service and an Ingress?" "A Service gives pods a stable address inside the cluster and load balances between them. An Ingress is a set of HTTP routing rules at the edge, by host name and path, that an ingress controller implements, typically with TLS. So one entry point can route to many services."
art "Ingress" <<'ART'
   internet -> [ Ingress ] -- /api --> [ Service api ] -> pods
                        \-- /    --> [ Service web ] -> pods
   one door, rules decide where each URL goes
ART
why "kubectl apply -k overlays/dev::deploy the app with Kustomize|rollout status::wait until ready" "We need the app running before we can route traffic to it with an Ingress."
step "Deploy the app (the dev environment) again on this cluster" "deployments created." ok 'devlab' <<'CMD'
kubectl apply -k 06-kubernetes/overlays/dev | tail -3; kubectl -n devlab-dev rollout status deploy/devlab-web --timeout=150s; kubectl -n devlab-dev rollout status sts/devlab-api --timeout=150s
CMD
why "ingress.yaml::HTTP routing rules by host name" "An Ingress tells the controller: requests for this host go to that service. One entry point can serve many apps."
step "Create the Ingress rule for devlab.localhost" "ingress.networking.k8s.io/devlab created" ok 'created' <<'CMD'
kubectl apply -f 21-k8s-advanced/ingress.yaml
CMD
why "-H Host: devlab.localhost::pretend the request is for that name|localhost:8081::the cluster entry port" "The controller chooses the service from the Host header. This is how many sites share one IP address."
step "Call the cluster entry point and ask for that host name" '{"ok":true}. Traefik read your rule and routed the request to the web service.' ok '"ok":true' <<'CMD'
for i in $(seq 1 20); do curl -s -H 'Host: devlab.localhost' localhost:8081/healthz | grep -q '"ok":true' && break; sleep 3; done; curl -s -H 'Host: devlab.localhost' localhost:8081/healthz
CMD
why "-H Host: unknown.localhost::a name with no rule" "The controller answers 404, because no rule matches. A clear 404 is the right behaviour for an unknown host."
step "Ask for a host nobody configured" "404. No rule matches, so Traefik answers not found." ok '404' <<'CMD'
curl -s -w '\n%{http_code}' -H 'Host: unknown.localhost' localhost:8081/ | tail -1
CMD
quiz "What is the difference between a Service and an Ingress?" "outside|external|http|host|path|route|rules|inside|stable" "A Service is a stable in-cluster address for a set of pods. An Ingress is HTTP routing for outside traffic (by host name and path) to Services, enforced by an ingress controller."

part "PART G · Troubleshoot like an SRE"
learn "Read the status, then the events" "When a pod is unhappy, its STATUS names the problem: ImagePullBackOff (the image cannot be downloaded: wrong name or tag, or a private registry without credentials), CrashLoopBackOff (the container starts and keeps crashing: read kubectl logs), Pending (no node can take it: not enough CPU or memory, or a nodeSelector, taint or affinity no node satisfies). The reason is always in kubectl describe, under Events at the bottom."
say "A pod is not running. How do you troubleshoot?" "I read its status and then its events. ImagePullBackOff means the image cannot be fetched, so I check the name, tag and credentials. CrashLoopBackOff means it keeps crashing, so I read kubectl logs and the previous logs. Pending means it cannot be scheduled, so I describe the pod and look for FailedScheduling. OOMKilled means it exceeded its memory. kubectl describe is my first move."
art "Which status means what?" <<'ART'
   Pending            -> not placed on a node     -> describe pod: FailedScheduling
   ImagePullBackOff   -> image cannot be fetched   -> describe pod: Failed to pull image
   CrashLoopBackOff   -> app starts then dies      -> kubectl logs POD (and --previous)
   OOMKilled (137)    -> over its memory limit     -> raise the limit or fix the leak
ART
why "kubectl run bad-image::start a pod|--image=nginx:no-such-tag-123::a tag that is not there" "We cause the most common beginner error on purpose. Kubernetes accepts the pod; the problem appears when it tries to pull the image."
step "Start a pod with an image tag that does not exist" "pod/bad-image created. Kubernetes accepts it; the problem shows later." ok 'created' <<'CMD'
kubectl delete pod bad-image --ignore-not-found >/dev/null 2>&1; kubectl run bad-image --image=nginx:no-such-tag-123
CMD
why "kubectl get pod bad-image::the pod status|retry loop::wait until it says ImagePull" "ErrImagePull, then ImagePullBackOff. Back-off means Kubernetes keeps retrying with longer delays."
step "Wait for the status to show the problem" "ErrImagePull and then ImagePullBackOff. Kubernetes retries with growing delays." ok 'ImagePull' <<'CMD'
for i in $(seq 1 30); do kubectl get pod bad-image --no-headers | grep -q ImagePull && break; sleep 3; done; kubectl get pod bad-image
CMD
why "kubectl describe pod::full details|grep -iE Failed::the lines about the failure" "The Events at the bottom say the image could not be pulled and why. Always read the events first."
step "Find the reason in the events" "A line saying Failed to pull image, with the name that could not be found." ok 'Failed' <<'CMD'
kubectl describe pod bad-image | grep -iE "Failed|not found" | head -3
CMD
why "kubectl set image::change the image of a pod|nginx:alpine::a real tag|kubectl wait --for=condition=Ready::wait until it works" "Fixing the cause turns the pod healthy. Verify by waiting for Ready, not by hoping."
step "Fix it by pointing the pod at a real tag" "pod/bad-image image updated, then the pod becomes ready." ok 'condition met' <<'CMD'
kubectl set image pod/bad-image bad-image=nginx:alpine; kubectl wait --for=condition=Ready pod/bad-image --timeout=120s
CMD
why "pending-pod.yaml::a pod that must run on a node labelled disktype=ssd" "No node has that label, so the scheduler cannot place the pod. The pod will stay Pending."
step "Now a pod that asks for a node that does not exist (nodeSelector disktype=ssd)" "pod/pending-pod created." ok 'created' <<'CMD'
kubectl delete pod pending-pod --ignore-not-found >/dev/null 2>&1; kubectl apply -f 21-k8s-advanced/pending-pod.yaml
CMD
why "kubectl get pod::status Pending|describe ... FailedScheduling::the scheduler reason" "Pending plus a FailedScheduling event means no node qualifies. The event says the nodes did not match the selector."
step "See it stuck, and why" "Status Pending, and an event FailedScheduling: no node matches the node selector." ok 'FailedScheduling' <<'CMD'
sleep 6; kubectl get pod pending-pod --no-headers; kubectl describe pod pending-pod | grep -i FailedScheduling | head -2
CMD
predict "How can you make that Pending pod schedule WITHOUT editing the pod?" "Label a node with disktype=ssd|Restart the cluster|Delete the Deployment|Add more memory" 1 "The scheduler only needs a node that matches the selector. Giving a node the label makes it eligible."
why "kubectl label node --all disktype=ssd::give the nodes the label|kubectl wait::wait for the pod" "The scheduler keeps retrying. As soon as a node matches, the pod starts, with no change to the pod itself."
step "Label the node and watch the pod start" "node/... labeled, then the pod is Ready." ok 'condition met' <<'CMD'
kubectl label node --all disktype=ssd --overwrite >/dev/null; kubectl wait --for=condition=Ready pod/pending-pod --timeout=120s
CMD
task "Fix a broken app" "A pod called broken-app was deployed with a typo in its image tag. Apply it with  kubectl apply -f 21-k8s-advanced/broken-app.yaml  , look at its status and events (kubectl get pod, kubectl describe pod), then fix the image to nginx:alpine and wait until it is Running. Type check when done." "kubectl set image pod/broken-app web=nginx:alpine  (the container is named web). Wait with: kubectl wait --for=condition=Ready pod/broken-app" <<'X'
[ "$(kubectl get pod broken-app -o jsonpath='{.status.phase}' 2>/dev/null)" = Running ] && kubectl get pod broken-app -o jsonpath='{.spec.containers[0].image}' | grep -q 'nginx:alpine'
---
kubectl delete pod broken-app --ignore-not-found >/dev/null 2>&1; kubectl apply -f 21-k8s-advanced/broken-app.yaml >/dev/null; kubectl set image pod/broken-app web=nginx:alpine >/dev/null; kubectl wait --for=condition=Ready pod/broken-app --timeout=120s >/dev/null
X
why "kubectl delete pod ...::remove the practice pods|label disktype-::remove the label (the minus sign deletes it)" "Leave the cluster as you found it."
step "Clean up the practice pods and the label" "Pods deleted." <<'CMD'
kubectl delete pod bad-image pending-pod broken-app --ignore-not-found --wait=false; kubectl label node --all disktype- >/dev/null
CMD

part "PART H · Where pods run: taints, tolerations and affinity"
learn "Steering the scheduler" "The scheduler decides which node runs each pod. You can steer it in two directions. A node can REPEL pods with a TAINT (for example dedicated=gpu:NoSchedule: no pod may land here); only pods that carry a matching TOLERATION are allowed. A pod can ATTRACT itself to nodes with AFFINITY: required (a must: if no node matches, the pod stays Pending) or preferred (a wish: used when possible, ignored otherwise). Typical uses: keep general pods off expensive GPU or database nodes, spread copies across zones, put a pod near its data. A taint says keep out; a toleration only says I may enter, it does not pull the pod there."
say "How do taints, tolerations and affinity differ?" "A taint on a node repels pods; only pods with a matching toleration may run there, which keeps general workloads off special nodes like GPU nodes. Node affinity attracts a pod to nodes by label, either required, a must, or preferred, a wish. A toleration allows but does not attract, so I often combine a taint with affinity."
art "Taint, toleration, affinity" <<'ART'
   node:  taint dedicated=gpu:NoSchedule     "keep out unless you tolerate this"
   pod A (no toleration)   -> Pending        pod B (toleration)  -> can run here
   affinity REQUIRED disk=nvme   -> Pending if no node has the label
   affinity PREFERRED disk=nvme  -> runs anywhere, prefers a match
ART
why "kubectl taint nodes --all::mark every node|dedicated=gpu:NoSchedule::a taint: new pods without a toleration may not run here" "A taint repels pods. It is used to keep ordinary workloads off special nodes. Pods already running are not removed."
step "Taint the node so that new pods are kept out" "The node is tainted (kubectl says tainted or modified). Pods already running are not affected (NoSchedule only blocks NEW pods)." ok 'tainted|modified' <<'CMD'
kubectl taint nodes --all dedicated=gpu:NoSchedule --overwrite
CMD
why "kubectl run no-toleration::a plain pod" "This pod does not carry the key to the tainted node, so it cannot be scheduled."
step "Start a pod WITHOUT a toleration" "pod/no-toleration created." ok 'created' <<'CMD'
kubectl delete pod no-toleration --ignore-not-found >/dev/null 2>&1; kubectl run no-toleration --image=nginx:alpine
CMD
why "describe pod ... FailedScheduling::the scheduler reason" "The event mentions an untolerated taint: the node has dedicated=gpu and the pod does not tolerate it."
step "See why it is stuck" "Pending, and the event says the node has an untolerated taint (dedicated: gpu)." ok 'untolerated taint' <<'CMD'
sleep 6; kubectl get pod no-toleration --no-headers; kubectl describe pod no-toleration | grep -i FailedScheduling | head -2
CMD
why "tolerations: key dedicated, value gpu::the matching key|effect NoSchedule::the effect to accept" "A toleration says I am allowed to run on nodes with this taint. It allows; it does not force the pod there."
step "Read the pod that carries a matching toleration" "A tolerations section: key dedicated, value gpu, effect NoSchedule." ok 'tolerations' <<'CMD'
cat 21-k8s-advanced/toleration-pod.yaml
CMD
why "kubectl apply -f toleration-pod.yaml::create the tolerating pod|kubectl wait::wait until ready" "The same node accepts this pod, because it tolerates the taint."
step "Start it: it IS allowed on the tainted node" "pod/with-toleration created, then it becomes Ready." ok 'condition met' <<'CMD'
kubectl delete pod with-toleration --ignore-not-found >/dev/null 2>&1; kubectl apply -f 21-k8s-advanced/toleration-pod.yaml >/dev/null; kubectl wait --for=condition=Ready pod/with-toleration --timeout=120s
CMD
predict "You now REMOVE the taint from the node. What happens to the Pending no-toleration pod?" "It stays Pending forever|The scheduler places it on the node by itself|It is deleted|It crashes" 2 "The scheduler keeps retrying Pending pods. As soon as the node is allowed, the pod is scheduled. No restart needed."
why "kubectl taint nodes --all dedicated-::the minus removes the taint|kubectl wait::wait for the other pod" "The scheduler retries Pending pods, so the stuck one starts by itself. No restart is needed."
step "Remove the taint and watch the stuck pod start" "node/... untainted, then the pod becomes Ready by itself." ok 'condition met' <<'CMD'
kubectl taint nodes --all dedicated- >/dev/null; kubectl wait --for=condition=Ready pod/no-toleration --timeout=120s
CMD
why "requiredDuringScheduling::a must|preferredDuringScheduling::a wish|key: disk, values: nvme::the node label they ask for" "Node affinity pulls a pod toward nodes with a label. Required means the pod waits if none exists. Preferred means it runs anywhere but likes a match."
step "Read the two affinity pods" "One uses requiredDuringScheduling... (a must) and one preferredDuringScheduling... (a wish), both asking for disk=nvme." ok 'required' <<'CMD'
grep -nE "name:|required|preferred|key:" 21-k8s-advanced/affinity-pods.yaml
CMD
why "kubectl apply -f affinity-pods.yaml::create both|kubectl get pods::compare the status" "The preferred pod runs because a wish can be ignored. The required pod stays Pending because nobody matches."
step "Start both and compare" "affinity-preferred is Running (the wish is ignored), affinity-required is Pending (a must nobody satisfies)." ok 'affinity-required +0/1 +Pending' <<'CMD'
kubectl delete pod affinity-required affinity-preferred --ignore-not-found >/dev/null 2>&1; kubectl apply -f 21-k8s-advanced/affinity-pods.yaml >/dev/null; kubectl wait --for=condition=Ready pod/affinity-preferred --timeout=120s >/dev/null; kubectl get pods affinity-required affinity-preferred --no-headers
CMD
mcq "A node has the taint dedicated=gpu:NoSchedule. Which pods can be scheduled on it?" "Only pods with a matching toleration|Every pod|No pod at all|Only pods in kube-system" 1 "A taint repels everything except pods that tolerate it. (A toleration allows, it does not force a pod onto that node: use affinity or a nodeSelector for that.)"
task "Let the stuck pod run" "Make the affinity-required pod start WITHOUT editing the pod: give the node the label it asks for.  kubectl label node --all disk=nvme   Then wait until the pod is Running." "The pod wants a node with disk=nvme. Label the node, and the scheduler places the pod." <<'X'
[ "$(kubectl get pod affinity-required -o jsonpath='{.status.phase}' 2>/dev/null)" = Running ]
---
kubectl label node --all disk=nvme --overwrite >/dev/null; kubectl wait --for=condition=Ready pod/affinity-required --timeout=120s >/dev/null
X
why "kubectl delete pod ...::remove the practice pods|label disk-::remove the label|taint dedicated-::remove the taint" "Always undo what you changed on the cluster, especially taints, which affect every new pod."
step "Clean up the practice pods, label and taint" "Pods deleted, label and taint removed." <<'CMD'
kubectl delete pod no-toleration with-toleration affinity-required affinity-preferred --ignore-not-found --wait=false; kubectl label node --all disk- >/dev/null; kubectl taint nodes --all dedicated- >/dev/null 2>&1; true
CMD

part "PART I · Clean up"
why "cluster.sh down::remove the practice cluster" "Clean up so your computer gets its memory back."
step "Delete the cluster" "cluster removed" ok 'cluster removed' <<'CMD'
bash 06-kubernetes/cluster.sh down
CMD

deeper "Kubernetes troubleshooting Zero to Hero (Abhishek Veeramalla)|https://github.com/iam-veeramalla/kubernetes-troubleshooting-zero-to-hero" "HPA, ingress and more on EKS (StackSimplify)|https://github.com/stacksimplify/aws-eks-kubernetes-masterclass" "k8s-kind-voting-app (Shubham Londhe)|https://github.com/LondheShubham153/k8s-kind-voting-app"
explain "Done! Next: bash lab.sh 22"
