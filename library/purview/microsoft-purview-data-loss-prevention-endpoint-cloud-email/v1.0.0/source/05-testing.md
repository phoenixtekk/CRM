# 5. Testing & Validation — Microsoft Purview Data Loss Prevention (DLP)

Validate the DLP implementation against explicit **pass/fail gates**. The three headline gates for this
solution are: **(A) leaks are blocked**, **(B) the false-positive rate is low**, and **(C) incidents are
handled**. Run every test with **non-real, clearly-fake sample data** (e.g. the Microsoft-documented test
credit-card number `4111 1111 1111 1111`) — never real customer/employee data — and record the evidence.

> All tests assume the policies from the Implementation Guide, first proven in **simulation** and then
> enforced to the **pilot ring**. Endpoint tests require an **onboarded** device (Req 2.3).

---

## Test A — Detection & enforcement (leaks are blocked)

| # | Test | Steps | Pass condition |
|---|---|---|---|
| A1 | Email match blocked | From a pilot-ring user, send an email to an **external** recipient containing enough fake SIT instances to meet the threshold. | Message is blocked/encrypted per the enforced action; sender sees the policy tip; a DLP alert is raised. |
| A2 | SharePoint/OneDrive external share blocked | As a ring user, upload a file with the fake SIT and attempt to share it **externally**. | External sharing is blocked/restricted on match; event appears in Activity Explorer. |
| A3 | Teams message match | Paste fake SIT content into a Teams chat/channel covered by the policy. | Message is blocked or tipped per the enforced action; event logged. |
| A4 | Endpoint — USB copy | On an onboarded ring device, copy a file containing the fake SIT to **removable media**. | Activity is audited/blocked per policy; endpoint DLP event appears in Activity Explorer. |
| A5 | Endpoint — print / cloud upload | On the ring device, attempt to **print** the file and **upload** it to an unallowed cloud app/browser. | Each activity is audited/restricted per policy; events logged. |
| A6 | Below-threshold negative | Send content with **fewer** SIT instances than the threshold (or lower confidence). | Correctly **not** matched — confirms the threshold/confidence tuning holds. |

**Gate A (pass):** A1–A5 each produce the enforced action and a logged event; A6 correctly does not match.

---

## Test B — False-positive rate (adoption gate)

| # | Test | Steps | Pass condition |
|---|---|---|---|
| B1 | Simulation FP baseline | Over the agreed dwell time, export simulation matches (`PURVDLP-Report.ps1 -Days <n>`) and classify each as TP/FP. | **False-positive rate ≤ the agreed threshold** (define with compliance; a common target is ≤10% of matches, or an absolute FP count the triage team can absorb). |
| B2 | Legitimate-traffic negative | Run representative legitimate business content (no real sensitive data) through the covered channels. | Legitimate traffic is **not** matched — no spurious tips/blocks. |
| B3 | Post-tuning re-measure | After each tuning change (confidence↑, instance count↑, keywords, EDM, exceptions), re-simulate and re-measure. | FP rate trends **down** while true positives (Test A) still fire. |
| B4 | Override sanity | In the pilot ring, review captured **allow-with-justification** overrides. | Overrides are legitimate business justifications, not routine bypass — if routine, re-tune or re-scope. |

**Gate B (pass):** measured FP rate at/under threshold on the simulation sample with true positives intact.

---

## Test C — Incident / alert handling (the control is operable)

| # | Test | Steps | Pass condition |
|---|---|---|---|
| C1 | Alert raised | Trigger a policy match (Test A1/A4). | A DLP **alert** appears in **Purview → Data loss prevention → Alerts** with the correct policy, severity, and evidence. |
| C2 | Triage workflow | The `DLP Alerts – Triage – Operations` owner/queue picks up the alert, sets status, and dispositions it. | Alert moves through the defined states to a resolved disposition by the named owner. |
| C3 | Activity Explorer trail | Locate the same event in **Data classification → Activity explorer**. | Full evidence trail present (user, location, SIT, action) for investigation. |
| C4 | SIEM forwarding (if configured) | Confirm the DLP event reaches the SIEM/Sentinel destination (Req 2.7). | Event present in the downstream system with usable fields. |

**Gate C (pass):** matches raise alerts, alerts are triaged to disposition by the owner, and the evidence
trail (and SIEM forward, if used) is present.

---

## Simulation-first & rollback validation

| # | Test | Pass condition |
|---|---|---|
| S1 | Nothing enforced outside the ring | Users/devices **outside** `DLP Pilot Ring – Stage1` experience no blocking during pilot. |
| S2 | Instant rollback | Setting any enforced policy back to **simulation mode** immediately removes enforcement with no data change (verify a previously-blocked action now only simulates). |
| S3 | Scripts are safe-by-default | `PURVDLP-Config.ps1` run **without** `-Commit` makes no change (`-WhatIf` output only); discovery/report/onboarding-check scripts are read-only. |

---

## Evidence to capture (for the deliverable record)
- Baseline posture CSV (Phase 0) and the SIT coverage map.
- Simulation match export + TP/FP classification and the computed **false-positive rate** before/after
  tuning (Gate B).
- Screenshots/log of Test A enforcement actions and the raised alerts (Gate A/C).
- The dispositioned incident from Test C2 and, if used, the SIEM forward (C4).
- Confirmation that outside-ring users were unaffected (S1) and that simulation rollback works (S2).

> **Determination boundary.** These tests prove the **control works**. Whether a given category's enforced
> action and FP threshold are *acceptable* is a compliance/privacy/legal sign-off, captured alongside the
> evidence above.
