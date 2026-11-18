# 12 · Networking (Specialist, ~2h)

> **Guided version:** run `bash lab.sh 12` from the repo root. It explains each step, has you type the commands yourself, and checks your hands-on tasks. This page is the reference.

**Goal:** understand the four things behind most "mysterious" outages: DNS, ports, TLS certificates and load balancing.

| File | What it is |
|---|---|
| [tls.conf](tls.conf) | nginx config that serves HTTPS with a certificate (TLS termination) |
| [lb.conf](lb.conf) | nginx load balancer: round-robin over two backends with failover |

## What you do
| Part | You see |
|---|---|
| DNS | containers find each other through Docker's DNS (`127.0.0.11`); `nslookup api` returns a private IP |
| Ports and TCP | `netstat` shows what listens; `curl -v` shows connect, then HTTP; a second server on the same port fails |
| TLS | you create a self-signed certificate, serve HTTPS, see curl reject it, then trust that one certificate and read the negotiated version (TLS 1.3) |
| Load balancing | two backends behind nginx answer in turn; stop one and nobody notices |

## Firewalls, bastion tunnels and CDN (parts E, F, G of the guided lab)
**Firewall.** Rules decide which traffic passes; deny by default, allow what is needed. A dropped packet gets no answer at all, so the client times out.
```bash
docker network create lab-fw-net
docker run -d --name lab-fw --network lab-fw-net --cap-add NET_ADMIN nginx:alpine
docker exec lab-fw apk add --no-cache iptables iptables-legacy
docker exec lab-fw iptables-legacy -A INPUT -p tcp --dport 80 -j DROP     # block port 80
docker run --rm --network lab-fw-net curlimages/curl -s -m 3 lab-fw       # hangs, then times out
docker exec lab-fw iptables-legacy -D INPUT -p tcp --dport 80 -j DROP     # unblock
```
In the cloud the same job is done by **security groups** (stateful, per instance) and **network ACLs** (per subnet).

**Bastion / tunnel / VPN.** Private services have no public address. A *bastion* sits on the public and the private network and forwards one port (this is `ssh -L` or AWS Systems Manager port forwarding); a *VPN* wraps all traffic to a private network in an encrypted tunnel. The guided lab builds a bastion from `alpine/socat` and two Docker networks (one `--internal`).

**CDN.** An edge cache serves repeat requests from its own copy for the TTL and asks the origin only on a miss. [cdn.conf](cdn.conf) is an nginx `proxy_cache` edge; the header `X-Cache-Status` shows `MISS`, then `HIT`.

## Concepts
- **DNS** turns names into addresses. In containers and Kubernetes, names are stable while IPs change.
- **A port** is a numbered door on one machine; only one program can own it.
- **TLS** encrypts the connection and proves identity with a certificate. Certificates **expire**; expired certificates are a classic outage.
- **Load balancing** gives scale and availability. Gotcha found while building this lab: nginx runs several worker processes, and without `zone` in the `upstream` block each worker round-robins on its own, so requests do not alternate evenly.

## Break it
1. Remove `zone backend 64k;` from `lb.conf`, restart the balancer and count which backend answers. Why is it uneven?
2. Create a certificate with `-days 0` or a wrong `CN` and see how curl complains.
3. Stop **both** backends: what status code does the balancer return (502)?

## Industry notes
- Use real certificates from a public authority (Let's Encrypt) and **monitor expiry** (module 08: `probe_ssl_earliest_cert_expiry`).
- Health-check backends actively in production (nginx Plus, HAProxy, cloud load balancers), not only on failed requests.
- `dig`, `curl -v`, `ss`/`netstat` and `openssl s_client` are the first four tools to reach for.

**Next:** [13 · Ansible](../13-ansible/README.md)
