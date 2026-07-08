# 7. Best Practices — Clipboard & Screen-Capture Protection (Microsoft Purview)

Field-tested practices for running clipboard and screen-capture Endpoint DLP so the control stays trusted,
effective, low-noise, and **defensible**. These complement the Implementation and Testing guides.

## Simulate before you enforce — always
- **Never** switch a new or materially changed endpoint restriction straight to block. Build
  **`DLP – Endpoint Clipboard+Screen – Simulation`** in **simulation / audit** first, long enough to capture
  representative device activity (Req 2.6), and read the results before enabling.
- Use **simulation with policy tips** on the pilot ring when you want end-user feedback before hard block.
- Treat **simulation mode as your permanent safety switch**: the enforced policy returns to simulation in one
  setting, instantly removing enforcement with no data change — this is your rollback.

## Onboarding is the gate (endpoint-specific)
- A **Devices-location policy is inert until the device is onboarded** (shared with Microsoft Defender for
  Endpoint) and reporting — verify onboarding and the **minimum OS build** before blaming the policy.
- **Screen-capture restriction is newer / may be in preview**, is limited to **supported apps/browsers and
  minimum OS builds**, and evolves — **verify your licensing/tenant** and deliver **clipboard first** if
  screen capture is not yet available. Flag, don't assume.
- Roll the two activities out **audit-first**: audit **copy to clipboard** and **screen capture** of
  sensitive content before restricting, so you see real usage and avoid blocking legitimate work.

## Label first, patterns second
- Where content is already labelled, key the rule on a **sensitivity-label condition** (optionally the
  **`Confidential – No-Copy – Endpoint`** label) as the primary, precise signal — it follows the marking
  decision a human or auto-labeling policy already made and produces far fewer false positives than broad SITs.
- Use **SITs at a chosen confidence and instance count** for unlabelled content; introduce **custom SITs /
  EDM / trainable classifiers** only for real gaps, and **never invent a SIT pattern** — build custom SITs
  from patterns the data owner supplies and test them in the SIT wizard's **Test** step.
- Getting the label/classifier right feeds the whole information-protection program — invest there, not in
  ever-more-complex regex.

## Right-size the allowed-app / browser / network exceptions
- **Mind allowed vs unallowed apps/browsers and network exceptions** so sanctioned copy-paste (e.g. between
  two internal line-of-business apps) and legitimate screenshots aren't caught alongside real exfiltration.
- Capture the sanctioned app/browser/network list from IT **and** the business before enforcing; re-tune it
  as tools change. A missing exception is the most common false-positive driver on endpoints.

## Tune for a low false-positive rate (adoption depends on it)
- Most false positives come from **broad SITs over-firing** — fix with **higher confidence/instance count**,
  a **label condition**, allowed-app/browser exceptions, or EDM, measured against the simulation results.
- Every false positive that reaches a user erodes trust in **every** policy tip. Budget for a tuning cycle,
  not a one-time build. Re-simulate after each change.

## Right-size the user experience
- Show **clear, actionable policy tips** in plain language — reuse one standard notice
  (**`DLP Notice – Clipboard/Screen – Standard`**) that tells the user the content is sensitive and what they
  may/may not do, not a compliance error code.
- Prefer **allow-with-justification / override** over hard block where legitimate exceptions exist, then
  **review the overrides** — routine overriding means the policy is mis-scoped. Reserve **hard block** for the
  categories where compliance requires it, escalating **one activity at a time**.

## Scope tightly, then expand
- Enforce first to the **`DLP Pilot Ring – Stage1`** (users **and** devices), keeping everyone else excluded,
  then expand once the pilot gate passes — this cuts false positives, shrinks blast radius, and keeps the
  control narrative clean.

## Evidence & operations (this is what a reviewer asks for)
- Give clipboard/screen-capture **alerts an owner and an SLA** via
  **`DLP Alerts – Clipboard/Screen – Operations`** (Req 2.7). Match volume without triage is not a control.
- **Retain the evidence trail** — alert dispositions, Activity Explorer exports, the simulate→enforce change
  log, and compliance sign-offs — so the control can be *shown*, not just claimed.
- Review **Activity Explorer** and the false-positive rate on a **recurring cadence**; re-tune as data and
  behaviour drift. Refresh **EDM** data on cadence if used.
- Enforce **least-privilege roles** and, where possible, **separate policy authors from alert triagers**.

## Stay honest about the boundary
- Endpoint DLP restricts content it can **classify** at the moment of the activity — a determined user can
  still **photograph a screen with a phone**. DLP is **one supporting control**, not a guarantee; combine it
  with sensitivity labels + encryption, access control, and insider-risk where the risk warrants.
- The **enforced action, which data categories are in scope, and whether the control is required** are
  **compliance / privacy / legal** decisions — you provide the technical control and the evidence; they own
  the call.
