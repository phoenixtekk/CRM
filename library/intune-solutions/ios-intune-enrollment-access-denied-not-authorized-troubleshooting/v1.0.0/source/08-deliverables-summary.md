# Deliverables Summary

Everything included in this solution.

## Documentation (compiled to PDF)
1. **Solution Overview** — what the "Access Denied / not authorized" screen means, the five gates that
   produce it in likelihood order, and the deterministic diagnosis path from the on-screen IDs.
2. **Requirements** — roles, the diagnostic IDs, Microsoft Graph PowerShell, enrollment-type
   confirmation, a reproduce/retry path, and change approval — each with why / verify / implement.
3. **Root-Cause & Remediation Guide** — the Phase 1–4 runbook: capture and read the failed sign-in →
   check and fix the gate (license, MDM scope, restriction, Conditional Access, account) → re-enroll and
   validate → prevent recurrence.
4. **Testing & Validation** — six objective tests, ending in a clean re-enrollment with a successful
   enrollment sign-in.
5. **Troubleshooting Guide / FAQ** — symptom→cause→verify→fix for the core failure, the "require
   compliant device" chicken-and-egg, per-user differences, ADE/Setup Assistant cases, residual failures,
   and sovereign clouds.
6. **Best Practices** — evidence-first diagnosis, change discipline, and designing out the common causes.
7. **Executive Summary** — the one-page brief for stakeholders.

## PowerShell tools (packaged as a ZIP)
1. **`ENRLDX-Get-EnrollmentSignin.ps1`** — finds the failed **Microsoft Intune Enrollment / Microsoft
   Intune** sign-in for the user (by correlation ID or time window) with the failure reason and applied
   Conditional Access — the deterministic root cause.
2. **`ENRLDX-Get-UserIntuneLicense.ps1`** — confirms an enabled Intune service plan (Phase 2A).
3. **`ENRLDX-Get-MdmUserScope.ps1`** — reports the Intune MDM user scope and whether the user is inside
   it (Phase 2B).
4. **`ENRLDX-Get-EnrollmentRestrictions.ps1`** — reports platform/ownership blocks and the device limit
   (Phase 2C).
5. **`ENRLDX-Get-EnrollmentCA.ps1`** — lists Conditional Access policies targeting the enrollment apps,
   flagging blocks and incompatible grants (Phase 2D).

All scripts are read-only diagnostics, connect via `Connect-MgGraph`, support `-Environment USGov` for
sovereign clouds, and are parse-verified.

## Scope
- **In scope:** the iOS/iPadOS enrollment **"Access Denied / not authorized"** authorization failure and
  its remediation across all common gates.
- **Referenced, not rebuilt:** general Intune iOS enrollment setup (ADE/ABM, Company Portal, enrollment
  profiles) and enrollment-time device grouping — covered by the companion Intune enrollment solutions.
