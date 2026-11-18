// Prints the answer of a Prometheus instant query in a readable form. Used by the lab shortcut  pq 'QUERY'
// (the shortcut sends the query to http://localhost:9090/api/v1/query and pipes the JSON in here).
let s = '';
process.stdin.on('data', (d) => (s += d)).on('end', () => {
  let r;
  try { r = JSON.parse(s); } catch (e) { console.log('Prometheus did not answer. Is it running? (dco up -d)'); process.exit(1); }
  if (r.status !== 'success') { console.log('ERROR: ' + r.error); process.exit(1); }
  const res = r.data.result;
  if (!res.length) { console.log('(no data)'); return; }
  for (const x of res) {
    const m = x.metric || {};
    const labels = Object.entries(m).filter(([k]) => k !== '__name__').map(([k, v]) => k + '="' + v + '"').join(', ');
    const v = Number(x.value[1]);
    console.log((m.__name__ || '') + '{' + labels + '} => ' + (Number.isInteger(v) ? v : +v.toFixed(4)));
  }
});
