# 2. Requirements Guide — Windows Updates for Business

Verify **every** requirement before configuring. Each entry: **Description · Why · Verify ·
Implement-if-missing.** Category-wide prerequisites are in `global-requirements-intune-solutions.md`.

## 2.1 Licensing
**Description:** Intune (Plan 1). WUfB itself is a free Windows feature.
**Why:** Intune delivers the update rings/profiles and reports status.
**Verify:** M365 admin center → **Billing → Licenses**.
**Implement:** Assign M365 E3/E5 or Business Premium (Intune included).

## 2.2 Device enrollment
**Description:** Targeted devices enrolled in Intune.
**Why:** Update rings apply only to enrolled devices.
**Verify:** Intune → **Devices → All devices**.
**Implement:** Enable automatic enrollment; enroll devices.

## 2.3 Supported Windows OS
**Description:** Windows 10/11 (Pro/Enterprise/Education).
**Why:** WUfB policies (rings, feature profiles, expedite) require a supported build.
**Verify:** `winver`; run **`WUFB-Discovery.ps1`**.
**Implement:** Patch/upgrade to a supported build.

## 2.4 Network (Windows Update + Delivery Optimization)
**Description:** Outbound HTTPS to Windows Update and Delivery Optimization endpoints.
**Why:** Devices pull updates from Microsoft and share content via Delivery Optimization.
**Verify:** From a device, Windows Update can check online; DO endpoints reachable.
**Implement:** Allow Windows Update / Delivery Optimization URLs through proxy/firewall; do not block DO peer ports if you want LAN caching.

## 2.5 Single update authority (no conflicts)
**Description:** Intune/WUfB is the authority for updates — not a leftover WSUS/GPO or ConfigMgr.
**Why:** Two update authorities fight and stall updates.
**Verify:** Check for a `WUServer` GPO/registry value; run **`WUFB-Discovery.ps1`** (flags WSUS).
**Implement:** Remove the WSUS/GPO settings (or set co-management update workload to Intune).

## 2.6 (Optional) Windows Update for Business reports
**Description:** Diagnostic data enabled + a Log Analytics workspace for the WUfB reports.
**Why:** Required only for the richer Update Compliance / WUfB reporting experience.
**Verify:** Devices send **Required** diagnostic data; the workspace is configured.
**Implement:** Set diagnostic data via an Intune policy and connect Windows Update for Business reports (optional).

---
## Checklist
- [ ] Intune licensing assigned
- [ ] Devices enrolled
- [ ] Windows 10/11 supported build — `WUFB-Discovery.ps1`
- [ ] Network allows Windows Update + Delivery Optimization
- [ ] No conflicting WSUS/GPO/ConfigMgr update authority
- [ ] (Optional) Diagnostic data + Log Analytics for WUfB reports
- [ ] Pilot + Broad Entra groups created
