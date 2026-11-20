# Incident drills (sourced by lab.sh):  bash lab.sh incident [N|list|all]
# The lab quietly breaks the running Compose stack and sends you a pager message. You find the cause with the tools
# you learned (dc ps, dc logs, curl, docker inspect ...), fix it, and type  check . The clock is running.
# Maintainers: LAB_AUTO=solve bash lab.sh incident all   breaks each fault, applies the reference fix and checks it.
INCSTATS="${LAB_STATS_INCIDENTS:-.incidents}"
INC_COUNT=5
INC_BAK=playground/incident.env.bak

# the one question that matters to the users: does the site answer?
inc_ok() { curl -s -m 5 localhost:8080/healthz 2>/dev/null | grep -q '"ok":true'; }
inc_wait_ok() { local t=${1:-60} i=0; while [ "$i" -lt "$t" ]; do inc_ok && return 0; sleep 2; i=$((i + 2)); done; return 1; }
inc_api() { dc ps -q api 2>/dev/null | head -1; }

# put the stack back to healthy (also repairs a drill that was abandoned half way)
inc_reset() {
  local id
  [ -f "$INC_BAK" ] && { cp "$INC_BAK" .env; rm -f "$INC_BAK"; }
  id=$(inc_api); [ -n "$id" ] && docker unpause "$id" >/dev/null 2>&1
  dc up -d --build --force-recreate >/dev/null 2>&1
  inc_wait_ok 90
}

# inc_load N: sets I_NAME I_LEVEL I_PAGE I_INJECT I_SOLVE I_CAUSE I_PREVENT and the I_HINT list
inc_load() {
  I_HINT=()
  case "$1" in
    1) I_NAME=api-stopped; I_LEVEL=easy
       I_PAGE="ALERT: devlab website returns 502 Bad Gateway on /healthz for 3 minutes. Customers see 'Bad Gateway'."
       I_INJECT='dc stop api'
       I_SOLVE='dc start api'
       I_HINT=("Check what is running:  dc ps -a   (look at the STATUS column of every service)." "The web container is fine. One service behind it is not running." "Start the api service again:  dc start api   then  check .")
       I_CAUSE="Someone stopped the api container. The web container (nginx) was healthy, but it had nothing to proxy to, so it answered 502."
       I_PREVENT="Alert on 'container not running' as well as on the HTTP check, and keep restart: unless-stopped so a crash heals itself." ;;
    2) I_NAME=api-hung; I_LEVEL=easy
       I_PAGE="ALERT: devlab /healthz times out (no answer in 5 seconds). Every container shows as up. Customers say 'the page just hangs'."
       I_INJECT='docker pause "$(inc_api)"'
       I_SOLVE='docker unpause "$(inc_api)"'
       I_HINT=("Everything is 'up', yet nothing answers. Look closely at the STATUS column:  dc ps -a  or  docker ps ." "One container is frozen: its processes are suspended, not stopped. Docker shows it as (Paused)." "Resume it:  docker unpause <container>   (get the name from docker ps).")
       I_CAUSE="The api container was paused (all its processes frozen). It still counts as 'running', so a simple 'is the container up?' check stays green while every request hangs."
       I_PREVENT="Use a real health check that makes a request (like /healthz) instead of only looking at container state, and alert on latency and timeouts." ;;
    3) I_NAME=bad-secret; I_LEVEL=medium
       I_PAGE="ALERT: devlab api keeps restarting since this afternoon's config change. /healthz returns 502."
       I_INJECT='mkdir -p playground; cp .env '"$INC_BAK"'; sed -i "s/^JWT_SECRET=.*/JWT_SECRET=short/" .env; dc up -d --force-recreate api'
       I_SOLVE='cp '"$INC_BAK"' .env; dc up -d --force-recreate api'
       I_HINT=("Read what the api says before it dies:  dc logs --tail 20 api" "The log names the setting that is wrong and the rule it breaks (a length). Where do settings live?  cat .env" "Give JWT_SECRET a value of at least 32 characters in .env, then recreate the api:  dc up -d --force-recreate api")
       I_CAUSE="A config change set JWT_SECRET to a 5-character value. In production mode the API refuses to start with a secret shorter than 32 characters, so the container crash-looped."
       I_PREVENT="Validate config in CI before it ships, fail fast with a clear log line (as the API does), and roll config out gradually so one bad value cannot take everything down." ;;
    4) I_NAME=network-cut; I_LEVEL=medium
       I_PAGE="ALERT: 502 from the web tier, but the api container is running and its health check is green. Nobody touched the code."
       I_INJECT='docker network disconnect devlab_backend "$(inc_api)"'
       I_SOLVE='dc up -d --force-recreate api'
       I_HINT=("The api is healthy, so the problem is between web and api. Read the web log:  dc logs --tail 20 web" "The web container cannot resolve the name 'api'. Which network should both containers share?  docker network inspect devlab_backend" "The api left the network. Recreate it so compose puts it back with its alias:  dc up -d --force-recreate api")
       I_CAUSE="The api container was detached from the devlab_backend network. It was still healthy inside, but nginx could no longer find the name 'api', so every proxied request failed."
       I_PREVENT="Manage networks only through the compose file, never by hand, and check the whole request path (a synthetic check through the web tier), not just each container's own health." ;;
    5) I_NAME=wrong-image; I_LEVEL=hard
       I_PAGE="ALERT: after tonight's release the site at http://localhost:8080 returns no page and connections are reset. You are on call: restore service."
       I_INJECT='docker image inspect nginx:alpine >/dev/null 2>&1 || docker pull -q nginx:alpine; dc stop web; docker tag nginx:alpine devlab-web:lab; dc up -d --no-build --force-recreate web'
       I_SOLVE='dc up -d --build --force-recreate web'
       I_HINT=("Is the web container up? What does it say?  dc ps -a   dc logs --tail 20 web" "It runs, but is it OUR web image? Look at what the container is made of:  docker exec \$(dc ps -q web) cat /etc/nginx/conf.d/default.conf   (our config listens on 8080)." "The tag devlab-web:lab now points at a stock nginx image. Rebuild ours and recreate the container:  dc up -d --build --force-recreate web")
       I_CAUSE="The tag devlab-web:lab was overwritten with a stock nginx image during the release. The container started fine but listened on port 80 with no app and no /healthz, while compose published port 8080."
       I_PREVENT="Deploy by an immutable version tag or digest (never a tag you reuse), keep the previous image so you can roll back in one command, and smoke-test /healthz right after every deploy." ;;
    *) return 1 ;;
  esac
}

inc_best() { [ -f "$INCSTATS" ] && grep "^$1|" "$INCSTATS" | cut -d'|' -f2 | sort -n | head -1; }
inc_fmt() { printf '%dm%02ds' $(( $1 / 60 )) $(( $1 % 60 )); }

inc_list() {
  local n b
  printf '\n  %sIncident drills%s  (bash lab.sh incident N, or just  bash lab.sh incident  for a random one you have not solved)\n' "$BOLD" "$RST"
  for n in $(seq 1 "$INC_COUNT"); do inc_load "$n"; b=$(inc_best "$I_NAME")
    printf '   %d  %-12s %-7s %s\n' "$n" "$I_NAME" "$I_LEVEL" "${b:+best: $(inc_fmt "$b")}"; done
  printf '\n'
}

# make sure the stack is up and healthy before breaking it
inc_prepare() {
  [ -f .env ] || cp .env.example .env
  inc_ok && return 0
  printf '  %sStarting the practice stack first (the first build can take a minute)...%s\n' "$DIM" "$RST"
  dc up -d --build >/dev/null 2>&1
  inc_wait_ok 120 || inc_reset || { printf '  %sThe stack does not come up. Run  bash lab.sh 03  first.%s\n' "$RED" "$RST"; return 1; }
}

# automatic test of one fault: break it, prove it is broken, fix it with the reference fix, prove it is fixed
inc_selftest() {
  inc_load "$1" || return 1
  printf 'incident %d %-12s ' "$1" "$I_NAME"
  inc_prepare || { echo "FAIL (no stack)"; return 1; }
  ( eval "$I_INJECT" ) >/dev/null 2>&1; sleep 4
  if inc_ok; then echo "FAIL (the fault did not break anything)"; inc_reset; return 1; fi
  ( eval "$I_SOLVE" ) >/dev/null 2>&1
  if inc_wait_ok 60; then echo "PASS"; [ -f "$INC_BAK" ] && rm -f "$INC_BAK"; return 0; fi
  echo "FAIL (the reference fix did not repair it)"; inc_reset; return 1
}

incident_main() {
  local arg="${1:-}" n pick line out hints=0 level_xp xp t k seen unsolved
  case "$arg" in
    list|ls) inc_list; return 0 ;;
    all) local bad=0; for n in $(seq 1 "$INC_COUNT"); do inc_selftest "$n" || bad=1; done; return $bad ;;
  esac
  if [ -n "$AUTO" ]; then
    [ -z "$arg" ] && { incident_main all; return; }
    inc_selftest "$arg"; return
  fi
  if [[ "$arg" =~ ^[0-9]+$ ]]; then n=$((10#$arg)); inc_load "$n" || { inc_list; return 1; }
  else # random, preferring a fault you have not solved yet
    unsolved=(); for k in $(seq 1 "$INC_COUNT"); do inc_load "$k"; [ -z "$(inc_best "$I_NAME")" ] && unsolved+=("$k"); done
    if [ "${#unsolved[@]}" -gt 0 ]; then n=${unsolved[$((RANDOM % ${#unsolved[@]}))]}; else n=$((RANDOM % INC_COUNT + 1)); fi
    inc_load "$n"
  fi
  inc_prepare || return 1
  ( eval "$I_INJECT" ) >/dev/null 2>&1; sleep 3
  printf '\n'; box "$BOLD$RED" "PAGER  ·  incident $n  ·  $I_LEVEL"
  explain "$I_PAGE"
  printf '\n  %sYou are on call. Find the cause and fix it. Type your commands right here, then  check  when the site answers again.%s\n' "$BOLD" "$RST"
  printf '  %sStart with:  dc ps -a    curl -i localhost:8080/healthz    dc logs --tail 20 api       hint (costs XP) | giveup | shortcuts | quit%s\n' "$DIM" "$RST"
  SECONDS=0
  while true; do
    printf '  %spager ▸%s ' "$RED$BOLD" "$RST"
    read -r line <&3 || { echo; exit 0; }
    case "$line" in
      '') continue ;;
      check) if inc_ok; then break; fi
             printf '  %s %s STILL DOWN %s  curl -s -o /dev/null -w "%%{http_code}" localhost:8080/healthz  gives: %s\n' "$BG_R" "$I_BAD" "$RST" "$(curl -s -m 5 -o /dev/null -w '%{http_code}' localhost:8080/healthz 2>/dev/null)" ;;
      hint|'?') if [ "$hints" -lt "${#I_HINT[@]}" ]; then hints=$((hints + 1)); fi
                printf '  %s➜ hint %d/%d:%s %s\n' "$YEL" "$hints" "${#I_HINT[@]}" "$RST" "${I_HINT[$((hints - 1))]:-Look at what is running, then at the logs.}" ;;
      giveup|answer) printf '  %sReference fix:%s %s\n' "$YEL" "$RST" "$I_SOLVE"; ( eval "$I_SOLVE" ) >/dev/null 2>&1; inc_wait_ok 60
                     printf '\n  %sFixed for you, no XP this time.%s\n' "$YEL" "$RST"; printf '  %sCause:%s %s\n  %sPrevent:%s %s\n' "$BOLD" "$RST" "$I_CAUSE" "$BOLD" "$RST" "$I_PREVENT"; rm -f "$INC_BAK"; return 0 ;;
      shortcuts) shortcuts ;;
      quit|q|exit) printf '  %sRestoring the stack...%s\n' "$DIM" "$RST"; inc_reset; printf '  bye!\n'; exit 0 ;;
      edit\ *|nano\ *|vi\ *|vim\ *) ( eval "$line" ) <&3 ;;
      *) out=$( ( eval "$line" ) <&3 2>&1 ); show_out "$out" ;;
    esac
  done
  t=$SECONDS; rm -f "$INC_BAK"
  xp=$(( 60 - 15 * hints )); [ "$xp" -lt 10 ] && xp=10; [ "$t" -lt 300 ] && xp=$((xp + 20))
  seen=$(inc_best "$I_NAME")
  printf '\n'; box "$BOLD$GRN" "RESOLVED in $(inc_fmt "$t") with $hints hint(s)"
  printf '  '; xp_add "$xp"; printf '\n'
  [ -n "$seen" ] && { if [ "$t" -lt "$seen" ]; then printf '  %sNew personal best!%s (was %s)\n' "$GRN" "$RST" "$(inc_fmt "$seen")"; else printf '  Your best on this one: %s\n' "$(inc_fmt "$seen")"; fi; }
  echo "$I_NAME|$t|$hints|$(date +%F)" >> "$INCSTATS"
  printf '\n  %sPostmortem%s\n    %sWhat broke:%s %s\n    %sHow to prevent it:%s %s\n' "$BOLD$CYN" "$RST" "$BOLD" "$RST" "$I_CAUSE" "$BOLD" "$RST" "$I_PREVENT"
  printf '\n  %sSay it like an interview:%s "The site returned errors. I checked what was running, read the logs of the failing part, found the cause, fixed it, and confirmed with the health check. Then I wrote up the cause and how to prevent it."\n' "$DIM" "$RST"
  printf '  %sAnother one: bash lab.sh incident%s\n' "$DIM" "$RST"
}
