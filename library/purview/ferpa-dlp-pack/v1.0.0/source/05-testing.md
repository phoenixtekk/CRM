# 5. Testing & Validation — FERPA DLP Pack (Microsoft Purview)

Validate the education-record DLP implementation against explicit **pass/fail gates**. The three headline
gates are: **(A) record leaks are blocked**, **(B) the false-positive rate is low**, and **(C) incidents are
handled**. Run every test with **non-real, clearly-fake sample data** — fabricated student IDs, the
Microsoft-documented test SSN pattern, and dummy names — **never real student records or PII**. Record the
evidence.

> All tests assume the policies from the Implementation Guide, first proven in **simulation** and then
> enforced to the **pilot ring**. Endpoint tests require an **onboarded** device (Req 2.3).

---

## Test A — Detection & enforcement (record leaks are blocked)

| # | Test | Steps | Pass condition |
|---|---|---|---|
| A1 | Email match blocked | From a pilot-ring user, send an email to an **external** recipient containing a fabricated roster with enough fake student IDs/SSNs to meet the threshold. | Message is blocked/encrypted per the enforced action; sender sees the policy tip; a DLP alert is raised. |
| A2 | SharePoint/OneDrive external share blocked | As a ring user, upload a fake gradebook with the education-record SIT and attempt to share it **externally**. | External sharing is blocked/restricted on match; event appears in Activity Explorer. |
| A3 | Teams message match | Paste fabricated student-ID/record content into a Teams chat/channel covered by the policy. | Message is blocked or tipped per the enforced action; event logged. |
| A4 | Endpoint — USB copy | On an onboarded ring device, copy a fake records file to **removable media**. | Activity is audited/blocked per policy; endpoint DLP event appears in Activity Explorer. |
| A5 | Endpoint — print / cloud upload | On the ring device, attempt to **print** the fake records file and **upload** it to an unallowed cloud app/browser. | Each activity is audited/restricted per policy; events logged. |
| A6 | Below-threshold negative | Send content with **fewer** student IDs than the threshold (or lower confidence). | Correctly **not** matched — confirms the threshold/confidence tuning holds. |

**Gate A (pass):** A1–A5 each produce the enforced action and a logged event; A6 correctly does not match.

---

## Test B — False-positive rate (adoption gate)

| # | Test | Steps | Pass condition |
|---|---|---|---|
| B1 | Simulation FP baseline | Over the agreed dwell time, export simulation matches (`DLPFERPA-Report.ps1 -Days <n>`) and classify each as TP/FP. | **False-positive rate ≤ the agreed threshold** (define with the FERPA function; a common target is ≤10% of matches, or an absolute FP count the triage team can absorb). |
| B2 | Legitimate-traffic negative | Run representative legitimate academic content (no real student data) through the covered channels — internal course materials, reference numbers, non-record documents. | Legitimate traffic is **not** matched — no spurious tips/blocks. |
| B3 | Student-ID SIT precision | Send documents containing unrelated numbers with the same digit length as a student ID but no supporting keywords. | The `Student ID – Custom SIT – FERPA` does **not** fire without its keyword/proximity context. |
| B4 | Post-tuning re-measure | After each tuning change (confidence↑, instance count↑, keywords, EDM, exceptions), re-simulate and re-measure. | FP rate trends **down** while true positives (Test A) still fire. |
| B5 | Override sanity | In the pilot ring, review captured **allow-with-justification** overrides. | Overrides are legitimate academic/administrative justifications, not routine bypass — if routine, re-tune or re-scope. |

**Gate B (pass):** measured FP rate at/under threshold on the simulation sample with true positives intact.

---

## Test C — Incident / alert handling (the control is operable)

| # | Test | Steps | Pass condition |
|---|---|---|---|
| C1 | Alert raised | Trigger a policy match (Test A1/A4). | A DLP **alert** appears in **Purview → Data loss prevention → Alerts** with the correct policy, severity, and evidence. |
| C2 | Triage workflow | The `FERPA DLP Alerts – Triage – Operations` owner/queue picks up the alert, sets status, and dispositions it. | Alert moves through the defined states to a resolved disposition by the named owner. |
| C3 | Activity Explorer trail | Locate the same event in **Data classification → Activity explorer**. | Full evidence trail present (user, location, SIT, action) for investigation. |
| C4 | Evidence access control | Confirm who can view the alert evidence (which may contain student PII). | Only appropriately-roled staff can view; least-privilege holds (Req 2.2/2.7). |
| C5 | SIEM forwarding (if configured) | Confirm the DLP event reaches the SIEM/Sentinel destination (Req 2.7). | Event present in the downstream system with usable fields. |

**Gate C (pass):** matches raise alerts, alerts are triaged to disposition by the owner with least-privilege
evidence access, and the trail (and SIEM forward, if used) is present.

---

## Simulation-first & rollback validation

| # | Test | Pass condition |
|---|---|---|
| S1 | Nothing enforced outside the ring | Users/devices **outside** `FERPA DLP Pilot Ring – Stage1` experience no blocking during pilot. |
| S2 | Instant rollback | Setting any enforced policy back to **simulation mode** immediately removes enforcement with no data change (verify a previously-blocked action now only simulates). |
| S3 | Scripts are safe-by-default | `DLPFERPA-Config.ps1` and `DLPFERPA-Set-Scope.ps1` run **without** `-Commit` make no change (`-WhatIf` output only); discovery/validate/report scripts are read-only. |

---

## Evidence to capture (for the deliverable record)
- Baseline posture CSV (Phase 0) and the education-record SIT coverage map.
- Simulation match export + TP/FP classification and the computed **false-positive rate** before/after
  tuning (Gate B).
- Screenshots/log of Test A enforcement actions and the raised alerts (Gate A/C).
- The dispositioned incident from Test C2, the evidence-access confirmation (C4), and, if used, the SIEM
  forward (C5).
- Confirmation that outside-ring users were unaffected (S1) and that simulation rollback works (S2).

> **Determination boundary.** These tests prove the **control works**. Whether a given record category's
> enforced action, its directory-vs-non-directory treatment, and the acceptable FP threshold are *acceptable*
> is a FERPA-compliance/registrar/legal sign-off, captured alongside the evidence above.
