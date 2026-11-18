#!/usr/bin/env bash
# Guided lab runner. Walks you through each module: explains, runs commands for you,
# gives hands-on tasks and checks your work. Run from the repo root in Git Bash:
#   bash lab.sh            menu (press Enter to continue where you left off)
#   bash lab.sh 00         start lesson 00 (continues to the next lesson by itself)
#   bash lab.sh next       resume at the first unfinished lesson
#   bash lab.sh status     your progress
#   bash lab.sh down       stop everything the labs started
#   bash lab.sh reset      forget progress
# Maintainers: LAB_AUTO=run|solve bash lab.sh 01   (non-interactive; solve also performs the tasks)
set -u
cd "$(dirname "$0")" || exit 1
export MSYS_NO_PATHCONV=1
export DC="docker compose -f 03-compose/docker-compose.yml --env-file .env"
export DCO="docker compose -f 03-compose/docker-compose.yml -f 08-observability/compose.observability.yml --env-file .env"
export DCP="docker compose -f 03-compose/docker-compose.yml -f 16-postgres/compose.postgres.yml --env-file .env"
KUBECONFIG="$(pwd -W 2>/dev/null || pwd)/.kube/config"; export KUBECONFIG
AUTO="${LAB_AUTO:-}"
MODE="${LAB_MODE:-type}"     # type = YOU type each command (default) | watch = the lab runs them, you press Enter
PROGRESS=.progress
PASS=0; FAIL=0; SKIP=0; CUR=0; TOTAL=0
LESSONS=$(ls lessons/*.sh 2>/dev/null | wc -l | tr -d " ")
W=78
mkdir -p playground

# ---------- short helper commands used in the lessons (type  shortcuts  to list them) ----------
dc()  { docker compose -f 03-compose/docker-compose.yml --env-file .env "$@"; }
dco() { docker compose -f 03-compose/docker-compose.yml -f 08-observability/compose.observability.yml --env-file .env "$@"; }
dcl() { docker compose -f 03-compose/docker-compose.yml -f 08-observability/compose.observability.yml -f 15-logging/compose.logging.yml --env-file .env "$@"; }
dcp() { docker compose -f 03-compose/docker-compose.yml -f 16-postgres/compose.postgres.yml --env-file .env "$@"; }
ac()  { docker compose -f 13-ansible/compose.yml "$@"; }
lab-ansible() { bash 13-ansible/ansible.sh "$@"; }
lab-helm()    { bash 14-helm/helm.sh "$@"; }
lab-tf-aws()  { bash 17-aws/tf-aws.sh "$@"; }
awsl()   { AWS_ACCESS_KEY_ID=test AWS_SECRET_ACCESS_KEY=test aws --no-cli-pager --endpoint-url=http://localhost:4566 --region ap-south-1 "$@"; }
leads()  { dc exec -T api node -e "const {DatabaseSync}=require('node:sqlite');console.log('leads in database:',new DatabaseSync('/data/database.sqlite').prepare('select count(*) c from leads').get().c)"; }
kleads() { kubectl -n devlab-dev exec devlab-api-0 -- node -e "const {DatabaseSync}=require('node:sqlite');console.log('leads in database:',new DatabaseSync('/data/database.sqlite').prepare('select count(*) c from leads').get().c)"; }
gh_repo() { git remote get-url origin 2>/dev/null | sed -E 's#(git@github.com:|https://github.com/)##; s#\.git$##'; }     # owner/repo of this checkout
ghget()   { curl -s "https://api.github.com/repos/$(gh_repo)$1"; }                                                          # read-only GitHub API for your repo (public repos need no login)
ghjobs()  { local id; id=$(ghget '/actions/workflows/ci.yml/runs?status=completed&per_page=1' | grep -m1 '"id"' | grep -o '[0-9]*'); ghget "/actions/runs/$id/jobs" | grep -E '^      "(name|conclusion)"' | sed -E 's/^ +"(name|conclusion)": "?([^",]*)"?,?/\1: \2/'; }   # jobs of the latest finished CI run
pq()  { curl -s localhost:9090/api/v1/query --data-urlencode "query=$1" | node 08-observability/pq.js; }   # ask Prometheus a PromQL question (module 08)
rc()  { docker exec lab-redis redis-cli "$@"; }                  # the Redis CLI in the practice Redis (module 24)
lx()  { docker exec lab-linux "$@"; }                       # run a command inside the Linux practice server (module 18)
g()   { git -C playground/collab "$@"; }                      # git inside the practice repo (module 19)
vlt() { local i=; case "$*" in *"policy write"*) i=-i ;; esac; docker exec $i -e VAULT_ADDR=http://127.0.0.1:8200 -e VAULT_TOKEN="${VAULT_TOKEN_LAB:-lab-root}" lab-vault vault "$@"; }   # the Vault CLI (module 20); stdin is attached only for "policy write"
leadsfor()  { dc exec -T api node -e "const {DatabaseSync}=require('node:sqlite');console.log(new DatabaseSync('/data/database.sqlite').prepare('select count(*) c from leads where email=?').get('$1').c)" | tr -d '\r\n '; }
kleadsfor() { kubectl -n devlab-dev exec devlab-api-0 -- node -e "const {DatabaseSync}=require('node:sqlite');console.log(new DatabaseSync('/data/database.sqlite').prepare('select count(*) c from leads where email=?').get('$1').c)" | tr -d '\r\n '; }
edit()   { local f="$1"; mkdir -p "$(dirname "$f")"; if command -v nano >/dev/null 2>&1; then nano "$f"; else notepad "$(cygpath -w "$f" 2>/dev/null || echo "$f")"; fi; }
shortcuts() {
  printf '  %sShortcuts defined by this lab%s\n' "$BOLD" "$RST"
  printf '    dc        docker compose for the app           (docker compose -f 03-compose/docker-compose.yml --env-file .env ...)\n'
  printf '    dco       dc + monitoring (Prometheus, Grafana)\n'
  printf '    dcl       dco + logging (Loki, Alloy, Jaeger)\n'
  printf '    dcp       dc + Postgres\n'
  printf '    ac        docker compose for the Ansible practice servers\n'
  printf '    lab-ansible / lab-helm / lab-tf-aws   run Ansible, Helm or Terraform-for-AWS in Docker\n'
  printf '    awsl      the AWS CLI pointed at LocalStack (the free fake AWS)\n'
  printf '    leads / kleads   count the leads in the database (compose / Kubernetes)\n'
  printf '    ghget /PATH   read your repo from the GitHub API, for example ghget /actions/runs   ghjobs  the jobs of the latest CI run\n'
  printf '    lx CMD    run CMD inside the Linux practice server (module 18)\n'
  printf '    pq QUERY  run a PromQL query against Prometheus, for example pq up (module 08)\n'
  printf '    rc CMD    the Redis CLI in the practice Redis, for example rc GET key (module 24)\n'
  printf '    g CMD     git inside the practice repo playground/collab (module 19)\n'
  printf '    vlt CMD   the Vault CLI against the practice Vault (module 20)\n'
  printf '    edit FILE open a file in the nano editor (Ctrl+O save, Ctrl+X exit)\n'
  printf '  Type  type dc  to see exactly what a shortcut does.\n'
}
# Read keyboard input from the terminal if there is one, otherwise from stdin (lets you pipe answers in).
if [ -z "$AUTO" ] && ( : </dev/tty ) 2>/dev/null; then exec 3</dev/tty; else exec 3<&0; fi

# ---------- look and feel ----------
if [ -n "${NO_COLOR:-}" ]; then
  BOLD=; DIM=; RED=; GRN=; YEL=; MAG=; CYN=; RST=; BG_G=; BG_R=; BG_Y=; BG_C=; BG_M=; BG_B=; BG_W=
else
  BOLD=$'\033[1m'; DIM=$'\033[2m'; RED=$'\033[31m'; GRN=$'\033[32m'; YEL=$'\033[33m'
  MAG=$'\033[35m'; CYN=$'\033[36m'; RST=$'\033[0m'
  BG_G=$'\033[42;30;1m'; BG_R=$'\033[41;97;1m'; BG_Y=$'\033[43;30;1m'; BG_C=$'\033[46;30;1m'; BG_M=$'\033[45;97;1m'; BG_B=$'\033[44;97;1m'; BG_W=$'\033[47;30;1m'
fi
rep()  { local i; for ((i=0; i<$2; i++)); do printf '%s' "$1"; done; }
rule() { printf '%s%s%s\n' "${2:-$DIM}" "$(rep "${1:-─}" "$W")" "$RST"; }
bar()  { # bar done total [width]
  local d=$1 t=$2 w=${3:-24} f; [ "$t" -le 0 ] && t=1; f=$(( d * w / t ))
  printf '%s%s%s%s%s' "$GRN" "$(rep █ "$f")" "$DIM" "$(rep ░ $((w - f)))" "$RST"
}
box()  { # color text  (plain text only)
  local c="$1" t="$2" len pad
  # character count that is right for UTF-8 (drops continuation bytes), independent of the locale
  len=$(printf '%s' "$t" | LC_ALL=C tr -d '\200-\277' | wc -c); pad=$(( W - 4 - len )); [ "$pad" -lt 0 ] && pad=0
  printf '%s╔%s╗\n║ %s%*s ║\n╚%s╝%s\n' "$c" "$(rep ═ $((W-2)))" "$t" "$pad" '' "$(rep ═ $((W-2)))" "$RST"
}
banner() {
  printf '%s%s' "$BOLD" "$CYN"
  cat <<'ART'
    ____             ____
   |  _ \  _____   _/ __ \ _ __  ___
   | | | |/ _ \ \ / / | | | '_ \/ __|
   | |_| |  __/\ V /| |_| | |_) \__ \
   |____/ \___| \_/  \____/| .__/|___/
                           |_|
ART
  printf '%s%s     C L O U D   L A B  %s·%s  learn by doing, check by running%s\n' "$RST" "$BOLD" "$DIM" "$RST" "$RST"
}
rank() { # completed lessons -> title (by share of all lessons)
  local p=$(( $1 * 100 / LESSONS ))
  if   [ "$p" -ge 100 ]; then echo "SRE Legend"
  elif [ "$p" -ge 80 ];  then echo "Senior Engineer"
  elif [ "$p" -ge 50 ];  then echo "Platform Engineer"
  elif [ "$p" -ge 25 ];  then echo "DevOps Engineer"
  elif [ "$p" -ge 1 ];   then echo "Junior Operator"
  else echo "Newcomer"; fi
}
done_count() { [ -f "$PROGRESS" ] && grep -c '^[0-9][0-9]$' "$PROGRESS" || echo 0; }

ask()     { [ -n "$AUTO" ] && return 0; printf '%s' "$1"; read -r _ <&3; }
title()   { printf '\n'; box "$BOLD$CYN" "$1"; }
explain() { printf '%s\n' "$1" | fold -s -w $((W-4)) | sed 's/^/  /'; }
part() {
  case "$1" in
    "PART "*) printf '\n%s━━━ %s %s%s\n' "$BOLD$CYN" "$1" "$(rep ━ $((W - 6 - $(printf '%s' "$1" | LC_ALL=C tr -d '\200-\277' | wc -c))))" "$RST" ;;
    *)        printf '\n%s%s%s\n' "$BOLD" "$1" "$RST" ;;
  esac
}
badge()   { CUR=$((CUR+1)); printf '\n%s %s %d/%d %s %s%s%s\n' "$2" "$1" "$CUR" "$TOTAL" "$RST" "$BOLD" "$3" "$RST"; }
pass()    { PASS=$((PASS+1)); printf '  %s ✔ PASS %s' "$BG_G" "$RST"; xp_add 25; printf '\n'; }
fail()    { FAIL=$((FAIL+1)); printf '  %s ✘ FAIL %s %s\n' "$BG_R" "$RST" "${1:-}"; }

# step "what this does" "what to look for" [ok|fail] ["regex the output must match (checked in auto mode)"] <<'CMD' ... CMD
step_watch() {
  local cmd rc; cmd=$(cat)
  badge "STEP" "$BG_B" "$1"
  printf '%s%s%s\n' "$DIM$CYN" "$(printf '%s' "$cmd" | sed 's/^/  ❯ /')" "$RST"
  ask "  ${DIM}press Enter to run it ▸ ${RST}"
  local out; out=$( ( eval "$cmd" ) 2>&1; echo "::rc=$?" ); rc=${out##*::rc=}; out=${out%::rc=*}
  printf '%s' "$out" | sed "s/^/  ${DIM}│${RST} /"; [ -n "$out" ] && [ "${out: -1}" != $'\n' ] && echo
  [ -n "${2:-}" ] && printf '  %s➜ Look for:%s %s\n' "$YEL" "$RST" "$2"
  if [ -n "$AUTO" ]; then
    if [ "${3:-ok}" = fail ]; then [ "$rc" -ne 0 ] && pass || fail "(expected this command to fail)"
    elif [ "$rc" -ne 0 ]; then fail "(command exited $rc)"
    elif [ -n "${4:-}" ] && ! printf '%s' "$out" | grep -Eq "$4"; then fail "(output did not match: $4)"
    else pass; fi
  fi
}

# task "goal" "how to do it" "hint" <<'X' ... check command ... \n---\n ... solution command ... X
task_watch() {
  local all check sol a; all=$(cat)
  check=${all%%$'\n---\n'*}; sol=${all#*$'\n---\n'}
  # OPT=1 task ...  = optional task (for example one that needs a real cloud account): skipping it never blocks the lesson
  if [ -n "${OPT:-}" ]; then badge "OPTIONAL" "$BG_C" "$1"; else badge "YOUR TURN" "$BG_Y" "$1"; fi
  explain "$2"
  if [ -n "$AUTO" ]; then
    if [ -n "${OPT:-}" ]; then printf '  %s○ optional task, not run in auto mode%s\n' "$YEL" "$RST"; return; fi
    [ "$AUTO" = solve ] && ( eval "$sol" ) >/dev/null 2>&1
    if ( eval "$check" ) >/dev/null 2>&1; then pass; else fail "(task check)"; fi
    return
  fi
  while true; do
    printf '  %sDo it in ANOTHER terminal, then press Enter to check  (s = skip, h = show answer) ▸ %s' "$YEL" "$RST"
    read -r a <&3
    case "$a" in
      s) [ -z "${OPT:-}" ] && SKIP=$((SKIP+1)); printf '  %s○ skipped%s\n' "$YEL" "$RST"; return ;;
      h) printf '  %sAnswer:%s\n%s\n' "$YEL" "$RST" "$(printf '%s' "$sol" | sed "s/^/    ${DIM}❯${RST} /")"; continue ;;
    esac
    if ( eval "$check" ) >/dev/null 2>&1; then pass; return; fi
    printf '  %s ✘ NOT YET %s Hint: %s\n' "$BG_R" "$RST" "${3:-read the instructions again}"
  done
}

# ---- typing mode: YOU type the commands ----
norm() { printf '%s' "$1" | tr '\n' ' ' | sed -E "s/[\"']//g; s/[[:space:]]+/ /g; s/^ //; s/ $//"; }
trim_tail() { printf '%s' "$1" | sed -E 's/ *2>&1 *\| *(tail|head)[^|;]*$//; s/ *2>&1 *$//; s/ *\| *(tail|head)[^|;]*$//; s/ *>\/dev\/null( 2>&1)?$//'; }
# Turn a leading lab shortcut into its long form, so typing the long form counts as the same command.
expand_sc() {
  printf '%s' "$1" | sed -E "s#^dc #docker compose -f 03-compose/docker-compose.yml --env-file .env #; s#^dco #docker compose -f 03-compose/docker-compose.yml -f 08-observability/compose.observability.yml --env-file .env #; s#^dcp #docker compose -f 03-compose/docker-compose.yml -f 16-postgres/compose.postgres.yml --env-file .env #; s#^dcl #docker compose -f 03-compose/docker-compose.yml -f 08-observability/compose.observability.yml -f 15-logging/compose.logging.yml --env-file .env #; s#^ac #docker compose -f 13-ansible/compose.yml #"
}
same_cmd() {
  local a b ta tb
  a=$(norm "$1"); b=$(norm "$2")
  ta=$(norm "$(trim_tail "$1")"); tb=$(norm "$(trim_tail "$2")")
  [ "$a" = "$b" ] || [ "$ta" = "$tb" ] || [ "$(norm "$(expand_sc "$ta")")" = "$(norm "$(expand_sc "$tb")")" ]
}
show_out() { [ -n "$1" ] && { printf '%s' "$1" | sed "s/^/  ${DIM}│${RST} /"; [ "${1: -1}" != $'\n' ] && echo; }; return 0; }

step_type() {
  local cmd typed out rc tries=0 accepted
  cmd=$(cat)
  badge "STEP" "$BG_B" "$1"
  printf '  %sType this command%s (type it or copy it, then press Enter):\n' "$BOLD" "$RST"
  printf '%s%s%s\n' "$DIM$CYN" "$(printf '%s' "$cmd" | sed 's/^/    ❯ /')" "$RST"
  printf '%s' "$cmd" | grep -Eq '\| *(tail|head)' && printf '  %s(the part after | tail or | head only shortens the output: you may leave it off)%s\n' "$DIM" "$RST"
  while true; do
    printf '  %s▸%s ' "$GRN$BOLD" "$RST"
    read -r typed <&3 || { echo; exit 0; }
    accepted=
    case "$typed" in
      '')          printf '  %sType the command shown above and press Enter.  ?=hint  run=let the lab run it  skip  shortcuts  quit%s\n' "$DIM" "$RST"; continue ;;
      '?'|hint)    printf '  %s➜ %s%s\n' "$YEL" "${2:-Type the command shown above.}" "$RST"; continue ;;
      shortcuts)   shortcuts; continue ;;
      skip)        SKIP=$((SKIP+1)); printf '  %s○ skipped%s\n' "$YEL" "$RST"; return ;;
      quit|q|exit) printf '  bye! Continue later with: bash lab.sh next\n'; exit 0 ;;
      run)         typed="$cmd"; accepted=1 ;;
    esac
    out=$( ( eval "$typed" ) <&3 2>&1; echo "::rc=$?" ); rc=${out##*::rc=}; out=${out%::rc=*}
    show_out "$out"
    if [ -z "$accepted" ]; then
      if same_cmd "$typed" "$cmd"; then accepted=1
      elif [ -n "${4:-}" ] && [ "${3:-ok}" != fail ] && [ "$rc" -eq 0 ] && printf '%s' "$out" | grep -Eq "$4"; then accepted=1
      fi
    fi
    if [ -n "$accepted" ]; then
      PASS=$((PASS+1)); printf '  %s ✔ DONE %s' "$BG_G" "$RST"; xp_add 10; printf '\n'
      [ -n "${2:-}" ] && printf '  %s➜ Look for:%s %s\n' "$YEL" "$RST" "$2"
      return
    fi
    tries=$((tries+1))
    printf '  %s ✘ NOT YET %s That ran, but this step needs the command shown above.' "$BG_R" "$RST"
    case "$(norm "$cmd")" in dc\ *|dco\ *|dcl\ *|dcp\ *|ac\ *) case "$(norm "$typed")" in "docker compose"*) printf '\n  %sTip: dc is short for  docker compose -f 03-compose/docker-compose.yml --env-file .env  . Type  shortcuts  to see all of them.%s' "$DIM" "$RST" ;; esac ;; esac
    [ "$tries" -ge 2 ] && printf '  Stuck? Type  run  and I will run it for you.'
    printf '\n'
  done
}

task_type() {
  local all check sol line out
  all=$(cat); check=${all%%$'\n---\n'*}; sol=${all#*$'\n---\n'}
  if [ -n "${OPT:-}" ]; then badge "OPTIONAL" "$BG_C" "$1"; else badge "YOUR TURN" "$BG_Y" "$1"; fi
  explain "$2"
  printf '  %sType your commands right here (no second window needed). Type  check  when you are done.%s\n' "$BOLD" "$RST"
  printf '  %s  hint | answer | skip | shortcuts | edit FILE (opens the nano editor) | quit%s\n' "$DIM" "$RST"
  while true; do
    printf '  %slab ▸%s ' "$YEL$BOLD" "$RST"
    read -r line <&3 || { echo; exit 0; }
    case "$line" in
      '') continue ;;
      check) if ( eval "$check" ) >/dev/null 2>&1; then pass; return; fi
             printf '  %s ✘ NOT YET %s Hint: %s\n' "$BG_R" "$RST" "${3:-read the instructions again}" ;;
      hint|'?') printf '  %s➜ %s%s\n' "$YEL" "${3:-read the instructions again}" "$RST" ;;
      answer|h) printf '  %sAnswer (type these yourself):%s\n%s\n' "$YEL" "$RST" "$(printf '%s' "$sol" | sed "s/^/    ${DIM}❯${RST} /")" ;;
      skip|s) [ -z "${OPT:-}" ] && SKIP=$((SKIP+1)); printf '  %s○ skipped%s\n' "$YEL" "$RST"; return ;;
      shortcuts) shortcuts ;;
      quit|q|exit) printf '  bye! Continue later with: bash lab.sh next\n'; exit 0 ;;
      edit\ *|nano\ *|vi\ *|vim\ *) ( eval "$line" ) <&3 ;;
      *) out=$( ( eval "$line" ) <&3 2>&1 ); show_out "$out" ;;
    esac
  done
}

step() { if [ -n "$AUTO" ] || [ "$MODE" = watch ]; then step_watch "$@"; else step_type "$@"; fi; }
task() { if [ -n "$AUTO" ] || [ "$MODE" = watch ]; then task_watch "$@"; else task_type "$@"; fi; }

# learn "title" "text": a short teaching block. In typing mode the student reads it and presses Enter.
learn() {
  printf '\n%s LEARN %s %s%s%s\n' "$BG_C" "$RST" "$BOLD" "$1" "$RST"
  explain "$2"
  if [ -z "$AUTO" ] && [ "$MODE" = type ]; then printf '  %s(read it, then press Enter to continue) ▸ %s' "$DIM" "$RST"; read -r _ <&3 || exit 0; fi
}

# exam KIND COLOR "title" "scenario" "hint" <<'X' setup --- check --- solution [--- cleanup] X
# Used by interview (hands-on interview questions) and final (module exam). The lab sets up a scenario,
# the student fixes or builds it at the lab prompt, and `check` verifies the real result. No 'answer' key: it is an exam.
exam() {
  local kind="$1" color="$2" title="$3" details="$4" hint="${5:-}" all setup check sol clean rest line out
  all=$(cat)
  setup=${all%%$'\n---\n'*}; rest=${all#*$'\n---\n'}
  check=${rest%%$'\n---\n'*}; rest=${rest#*$'\n---\n'}
  if [[ "$rest" == *$'\n---\n'* ]]; then sol=${rest%%$'\n---\n'*}; clean=${rest#*$'\n---\n'}; else sol=$rest; clean=true; fi
  badge "$kind" "$color" "$title"
  ( eval "$setup" ) >/dev/null 2>&1
  explain "$details"
  if [ -n "$AUTO" ]; then
    [ "$AUTO" = solve ] && ( eval "$sol" ) >/dev/null 2>&1
    if ( eval "$check" ) >/dev/null 2>&1; then pass; else fail "($kind check)"; fi
    ( eval "$clean" ) >/dev/null 2>&1
    return
  fi
  printf '  %sType your commands right here. Type  check  when you are done.%s  %shint | skip | shortcuts | edit FILE | quit%s\n' "$BOLD" "$RST" "$DIM" "$RST"
  while true; do
    printf '  %slab ▸%s ' "$YEL$BOLD" "$RST"
    read -r line <&3 || { echo; exit 0; }
    case "$line" in
      '') continue ;;
      check) if ( eval "$check" ) >/dev/null 2>&1; then
               pass; [ "$kind" = INTERVIEW ] && printf '  %s🎤 Interviewer:%s "Good. That is exactly what I wanted to see."\n' "$BOLD" "$RST"
               ( eval "$clean" ) >/dev/null 2>&1; return
             fi
             printf '  %s ✘ NOT YET %s%s\n' "$BG_R" "$RST" "${hint:+ Hint: $hint}" ;;
      hint|'?') printf '  %s➜ %s%s\n' "$YEL" "${hint:-Re-read the question and look at what the check could be testing.}" "$RST" ;;
      skip|s) SKIP=$((SKIP+1)); printf '  %s○ skipped (this counts as not passed)%s\n' "$YEL" "$RST"; ( eval "$clean" ) >/dev/null 2>&1; return ;;
      shortcuts) shortcuts ;;
      quit|q|exit) ( eval "$clean" ) >/dev/null 2>&1; printf '  bye! Continue later with: bash lab.sh next\n'; exit 0 ;;
      edit\ *|nano\ *|vi\ *|vim\ *) ( eval "$line" ) <&3 ;;
      *) out=$( ( eval "$line" ) <&3 2>&1 ); show_out "$out" ;;
    esac
  done
}
interview() { exam INTERVIEW "$BG_M" "$@"; }
final()     { exam FINAL "$BG_W" "$@"; }

# qa "question" 'regex of a correct answer' "model answer": a scored spoken-interview question.
# Wrong answers do not block; qa_need N requires at least N correct answers in the block.
QA_OK=0; QA_N=0
qa() {
  local a; QA_N=$((QA_N+1))
  if [ -n "$AUTO" ]; then
    if printf '%s' "$3" | grep -Eiq "$2"; then QA_OK=$((QA_OK+1)); pass; else fail "(model answer does not match its own pattern)"; fi
    return 0
  fi
  badge "QUESTION" "$BG_M" "$1"
  printf '  %s🎤 Your answer ▸ %s' "$MAG" "$RST"; read -r a <&3 || exit 0
  if [ "$(printf '%s' "$a" | wc -w | tr -d ' ')" -ge 3 ] && printf '%s' "$a" | grep -Eiq "$2"; then QA_OK=$((QA_OK+1)); PASS=$((PASS+1)); printf '  %s✔ Good.%s  A strong answer also says: %s\n' "$GRN" "$RST" "$3"
  else printf '  %s✘ Not quite (a one-word answer or a different angle).%s  Model answer: %s\n' "$YEL" "$RST" "$3"; fi
}
qa_need() {
  local need="$1"
  if [ "$QA_OK" -ge "$need" ]; then printf '\n  %s✔ Interview round passed:%s %d of %d answers were strong (needed %d).\n' "$GRN" "$RST" "$QA_OK" "$QA_N" "$need"
  else FAIL=$((FAIL+1)); printf '\n  %s ✘ NOT YET %s %d of %d answers were strong, you need %d. Re-read the model answers above and retry this module.\n' "$BG_R" "$RST" "$QA_OK" "$QA_N" "$need"; fi
  QA_OK=0; QA_N=0
}

# ---------- XP, diagrams, missions, multiple choice ----------
XPFILE=.xp
xp_total() { cat "$XPFILE" 2>/dev/null || echo 0; }
xp_level() { echo $(( $(xp_total) / 150 + 1 )); }
xp_add() { [ -n "$AUTO" ] && return 0; echo $(( $(xp_total) + $1 )) > "$XPFILE"; printf ' %s+%d XP%s' "$YEL" "$1" "$RST"; }

# deeper "label|url" ...: optional further practice on a public repo (never required, never blocks)
deeper() {
  local a
  printf '\n  %s┌─ GO DEEPER (optional): same skill, on someone else'"'"'s project%s\n' "$GRN" "$RST"
  for a in "$@"; do printf '  %s│%s %s\n  %s│%s   %s%s%s\n' "$GRN" "$RST" "${a%%|*}" "$GRN" "$RST" "$DIM" "${a#*|}" "$RST"; done
  printf '  %s└%s%s\n' "$GRN" "$(rep ─ 40)" "$RST"
}

# art "caption" <<'X' ... X : a framed diagram
art() {
  local line; printf '\n  %s┌─ %s%s\n' "$CYN" "$1" "$RST"
  while IFS= read -r line; do printf '  %s│%s %s%s%s\n' "$CYN" "$RST" "$CYN$BOLD" "$line" "$RST"; done
  printf '  %s└%s%s\n' "$CYN" "$(rep ─ 40)" "$RST"
}

# row COLOR "text": one padded line of a multi-line box
_row() {
  local len pad; len=$(printf '%s' "$2" | LC_ALL=C tr -d '\200-\277' | wc -c); pad=$(( W - 4 - len )); [ "$pad" -lt 0 ] && pad=0
  printf '%s║ %s%*s ║%s\n' "$1" "$2" "$pad" '' "$RST"
}
# mission "story": the situation you are in, shown as a box at the start of a module
mission() {
  local c="$BOLD$MAG" line
  printf '\n%s╔%s╗%s\n' "$c" "$(rep ═ $((W-2)))" "$RST"
  _row "$c" "MISSION"
  while IFS= read -r line; do _row "$c" "$line"; done < <(printf '%s\n' "$1" | fold -s -w $((W-6)))
  printf '%s╚%s╝%s\n' "$c" "$(rep ═ $((W-2)))" "$RST"
}

# mcq / predict "question" "option 1|option 2|option 3" CORRECT_NUMBER "why": a one-key question, never blocks
_choose() {
  local kind="$1" q="$2" opts="$3" ans="$4" why="$5" a i n=0 o
  [ -n "$AUTO" ] && return 0
  local IFS='|'; local arr=($opts); IFS=' '
  if [ "$kind" = PREDICT ]; then printf '\n %s PREDICT %s %s%s%s\n' "$BG_Y" "$RST" "$BOLD" "$q" "$RST"
  else printf '\n %s QUICK CHECK %s %s%s%s\n' "$BG_C" "$RST" "$BOLD" "$q" "$RST"; fi
  for o in "${arr[@]}"; do n=$((n+1)); printf '    %s%d)%s %s\n' "$BOLD" "$n" "$RST" "$o"; done
  printf '  %sPress a number ▸ %s' "$YEL" "$RST"; read -r a <&3 || exit 0
  if [ "$a" = "$ans" ]; then printf '  %s✔ Correct!%s' "$GRN" "$RST"; xp_add 5; printf '  %s\n' "$why"
  else printf '  %s✘ Not quite.%s The answer is %s) %s. %s\n' "$YEL" "$RST" "$ans" "${arr[$((ans-1))]}" "$why"; fi
  return 0
}
mcq()     { _choose CHECK "$@"; }
predict() { _choose PREDICT "$@"; }

trophy() {
  printf '%s' "$YEL$BOLD"
  cat <<'ART'
            ___________
           '._==_==_=_.'
           .-\:      /-.
          | (|:.     |) |
           '-|:.     |-'
             \::.    /
              '::. .'
                ) (
              _.' '._
             `"""""""`
ART
  printf '%s' "$RST"
}

# roadmap: the whole course as a map you can see at a glance
roadmap() {
  local f id st n=0 label
  printf '\n  %sYOUR ROADMAP%s   XP %s%d%s  Level %s%d%s\n' "$BOLD" "$RST" "$YEL" "$(xp_total)" "$RST" "$CYN" "$(xp_level)" "$RST"
  printf '  %s✔ done   ◐ lessons done   ● open now   🔒 locked%s\n' "$DIM" "$RST"
  local group
  for f in lessons/*.sh; do
    id=$(basename "$f" | cut -c1-2)
    case "$((10#$id))" in 0) group="START HERE: Git from zero" ;; 1) group="THE CORE PATH" ;; 12) group="SPECIALIST TRACKS" ;; 18) group="JOB-READY EXTRAS" ;; *) group="" ;; esac
    [ -n "$group" ] && { printf '\n  %s%s%s\n  ' "$BOLD$CYN" "$group" "$RST"; n=0; }
    if has "$id"; then st="${GRN}✔${RST}"; elif has "$id.learn"; then st="${YEL}◐${RST}"; elif gate_ok "$id"; then st="${BOLD}●${RST}"; else st="${DIM}🔒${RST}"; fi
    label=$(sed -n '1s/^# *//p' "$f" | sed 's/[:(].*//' | cut -c1-14)
    printf '[%s %s %-13s] ' "$st" "$id" "$label"
    n=$((n+1)); [ $((n % 3)) -eq 0 ] && printf '\n  '
  done
  printf '\n\n'
}

# quiz "question" 'regex of a correct answer' "model answer"
quiz() {
  [ -n "$AUTO" ] && return 0
  local a; badge "QUIZ" "$BG_M" "$1"
  printf '  %sYour answer ▸ %s' "$MAG" "$RST"; read -r a <&3
  if printf '%s' "$a" | grep -Eiq "$2"; then printf '  %s✔ Good.%s %s\n' "$GRN" "$RST" "$3"
  else printf '  %sCompare with this:%s %s\n' "$YEL" "$RST" "$3"; fi
}

mark() { grep -qx "$1" "$PROGRESS" 2>/dev/null || echo "$1" >> "$PROGRESS"; }
has()  { grep -qx "$1" "$PROGRESS" 2>/dev/null; }

# part_summary ID "label": prints the result box for one part (lessons, or interview + final)
part_summary() {
  local n msg c; n=$(done_count)
  if [ "$FAIL" -eq 0 ] && [ "$SKIP" -eq 0 ]; then msg="$2 complete."; c="$BOLD$GRN"
  elif [ "$FAIL" -gt 0 ]; then msg="$2: needs more work."; c="$BOLD$RED"
  else msg="$2 not finished (items skipped)."; c="$BOLD$YEL"; fi
  printf '\n'; box "$c" "Module $1 · $msg"
  printf '  %s%s summary:%s %s%d passed%s   %s%d failed%s   %s%d skipped%s\n' "$BOLD" "$1" "$RST" "$GRN" "$PASS" "$RST" "$RED" "$FAIL" "$RST" "$YEL" "$SKIP" "$RST"
  printf '  Overall  %s  %d/%d modules   Rank: %s%s%s   XP %s%d%s (level %d)\n' "$(bar "$n" "$LESSONS")" "$n" "$LESSONS" "$BOLD" "$(rank "$n")" "$RST" "$YEL" "$(xp_total)" "$RST" "$(xp_level)"
  [ "$SKIP" -gt 0 ] && printf '  %sSkipped items do not count. Run  bash lab.sh %s  again to finish them.%s\n' "$YEL" "$1" "$RST"
  return 0
}

lesson_file()  { ls lessons/"$1"-*.sh 2>/dev/null | head -1; }
lesson_title() { sed -n '1s/^# *//p' "$1"; }

menu() {
  local f id mark n; n=$(done_count)
  printf '\n'; banner; printf '\n'
  for f in lessons/*.sh; do
    id=$(basename "$f" | cut -c1-2)
    if has "$id"; then mark="${GRN}✔${RST}"
    elif has "$id.learn"; then mark="${YEL}◐${RST}"
    elif ! gate_ok "$id"; then mark="${DIM}🔒${RST}"
    else mark="${DIM}○${RST}"; fi
    printf '   %s  %s%s%s  %s\n' "$mark" "$BOLD" "$id" "$RST" "$(lesson_title "$f")"
  done
  printf '\n   Progress  %s  %d/%d      Rank: %s%s%s   XP %s%d%s  Level %d\n' "$(bar "$n" "$LESSONS" 30)" "$n" "$LESSONS" "$BOLD$CYN" "$(rank "$n")" "$RST" "$YEL" "$(xp_total)" "$RST" "$(xp_level)"
  printf '\n   %s✔ complete   ◐ lessons done, exam pending   🔒 locked until its prerequisite module is passed%s\n' "$DIM" "$RST"
  printf '   %sbash lab.sh 00%s start (continues by itself)   %sbash lab.sh next%s resume   %sbash lab.sh final 05%s retake an exam   %sbash lab.sh down%s stop all\n' "$DIM" "$RST" "$DIM" "$RST" "$DIM" "$RST" "$DIM" "$RST"
}

# Which module must be passed before this one unlocks. Core path: the previous number.
# Extra modules open earlier: Linux admin and Git collaboration after 00, Secrets after 03,
# Kubernetes advanced after 06, Ship-it-for-real and Interview prep after the core path (11).
prereq_of() {
  case "$((10#$1))" in
    01) echo 00 ;;
    18) echo 01 ;;
    19) echo 00 ;;
    24) echo 12 ;;
    20) echo 03 ;;
    21) echo 06 ;;
    22|23) echo 11 ;;
    *) printf '%02d' "$((10#$1 - 1))" ;;
  esac
}
gate_ok() { # a module unlocks when its prerequisite is complete (not enforced in auto-test mode)
  [ -n "$AUTO" ] || [ -n "${LAB_SKIPGATE:-}" ] && return 0
  [ "$((10#$1))" -le 0 ] && return 0
  has "$(prereq_of "$1")"
}

run_lesson() {
  local id="$1" f ff ok
  f=$(lesson_file "$id"); ff="finals/$id.sh"
  [ -z "$f" ] && { echo "No lesson '$id'. Try: bash lab.sh"; exit 1; }
  if ! gate_ok "$id"; then
    printf '\n  %s🔒 Module %s is locked.%s Pass module %s (lessons, interview and final) first:  bash lab.sh %s\n' "$BOLD" "$id" "$RST" "$(prereq_of "$id")" "$(prereq_of "$id")"
    return 1
  fi
  [ -f .env ] || cp .env.example .env
  if [ -z "$AUTO" ] && [ "$MODE" = type ]; then printf '\n  %sHow this works:%s you LEARN a little, then DO it (you type). ?=hint  run=let the lab run it  skip  shortcuts  quit\n' "$BOLD" "$RST"; fi

  # ---- part 1: the lessons (learn, do, learn, do ...) ----
  if [ -z "${ONLY_FINAL:-}" ] && { [ -n "$AUTO" ] || ! has "$id.learn"; }; then
    PASS=0; FAIL=0; SKIP=0; CUR=0; TOTAL=$(grep -cE '^(OPT=1 )?(step|task|quiz|qa) ' "$f")
    # shellcheck disable=SC1090
    . "$f"
    part_summary "$id" "Lessons"
    if [ "$FAIL" -eq 0 ] && [ "$SKIP" -eq 0 ]; then mark "$id.learn"; else return 1; fi
  elif [ -z "${ONLY_FINAL:-}" ]; then
    printf '\n  %s✔ The lessons of module %s are already done.%s Going straight to the interview and final.\n' "$GRN" "$id" "$RST"
  fi

  # ---- part 2: interview + module final ----
  ok=1
  if [ -f "$ff" ]; then
    PASS=0; FAIL=0; SKIP=0; CUR=0; TOTAL=$(grep -cE '^(interview|final|qa) ' "$ff")
    printf '\n'; box "$BOLD$MAG" "Module $id · INTERVIEW and FINAL: show me, do not just tell me"
    explain "No more step-by-step help. The interviewer describes a situation, you fix or build it at the lab prompt, then type check. There is no answer key and every item must pass to unlock the next module. You may use  hint  and look things up."
    # shellcheck disable=SC1090
    . "$ff"
    part_summary "$id" "Interview and final"
    if [ "$FAIL" -eq 0 ] && [ "$SKIP" -eq 0 ]; then mark "$id.final"; else ok=0; fi
  else
    mark "$id.final"
  fi
  [ "$ok" -eq 1 ] || return 1
  mark "$id"
  printf '\n'; box "$BOLD$GRN" "★ MODULE $id COMPLETE ★  Rank: $(rank "$(done_count)")"
  [ -z "$AUTO" ] && trophy
  [ -z "$AUTO" ] && [ "$(done_count)" -lt "$LESSONS" ] && printf '  %sThe next module is now unlocked.%s\n' "$GRN" "$RST"
  return 0
}

first_incomplete() {
  local f id
  for f in lessons/*.sh; do id=$(basename "$f" | cut -c1-2); grep -qx "$id" "$PROGRESS" 2>/dev/null || { echo "$id"; return; }; done
}

# Run a lesson, then move straight on to the next one (stay in this terminal until you quit).
flow() {
  local id="$1" nxt a
  while [ -n "$(lesson_file "$id")" ]; do
    if run_lesson "$id"; then
      nxt=$(printf '%02d' "$((10#$id + 1))")
      if [ -z "$(lesson_file "$nxt")" ]; then
        printf '\n'; box "$BOLD$GRN" "★ YOU FINISHED EVERY LESSON ★   Rank: $(rank "$LESSONS")"
        printf '  Run  bash lab.sh down  to stop everything.\n'; return
      fi
      [ -n "$AUTO" ] && return
      printf '\n%s➜ Lesson %s done!%s Press Enter to start lesson %s (type q to quit) ▸ ' "$BOLD$GRN" "$id" "$RST" "$nxt"
      read -r a <&3; [ "$a" = q ] && return
      id="$nxt"
    else
      [ -n "$AUTO" ] && return
      gate_ok "$id" || return
      printf '\n%sModule %s is not passed yet.%s Press Enter to try it again (type q to quit) ▸ ' "$YEL" "$id" "$RST"
      read -r a <&3; [ "$a" = q ] && return
    fi
  done
}

case "${1:-menu}" in
  menu|list) menu
    if [ -z "$AUTO" ]; then
      nxt=$(first_incomplete); [ -z "$nxt" ] && nxt=00
      printf '\n  Type a lesson number, or press Enter to continue with lesson %s (q to quit) ▸ ' "$nxt"; read -r n <&3
      if [ "$n" = q ]; then :
      elif [ -z "$n" ]; then flow "$nxt"
      elif [[ "$n" =~ ^[0-9]+$ ]]; then flow "$(printf '%02d' "$((10#$n))")"
      else echo "Please type a lesson number like 1 or 01."; fi
    fi ;;
  status) menu ;;
  down)
    # one 'down' that knows every compose file used by the lessons (app, monitoring, logging, postgres)
    docker compose -f 03-compose/docker-compose.yml -f 08-observability/compose.observability.yml -f 15-logging/compose.logging.yml -f 16-postgres/compose.postgres.yml --env-file .env down --remove-orphans 2>&1 | tail -3
    docker rm -f lab-redis lab-jenkins lab-fw lab-secret lab-bastion lab-origin lab-edge my-nginx my-page lab-api lab-tls lab-a lab-b lab-lb lab-linux lab-vault vault-api exam-vault-api exam-api exam-a exam-b exam-db port-squatter >/dev/null 2>&1; docker network rm lab-net exam-net lab-fw-net lab-pub lab-priv lab-cdn-net >/dev/null 2>&1
    bash 06-kubernetes/cluster.sh down 2>/dev/null
    docker compose -f 05-terraform/compose.localstack.yml down 2>&1 | tail -1
    docker compose -f 13-ansible/compose.yml down 2>&1 | tail -1 ;;
  reset) rm -f "$PROGRESS" "$XPFILE"; echo "progress cleared" ;;
  map|roadmap) roadmap ;;
  feedback)
    printf '\n%sLab feedback%s\n' "$BOLD" "$RST"
    printf '  Tell us what was confusing, broken, too easy or too hard. It makes the lab better for everyone.\n'
    printf '  1. Open:  https://github.com/%s/issues/new?template=feedback.yml\n' "$(gh_repo)"
    printf '  2. Paste this summary of your progress:\n\n'
    printf '     modules complete: %s of %s\n' "$(done_count)" "$LESSONS"
    printf '     completed: %s\n' "$(grep -E '^[0-9][0-9]$' "$PROGRESS" 2>/dev/null | tr '\n' ' ')"
    printf '     computer: %s, docker %s\n\n' "${OSTYPE:-unknown}" "$(docker --version 2>/dev/null | sed 's/Docker version //; s/,.*//')" ;;
  final) ONLY_FINAL=1 run_lesson "$(printf '%02d' "$((10#${2:-1}))")" ;;
  next|continue) nxt=$(first_incomplete); [ -z "$nxt" ] && { echo "All lessons are done."; exit 0; }; flow "$nxt" ;;
  [0-9]*) if [ -n "$AUTO" ]; then run_lesson "$(printf '%02d' "$((10#$1))")"; else flow "$(printf '%02d' "$((10#$1))")"; fi ;;
  *) echo "usage: bash lab.sh [menu|NN|next|final NN|map|status|feedback|down|reset]"; exit 1 ;;
esac
