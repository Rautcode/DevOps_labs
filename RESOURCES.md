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

## Where to go after this lab
1. **Cloud:** pick one provider and do its free-tier path; redo module 05 against the real API. Certifications worth the effort: AWS Solutions Architect Associate or Azure AZ-104, then CKA / CKAD (Kubernetes) and HashiCorp Terraform Associate.
2. **Specialise:** *SRE* (SLOs, incident command), *Platform engineering* (Backstage, golden paths), or *DevSecOps* (supply chain, policy).
3. **Portfolio:** publish this repo's pipeline and a write-up of your game-day postmortem. Concrete evidence beats a list of tools.
