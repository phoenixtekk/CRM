# 7. Best Practices — Oracle C2M Troubleshooting & Root-Cause Analysis Toolkit

- Isolate the layer before you fix anything. Walk the ladder every time — Reachable (network) → Up
  (middleware) → Authenticated (DB/SSL) → Resourced (JVM/DB/pools/JMS) → Correct (application/OUAF).
  The single biggest cause of long outages is fixing the wrong layer; a passing rung *rules a layer
  out*, a failing rung *is* the cause or the next descent.
- Capture the snapshot before you restart. Run `OC2MRCA-Discovery.sh` first, always — server states,
  thread/heap dumps, log tails, DB signals. A restart clears the symptom *and* the evidence; without
  the `C2M RCA - Diagnostic Snapshot` there is no defensible RCA and the incident will recur unexplained.
- Keep a healthy baseline. RCA is a comparison — "this is what changed." Record a known-good snapshot
  (`OC2MRCA-Discovery.sh` + `OC2MRCA-Report.sql`) on a normal day so the deviating layer stands out
  instead of every reading looking suspicious.
- Read the top of the thread dump, not the surface. A stuck thread is named by where it is waiting:
  JDBC at the top = database, an object-lock wait = deadlock, product code = application. "It's stuck
  in WebLogic" is not a root cause; the stack is.
- Treat "won't connect" as network-or-DB until proven otherwise. A suspended data source, a login that
  hangs, a failed outbound call — the cause is usually a down listener, a locked/expired DB account, a
  firewall, or an **expired certificate**, not a WebLogic defect. Check reachability and certs early.
- Restore with the smallest reversible action. Prefer starting the listener, freeing the disk, or an
  orderly single-server restart over a full-stack bounce. Preview with `OC2MRCA-Remediation.sh`
  (dry-run) and apply only in a change window with backups — the least action that restores service is
  the safest and the easiest to roll back.
- Watch the cheap, high-signal resources first in a stall. Full GC / `OutOfMemoryError` in the `.out`,
  stuck/hogging thread counts (default stuck = busy > 600s; all default-queue stuck → health
  `critical`), connection-pool at max, JMS pending climbing with zero consumers — these four catch most
  performance and backlog incidents before any deep dive.
- Prefer IWS, and know its defaults. Inbound Web Services superseded the deprecated XAI servlet; IWS is
  **disabled by default** and must be enabled, and XAI-via-IWS needs the External Messages *Support XAI
  Services via IWS* feature option. A "broken integration" is often just a service not enabled or not
  deployed — check state before logic.
- Rehearse on non-production, or on a captured snapshot. Prove the toolkit and seed per-layer faults on
  non-production so the method is muscle memory before the outage. When a fault is production-only,
  diagnose from the read-only snapshot and test the fix on non-production first.
- Write the Root-Cause Record every time, even for quick fixes. `C2M RCA - Root-Cause Record` —
  symptom, timeline, the isolating check, the layer and cause, the fix, and the prevention — is what
  stops the repeat outage and what a defensible post-incident review (and Oracle) needs.
- Escalate with evidence, not symptoms. When it is a product defect, attach the full snapshot to the
  service request and cite the version's My Oracle Support note — gated content is pointed to, never
  reproduced. Oracle resolves an isolated, evidenced fault far faster than "C2M is slow".
- Change under change control only. Every restore action in production — restart, data-source re-sync,
  JMS re-sync — is a change: backups first (domain and product config), a change window, and a
  documented rollback. "Safe" still means controlled.
