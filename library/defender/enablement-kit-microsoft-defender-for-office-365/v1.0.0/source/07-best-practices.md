# Best Practices — Enablement Kit: Microsoft Defender for Office 365

Keep-it-clean guidance for turning an MDO enablement kit into a durable email-security skill that stays
sharp over time.

## Hunt on a question, not a hunch

- **Start every hunt from an answerable question** — "who else received this?", "who clicked after
  delivery?", "is it still in inboxes?" — and pivot in Explorer on the entity (sender, URL, hash,
  click verdict). Save the good hunts (`Explorer-MDOLab-Pilot`, `Hunt-MDOLab-Pilot`) so the team
  reuses them.
- **Prefer post-delivery signal.** The prevention stack already blocked the obvious; the value is in
  what got through and what changed after delivery (weaponized-after-delivery URLs, late clicks).
- **Re-hunt after every incident.** A new indicator (sender, domain, hash) is a new query — run it
  across the whole tenant, not just the reporting user.

## Understand the protection stack — then let the right solution change it

- **Read before you reason.** Knowing how anti-phish, Safe Links, and Safe Attachments decide lets you
  explain a verdict instead of guessing. Inspect the policies; don’t treat them as a black box.
- **Change is a different job.** Tightening the prevention policies is the **Mail Hygiene** solution;
  operationalizing post-delivery detection/response is the **Defender for Office 365 (Plan 2)**
  implementation solution. The enablement kit builds the skill that makes both changes safer.

## Simulate to measure, train to fix — never to punish

- **Simulation is a measurement tool.** Its job is honest susceptibility data and targeted training —
  not to embarrass anyone. Make the non-punitive intent explicit (R4); a punitive program destroys
  reporting culture.
- **Start easy, escalate slowly.** Begin with credential-harvest to the lab group (`Sim-MDOLab-Pilot`),
  then broaden technique and audience over time — a **people/security decision** made with HR.
- **Respect people and the law.** Whether, when, and how you simulate employees — and who must be
  informed — are **HR/legal decisions**. Agree them before you launch.

## Automate response only after you trust it

- **Approval-required first.** Keep AIR **approval-required** and route remediation through the **Action
  center** until it is trusted. A human approves every deletion at first.
- **Soft before hard.** Prefer **soft-delete** (recoverable) over **hard-delete** (irreversible); make
  hard-delete a **named-approver-only** action. None of this is executed in the enablement kit — it is
  taught and gated.
- **Raise automation deliberately.** Lifting AIR automation is a **documented operations decision**,
  owned by the implementation solution — not a default this enablement kit flips.

## Turn hunts into durable coverage — carefully

- **Alert-only first.** Promote a hunt to a custom detection (`Detect-MDOLab-Pilot`) only once it is
  quiet and accurate, and keep it alert-only until proven.
- **Version your queries.** Keep the email KQL library in source control so hunts are reviewable and
  portable — the same discipline the Sentinel detection-as-code solution applies.

## Run it as a program, not a one-off class

- **Loop, don’t launch-and-forget.** Hunt → simulate → train → investigate → (gated) remediate →
  report, on a cadence. Post-delivery threats and user behavior both drift.
- **Feed the hunt library and the implementation.** Hand tuned hunts to the **Threat Hunting
  hunt-library** program and the operational rollout to the **Defender for Office 365 (Plan 2)**
  solution.
- **Re-run for new hires.** The take-home runbook and knowledge-check make onboarding a new analyst
  repeatable.

## Where to go next

With the team able to hunt, simulate, and respond on email, the natural next steps in this catalog
are:

- **Defender for Office 365 (Plan 2): Threat Explorer, Attack Simulation & AIR** — operationalize the
  post-delivery features across the org (the rollout this enablement kit’s skills feed).
- **Microsoft 365 Mail Hygiene: Anti-Spam, EOP & Defender for Office 365** — tighten the prevention
  policies you learned to read, reducing what you have to hunt.
- **Advanced KQL for SecOps enablement kit** — deepen the query language this enablement kit applies to the email
  tables, and extend hunting across Defender XDR and Sentinel.
- **Microsoft Defender XDR onboarding** — bring endpoint, identity, and cloud-app signal into the same
  incident so email threats correlate with the whole kill chain.
