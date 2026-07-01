# 2. Requirements Guide — Endpoint Security Baselines

Verify **every** requirement before configuring. Each entry: **Description · Why · Verify ·
Implement-if-missing.** Category-wide prerequisites are in `global-requirements-intune-solutions.md`.

## 2.1 Licensing
**Description:** Intune (Plan 1). The Defender for Endpoint baseline needs MDE licensing.
**Why:** Intune delivers baselines; the MDE baseline only applies to MDE-licensed/onboarded devices.
**Verify:** M365 admin center → **Billing → Licenses**.
**Implement:** Assign M365 E3/E5 or Business Premium; add MDE licensing for the Defender baseline.

## 2.2 Device enrollment
**Description:** Targeted devices enrolled in Intune.
**Why:** Baselines apply only to enrolled devices.
**Verify:** Intune → **Devices → All devices**.
**Implement:** Enable automatic enrollment; enroll devices.

## 2.3 Supported Windows OS
**Description:** Windows 10/11 current build.
**Why:** Baseline settings map to OS capabilities; older builds may not honor all settings.
**Verify:** `winver`; run **`ESB-Discovery.ps1`** for the current posture.
**Implement:** Patch/upgrade to a supported build.

## 2.4 Inventory of existing configuration
**Description:** Awareness of existing config profiles, security policies, and any GPOs.
**Why:** Baselines can conflict with settings you already manage elsewhere.
**Verify:** Intune → **Devices → Configuration**; **Endpoint security** policies; run **`ESB-ConflictCheck.ps1`** after assignment.
**Implement:** Document current policies; plan to consolidate or scope to avoid conflicts.

## 2.5 (Optional) Defender for Endpoint onboarding
**Description:** Devices onboarded to MDE.
**Why:** Required for the Microsoft Defender for Endpoint baseline.
**Verify:** Intune → **Endpoint security → Microsoft Defender for Endpoint**.
**Implement:** Deploy the **Defender for Endpoint Integration** solution.

## 2.6 Pilot group
**Description:** A pilot security group.
**Why:** Baselines change many settings — pilot to catch app/usability impact.
**Verify:** Entra → **Groups**.
**Implement:** Create a `Baseline-Pilot` security group.

---
## Checklist
- [ ] Intune licensing assigned (MDE licensing for the Defender baseline)
- [ ] Devices enrolled
- [ ] Supported Windows build — `ESB-Discovery.ps1`
- [ ] Existing config/GPO inventory documented
- [ ] (Optional) Devices onboarded to MDE for the Defender baseline
- [ ] Pilot Entra group created
