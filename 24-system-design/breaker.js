// A circuit breaker, simulated with a virtual clock (the demo finishes instantly).
//   node 24-system-design/breaker.js [FAILURE_THRESHOLD=3]
// A dependency is down from t=2.0 s to t=8.0 s. Each call to it then waits 1000 ms and times out.
const threshold = Number(process.argv[2]) || 3;
const cooldown = 3000;   // ms the breaker stays OPEN before it tries again
const gap = 500;         // a call every 500 ms
const calls = 24;
const down = (t) => t >= 2000 && t < 8000;

let state = 'CLOSED', fails = 0, openedAt = 0, waited = 0, waitedWithout = 0;
console.log('circuit breaker demo: failure threshold = ' + threshold + ', cooldown = ' + cooldown / 1000 + ' s');
for (let i = 1; i <= calls; i++) {
  const t = (i - 1) * gap;
  waitedWithout += down(t) ? 1000 : 20;
  let note;
  if (state === 'OPEN' && t - openedAt >= cooldown) state = 'HALF-OPEN';   // time to test the dependency
  const shown = state;
  if (state === 'OPEN') {
    note = 'fast-fail (1 ms): the dependency is not even called';
    waited += 1;
  } else if (!down(t)) {
    note = 'ok (20 ms)';
    waited += 20;
    if (state === 'HALF-OPEN') { state = 'CLOSED'; note += '  -> trial worked, breaker CLOSED again'; }
    fails = 0;
  } else {
    note = 'TIMEOUT (1000 ms)';
    waited += 1000;
    fails++;
    if (state === 'HALF-OPEN' || fails >= threshold) { state = 'OPEN'; openedAt = t; note += '  -> breaker OPENS'; }
  }
  console.log('call ' + String(i).padStart(2) + '  t=' + (t / 1000).toFixed(1).padStart(4) + 's  breaker=' + shown.padEnd(10) + note);
}
console.log('time spent waiting WITH the breaker:    ' + waited + ' ms');
console.log('time spent waiting WITHOUT the breaker: ' + waitedWithout + ' ms');
