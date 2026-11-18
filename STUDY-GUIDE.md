# Study guide: this lab plus two public course repos

The lab teaches you by **doing**. The repos below are good for **reading and a second pass** on the same skills with a different app. This guide says exactly what to read, in which order, and what to watch out for. I read the repository folders and READMEs listed here before writing it; I did not run their code.

- **A. Veeramalla:** [github.com/iam-veeramalla](https://github.com/iam-veeramalla) (Abhishek Veeramalla). Many "zero to hero" repos, most laid out as day-by-day folders.
- **StackSimplify:** [aws-eks-kubernetes-masterclass](https://github.com/stacksimplify/aws-eks-kubernetes-masterclass) (Kalyan Reddy Daida). A step-by-step Kubernetes-on-AWS course. The README advertises a paid video course; the repo itself holds the written steps.

## The rhythm for every topic (about 3 steps)
1. **Do the lab module first.** It is guided, local and free, and it checks your work.
2. **Read** the matching chapter below for a second explanation and more examples.
3. **Repeat the idea on their app** without help (this is the part that makes it stick), then write 3 lines of notes: what broke, what fixed it.

## Topic map

| Lab module | Read in these repos | What you get |
|---|---|---|
| **00-01** Git, Linux, shell | [ultimate-linux-guide](https://github.com/iam-veeramalla/ultimate-linux-guide): folders 01 to 10 (getting started, folder structure, users, files, vi, permissions, processes, monitoring, networking, disks). [shell-scripting-projects](https://github.com/iam-veeramalla/shell-scripting-projects): two real projects (AWS S3 event triggering, GitHub API) | A text reference for every Linux skill in modules 01 and 18, and shell projects for after module 01 |
| **02-03** Docker, Compose | [Docker-Zero-to-Hero](https://github.com/iam-veeramalla/Docker-Zero-to-Hero): README plus `commands.md`, `networking.md`, `volumes.md`, `examples/` | Containers vs VMs, commands, networking and volumes written out |
| **04** CI/CD | [GitHub-Actions-Zero-to-Hero](https://github.com/iam-veeramalla/GitHub-Actions-Zero-to-Hero) (a small repo with examples and a GitHub-Actions-vs-Jenkins comparison). [Jenkins-Zero-To-Hero](https://github.com/iam-veeramalla/Jenkins-Zero-To-Hero): pipelines, Docker agents, multi-stage pipelines, shared libraries, plus `Interview_Questions.md`. [cicd-end-to-end](https://github.com/iam-veeramalla/cicd-end-to-end) | A second CI tool (Jenkins) so you can compare it with GitHub Actions in an interview |
| **05** Terraform | [terraform-zero-to-hero](https://github.com/iam-veeramalla/terraform-zero-to-hero): Day 1 getting started and lifecycle, Day 2 advanced configuration, Day 3 modules, Day 4 state and collaboration, Day 5 provisioners, Day 6 workspaces, Day 7 security and advanced topics | Workspaces and provisioners are **not** covered in this lab; learn them here |
| **06, 14, 21** Kubernetes | [kubernetes-troubleshooting-zero-to-hero](https://github.com/iam-veeramalla/kubernetes-troubleshooting-zero-to-hero): ImagePullBackOff, CrashLoopBackOff, pods not schedulable (node selector, affinity, taints, tolerations), StatefulSet and volumes, NetworkPolicy. [StackSimplify masterclass](https://github.com/stacksimplify/aws-eks-kubernetes-masterclass) for Secrets, init containers, probes, requests and limits, namespaces with LimitRange and ResourceQuota, storage classes, PV and PVC, Ingress, HPA, VPA | Module 21 now has the first three troubleshooting cases hands-on |
| **08, 15** Monitoring, logs | [observability-zero-to-hero](https://github.com/iam-veeramalla/observability-zero-to-hero): a 7-day series. Days 1 to 4 (read): observability concepts, Prometheus and Grafana with the kube-prometheus-stack Helm chart, PromQL, custom metrics with `prom-client` plus Alertmanager. The repo also has an OpenSearch stack | Real **PromQL** practice and writing your own metrics in code |
| **12** Networking | [a-to-z-of-networking](https://github.com/iam-veeramalla/a-to-z-of-networking): 11 topics: IP addressing and subnetting, TCP/IP and OSI, DNS, HTTP, load balancing, firewalls, VPN, proxies, CDN, Docker networking, Kubernetes networking | The theory behind module 12, plus firewalls, VPN and CDN that the lab does not cover |
| **13** Ansible | [ansible-zero-to-hero](https://github.com/iam-veeramalla/ansible-zero-to-hero): Days 1 to 9: install, ad-hoc commands and inventory, first playbook, roles, Galaxy, variables and Jinja2 templates, conditionals and loops, error handling, **Ansible Vault** | Roles, templates and Vault are **not** covered in the lab; learn them here |
| **17** AWS | [aws-devops-zero-to-hero](https://github.com/iam-veeramalla/aws-devops-zero-to-hero): a 27-day plan (IAM, EC2, VPC, Route 53, S3, CLI, CloudFormation, CodePipeline, CodeBuild, CodeDeploy, CloudWatch, Lambda, EventBridge, CloudFront, ECR, ECS, EKS, Systems Manager, Terraform, CloudTrail, Elastic Load Balancer) plus interview questions | The service-by-service background the lab's budget and security module assumes |
| **11, 22** End to end | [ultimate-devops-project-aws](https://github.com/iam-veeramalla/ultimate-devops-project-aws): notes for a ten-section end-to-end project, including EKS install and an ingress controller | A bigger project to compare with your own pipeline |
| **23** Interviews | `Interview_Questions.md` in Jenkins-Zero-To-Hero, [devops-cloud-interview-guide](https://github.com/iam-veeramalla/devops-cloud-interview-guide), [devops-interview-preparation-guide](https://github.com/iam-veeramalla/devops-interview-preparation-guide), `interview-questions/` in aws-devops-zero-to-hero | Extra questions to practise out loud after finishing the lab's mock interview |

## The StackSimplify masterclass: a suggested route
It builds one application up on **AWS EKS**. Its 18 chapters, in the order the README lists them: create a cluster with eksctl, Docker fundamentals, Kubernetes fundamentals, storage with the EBS CSI driver, important concepts (Secrets, init containers, probes, requests and limits, namespaces), storage with RDS MySQL, load balancers (Classic, Network, Application with Ingress, SSL, External DNS), Fargate, ECR, a CodeCommit/CodeBuild/CodePipeline pipeline, microservices and service discovery, X-Ray tracing, canary deployments, HPA, VPA, Cluster Autoscaler, and CloudWatch Container Insights.

Use it like this:
1. **Finish lab modules 06, 14 and 21 first.** Chapters 2, 3 and 5 are then revision, and you can go quickly.
2. **Skip the cluster-creation chapters until you have a budget alarm** (lab module 17). EKS and load balancers bill by the hour.
3. Do the chapters that match what you learned (probes, limits, Ingress, autoscaling) on EKS. The ideas are identical to the lab; only the platform differs.
4. **Delete everything when you finish** (`eksctl delete cluster`, then check for leftover load balancers and volumes).

## Cost and safety notes
- [Kubernetes-Zero-to-Hero](https://github.com/iam-veeramalla/Kubernetes-Zero-to-Hero) installs Kubernetes with **kOps on EC2**, using broad IAM permissions (EC2, S3, IAM and VPC full access). Its own README warns that some created resources are outside the free tier. Prefer the lab's local cluster for learning; if you try kOps, use a throwaway account with a budget alarm.
- Jenkins-Zero-To-Hero starts from an EC2 instance. Do not leave a Jenkins server open to the internet: restrict the port to your own IP, as the README itself says.
- Never paste real keys into someone else's example. Follow lab module 20 for secrets.
- Many of these repos are lecture notes for videos. Some pages are short. Treat them as a map and use the official documentation (see [RESOURCES.md](RESOURCES.md)) when a page is thin.

## What this lab covers that those repos do not (and the reverse)
- **Only in the lab:** the guided check of your work, exams, SLOs and error budgets, a real disaster-recovery drill, Vault, Argo CD with drift, security scanners in CI, a live GitHub pipeline, and the mock interview.
- **Only in the repos (learn them next):** Terraform workspaces and provisioners, Ansible roles, templates and Vault, Jenkins, Lambda and the other AWS services, CDN, VPN and firewalls, and the cloud-managed Kubernetes (EKS) experience.

## A 6-week plan
| Week | Lab | Repos |
|---|---|---|
| 1 | Modules 00, 01, 02, 03 | ultimate-linux-guide, Docker-Zero-to-Hero |
| 2 | Modules 04, 05 | GitHub-Actions-Zero-to-Hero, terraform-zero-to-hero (Days 4 to 7) |
| 3 | Modules 06, 07, 14, 21 | kubernetes-troubleshooting-zero-to-hero, StackSimplify chapters 5 and 15 to 17 (read; run only with a budget alarm) |
| 4 | Modules 08, 09, 10, 15 | observability-zero-to-hero (Days 2 to 4) |
| 5 | Modules 12, 13, 16, 17, 18, 20 | a-to-z-of-networking, ansible-zero-to-hero (Days 4 to 9), aws-devops-zero-to-hero (first 10 days) |
| 6 | Modules 11, 19, 22, 23 | interview guides, ultimate-devops-project-aws |
