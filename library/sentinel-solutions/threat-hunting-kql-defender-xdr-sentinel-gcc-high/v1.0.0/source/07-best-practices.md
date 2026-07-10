# Best Practices — Threat Hunting with KQL: Microsoft Defender XDR & Sentinel

Keep-it-clean guidance for a hunt program that stays proactive, disciplined, and current over time.

## Hunt from a hypothesis, not a hunch

- **Every hunt starts with a written hypothesis.** "If technique *X* were happening, this query would
  surface it." A query with no hypothesis is a fishing trip you cannot document, repeat, or learn from.
- **Scope narrow, then widen.** Start within retention and on high-value assets/identities, confirm the
  logic returns *something* sane, then broaden. It is faster, cheaper, and avoids hitting query limits
  (R8).
- **A null result is still a result.** "Not found this window" is valuable and belongs in the register —
  it records where you have looked, so effort goes to unhunted ground next cycle.

## Hunt against a map (MITRE ATT&CK)

- **Tag every hunt to a technique.** The tags turn the library into a **coverage map**: you can see which
  tactics you actively hunt and which you have never looked at — and steer the backlog to the gaps.
- **Prioritize by risk, not by ease.** Which techniques matter most is a **leadership decision (R4)**;
  hunt the crown-jewel-relevant techniques first, not the ones with the tidiest query.
- **Cover breadth *and* depth.** One shallow hunt per tactic is thin coverage. For high-risk techniques,
  run several complementary hunts.

## Stay read-only — hunting finds, it does not act

- **Never take a response action from a hunt.** Isolation, account disablement, mailbox purge, and
  escalation belong to the **reactive** process (*M365 & Azure Incident Response & Escalation Runbook*).
  A hunter improvising containment has neither the authority nor the change record for it.
- **Separate hunt (read) from promote (write).** Give hunters read-only access; keep detection creation
  with a smaller admin set. Least privilege keeps the program safe and auditable.
- **Hand off cleanly.** A confirmed true positive becomes an **incident with evidence attached**, not a
  chat message — so responders inherit the full context and nothing is lost in translation.

## Document so the knowledge compounds

- **The register is the program.** Hypothesis, scope, query, outcome, decision — per hunt. A hunt whose
  result lives in a browser tab is a hunt you will pay to run again.
- **Bookmark the evidence.** Advanced hunting is ~30-day retention; a `Bookmark-<Hunt>-Finding` (with
  entities mapped) preserves the row after the window rolls off.
- **Version the library.** Keep `Hunt Library - Tenant - Main` (`THREATHUNTG-HuntLibrary.kql`) in source
  control alongside the promoted detections, so a good query is reviewable, diffable, and portable.

## Promote wins into permanent detections

- **A hunt that keeps finding real activity should stop being a hunt.** Promote it to a **custom
  detection** (Defender XDR) or a **scheduled analytics rule** (Sentinel) so it runs automatically
  forever — that is how a program compounds.
- **Promote into a low-impact posture, then tune.** A promoted Sentinel rule starts with incident
  creation disabled and is tuned for false positives in the *Microsoft Sentinel Analytics Rules & MITRE
  ATT&CK Detection Coverage* solution before the SOC trusts it. A noisy auto-detection is worse than a
  manual hunt.
- **Retire what only ever finds noise.** Not every hunt deserves promotion; record the decision so the
  library stays sharp.

## Run it as a program, on a cadence

- **Loop, don't launch-and-forget.** Assess → configure → pilot → validate → expand, then take the next
  batch of techniques on `Hunt Cadence - Tenant - Monthly`. Adversary behavior and your environment both
  drift; the cadence keeps hunting honest.
- **Feed threat intel into the backlog.** New intel (a campaign, a new TTP) should spawn a hypothesis and
  a hunt — the fastest way to know whether *that* threat is already in your environment.
- **Watch the trend.** Growing tagged-hunt coverage, findings that become detections, and shrinking
  time-to-find are the signs the program is maturing — `THREATHUNTG-Report.ps1` surfaces them.

## Where to go next

With a proactive hunt program running, the natural next steps in this catalog are:

- **Microsoft Sentinel Analytics Rules & MITRE ATT&CK Detection Coverage** — tune the detections you
  promote from hunts so they are trustworthy and low-noise (the promotion target of this solution).
- **M365 & Azure Incident Response & Escalation Runbook** — the reactive counterpart that works the
  incidents your hunts hand off (containment, eradication, escalation).
- **Sentinel SOAR / automation playbooks** — automate enrichment and response for the detections your
  hunts create.
- **Deploy Microsoft Sentinel: Workspace, Data Connectors & Ingestion** — add the sources that would let
  you hunt techniques you currently cannot see.
