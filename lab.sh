#!/usr/bin/env bash
# Guided lab runner. Walks you through each module: explains, runs commands for you,
# gives hands-on tasks and checks your work. Run from the repo root in Git Bash:
#   bash lab.sh            menu (press Enter to continue where you left off)
#   bash lab.sh 01         start lesson 01 (continues to the next lesson by itself)
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
export KUBECONFIG="$(pwd -W 2>/dev/null || pwd)/.kube/config"
AUTO="${LAB_AUTO:-}"
PROGRESS=.progress
PASS=0; FAIL=0; SKIP=0; CUR=0; TOTAL=0
LESSONS=$(ls lessons/*.sh 2>/dev/null | wc -l | tr -d " ")
W=78
mkdir -p playground
# Read keyboard input from the terminal if there is one, otherwise from stdin (lets you pipe answers in).
if [ -z "$AUTO" ] && ( : </dev/tty ) 2>/dev/null; then exec 3</dev/tty; else exec 3<&0; fi

# ---------- look and feel ----------
if [ -n "${NO_COLOR:-}" ]; then
  BOLD=; DIM=; RED=; GRN=; YEL=; BLU=; MAG=; CYN=; RST=; BG_G=; BG_R=; BG_Y=; BG_C=; BG_M=; BG_B=
else
  BOLD=$'\033[1m'; DIM=$'\033[2m'; RED=$'\033[31m'; GRN=$'\033[32m'; YEL=$'\033[33m'
  BLU=$'\033[34m'; MAG=$'\033[35m'; CYN=$'\033[36m'; RST=$'\033[0m'
  BG_G=$'\033[42;30;1m'; BG_R=$'\033[41;97;1m'; BG_Y=$'\033[43;30;1m'; BG_C=$'\033[46;30;1m'; BG_M=$'\033[45;97;1m'; BG_B=$'\033[44;97;1m'
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
pass()    { PASS=$((PASS+1)); printf '  %s ✔ PASS %s\n' "$BG_G" "$RST"; }
fail()    { FAIL=$((FAIL+1)); printf '  %s ✘ FAIL %s %s\n' "$BG_R" "$RST" "${1:-}"; }

# step "what this does" "what to look for" [ok|fail] ["regex the output must match (checked in auto mode)"] <<'CMD' ... CMD
step() {
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
task() {
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

# quiz "question" 'regex of a correct answer' "model answer"
quiz() {
  [ -n "$AUTO" ] && return 0
  local a; badge "QUIZ" "$BG_M" "$1"
  printf '  %sYour answer ▸ %s' "$MAG" "$RST"; read -r a <&3
  if printf '%s' "$a" | grep -Eiq "$2"; then printf '  %s✔ Good.%s %s\n' "$GRN" "$RST" "$3"
  else printf '  %sCompare with this:%s %s\n' "$YEL" "$RST" "$3"; fi
}

finish() {
  local n msg c; n=$(done_count)
  if [ "$FAIL" -eq 0 ] && [ "$SKIP" -eq 0 ]; then
    grep -qx "$1" "$PROGRESS" 2>/dev/null || echo "$1" >> "$PROGRESS"; n=$(done_count)
    msg="Lesson $1 complete."; c="$BOLD$GRN"
  elif [ "$FAIL" -gt 0 ]; then msg="Lesson $1 needs more work."; c="$BOLD$RED"
  else msg="Lesson $1 not finished (tasks skipped)."; c="$BOLD$YEL"; fi
  printf '\n'
  box "$c" "$msg"
  printf '  %s lesson summary:%s %s%d passed%s   %s%d failed%s   %s%d skipped%s\n' "$BOLD$1" "$RST" "$GRN" "$PASS" "$RST" "$RED" "$FAIL" "$RST" "$YEL" "$SKIP" "$RST"
  printf '  Overall  %s  %d/%d lessons   Rank: %s%s%s\n' "$(bar "$n" "$LESSONS")" "$n" "$LESSONS" "$BOLD" "$(rank "$n")" "$RST"
  [ "$SKIP" -gt 0 ] && printf '  %sRun  bash lab.sh %s  again to finish the skipped tasks and earn the tick.%s\n' "$YEL" "$1" "$RST"
}

lesson_file()  { ls lessons/"$1"-*.sh 2>/dev/null | head -1; }
lesson_title() { sed -n '1s/^# *//p' "$1"; }

menu() {
  local f id mark n; n=$(done_count)
  printf '\n'; banner; printf '\n'
  for f in lessons/*.sh; do
    id=$(basename "$f" | cut -c1-2)
    if grep -qx "$id" "$PROGRESS" 2>/dev/null; then mark="${GRN}✔${RST}"; else mark="${DIM}○${RST}"; fi
    printf '   %s  %s%s%s  %s\n' "$mark" "$BOLD" "$id" "$RST" "$(lesson_title "$f")"
  done
  printf '\n   Progress  %s  %d/%d      Rank: %s%s%s\n' "$(bar "$n" "$LESSONS" 30)" "$n" "$LESSONS" "$BOLD$CYN" "$(rank "$n")" "$RST"
  printf '\n   %sbash lab.sh 01%s start (continues by itself)   %sbash lab.sh next%s resume   %sbash lab.sh down%s stop all\n' "$DIM" "$RST" "$DIM" "$RST" "$DIM" "$RST"
}

run_lesson() {
  local f; f=$(lesson_file "$1")
  [ -z "$f" ] && { echo "No lesson '$1'. Try: bash lab.sh"; exit 1; }
  [ -f .env ] || cp .env.example .env
  PASS=0; FAIL=0; SKIP=0; CUR=0; TOTAL=$(grep -cE '^(OPT=1 )?(step|task|quiz) ' "$f")
  # shellcheck disable=SC1090
  . "$f"
  finish "$1"
  [ "$FAIL" -eq 0 ] && [ "$SKIP" -eq 0 ]
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
      printf '\n%sLesson %s is not finished yet.%s Press Enter to try it again (type q to quit) ▸ ' "$YEL" "$id" "$RST"
      read -r a <&3; [ "$a" = q ] && return
    fi
  done
}

case "${1:-menu}" in
  menu|list) menu
    if [ -z "$AUTO" ]; then
      nxt=$(first_incomplete); [ -z "$nxt" ] && nxt=01
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
    docker rm -f lab-api lab-tls lab-a lab-b lab-lb >/dev/null 2>&1; docker network rm lab-net >/dev/null 2>&1
    bash 06-kubernetes/cluster.sh down 2>/dev/null
    docker compose -f 05-terraform/compose.localstack.yml down 2>&1 | tail -1
    docker compose -f 13-ansible/compose.yml down 2>&1 | tail -1 ;;
  reset) rm -f "$PROGRESS"; echo "progress cleared" ;;
  next|continue) nxt=$(first_incomplete); [ -z "$nxt" ] && { echo "All lessons are done."; exit 0; }; flow "$nxt" ;;
  [0-9]*) if [ -n "$AUTO" ]; then run_lesson "$(printf '%02d' "$((10#$1))")"; else flow "$(printf '%02d' "$((10#$1))")"; fi ;;
  *) echo "usage: bash lab.sh [menu|NN|next|status|down|reset]"; exit 1 ;;
esac
