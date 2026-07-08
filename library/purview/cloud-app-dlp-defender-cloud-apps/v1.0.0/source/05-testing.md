# 5. Testing & Validation — Cloud-App DLP (Defender for Cloud Apps)

Validate the cloud-app DLP implementation against explicit **pass/fail gates**. The three headline gates
are: **(A) cloud-app leaks are controlled** (file governance at rest + real-time session control),
**(B) the false-positive rate is low**, and **(C) incidents are handled**. Run every test with **non-real,
clearly-fake sample data** (e.g. the Microsoft-documented test credit-card number `4111 1111 1111 1111`) —
never real customer/employee data — and record the evidence.

> All tests assume the policies from the Implementation Guide, first proven in **test mode** (CA policy
> report-only, session policies Monitor only, file policies alert-only) and then enforced to the **pilot
> ring**. File-policy tests require a **connected app** (Req 2.3); session tests require **Conditional
> Access App Control routing** (Req 2.4).

---

## Test A — Detection & control (leaks are controlled)

### A(i) — File policy (data at rest, via API connector)

| # | Test | Steps | Pass condition |
|---|---|---|---|
| A1 | At-rest match detected | In a **connected** app, place a file containing enough fake SIT instances (or the target sensitivity label) to meet the policy filter. | The file policy matches it; a match/alert appears in **Cloud apps** within the connector scan interval. |
| A2 | Remove-sharing governance | On a matching file shared externally/publicly, let the enforcing file policy act (or run its governance action). | External/public sharing is **removed**; the change is logged as a governance action. |
| A3 | Apply-label / quarantine governance | For a category whose determination is *apply label* or *quarantine*, confirm the action. | The **sensitivity label is applied** / the file is **quarantined** per policy; action logged. |

### A(ii) — Session policy (real time, via CA App Control)

| # | Test | Steps | Pass condition |
|---|---|---|---|
| A4 | Block download to unmanaged device | As a pilot-ring user on an **unmanaged** device, open the CA-App-Control app and attempt to **download** content matching the SIT/label. | Download is **blocked** per the session policy; user sees the block message; activity logged. |
| A5 | Protect on download | Where the action is *Protect*, download matching content. | The file is **protected on download** (label/encryption applied) rather than delivered in the clear; logged. |
| A6 | Upload / copy / print (if scoped) | Attempt a scoped activity (upload matching content, copy/paste, or print) in the session. | The activity is **monitored or blocked** per the session policy; logged. |
| A7 | Below-threshold / non-matching negative | Perform the same activities with content that does **not** meet the SIT confidence/instance count or lacks the label. | Correctly **not** controlled — confirms the match tuning holds. |

**Gate A (pass):** A1–A6 each produce the configured control (governance action / block / protect) and a
logged event; A7 correctly does not trigger.

---

## Test B — False-positive rate (adoption gate)

| # | Test | Steps | Pass condition |
|---|---|---|---|
| B1 | Test-mode FP baseline | Over the agreed dwell time (CA report-only, session Monitor-only, file alert-only), export matches (`DLPCLOUD-Report.ps1 -Days <n>`) and classify each as TP/FP. | **False-positive rate ≤ the agreed threshold** (define with compliance; a common target is ≤10% of matches, or an absolute FP count the triage team can absorb). |
| B2 | Legitimate-traffic negative | Run representative legitimate business content/activity (no real sensitive data) through the connected/CA-App-Control apps. | Legitimate traffic is **not** matched — no spurious governance/blocks. |
| B3 | Post-tuning re-measure | After each tuning change (confidence↑, instance count↑, narrower app/folder/sharing filter, label match, exclusions), re-measure. | FP rate trends **down** while true positives (Test A) still fire. |
| B4 | Session UX sanity | In the pilot ring, review real-time **block/monitor** events for legitimate work caught. | Blocks/monitors are on genuine sensitive activity, not routine legitimate work — if routine, re-tune or re-scope. |

**Gate B (pass):** measured FP rate at/under threshold on the test sample with true positives intact.

---

## Test C — Incident / alert handling (the control is operable)

| # | Test | Steps | Pass condition |
|---|---|---|---|
| C1 | Alert raised | Trigger a file-policy match (A1) or a session block (A4). | An **alert** appears in **Cloud apps → Alerts** (and as an incident in the Defender portal / Graph security alerts) with the correct policy, severity, and evidence. |
| C2 | Triage workflow | The `MDCA Alerts – Triage – Operations` owner/queue picks up the alert, sets status, and dispositions it. | Alert moves through the defined states to a resolved disposition by the named owner. |
| C3 | Evidence trail | Locate the same event in the Cloud-apps **activity/file** views (and via `DLPCLOUD-Report.ps1`). | Full evidence trail present (user, app, file, SIT/label, action) for investigation. |
| C4 | SIEM forwarding (if configured) | Confirm the alert reaches the SIEM/Sentinel destination (Req 2.7). | Event present downstream with usable fields. |

**Gate C (pass):** matches raise alerts, alerts are triaged to disposition by the owner, and the evidence
trail (and SIEM forward, if used) is present.

---

## Test-mode-first & rollback validation

| # | Test | Pass condition |
|---|---|---|
| S1 | Nothing enforced outside the ring | Users/devices **outside** `MDCA Pilot Ring – Stage1` experience no block/protect/governance during pilot (the CA policy assignment and file scope exclude them). |
| S2 | Instant session rollback | Setting the **Entra CA policy back to report-only** (or the session policy to **Monitor only**) immediately removes real-time enforcement with no data change (verify a previously-blocked download now only monitors). |
| S3 | File-governance rollback | Disabling the file policy's enforcing governance action stops further at-rest changes. *(Already-applied label/quarantine/trash may require manual reversal — record this.)* |
| S4 | Scripts are safe-by-default | `DLPCLOUD-FilePolicy.ps1` run **without** `-Commit` makes no change (`-WhatIf`/spec output only); discovery/readiness/report scripts are read-only. |

---

## Evidence to capture (for the deliverable record)
- Baseline posture CSV (Phase 0): labels/SITs available, connected apps, CA App Control state.
- Test-mode match export + TP/FP classification and the computed **false-positive rate** before/after
  tuning (Gate B).
- Screenshots/log of Test A file-governance and session block/protect actions and the raised alerts
  (Gate A/C).
- The dispositioned incident from Test C2 and, if used, the SIEM forward (C4).
- Confirmation that outside-ring users were unaffected (S1) and that report-only/Monitor rollback works
  (S2), plus any manual at-rest reversal performed (S3).

> **Determination boundary.** These tests prove the **control works**. Whether a given category's
> governance/session action and FP threshold are *acceptable* is a compliance/privacy/legal sign-off,
> captured alongside the evidence above.
