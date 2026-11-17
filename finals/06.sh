# Module 06 · interview and final (sourced by lab.sh)
part "PART · INTERVIEW"

interview "A bad release is live" "Interviewer: 'A teammate just deployed a new version of the web app to the dev namespace (devlab-dev) and it is stuck: the new pods cannot start. Customers are still being served by the old pods, but the rollout is broken. Roll the deployment back to the last good version and prove the rollout completes.'" "kubectl -n devlab-dev rollout undo deploy/devlab-web   then   kubectl -n devlab-dev rollout status deploy/devlab-web   . Look at  kubectl -n devlab-dev get pods  first to see the problem." <<'X'
bash 06-kubernetes/cluster.sh up >/dev/null 2>&1; kubectl apply -k 06-kubernetes/overlays/dev >/dev/null 2>&1; kubectl -n devlab-dev rollout status deploy/devlab-web --timeout=150s >/dev/null 2>&1; kubectl -n devlab-dev rollout status sts/devlab-api --timeout=150s >/dev/null 2>&1; kubectl -n devlab-dev set image deploy/devlab-web web=devlab-web:does-not-exist >/dev/null 2>&1; sleep 6
---
[ "$(kubectl -n devlab-dev get deploy devlab-web -o jsonpath='{.spec.template.spec.containers[0].image}')" = "devlab-web:lab" ] && kubectl -n devlab-dev rollout status deploy/devlab-web --timeout=90s
---
kubectl -n devlab-dev rollout undo deploy/devlab-web >/dev/null 2>&1; kubectl -n devlab-dev rollout status deploy/devlab-web --timeout=120s >/dev/null 2>&1
X

interview "Handle a traffic spike" "Interviewer: 'Traffic is about to triple. Run 3 copies of the web deployment (in devlab-dev) and prove all 3 are ready.'" "kubectl -n devlab-dev scale deploy/devlab-web --replicas=3" <<'X'
true
---
[ "$(kubectl -n devlab-dev get deploy devlab-web -o jsonpath='{.status.readyReplicas}')" = "3" ]
---
kubectl -n devlab-dev scale deploy/devlab-web --replicas=3 >/dev/null 2>&1; kubectl -n devlab-dev rollout status deploy/devlab-web --timeout=120s >/dev/null 2>&1
---
kubectl -n devlab-dev scale deploy/devlab-web --replicas=2 >/dev/null 2>&1
X

part "PART · MODULE FINAL"

final "Add configuration" "Exam 1 of 3. Create a ConfigMap named exam-config in the namespace devlab-dev containing one key GREETING with the value hello." "kubectl -n devlab-dev create configmap exam-config --from-literal=GREETING=hello" <<'X'
kubectl -n devlab-dev delete configmap exam-config >/dev/null 2>&1
---
[ "$(kubectl -n devlab-dev get cm exam-config -o jsonpath='{.data.GREETING}' 2>/dev/null)" = "hello" ]
---
kubectl -n devlab-dev create configmap exam-config --from-literal=GREETING=hello >/dev/null 2>&1
---
kubectl -n devlab-dev delete configmap exam-config >/dev/null 2>&1
X

final "Prove the network policy works" "Exam 2 of 3. Prove that a pod in the DEFAULT namespace cannot reach the API service (devlab-api.devlab-dev.svc.cluster.local, port 5000). Run a throwaway busybox pod that tries (wget -T3), and if it is blocked write the word blocked into playground/np.txt. I will test it again myself before I believe you." "kubectl run probe --rm -i --restart=Never --image=busybox:1.36 -- wget -qO- -T3 http://devlab-api.devlab-dev.svc.cluster.local:5000/healthz   (it times out when the policy works)" <<'X'
rm -f playground/np.txt
---
[ -f playground/np.txt ] && grep -q blocked playground/np.txt && ! kubectl run np-check --rm -i --restart=Never --image=busybox:1.36 -- wget -qO- -T3 http://devlab-api.devlab-dev.svc.cluster.local:5000/healthz >/dev/null 2>&1
---
kubectl run np-test --rm -i --restart=Never --image=busybox:1.36 -- wget -qO- -T3 http://devlab-api.devlab-dev.svc.cluster.local:5000/healthz >/dev/null 2>&1 || echo blocked > playground/np.txt
X

final "Crash the database pod" "Exam 3 of 3. A lead (k8s-exam@example.com) has just been saved through the site. Delete the API pod (devlab-api-0) to simulate a crash. I will check that Kubernetes made a NEW pod, that it is ready again, and that the lead is STILL THERE." "kubectl -n devlab-dev delete pod devlab-api-0   then wait:  kubectl -n devlab-dev wait --for=condition=ready pod/devlab-api-0 --timeout=120s" <<'X'
curl -s -X POST localhost:30080/api/inquiries -H "content-type: application/json" -d '{"name":"K8s Exam","email":"k8s-exam@example.com"}' >/dev/null; kubectl -n devlab-dev get pod devlab-api-0 -o jsonpath='{.metadata.uid}' > playground/.uid
---
[ "$(kubectl -n devlab-dev get pod devlab-api-0 -o jsonpath='{.metadata.uid}' 2>/dev/null)" != "$(cat playground/.uid)" ] && kubectl -n devlab-dev wait --for=condition=ready pod/devlab-api-0 --timeout=60s >/dev/null 2>&1 && [ "$(kleadsfor k8s-exam@example.com)" -ge 1 ]
---
kubectl -n devlab-dev delete pod devlab-api-0 --wait=false >/dev/null 2>&1; sleep 8; kubectl -n devlab-dev wait --for=condition=ready pod/devlab-api-0 --timeout=120s >/dev/null 2>&1
---
bash 06-kubernetes/cluster.sh down >/dev/null 2>&1
X
