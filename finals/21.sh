# Module 21 · interview and final (sourced by lab.sh)
# helper: a cluster with the extras (ingress, metrics-server) and the app deployed
k21_up() {
  bash 06-kubernetes/cluster.sh down >/dev/null 2>&1; K3S_ADDONS=1 bash 06-kubernetes/cluster.sh up >/dev/null 2>&1
  for i in $(seq 1 40); do kubectl top nodes 2>/dev/null | grep -q CPU && break; sleep 5; done
}

part "PART · INTERVIEW"

interview "Run a task once" "Interviewer: 'Nightly we need a one-off task: run a container that prints exam-done and then stops. Write playground/exam-job.yaml for a Kubernetes Job named exam-job (image busybox:1.36), apply it, and let it complete. I will read its logs.'" "Model it on 21-k8s-advanced/job.yaml: kind Job, restartPolicy Never, command [\"sh\", \"-c\", \"echo exam-done\"]. Apply with kubectl apply -f playground/exam-job.yaml" <<'X'
k21_up; rm -f playground/exam-job.yaml
---
kubectl wait --for=condition=complete job/exam-job --timeout=90s >/dev/null 2>&1 && kubectl logs job/exam-job 2>/dev/null | grep -q exam-done
---
printf 'apiVersion: batch/v1\nkind: Job\nmetadata:\n  name: exam-job\nspec:\n  template:\n    spec:\n      restartPolicy: Never\n      containers:\n        - name: t\n          image: busybox:1.36\n          command: ["sh", "-c", "echo exam-done"]\n' > playground/exam-job.yaml && kubectl apply -f playground/exam-job.yaml >/dev/null 2>&1
X

interview "The pod that keeps dying" "Interviewer: 'The pod oom-demo is restarting again and again. Find out WHY, and fix it so that it runs stably (Running, zero restarts for at least 20 seconds). You may recreate the pod.'" "kubectl describe pod oom-demo  shows OOMKilled: the memory limit (20Mi) is too small. Recreate the pod with a bigger limit, for example 256Mi (edit a copy of 21-k8s-advanced/oom.yaml)." <<'X'
kubectl delete pod oom-demo --ignore-not-found >/dev/null 2>&1; kubectl apply -f 21-k8s-advanced/oom.yaml >/dev/null 2>&1; sleep 25
---
[ "$(kubectl get pod oom-demo -o jsonpath='{.status.phase}' 2>/dev/null)" = Running ] && [ "$(kubectl get pod oom-demo -o jsonpath='{.status.containerStatuses[0].restartCount}' 2>/dev/null)" = 0 ] && [ "$(kubectl get pod oom-demo -o jsonpath='{.spec.containers[0].resources.limits.memory}')" != 20Mi ]
---
kubectl delete pod oom-demo --wait=true >/dev/null 2>&1; sed 's/20Mi/256Mi/' 21-k8s-advanced/oom.yaml | kubectl apply -f - >/dev/null 2>&1; sleep 25
---
kubectl delete pod oom-demo --ignore-not-found >/dev/null 2>&1
X

part "PART · MODULE FINAL"

final "Config as a file" "Exam 1 of 3. Create a ConfigMap named exam-cm with one key motto whose value is ship-it, and run a pod named exam-pod (image busybox:1.36, command sleep 600) that mounts the ConfigMap as files at /etc/exam. I will read /etc/exam/motto inside the pod. Save your YAML in playground/exam-pod.yaml." "A volume of type configMap, mounted with volumeMounts mountPath /etc/exam. Model it on 21-k8s-advanced/config-demo.yaml." <<'X'
kubectl delete pod exam-pod --ignore-not-found >/dev/null 2>&1; kubectl delete cm exam-cm --ignore-not-found >/dev/null 2>&1; rm -f playground/exam-pod.yaml
---
[ "$(kubectl exec exam-pod -- cat /etc/exam/motto 2>/dev/null | tr -d '\r\n')" = "ship-it" ]
---
printf 'apiVersion: v1\nkind: ConfigMap\nmetadata:\n  name: exam-cm\ndata:\n  motto: ship-it\n---\napiVersion: v1\nkind: Pod\nmetadata:\n  name: exam-pod\nspec:\n  containers:\n    - name: c\n      image: busybox:1.36\n      command: ["sleep", "600"]\n      volumeMounts:\n        - name: cfg\n          mountPath: /etc/exam\n  volumes:\n    - name: cfg\n      configMap:\n        name: exam-cm\n' > playground/exam-pod.yaml && kubectl apply -f playground/exam-pod.yaml >/dev/null 2>&1 && kubectl wait --for=condition=ready pod/exam-pod --timeout=120s >/dev/null 2>&1
X

final "Route a host name" "Exam 2 of 3. The app is deployed in the namespace devlab-dev. Write playground/exam-ingress.yaml: an Ingress that sends the host exam.localhost to the Service devlab-web on port 80, and apply it. I will call the cluster entry point (localhost:8081) with that host name." "Copy 21-k8s-advanced/ingress.yaml, change the name and the host to exam.localhost, keep the namespace devlab-dev." <<'X'
kubectl apply -k 06-kubernetes/overlays/dev >/dev/null 2>&1; kubectl -n devlab-dev rollout status deploy/devlab-web --timeout=150s >/dev/null 2>&1; kubectl -n devlab-dev rollout status sts/devlab-api --timeout=150s >/dev/null 2>&1; rm -f playground/exam-ingress.yaml
---
for i in 1 2 3 4 5 6 7 8; do curl -s -H 'Host: exam.localhost' localhost:8081/healthz | grep -q '"ok":true' && exit 0; sleep 3; done; exit 1
---
sed 's/name: devlab$/name: exam/; s/devlab.localhost/exam.localhost/' 21-k8s-advanced/ingress.yaml > playground/exam-ingress.yaml && kubectl apply -f playground/exam-ingress.yaml >/dev/null 2>&1
X

final "Autoscale a deployment" "Exam 3 of 3. The deployment burner is running without any autoscaling. Create a HorizontalPodAutoscaler for it: minimum 1 replica, maximum 3, target 50 percent CPU." "kubectl autoscale deployment burner --cpu-percent=50 --min=1 --max=3" <<'X'
kubectl delete hpa burner --ignore-not-found >/dev/null 2>&1; kubectl delete deploy burner --ignore-not-found >/dev/null 2>&1; kubectl apply -f 21-k8s-advanced/hpa-demo.yaml >/dev/null 2>&1; kubectl delete hpa burner >/dev/null 2>&1
---
[ "$(kubectl get hpa burner -o jsonpath='{.spec.maxReplicas}.{.spec.minReplicas}' 2>/dev/null)" = "3.1" ] && kubectl get hpa burner -o jsonpath='{.spec.metrics[0].resource.target.averageUtilization}' | grep -q '^50$'
---
kubectl autoscale deployment burner --cpu-percent=50 --min=1 --max=3 >/dev/null 2>&1
---
bash 06-kubernetes/cluster.sh down >/dev/null 2>&1
X
