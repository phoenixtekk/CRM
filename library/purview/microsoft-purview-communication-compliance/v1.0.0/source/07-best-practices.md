# 7. Best Practices — Microsoft Purview Communication Compliance

- **Configure the guardrails before the policy.** Set privacy options and populate the role groups with
  **separation** *first* — before any policy processes a single message. Detection stood up without
  governed reviewers and minimized scope is a privacy liability, not a control.
- **Separate builders, reviewers, and investigators.** Keep **Admin** (builds policies), **Analysts**
  (review content), **Investigators** (escalation), and **Viewers** (reports only) as distinct people.
  Avoid the combined **Communication Compliance** role group outside a tiny pilot — it collapses the
  separation you are trying to prove.
- **Reviewers are HR/compliance, not IT.** The people who read flagged content should be the agreed
  human-resources / compliance function. IT configures the mechanism; it does not review employees'
  messages.
- **Minimize the supervised population.** Scope to the **minimum the obligation requires**, never
  "everyone", and maintain `Comms Excluded – Privacy` for anyone who must not be monitored. Narrow scope
  is both a privacy control and a review-load control.
- **Pseudonymize where privacy requires it.** Turn on anonymized/pseudonymized usernames in the review
  experience when your privacy stakeholders call for it — reviewers can still triage without seeing
  identities until an escalation genuinely needs them.
- **Get the lawful basis first.** In many jurisdictions monitoring communications requires employee
  notice, works-council/union agreement, or a documented lawful basis **before** enabling. Confirm it
  with legal — the tool does not substitute for that.
- **Always pilot in simulation/test first.** Build the first policy against `Comms In-Scope – Pilot`,
  tune it, and validate the reviewer workflow before expanding. Monitoring is high-impact; never switch
  it on tenant-wide blind.
- **Always dry-run automation.** `PURVCC-Configuration.ps1`, `PURVCC-ReviewerWorkflow.ps1`, and
  `PURVCC-Set-Scope.ps1` default to **`-WhatIf`**. Read every line of the planned change; run `-Commit`
  only after the output is right and HR/legal have signed off.
- **Tune for signal, not volume.** Trainable classifiers are probabilistic — expect false positives and
  reduce them with better conditions, tighter keyword lexicons, and a sensible **sampling percentage**.
  A queue reviewers can't sustain gets ignored, which defeats the control.
- **Outcomes belong to HR/legal.** The tool surfaces candidate violations and routes them; **whether a
  message is a violation and what happens next is HR/privacy/legal's determination.** Reviewers tag,
  resolve, escalate — they do not adjudicate employment or regulatory outcomes.
- **Keep the separation evidence current.** Re-run `PURVCC-Discovery.ps1` / `PURVCC-Report.ps1` on a
  cadence; role-group membership drifts as people join and leave, and the membership snapshot is your
  auditable proof that oversight stayed governed.
- **Distinguish this from Insider Risk.** Communication Compliance inspects **message content**; Insider
  Risk scores **risky activity**. Don't try to make one do the other — route behaviour-based signals to
  Insider Risk Management and keep this focused on communications.
- **Verify licensing and classifier availability against your tenant.** E5 / E5 Compliance / Insider Risk
  entitlement, specific classifiers, connected sources, and portal paths are plan-dependent and evolve —
  confirm, never assume.
- **Maintain the channels.** As Teams/Viva Engage usage and connected sources change, revisit which
  channels each policy covers so coverage doesn't silently drift.
