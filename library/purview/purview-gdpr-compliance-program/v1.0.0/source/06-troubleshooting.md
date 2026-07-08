# 6. Troubleshooting Guide — Microsoft Purview GDPR Compliance Program

Common field issues for the GDPR program and how to resolve them. Objects are named verbatim from the
Implementation Guide. Most problems are **licensing/cloud gaps**, **replication delay**, or **audit
not-yet-tuned** — not step mistakes. When a feature is simply absent, treat it as a plan/cloud gap
(Requirement 2.1) and **verify your licensing/tenant** first. Remember the boundary: **GDPR
applicability, lawful basis, ROPA (Art. 30), DPIA (Art. 35) outcomes, retention schedules, and evidence
adequacy are compliance/privacy/legal determinations** — the tooling configures and evidences, it does
not decide.

## The GDPR assessment template isn't available in Compliance Manager
- **Symptom:** `GDPR Assessment – Regulation – Pilot` can't be created; the **GDPR** template is
  missing.
- **Likely cause:** Premium Compliance Manager assessments need **Microsoft 365 E5 / E5 Compliance**;
  availability varies by cloud.
- **Resolve:** Run `GDPR-Discovery.ps1`; confirm the plan in the M365 admin center; **verify your
  tenant.** Where the template is absent, evidence the mapped controls against the available baseline
  and record the gap.

## Compliance Score doesn't move / improvement actions don't auto-test
- **Symptom:** After configuring controls, `GDPR Assessment` score or action status doesn't update.
- **Likely cause:** **Automatic testing** isn't enabled, the action isn't eligible for auto-test, or
  testing/scan latency.
- **Resolve:** Purview → **Compliance Manager → Settings** → enable automatic testing
  (`GDPR Automatic Testing – Setting`); note only eligible Microsoft-managed actions auto-test — the
  rest are **manual** and evidenced by hand in `GDPR Evidence – Register`. Allow time to reflect.

## The personal-data label doesn't appear for pilot users
- **Symptom:** `Sensitivity Label - Personal Data (GDPR) - All Users` isn't visible in Word/Outlook.
- **Likely cause:** **Replication delay**, the user isn't in `GDPR - Pilot Scope`, or the client hasn't
  refreshed.
- **Resolve:** Confirm publication with `GDPR-Validation.ps1`; verify pilot-group membership
  (`GDPR-Set-Scope.ps1`); restart the Office client; allow propagation before re-publishing.

## Auto-labeling simulation shows nothing (or the wrong items)
- **Symptom:** `Auto-Label - EU Personal Data - Pilot` simulation is empty or flags routine content.
- **Likely cause:** Simulation still crawling; the condition doesn't use the **EU personal-data
  sensitive-information types**; no matching content in the in-scope locations.
- **Resolve:** Let the simulation complete; confirm the rule uses EU SITs (National ID / Passport / Tax
  ID etc., Requirement 2.4) and applies the correct label; seed a pilot site with test EU-personal-data
  content; re-run. Never turn the policy on until the simulation is clean.

## DLP records nothing in audit
- **Symptom:** No policy tips or Activity-explorer events from `DLP Policy - EU Personal Data - Audit`.
- **Likely cause:** Policy still deploying; **audit logging off** (Requirement 2.7); the location isn't
  in scope.
- **Resolve:** Confirm auditing is on and returning results; run `GDPR-EvidenceReport.ps1` for the
  event summary; verify the policy's locations and `GDPR - Pilot Scope` scoping. Allow deployment time.

## DLP blocks legitimate work after enforce
- **Symptom:** After Step 8, routine business email/files are blocked.
- **Likely cause:** The policy was promoted before the **audit gate** was clean, or exceptions are
  missing.
- **Resolve:** **Rollback** — set `DLP Policy - EU Personal Data - Enforce` back to **Test mode**
  (audit); tune out false positives (confidence, instance counts, exceptions); re-enforce only after
  the gate passes.

## A DSR (subject rights request) returns nothing / too much
- **Symptom:** The Priva Subject Rights Request or the content search `DSR - Data Subject Access -
  Search` misses or over-returns the subject's data.
- **Likely cause:** Wrong/insufficient subject identifiers, workloads out of scope, or indexing delay.
- **Resolve:** Broaden the identifiers (email aliases, employee ID, phone); confirm all in-scope
  workloads are searched; allow indexing time. Record the run in `GDPR Evidence – Register`. **The
  erase/produce decision is privacy/legal** — the tooling locates and produces, it does not decide.

## Retention deletes too much or nothing (storage limitation)
- **Symptom:** `Retention Label - Personal Data - Storage Limitation` behaves unexpectedly.
- **Likely cause:** Policy still propagating; wrong locations; duration/end-action set from a **guess**
  rather than the retention schedule.
- **Resolve:** Confirm the policy is **On** and scoped (`GDPR-Validation.ps1`); use **disposition
  review** so nothing auto-deletes unreviewed. **Retention durations are a records/legal
  determination** — confirm the schedule before activating deletion. Deletion is irreversible.

## Role separation looks wrong (HR/privacy-sensitive roles)
- **Symptom:** Insider Risk / Communication Compliance roles held by the same owner as configuration
  roles.
- **Likely cause:** Over-broad role assignment; least-privilege separation not applied.
- **Resolve:** Purview → **Settings → Roles and scopes → Role groups**; separate the HR/privacy-
  sensitive roles from configuration roles; re-capture `GDPR Roles – Separation Evidence` via
  `GDPR-Discovery.ps1`. Role separation is a control, not a convenience.

## Evidence report is empty or partial
- **Symptom:** `GDPR-EvidenceReport.ps1` produces little cross-control evidence.
- **Likely cause:** Audit off; DLP not yet auditing; labels/retention not yet published; read-access
  gaps.
- **Resolve:** Enable audit (Requirement 2.7); confirm the controls are configured and auditing;
  re-run after events accumulate; confirm the operator holds the read roles.

## PowerShell can't connect or a cmdlet is missing
- **Symptom:** `Connect-IPPSSession` / `Connect-MgGraph` fails or a cmdlet is unavailable.
- **Likely cause:** Modules missing/old, or MFA/modern-auth blocked.
- **Resolve:** `Install-Module ExchangeOnlineManagement -Scope CurrentUser` (and Microsoft.Graph for
  the scope script); sign in with an MFA-capable Compliance Administrator; retry. A cmdlet still
  missing after a good connection is a plan/cloud gap — **verify your tenant.**

---
### Escalation & rollback
| Situation | Action |
|---|---|
| DLP enforce disrupts work | Revert to **Test mode** (audit); fix exceptions; re-run the audit gate |
| Auto-labeling mislabels | Return the policy to **simulation**; fix the rule; re-simulate |
| Retention deleting wrongly | Disable the retention policy; enable **disposition review**; confirm the schedule with records/legal |
| Feature genuinely absent | Treat as licensing/cloud gap (Req 2.1) — **verify your licensing/tenant** |
| Applicability / lawful basis / ROPA / DPIA / erasure question | **Determination deferred** to compliance/privacy/legal — capture, don't decide |
