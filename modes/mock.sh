# Mock interview mode (sourced by lab.sh):  bash lab.sh mock [NN]
# Asks random questions taken from INTERVIEW-ANSWERS.md, then shows the model answer and lets you rate yourself.
# Questions you miss come back more often. Scores are kept in .mockstats (git-ignored).
MOCKSTATS="${LAB_STATS:-.mockstats}"

# answers_tsv [NN]: one line per answer: module <TAB> question <TAB> answer
answers_tsv() {
  awk -v M="${1:-}" '
    function flush() { if (q != "" && a != "" && (M == "" || M == mod)) print mod "\t" q "\t" a; q = ""; a = "" }
    /^## Module [0-9][0-9]/ { flush(); split($0, w, " "); mod = w[3]; next }
    /^###? / { flush(); next }
    /^\*\*If asked:\*\*/ { flush(); q = $0; sub(/^\*\*If asked:\*\* */, "", q); next }
    /^> / { if (q != "") { t = substr($0, 3); a = (a == "" ? t : a " " t) } ; next }
    END { flush() }' INTERVIEW-ANSWERS.md
}

# recap_questions NN: shown when you finish a module, so you see what you can now say in an interview
recap_questions() {
  local qs; qs=$(answers_tsv "$1" | cut -f2 | head -3)
  [ -z "$qs" ] && return 0
  printf '\n  %sYou can now answer, out loud, questions like:%s\n' "$BOLD" "$RST"
  printf '%s\n' "$qs" | sed "s/^/    ${CYN}?${RST} /"
  printf '  %sPractise them:  bash lab.sh mock %s%s\n' "$DIM" "$1" "$RST"
}

mock_id() { printf '%s' "$1" | cksum | cut -d' ' -f1; }
mock_last() { [ -f "$MOCKSTATS" ] && grep "^$1|" "$MOCKSTATS" | tail -1 | cut -d'|' -f2; }

mock_main() {
  local filter="${1:-}" n=5 total=0 i k pick r acc got=0 part=0 miss=0 ans rate id last sc
  local -a mods qs as ws missed
  [ -n "$filter" ] && filter=$(printf '%02d' "$((10#$filter))")
  while IFS=$'\t' read -r m q a; do
    mods+=("$m"); qs+=("$q"); as+=("$a")
    id=$(mock_id "$q"); last=$(mock_last "$id")
    case "$last" in 0) sc=5 ;; 1) sc=3 ;; 2) sc=1 ;; *) sc=3 ;; esac   # missed questions come back most often, known ones least
    ws+=("$sc"); total=$((total + sc))
  done < <(answers_tsv "$filter")
  [ "${#qs[@]}" -eq 0 ] && { echo "No interview answers found${filter:+ for module $filter}."; return 1; }
  if [ -n "$AUTO" ]; then printf 'mock: %d questions available\n' "${#qs[@]}"; return 0; fi
  [ "${#qs[@]}" -lt "$n" ] && n=${#qs[@]}

  printf '\n'; box "$BOLD$MAG" "MOCK INTERVIEW${filter:+ · module $filter} · $n questions · 60 seconds each"
  printf '  %sAnswer out loud, or type a few key words, then press Enter. Be honest when you rate yourself: it decides which questions come back.%s\n' "$DIM" "$RST"
  for ((i = 1; i <= n; i++)); do
    r=$(( (RANDOM * 32768 + RANDOM) % total )); pick=0; acc=0
    for ((k = 0; k < ${#qs[@]}; k++)); do acc=$((acc + ws[k])); if [ "$r" -lt "$acc" ]; then pick=$k; break; fi; done
    total=$((total - ws[pick])); ws[pick]=0
    printf '\n%s Q%d/%d %s %sModule %s%s\n' "$BG_M" "$i" "$n" "$RST" "$DIM" "${mods[pick]}" "$RST"
    printf '  %s🎤 %s%s\n' "$BOLD" "${qs[pick]}" "$RST"
    printf '  %sYour answer (60 seconds) ▸ %s' "$MAG" "$RST"
    if read -r -t 60 ans <&3; then :; else [ $? -gt 128 ] && printf '\n  %s⏱ Time is up.%s\n' "$YEL" "$RST" || { echo; exit 0; }; fi
    printf '  %sModel answer:%s\n' "$BOLD$GRN" "$RST"; explain "${as[pick]}"
    while true; do
      printf '  %sDid you cover the main points?%s  y = yes   p = partly   n = not really ▸ ' "$BOLD" "$RST"; read -r rate <&3 || exit 0
      rate=$(printf '%s' "$rate" | tr -d '[:space:]' | tr 'A-Z' 'a-z')
      case "$rate" in y) sc=2; got=$((got+1)); xp_add 5; break ;; p) sc=1; part=$((part+1)); xp_add 2; break ;; n) sc=0; miss=$((miss+1)); missed+=("${mods[pick]}"); break ;; esac
    done
    printf '\n'
    echo "$(mock_id "${qs[pick]}")|$sc|$(date +%F)|${mods[pick]}" >> "$MOCKSTATS"
  done
  printf '\n'; box "$BOLD$GRN" "Round done: $got covered, $part partly, $miss missed"
  if [ "${#missed[@]}" -gt 0 ]; then
    printf '  %sRe-read these modules, then try again:%s' "$YEL" "$RST"
    printf '%s\n' "${missed[@]}" | sort -u | while read -r m; do printf '  bash lab.sh %s ' "$m"; done; printf '\n'
  fi
  printf '  %sAnother round: bash lab.sh mock%s\n' "$DIM" "$RST"
}
