# Research and further learning

This curriculum was designed after surveying popular GitHub repos, hands-on platforms and DevOps/SRE guides. Notes on what each is good for, and how it shaped this lab. Star counts and 2026 claims come from third-party articles; check the repos yourself.

## What the research showed
- Guides agree on the order: **Linux/Git → containers → CI/CD → cloud + IaC → Kubernetes → monitoring**, then SRE/platform topics (SLOs, error budgets, internal developer platforms). This lab follows it.
- One analysis of 2026 job postings (unverified methodology) puts **Kubernetes, Terraform, AWS and CI/CD** at the top of requirements: modules 04-06 are weighted accordingly.
- Most repos are **question banks or reading lists**, not runnable labs. Few give you one real app to ship end to end, which is the gap this lab fills.
- **LocalStack** now needs an account for current images (March 2026), so this lab pins the last tokenless version and lists alternatives.

## Repos and sites (what to use them for)
| Resource | Best for | Level |
|---|---|---|
| [roadmap.sh/devops](https://roadmap.sh/devops) ([source repo](https://github.com/nilbuild/developer-roadmap)) | see the whole landscape, decide what to learn next | beginner |
| [MichaelCade/90DaysOfDevOps](https://github.com/MichaelCade/90DaysOfDevOps) | structured daily plan: Linux, networking, containers, k8s | beginner |
| [bregman-arie/devops-exercises](https://github.com/bregman-arie/devops-exercises) | questions to find knowledge gaps, interview prep | intermediate |
| [milanm/DevOps-Roadmap](https://github.com/milanm/DevOps-Roadmap) | curated books/courses per step | beginner to intermediate |
| [The-DevOps-Daily/devops-daily](https://github.com/The-DevOps-Daily/devops-daily) | tutorials, exercises, quizzes | mixed |
| [nirgeier/KubernetesLabs](https://github.com/nirgeier/KubernetesLabs), [nirgeier/ArgoCDLabs](https://github.com/nirgeier/ArgoCDLabs) | step-by-step Kubernetes and Argo CD labs | intermediate |
| [kelseyhightower/kubernetes-the-hard-way](https://github.com/kelseyhightower/kubernetes-the-hard-way) | how Kubernetes actually works (manual bootstrap) | advanced |
| [stefanprodan/podinfo](https://github.com/stefanprodan/podinfo) | a tiny app to practise GitOps/progressive delivery on | intermediate |
| [deusyu/gitops-lab](https://github.com/deusyu/gitops-lab) | kind + Argo CD + Flux + Terraform demos | intermediate |
| [mheadd/terraform-local-learning](https://github.com/mheadd/terraform-local-learning) | Terraform with LocalStack and kind | intermediate |
| [dastergon/awesome-sre](https://github.com/dastergon/awesome-sre) | SRE reading list: reliability, incidents, postmortems | intermediate |
| [ramitsurana/awesome-kubernetes](https://github.com/ramitsurana/awesome-kubernetes) | annotated Kubernetes directory | intermediate to advanced |
| [wmariuss/awesome-devops](https://github.com/wmariuss/awesome-devops) | tool landscape | beginner |
| [DevOpsCube: DevOps projects](https://devopscube.com/devops-projects/) | project ideas by level (Nginx, VPC design, Prometheus stack, zero-trust CI/CD, internal developer portal) | beginner to advanced |
| KodeKloud, Killercoda, SadServers | browser-based labs and troubleshooting practice, no setup | all |

## Primary sources (read these, not summaries)
- *Site Reliability Engineering* and *The SRE Workbook* (free at sre.google/books): SLOs, burn-rate alerts (the alert rules here follow the Workbook's multi-window approach).
- DORA research (dora.dev): the four delivery metrics used in module 11.
- *The Twelve-Factor App* (12factor.net): config, logs, disposability.
- Official docs: Kubernetes, Terraform, Prometheus, Argo CD, GitHub Actions, SLSA (slsa.dev).
- Books: *The Phoenix Project* (why), *Accelerate* (evidence), *Kubernetes in Action* (depth), *Terraform: Up & Running* (IaC).

## Specialist modules (12-17): primary documentation
| Topic | Read |
|---|---|
| Networking | `man curl`, `openssl s_client`, the nginx docs for `upstream`, `proxy_pass` and `ssl`; *High Performance Browser Networking* (free online) |
| Ansible | docs.ansible.com (playbooks, roles, Vault); `ansible-lint`; *Ansible for DevOps* |
| Helm and RBAC | helm.sh/docs (charts, values, hooks); kubernetes.io RBAC guide; `kubectl auth can-i --list` |
| Logging and tracing | grafana.com/docs/loki (LogQL), grafana.com/docs/alloy, opentelemetry.io, jaegertracing.io |
| Postgres | postgresql.org/docs (backup and restore, WAL archiving); managed offerings (RDS, Cloud SQL) |
| AWS | AWS Well-Architected Framework, AWS Budgets docs, IAM Identity Center, GitHub OIDC for AWS; Checkov policy index |

Note: Promtail reached end of life in 2026, so the logging module uses Grafana Alloy. LocalStack's latest image needs an account token, so module 05 pins the last tokenless version (4.12).

## More practice: Shubham Londhe (TrainWithShubham) repositories
Shubham Londhe publishes many hands-on DevOps learning repos on GitHub ([profile](https://github.com/LondheShubham153?tab=repositories), about 210 repositories). The ones below fit this lab's modules and make good **second helpings**: same skills, different sample apps. Star counts are from when this list was made and change over time. Only the repository names and short descriptions on the profile were reviewed, so look at a repo's README before committing time to it.

| Repository | What it is | Practise it after module |
|---|---|---|
| [Shell-Scripting-For-DevOps](https://github.com/LondheShubham153/Shell-Scripting-For-DevOps) (~221 stars) | shell scripting for DevOps | 01 Foundations |
| [python-masterclass](https://github.com/LondheShubham153/python-masterclass) (~108 stars) | code for a Python for DevOps course | 01, 04 |
| [two-tier-flask-app](https://github.com/LondheShubham153/two-tier-flask-app) (~247 stars) | a Flask app plus database to containerise | 02, 03 |
| [node-todo-cicd](https://github.com/LondheShubham153/node-todo-cicd) (~283 stars) | a Node to-do app with a CI/CD pipeline | 04 CI/CD |
| [django-notes-app](https://github.com/LondheShubham153/django-notes-app) (~272 stars) | a Django app to containerise and deploy | 02, 04 |
| [django-todo-cicd](https://github.com/LondheShubham153/django-todo-cicd) (~105 stars) | deploying a Django to-do app with Jenkins | 04 (a second CI tool) |
| [github-actions-cicd-masterclass](https://github.com/LondheShubham153/github-actions-cicd-masterclass), [github-actions-practice](https://github.com/LondheShubham153/github-actions-practice), [e-commerce-github-actions](https://github.com/LondheShubham153/e-commerce-github-actions) | GitHub Actions practice material | 04 |
| [terraform-for-devops](https://github.com/LondheShubham153/terraform-for-devops) (~168 stars) | Terraform for DevOps engineers | 05 Terraform |
| [TerraWeek](https://github.com/LondheShubham153/TerraWeek) (~95 stars) | a 7-day Terraform challenge | 05 |
| [kubestarter](https://github.com/LondheShubham153/kubestarter) (~1,000 stars) | starter material for learning Kubernetes | 06 Kubernetes |
| [kubernetes-in-one-shot](https://github.com/LondheShubham153/kubernetes-in-one-shot) (~141 stars) | Kubernetes in one sitting | 06 |
| [k8s-kind-voting-app](https://github.com/LondheShubham153/k8s-kind-voting-app) (~103 stars) | a multi-container voting app on a kind cluster | 06 (practise on a new app) |
| [reddit-clone-k8s-ingress](https://github.com/LondheShubham153/reddit-clone-k8s-ingress) (~43 stars) | learn Kubernetes with an ingress | 06, 12 |
| [argocd-in-one-shot](https://github.com/LondheShubham153/argocd-in-one-shot) (~99 stars), [argocd-demos](https://github.com/LondheShubham153/argocd-demos) | Argo CD learning material and demos | 07 GitOps |
| [observability-for-devops](https://github.com/LondheShubham153/observability-for-devops) (~62 stars) | an observability resource for DevOps engineers | 08, 15 |
| [otel-playground](https://github.com/LondheShubham153/otel-playground) | a sample orders and payments app with OpenTelemetry | 15 Tracing (real instrumentation) |
| [aws-zero-to-hero](https://github.com/LondheShubham153/aws-zero-to-hero) (~172 stars) | AWS from basics to advanced | 17 Real cloud (AWS) |
| [elastic-beanstalk-in-one-shot](https://github.com/LondheShubham153/elastic-beanstalk-in-one-shot) | Elastic Beanstalk notes and three projects | 17 |
| [three-tier-eks-iac](https://github.com/LondheShubham153/three-tier-eks-iac) (~179 stars), [TWSThreeTierAppChallenge](https://github.com/LondheShubham153/TWSThreeTierAppChallenge) (~175 stars) | a three-tier app on EKS with infrastructure as code | 05, 06, 17 (capstone-style) |
| [SkillPulse](https://github.com/LondheShubham153/SkillPulse) | a Go app behind NGINX deployed with GitHub Actions, Terraform and Kubernetes | 11 Capstone (a full pipeline to compare with yours) |
| [90DaysOfDevOps](https://github.com/LondheShubham153/90DaysOfDevOps) (a fork of the TrainWithShubham challenge) | a 90-day DevOps plan | the whole path |

**How to use these:** finish a module here first, then repeat the same idea on a different app from the table. Doing the skill twice, on two apps, is what makes it stick.

## More practice: Abhishek Veeramalla and StackSimplify
**Start with [STUDY-GUIDE.md](STUDY-GUIDE.md):** it says which folder or day to read for each lab module, and what to watch out for.

Two more public sources, matched to the modules. Star counts are approximate and from the GitHub API at the time of writing; read a repo's README before committing time to it.

**[Abhishek Veeramalla](https://github.com/iam-veeramalla)** publishes a "zero to hero" repo for most DevOps topics:
| Repository | What it is | Pairs with module |
|---|---|---|
| [ultimate-linux-guide](https://github.com/iam-veeramalla/ultimate-linux-guide) (~4.2k stars) | learn Linux from scratch | 01, 18 |
| [shell-scripting-projects](https://github.com/iam-veeramalla/shell-scripting-projects) (~1.2k) | shell scripting projects that simulate real work | 01 |
| [Docker-Zero-to-Hero](https://github.com/iam-veeramalla/Docker-Zero-to-Hero) (~7.5k) | Docker with examples | 02, 03 |
| [Jenkins-Zero-To-Hero](https://github.com/iam-veeramalla/Jenkins-Zero-To-Hero) (~10k), [GitHub-Actions-Zero-to-Hero](https://github.com/iam-veeramalla/GitHub-Actions-Zero-to-Hero) (~1.9k), [cicd-end-to-end](https://github.com/iam-veeramalla/cicd-end-to-end) | CI/CD with Jenkins and GitHub Actions, plus an end-to-end demo | 04, 07 |
| [terraform-zero-to-hero](https://github.com/iam-veeramalla/terraform-zero-to-hero) (~4.3k) | Terraform in 7 days | 05 |
| [Kubernetes-Zero-to-Hero](https://github.com/iam-veeramalla/Kubernetes-Zero-to-Hero) (~2.8k), [kubernetes-troubleshooting-zero-to-hero](https://github.com/iam-veeramalla/kubernetes-troubleshooting-zero-to-hero) (~1k) | Kubernetes basics and fixing common problems | 06, 21 |
| [observability-zero-to-hero](https://github.com/iam-veeramalla/observability-zero-to-hero) (~3.2k) | learn observability | 08, 15 |
| [a-to-z-of-networking](https://github.com/iam-veeramalla/a-to-z-of-networking) (~1k) | networking with real-time examples | 12 |
| [ansible-zero-to-hero](https://github.com/iam-veeramalla/ansible-zero-to-hero) (~1.7k) | Ansible fundamentals with examples | 13 |
| [aws-devops-zero-to-hero](https://github.com/iam-veeramalla/aws-devops-zero-to-hero) (~11.7k) | AWS in 30 days, with projects and interview questions | 17 |
| [ultimate-devops-project-aws](https://github.com/iam-veeramalla/ultimate-devops-project-aws) (~1k) | an end-to-end DevOps project | 11, 22 |
| [devops-cloud-interview-guide](https://github.com/iam-veeramalla/devops-cloud-interview-guide) (~1.4k), [devops-interview-preparation-guide](https://github.com/iam-veeramalla/devops-interview-preparation-guide) (~1.1k) | interview questions | 23 |

**[StackSimplify: aws-eks-kubernetes-masterclass](https://github.com/stacksimplify/aws-eks-kubernetes-masterclass)** (~1.8k stars) is a step-by-step course repo for running Kubernetes on AWS EKS. Its folders cover Docker and Kubernetes fundamentals, storage with EBS and RDS, load balancers, Fargate, ECR, a DevOps pipeline, microservices with tracing and canary deployments, autoscaling (HPA, VPA, cluster autoscaler) and CloudWatch monitoring. Use it **after modules 06, 14 and 21**, when you want to repeat those ideas on a managed cluster. EKS costs real money, so set a budget alarm first (module 17) and delete the cluster when you finish.

## Where to go after this lab
1. **Cloud:** pick one provider and do its free-tier path; redo module 05 against the real API.
2. **Specialise:** *SRE* (SLOs, incident command), *Platform engineering* (Backstage, golden paths), or *DevSecOps* (supply chain, policy).
3. **Portfolio:** publish this repo's pipeline and a write-up of your game-day postmortem. Concrete evidence beats a list of tools.
