// Sharding: which database server holds which key?
//   node 24-system-design/shard.js mod 3        how 1000 keys spread over 3 shards with  hash(key) % N
//   node 24-system-design/shard.js compare      what happens to the keys when you add a shard (3 -> 4)
const crypto = require('crypto');
const hash = (k) => parseInt(crypto.createHash('md5').update(k).digest('hex').slice(0, 8), 16);
const keys = Array.from({ length: 1000 }, (_, i) => 'user:' + i);

const byMod = (shards) => (k) => hash(k) % shards;

// consistent hashing: shards sit on a ring (many points each); a key goes to the next point on the ring
function byRing(shards, points = 100) {
  const ring = [];
  for (let s = 0; s < shards; s++) for (let p = 0; p < points; p++) ring.push([hash('shard' + s + '#' + p), s]);
  ring.sort((a, b) => a[0] - b[0]);
  return (k) => { const h = hash(k); for (const [pos, s] of ring) if (pos >= h) return s; return ring[0][1]; };
}

function spread(place, shards) {
  const count = Array(shards).fill(0);
  keys.forEach((k) => count[place(k)]++);
  return count;
}
function moved(a, b) { return keys.filter((k) => a(k) !== b(k)).length; }

const mode = process.argv[2] || 'mod';
const n = Number(process.argv[3]) || 3;
if (mode === 'compare') {
  const m = moved(byMod(3), byMod(4));
  const c = moved(byRing(3), byRing(4));
  console.log('Adding a 4th shard to a cluster of 3, with 1000 keys:');
  console.log('  hash-mod  (hash % N)      moves ' + m + ' keys (' + Math.round(m / 10) + '%)');
  console.log('  consistent hashing (ring)  moves ' + c + ' keys (' + Math.round(c / 10) + '%)');
  console.log('Fewer moved keys = less data to copy while the system is live. Consistent hashing wins.');
} else {
  const place = mode === 'ring' ? byRing(n) : byMod(n);
  spread(place, n).forEach((c, s) => console.log('shard ' + s + ': ' + c + ' keys  ' + '#'.repeat(Math.round(c / 20))));
}
