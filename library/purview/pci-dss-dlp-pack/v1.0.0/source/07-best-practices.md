# 7. Best Practices — PCI-DSS DLP Pack (Microsoft Purview)

Field-tested practices for running cardholder-data DLP across endpoint, cloud, and email so the control
stays trusted, effective, and low-noise. These complement the Implementation and Testing guides.

## Simulate before you enforce — always
- **Never** switch a new or materially changed PAN DLP policy straight to enforce. Run it in
  **simulation** first, long enough to capture representative card-data traffic (Req 2.6), and read the
  results before enabling.
- Use **simulation with policy tips** on the pilot ring when you want end-user feedback before hard block.
- Treat **simulation mode as your permanent safety switch**: any enforced policy can be returned to
  simulation in one setting, instantly removing enforcement with no data change — this is your rollback.

## Anchor on PAN, and tune for a low false-positive rate
- Detection anchors on the built-in **Credit Card Number** SIT (card-brand pattern + **Luhn** + keywords).
  A lone Luhn-valid number is noise; the same number **with a card-brand keyword nearby** or **ten in one
  file** is a real signal — use confidence and instance count accordingly.
- Keep **two policy shapes**: a **single-PAN** policy for the "one card number in an email" case, and a
  **bulk (≥N)** policy for exports/spreadsheets — different thresholds, different actions.
- Use **Exact Data Match** (`Cardholder PAN – EDM – PCI`) for storage where the pattern SIT over-fires on
  internal reference numbers — it matches your *actual* PANs and drives false positives toward zero, at the
  cost of an upload + refresh cadence.
- Every false positive that reaches a user erodes trust in **every** policy tip. Budget for a tuning cycle,
  not a one-time build.

## Respect the card-data rules (don't over- or under-reach)
- **Truncated PANs are not full PANs.** First-six/last-four (per PCI display rules) should *not* match a
  full-PAN detector — validate this (Test A6) so masked receipts and logs don't generate noise.
- **SAD detection is best-effort.** CVV/track/PIN detectors are weak alone; use PAN + supporting keywords
  as an early-warning signal and treat SAD hits as *investigate*, not proof. Never store SAD — DLP is a
  backstop, not the control that keeps it out of storage.
- **Never test with real PANs.** Use the documented test card numbers; a test PAN exercises the detector
  without you handling live cardholder data.

## Right-size the user experience
- Show **clear, actionable policy tips** in business language — tell the user this looks like a payment
  card number and what the approved process is, not a compliance error code. Reuse one standard notice
  (`PCI DLP Notice – Standard – AllPolicies`).
- Prefer **allow-with-justification / override** over hard block where legitimate card-handling exceptions
  exist, then **review the overrides** — routine overriding means the policy is mis-scoped (often the
  sanctioned in-CDE application should be an exception).
- Reserve **hard block/encrypt** for the flows where PCI/compliance require it; escalate to block one
  flow/location at a time, re-validating each.

## Endpoint DLP specifics
- **Onboarding is the gate.** A Devices policy is inert until the device is onboarded (shared with Defender
  for Endpoint) and reporting — verify onboarding before blaming the policy.
- Roll endpoint controls out **audit-first**: audit USB/print/cloud-upload of PAN-bearing files before
  restricting, so you see real usage and avoid blocking legitimate workflows.
- Mind **unallowed vs allowed apps/browsers and network exceptions** — configure the allowed-app and
  network-path lists so sanctioned payment tools aren't caught alongside exfiltration paths.

## Scoping and CDE hygiene
- **Use DLP to find PAN sprawl.** The highest early value is discovering PAN *outside* the CDE (email,
  files, chat, endpoints) — that finding informs scope reduction; the CDE/scope determination stays with
  compliance/QSA.
- **Exclude the sanctioned in-CDE path deliberately and document it** — don't let the payment application's
  own mailbox/site flood the queue; scope it out with a written reason.
- **Version and document** any EDM schema (fields, refresh cadence, owner) so tuning changes are traceable
  for the assessor.
- **Refresh EDM data** on a schedule — stale EDM data silently degrades PAN matching.

## Operations & governance
- Give PAN **alerts an owner and an SLA** (Req 2.7), aligned to your incident-response plan. A card-data
  match volume with no triage is not a control. Forward to SIEM/Sentinel where central SecOps needs
  visibility.
- Review **Activity Explorer** and the false-positive rate on a **recurring cadence**; re-tune as data and
  behavior drift.
- Enforce **least-privilege roles** and, where possible, **separate policy authors from alert triagers** —
  role separation is expected in a PCI environment.
- Keep a **change log** of every simulate→enforce transition and every action escalation, with the
  compliance sign-off attached — this is assessor evidence.

## Stay inside the boundary
- DLP is **one control**, not proof the CDE is contained — it inspects content it can classify; combine
  with sensitivity labels, encryption, and access controls where the risk warrants.
- **Verify licensing/tenant** before relying on any endpoint, EDM, or advanced-classifier capability —
  plans and portal paths evolve; don't assume a feature is present.
- The **CDE scope, the enforced action per flow, the acceptable false-positive threshold, and PCI-DSS
  compliance/attestation are compliance/PCI/QSA determinations** — you provide the technical control and
  the evidence; they own the decision and the attestation.
