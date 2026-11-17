# Certification map

Certifications are not required for DevOps jobs, but for juniors they are a cheap, recognisable signal, and preparing for them fills gaps. This page maps the lab to the most useful ones.

> **Check before you book.** Exam names, codes, domains, prices and formats change. Always read the official exam guide on the provider's site first. The lists below are study guidance, not exam content, and I have not verified the current exam domains: use them as a starting point and compare with the official guide.

## Which one first?
| Goal | Start with | Then |
|---|---|---|
| Cloud basics, any role | **AWS Cloud Practitioner** (or Azure AZ-900) | AWS Solutions Architect Associate |
| Infrastructure as code | **HashiCorp Terraform Associate** | a cloud associate exam |
| Kubernetes user | **CKAD** (Certified Kubernetes Application Developer) | CKA |
| Kubernetes admin | **CKA** (Certified Kubernetes Administrator) | CKS (security) |
| Cloud operations | **AWS SysOps Administrator** or Azure AZ-104 | DevOps Engineer Professional |
| Linux | **LFCS** or **RHCSA** | |

Rule of thumb: one cloud associate certification plus either CKAD or the Terraform Associate makes a strong junior CV.

## How the lab maps to the topics
| Certification topic | Practise it in | Still study from the official guide |
|---|---|---|
| Linux fundamentals (LFCS, RHCSA) | 01, 18 | storage (LVM), SELinux, networking configuration, package management |
| Containers and images | 02, 03 | registry authentication, multi-arch builds |
| Kubernetes workloads, config, services (CKAD) | 06, 14, 21 | init containers, sidecars, more probe types, kubectl speed |
| Kubernetes cluster admin (CKA) | 06, 14, 21 | cluster install and upgrade (kubeadm), etcd backup, troubleshooting nodes |
| Terraform (Terraform Associate) | 05, 17, 22 | workspaces, import, remote state in practice, functions, Terraform Cloud |
| CI/CD (GitHub Actions) | 04, 22 | reusable workflows, environments, self-hosted runners |
| Cloud core services (AWS/Azure basics) | 17, 22 | VPC, IAM in depth, S3, EC2, RDS, pricing and the shared responsibility model |
| Monitoring and SRE concepts | 08, 10, 15 | cloud-native monitoring services |
| Security fundamentals | 09, 20 | cloud IAM, encryption services, compliance |

## An 8-week plan (about 8 hours a week)
| Week | Focus |
|---|---|
| 1-2 | Official exam guide and a good video course for your chosen exam. Repeat the matching lab modules. |
| 3-5 | Hands-on in a real account or cluster. Do something small every day. |
| 6-7 | Practice exams. Write down every wrong answer and the reason, then redo the matching lab step. |
| 8 | Book the exam. Rest the day before. |

For the Kubernetes exams, practise typing `kubectl` quickly and use the exam simulator that comes with the registration (check the provider's current terms). The lab's typing-based lessons are good warm-up for that speed.

## Free ways to practise
The cloud providers' free tiers (with a budget alarm first, module 17), the official documentation (open-book rules for the Kubernetes exams allow the docs), and the second-helping repositories listed in RESOURCES.md.
