# Progress report (sourced by lab.sh):  bash lab.sh report
# Writes playground/report.html: your level, modules, incident times, mock-interview results and
# a ready-to-edit list of résumé bullets for the modules you finished. One self-contained file, light and dark mode.

html_esc() { sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g'; }

report_main() {
  local out=playground/report.html f id state cls label n=0 done_n xp lvl pct rank_t inc_n=0 mock_n=0 mock_got=0 b
  mkdir -p playground
  done_n=$(done_count); xp=$(xp_total); lvl=$(xp_level); pct=$(( done_n * 100 / LESSONS )); rank_t=$(rank "$done_n")
  [ -f "${INCSTATS:-.incidents}" ] && inc_n=$(cut -d'|' -f1 "${INCSTATS:-.incidents}" | sort -u | wc -l | tr -d ' ')
  if [ -f "${MOCKSTATS:-.mockstats}" ]; then
    mock_n=$(wc -l < "${MOCKSTATS:-.mockstats}" | tr -d ' ')
    mock_got=$(cut -d'|' -f2 "${MOCKSTATS:-.mockstats}" | grep -c '^2$')
  fi
  {
    cat <<'HEAD'
<!doctype html>
<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>DevOps Cloud Lab progress</title>
<style>
:root{--bg:#f6f7f9;--card:#fff;--ink:#14171a;--mute:#5b6570;--line:#dfe3e8;--accent:#0b6bcb;--ok:#1a7f37;--warn:#9a6700;--lock:#8a939c}
@media (prefers-color-scheme:dark){:root:not([data-theme="light"]){--bg:#0f1317;--card:#171c22;--ink:#e8ecf0;--mute:#9aa5b1;--line:#2a323b;--accent:#58a6ff;--ok:#3fb950;--warn:#d29922;--lock:#6b7580}}
*{box-sizing:border-box}body{margin:0;background:var(--bg);color:var(--ink);font:16px/1.5 system-ui,-apple-system,Segoe UI,Roboto,sans-serif}
main{max-width:960px;margin:0 auto;padding:24px 16px 48px}h1{font-size:1.6rem;margin:0 0 4px}h2{font-size:1.15rem;margin:32px 0 10px}
.sub{color:var(--mute);margin:0 0 20px}.stats{display:grid;grid-template-columns:repeat(auto-fit,minmax(140px,1fr));gap:10px}
.stat{background:var(--card);border:1px solid var(--line);border-radius:10px;padding:12px 14px}.stat b{display:block;font-size:1.5rem}.stat span{color:var(--mute);font-size:.85rem}
.bar{height:12px;background:var(--line);border-radius:6px;overflow:hidden;margin:14px 0 0}.bar i{display:block;height:100%;background:var(--accent)}
.grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(250px,1fr));gap:8px}.mod{background:var(--card);border:1px solid var(--line);border-radius:8px;padding:8px 12px;display:flex;gap:10px;align-items:center}
.mod em{font-style:normal;font-weight:700;min-width:1.8rem}.mod small{margin-left:auto;font-weight:600}.done small{color:var(--ok)}.half small{color:var(--warn)}.open small{color:var(--accent)}.lock{opacity:.6}.lock small{color:var(--lock)}
table{width:100%;border-collapse:collapse;background:var(--card);border:1px solid var(--line);border-radius:8px;overflow:hidden}th,td{text-align:left;padding:8px 12px;border-bottom:1px solid var(--line)}th{color:var(--mute);font-weight:600;font-size:.85rem}
ul.bul{padding-left:20px}ul.bul li{margin:6px 0}.note{color:var(--mute);font-size:.9rem}
</style></head><body><main>
HEAD
    printf '<h1>DevOps Cloud Lab: my progress</h1><p class="sub">Generated %s by <code>bash lab.sh report</code></p>\n' "$(date '+%Y-%m-%d %H:%M')"
    printf '<div class="stats"><div class="stat"><b>%s</b><span>rank</span></div><div class="stat"><b>Level %s</b><span>%s XP</span></div><div class="stat"><b>%s / %s</b><span>modules complete</span></div><div class="stat"><b>%s / 5</b><span>incident drills solved</span></div><div class="stat"><b>%s</b><span>mock answers rated (%s fully covered)</span></div></div>\n' "$rank_t" "$lvl" "$xp" "$done_n" "$LESSONS" "$inc_n" "$mock_n" "$mock_got"
    printf '<div class="bar" role="progressbar" aria-valuenow="%s" aria-valuemin="0" aria-valuemax="100"><i style="width:%s%%"></i></div>\n' "$pct" "$pct"
    printf '<h2>Modules</h2><div class="grid">\n'
    for f in lessons/*.sh; do
      id=$(basename "$f" | cut -c1-2); label=$(lesson_title "$f" | sed 's/[:(].*//; s/ *$//' | html_esc)
      if has "$id"; then cls=done; state="done"; elif has "$id.learn"; then cls=half; state="exam pending"; elif gate_ok "$id"; then cls=open; state="open"; else cls=lock; state="locked"; fi
      printf '<div class="mod %s"><em>%s</em><span>%s</span><small>%s</small></div>\n' "$cls" "$id" "$label" "$state"
    done
    printf '</div>\n<h2>Incident drills</h2>\n'
    if [ -f "${INCSTATS:-.incidents}" ]; then
      printf '<table><tr><th>Fault</th><th>Best time</th><th>Hints</th><th>Last solved</th></tr>\n'
      cut -d'|' -f1 "${INCSTATS:-.incidents}" | sort -u | while read -r n; do
        b=$(grep "^$n|" "${INCSTATS:-.incidents}" | sort -t'|' -k2 -n | head -1)
        printf '<tr><td>%s</td><td>%s</td><td>%s</td><td>%s</td></tr>\n' "$n" "$(inc_fmt "$(echo "$b" | cut -d'|' -f2)")" "$(echo "$b" | cut -d'|' -f3)" "$(grep "^$n|" "${INCSTATS:-.incidents}" | tail -1 | cut -d'|' -f4)"
      done
      printf '</table>\n'
    else printf '<p class="note">No drills solved yet. Try <code>bash lab.sh incident</code>.</p>\n'; fi
    printf '<h2>Résumé bullets for the modules I finished</h2><p class="note">Written from what the lab covers. Add one real detail from your own practice to each before using it, and keep it true.</p>\n<ul class="bul">\n'
    n=0
    while IFS='|' read -r id b; do has "$id" && { printf '<li>%s</li>\n' "$(printf '%s' "$b" | html_esc)"; n=$((n+1)); }; done < modes/resume-bullets.txt
    [ "$n" -eq 0 ] && printf '<li class="note">Finish a module (lessons, interview and final) and its bullet appears here.</li>\n'
    printf '</ul>\n</main></body></html>\n'
  } > "$out"
  printf '\n  %sReport written:%s %s\n  Open it in your browser: file:///%s\n\n' "$BOLD" "$RST" "$out" "$(pwd -W 2>/dev/null | tr '\\' '/' || pwd)/$out"
}
