# Best Practices — Defender for Office 365 (Plan 2): Threat Explorer, Attack Simulation & Automated Investigation

Keep-it-clean guidance for a post-delivery detection-and-response practice that stays trusted,
measured, and current over time.

## Hunt on a question, not a hunch

- **Start every hunt from an answerable question** — "who else received this?", "who clicked after
  delivery?", "is it still in inboxes?" — and pivot in Explorer on the entity (sender, URL, hash,
  click verdict). Save the good hunts (`Explorer-PostDelivery-Pilot`, the KQL library) so the team
  reuses them instead of reinventing.
- **Prefer post-delivery signal.** The prevention layer already blocked the obvious; your value is in
  what got through and what changed after delivery (weaponized-after-delivery URLs, late clicks).
- **Re-hunt after every incident.** A new indicator (sender, domain, hash) is a new query — run it
  across the whole tenant, not just the reporting user.

## Simulate to measure, train to fix — never to punish

- **Simulation is a measurement tool.** Its job is to produce **honest susceptibility data** and
  route the right people to targeted training — not to embarrass anyone. Make the non-punitive intent
  explicit in the communications plan (R5); a punitive program destroys reporting culture.
- **Start easy, escalate slowly.** Begin with credential-harvest to the pilot group
  (`Sim-CredHarvest-Pilot`), then broaden technique and audience over time (`Sim-CredHarvest-Org`).
  Track the **repeat-offender** trend, not a single campaign's click rate.
- **Respect people and the law.** Whether, when, and how you simulate employees — and who must be
  informed — are **HR/legal decisions**. Get them agreed before you launch.

## Automate response only after you trust it

- **Approval-required first.** Keep AIR in an **approval-required** posture and route remediation
  through the **Action center** until the pilot proves the recommendations are right. A human
  approves every deletion at first.
- **Soft before hard.** Prefer **soft-delete** (recoverable from Deleted Items) over **hard-delete**
  (irreversible). Make hard-delete a **named-approver-only** action, always previewed with `-WhatIf`
  before execution.
- **Raise automation deliberately.** Only lift AIR to a higher automation level as a **documented
  operations decision (R6)**, for specific well-understood action types, with rollback in mind — not
  because it is convenient.

## Make detections durable

- **Custom detections earn their place.** Promote a hunting query to a custom detection
  (`Detect-PostDeliveryPhish-Pilot`) only once it is **quiet and accurate**; keep it alert-only until
  proven, then widen scope.
- **Version the good queries.** Keep your KQL library in source control so hunts are reviewable and
  portable — the same discipline the Sentinel detection-as-code solution applies.

## Run it as a program, and watch the trend

- **Loop, don't launch-and-forget.** Hunt → simulate → train → investigate → (gated) remediate →
  report, on a cadence. Post-delivery threats and user behavior both drift.
- **Track the right signals.** A falling repeat-offender rate, faster time-to-remediate, and more
  threats caught post-delivery are the signs the program is working — report them to leadership.

## Where to go next

With post-delivery detection and response operational, the natural next steps in this catalog are:

- **Microsoft 365 Mail Hygiene: Anti-Spam, EOP & Defender for Office 365** — the **prevention** layer
  this solution sits on top of; revisit it to tighten the policies that reduce what you have to hunt.
- **Microsoft Defender XDR** onboarding — bring endpoint, identity, and cloud-app detection into the
  same incident so email threats correlate with the rest of the kill chain.
- **Microsoft Sentinel analytics rules & SOAR** — export these email detections to the SIEM and build
  playbooks so trusted incidents drive automated response beyond the mailbox.
- **Entra ID conditional access & phishing-resistant authentication** — reduce the payoff of the
  credential-harvest that simulation keeps finding.
