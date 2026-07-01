# 2. Requirements Guide — Attack Surface Reduction (ASR) Rules

Verify **every** requirement before configuring. Each entry: **Description · Why · Verify ·
Implement-if-missing.** Category-wide prerequisites are in `global-requirements-intune-solutions.md`.

## 2.1 Licensing
**Description:** Intune (Plan 1). Defender for Endpoint enriches reporting (optional).
**Why:** Intune delivers the ASR policy; MDE provides centralized ASR reporting/hunting.
**Verify:** M365 admin center → **Billing → Licenses**.
**Implement:** Assign M365 E3/E5 or Business Premium; add MDE for richer reporting.

## 2.2 Microsoft Defender Antivirus active
**Description:** Defender Antivirus is the active AV with real-time protection on.
**Why:** ASR rules are enforced by Defender AV; they do nothing if Defender is disabled/passive.
**Verify:** `Get-MpComputerStatus` (`AMRunning`, `RealTimeProtectionEnabled`); run **`ASR-Discovery.ps1`**.
**Implement:** Ensure Defender AV is active (not passive/third-party-only); enable real-time protection.

## 2.3 Supported Windows OS
**Description:** Windows 10 1709+/Windows 11.
**Why:** ASR rules require a supported Defender platform.
**Verify:** `winver`.
**Implement:** Patch/upgrade to a supported build; keep the Defender platform current.

## 2.4 Device enrollment
**Description:** Devices enrolled in Intune.
**Why:** The ASR policy applies only to enrolled devices.
**Verify:** Intune → **Devices → All devices**.
**Implement:** Enable automatic enrollment; enroll devices.

## 2.5 (Recommended) Defender for Endpoint onboarding
**Description:** Devices onboarded to MDE.
**Why:** Centralized ASR rule reports and advanced hunting come from MDE.
**Verify:** Intune → **Endpoint security → Microsoft Defender for Endpoint**.
**Implement:** Deploy the **Defender for Endpoint Integration** solution.

## 2.6 Application inventory (for exclusions)
**Description:** Awareness of legitimate apps that may trip a rule.
**Why:** Audit mode reveals them; you exclude them before moving to Block.
**Verify:** Review **`ASR-AuditReport.ps1`** output during the audit phase.
**Implement:** Maintain an exclusions list per rule as needed.

---
## Checklist
- [ ] Intune licensing assigned
- [ ] Defender AV active + real-time protection on — `ASR-Discovery.ps1`
- [ ] Supported Windows build
- [ ] Devices enrolled
- [ ] (Recommended) MDE onboarded for reporting
- [ ] Pilot Entra group created
