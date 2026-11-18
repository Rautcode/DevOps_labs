# Networking: DNS, ports, TLS and load balancing (about 2h)
title "Module 12 · Networking"
mission "Users say the site cannot be reached, but the servers look fine. Most outages like this are network problems. Your mission: learn to tell names (DNS), doors (ports), locks (TLS) and traffic police (load balancers) apart, and find the broken one fast."
explain "Most 'mysterious' outages are network problems: a name that does not resolve, a port that is taken, a certificate that expired, a server that is down behind a load balancer. You will see each one with your own eyes."

part "PART A · DNS: how a name becomes an address"
learn "DNS: names to addresses" "Computers connect by IP address, but people and programs use names. DNS translates one into the other. Inside Docker, a built-in DNS server (127.0.0.11) knows every container by name, which is why the web server can find the API simply as api even though its IP changes."
art "DNS lookup" <<'ART'
   browser: "where is example.com?"
        |
        v
   [ DNS resolver ] ---> "93.184.x.x"
        |
        v
   browser connects to that IP address, then the port
ART
step "Make sure the practice app is running" '{"ok":true}' ok '"ok":true' <<'CMD'
dc up -d 2>&1 | tail -1; sleep 12; curl -s localhost:8080/healthz
CMD
step "Which DNS server do containers use?" "nameserver 127.0.0.11. That is Docker's built-in DNS. It maps container names (like 'api') to their private IP addresses." ok '127.0.0.11' <<'CMD'
docker exec devlab-web-1 cat /etc/resolv.conf
CMD
step "Ask DNS: what is the address of 'api'?" "A private IP such as 172.x.x.x. This is how the web server finds the API without a fixed IP." ok 'Address' <<'CMD'
docker exec devlab-web-1 nslookup api
CMD
step "Ask a PUBLIC name (needs internet)" "One or more public IP addresses for github.com." ok 'Address' <<'CMD'
docker run --rm busybox nslookup github.com 2>&1 | tail -6
CMD
task "Find the API's IP address with DNS and save it" "Run nslookup for 'api' from inside the web container and save ONLY the IP address into the file playground/api-ip.txt. Hint: docker exec devlab-web-1 nslookup api   (take the last Address line)." "The file must contain just the IP, for example 172.19.0.2. It must equal the API container's real IP." <<'X'
[ -s playground/api-ip.txt ] && [ "$(tr -d '[:space:]' < playground/api-ip.txt)" = "$(dc ps -q api | head -1 | xargs docker inspect --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}')" ]
---
docker exec devlab-web-1 nslookup api | grep -E '^Address' | tail -1 | awk '{print $NF}' > playground/api-ip.txt
X
quiz "Why do containers use names like 'api' instead of IP addresses?" "change|dynamic|restart|new ip|name|dns|stable" "Container IPs change every time a container is recreated. Names are stable and DNS finds the current IP."

part "PART B · Ports and TCP: how a connection is made"
learn "IP addresses and subnets (CIDR)" "An IPv4 address has four numbers (0-255), such as 10.0.1.25. A network is written in CIDR form, 10.0.1.0/24: the number after the slash says how many of the 32 bits are fixed for the network, and the rest are free for hosts. A /24 leaves 8 free bits, so 2 to the power 8 = 256 addresses (254 usable). A /16 has 65,536. Bigger slash number means a SMALLER network. Cloud networks (VPCs) and Kubernetes pods are carved out of private ranges: 10.0.0.0/8, 172.16.0.0/12 and 192.168.0.0/16."
art "Reading 10.0.1.0/24" <<'ART'
   10 . 0 . 1 . 25      /24  = first 24 bits are the NETWORK
   |______________|   |____|
     fixed (network)   last 8 bits = HOST: 256 addresses
   /16 -> 65,536 addresses     /28 -> 16 addresses     /32 -> exactly one
ART
mcq "How many addresses are in 10.0.0.0/24?" "24|256|255|65536" 2 "32 - 24 = 8 free bits, and 2 to the power 8 = 256 (two are reserved, so 254 are usable)."
mcq "Which of these is a PRIVATE address (not reachable from the internet)?" "8.8.8.8|172.15.0.1|172.20.4.9|93.184.216.34" 3 "The private 172 range is 172.16.0.0 to 172.31.255.255, so 172.20.4.9 is private and 172.15.0.1 is not."
learn "Ports and TCP" "An IP address finds a machine and a port finds a program on it. A server LISTENS on a port; a client CONNECTS to it. Only one program can own a port, so two servers on one machine need different ports or a reverse proxy in front."
step "What is the web server listening on?" "0.0.0.0:8080 in LISTEN state. A port is like a door number on one machine." ok '8080' <<'CMD'
docker exec devlab-web-1 netstat -tln
CMD
step "Watch a connection happen (verbose curl)" "'Connected to localhost' (TCP), then 'HTTP/1.1 200 OK'. First the connection (TCP), then the request (HTTP)." ok 'Connected to' <<'CMD'
curl -sv localhost:8080/healthz 2>&1 | grep -E "Connected to|HTTP/1.1 200"
CMD
step "Where does the time go? DNS, connect, total" "Three small numbers. When something is slow, this tells you if it is DNS, the network, or the app." ok 'connect=' <<'CMD'
curl -s -w '\ndns=%{time_namelookup}s connect=%{time_connect}s total=%{time_total}s\n' localhost:8080/healthz | tail -1
CMD
step "Try to start a second server on the SAME port" "'port is already allocated'. Only one program can own a port. It FAILS on purpose." fail 'already allocated|address already in use|port is already' <<'CMD'
docker run --rm -p 8080:80 nginx:alpine 2>&1 | tail -2; exit ${PIPESTATUS[0]}
CMD
quiz "Two servers must both be reachable from outside. How can they share one machine?" "port|different|proxy|host|virtual|name" "Give them different ports, or put a reverse proxy (like our nginx) in front that routes by path or host name."

part "PART C · TLS: encrypted connections (HTTPS)"
explain "HTTPS = HTTP inside TLS. The server proves who it is with a certificate. Real sites get certificates from a trusted authority. Here you make your own, so browsers do not trust it, and you will see exactly why."
learn "TLS and certificates" "TLS encrypts a connection and a certificate proves who the server is. A trusted authority signs real certificates; a self-signed one is signed by nobody, so clients warn about it. Certificates expire, and an expired certificate is one of the most common outages."
art "TLS handshake (short)" <<'ART'
   client                                  server
     | -- hello, here are my ciphers --->    |
     | <-- certificate (proves identity) --- |
     |     check: trusted CA? name matches? not expired?
     | == encrypted traffic from here on ==   |
ART
mcq "Which of these makes a certificate fail?" "Expired date or wrong name|Too many visitors|Using port 443|Having a .com address" 1 "Browsers reject a certificate that is expired, for a different name, or signed by an unknown authority."
step "Create a self-signed certificate (valid 7 days)" "cert.pem and key.pem appear in playground/tls." ok 'cert.pem' <<'CMD'
mkdir -p playground/tls; docker run --rm -v "$PWD/playground/tls:/out" alpine/openssl req -x509 -newkey rsa:2048 -nodes -keyout /out/key.pem -out /out/cert.pem -days 7 -subj "/CN=localhost" -addext "subjectAltName=DNS:localhost" >/dev/null 2>&1; ls playground/tls
CMD
step "Read the certificate" "subject=CN = localhost and a notBefore / notAfter date. Certificates EXPIRE. Expired certificates are a very common outage." ok 'notAfter' <<'CMD'
docker run --rm -v "$PWD/playground/tls:/out" alpine/openssl x509 -in /out/cert.pem -noout -subject -dates
CMD
step "Start nginx serving HTTPS on port 8443" "A container id is printed." ok '[0-9a-f]{12}' <<'CMD'
docker rm -f lab-tls >/dev/null 2>&1; docker run -d --name lab-tls -p 8443:443 -v "$PWD/12-networking/tls.conf:/etc/nginx/conf.d/default.conf:ro" -v "$PWD/playground/tls:/certs:ro" nginx:alpine; sleep 3
CMD
step "Call it WITHOUT trusting the certificate" "curl refuses: 'self-signed certificate' (exit 60). It does not trust a certificate that no known authority signed. This is the browser warning you have seen." fail 'self-signed|unable to get local issuer|certificate' <<'CMD'
curl -sS https://localhost:8443 2>&1 | tail -2; exit ${PIPESTATUS[0]}
CMD
step "Call it and TRUST that one certificate (--cacert)" "secure hello over TLS. The encrypted connection works once the client trusts the certificate." ok 'secure hello' <<'CMD'
curl -s --cacert playground/tls/cert.pem https://localhost:8443
CMD
step "Which TLS version was negotiated?" "TLSv1.3 (or 1.2). The server only allows modern versions." ok 'TLSv1\.[23]' <<'CMD'
docker run --rm --add-host=host.docker.internal:host-gateway alpine/openssl s_client -connect host.docker.internal:8443 -brief </dev/null 2>&1 | grep -E "Protocol|TLSv1" | head -2
CMD
step "Clean up the TLS server" "removed" ok 'lab-tls' <<'CMD'
docker rm -f lab-tls
CMD
quiz "Why does a browser show a warning for a self-signed certificate?" "trust|authority|ca|sign|verify|known|who" "Nobody the browser trusts vouched for it. Anyone can create a self-signed certificate, so it proves nothing about who you are talking to."

part "PART D · Load balancing and failover"
explain "A load balancer spreads requests over several copies of a service and stops sending to a dead one. You will build a tiny one with two backends."
learn "Load balancing and failover" "A load balancer spreads requests over several copies of a service (round-robin means taking turns) and stops sending traffic to a dead copy. That gives you both scale and availability. A gotcha you will meet: without a shared memory zone, each nginx worker keeps its own turn counter."
art "Load balancer" <<'ART'
                   +--> [ server A ]
   users --> [ LB ] -+
                   +--> [ server B ]      A dies -> LB sends everything to B
ART
step "Start two backends and a load balancer" "Three containers started: lab-a, lab-b and the balancer on port 8090." ok 'lab-lb' <<'CMD'
docker rm -f lab-a lab-b lab-lb >/dev/null 2>&1; docker network rm lab-net >/dev/null 2>&1; docker network create lab-net >/dev/null; docker run -d --name lab-a --network lab-net traefik/whoami >/dev/null; docker run -d --name lab-b --network lab-net traefik/whoami >/dev/null; sleep 2; docker run -d --name lab-lb --network lab-net -p 8090:80 -v "$PWD/12-networking/lb.conf:/etc/nginx/conf.d/default.conf:ro" nginx:alpine >/dev/null && echo "started lab-a lab-b lab-lb"; sleep 3
CMD
step "Send 6 requests: who answered?" "Two different hostnames, taking turns (round-robin)." ok 'backends answering: 2' <<'CMD'
for i in 1 2 3 4 5 6; do curl -s localhost:8090 | grep Hostname; done | sort | uniq -c | awk '{print} END {print "backends answering: " NR}'
CMD
task "Kill one backend and prove the site still works" "Stop the backend lab-a:  docker stop lab-a   Then call the balancer again:  curl localhost:8090  It must still answer, now only from lab-b. That is failover." "The check passes when lab-a is stopped AND the balancer still answers." <<'X'
[ "$(docker inspect -f '{{.State.Running}}' lab-a)" = "false" ] && curl -s localhost:8090 | grep -q Hostname
---
docker stop lab-a >/dev/null
X
step "Send 6 requests again" "Only ONE backend now answers, but no request failed. Users never noticed the failure." ok 'backends answering: 1' <<'CMD'
for i in 1 2 3 4 5 6; do curl -s localhost:8090 | grep Hostname; done | sort | uniq -c | awk '{print} END {print "backends answering: " NR}'
CMD
step "Clean up" "Containers and network removed." ok 'lab-net' <<'CMD'
docker rm -f lab-a lab-b lab-lb >/dev/null; docker network rm lab-net
CMD
quiz "What two things does a load balancer give you?" "scale|spread|distribut|failover|availab|resilien|redundan|health|more than one" "Scaling (spread load over many copies) and availability (stop sending traffic to a failed copy, so one failure does not take the site down)."

deeper "A to Z of networking (Abhishek Veeramalla)|https://github.com/iam-veeramalla/a-to-z-of-networking"
explain "Done! Next: bash lab.sh 13"
