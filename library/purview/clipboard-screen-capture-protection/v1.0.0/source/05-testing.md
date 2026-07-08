# 5. Testing & Validation — Clipboard & Screen-Capture Protection (Microsoft Purview)

Validate the Endpoint DLP implementation against explicit **pass/fail gates**. The three headline gates are:
**(A) clipboard/screen-capture of sensitive content is restricted**, **(B) the false-positive rate is low**,
and **(C) incidents are handled and evidenced**. Run every test with **non-real, clearly-fake sample
content** — a test document containing a **fake SIT match** (e.g. the Microsoft test credit-card number
`4111 1111 1111 1111`) and/or carrying the optional **`Confidential – No-Copy – Endpoint`** sensitivity
label — **never** real sensitive data. Record the evidence; it supports the control narrative (whether the
control is *required* and the *enforced action* per category stays a **compliance/privacy/legal**
determination).

> All tests assume the policy from the Implementation Guide, first proven in **simulation** as
> **`DLP – Endpoint Clipboard+Screen – Simulation`** (rule **`DLP – Endpoint Clipboard+Screen – Rule`**) and
> then enforced to the **`DLP Pilot Ring – Stage1`** as **`DLP – Endpoint Clipboard+Screen – Enforce Pilot`**.
> Every endpoint test requires an **onboarded** device (Req 2.3) that meets the minimum OS build. **Screen-
> capture restriction is newer / may be in preview and is OS-/app-gated — verify your licensing/tenant**; if
> it is not available, run the clipboard tests and mark the screen-capture rows *"verify in tenant."**

---

## Test A — Detection & enforcement (clipboard/screen-capture of sensitive content is restricted)

| # | Test | Steps | Pass condition |
|---|---|---|---|
| A1 | Clipboard → unallowed browser/app | On an onboarded ring device, open the fake sensitive test file, **copy** matching content, and **paste** it into an **unallowed** browser or app (e.g. a personal webmail tab). | The paste is audited (simulation) or blocked/tipped (enforce) per the action; the `DLP Notice – Clipboard/Screen – Standard` tip appears when enforced; an endpoint DLP event is logged. |
| A2 | Screen capture of sensitive content | With the fake sensitive file on screen, take a **screenshot** (Print Screen / Snipping Tool / a supported capture app). | The capture is audited or blocked per the action; event logged. **If screen capture is unavailable in your tenant, record "verify in tenant" and skip.** |
| A3 | Label-based match (optional) | Apply the **`Confidential – No-Copy – Endpoint`** label to a fake file, then repeat A1/A2. | The rule fires on the **sensitivity-label** condition (not just the SIT) — confirms the label signal works and is more precise. |
| A4 | Allowed-app / sanctioned workflow negative | **Copy-paste** the same content **between two sanctioned internal apps** (on the Endpoint DLP **allowed** list) and screenshot a normal, non-sensitive page. | Sanctioned copy-paste and non-sensitive screenshots are correctly **not** restricted — confirms the allowed-app/browser exceptions and conditions hold. |
| A5 | Below-threshold negative | Copy content that is **below** the configured confidence/instance count (e.g. a single low-confidence fragment). | Correctly **not** matched — confirms the confidence/instance tuning is doing its job. |

**Gate A (pass):** A1–A3 each produce the configured action and a logged endpoint event; A4–A5 correctly do
not fire.

---

## Test B — False-positive rate (adoption gate)

| # | Test | Steps | Pass condition |
|---|---|---|---|
| B1 | Simulation FP baseline | Over the agreed dwell time, export simulation matches (`DLPCLIP-Report.ps1 -Days <n>`) and classify each clipboard/screen-capture match as TP/FP. | **False-positive rate ≤ the agreed threshold** (define with compliance; label-keyed matching should be very precise, so target a low absolute FP count the triage team can absorb). |
| B2 | "Mentions but isn't" negative | Run legitimate content that merely resembles a pattern (e.g. a training doc that contains a formatted-but-invalid number) through a normal copy. | Not matched — confirms confidence/instance count and (where used) keyword proximity carry the weight. |
| B3 | Post-tuning re-measure | After each tuning change (raise confidence/instance, add label condition, add allowed-app/browser exception, add EDM), re-simulate and re-measure. | FP rate trends **down** while true positives (Test A) still fire. |
| B4 | Override sanity | In the pilot ring, review captured **allow-with-justification** overrides on clipboard/screen-capture. | Overrides are legitimate business justifications, not routine bypass — if routine, re-tune or re-scope. |

**Gate B (pass):** measured FP rate at/under threshold on the simulation sample with true positives intact.

---

## Test C — Incident / alert handling & evidence (the control is operable and auditable)

| # | Test | Steps | Pass condition |
|---|---|---|---|
| C1 | Alert raised | Trigger a match (Test A1/A2). | A DLP **alert** appears in **Purview → Data loss prevention → Alerts** with the correct policy, severity, and evidence. |
| C2 | Triage workflow | The `DLP Alerts – Clipboard/Screen – Operations` owner/queue picks up the alert, sets status, and dispositions it. | Alert moves through the defined states to a resolved disposition by the named owner. |
| C3 | Activity Explorer evidence trail | Locate the same event in **Data classification → Activity explorer** (filter to *copy to clipboard* / *screen capture*) and **export** it. | Full evidence trail present (user, device, app/browser, label/SIT, action) and retained for audit. |
| C4 | SIEM forwarding (if configured) | Confirm the endpoint DLP event reaches the SIEM/Sentinel destination (Req 2.7). | Event present in the downstream system with usable fields. |

**Gate C (pass):** matches raise alerts, alerts are triaged to disposition by the owner, and the retained
evidence trail (and SIEM forward, if used) is present.

---

## Simulation-first & rollback validation

| # | Test | Pass condition |
|---|---|---|
| S1 | Nothing enforced outside the ring | Users/devices **outside** `DLP Pilot Ring – Stage1` experience no clipboard/screen-capture blocking during pilot. |
| S2 | Instant rollback | Setting the enforced policy back to **simulation mode** immediately removes enforcement with no data change (verify a previously-blocked copy/screenshot now only simulates). |
| S3 | Scripts are safe-by-default | `DLPCLIP-Configure.ps1` / `DLPCLIP-ScopeHealth.ps1` run **without** `-Commit` make no change (`-WhatIf` output only); discovery/validate/report scripts are read-only. |

---

## Evidence to capture (for the deliverable record & control narrative)
- Baseline posture CSV (Phase 0), the endpoint-readiness output, and the SIT/label coverage map.
- Simulation match export + TP/FP classification and the computed **false-positive rate** before/after
  tuning (Gate B).
- Screenshots/log of Test A enforcement actions (clipboard **and** screen capture, and the optional
  label-based match) and the raised alerts (Gate A/C).
- The dispositioned, retained incident from Test C2/C3 and, if used, the SIEM forward (C4).
- Confirmation that outside-ring users were unaffected (S1) and that simulation rollback works (S2).

> **Determination boundary.** These tests prove the **control works** and produce the **evidence**. Whether
> the control is *required* for a given data category, the **acceptable false-positive threshold**, and the
> **enforced action** (audit vs block-with-override vs hard block) per category are **compliance / privacy /
> legal** sign-offs, captured alongside the evidence above.
