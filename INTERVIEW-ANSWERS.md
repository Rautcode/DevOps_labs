# Interview-ready answers

One spoken answer for every topic in the lab, grouped by module. Each is about 40 to 70 seconds when said aloud.

**How to use this page**
- Read the lab explanation first, then say the answer **out loud, in your own words**. Do not memorise it word for word; interviewers can tell.
- Add one real detail from your own practice (a command you ran, something that broke). The answers mention the lab where it fits.
- Be honest: this is hands-on lab experience, not production experience. "In my lab I..." is a strong, truthful opening.
- The same answers appear in the guided lab, in a yellow **INTERVIEW-READY ANSWER** box after each topic.

## Module 00 · Git from zero

### Git is a time machine for your files

**If asked:** What is Git and why do teams use it?

> Git is a version control system. Every time I commit, it saves a snapshot of the project with a message and an author, so I can see what changed, compare versions and go back if something breaks. Teams use it because many people can work on the same code at once, on separate branches, without overwriting each other, and every change can be reviewed.

### A repository is just a folder Git is watching

**If asked:** What is a repository, and what does git init do?

> A repository is a normal project folder that Git is tracking. It has a hidden .git folder where Git keeps the whole history. git init creates it, and from then on I use git status, add and commit to record changes. The three places to remember are the working folder, the staging area and the commit history.

### Change, look, commit

**If asked:** What does your everyday Git workflow look like?

> I edit files, check what changed with git status and git diff, stage only what belongs together with git add, and commit with a clear message that says what and why. I keep commits small, so the history is easy to read, easy to review and easy to undo if one of them turns out to be wrong.

### Nobody is afraid of mistakes in Git

**If asked:** How do you undo a mistake in Git?

> It depends where the mistake is. For an unsaved edit I use git restore to bring a file back to the last commit. If a bad commit is already shared, I use git revert, which adds a new commit that undoes it, so history is not rewritten. And if I think I lost work, git reflog usually shows where it went.

### A branch is a parallel timeline

**If asked:** What is a branch, and why use one?

> A branch is a separate line of work. I create one per feature or fix with git switch -c, commit there without disturbing main, and merge it back when it is reviewed and ready. If the idea does not work out, I just delete the branch. It keeps main stable and lets several people work in parallel.

### The .gitignore file

**If asked:** How do you keep secrets and build files out of Git?

> I list them in a .gitignore file before I create them, for example .env files, keys, node_modules and build output. The important point is that anything committed once stays in the history, so ignoring it afterwards is too late. If a secret is ever committed, I treat it as leaked and rotate it, rather than just deleting the file.

### Remotes, push and pull

**If asked:** What is the difference between clone, push and pull?

> A remote, usually on GitHub, is a shared copy of the repository. git clone downloads it the first time. git push sends my commits to it, and git pull brings other people's commits to me. For team work I push a branch and open a pull request, so the change is reviewed before it is merged into main.

## Module 01 · Foundations

### Containers in one minute

**If asked:** What is a container, and how is it different from a virtual machine?

> A container is an isolated process that packages an app with its dependencies, and it shares the host's kernel. A virtual machine has a whole guest operating system on virtual hardware. So containers are much smaller and start in seconds, while VMs give stronger isolation. I use containers so the app runs the same on my laptop, in CI and in production.

### Look inside a running container

**If asked:** How do you debug a running container?

> I start with docker ps to see its state, then docker logs for what it printed, and docker exec to run a command inside it, like checking the user, the files or the environment variables. docker inspect shows the configuration and the health status. In a minimal image there may be no shell tools, so I rely on the logs and the /proc filesystem.

### HTTP in 60 seconds

**If asked:** Explain a basic HTTP request.

> A client sends a request with a method like GET or POST, a path, headers and sometimes a body. The server answers with a status code, headers and a body. Codes in the 200s mean success, 300s are redirects, 400s mean the client's request was wrong, like 404 not found, and 500s mean the server failed. I use curl with -i to see the exact headers when I debug.

### Git keeps you safe

**If asked:** Why is Git useful beyond storing code?

> It gives me a safety net and a history. I can branch to try something risky, see exactly what changed with diff and log, and undo a bad change. For a team it is also the audit trail: every change has an author, a message and a review. That is why infrastructure and configuration belong in Git too.

### Scripts and exit codes

**If asked:** What is an exit code, and why does it matter in automation?

> Every command ends with an exit code: zero means success and anything else means failure. Scripts and CI pipelines rely on it to decide whether to continue. In shell scripts I use set -e and check the codes, so a failed step stops the pipeline instead of silently carrying on with bad data.

### Debug by layers

**If asked:** A website is not loading. How do you troubleshoot?

> I work through the layers from the bottom up. Is the machine or container running? Does the name resolve in DNS? Does the port accept a connection? Does the app return the right status, and what do its logs say? Going layer by layer finds the broken part quickly instead of guessing, and I stop at the first layer that fails.

## Module 02 · Containers

### Image, container, registry

**If asked:** What are an image, a container and a registry?

> An image is a read-only package with an app and everything it needs. A container is a running instance of an image. A registry, like Docker Hub or ECR, is where images are stored and pulled from. So the flow is: build an image, push it to a registry, then pull and run it as containers wherever I need it.

### Ports and background containers

**If asked:** What does docker run -d -p 8080:80 do?

> It starts a container in the background, detached, and publishes port 80 inside the container as port 8080 on my machine. The first number is the host port and the second is the container port. I usually add --name so I can refer to it, and I check it with docker ps and docker logs.

### The Dockerfile

**If asked:** What is a Dockerfile, and how do layers and caching work?

> A Dockerfile is the recipe for an image: FROM chooses the base, COPY adds files, RUN executes build commands and CMD sets what starts. Each instruction becomes a layer, and Docker caches layers it has already built. So I put rarely changing steps, like installing dependencies, before frequently changing ones, like copying the source code, to keep rebuilds fast.

### Static site in nginx

**If asked:** How would you containerise a static website?

> I use the official nginx image as the base and copy the site files into /usr/share/nginx/html with a two-line Dockerfile. nginx already knows how to start, so I do not need a CMD. Then I build the image, run it with a published port and check it with curl. For production I would pin the image version.

### Production images

**If asked:** What makes a Docker image production-ready?

> A small base image and a multi-stage build, so compilers and build tools are not shipped; a non-root user; pinned versions instead of latest; a HEALTHCHECK; and a .dockerignore so secrets and junk stay out. Then I scan the image for vulnerabilities in CI. Smaller, simpler images pull faster and have less attack surface.

### Running a container

**If asked:** How do you run and verify a container properly?

> I run it detached with a name, a port mapping and environment variables for configuration, never secrets baked into the image. Then I verify it with the health check status, docker logs and a curl to its health endpoint. A HEALTHCHECK matters because it tells Docker the difference between started and actually working.

### Fail fast

**If asked:** What does fail fast mean for a service?

> The service checks its required configuration at startup, for example a missing or weak secret, and refuses to run with a clear error. A loud crash at startup is cheap to fix, while a service that quietly runs misconfigured can cause a security hole or data problems in production. And the orchestrator sees the failure immediately.

### Your own Dockerfile

**If asked:** What are best practices when writing a Dockerfile?

> Use a specific, pinned base image, write CMD in exec form so signals reach the process, copy only what is needed, order layers for caching, run as a non-root user and keep the image small. I also use multi-stage builds when there is a build step, and I lint the file with hadolint.

## Module 03 · Compose

### Why Docker Compose?

**If asked:** Why use Docker Compose?

> Real applications are several containers. Compose describes the whole stack in one file, with services, networks, volumes, environment and health checks, and I start everything with one command. It is reproducible and reviewable, so a new teammate gets the same environment. It is great for local development and tests; for production at scale I would use Kubernetes.

### Volumes keep data

**If asked:** How do containers persist data?

> A container's own filesystem is disposable: it disappears when the container is removed. A volume is storage managed outside the container, so the data survives restarts and replacement. Databases and uploads should always use volumes. I also back them up, because a volume protects against losing the container, not against deletion or corruption.

### Override files

**If asked:** How do you manage different environments with Compose?

> I keep a base compose file and add override files with -f. Later files override earlier ones, so a monitoring or production override contains only the differences. That avoids copying a big file per environment and keeps the shared parts in one place.

## Module 04 · CI/CD

### What CI/CD means

**If asked:** What is CI/CD?

> Continuous integration means every change is automatically built, tested and scanned, so problems are caught within minutes. Continuous delivery or deployment extends that: a passing change is packaged and can be released automatically. The result is small, frequent, low-risk releases instead of big risky ones. In my project, every pull request runs tests, a dependency audit and an image build.

### Reproducible builds

**If asked:** How do you make builds reproducible?

> I commit lock files and install with npm ci, so CI uses exactly the same dependency versions as my machine. I pin base images and actions, ideally to a digest or commit SHA, and I avoid latest tags. That way a build that passes today produces the same result tomorrow, and a supply-chain surprise cannot sneak in.

### Anatomy of a workflow

**If asked:** Walk me through a GitHub Actions workflow.

> A workflow is a YAML file in .github/workflows. The on key says what triggers it, like a push or pull request. Jobs run on runners, and each job has steps that use actions or run commands. I give it the minimum permissions, pin actions to a commit SHA, and use secrets for credentials. A failing step fails the job and blocks the merge.

### Jenkins and GitHub Actions

**If asked:** How does Jenkins compare with GitHub Actions?

> Both run pipeline stages on every change. Jenkins is self-hosted and very flexible, with a huge plugin ecosystem and a Jenkinsfile, but I have to maintain the server, plugins and security. GitHub Actions is hosted next to the code, written in YAML, and needs no server. I would choose Actions for simplicity, and Jenkins when a company already runs it or needs heavy customisation.

## Module 05 · Terraform (Infrastructure as Code)

### Infrastructure as code

**If asked:** What is infrastructure as code, and why use it?

> It means describing infrastructure in files instead of clicking in a console. The files live in Git, so changes are reviewed, versioned and repeatable, and I can recreate an environment from scratch. It also reduces drift and human error. In my lab I used Terraform to create a bucket, queues and permissions, and tested the module before applying it.

### The Terraform workflow

**If asked:** Explain the Terraform workflow and the state file.

> I run init to download providers, plan to preview exactly what will change, and apply to make it so. Terraform stores what it created in a state file that maps my code to real resources. State can contain secrets, so it is never committed, and in a team it lives in a remote backend with locking. I always read the plan before applying.

### Workspaces

**If asked:** What are Terraform workspaces?

> A workspace is a separate state for the same code, so one configuration can manage several environments such as dev and staging. A new workspace starts empty, so Terraform wants to create everything again without touching the other one. Many teams prefer separate folders or state files per environment, because applying in the wrong workspace is an easy mistake, so I always check the current workspace first.

## Module 06 · Kubernetes

### What Kubernetes does

**If asked:** What does Kubernetes do?

> Kubernetes runs containers across machines and keeps them in the state I declare. I describe what I want, for example two copies of the web service, and controllers keep making reality match. It restarts crashed containers, rolls out updates without downtime, balances traffic through Services and enforces resource and network rules. The main objects are pods, deployments, services and config.

### Self-healing

**If asked:** How does Kubernetes self-heal?

> Controllers continuously compare the desired state with the actual state. If a pod dies, the Deployment creates a replacement. Liveness probes restart containers that hang, readiness probes keep traffic away from pods that are not ready, and the pods of a failed node are rescheduled elsewhere. I demonstrated it by deleting a pod and watching a new one appear within seconds.

### Scaling

**If asked:** How do you scale an application on Kubernetes?

> Stateless apps scale horizontally by changing the replica count, manually with kubectl scale or automatically with a Horizontal Pod Autoscaler based on CPU or other metrics. Requests and limits matter so the scheduler places pods sensibly. Stateful services like databases need more care, usually a StatefulSet with persistent volumes, or a managed database.

## Module 07 · GitOps

### Kustomize: base plus overlays

**If asked:** How do you manage config for several environments in Kubernetes?

> With Kustomize I keep a base with the manifests all environments share, and an overlay per environment, such as dev and prod, that patches only the differences, like replicas, image tags or resources. It is plain YAML without templating and is built into kubectl, and it keeps environments consistent. Helm is the alternative when I want templated, packaged charts.

### Argo CD

**If asked:** What is GitOps, and how does Argo CD work?

> GitOps means Git is the single source of truth for what runs in the cluster. Argo CD runs in the cluster, watches a Git repository and keeps the cluster in sync with it. If someone changes the cluster by hand, it detects the drift and can revert it. Every change is reviewed in a pull request and recorded in the history.

### Changes go through git

**If asked:** How do you roll back a bad release with GitOps?

> I revert the commit in Git and let the controller apply it. Nobody edits the live cluster by hand, so the history shows exactly what changed and who approved it, and a rollback is just another reviewed commit. It is auditable and repeatable, which is the whole point of GitOps.

## Module 08 · Observability

### Monitoring basics

**If asked:** How does Prometheus monitoring work?

> Prometheus pulls, or scrapes, metrics from targets every few seconds and stores them as time series. Grafana visualises them, and alert rules are queries that fire when a condition holds for long enough. I also used black-box probes, which measure what a visitor really experiences without changing the app. Alerts go through Alertmanager to notify a person.

### The Prometheus query language

**If asked:** What is PromQL, and how do you use rate?

> PromQL is Prometheus' query language. A selector picks series by name and labels, and functions and aggregations like sum by combine them. Counters only ever increase and reset on restart, so I never read them raw: rate over a window gives the per-second speed. Gauges, like current memory, can be read directly. Alerts and dashboards are all written in PromQL.

### Alerts and burn rate

**If asked:** How do you design good alerts?

> I alert on symptoms users feel, not on causes like high CPU, and I make alerts actionable. A for duration avoids flapping on short blips. Burn-rate alerts watch how fast the error budget is being used over a short and a long window, so I get paged quickly for a serious outage and only get a ticket for a slow leak. That reduces alert fatigue.

## Module 09 · DevSecOps

### Shift left

**If asked:** What does shift left mean in DevSecOps?

> It means finding security problems as early as possible, when they are cheapest to fix. Instead of one audit before release, I scan on every commit and pull request: secrets with gitleaks, Dockerfiles with hadolint, images and dependencies with Trivy, and infrastructure code with Checkov. Developers get fast feedback, and the pipeline blocks risky changes automatically.

### Test what the site REALLY sends

**If asked:** How do you verify security headers?

> Scanners read files, but only a real request shows what the server actually sends. I use curl -i against the running site and check headers like Content-Security-Policy, X-Content-Type-Options and Strict-Transport-Security. In my lab I hit a subtle nginx issue where add_header in a location block replaced the inherited headers, which a live header check caught and a file scan did not.

### Dependencies are risk

**If asked:** How do you handle vulnerable dependencies?

> I run npm audit and an image scanner in CI, keep a lock file, and enable Dependabot so updates arrive as reviewed pull requests. I prioritise by severity and by whether the vulnerable code is actually reachable, and I fix or upgrade rather than ignore. Fewer dependencies and minimal base images also reduce the risk.

## Module 10 · SRE and incident response

### SLI, SLO and error budget

**If asked:** Explain SLI, SLO and error budget.

> An SLI is a measured number, like the percentage of successful requests. An SLO is the target I promise, like 99.9 percent over thirty days. The error budget is what is left over, the allowed failure, here about 43 minutes a month. If the budget is healthy we ship features; if it is burning, we slow down and fix reliability.

### Game days

**If asked:** What is a game day?

> A planned failure exercise in a safe environment. I break something on purpose, like stopping a service, and measure how quickly we detect it, whether the alerts and the runbook work, and how long recovery takes. It finds gaps in monitoring and documentation before a real incident does, and the findings turn into improvements.

### Blameless postmortems

**If asked:** How do you run a postmortem?

> Blameless and written down: a summary, the impact, a timeline, the root cause and contributing factors, what went well, what went badly, and action items with owners and dates. The focus is on the system and the process, not on who made a mistake, so people report problems honestly. Follow-up actions are tracked until they are done.

## Module 11 · Capstone

### Backups and recovery

**If asked:** How do you approach backups and disaster recovery?

> A backup is only real once I have restored it. I define the RPO, how much data I can afford to lose, and the RTO, how long recovery may take, and choose backup frequency and method from that. I keep copies in another location, automate backups and run restore drills regularly. In my lab I deleted data on purpose and restored it to prove the process.

## Module 12 · Networking

### DNS: names to addresses

**If asked:** What happens when you type a URL into a browser?

> The browser checks its cache, then asks a DNS resolver to turn the name into an IP address. It opens a TCP connection to that address and port, does a TLS handshake for HTTPS, sends the HTTP request, and the server responds. Each step can fail differently, so I troubleshoot in that order: DNS, connection, TLS, then HTTP.

### IP addresses and subnets (CIDR)

**If asked:** What does 10.0.1.0/24 mean?

> It is CIDR notation. The first 24 bits identify the network and the remaining 8 bits are for hosts, so there are 256 addresses, 254 of them usable. A bigger slash number means a smaller network. Cloud networks are carved from private ranges like 10.0.0.0/8, 172.16.0.0/12 and 192.168.0.0/16, and I plan subnets so they do not overlap.

### Ports and TCP

**If asked:** What is the difference between an IP address and a port?

> An IP address finds the machine and a port finds the program on it. A server listens on a port and a client opens a TCP connection to it. Two programs cannot listen on the same port, which causes the classic port already allocated error. I use tools like ss or curl to see what is listening and whether a connection succeeds.

### TLS and certificates

**If asked:** How does TLS work?

> TLS encrypts the connection and authenticates the server. The server presents a certificate signed by a trusted certificate authority, the client checks that it is valid, not expired and issued for that name, and then they agree on keys for encryption. Expired or mismatched certificates are a common cause of outages, so I monitor expiry and automate renewal.

### Load balancing and failover

**If asked:** What does a load balancer do?

> It spreads requests across several copies of a service and stops sending traffic to unhealthy ones, using health checks. That gives scalability and availability. Algorithms include round robin, least connections and IP hash, and it can work at layer 4 on connections or layer 7 on HTTP. I built one with nginx and showed requests still succeed when I stop one backend.

### Firewalls

**If asked:** How do firewalls and security groups work?

> They allow or deny traffic by source, destination and port. The safe default is to deny everything and allow only what is needed, for example 443 from anywhere and SSH only from a trusted address. Security groups in the cloud are stateful, so replies are allowed automatically. A dropped packet gets no answer, so the client just times out, which is a useful clue when debugging.

### Reaching things that are not on the internet

**If asked:** How do you give access to a private service securely?

> Private services get no public address. I provide a controlled doorway: a bastion or jump host, a port-forwarding tunnel such as SSH or SSM, or a VPN for whole networks. Then only one hardened, logged entry point needs protecting instead of many exposed services. In my lab I built a bastion that forwarded one port into a private network.

### What a CDN does

**If asked:** What is a CDN, and when do you use it?

> A content delivery network is a set of cache servers close to users. A request is answered from the nearest edge on a hit, and only a miss goes to the origin, so it is faster and takes load off the origin. It is ideal for static public content. Personalised or private pages must not be cached for everyone, and the TTL controls how long a copy is kept.

## Module 13 · Ansible

### Configuration management

**If asked:** What is configuration management, and where does Ansible fit?

> Terraform creates infrastructure, and a configuration management tool like Ansible configures what runs on it: packages, files, users and services. I describe the desired state in a playbook and Ansible makes each server match, over SSH with no agent. It makes servers consistent, repeatable and documented, instead of hand-configured.

### Ad-hoc commands and playbooks

**If asked:** What is the difference between an ad-hoc command and a playbook?

> An ad-hoc command runs one module on many servers right now, which is good for quick checks like ping. A playbook is a saved, repeatable, reviewable list of tasks that describes the desired state. For anything that changes servers permanently I use a playbook kept in Git.

### Idempotence

**If asked:** What does idempotent mean?

> Running it once or many times gives the same result. Ansible tasks describe a state, like package present, and Ansible changes things only if the server differs. The second run reports no changes. That makes the automation safe to re-run, and I can use it to continuously enforce the desired state.

### Drift

**If asked:** What is configuration drift?

> Drift is when a server no longer matches its desired state, usually because someone changed it by hand. Re-running the playbook detects the difference and repairs it. To prevent drift I restrict manual changes, keep everything in code and run the automation regularly. In my lab I edited a config by hand and Ansible put it back.

### Roles

**If asked:** What are Ansible roles?

> A role packages one job in a standard folder structure with tasks, defaults, templates and handlers, so it can be reused across playbooks and projects. A playbook then just lists the roles to apply. Defaults can be overridden with variables, and Ansible Galaxy shares community roles. Roles keep large automation organised and testable.

### Ansible Vault

**If asked:** How do you manage secrets in Ansible?

> I encrypt secret variable files with Ansible Vault, so the encrypted file can be committed to Git while the vault password is stored elsewhere, like a CI secret or a password manager. Playbooks decrypt it in memory, and I set no_log on tasks that handle secrets. For rotation and access control I would use a secrets manager such as HashiCorp Vault.

## Module 14 · Helm and RBAC

### Helm: a package manager for Kubernetes

**If asked:** What is Helm?

> Helm is the package manager for Kubernetes. A chart is a set of templated manifests, and values let me configure each install, for example per environment. I can install, upgrade and roll back a release with single commands, and Helm keeps a history of releases. It is great for third-party software and for packaging my own apps consistently.

### RBAC: who may do what

**If asked:** How does Kubernetes RBAC work?

> By default an account can do nothing. A Role lists allowed verbs on resources in a namespace, and a RoleBinding gives that role to a user or service account. ClusterRoles work cluster-wide. I follow least privilege, give each workload its own service account, and test permissions with kubectl auth can-i.

## Module 15 · Logging and tracing

### Logs, metrics and traces

**If asked:** What are the three pillars of observability?

> Metrics are numbers over time that tell me that something is wrong. Logs are event records that tell me what happened. Traces follow one request across services and tell me where the time went. I use them together: an alert from metrics, logs to find the error, and a trace to find the slow service.

### Traces and spans

**If asked:** What is distributed tracing?

> A trace is the journey of one request through the system, made of spans, each representing one operation with a start time and a duration. A trace ID is passed between services, so I can see the whole path and find which step is slow or failing. I used Jaeger to view traces and OpenTelemetry to produce them.

## Module 16 · Postgres

### Stateless apps and a shared database

**If asked:** What is a stateless application, and why does it matter?

> A stateless service keeps no important data in its own memory or disk; state lives in a shared database or cache. Then any copy can serve any request, so I can run many copies, replace them freely and scale horizontally. My API originally used a local SQLite file, which limited it to one copy, so I moved the data into Postgres.

### Scaling out

**If asked:** What is horizontal scaling, and what does it need?

> Horizontal scaling means adding more copies instead of a bigger machine. It needs stateless instances, a load balancer in front and shared state in a database. It improves capacity and availability, but the database can become the bottleneck, so then I look at caching, read replicas and eventually sharding.

### Logical backups

**If asked:** How do you back up a PostgreSQL database?

> pg_dump produces a logical backup, the database as SQL that I can replay with psql, which is simple and portable. For large systems I add continuous archiving or managed snapshots for point-in-time recovery. Either way I store backups off the server and test restores regularly, because an untested backup is not a backup.

## Module 17 · Real cloud: AWS

### Same code, different target

**If asked:** How do you test cloud infrastructure code safely and cheaply?

> I run the same Terraform module against LocalStack, a local AWS emulator, to test the logic for free, and then point it at a real account by changing the endpoint and credentials. Before any real apply I read the plan, set a budget alarm and scan the code. It avoids surprise bills and mistakes in a real account.

### Policy as code

**If asked:** What is policy as code?

> Security and compliance rules written as automated checks on infrastructure code, for example with Checkov or OPA. They flag things like public buckets, missing encryption or open security groups before anything is deployed. Running them in CI makes security consistent and shifts it left, instead of relying on manual review.

## Module 18 · Linux administration

### Your practice server

**If asked:** How do you practise Linux administration safely?

> I use a disposable Linux server running in a container, so I can create users, change permissions, kill processes and break services without any risk, then rebuild it in seconds. Practising on a throwaway machine builds real muscle memory for the commands I would use on a production server.

### Who may do what to a file

**If asked:** Explain Linux file permissions.

> Each file has an owner, a group and others, with read, write and execute bits for each, shown as rwx. In octal, read is 4, write is 2 and execute is 1, so chmod 640 means the owner can read and write, the group can read, and others get nothing. I follow least privilege, for example private keys must be 600, and I use chown to set ownership.

### Processes and signals

**If asked:** How do you stop a misbehaving process?

> I find it with ps or top, then send a signal with kill. SIGTERM asks it to shut down cleanly and is my first choice. SIGKILL cannot be ignored and is the last resort, because the program cannot clean up. For services I prefer systemctl stop or restart, and then I check the logs to see why it misbehaved.

### The USE method

**If asked:** A server is slow. How do you investigate?

> I use the USE method: for CPU, memory, disk and network I check Utilisation, Saturation and Errors in order. For example top or uptime for load, free for memory, and iostat and df for disk. That gives me a structured way to find the bottleneck instead of guessing, and then I look at the process responsible.

### Logs and cron

**If asked:** How do you read logs and schedule jobs on Linux?

> I use tail -f to follow a log, grep to search it, and journalctl for systemd services. For scheduled jobs I use cron with the five-field schedule, and I make sure jobs log their output and use full paths, because cron has a minimal environment. Modern setups sometimes use systemd timers instead.

### systemd units

**If asked:** What is systemd, and how do you manage a service?

> systemd starts and supervises services on most Linux servers. A unit file defines the command, the user, the restart policy and the dependencies. I use systemctl start, stop, status and enable for boot, and journalctl -u to read the logs. Restart=on-failure gives basic self-healing for a crashed process.

### SSH keys and sudo

**If asked:** How do you secure SSH access?

> I use key pairs instead of passwords: the private key stays with me with strict permissions and the public key goes on the server. I disable password login and root login, use sudo for admin tasks so actions are attributable, and restrict access with firewalls or a bastion. Keys are rotated and removed when people leave.

## Module 19 · Git collaboration

### Your practice repo

**If asked:** How do you practise risky Git operations safely?

> I use a throwaway repository, so I can try conflicts, rebases, resets and bisects without risking real work. Because everything is recorded in the reflog, I can also recover from my own mistakes, which builds confidence before I do the same on a shared repository.

### Branches and pull requests

**If asked:** Describe your pull request workflow.

> I create a branch from main, make small focused commits, push it and open a pull request. CI runs tests and scans, a teammate reviews, I address the feedback, and then it is merged, often with a squash. Branch protection on main requires passing checks and an approval, so nothing unreviewed or broken reaches it.

### Merge conflicts

**If asked:** How do you resolve a merge conflict?

> A conflict happens when two branches changed the same lines. Git marks the file with conflict markers; I open it, decide what the final content should be, remove the markers, stage the file and continue the merge or rebase. I run the tests afterwards, and for tricky conflicts I talk to the author of the other change.

### Merge versus rebase

**If asked:** What is the difference between merge and rebase?

> Merge keeps the true history and adds a merge commit. Rebase replays my commits on top of the new base, which gives a straight, clean history but new commit IDs. So I rebase only my own unshared branches to tidy them, and I never rebase commits others already use, because rewriting shared history causes problems.

### Stash, cherry-pick, reflog

**If asked:** What are stash, cherry-pick and reflog for?

> git stash parks unfinished work so I can switch branches. cherry-pick copies one specific commit onto another branch, which is handy for hotfixes. reflog records where HEAD has been, so even after a bad reset or a deleted branch I can find the old commit and recover it. Together they make me comfortable fixing mistakes.

### git bisect

**If asked:** How do you find which commit introduced a bug?

> I use git bisect. I mark a known bad commit and a known good one, and Git checks out the middle commit; I test it and tell Git good or bad, and it halves the range each time. With a few hundred commits I find the culprit in about eight steps, and I can automate it with a test script.

### How to review a pull request

**If asked:** How do you review a pull request?

> I check that it does what the description says, that it is small and understandable, has tests, handles errors and security concerns like secrets or input validation, and fits the existing design. I give specific, kind, actionable comments, separate must-fix items from suggestions, and approve when I would be comfortable owning that code.

## Module 20 · Secrets management

### Why a secret manager?

**If asked:** Why use a secrets manager instead of environment files?

> A .env file is plain text that is easy to copy and commit. A secret manager like HashiCorp Vault stores secrets centrally and encrypted, with access control, audit logs, rotation and short-lived credentials. Applications authenticate and fetch only what they need at runtime, so secrets are never in Git, images or CI logs.

### The key-value engine

**If asked:** How does Vault store secrets?

> The key-value secrets engine stores secrets at paths, such as secret/devlab/api, with versioning, so I can read an earlier version or see what changed. Access is controlled by path through policies. I write and read secrets with the CLI or the API, and the data is encrypted at rest.

### Policies and tokens

**If asked:** How do you control access in Vault?

> With policies that list paths and allowed capabilities, like read or create, attached to tokens or auth methods. I follow least privilege: each application gets a policy for only its own path and a short-lived token. Revoking the token cuts access immediately, and the audit log shows who read what.

### Inject secrets at deploy time

**If asked:** How do secrets get from a secret manager into a running app?

> At deploy or start time the platform authenticates, fetches the secret and injects it as an environment variable or a file in memory, using an agent, an init step or the CSI driver. The secret never lives in Git, in the image or in a file in the repo, and rotating it does not need a rebuild.

### Secrets in Kubernetes

**If asked:** Are Kubernetes Secrets secure?

> By default a Secret is only base64-encoded, not encrypted, so anyone who can read it, or read etcd, can decode it. I restrict access with RBAC, enable encryption at rest, and prefer an external secret manager synced into the cluster. And I never commit secret manifests to Git unencrypted.

## Module 21 · Kubernetes advanced

### Two add-ons

**If asked:** What do metrics-server and an ingress controller do?

> metrics-server collects CPU and memory usage from nodes and pods, and it is what kubectl top and the Horizontal Pod Autoscaler use. An ingress controller, such as Traefik or nginx, is the program that reads Ingress rules and routes outside HTTP traffic to the right service. Without either of them, autoscaling and external routing do not work.

### Batch work

**If asked:** How do you run batch or scheduled work in Kubernetes?

> A Job runs a pod until it completes successfully, with retries controlled by backoffLimit. A CronJob creates Jobs on a cron schedule. I use them for backups, reports and cleanups, and I make them idempotent because a job can run twice. A Deployment is for things that should run forever.

### ConfigMaps and Secrets

**If asked:** How do you configure apps in Kubernetes?

> I keep configuration out of the image: a ConfigMap holds non-secret settings and a Secret holds sensitive values, injected as environment variables or mounted files. That way the same image runs in every environment with different config. Secrets still need protection with RBAC and ideally an external secret store.

### Requests and limits

**If asked:** What are resource requests and limits?

> A request is what the scheduler reserves for a container; a limit is the most it may use. If a container exceeds its memory limit it is killed with OOMKilled, exit code 137, while exceeding the CPU limit just throttles it. I set both from measured usage, so pods are placed sensibly and one greedy app cannot starve the others.

### Horizontal Pod Autoscaler

**If asked:** How does the Horizontal Pod Autoscaler work?

> It reads metrics from metrics-server, such as average CPU, compares them with a target and changes the replica count between a minimum and a maximum. It needs resource requests to be set, and a stabilisation window prevents flapping. It scales pods; to scale nodes I would also need a cluster autoscaler.

### Ingress

**If asked:** What is the difference between a Service and an Ingress?

> A Service gives pods a stable address inside the cluster and load balances between them. An Ingress is a set of HTTP routing rules at the edge, by host name and path, that an ingress controller implements, typically with TLS. So one entry point can route to many services.

### Read the status, then the events

**If asked:** A pod is not running. How do you troubleshoot?

> I read its status and then its events. ImagePullBackOff means the image cannot be fetched, so I check the name, tag and credentials. CrashLoopBackOff means it keeps crashing, so I read kubectl logs and the previous logs. Pending means it cannot be scheduled, so I describe the pod and look for FailedScheduling. OOMKilled means it exceeded its memory. kubectl describe is my first move.

### Steering the scheduler

**If asked:** How do taints, tolerations and affinity differ?

> A taint on a node repels pods; only pods with a matching toleration may run there, which keeps general workloads off special nodes like GPU nodes. Node affinity attracts a pod to nodes by label, either required, a must, or preferred, a wish. A toleration allows but does not attract, so I often combine a taint with affinity.

## Module 22 · Ship it for real

### CI on GitHub

**If asked:** Tell me about a CI/CD pipeline you built.

> In my project every push and pull request runs on GitHub Actions: tests, a dependency audit, secret and Dockerfile scanning, an image build and a vulnerability scan. Actions are pinned to commit SHAs and permissions are minimal. The status badge is on the README, so anyone can see the pipeline is green. It is a small project, but it shows the real workflow end to end.

### A real failure, and what it teaches

**If asked:** Tell me about a time a pipeline broke.

> In my project the pipeline failed because the tag of a third-party scanning action I used no longer existed. I found it in the job logs, replaced it by running the scanner from a pinned container image, and pinned the rest of the actions too. The lesson was that external dependencies in a pipeline are a risk and should be pinned and monitored.

### Dependabot and a status badge

**If asked:** How do you keep dependencies up to date?

> I use Dependabot, which opens pull requests for new versions of npm packages, GitHub Actions and Docker images. The pipeline tests each one, so I can review and merge small updates regularly instead of facing a big risky upgrade later. A status badge on the README shows the current health of the pipeline.

### Protect main

**If asked:** How do you protect the main branch?

> With branch protection rules: require a pull request, require status checks to pass, require at least one review, and block force pushes. That means nothing reaches main without tests and review, and mistakes are caught before release.

### From a pipeline to a server

**If asked:** How does a change get from a pipeline to production?

> The pipeline builds a versioned image and pushes it to a registry on a release tag. A deployment step, ideally GitOps, updates the environment to that version after approval, with health checks and an easy rollback to the previous version. I keep the infrastructure in Terraform, and I always set budgets and least-privilege access for a cloud account.

### Turn this into evidence

**If asked:** Walk me through a project you have built.

> I built a small web service, a Node API behind nginx, and operated it end to end: containers, Compose, CI with scanning, Terraform, Kubernetes with probes and autoscaling, GitOps, monitoring with SLO alerts, and incident drills with postmortems. It is a lab, not production, but everything is public in my repository with a green pipeline, so you can see how I work.

## Module 23 · Interview prep

### The usual stages

**If asked:** What happens in a typical DevOps interview process?

> Usually a recruiter or HR screen about my background and motivation, then a technical screen on fundamentals like Linux, networking, containers and CI/CD, a hands-on or troubleshooting round, a system design or architecture discussion, and a behavioural round with the hiring manager. I prepare for each with real examples from my projects.

### How to answer

**If asked:** How do you answer a technical question when you only partly know the answer?

> I think aloud: what I know, what I would check first and how I would confirm it. I give the answer first, then the reasoning and an example from my practice. If I truly do not know, I say so honestly and explain how I would find out, which is better than bluffing.

### Design questions

**If asked:** How do you approach a design question?

> I clarify the requirements and the scale first, then sketch the simplest design that works, identify the bottlenecks and add components like caching, queues or replicas, with a reason for each. I state the trade-offs and failure modes, and I think about cost and security. A clear structure matters more than a perfect diagram.

### The STAR method

**If asked:** How do you answer behavioural questions?

> I use STAR: the Situation in one sentence, the Task I owned, the Action I took, which is the longest part, and the Result with a number or a lesson. I keep it under two minutes, say I rather than we for my own contribution, and choose real examples, including ones where something went wrong.

## Module 24 · System design

### Five steps, every time

**If asked:** How do you approach a system design question?

> Five steps: clarify the requirements and the scale, estimate numbers like requests per second, sketch the simplest design, scale the bottlenecks with the right building blocks, then discuss trade-offs and failure. For example, a million users doing ten requests a day is about a hundred requests per second on average, so I plan for several times that at peak.

### Keep answers close

**If asked:** How does caching work, and what are the pitfalls?

> A cache keeps the results of slow work in fast memory. With cache-aside I check the cache first, and on a miss I read the database and store the result with a TTL. The hard part is invalidation, since cached data can go stale, so I use sensible TTLs and invalidate on writes. I also handle eviction, usually least recently used, and cache stampedes.

### Do slow work later

**If asked:** Why use a message queue?

> A queue decouples producers from consumers. A web request adds a job and returns at once, and workers process it later at their own pace, which absorbs spikes, enables retries and lets me scale workers separately. Delivery is usually at least once, so jobs must be idempotent, and failed jobs go to a dead-letter queue.

### Say no before the system falls over

**If asked:** How would you implement rate limiting?

> I count requests per client per time window in a shared store like Redis, using an atomic increment with an expiry, and return HTTP 429 with a Retry-After header when over the limit. The algorithms are fixed window, sliding window and token bucket, which allows bursts. The counter must be shared, because per-server counters multiply the real limit.

### Spread the work, move the content closer

**If asked:** How do load balancing and a CDN help scalability?

> A load balancer spreads requests over many stateless servers and removes unhealthy ones, which gives scale and availability. A CDN caches static content at edge locations near users, so most requests never reach my origin and latency drops. Together they handle traffic growth, and I keep personalised content out of the shared cache.

### Split the data

**If asked:** What is sharding, and how do you choose a shard key?

> Sharding splits data across several database servers by a shard key. A good key spreads data and load evenly and keeps related rows together, like user ID, while a bad key such as a timestamp creates a hot shard. Hash modulo N moves most keys when I add a shard, so I use consistent hashing, which moves only about one over N.

### Fail fast when a dependency is down

**If asked:** What is a circuit breaker?

> A pattern that protects a service from a failing dependency. When failures pass a threshold the breaker opens, and calls fail immediately instead of waiting for timeouts, which prevents cascading failure. After a cooldown it goes half-open and allows a trial call; success closes it and failure opens it again. I combine it with timeouts and retries with backoff and jitter.

### Design a URL shortener

**If asked:** Design a URL shortener.

> Reads far outnumber writes, so I put a load balancer in front of stateless app servers, store the code-to-URL mappings in a database sharded by code with read replicas, and cache hot codes in Redis. A CDN serves popular links. I rate-limit link creation, send click analytics through a queue so redirects never wait, and add timeouts and a circuit breaker around external calls.
