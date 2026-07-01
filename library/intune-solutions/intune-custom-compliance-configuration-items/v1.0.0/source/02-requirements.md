# 2. Requirements Guide — Intune Custom Compliance & Configuration Items (Scripted)

Verify **every** requirement before authoring. Each entry: Description · Why · Verify ·
Implement-if-missing. Category-wide prerequisites are in `global-requirements-intune-solutions.md`.

## 2.1 Licensing
Description: Intune (Plan 1). Custom compliance and configuration items are included features.
Why: Intune hosts the detection script, custom compliance policy, and configuration items.
Verify: M365 admin center → `Billing → Licenses`.
Implement: Assign M365 E3/E5 or Business Premium (Intune included).

## 2.2 Device enrollment
Description: Targeted devices enrolled in Intune.
Why: Detection scripts and config items apply only to enrolled devices.
Verify: Intune → `Devices → All devices`.
Implement: Enable automatic enrollment; enroll devices.

## 2.3 Supported Windows OS
Description: Windows 10/11 (Pro/Enterprise/Education), current build.
Why: Custom compliance detection scripts run in 64-bit PowerShell on a supported Windows build.
Verify: `winver`; run `CUSTCOMP-Discovery.ps1`.
Implement: Patch/upgrade to a supported build.

## 2.4 A compliance baseline (built-in policy)
Description: A standard device compliance policy already assigned (encryption, OS version, etc.).
Why: Custom compliance extends the baseline; it is not a replacement for the built-in rules.
Verify: Intune → `Devices → Compliance`; a Windows policy exists and is assigned.
Implement: Create a built-in compliance policy first (see the Device Compliance Policies solution).

## 2.5 PowerShell script signing / execution
Description: Detection scripts are trusted code — signed, or execution allowed per your standard.
Why: The device must run the detection script; unsigned/blocked scripts fail to evaluate.
Verify: `Get-ExecutionPolicy -List`; confirm scripts you author can run.
Implement: Sign scripts with your code-signing certificate, or set an appropriate execution policy via Intune.

## 2.6 Target device groups
Description: A pilot group and a broad group for staged assignment.
Why: Every custom check is piloted before the fleet gets it.
Verify: Entra → `Groups`; the pilot/broad groups exist.
Implement: Run `CUSTCOMP-Set-ScopeTargeting.ps1`, or Entra → `Groups → New group`.

## 2.7 Conditional Access (to enforce, not just report)
Description: A Conditional Access policy that requires a compliant device.
Why: Custom compliance only gates access when Conditional Access requires compliance.
Verify: Entra → `Security → Conditional Access`; a "require compliant device" policy exists.
Implement: Create a Conditional Access policy requiring a compliant device (start in report-only).

---
## Checklist
- [ ] Intune licensing assigned
- [ ] Devices enrolled
- [ ] Windows 10/11 supported build — `CUSTCOMP-Discovery.ps1`
- [ ] A built-in compliance baseline is assigned
- [ ] PowerShell script signing / execution allowed
- [ ] Pilot + broad Entra groups created — `CUSTCOMP-Set-ScopeTargeting.ps1`
- [ ] Conditional Access "require compliant device" policy (report-only to start)
