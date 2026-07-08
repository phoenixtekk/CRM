# 5. Testing & Validation — OneDrive for Business DLP (Microsoft Purview)

Validate the OneDrive DLP implementation against explicit **pass/fail gates**. The three headline gates
for this solution are: **(A) sensitive content and risky shares are caught**, **(B) the false-positive
rate is low**, and **(C) incidents are handled**. Run every test with **non-real, clearly-fake sample
data** (e.g. the Microsoft-documented test credit-card number `4111 1111 1111 1111`) — never real
customer/employee data — and record the evidence.

> All tests assume the policies from the Implementation Guide, first proven in **simulation** and then
> enforced to the **pilot ring** (`DLP OneDrive Pilot Ring – Stage1`).

---

## Test A — Detection & enforcement (sensitive content and risky shares are caught)

| # | Test | Steps | Pass condition |
|---|---|---|---|
| A1 | At-rest sensitive content | As a pilot-ring user, upload a file to OneDrive containing enough fake SIT instances to meet the at-rest threshold. | Match recorded (simulation) or restricted (enforced) per the `DLP – OneDrive Sensitive` policy; event appears in Activity Explorer (OneDrive workload). |
| A2 | External "anyone with the link" share | As a ring user, share a file containing the fake SIT with an **"anyone with the link"** option. | The `DLP – OneDrive External Share` rule matches; per enforced action the anyone-link/external access is restricted; a DLP alert is raised. |
| A3 | External direct share | Share the fake-SIT file directly to an **external** email address. | Rule matches on *shared with people outside my organization*; external access restricted per policy; event logged. |
| A4 | Internal share negative | Share the fake-SIT file **only with an internal colleague** (no external link). | External-share rule correctly does **not** restrict — internal collaboration is untouched (at-rest rule may still record the content). |
| A5 | Policy tip shown | On an enforced ring account, trigger A1/A2. | The `DLP Notice – OneDrive – Standard` policy tip is shown to the user; override-with-justification is offered where configured. |
| A6 | Below-threshold negative | Store content with **fewer** SIT instances than the at-rest threshold (or lower confidence). | Correctly **not** matched by the at-rest rule — confirms the threshold/confidence tuning holds. |

**Gate A (pass):** A1–A3 each produce the enforced action and a logged event; A4 and A6 correctly do
**not** restrict; A5 shows the tip/override.

---

## Test B — False-positive rate (adoption gate)

| # | Test | Steps | Pass condition |
|---|---|---|---|
| B1 | Simulation FP baseline | Over the agreed dwell time, export simulation matches (`DLPOD-Report.ps1 -Days <n>`) and classify each as TP/FP. | **False-positive rate ≤ the agreed threshold** (define with compliance; a common target is ≤10% of matches, or an absolute FP count the triage team can absorb). |
| B2 | Legitimate-traffic negative | Store and share representative legitimate business content (no real sensitive data) in a ring account. | Legitimate content is **not** matched/restricted — no spurious tips or blocked shares. |
| B3 | Post-tuning re-measure | After each tuning change (confidence↑, instance count↑, keywords, EDM, exceptions), re-simulate and re-measure. | FP rate trends **down** while true positives (Test A) still fire. |
| B4 | Override sanity | In the pilot ring, review captured **allow-with-justification** overrides. | Overrides are legitimate business justifications, not routine bypass — if routine, re-tune or re-scope. |

**Gate B (pass):** measured FP rate at/under threshold on the simulation sample with true positives
(including external over-shares) intact.

---

## Test C — Incident / alert handling (the control is operable)

| # | Test | Steps | Pass condition |
|---|---|---|---|
| C1 | Alert raised | Trigger a policy match (Test A1/A2). | A DLP **alert** appears in **Purview → Data loss prevention → Alerts** with the correct policy, severity, and evidence. |
| C2 | Triage workflow | The `DLP Alerts – OneDrive – Triage` owner/queue picks up the alert, sets status, and dispositions it. | Alert moves through the defined states to a resolved disposition by the named owner. |
| C3 | Activity Explorer trail | Locate the same event in **Data classification → Activity explorer** (OneDrive workload). | Full evidence trail present (user, file, SIT, sharing state, action) for investigation. |
| C4 | SIEM forwarding (if configured) | Confirm the DLP event reaches the SIEM/Sentinel destination (Req 2.7). | Event present in the downstream system with usable fields. |

**Gate C (pass):** matches raise alerts, alerts are triaged to disposition by the owner, and the evidence
trail (and SIEM forward, if used) is present.

---

## Simulation-first & rollback validation

| # | Test | Pass condition |
|---|---|---|
| S1 | Nothing enforced outside the ring | Accounts **outside** `DLP OneDrive Pilot Ring – Stage1` experience no restriction during pilot. |
| S2 | Instant rollback | Setting any enforced policy back to **simulation mode** immediately removes enforcement with no data change (verify a previously-restricted external share now only simulates). |
| S3 | Scripts are safe-by-default | `DLPOD-Config.ps1` / `DLPOD-Scope.ps1` run **without** `-Commit` make no change (`-WhatIf` output only); discovery/report/validate scripts are read-only. |

---

## Evidence to capture (for the deliverable record)
- Baseline posture CSV (Phase 0) and the SIT coverage map.
- Simulation match export + TP/FP classification and the computed **false-positive rate** before/after
  tuning (Gate B).
- Screenshots/log of Test A enforcement actions (at-rest match + external-share restriction) and the
  raised alerts (Gate A/C).
- The dispositioned incident from Test C2 and, if used, the SIEM forward (C4).
- Confirmation that outside-ring accounts were unaffected (S1) and that simulation rollback works (S2).
- The `DLPOD-Validate.ps1` output summarizing the OneDrive policy modes, scope, and readiness signals.

> **Determination boundary.** These tests prove the **control works**. Whether a given category's
> enforced action (e.g. block external sharing outright) and FP threshold are *acceptable* is a
> compliance/privacy/legal sign-off, captured alongside the evidence above.
