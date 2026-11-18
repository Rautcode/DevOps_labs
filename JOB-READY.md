# Job-ready guide

This lab gives you skills and **evidence**. This page shows how to turn both into interviews and offers. It is honest about what a lab can and cannot do.

## What this lab proves (and what it does not)
| It proves | It does not prove |
|---|---|
| You can build, ship and operate a small service end to end | You have run production at scale with a team |
| You can debug on Linux, Docker and Kubernetes under a scenario | You have been on call for real customers |
| You write Terraform, pipelines, runbooks and postmortems | You know a specific company's stack |
| You can explain your choices out loud (module 23) | You know one company's specific tools |

Aim for **junior DevOps, SRE-trainee, platform or cloud-support roles and internships**. Be upfront that your experience is hands-on practice. Employers hiring juniors value learning speed and honesty.

## Your portfolio checklist (all inside this repo)
Tick each one before you apply. Everything here is public, so a recruiter can click it.
- [ ] The repo is **public** with a clear README and the green **CI badge** (module 22).
- [ ] The pipeline is live: tests, scans and image builds run on every push (module 22, part A).
- [ ] At least one **pull request** you opened and merged yourself, with passing checks (module 22, part C).
- [ ] A **tagged release** with images published (module 22, part C).
- [ ] **Dependabot** pull requests merged (a small, real sign of maintenance).
- [ ] A **postmortem** and a **runbook** written in your own words (modules 10 and 23).
- [ ] The **design document** and your **STAR story** from module 23 saved in the repo, and one **system design** you can draw and explain in 10 minutes (module 24) (copy them out of `playground/`).
- [ ] Optional but strong: a **live URL** from the real-cloud deployment (module 22, part D), with the budget alarm screenshot, and the destroy confirmed.

## CV bullets you can honestly write
Replace the numbers with your own. Do not claim anything you did not do.
- Built a containerised web service (Node.js, nginx) with multi-stage, non-root images; reduced vulnerabilities to zero with Trivy and Hadolint in CI.
- Wrote a GitHub Actions pipeline (tests, dependency audit, image build, secret and IaC scanning) that gates every pull request.
- Provisioned cloud resources with Terraform modules covered by automated tests and Checkov policy scans.
- Deployed to Kubernetes with probes, resource limits, autoscaling, network policies and RBAC; practised GitOps with Argo CD.
- Implemented monitoring with Prometheus and Grafana, defined an SLO and error-budget burn-rate alerts, and ran a game day with a blameless postmortem.
- Practised incident response: diagnosed crash loops, port conflicts, bad releases and disk issues using logs, metrics and runbooks.

## Your GitHub profile in 10 minutes
1. Pin this repo. Write a one-line description: "Hands-on DevOps and cloud lab: Docker, Kubernetes, Terraform, CI/CD, observability, SRE."
2. Add topics: `devops`, `kubernetes`, `terraform`, `docker`, `github-actions`, `sre`.
3. Add a profile README with three bullets: what you built, what you are learning next, how to contact you.

## 30-day plan after finishing
| Week | Do |
|---|---|
| 1 | Redo modules 06 and 08 on a **different app** (see the second-helping links in RESOURCES.md). Make the repo public and tidy. |
| 2 | Run the real-cloud deployment (module 22, part D) with a budget alarm. Take screenshots, then destroy. |
| 3 | Pick a second small project (module 21 or 22 ideas) and add it to the repo, so you have two stories to tell. |
| 4 | Apply to 10 roles a week. For each, tailor three CV bullets to the job post and rehearse the module 23 answers. |

## Interview-day checklist
- Explain one project from start to finish in 3 minutes: the problem, what you built, one thing that broke, what you changed.
- Be ready to **share your screen** and run a command: practise `docker`, `kubectl`, `git` and basic Linux until they are automatic.
- When stuck, think aloud: what do I know, what would I check first, how would I confirm?
- Prepare two questions about on-call, deployments or team practices.
- Never bluff. "I have not done that in production, but in my lab I..." is a good answer.

## What to learn after this lab
Cloud-managed Kubernetes (EKS, AKS or GKE), a second cloud, Python or Go for automation, networking depth (VPCs, subnets, routing), and a real on-call or open-source contribution. Contributing a documentation or small fix to an open-source DevOps project is a genuine, public form of experience.
