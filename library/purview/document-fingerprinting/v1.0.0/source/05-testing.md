# 5. Testing & Validation — Document Fingerprinting (Microsoft Purview)

Validate the fingerprinting implementation against explicit **pass/fail gates**. The three headline gates
are: **(A) the forms are detected**, **(B) the false-positive rate is low / detection is specific**, and
**(C) incidents are handled**. Run every test with **clearly-fake sample data** — fill the forms with
obviously non-real values (e.g. `John Doe`, `000-00-0000`), never real personal data — and record the
evidence.

> All tests assume the fingerprint SIT and DLP policy from the Implementation Guide, first proven in
> **simulation** and then enforced to the **pilot ring**. Endpoint tests (if the Devices location is
> used) require an **onboarded** device.

---

## Test A — Detection (the forms are detected)

| # | Test | Steps | Pass condition |
|---|---|---|---|
| A1 | Filled form detected in email | Fill a fingerprinted form with fake data, save it, and email it to another user covered by the policy. | The document matches the fingerprint SIT; a DLP match/alert (simulation or enforced) is raised for the correct policy. |
| A2 | Form on SharePoint/OneDrive | Upload a filled fingerprinted form to a covered site/account (and, in enforce, attempt an external share). | Match recorded in Activity Explorer; in enforce, external share is restricted per the action. |
| A3 | Form in Teams | Share a filled fingerprinted form in a covered Teams chat/channel. | Match recorded; in enforce, tipped/blocked per the action. |
| A4 | Re-saved / forwarded variant | Take the filled form, re-save it (same boilerplate) and move it again. | Still detected — confirms the fingerprint keys off the form's word pattern, not the exact file. |
| A5 | Endpoint (if Devices used) | On an onboarded ring device, copy the filled form to removable media / print it. | Activity audited/restricted per policy; endpoint DLP event appears in Activity Explorer. |
| A6 | Multi-form SIT | If the SIT carries several form fingerprints, test one filled copy of **each** form. | Each distinct form is detected by the same SIT. |

**Gate A (pass):** the filled forms (A1–A4, and A5 if endpoint used) are detected across the covered
channels and, in enforce, produce the configured action and a logged event.

---

## Test B — Specificity / false-positive rate (adoption gate)

| # | Test | Steps | Pass condition |
|---|---|---|---|
| B1 | Unrelated content negative | Move representative **unrelated** documents (memos, ordinary attachments — no form boilerplate) through the covered channels. | Unrelated content is **not** matched — no spurious tips/blocks. |
| B2 | Simulation FP baseline | Over the agreed dwell time, export matches (`CLSFINGER-Report.ps1 -Days <n>`) and classify each as TP/FP. | **False-positive rate ≤ the agreed threshold** (define with compliance). |
| B3 | Shared-boilerplate check | If forms share a common letterhead/header, move a **different** document that also carries that letterhead. | It is **not** matched by the form's fingerprint — confirms the fingerprint keys off form-specific text, not just the common header. If it matches, re-source a more form-specific template (Impl. Phase 4). |
| B4 | Fragment / partial negative | Move a document containing only a **small fragment** of the form's text. | Correctly **not** matched (or matched only per the intended sensitivity) — confirms the fingerprint requires substantial form structure. |
| B5 | Non-fingerprintable input | Attempt with an **image-only** scan of the form and a **password-protected** copy. | Correctly **not** detected — documents the known limitation so operators aren't surprised. |

**Gate B (pass):** unrelated/partial/non-text content is not matched; measured FP rate on the simulation
sample is at/under threshold with true positives intact.

---

## Test C — Incident / alert handling (the control is operable)

| # | Test | Steps | Pass condition |
|---|---|---|---|
| C1 | Alert raised | Trigger a match (Test A1). | A DLP **alert** appears in **Purview → Data loss prevention → Alerts** with the correct policy, severity, and evidence. |
| C2 | Triage workflow | The `Fingerprint Alerts – Triage – Operations` owner/queue picks up the alert, sets status, and dispositions it. | Alert moves through the defined states to a resolved disposition by the named owner. |
| C3 | Activity Explorer trail | Locate the same event in **Data classification → Activity explorer**. | Full evidence trail present (user, location, SIT, action) for investigation. |
| C4 | SIEM forwarding (if configured) | Confirm the event reaches the SIEM/Sentinel destination (Req 2.7). | Event present downstream with usable fields. |

**Gate C (pass):** matches raise alerts, alerts are triaged to disposition by the owner, and the evidence
trail (and SIEM forward, if used) is present.

---

## Simulation-first & rollback validation

| # | Test | Pass condition |
|---|---|---|
| S1 | Nothing enforced outside the ring | Users outside `Fingerprint Pilot Ring – Stage1` experience no blocking during pilot. |
| S2 | Instant rollback | Setting the enforced policy back to **simulation mode** immediately removes enforcement with no data change (verify a previously-blocked action now only simulates). |
| S3 | Scripts are safe-by-default | `CLSFINGER-CreateFingerprint.ps1` and `CLSFINGER-Set-Scope.ps1` run **without** `-Commit` make no change (`-WhatIf` output only); Discovery/Validation/Report scripts are read-only. |
| S4 | Refresh path | After adding a revised form's fingerprint to the SIT (Req 2.5), re-run Test A on the new template and confirm it is detected. |

---

## Evidence to capture (for the deliverable record)
- Baseline posture CSV (Phase 0) and the form inventory.
- Confirmation the fingerprint SIT exists and is referenced by the simulation policy (Validation script).
- Simulation match export + TP/FP classification and the computed **false-positive rate** (Gate B).
- Screenshots/log of Test A detection and the raised alerts (Gate A/C).
- The dispositioned incident from Test C2 and, if used, the SIEM forward (C4).
- Confirmation outside-ring users were unaffected (S1) and that simulation rollback works (S2).

> **Determination boundary.** These tests prove the **control works** — that the forms are detected and
> handled. Whether a given form's enforced action and FP threshold are *acceptable* is a
> compliance/privacy/legal sign-off, captured alongside the evidence above.
