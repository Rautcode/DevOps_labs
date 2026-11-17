# 21 · Kubernetes advanced (Extra, ~3h)

> **Guided version:** run `bash lab.sh 21` from the repo root. It explains each step, has you type the commands yourself, and checks your hands-on tasks. This page is the reference. **Unlocks after module 06.**

**Goal:** the Kubernetes topics that come right after the basics: Jobs and CronJobs, configuration in ConfigMaps, resource requests and limits (and the OOMKilled crash), autoscaling with metrics-server, and routing with an Ingress.

| File | What it is |
|---|---|
| [job.yaml](job.yaml), [cronjob.yaml](cronjob.yaml) | a one-off task and a task on a schedule |
| [config-demo.yaml](config-demo.yaml) | a ConfigMap used as an env var and as a file |
| [oom.yaml](oom.yaml) | a pod that needs 100 MB but may use 20 MB: killed with OOMKilled |
| [hpa-demo.yaml](hpa-demo.yaml) | a CPU burner plus a HorizontalPodAutoscaler |
| [ingress.yaml](ingress.yaml) | an Ingress that routes host `devlab.localhost` to the web service |

The lab cluster is created with the add-ons switched on: `K3S_ADDONS=1 bash 06-kubernetes/cluster.sh up` keeps k3s's built-in **metrics-server** and **Traefik** ingress controller (port 8081 on your computer).

## Cheat sheet
| Task | Command |
|---|---|
| Live resource use | `kubectl top nodes`, `kubectl top pods` |
| Why did it restart | `kubectl describe pod X` (Last State, Reason, Exit Code), `kubectl logs X --previous` |
| Job result | `kubectl wait --for=condition=complete job/X`, `kubectl logs job/X` |
| Autoscale quickly | `kubectl autoscale deployment X --cpu-percent=50 --min=1 --max=3` |
| Test an ingress rule | `curl -H 'Host: devlab.localhost' http://localhost:8081/` |

## Concepts
- **Requests** are reserved for scheduling; **limits** are enforced. Memory over the limit means OOMKilled (exit code 137); CPU over the limit means throttling.
- The **HPA** compares usage with the CPU *request*, so set requests. Scaling up is fast, scaling down is deliberately slow.
- An **Ingress** holds routing rules; an **ingress controller** (Traefik, nginx, cloud load balancers) enforces them.

## Break it
1. Remove the CPU request from the burner and see what the HPA reports.
2. Point the Ingress at a Service name that does not exist and read the controller's answer.
3. Give the OOM pod 50Mi: does it live?

## Industry notes
Set requests and limits on everything, add PodDisruptionBudgets and topology spread, use `kubectl top` and your monitoring to right-size, and terminate TLS at the ingress with automatically renewed certificates (cert-manager).
