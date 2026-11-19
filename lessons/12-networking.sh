# Networking: DNS, ports, TLS and load balancing (about 2h)
title "Module 12 · Networking"
mission "Users say the site cannot be reached, but the servers look fine. Most outages like this are network problems. Your mission: learn to tell names (DNS), doors (ports), locks (TLS) and traffic police (load balancers) apart, and find the broken one fast."
explain "Most 'mysterious' outages are network problems: a name that does not resolve, a port that is taken, a certificate that expired, a server that is down behind a load balancer. You will see each one with your own eyes."

part "PART A · DNS: how a name becomes an address"
learn "DNS: names to addresses" "Computers connect by IP address, but people and programs use names. DNS translates one into the other. Inside Docker, a built-in DNS server (127.0.0.11) knows every container by name, which is why the web server can find the API simply as api even though its IP changes."
say "What happens when you type a URL into a browser?" "The browser checks its cache, then asks a DNS resolver to turn the name into an IP address. It opens a TCP connection to that address and port, does a TLS handshake for HTTPS, sends the HTTP request, and the server responds. Each step can fail differently, so I troubleshoot in that order: DNS, connection, TLS, then HTTP."
art "DNS lookup" <<'ART'
   browser: "where is example.com?"
        |
        v
   [ DNS resolver ] ---> "93.184.x.x"
        |
        v
   browser connects to that IP address, then the port
ART
why "dc up -d::start the stack|curl /healthz::check it" "The networking experiments use the running app, so we start it first."
step "Make sure the practice app is running" '{"ok":true}' ok '"ok":true' <<'CMD'
dc up -d 2>&1 | tail -1; sleep 12; curl -s localhost:8080/healthz
CMD
why "cat /etc/resolv.conf::the file that lists the DNS server a machine asks" "Every machine knows where to send name questions. Inside Docker it is a built-in server at 127.0.0.11, which answers for container names."
step "Which DNS server do containers use?" "nameserver 127.0.0.11. That is Docker's built-in DNS. It maps container names (like 'api') to their private IP addresses." ok '127.0.0.11' <<'CMD'
docker exec devlab-web-1 cat /etc/resolv.conf
CMD
why "nslookup api::ask the DNS server for the address of the name api" "Containers find each other by name, and DNS turns the name into an IP address. If a service cannot reach another, a failing lookup is the first suspect."
step "Ask DNS: what is the address of 'api'?" "A private IP such as 172.x.x.x. This is how the web server finds the API without a fixed IP." ok 'Address' <<'CMD'
docker exec devlab-web-1 nslookup api
CMD
why "nslookup github.com::ask for the address of a name on the internet|busybox::a tiny image that has the tool" "The same question about a public name goes through your resolver to the wider internet. You should get one or more IP addresses back."
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
say "What does 10.0.1.0/24 mean?" "It is CIDR notation. The first 24 bits identify the network and the remaining 8 bits are for hosts, so there are 256 addresses, 254 of them usable. A bigger slash number means a smaller network. Cloud networks are carved from private ranges like 10.0.0.0/8, 172.16.0.0/12 and 192.168.0.0/16, and I plan subnets so they do not overlap."
art "Reading 10.0.1.0/24" <<'ART'
   10 . 0 . 1 . 25      /24  = first 24 bits are the NETWORK
   |______________|   |____|
     fixed (network)   last 8 bits = HOST: 256 addresses
   /16 -> 65,536 addresses     /28 -> 16 addresses     /32 -> exactly one
ART
mcq "How many addresses are in 10.0.0.0/24?" "24|256|255|65536" 2 "32 - 24 = 8 free bits, and 2 to the power 8 = 256 (two are reserved, so 254 are usable)."
mcq "Which of these is a PRIVATE address (not reachable from the internet)?" "8.8.8.8|172.15.0.1|172.20.4.9|93.184.216.34" 3 "The private 172 range is 172.16.0.0 to 172.31.255.255, so 172.20.4.9 is private and 172.15.0.1 is not."
learn "Ports and TCP" "An IP address finds a machine and a port finds a program on it. A server LISTENS on a port; a client CONNECTS to it. Only one program can own a port, so two servers on one machine need different ports or a reverse proxy in front."
say "What is the difference between an IP address and a port?" "An IP address finds the machine and a port finds the program on it. A server listens on a port and a client opens a TCP connection to it. Two programs cannot listen on the same port, which causes the classic port already allocated error. I use tools like ss or curl to see what is listening and whether a connection succeeds."
art "Address plus port" <<'ART'
   client 10.0.0.5:51234  ------>  server 10.0.0.9:443
          (random port)            |-- :22  ssh
                                   |-- :80  http
                                   `-- :443 https   (a program listens on each)
   one port, one program: a second listener fails with "port already allocated"
ART
why "netstat -tln::list TCP ports that are listening" "A server has to listen on a port before anyone can connect. This shows which doors are open on the web container, such as port 8080."
step "What is the web server listening on?" "0.0.0.0:8080 in LISTEN state. A port is like a door number on one machine." ok '8080' <<'CMD'
docker exec devlab-web-1 netstat -tln
CMD
why "curl -v::verbose, show every step|grep -E::keep the lines Connected and HTTP 200" "Verbose mode shows the connection being made and then the answer. It is the best way to see where a request stops: before, during or after connecting."
step "Watch a connection happen (verbose curl)" "'Connected to localhost' (TCP), then 'HTTP/1.1 200 OK'. First the connection (TCP), then the request (HTTP)." ok 'Connected to' <<'CMD'
curl -sv localhost:8080/healthz 2>&1 | grep -E "Connected to|HTTP/1.1 200"
CMD
why "-w::print a custom report|time_namelookup, time_connect, time_total::the time of each phase" "A slow request can be slow in DNS, in connecting or in the app. Splitting the time tells you which layer to investigate."
step "Where does the time go? DNS, connect, total" "Three small numbers. When something is slow, this tells you if it is DNS, the network, or the app." ok 'connect=' <<'CMD'
curl -s -w '\ndns=%{time_namelookup}s connect=%{time_connect}s total=%{time_total}s\n' localhost:8080/healthz | tail -1
CMD
why "docker run -p 8080:80::try to take port 8080 which is already used" "This fails on purpose with port is already allocated. Only one program can own a port. It is a very common error, and now you will recognise it."
step "Try to start a second server on the SAME port" "'port is already allocated'. Only one program can own a port. It FAILS on purpose." fail 'already allocated|address already in use|port is already' <<'CMD'
docker run --rm -p 8080:80 nginx:alpine 2>&1 | tail -2; exit ${PIPESTATUS[0]}
CMD
quiz "Two servers must both be reachable from outside. How can they share one machine?" "port|different|proxy|host|virtual|name" "Give them different ports, or put a reverse proxy (like our nginx) in front that routes by path or host name."

part "PART C · TLS: encrypted connections (HTTPS)"
explain "HTTPS = HTTP inside TLS. The server proves who it is with a certificate. Real sites get certificates from a trusted authority. Here you make your own, so browsers do not trust it, and you will see exactly why."
learn "TLS and certificates" "TLS encrypts a connection and a certificate proves who the server is. A trusted authority signs real certificates; a self-signed one is signed by nobody, so clients warn about it. Certificates expire, and an expired certificate is one of the most common outages."
say "How does TLS work?" "TLS encrypts the connection and authenticates the server. The server presents a certificate signed by a trusted certificate authority, the client checks that it is valid, not expired and issued for that name, and then they agree on keys for encryption. Expired or mismatched certificates are a common cause of outages, so I monitor expiry and automate renewal."
art "TLS handshake (short)" <<'ART'
   client                                  server
     | -- hello, here are my ciphers --->    |
     | <-- certificate (proves identity) --- |
     |     check: trusted CA? name matches? not expired?
     | == encrypted traffic from here on ==   |
ART
mcq "Which of these makes a certificate fail?" "Expired date or wrong name|Too many visitors|Using port 443|Having a .com address" 1 "Browsers reject a certificate that is expired, for a different name, or signed by an unknown authority."
why "openssl req -x509::make a certificate signed by itself|-newkey rsa:2048::a new 2048-bit key|-days 7::valid for 7 days|-subj /CN=localhost::the name it is for" "A certificate proves who a server is. Real ones are signed by a trusted authority. A self-signed one is fine for practice, but browsers will not trust it by default."
step "Create a self-signed certificate (valid 7 days)" "cert.pem and key.pem appear in playground/tls." ok 'cert.pem' <<'CMD'
mkdir -p playground/tls; docker run --rm -v "$PWD/playground/tls:/out" alpine/openssl req -x509 -newkey rsa:2048 -nodes -keyout /out/key.pem -out /out/cert.pem -days 7 -subj "/CN=localhost" -addext "subjectAltName=DNS:localhost" >/dev/null 2>&1; ls playground/tls
CMD
why "openssl x509 -noout::print the certificate details|-subject -dates::who it is for and when it is valid" "Reading a certificate shows the name it protects and its start and end dates. Expired certificates are a very common cause of outages."
step "Read the certificate" "subject=CN = localhost and a notBefore / notAfter date. Certificates EXPIRE. Expired certificates are a very common outage." ok 'notAfter' <<'CMD'
docker run --rm -v "$PWD/playground/tls:/out" alpine/openssl x509 -in /out/cert.pem -noout -subject -dates
CMD
why "-p 8443:443::open port 8443 for the HTTPS port inside|-v tls.conf::mount the nginx settings|-v certs::mount the key and certificate" "nginx needs the certificate and its private key to speak HTTPS. We mount them read-only from files on your computer."
step "Start nginx serving HTTPS on port 8443" "A container id is printed." ok '[0-9a-f]{12}' <<'CMD'
docker rm -f lab-tls >/dev/null 2>&1; docker run -d --name lab-tls -p 8443:443 -v "$PWD/12-networking/tls.conf:/etc/nginx/conf.d/default.conf:ro" -v "$PWD/playground/tls:/certs:ro" nginx:alpine; sleep 3
CMD
why "curl -sS https://localhost:8443::call the HTTPS address" "This should fail with a certificate error. The server is fine, but curl does not trust a certificate it cannot verify. That is exactly what protects you from fake websites."
step "Call it WITHOUT trusting the certificate" "curl refuses: 'self-signed certificate' (exit 60). It does not trust a certificate that no known authority signed. This is the browser warning you have seen." fail 'self-signed|unable to get local issuer|certificate' <<'CMD'
curl -sS https://localhost:8443 2>&1 | tail -2; exit ${PIPESTATUS[0]}
CMD
why "--cacert cert.pem::trust this one certificate" "Now curl is told which certificate to trust, so the check passes and the data arrives encrypted. This is how you trust an internal certificate authority."
step "Call it and TRUST that one certificate (--cacert)" "secure hello over TLS. The encrypted connection works once the client trusts the certificate." ok 'secure hello' <<'CMD'
curl -s --cacert playground/tls/cert.pem https://localhost:8443
CMD
why "openssl s_client::a tool that connects and shows the TLS handshake|-brief::a short summary" "Client and server agree on a version. TLS 1.2 or 1.3 is good, and old versions are insecure. Checking this is part of a security review."
step "Which TLS version was negotiated?" "TLSv1.3 (or 1.2). The server only allows modern versions." ok 'TLSv1\.[23]' <<'CMD'
docker run --rm --add-host=host.docker.internal:host-gateway alpine/openssl s_client -connect host.docker.internal:8443 -brief </dev/null 2>&1 | grep -E "Protocol|TLSv1" | head -2
CMD
why "docker rm -f lab-tls::stop and remove the container" "Free the port and keep the lab tidy."
step "Clean up the TLS server" "removed" ok 'lab-tls' <<'CMD'
docker rm -f lab-tls
CMD
quiz "Why does a browser show a warning for a self-signed certificate?" "trust|authority|ca|sign|verify|known|who" "Nobody the browser trusts vouched for it. Anyone can create a self-signed certificate, so it proves nothing about who you are talking to."

part "PART D · Load balancing and failover"
explain "A load balancer spreads requests over several copies of a service and stops sending to a dead one. You will build a tiny one with two backends."
learn "Load balancing and failover" "A load balancer spreads requests over several copies of a service (round-robin means taking turns) and stops sending traffic to a dead copy. That gives you both scale and availability. A gotcha you will meet: without a shared memory zone, each nginx worker keeps its own turn counter."
say "What does a load balancer do?" "It spreads requests across several copies of a service and stops sending traffic to unhealthy ones, using health checks. That gives scalability and availability. Algorithms include round robin, least connections and IP hash, and it can work at layer 4 on connections or layer 7 on HTTP. I built one with nginx and showed requests still succeed when I stop one backend."
art "Load balancer" <<'ART'
                   +--> [ server A ]
   users --> [ LB ] -+
                   +--> [ server B ]      A dies -> LB sends everything to B
ART
why "traefik/whoami::a tiny server that prints its own name|nginx lb.conf::a load balancer in front of both" "A load balancer spreads requests over several servers. We make two backends that identify themselves so you can see who answered."
step "Start two backends and a load balancer" "Three containers started: lab-a, lab-b and the balancer on port 8090." ok 'lab-lb' <<'CMD'
docker rm -f lab-a lab-b lab-lb >/dev/null 2>&1; docker network rm lab-net >/dev/null 2>&1; docker network create lab-net >/dev/null; docker run -d --name lab-a --network lab-net traefik/whoami >/dev/null; docker run -d --name lab-b --network lab-net traefik/whoami >/dev/null; sleep 2; docker run -d --name lab-lb --network lab-net -p 8090:80 -v "$PWD/12-networking/lb.conf:/etc/nginx/conf.d/default.conf:ro" nginx:alpine >/dev/null && echo "started lab-a lab-b lab-lb"; sleep 3
CMD
why "for i in 1..6: curl::six requests|sort and uniq -c::count how many each server answered" "Both backends answer in turn. That is round robin. Spreading the load is how a service grows past one machine."
step "Send 6 requests: who answered?" "Two different hostnames, taking turns (round-robin)." ok 'backends answering: 2' <<'CMD'
for i in 1 2 3 4 5 6; do curl -s localhost:8090 | grep Hostname; done | sort | uniq -c | awk '{print} END {print "backends answering: " NR}'
CMD
task "Kill one backend and prove the site still works" "Stop the backend lab-a:  docker stop lab-a   Then call the balancer again:  curl localhost:8090  It must still answer, now only from lab-b. That is failover." "The check passes when lab-a is stopped AND the balancer still answers." <<'X'
[ "$(docker inspect -f '{{.State.Running}}' lab-a)" = "false" ] && curl -s localhost:8090 | grep -q Hostname
---
docker stop lab-a >/dev/null
X
why "the same six requests::after one backend was stopped" "Only one backend answers now, but no request failed. The balancer noticed the failure and stopped using the dead server. That is failover."
step "Send 6 requests again" "Only ONE backend now answers, but no request failed. Users never noticed the failure." ok 'backends answering: 1' <<'CMD'
for i in 1 2 3 4 5 6; do curl -s localhost:8090 | grep Hostname; done | sort | uniq -c | awk '{print} END {print "backends answering: " NR}'
CMD
why "docker rm -f::remove the containers|docker network rm::remove the network" "Remove the practice containers and the private network."
step "Clean up" "Containers and network removed." ok 'lab-net' <<'CMD'
docker rm -f lab-a lab-b lab-lb >/dev/null; docker network rm lab-net
CMD
quiz "What two things does a load balancer give you?" "scale|spread|distribut|failover|availab|resilien|redundan|health|more than one" "Scaling (spread load over many copies) and availability (stop sending traffic to a failed copy, so one failure does not take the site down)."

part "PART E · Firewalls and security groups"
learn "Firewalls" "A firewall decides which network traffic may pass, by rules on source, destination and port. The safest default is DENY everything, then allow only what is needed (for example port 443 from anywhere, port 22 only from the office). A host firewall such as iptables runs on one machine; in the cloud a SECURITY GROUP does the same job in front of a server, and a network ACL does it for a whole subnet. Security groups are stateful: if a request is allowed in, the reply is allowed out automatically. A rule that DROPs traffic gives the sender no answer at all, so the client just waits and times out (REJECT sends back a refusal instead)."
say "How do firewalls and security groups work?" "They allow or deny traffic by source, destination and port. The safe default is to deny everything and allow only what is needed, for example 443 from anywhere and SSH only from a trusted address. Security groups in the cloud are stateful, so replies are allowed automatically. A dropped packet gets no answer, so the client just times out, which is a useful clue when debugging."
art "Rules decide what gets through" <<'ART'
   internet --> [ firewall / security group ] --> server
                  allow tcp 443 from anywhere      443: yes
                  allow tcp 22  from office only   22 : only from the office
                  everything else: DENY            80 : dropped, no answer
ART
why "docker network create::a private network|--cap-add NET_ADMIN::allow changing network rules inside this container" "To practise a firewall we need a server we are allowed to change the rules of. A normal container is not allowed to, which is a good security default."
step "Start a web server in its own network, with permission to edit its firewall" "A container id. lab-fw is nginx; --cap-add NET_ADMIN lets us change its network rules." <<'CMD'
docker rm -f lab-fw >/dev/null 2>&1; docker network rm lab-fw-net >/dev/null 2>&1; docker network create lab-fw-net >/dev/null; docker run -d --name lab-fw --network lab-fw-net --cap-add NET_ADMIN nginx:alpine; sleep 2
CMD
why "apk add::install a package in this Alpine Linux|iptables::the Linux firewall tool" "iptables is how Linux decides which packets to accept or drop. We add it to the container so we can write a rule."
step "Install the firewall tool (iptables) inside it" "OK: and a package count. iptables is ready." ok 'OK' <<'CMD'
docker exec lab-fw apk add --no-cache iptables iptables-legacy 2>&1 | tail -1
CMD
why "curlimages/curl::a small container that has curl|-m 3::give up after 3 seconds|lab-fw::the server name" "A client in a separate container tests the server from outside, like a real visitor. We expect HTTP 200."
step "Call the web server from a different container" "HTTP 200: the server answers." ok 'HTTP 200' <<'CMD'
docker run --rm --network lab-fw-net curlimages/curl -s -m 3 -w '\nHTTP %{http_code}\n' lab-fw | tail -1
CMD
predict "You add a rule that DROPs all traffic to port 80. What will the client see?" "A 403 Forbidden page|A refusal at once|Nothing: the request hangs until it times out|A 404 page" 3 "DROP discards packets silently, so the client waits. HTTP codes come from the web server, but the web server never even sees the request."
why "iptables -A INPUT::add a rule for incoming traffic|-p tcp --dport 80::TCP traffic to port 80|-j DROP::throw the packets away silently" "DROP gives the sender no answer at all, not even a refusal. The rule list shows your new rule."
step "Add the firewall rule: drop all traffic to port 80" "A table with one rule: DROP tcp dpt:80." ok 'DROP' <<'CMD'
docker exec lab-fw iptables-legacy -A INPUT -p tcp --dport 80 -j DROP && docker exec lab-fw iptables-legacy -L INPUT -n
CMD
why "curl -m 3::the same call, giving up after 3 seconds" "No answer within 3 seconds, so you see HTTP 000. The web server is fine, the firewall blocks the door. A hang that ends in a timeout often means a firewall."
step "Call it again" "HTTP 000: no answer. curl gave up after 3 seconds. The web server is running fine; the firewall is blocking." ok 'HTTP 000' <<'CMD'
docker run --rm --network lab-fw-net curlimages/curl -s -m 3 -w '\nHTTP %{http_code}\n' lab-fw | tail -1
CMD
why "iptables -D INPUT ...::delete the same rule|curl::call again" "Removing the rule restores access immediately. Firewall rules take effect at once, in both directions."
step "Remove the rule and call once more" "HTTP 200 again." ok 'HTTP 200' <<'CMD'
docker exec lab-fw iptables-legacy -D INPUT -p tcp --dport 80 -j DROP; docker run --rm --network lab-fw-net curlimages/curl -s -m 3 -w '\nHTTP %{http_code}\n' lab-fw | tail -1
CMD
mcq "A cloud security group allows inbound only port 443. A client tries port 22. What happens?" "The request is silently dropped and times out|The server answers 403|The server closes the port|The client is banned" 1 "Anything not allowed is denied, and denied traffic is normally dropped without a reply."

part "PART F · Private networks, bastions and VPNs"
learn "Reaching things that are not on the internet" "Databases and internal services should have NO public address. People still need to reach them, so you build a controlled doorway. A BASTION (jump host) is one hardened machine that is reachable from outside and also sits inside the private network; you connect through it. A TUNNEL (ssh -L port forwarding, or a service such as AWS Systems Manager) carries one port through that doorway. A VPN does the same for whole networks: it wraps all your traffic in an encrypted connection to a private network, so your laptop behaves as if it were inside it (site-to-site VPNs join an office to a cloud network). The rule of thumb: nothing private is exposed, and every doorway is logged."
say "How do you give access to a private service securely?" "Private services get no public address. I provide a controlled doorway: a bastion or jump host, a port-forwarding tunnel such as SSH or SSM, or a VPN for whole networks. Then only one hardened, logged entry point needs protecting instead of many exposed services. In my lab I built a bastion that forwarded one port into a private network."
art "A bastion in front of a private network" <<'ART'
   your laptop --> [ bastion ]  (public side)
                       |        (private side)
                       v
                 [ secret service ]   no public address, unreachable directly
ART
why "docker network create --internal::a network with no route to the outside|lab-secret::a web server only on that network" "A private service has no public address and no published port. From your computer it is simply not reachable."
step "Create a private network (no outside access) with a secret page on it" "ready. The secret service lives only on the private network." ok 'ready' <<'CMD'
docker rm -f lab-secret lab-bastion >/dev/null 2>&1; docker network rm lab-pub lab-priv >/dev/null 2>&1; docker network create lab-pub >/dev/null; docker network create --internal lab-priv >/dev/null; docker run -d --name lab-secret --network lab-priv nginx:alpine >/dev/null; sleep 1; docker exec lab-secret sh -c 'echo "SECRET internal page" > /usr/share/nginx/html/index.html'; echo ready
CMD
why "curl -m 3 localhost:9099::try the address that will later be the tunnel" "You get HTTP 000: there is nothing to connect to. This is the starting point before we build the doorway."
step "Try to reach it from your own computer" "HTTP 000: there is nothing to connect to. The private service is not exposed." ok 'HTTP 000' <<'CMD'
curl -s -m 3 -w '\nHTTP %{http_code}\n' localhost:9099 | tail -1
CMD
why "socat tcp-listen:80 tcp:lab-secret:80::listen on a port and pass everything on to the secret page|docker network connect::also join the private network" "A bastion is the one controlled doorway into a private network. This one forwards a single port, like ssh -L would. Only this one entry point needs protecting."
step "Start a bastion that sits on BOTH networks and forwards port 9099 to the secret page" "bastion ready. This is what ssh -L 9099:secret:80 does, built from socat." ok 'bastion ready' <<'CMD'
docker run -d --name lab-bastion --network lab-pub -p 9099:80 alpine/socat tcp-listen:80,fork,reuseaddr tcp:lab-secret:80 >/dev/null; docker network connect lab-priv lab-bastion; sleep 2; echo bastion ready
CMD
why "curl localhost:9099::call the bastion port" "The request goes through the doorway to the private server and back. Same address as before, but now it works."
step "Try again, now through the bastion" "SECRET internal page. You reached the private service through the controlled doorway." ok 'SECRET internal page' <<'CMD'
curl -s -m 5 localhost:9099
CMD
mcq "What is the main benefit of a bastion or VPN over giving the database a public IP address?" "Only one hardened, logged doorway needs protecting|It is faster|It is cheaper|The database becomes unnecessary" 1 "The fewer public doors, the smaller the attack surface. Everything private stays unreachable except through the doorway you control and monitor."

part "PART G · CDN: caching at the edge"
learn "What a CDN does" "A CDN (content delivery network) is many cache servers around the world. A user's request goes to the nearest EDGE server. On a HIT the edge answers from its copy (fast, and your origin does no work). On a MISS the edge fetches from the ORIGIN, keeps a copy for the TTL, and answers. The TTL comes from the origin's Cache-Control header. It also absorbs traffic spikes and attacks, and shows an X-Cache style header so you can see what happened. You will build a one-edge CDN with nginx."
say "What is a CDN, and when do you use it?" "A content delivery network is a set of cache servers close to users. A request is answered from the nearest edge on a hit, and only a miss goes to the origin, so it is faster and takes load off the origin. It is ideal for static public content. Personalised or private pages must not be cached for everyone, and the TTL controls how long a copy is kept."
art "Edge cache and origin" <<'ART'
   user --> [ edge cache ] --HIT--> answer (origin not touched)
                  | MISS (first time, or expired)
                  v
              [ origin server ]  -> answer is kept at the edge for the TTL (30 s here)
ART
why "lab-origin::the real server|lab-edge::an nginx cache with the rules in cdn.conf|-p 8091:80::the port you call" "A CDN edge keeps copies of answers near the user. Here one edge in front of one origin shows the whole idea in miniature."
step "Start an origin server and an edge cache in front of it" "edge ready. The edge listens on port 8091; cdn.conf holds the caching rules." ok 'edge ready' <<'CMD'
docker rm -f lab-origin lab-edge >/dev/null 2>&1; docker network rm lab-cdn-net >/dev/null 2>&1; docker network create lab-cdn-net >/dev/null; docker run -d --name lab-origin --network lab-cdn-net nginx:alpine >/dev/null; docker run -d --name lab-edge --network lab-cdn-net -p 8091:80 -v "$PWD/12-networking/cdn.conf:/etc/nginx/conf.d/default.conf:ro" nginx:alpine >/dev/null; sleep 2; echo edge ready
CMD
why "curl -D -::print the response headers|grep -i x-cache::the header that says what the cache did" "The edge has no copy yet, so it asks the origin and keeps the answer. The header says MISS."
step "First request: a MISS, the edge must ask the origin" "X-Cache-Status: MISS." ok 'MISS' <<'CMD'
curl -s -D - localhost:8091 | grep -i x-cache
CMD
why "the same curl::ask again" "This time the edge answers from its own copy, so the header says HIT. The origin did no work. That saving is the reason CDNs exist."
step "Second request: a HIT, answered from the edge's copy" "X-Cache-Status: HIT." ok 'HIT' <<'CMD'
curl -s -D - localhost:8091 | grep -i x-cache
CMD
why "docker logs lab-origin::the origin access log|grep -c::count the matching lines" "Two requests came in but the origin saw only one. The cache absorbed the other. This is how a CDN protects your servers."
step "How many requests did the ORIGIN really see?" "origin requests: 1. Two users asked, the origin worked once. That is the offload a CDN gives." ok 'origin requests: 1' <<'CMD'
echo "origin requests: $(docker logs lab-origin 2>&1 | grep -c 'GET /')"
CMD
mcq "Which setting controls how long an edge may keep its copy?" "The TTL (from Cache-Control or the cache rule)|The port number|The IP address|The container name" 1 "A short TTL means fresher data but more origin traffic; a long TTL means fewer origin requests but staler content."
why "docker rm -f ...::remove all practice containers|docker network rm ...::remove the practice networks" "Leave nothing behind: containers, networks and ports are freed."
step "Clean up the firewall, tunnel and CDN practice containers" "Everything removed." ok 'cleaned' <<'CMD'
docker rm -f lab-fw lab-secret lab-bastion lab-origin lab-edge >/dev/null 2>&1; docker network rm lab-fw-net lab-pub lab-priv lab-cdn-net >/dev/null 2>&1; echo cleaned
CMD
quiz "Name one kind of content that is a good fit for a CDN and one that is not." "image|static|video|script|css|public|javascript|private|personal|user|account|login|checkout|cookie|dynamic" "Good: static public files such as images, scripts, videos. Not: personalised or private pages (account, cart, checkout), which must not be shared between users."

deeper "A to Z of networking (Abhishek Veeramalla)|https://github.com/iam-veeramalla/a-to-z-of-networking"
explain "Done! Next: bash lab.sh 13"
