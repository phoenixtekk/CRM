# 6. Troubleshooting — Microsoft Purview CJIS Compliance Program

The failure modes that make a CJIS-aligned Purview program **non-authorized, over-blocking, or
unevidenced** — plus the environment, licensing, DLP-simulation, audit, and evidence issues you'll hit.
Each: **symptom → likely cause → fix.** The recurring lesson: this program configures **technical
controls and evidence** — it does **not** attest CJIS compliance or authorize the environment. Control
satisfaction, the retention schedule, and environment authorization are **CSA / auditor / records**
determinations; escalate those rather than treating them as tool faults.

## `CMPCJIS-Discovery.ps1` can't confirm the environment is CJIS-authorized
- **Cause:** the script reports **indicative** licensing/environment hints but **cannot** attest GCC High
  / Azure Government authorization or the CJIS Security Addendum.
- **Fix:** confirm the authorized cloud and agreements with your **CSA/CSO** and Microsoft (Requirement
  2.1) **before** configuring CJI controls. **Commercial M365 is generally not CJIS-authorized** — do not
  proceed there. This is Gate 0 and it is a determination, not a script output.

## A CJI-control capability shows `CHECK` / not licensed
- **Cause:** advanced DLP, auto-labeling, **Audit Premium**, Insider Risk, or the CJIS/US-gov Compliance
  Manager assessment template needs **E5 / E5 Compliance** and specific availability in **your** cloud —
  GCC High / Azure Government lag or differ from commercial.
- **Fix:** confirm the SKU (Requirement 2.2) and **verify availability in your cloud**; assign the plan or
  record the control as **deferred — not licensed** on the control map. Never fabricate a control state.

## The CJI DLP over-blocks legitimate criminal-justice work
- **Cause:** the DLP rule / CJI Sensitive Information Types match too broadly, or it was enforced before
  the simulation review.
- **Fix:** keep the DLP in **test/simulation mode** and review the results with the agency's **security
  officer** (Gate 6) before enforcing. Tune the CJI label/SIT conditions — **the CJI identifiers come from
  the agency**, not the tool. `CMPCJIS-Validate.ps1` FAILs if the pilot policy is not in test mode.

## The CJI DLP misses CJI (false negatives)
- **Cause:** the rule doesn't bind the CJI label or the agency's CJI identifiers, or the SITs are too
  narrow.
- **Fix:** confirm a DLP **rule** exists (`CMPCJIS-Validate.ps1` reports the rule count) and that it
  matches the `CJI – Protected – Label` and/or the agency-defined SITs. Re-simulate and review before
  enforcing. Mis-defined identifiers leak CJI — get them from the agency's records/security owners.

## The CJI label has no encryption / access scope
- **Cause:** `CMPCJIS-Configure.ps1` creates the label but leaves **encryption/access scope** to be
  finalized in the portal per the agency design (the full encryption param set is intricate and
  tenant-specific).
- **Fix:** finalize encryption and the access scope in the portal (or with the documented `Set-Label`
  encryption parameters — **verify supported params in your tenant**). `CMPCJIS-Validate.ps1` reports
  `CHECK` on label encryption until it can confirm it; treat that as an action, not a pass.

## `CMPCJIS-Validate.ps1` FAILs on unified audit logging
- **Cause:** `UnifiedAuditLogIngestionEnabled = False` — the CJIS **auditing & accountability** trail
  isn't on.
- **Fix:** `CMPCJIS-Configure.ps1 -EnableAudit -Commit` (or `Set-AdminAuditLogConfig
  -UnifiedAuditLogIngestionEnabled $true`) under change control. Confirm the required **retention
  duration** (Audit Premium) with your CSA/records owner — the duration is a determination the validator
  flags `CHECK`.

## Audit events aren't retained long enough for CJIS
- **Cause:** the default audit-retention window is shorter than the CJIS-required period, and **Audit
  Premium** / an audit-retention policy isn't in place.
- **Fix:** license **Audit (Premium)** and configure an audit-retention policy for the CJI-touching
  activities. **The required duration is a CJIS/records determination** — confirm it, don't guess.

## Separation-of-duties FAIL / role bleed
- **Cause:** the CJI-control configurer also holds an investigative role (Insider Risk / Communication
  Compliance / eDiscovery), or the audit-evidence reader is the same person.
- **Fix:** separate the roles (Requirement 2.3). Supply the role matrix to `CMPCJIS-Validate.ps1
  -RoleMatrixCsv` to catch conflicts; remove the conflicting membership. Where Insider Risk is used, keep
  it **aggregate/de-identified** under a separate role, outcomes deferred to HR/legal and CJIS governance.

## `CMPCJIS-Configure.ps1 -Enforce -Commit` caused user impact you didn't expect
- **Cause:** enforcement was applied before the pilot simulation was reviewed and signed off.
- **Fix:** enforce is the **one** step that turns on real impact and it is deliberate/gated by design.
  **Rollback:** re-run without `-Enforce` (`-Commit`) to return DLP to test mode / unpublish the label /
  disable retention; or `-Remove -Commit` to delete the program's managed objects (pre-existing policies
  are untouched). Re-review the simulation before re-enforcing.

## The evidence package shows a control as `NOT FOUND` / `OFF`
- **Cause:** the mapped object doesn't exist, isn't in the expected state, or audit is off — a **real gap**
  the package is correctly surfacing.
- **Fix:** `CMPCJIS-Report.ps1` colours these red for a reason — remediate the underlying control
  (create/enable it) and regenerate, or annotate it with the CSA if it's intentionally deferred. Don't
  edit the package to hide a gap; the auditor needs the true state.

## Policy-area numbers in the control map don't match the auditor's
- **Cause:** the CJIS Security Policy is **versioned** — 5.9.x and the 6.0 restructuring (aligned to NIST
  800-53) number and group controls differently.
- **Fix:** the program maps by **policy area / control intent** and flags `verify`. Confirm the exact
  area/control numbers against **your current CJIS Security Policy version** with your CSO/auditor and
  update the control map accordingly.

## `Connect-IPPSSession` / `Connect-ExchangeOnline` / `Connect-MgGraph` fails
- **Cause:** module not installed, MFA/modern-auth not completed, or the wrong cloud endpoint (GCC High /
  Azure Government use different endpoints).
- **Fix:** install the modules; complete the interactive sign-in (Requirement 2.3); for GCC High / Azure
  Government, connect with the correct cloud/environment parameter (verify the endpoint for your cloud).
  Read-only/`-WhatIf` scripts are safe to retry. **No credentials in code.**

## When to escalate beyond this solution
- **Whether the environment is CJIS-authorized, and whether a control *satisfies* CJIS** → **CSA / CSO /
  CJIS auditor**. This program configures technical controls and produces evidence; it does not attest
  compliance.
- **The CJI records-retention schedule and regulatory applicability** → **records and legal**.
- **The CJI identifiers that drive the label/SITs** → the **agency's records/security owners** — they are
  agency data, not invented here.
- **A cmdlet/capability that has genuinely changed or differs in your cloud** → verify against current
  Microsoft documentation for **your** cloud (GCC High / Azure Government); Purview capabilities and the
  portal evolve.
