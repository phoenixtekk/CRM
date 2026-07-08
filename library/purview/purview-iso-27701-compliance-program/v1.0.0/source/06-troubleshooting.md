# 6. Troubleshooting Guide — Microsoft Purview ISO 27701 Compliance Program

Common field issues for the ISO 27701 PIMS program and how to resolve them. Objects are named verbatim
from the Implementation Guide. Most problems are **licensing/cloud gaps**, **replication delay**, or
**audit not-yet-tuned** — not step mistakes. When a feature is simply absent, treat it as a plan/cloud gap
(Requirement 2.1) and **verify your licensing/tenant** first. Remember the boundary: **ISO 27701
applicability, PIMS scope, the controller/processor determination, retention schedules, evidence adequacy,
and the certification decision are compliance/privacy/legal/auditor determinations** — the tooling
configures and evidences, it does not decide and is not a certification.

## The ISO 27701 assessment template isn't available in Compliance Manager
- **Symptom:** `ISO 27701 Assessment – PIMS – Pilot` can't be created; the **ISO 27701** template is
  missing.
- **Likely cause:** Premium Compliance Manager assessments need **Microsoft 365 E5 / E5 Compliance**;
  availability varies by cloud.
- **Resolve:** Run `ISO27701-Discovery.ps1`; confirm the plan; **verify your tenant.** Where the template
  is absent, evidence the mapped controls against the available baseline (e.g. an ISO 27001 assessment)
  and record the gap.

## The PIMS extension doesn't layer on ISO 27001 as expected
- **Symptom:** Controls appear duplicated or conflicting with an existing ISO 27001 program.
- **Likely cause:** The PIMS was built as a parallel program rather than **extending** the existing ISMS
  (Requirement 2.5).
- **Resolve:** Identify the existing ISO 27001 assessment and reusable controls; **reuse and evidence**
  them; only add the privacy-specific overlay. Record the reuse in `ISO 27701 Control Map – Clauses`.

## Compliance Score doesn't move / actions don't auto-test
- **Symptom:** After configuring controls, the score or action status doesn't update.
- **Likely cause:** **Automatic testing** isn't enabled, the action isn't eligible, or testing latency.
- **Resolve:** Purview → **Compliance Manager → Settings** → enable automatic testing; note only eligible
  Microsoft-managed actions auto-test — the rest are **manual** and evidenced by hand in `ISO 27701
  Evidence – Register`. Allow time to reflect.

## The PII label doesn't appear for pilot users
- **Symptom:** `Sensitivity Label - PII (PIMS) - All Users` isn't visible in Word/Outlook.
- **Likely cause:** **Replication delay**, the user isn't in `ISO 27701 - Pilot Scope`, or the client
  hasn't refreshed.
- **Resolve:** Confirm publication with `ISO27701-Validation.ps1`; verify pilot-group membership
  (`ISO27701-Set-Scope.ps1`); restart the Office client; allow propagation before re-publishing.

## Auto-labeling simulation shows nothing (or the wrong items)
- **Symptom:** `Auto-Label - PII - Pilot` simulation is empty or flags routine content.
- **Likely cause:** Simulation still crawling; the condition doesn't use the **PII sensitive-information
  types**; no matching content in the in-scope locations.
- **Resolve:** Let the simulation complete; confirm the rule uses the PII SITs (Requirement 2.4) and
  applies the correct label; seed a pilot site with test PII content; re-run. Never turn the policy on
  until the simulation is clean.

## DLP records nothing in audit / blocks legitimate work after enforce
- **Symptom:** No events from `DLP Policy - PII (PIMS) - Audit`, or `... - Enforce` blocks routine work.
- **Likely cause:** Policy still deploying, **audit off** (Requirement 2.8), location out of scope; or the
  policy was promoted before the **audit gate** was clean.
- **Resolve:** Confirm auditing is on and returning results (`ISO27701-EvidenceReport.ps1`); verify
  locations/scope. If enforce over-blocks, **roll back** to **Test mode**, tune out false positives, and
  re-enforce only after the gate passes.

## A DSR (PII-principal request) returns nothing / too much
- **Symptom:** The Priva Subject Rights Request or the content search `DSR - PII Principal Access - Search`
  misses or over-returns.
- **Likely cause:** Wrong/insufficient identifiers, workloads out of scope, or indexing delay.
- **Resolve:** Broaden the identifiers; confirm all in-scope workloads are searched; allow indexing time.
  Record the run in `ISO 27701 Evidence – Register`. **The correct/erase/produce decision is
  privacy/legal** — the tooling locates and produces.

## Retention (retention limitation) behaves unexpectedly
- **Symptom:** `Retention Label - PII - Retention Limitation` retains or deletes wrongly.
- **Likely cause:** Policy still propagating; wrong locations; duration/end-action from a **guess**.
- **Resolve:** Confirm the policy is **On** and scoped (`ISO27701-Validation.ps1`); use **disposition
  review**. **Retention durations are a records/legal determination** — confirm the schedule before
  activating deletion. Deletion is irreversible.

## Role separation looks wrong
- **Symptom:** Insider Risk / Communication Compliance / Priva roles held by the same owner as
  configuration roles.
- **Likely cause:** Over-broad role assignment.
- **Resolve:** Separate the privacy-sensitive roles from configuration roles; re-capture `ISO 27701 Roles
  – Separation Evidence` via `ISO27701-Discovery.ps1`. Separation of duties is a PIMS control.

## Evidence report is empty or partial
- **Symptom:** `ISO27701-EvidenceReport.ps1` produces little evidence.
- **Likely cause:** Audit off; DLP not yet auditing; labels/retention not yet published; read-access gaps.
- **Resolve:** Enable audit (Requirement 2.8); confirm the controls are configured and auditing; re-run
  after events accumulate; confirm the operator holds the read roles.

## PowerShell can't connect or a cmdlet is missing
- **Symptom:** `Connect-IPPSSession` / `Connect-MgGraph` fails or a cmdlet is unavailable.
- **Likely cause:** Modules missing/old, or MFA/modern-auth blocked.
- **Resolve:** `Install-Module ExchangeOnlineManagement -Scope CurrentUser` (and Microsoft.Graph for the
  scope script); sign in with an MFA-capable Compliance Administrator; retry. A cmdlet still missing after
  a good connection is a plan/cloud gap — **verify your tenant.**

---
### Escalation & rollback
| Situation | Action |
|---|---|
| DLP enforce disrupts work | Revert to **Test mode** (audit); fix exceptions; re-run the audit gate |
| Auto-labeling mislabels | Return the policy to **simulation**; fix the rule; re-simulate |
| Retention deleting wrongly | Disable the retention policy; enable **disposition review**; confirm the schedule with records/legal |
| Feature genuinely absent | Treat as licensing/cloud gap (Req 2.1) — **verify your licensing/tenant** |
| Applicability / scope / controller-processor / certification question | **Determination deferred** to compliance/privacy/legal/auditor — capture, don't decide |
