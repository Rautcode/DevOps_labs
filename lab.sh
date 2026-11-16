#!/usr/bin/env bash
# Guided lab runner. Walks you through each module: explains, runs commands for you,
# gives hands-on tasks and checks your work. Run from the repo root in Git Bash:
#   bash lab.sh            menu
#   bash lab.sh 01         start lesson 01
#   bash lab.sh status     your progress
#   bash lab.sh down       stop everything the labs started
#   bash lab.sh reset      forget progress
# Maintainers: LAB_AUTO=run|solve bash lab.sh 01   (non-interactive; solve also performs the tasks)
set -u
cd "$(dirname "$0")" || exit 1
export MSYS_NO_PATHCONV=1
export DC="docker compose -f 03-compose/docker-compose.yml --env-file .env"
export DCO="docker compose -f 03-compose/docker-compose.yml -f 08-observability/compose.observability.yml --env-file .env"
export KUBECONFIG="$(pwd -W 2>/dev/null || pwd)/.kube/config"
AUTO="${LAB_AUTO:-}"
PROGRESS=.progress
PASS=0; FAIL=0; SKIP=0
B=$'\033[1m'; G=$'\033[32m'; R=$'\033[31m'; Y=$'\033[33m'; C=$'\033[36m'; D=$'\033[2m'; N=$'\033[0m'
mkdir -p playground
# Read keyboard input from the terminal if there is one, otherwise from stdin (lets you pipe answers in).
if [ -z "$AUTO" ] && ( : </dev/tty ) 2>/dev/null; then exec 3</dev/tty; else exec 3<&0; fi

ask()     { [ -n "$AUTO" ] && return 0; read -r -p "$1" _ <&3; }
title()   { printf '\n%s━━ %s ━━%s\n' "$B$C" "$1" "$N"; }
part()    { printf '\n%s%s%s\n' "$B" "$1" "$N"; }
explain() { printf '%s\n' "$1" | fold -s -w 88 | sed 's/^/  /'; }
pass()    { PASS=$((PASS+1)); printf '  %s✔ PASS%s\n' "$G" "$N"; }
fail()    { FAIL=$((FAIL+1)); printf '  %s✘ FAIL%s %s\n' "$R" "$N" "${1:-}"; }

# step "what this does" "what to look for" [fail] <<'CMD' ... CMD
step() {
  local cmd rc; cmd=$(cat)
  part "▶ $1"
  printf '%s%s%s\n' "$D" "$(printf '%s' "$cmd" | sed 's/^/  $ /')" "$N"
  ask "  [Enter = run it] "
  ( eval "$cmd" ) 2>&1 | sed 's/^/  │ /'; rc=${PIPESTATUS[0]}
  [ -n "${2:-}" ] && printf '  %sLook for:%s %s\n' "$Y" "$N" "$2"
  if [ -n "$AUTO" ]; then
    if [ "${3:-ok}" = fail ]; then [ "$rc" -ne 0 ] && pass || fail "(expected this command to fail)"
    else [ "$rc" -eq 0 ] && pass || fail "(command exited $rc)"; fi
  fi
}

# task "goal" "how to do it" "hint" <<'X' ... check command ... \n---\n ... solution command ... X
task() {
  local all check sol a; all=$(cat)
  check=${all%%$'\n---\n'*}; sol=${all#*$'\n---\n'}
  part "✋ YOUR TURN: $1"; explain "$2"
  if [ -n "$AUTO" ]; then
    [ "$AUTO" = solve ] && ( eval "$sol" ) >/dev/null 2>&1
    if ( eval "$check" ) >/dev/null 2>&1; then pass; else fail "(task check)"; fi
    return
  fi
  while true; do
    read -r -p "  Do it in ANOTHER terminal, then press Enter to check (s = skip, h = show answer): " a <&3
    case "$a" in
      s) SKIP=$((SKIP+1)); printf '  %sskipped%s\n' "$Y" "$N"; return ;;
      h) printf '  %sAnswer:%s\n%s\n' "$Y" "$N" "$(printf '%s' "$sol" | sed 's/^/    $ /')"; continue ;;
    esac
    if ( eval "$check" ) >/dev/null 2>&1; then pass; return; fi
    printf '  %s✘ Not yet.%s Hint: %s\n' "$R" "$N" "${3:-read the instructions again}"
  done
}

# quiz "question" 'regex of a correct answer' "model answer"
quiz() {
  [ -n "$AUTO" ] && return 0
  local a; part "❓ $1"
  read -r -p "  Your answer: " a <&3
  if printf '%s' "$a" | grep -Eiq "$2"; then printf '  %s✔ Good.%s %s\n' "$G" "$N" "$3"
  else printf '  %sCompare with this:%s %s\n' "$Y" "$N" "$3"; fi
}

finish() {
  printf '\n%s%s lesson summary:%s %s%d passed%s, %s%d failed%s, %d skipped\n' "$B" "$1" "$N" "$G" "$PASS" "$N" "$R" "$FAIL" "$N" "$SKIP"
  if [ "$FAIL" -eq 0 ] && [ "$SKIP" -eq 0 ]; then
    grep -qx "$1" "$PROGRESS" 2>/dev/null || echo "$1" >> "$PROGRESS"
    printf '%sLesson %s complete.%s\n' "$G" "$1" "$N"
  elif [ "$SKIP" -gt 0 ]; then
    printf '%sYou skipped %d task(s). Run  bash lab.sh %s  again to finish them and earn the tick.%s\n' "$Y" "$SKIP" "$1" "$N"
  fi
}

lesson_file() { ls lessons/"$1"-*.sh 2>/dev/null | head -1; }
lesson_title() { sed -n '1s/^# *//p' "$1"; }

menu() {
  printf '%s\n  DevOps & Cloud Lab: guided mode%s\n\n' "$B" "$N"
  local f id mark
  for f in lessons/*.sh; do
    id=$(basename "$f" | cut -c1-2)
    mark=" "; grep -qx "$id" "$PROGRESS" 2>/dev/null && mark="${G}✔${N}"
    printf '  [%s] %s  %s\n' "$mark" "$id" "$(lesson_title "$f")"
  done
  printf '\n  Start one:  bash lab.sh 01      Stop everything:  bash lab.sh down\n'
}

run_lesson() {
  local f; f=$(lesson_file "$1")
  [ -z "$f" ] && { echo "No lesson '$1'. Try: bash lab.sh"; exit 1; }
  [ -f .env ] || cp .env.example .env
  PASS=0; FAIL=0; SKIP=0
  # shellcheck disable=SC1090
  . "$f"
  finish "$1"
  [ "$FAIL" -eq 0 ]
}

case "${1:-menu}" in
  menu|list) menu
    if [ -z "$AUTO" ]; then read -r -p $'\n  Lesson number to start (Enter to quit): ' n <&3; [ -n "$n" ] && run_lesson "$(printf '%02d' "$((10#$n))")"; fi ;;
  status) menu ;;
  down)
    $DCO down 2>&1 | tail -2; docker rm -f evio-k3s lab-api >/dev/null 2>&1; docker rm -f devlab-k3s >/dev/null 2>&1
    bash 06-kubernetes/cluster.sh down 2>/dev/null; docker compose -f 05-terraform/compose.localstack.yml down 2>&1 | tail -1 ;;
  reset) rm -f "$PROGRESS"; echo "progress cleared" ;;
  [0-9]*) run_lesson "$(printf '%02d' "$((10#$1))")" ;;
  *) echo "usage: bash lab.sh [menu|NN|status|down|reset]"; exit 1 ;;
esac
