# Executive Summary — Threat Hunting with KQL: Microsoft Defender XDR & Sentinel

## The problem

A security team that only *waits for alerts* is always a step behind. Detections fire on the attacks
someone already anticipated and wrote a rule for — but the intrusions that matter most are the ones
that slip **between** the rules: a living-off-the-land command that looks like admin work, a mailbox
rule quietly forwarding to an attacker, a service account signing in from a place it never has.
By the time a reactive alert catches up, the adversary has usually already moved.

Two failure modes are common, and most organizations have both:

- **No proactive discipline.** Nobody systematically asks "if an attacker were already inside, how
  would we find them?" There is no repeatable method, no hypothesis backlog, no cadence — hunting
  happens only after an incident, if at all.
- **Knowledge that evaporates.** When someone *does* run a clever query and finds something, the query
  lives in a browser tab and the finding lives in a chat message. The next hunter starts from zero, and
  a hunt that worked never becomes a permanent detection.

## The solution

This solution stands up a **proactive, repeatable threat-hunting program** across **Microsoft Defender
XDR advanced hunting** and **Microsoft Sentinel**, driven by **KQL**. It:

- **Establishes the hunting environment** — advanced hunting (XDR) and Sentinel hunting, with scoped,
  least-privilege **read-only** access so hunters can query broadly without the power to change
  anything.
- **Delivers a MITRE ATT&CK-aligned, reusable KQL hunt library** — real, ready-to-run hunt queries,
  each tagged to the tactic/technique it targets, so the team hunts against a **map of adversary
  behavior**, not a blank page.
- **Runs a hypothesis-driven method on a cadence** — every hunt starts from a written hypothesis, is
  scoped and time-boxed, and produces a documented result (found / not found / needs follow-up),
  captured as **bookmarks** and a **hunt register**.
- **Promotes successful hunts into permanent detections** — a hunt that reliably finds real activity is
  turned into a **scheduled analytics rule** (Sentinel) or a **custom detection rule** (Defender XDR),
  so the win is captured forever instead of re-run by hand.
- **Hands confirmed findings off cleanly** — a true-positive hunt becomes an **incident** that flows
  into your **reactive incident-response process**, not an ad-hoc fire drill.

## How it works

It follows the same repeatable model every solution in this program uses —
**Assess → Configure → Pilot → Validate → Expand**. You first **assess** the hunting surface (which
tables have data, who has access, which techniques matter most), **configure** the hunt library,
register, RBAC, and cadence, run a **pilot** batch of hypothesis-driven hunts read-only and document
what you find, **validate** that findings are coherent and that a successful hunt promotes cleanly into
a detection, and only then **expand** the library across the ATT&CK matrix on a recurring cadence.
**Every hunt is read-only** — hunting *finds*; it never *acts*.

The solution ships as **self-guided, click-by-click documentation plus a KQL hunt library and four
PowerShell tools** (Microsoft.Graph `runHuntingQuery` for Defender XDR + Az for Sentinel) that
discover the hunting surface, run the whole library across both platforms and report findings,
validate the program against pass/fail gates, and report hunt-program metrics — all **read-only**,
with **no credentials in code** and **no response actions**.

## The boundary — proactive hunting, not reactive response

This solution is deliberately the **proactive** half of detection & response. It **finds** suspicious
activity and turns durable findings into detections; it does **not** contain, isolate, disable, or
remediate. **Response actions — device isolation, account disablement, mailbox purges, escalation, and
crisis coordination — are out of scope and belong to the companion
*M365 & Azure Incident Response & Escalation Runbook*.** When a hunt confirms a true positive, this
solution's job is to **document it and hand it off** to that reactive process, cleanly. The two are
designed to fit together: hunting feeds the incident queue; the runbook works the queue.

## Important boundaries

Threat hunting **reduces dwell time; it is not a guarantee** — a hunt that returns nothing means *this
hypothesis found nothing over this window*, not that the environment is clean. It **assumes telemetry
is already flowing**: a hunt can only find what the platforms ingest, so it depends on onboarded
Defender XDR data and a connected Sentinel workspace. It **does not decide** which techniques matter
most for your organization or your risk tolerance — those are security-leadership determinations that
prioritize the hunt backlog. Defender XDR advanced hunting **schema, retention, and query limits**, and
the availability of specific tables and custom-detection features, **evolve and can differ by cloud
(Commercial vs Government) and by license** — *verify current availability and limits in your tenant.*

## Effort

A competent security analyst can stand up the hunting environment, import the library, and run and
document the first pilot hunts in a focused engagement, then settle into a recurring monthly cadence.
The documentation is click-by-click; the KQL library and PowerShell tools do the heavy lifting.
Delivered as a **Complete Solution Package (PDF + Word + scripts)** — reusable on every tenant and every
hunt cycle.
