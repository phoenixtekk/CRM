# 5. Testing & Validation — GDPR / PII DLP Pack (Microsoft Purview)

Validate the personal-data DLP implementation against explicit **pass/fail gates**. The three headline gates
are: **(A) personal-data leaks are blocked**, **(B) the false-positive rate is low**, and **(C) incidents are
handled**. Run every test with **non-real, clearly-fake sample data** — fabricated national-ID/IBAN values,
Microsoft-documented test patterns, and dummy names — **never real personal data or data-subject records**.
Record the evidence.

> All tests assume the policies from the Implementation Guide, first proven in **simulation** and then
> enforced to the **pilot ring**. Endpoint tests require an **onboarded** device (Req 2.3).

---

## Test A — Detection & enforcement (personal-data leaks are blocked)

| # | Test | Steps | Pass condition |
|---|---|---|---|
| A1 | Email match blocked | From a pilot-ring user, send an email to an **external** recipient containing a fabricated list with enough fake national-ID/IBAN values to meet the threshold. | Message is blocked/encrypted per the enforced action; sender sees the policy tip; a DLP alert is raised. |
| A2 | SharePoint/OneDrive external share blocked | As a ring user, upload a fake data-subject file with the EU-personal-data SIT and attempt to share it **externally**. | External sharing is blocked/restricted on match; event appears in Activity Explorer. |
| A3 | Teams message match | Paste fabricated national-ID/personal-data content into a Teams chat/channel covered by the policy. | Message is blocked or tipped per the enforced action; event logged. |
| A4 | Endpoint — USB copy | On an onboarded ring device, copy a fake data-subject file to **removable media**. | Activity is audited/blocked per policy; endpoint DLP event appears in Activity Explorer. |
| A5 | Endpoint — print / cloud upload | On the ring device, attempt to **print** the fake data-subject file and **upload** it to an unallowed cloud app/browser. | Each activity is audited/restricted per policy; events logged. |
| A6 | Cross-border / external-recipient awareness | Send the fabricated personal-data file to an **external** recipient where the *recipient is external* condition is configured. | The external-transfer condition contributes to the match / raises the flagged action; internal-only send behaves per its own rule. |
| A7 | Below-threshold negative | Send content with **fewer** identifiers than the threshold (or lower confidence). | Correctly **not** matched — confirms the threshold/confidence tuning holds. |

**Gate A (pass):** A1–A6 each produce the enforced action and a logged event; A7 correctly does not match.

---

## Test B — False-positive rate (adoption gate)

| # | Test | Steps | Pass condition |
|---|---|---|---|
| B1 | Simulation FP baseline | Over the agreed dwell time, export simulation matches (`DLPGDPR-Report.ps1 -Days <n>`) and classify each as TP/FP. | **False-positive rate ≤ the agreed threshold** (define with the DPO/privacy function; a common target is ≤10% of matches, or an absolute FP count the triage team can absorb). |
| B2 | Legitimate-traffic negative | Run representative legitimate business content (no real personal data) through the covered channels — internal reference numbers, non-record documents. | Legitimate traffic is **not** matched — no spurious tips/blocks. |
| B3 | Custom-SIT precision | Send documents containing unrelated numbers of the same length as a national ID / IBAN but with no supporting keywords. | The `EU National ID – Custom SIT – GDPR` does **not** fire without its keyword/proximity context. |
| B4 | Post-tuning re-measure | After each tuning change (confidence↑, instance count↑, keywords, EDM, exceptions), re-simulate and re-measure. | FP rate trends **down** while true positives (Test A) still fire. |
| B5 | Override sanity | In the pilot ring, review captured **allow-with-justification** overrides. | Overrides are legitimate business justifications, not routine bypass — if routine, re-tune or re-scope. |

**Gate B (pass):** measured FP rate at/under threshold on the simulation sample with true positives intact.

---

## Test C — Incident / alert handling (the control is operable)

| # | Test | Steps | Pass condition |
|---|---|---|---|
| C1 | Alert raised | Trigger a policy match (Test A1/A4). | A DLP **alert** appears in **Purview → Data loss prevention → Alerts** with the correct policy, severity, and evidence. |
| C2 | Triage workflow | The `GDPR DLP Alerts – Triage – Operations` owner/queue picks up the alert, sets status, and dispositions it. | Alert moves through the defined states to a resolved disposition by the named owner. |
| C3 | Breach hand-off | For a match representing a real personal-data exposure, exercise the hand-off to the **DPO/breach-assessment** process. | The DPO/legal function receives the evidence and records the breach-notification determination (the determination itself is theirs, not the control's). |
| C4 | Activity Explorer trail | Locate the same event in **Data classification → Activity explorer**. | Full evidence trail present (user, location, SIT, action) for investigation. |
| C5 | Evidence access control | Confirm who can view the alert evidence (which contains personal data). | Only appropriately-roled staff can view; least-privilege / data-minimisation holds (Req 2.2/2.7). |
| C6 | SIEM forwarding (if configured) | Confirm the DLP event reaches the SIEM/Sentinel destination (Req 2.7). | Event present in the downstream system with usable fields. |

**Gate C (pass):** matches raise alerts, alerts are triaged to disposition by the owner with least-privilege
evidence access, the DPO/breach hand-off works, and the trail (and SIEM forward, if used) is present.

---

## Simulation-first & rollback validation

| # | Test | Pass condition |
|---|---|---|
| S1 | Nothing enforced outside the ring | Users/devices **outside** `GDPR DLP Pilot Ring – Stage1` experience no blocking during pilot. |
| S2 | Instant rollback | Setting any enforced policy back to **simulation mode** immediately removes enforcement with no data change (verify a previously-blocked action now only simulates). |
| S3 | Scripts are safe-by-default | `DLPGDPR-Config.ps1` and `DLPGDPR-Set-Scope.ps1` run **without** `-Commit` make no change (`-WhatIf` output only); discovery/validate/report scripts are read-only. |

---

## Evidence to capture (for the deliverable record)
- Baseline posture CSV (Phase 0) and the EU-personal-data SIT coverage map.
- Simulation match export + TP/FP classification and the computed **false-positive rate** before/after
  tuning (Gate B).
- Screenshots/log of Test A enforcement actions and the raised alerts (Gate A/C).
- The dispositioned incident from Test C2, the DPO/breach hand-off record (C3), the evidence-access
  confirmation (C5), and, if used, the SIEM forward (C6).
- Confirmation that outside-ring users were unaffected (S1) and that simulation rollback works (S2).

> **Determination boundary.** These tests prove the **control works**. Whether a given data category's
> enforced action, its special-category/lawful-basis treatment, whether a transfer is restricted, and the
> acceptable FP threshold are *acceptable* is a data-protection/privacy (DPO)/legal sign-off, captured
> alongside the evidence above.
