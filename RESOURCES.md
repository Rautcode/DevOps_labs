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

## Where to go after this lab
1. **Cloud:** pick one provider and do its free-tier path; redo module 05 against the real API. Certifications worth the effort: AWS Solutions Architect Associate or Azure AZ-104, then CKA / CKAD (Kubernetes) and HashiCorp Terraform Associate.
2. **Specialise:** *SRE* (SLOs, incident command), *Platform engineering* (Backstage, golden paths), or *DevSecOps* (supply chain, policy).
3. **Portfolio:** publish this repo's pipeline and a write-up of your game-day postmortem. Concrete evidence beats a list of tools.
