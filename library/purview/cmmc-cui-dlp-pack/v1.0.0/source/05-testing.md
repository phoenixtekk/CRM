# 5. Testing & Validation — CMMC / CUI DLP Pack (Microsoft Purview)

Validate the CUI DLP implementation against explicit **pass/fail gates**. The three headline gates are:
**(A) CUI leaks are blocked**, **(B) the false-positive rate is low**, and **(C) incidents are handled and
evidenced**. Run every test with **non-real, clearly-fake sample content** — a test document **marked
`CUI`** and/or carrying the `CUI` sensitivity label, containing **no real CUI/CDI** — never real controlled
data. Record the evidence; it supports the control narrative (the CMMC/NIST SP 800-171 **satisfaction
determination stays with compliance/C3PAO**).

> All tests assume the policies from the Implementation Guide, first proven in **simulation** and then
> enforced to the **`CUI DLP Pilot Ring – Stage1`**. Endpoint tests require an **onboarded** device
> (Req 2.5). On **GCC High**, confirm each step against your tenant's portal.

---

## Test A — Detection & enforcement (CUI leaks are blocked)

| # | Test | Steps | Pass condition |
|---|---|---|---|
| A1 | Labeled-CUI email blocked | From a ring user, apply the **`CUI`** label to a fake test file and email it to an **external** recipient. | Message is blocked/encrypted per the enforced action; sender sees the CUI policy tip; a DLP alert is raised. |
| A2 | Marked-but-unlabeled CUI email | Send an email whose body/attachment contains the **CUI banner marking** text (matched by the marking SIT) to an external recipient. | Matched by the marking SIT condition; enforced action applied; alert raised — confirms the marking backstop works. |
| A3 | SharePoint/OneDrive external share blocked | As a ring user, upload a **`CUI`**-labeled fake file and attempt to share it **externally**. | External sharing is blocked/restricted on match; event appears in Activity Explorer. |
| A4 | Teams message match | Paste fake **CUI-marked** content into a Teams chat/channel covered by the policy. | Message is blocked or tipped per the enforced action; event logged. |
| A5 | Endpoint — USB / print / cloud upload | On an onboarded ring device, copy a **`CUI`**-labeled fake file to **removable media**, **print** it, and **upload** it to an unallowed cloud app/browser. | Each activity is audited/blocked per policy; endpoint DLP events appear in Activity Explorer. |
| A6 | Internal-movement / below-threshold negative | Move the same CUI file **internally within the enclave**, and send unmarked/unlabeled content. | Internal enclave movement and non-CUI content are correctly **not** blocked — confirms scoping/conditions hold. |

**Gate A (pass):** A1–A5 each produce the enforced action and a logged event; A6 correctly does not fire.

---

## Test B — False-positive rate (adoption & assessment gate)

| # | Test | Steps | Pass condition |
|---|---|---|---|
| B1 | Simulation FP baseline | Over the agreed dwell time, export simulation matches (`DLPCMMC-Report.ps1 -Days <n>`) and classify each as TP/FP. | **False-positive rate ≤ the agreed threshold** (define with compliance; label-keyed matching should be very precise, so target a low absolute FP count the triage team can absorb). |
| B2 | "CUI mention" negative | Run legitimate content that merely **mentions** the word "CUI" (e.g. a compliance-training doc) but is not itself CUI. | Not matched — confirms the marking SIT uses proximity/context and the label condition carries the weight. |
| B3 | Post-tuning re-measure | After each tuning change (label-first, proximity, exceptions, recipient scope), re-simulate and re-measure. | FP rate trends **down** while true positives (Test A) still fire. |
| B4 | Override sanity | In the pilot ring, review captured **allow-with-justification** overrides. | Overrides are legitimate business justifications, not routine bypass — if routine, re-tune or re-scope. |

**Gate B (pass):** measured FP rate at/under threshold on the simulation sample with true positives intact.

---

## Test C — Incident / alert handling & evidence (the control is operable and auditable)

| # | Test | Steps | Pass condition |
|---|---|---|---|
| C1 | Alert raised | Trigger a policy match (Test A1/A5). | A DLP **alert** appears in **Purview → Data loss prevention → Alerts** with the correct policy, severity, and evidence. |
| C2 | Triage workflow | The `CUI DLP Alerts – Triage – Operations` owner/queue picks up the alert, sets status, and dispositions it. | Alert moves through the defined states to a resolved disposition by the named owner. |
| C3 | Activity Explorer evidence trail | Locate the same event in **Data classification → Activity explorer** and **export** it. | Full evidence trail present (user, location, label/SIT, action) and retained per Req 2.8 for assessment/audit. |
| C4 | SIEM forwarding (if configured) | Confirm the DLP event reaches the SIEM/Sentinel destination (Req 2.8). | Event present in the downstream system with usable fields. |

**Gate C (pass):** matches raise alerts, alerts are triaged to disposition by the owner, and the **retained
evidence trail** (and SIEM forward, if used) is present.

---

## Simulation-first & rollback validation

| # | Test | Pass condition |
|---|---|---|
| S1 | Nothing enforced outside the ring | Users/devices **outside** `CUI DLP Pilot Ring – Stage1` experience no blocking during pilot. |
| S2 | Instant rollback | Setting any enforced policy back to **simulation mode** immediately removes enforcement with no data change (verify a previously-blocked CUI action now only simulates). |
| S3 | Scripts are safe-by-default | `DLPCMMC-Config.ps1` / `DLPCMMC-Set-Scope.ps1` run **without** `-Commit` make no change (`-WhatIf` output only); discovery/validate/report scripts are read-only. |

---

## Evidence to capture (for the deliverable record & control narrative)
- Baseline posture CSV (Phase 0), the `CUI` label confirmation, and the marking-SIT test result.
- Simulation match export + TP/FP classification and the computed **false-positive rate** before/after
  tuning (Gate B).
- Screenshots/log of Test A enforcement actions (labeled CUI **and** marked-but-unlabeled) and the raised
  alerts (Gate A/C).
- The dispositioned, **retained** incident from Test C2/C3 and, if used, the SIEM forward (C4).
- Confirmation that outside-ring users were unaffected (S1) and that simulation rollback works (S2).

> **Determination boundary.** These tests prove the **control works** and produce the **evidence**. Whether
> that evidence **satisfies** a given NIST SP 800-171 / CMMC practice, the SPRS score, the acceptable FP
> threshold, and the enforced action per CUI category are **compliance / contracts / legal / C3PAO**
> sign-offs, captured alongside the evidence above.
