# 7. Best Practices — Custom DLP Policy Development (Microsoft Purview)

- **Never create a DLP policy directly in enforcement.** Always author in **`TestWithoutNotifications`**
  first — it evaluates content and records matches with **zero user impact**. Enforcement is something you
  *promote a tuned policy to*, never the starting state. This is the whole reason the Purview model pilots
  in simulation.
- **Tune before you enforce, and tune against evidence.** Use the simulation match report to drive down
  false positives (raise confidence, raise instance-count minimums, add exceptions, narrow the SIT) and
  false negatives (add/broaden SITs, lower over-strict thresholds). A block action on an untuned policy is
  how DLP breaks legitimate work on day one.
- **False positives are a security problem.** Every over-firing rule trains users to dismiss DLP warnings,
  so the warning that matters gets dismissed too. Precision *is* the security control — not an aesthetic.
- **Encode approved flows as explicit exceptions.** The business has legitimate sharing paths (partner
  domains, service mailboxes, specific sites). Capture them as `ExceptIf…` exceptions so the policy protects
  data without becoming the thing everyone routes around.
- **Prefer high confidence and instance counts over blunt matches.** A single SSN-shaped string is noisy;
  *ten* at *high* confidence going *outside the organisation* is a real signal. Design conditions for
  signal, not for maximum firing.
- **Consume data classes; don't invent them here.** If a condition needs a data class Purview lacks, build
  the **custom SIT / Exact Data Match / document fingerprint / trainable classifier** in its own solution
  first, then reference it. Don't stretch a built-in SIT to fit — accuracy comes from the right classifier.
- **Stage the actions, not just the mode.** Move audit-only → policy tip/notify → restrict/block →
  encrypt. Let users learn from tips before anything is blocked; validate each stage before the next.
- **Always dry-run policy changes.** Run every create/update with `-WhatIf` and read it against the design
  before `-Commit`; the scripts print the exact reverse command so rollback to no-impact simulation
  (`-Mode TestWithoutNotifications`) or `Disable` is one line.
- **Pilot on a scope, then expand.** Simulate and tune on a pilot user/site set; broaden to the full
  population only after the enforced policy is confirmed healthy on the pilot and approved flows still work.
- **Treat portal paths and the simulation UI as provisional.** The Purview DLP portal and simulation
  experience evolve — verify paths in your tenant rather than trusting last quarter's screenshot.
- **Determinations belong to compliance/privacy/legal.** *What* is sensitive, *which* regulation applies,
  and any records/retention implication are theirs to decide — you provide the technical policy and the
  match evidence, not the ruling.
