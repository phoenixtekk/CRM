# 5. Testing & Validation — PCI-DSS DLP Pack (Microsoft Purview)

Validate the cardholder-data DLP implementation against explicit **pass/fail gates**. The three headline
gates for this solution are: **(A) PAN leaks are blocked**, **(B) the false-positive rate is low**, and
**(C) incidents are handled**. Run every test with **non-real, clearly-fake test PANs** — use the standard
documented test card numbers (e.g. Visa test PAN `4111 1111 1111 1111`, or `4242 4242 4242 4242`) — and
**never real cardholder data**. Record the evidence.

> All tests assume the policies from the Implementation Guide, first proven in **simulation** and then
> enforced to the **pilot ring**. Endpoint tests require an **onboarded** device (Req 2.3). Test PANs are
> Luhn-valid but not issued to any account, so they exercise the detector without handling real card data.

---

## Test A — Detection & enforcement (PAN leaks are blocked)

| # | Test | Steps | Pass condition |
|---|---|---|---|
| A1 | Email PAN blocked | From a pilot-ring user, send an email to an **external** recipient containing a fake test PAN (enough instances to meet the threshold). | Message is blocked/encrypted per the enforced action; sender sees the policy tip; a DLP alert is raised. |
| A2 | SharePoint/OneDrive external share blocked | As a ring user, upload a file containing a fake test PAN and attempt to share it **externally**. | External sharing is blocked/restricted on match; event appears in Activity Explorer. |
| A3 | Teams PAN message | Paste a fake test PAN into a Teams chat/channel covered by the policy. | Message is blocked or tipped per the enforced action; event logged. |
| A4 | Endpoint — USB copy | On an onboarded ring device, copy a file containing a fake test PAN to **removable media**. | Activity is audited/blocked per policy; endpoint DLP event appears in Activity Explorer. |
| A5 | Endpoint — print / cloud upload | On the ring device, attempt to **print** the PAN file and **upload** it to an unallowed cloud app/browser. | Each activity is audited/restricted per policy; events logged. |
| A6 | Truncated-PAN / below-threshold negative | Send a **truncated** PAN (first-six/last-four per PCI display rules) or fewer PAN instances than the threshold. | Correctly **not** matched — confirms truncated PANs and threshold tuning don't over-fire. |

**Gate A (pass):** A1–A5 each produce the enforced action and a logged event; A6 correctly does not match.

---

## Test B — False-positive rate (adoption gate)

| # | Test | Steps | Pass condition |
|---|---|---|---|
| B1 | Simulation FP baseline | Over the agreed dwell time, export simulation matches (`PURVPCI-Report.ps1 -Days <n>`) and classify each as TP (real PAN) / FP. | **False-positive rate ≤ the agreed threshold** (define with compliance; a common target is ≤10% of matches, or an absolute FP count the triage team can absorb). |
| B2 | Internal-reference-number negative | Run representative legitimate business content containing **Luhn-valid internal reference/order numbers** (no real card data) through the covered channels. | Internal numbers are **not** matched as PAN — no spurious tips/blocks. |
| B3 | Post-tuning re-measure | After each tuning change (confidence↑, instance count↑, keywords, EDM, exceptions), re-simulate and re-measure. | FP rate trends **down** while true PAN positives (Test A) still fire. |
| B4 | Override sanity | In the pilot ring, review captured **allow-with-justification** overrides. | Overrides are legitimate business justifications, not routine bypass — if routine, re-tune or re-scope. |

**Gate B (pass):** measured FP rate at/under threshold on the simulation sample with real-PAN detection
intact.

---

## Test C — Incident / alert handling (the control is operable)

| # | Test | Steps | Pass condition |
|---|---|---|---|
| C1 | Alert raised | Trigger a PAN match (Test A1/A4). | A DLP **alert** appears in **Purview → Data loss prevention → Alerts** with the correct policy, severity, and evidence. |
| C2 | Triage workflow | The `PCI DLP Alerts – Triage – Operations` owner/queue picks up the alert, sets status, and dispositions it per the incident-response plan. | Alert moves through the defined states to a resolved disposition by the named owner. |
| C3 | Activity Explorer trail | Locate the same event in **Data classification → Activity explorer**. | Full evidence trail present (user, location, SIT, action) for investigation and assessor evidence. |
| C4 | SIEM forwarding (if configured) | Confirm the DLP event reaches the SIEM/Sentinel destination (Req 2.7). | Event present in the downstream system with usable fields. |

**Gate C (pass):** PAN matches raise alerts, alerts are triaged to disposition by the owner, and the
evidence trail (and SIEM forward, if used) is present.

---

## Simulation-first & rollback validation

| # | Test | Pass condition |
|---|---|---|
| S1 | Nothing enforced outside the ring | Users/devices **outside** `PCI DLP Pilot Ring – Stage1` experience no blocking during pilot. |
| S2 | Instant rollback | Setting any enforced policy back to **simulation mode** immediately removes enforcement with no data change (verify a previously-blocked PAN action now only simulates). |
| S3 | Scripts are safe-by-default | `PURVPCI-Config.ps1` / `PURVPCI-Set-Scope.ps1` run **without** `-Commit` make no change (`-WhatIf` output only); discovery/report/endpoint-check scripts are read-only. |

---

## Evidence to capture (for the deliverable record / assessor)
- Baseline posture CSV (Phase 0) and confirmation the Credit Card Number SIT is present.
- Simulation match export + TP/FP classification and the computed **false-positive rate** before/after
  tuning (Gate B).
- Screenshots/log of Test A enforcement actions on **fake test PANs** and the raised alerts (Gate A/C).
- The dispositioned incident from Test C2 and, if used, the SIEM forward (C4).
- Confirmation that outside-ring users were unaffected (S1) and that simulation rollback works (S2).
- The change log of each simulate→enforce transition with the compliance sign-off attached.

> **Determination boundary.** These tests prove the **control works** and produce evidence. Whether the
> enforced action, the FP threshold, and the CDE scope are *acceptable for PCI-DSS* is a compliance/QSA
> sign-off, captured alongside the evidence above — this solution does not attest to compliance.
