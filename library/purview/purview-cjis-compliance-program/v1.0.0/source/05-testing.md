# 5. Testing & Validation — Microsoft Purview CJIS Compliance Program

Work through every gate. Each has a **method**, an **expected result (pass)**, and a **fail action**.
Tests are read-only except where they exercise the safe-first configuration you already committed; no
control is enforced by a test. Do not expand to enforcement or present the evidence package until every
gate passes for the pilot, then re-confirm each audit cycle.

> **Remember:** these gates prove the **technical controls are configured, in the expected state, and
> evidenced** — they do **not** prove the controls **satisfy** CJIS. Control satisfaction, the retention
> schedule, and environment authorization are **CSA / CJIS auditor / records** determinations.

## Gate 0 — The environment is CJIS-authorized (determination — not a script)
- **Method:** confirm with your **CSA/CSO** and Microsoft that the tenant is in an authorized cloud (GCC
  High / Azure Government) under the CJIS Security Addendum (Requirement 2.1).
- **Pass:** the CSA/CSO confirms the authorized environment and agreements.
- **Fail:** stop — do not configure CJI controls in a non-authorized tenant; engage CSA/CSO/Microsoft.

## Gate 1 — Licensing and current state are known
- **Method:** `CMPCJIS-Discovery.ps1` (and `CMPCJIS-ScopeCheck.ps1` for permission/health).
- **Pass:** the CJI-control capabilities are classified licensed/reachable or *"not licensed / verify,"*
  the audit-logging state is reported, and the existing CJI-relevant objects are listed.
- **Fail:** assign the missing license (Requirement 2.2) or role (2.3); a not-licensed control is recorded
  as **deferred**, not fabricated.

## Gate 2 — The control map is complete and reviewed
- **Method:** open `CJIS Control Map – Purview – Baseline`.
- **Pass:** every in-scope CJIS policy area maps to a named Purview object, a status, and an owner; the
  CSA/auditor has reviewed the mapping approach.
- **Fail:** complete the map (Implementation Step 2) and re-review with the CSA/auditor.

## Gate 3 — Unified audit logging is on and retention is targeted
- **Method:** `CMPCJIS-Validate.ps1` audit checks (and the portal audit-search settings).
- **Pass:** `UnifiedAuditLogIngestionEnabled = True`; the audit-retention target is met, or **Audit
  Premium** is flagged where longer retention is required. **The required duration is a CJIS/records
  determination.**
- **Fail:** enable unified audit logging (Implementation Step 4.1); license Audit Premium if needed;
  confirm the target with your CSA/records owner.

## Gate 4 — The CJI label exists with encryption in the expected state
- **Method:** `CMPCJIS-Discovery.ps1` / `CMPCJIS-Validate.ps1` against `CJI – Protected – Label`.
- **Pass:** the label exists, **encryption is configured**, access scope matches the design, and it is
  **unpublished/pilot-scoped** (not tenant-wide) until enforcement.
- **Fail:** correct the label configuration (Implementation Step 4); confirm encryption/access with the
  records/security owner.

## Gate 5 — The CJI DLP policy is present in test/simulation mode
- **Method:** `CMPCJIS-Validate.ps1` against `CJI Protection – Exfiltration – Policy`.
- **Pass:** the DLP policy exists in **test/simulation mode**, scoped to the pilot, targeting CJI as
  designed — **not enforcing**.
- **Fail:** return the policy to test mode / correct the scope; never leave it enforcing before the pilot
  review passes.

## Gate 6 — DLP simulation matches CJI as intended (security-officer review)
- **Method:** generate benign in-scope CJI-like activity; review the DLP test/simulation results in the
  portal with the agency's **security officer** (Implementation Step 5).
- **Pass:** the simulation matches CJI as intended with no material false-positives/negatives the officer
  rejects; the review is recorded.
- **Fail:** tune the label/SIT/DLP conditions and re-simulate before enforcing.

## Gate 7 — CJI retention is staged correctly
- **Method:** `CMPCJIS-Validate.ps1` against `CJI Records – Retention – Policy`.
- **Pass:** the retention policy exists **staged/disabled or pilot-scoped**, per the agency's schedule
  intent. **The retention schedule itself is a records/legal determination.**
- **Fail:** correct the staging; confirm the schedule with the records owner before broad application.

## Gate 8 — Separation of duties holds
- **Method:** `CMPCJIS-Validate.ps1` / `CMPCJIS-ScopeCheck.ps1` role checks.
- **Pass:** the CJI-control configurer, the audit-evidence reader, and any insider-risk reviewer are
  **separate** roles; insider-risk (where used) is aggregate/de-identified under a separate role.
- **Fail:** correct the role assignments (Requirement 2.3) before proceeding.

## Gate 9 — CJI-touching activity is captured in the audit trail
- **Method:** perform a benign in-scope action; confirm it appears in the unified audit log for the pilot
  scope.
- **Pass:** the activity is captured and retrievable within the audit search window.
- **Fail:** confirm audit logging is on and the activity type is audited; verify Audit Premium coverage
  for longer-retention activities.

## Gate 10 — The evidence package is accurate and reconciles
- **Method:** `CMPCJIS-Report.ps1` → open `CJIS Evidence – Formal Audit – Package`; spot-check each
  control's state against its Purview blade.
- **Pass:** each mapped control shows its implementing object, current state, and audit reference, and the
  states reconcile to the portal.
- **Fail:** correct the underlying control/evidence and regenerate the package.

## Evidence to retain
- `CMPCJIS-Discovery.ps1` / `CMPCJIS-ScopeCheck.ps1` outputs (licensing, current state, audit state).
- The reviewed `CJIS Control Map – Purview – Baseline`.
- The recorded DLP simulation review (Gate 6) signed off by the security officer.
- `CMPCJIS-Validate.ps1` output per cycle and the `CJIS Evidence – Formal Audit – Package`.

> Whether the configured controls **satisfy** the CJIS Security Policy — and whether the environment is
> **authorized** — are **CSA / CJIS auditor / records** determinations. These gates prove the controls
> are **configured, in the expected state, and evidenced**, not that they are **compliant**. Capability
> availability is **licensing-/cloud-dependent and evolving — verify against your entitlements, your
> cloud (GCC High / Azure Government), and your CJIS Security Policy version.**
