# 5. Testing & Validation — HIPAA / PHI DLP Pack (Microsoft Purview)

Validate the PHI DLP implementation against explicit **pass/fail gates**. The three headline gates for
this solution are: **(A) PHI leaks are blocked**, **(B) the false-positive rate is low**, and **(C)
incidents are handled and escalated**. Run every test with **non-real, clearly-fake test data** — a
made-up MRN, the Microsoft-documented test SSN pattern, and a random ICD-10 code applied to a fake
patient — **never real PHI**, and record the evidence.

> All tests assume the policies from the Implementation Guide, first proven in **simulation** and then
> enforced to the **pilot ring**. Endpoint tests require an **onboarded** device (Req 2.3). PHI matches
> best on a **combination** (identifier + clinical detector), so build test samples that pair a fake
> SSN/MRN with a fake ICD code.

---

## Test A — Detection & enforcement (PHI leaks are blocked)

| # | Test | Steps | Pass condition |
|---|---|---|---|
| A1 | Email PHI blocked/encrypted | From a pilot-ring user, send an email to an **external** recipient containing a fake SSN/MRN paired with a fake ICD-10 code. | Message is blocked or **encrypted** per the enforced action; sender sees the policy tip; a DLP alert is raised. |
| A2 | SharePoint/OneDrive external share blocked | As a ring user, upload a file with the fake PHI combination and attempt to share it **externally**. | External sharing is blocked/restricted on match; event appears in Activity Explorer. |
| A3 | Teams message match | Paste the fake PHI combination into a Teams chat/channel covered by the policy. | Message is blocked or tipped per the enforced action; event logged. |
| A4 | Endpoint — USB copy | On an onboarded ring device, copy a file containing the fake PHI to **removable media**. | Activity is audited/blocked per policy; endpoint DLP event appears in Activity Explorer. |
| A5 | Endpoint — print / cloud upload | On the ring device, attempt to **print** the file and **upload** it to an unallowed cloud app/browser. | Each activity is audited/restricted per policy; events logged. |
| A6 | Below-threshold / single-detector negative | Send content with only a lone ICD code or a lone 9-digit number (no pairing), below the threshold. | Correctly **not** matched (if co-occurrence is required) — confirms tuning holds and avoids false positives. |

**Gate A (pass):** A1–A5 each produce the enforced action and a logged event; A6 correctly does not
match (validating the PHI co-occurrence/threshold tuning).

---

## Test B — False-positive rate (adoption gate)

| # | Test | Steps | Pass condition |
|---|---|---|---|
| B1 | Simulation FP baseline | Over the agreed dwell time, export simulation matches (`PHIDLP-Report.ps1 -Days <n>`) and classify each as TP/FP. | **False-positive rate ≤ the agreed threshold** (define with compliance; a common target is ≤10% of matches, or an absolute FP count the triage team can absorb). |
| B2 | Legitimate-traffic negative | Run representative legitimate business content (no real PHI) — e.g. internal reference numbers, order IDs — through the covered channels. | Legitimate traffic is **not** matched — no spurious tips/blocks on non-PHI numbers. |
| B3 | Post-tuning re-measure | After each tuning change (co-occurrence, confidence↑, instance count↑, keywords, EDM, exceptions), re-simulate and re-measure. | FP rate trends **down** while true PHI positives (Test A) still fire. |
| B4 | Override sanity | In the pilot ring, review captured **allow-with-justification** overrides. | Overrides are legitimate clinical/billing justifications, not routine bypass — if routine, re-tune or re-scope. |

**Gate B (pass):** measured FP rate at/under threshold on the simulation sample with true PHI positives
intact.

---

## Test C — Incident / alert handling & escalation (the control is operable)

| # | Test | Steps | Pass condition |
|---|---|---|---|
| C1 | Alert raised | Trigger a policy match (Test A1/A4). | A DLP **alert** appears in **Purview → Data loss prevention → Alerts** with the correct policy, severity, and evidence. |
| C2 | Triage workflow | The `PHI DLP Alerts – Triage – Operations` owner/queue picks up the alert, sets status, and dispositions it. | Alert moves through the defined states to a resolved disposition by the named owner. |
| C3 | Privacy/Security escalation | For a match that *could* be a reportable disclosure, exercise the escalation path to the HIPAA Privacy/Security Officer. | The escalation path works and is documented; the **breach determination is made by Privacy/Security/legal, not the DLP tool**. |
| C4 | Activity Explorer trail | Locate the same event in **Data classification → Activity explorer**. | Full evidence trail present (user, location, SIT, action) for investigation. |
| C5 | SIEM forwarding (if configured) | Confirm the DLP event reaches the SIEM/Sentinel destination (Req 2.7). | Event present in the downstream system with usable fields. |

**Gate C (pass):** matches raise alerts, alerts are triaged to disposition by the owner, the
Privacy/Security escalation path is exercised, and the evidence trail (and SIEM forward, if used) is
present.

---

## Simulation-first & rollback validation

| # | Test | Pass condition |
|---|---|---|
| S1 | Nothing enforced outside the ring | Users/devices **outside** `PHI DLP Pilot Ring – Stage1` experience no blocking during pilot. |
| S2 | Instant rollback | Setting any enforced policy back to **simulation mode** immediately removes enforcement with no data change (verify a previously-blocked action now only simulates). |
| S3 | Scripts are safe-by-default | `PHIDLP-Config.ps1` run **without** `-Commit` makes no change (`-WhatIf` output only) and is simulation-only; discovery/validate/report scripts are read-only; the scope/health helper writes only with `-Commit`. |
| S4 | Validate gate check | `PHIDLP-Validate.ps1` reports each expected policy's mode, PHI-SIT presence, and scope — a green pass before enforcement, and the enforced state after. |

---

## Evidence to capture (for the HIPAA control record)
- Baseline posture CSV (Phase 0) and the HIPAA-SIT coverage map.
- Simulation match export + TP/FP classification and the computed **false-positive rate** before/after
  tuning (Gate B).
- Screenshots/log of Test A enforcement/encryption actions and the raised alerts (Gate A/C).
- The dispositioned incident from Test C2, the **Privacy/Security escalation** evidence from C3, and, if
  used, the SIEM forward (C5).
- Confirmation that outside-ring users were unaffected (S1) and that simulation rollback works (S2).
- The `PHIDLP-Validate.ps1` output showing the expected policy/mode/SIT/scope state (S4).

> **Determination boundary.** These tests prove the **control works**. Whether a given category's
> enforced action and FP threshold are *acceptable*, and whether any real event is a **reportable HIPAA
> breach**, are compliance/privacy/legal sign-offs, captured alongside the evidence above.
