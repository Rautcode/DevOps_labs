# 10 · SRE and Incident Response (Advanced, ~4h)

**Goal:** operate the system like an owner: define reliability, get alerted on what matters, respond from a runbook, learn through blameless postmortems.

| File | Purpose |
|---|---|
| [slo.md](slo.md) | SLIs, the 99.5% SLO and its error budget (3h 36m / 30 days) |
| [runbooks/api-down.md](runbooks/api-down.md) | what the on-call does when `EndpointDown` fires (linked from the alert) |
| [postmortem-template.md](postmortem-template.md) | blameless postmortem format |
| [gameday.md](gameday.md) | six chaos scenarios with predictions |

## Do it
1. Start the stack **with** observability ([module 08](../08-observability/README.md)).
2. Run game-day scenario 1 and watch the alert go `pending → firing` at http://localhost:9090/alerts.
3. Follow the runbook **literally**. Where is it vague or wrong? Fix it: runbooks are living code.
4. Write a postmortem for your game day.

**Check:** you can state, for your drill, the time to detect, time to recover, and the share of error budget consumed.

## Industry notes
- **Alert on symptoms (burn rate), not causes (CPU%).** Fewer pages, all meaningful.
- Every page links a runbook; every incident yields action items with an owner and a date.
- Error-budget policy aligns product and engineering: budget left → ship; budget gone → fix reliability.
- Measure **MTTD / MTTR** and, for data, **RPO / RTO** (module 11).

**Next:** [11 · Capstone](../11-capstone/README.md)
