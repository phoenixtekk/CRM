# 2. Requirements Guide — WSUS to Windows Update for Business Migration

Verify **every** requirement before you start the cutover. Each entry: **Description · Why ·
Verify · Implement-if-missing.** Category-wide prerequisites are in
`global-requirements-intune-solutions.md`.

## 2.1 Licensing
**Description:** Intune (Plan 1). Windows Update for Business itself is a free Windows feature.
**Why:** Intune delivers the update rings/policies and reports status; it is the replacement control
plane for WSUS.
**Verify:** M365 admin center → **Billing → Licenses**.
**Implement:** Assign M365 E3/E5 or Business Premium (Intune included).

## 2.2 Device enrollment
**Description:** Targeted devices enrolled in Intune (Entra-joined or hybrid-joined).
**Why:** Update rings apply only to enrolled devices; WSUS-managed devices that are not yet enrolled
cannot receive WUfB policy.
**Verify:** Intune → **Devices → All devices**.
**Implement:** Enable automatic enrollment; enroll/join the devices currently served by WSUS.

## 2.3 Supported Windows OS
**Description:** Windows 10/11 (Pro/Enterprise/Education).
**Why:** WUfB policies (rings, feature/quality update policies) require a supported build.
**Verify:** `winver`; run `WSUSM-Discovery.ps1`.
**Implement:** Patch/upgrade to a supported build.

## 2.4 Inventory of the current WSUS configuration
**Description:** A record of the WSUS server URL, the GPO/registry update policy in force, and the
current approvals/groups in the WSUS console.
**Why:** You cannot safely remove the old authority or confirm the cutover without knowing what is
in place today.
**Verify:** Run `WSUSM-Discovery.ps1` on representative devices (reads `WUServer`,
`DoNotConnectToWindowsUpdateInternetLocations`, `UseWUServer`); review the WSUS console for approval
groups.
**Implement:** Capture the discovery output and the WSUS group/approval list before changing
anything.

## 2.5 Network (Windows Update + Delivery Optimization)
**Description:** Outbound HTTPS to Windows Update and Delivery Optimization endpoints.
**Why:** After cutover, devices pull updates from Microsoft and share content via Delivery
Optimization instead of from the WSUS server.
**Verify:** From a device, Windows Update can check online; DO endpoints reachable.
**Implement:** Allow Windows Update / Delivery Optimization URLs through proxy/firewall; do not block
DO peer ports if you want LAN caching. Ensure `DoNotConnectToWindowsUpdateInternetLocations` is not
left enabled (it blocks the online scan).

## 2.6 Single update authority (remove the WSUS/GPO conflict)
**Description:** Intune/WUfB becomes the only update authority — the leftover WSUS pointer and
GPO update policy must be removed from migrated devices.
**Why:** Two authorities fight: a device that still has `WUServer`/`UseWUServer` set will keep
scanning WSUS and ignore the Intune ring.
**Verify:** Run `WSUSM-Discovery.ps1` (flags `WUServer`/`UseWUServer`) and `WSUSM-Validation.ps1`
(confirms the device scans Microsoft).
**Implement:** Remove the **Specify intranet Microsoft update service location** and **Do not connect
to any Windows Update Internet locations** GPO settings; clear the residual registry pointers with
`WSUSM-Remediation.ps1`.

## 2.7 Migration ring groups
**Description:** Entra security groups for the pilot and broad migration rings.
**Why:** Rings are assigned to groups; the pilot cuts over first, the broad ring follows.
**Verify:** Entra → **Groups** show the pilot and broad groups.
**Implement:** Create `WUfB – Ring – Pilot` and `WUfB – Ring – Broad` (see Implementation Step 1).

## 2.8 (Optional) Windows Update for Business reports
**Description:** Diagnostic data enabled + a Log Analytics workspace for the WUfB reports.
**Why:** Required only for the richer reporting experience that replaces WSUS console reporting.
**Verify:** Devices send **Required** diagnostic data; the workspace is configured.
**Implement:** Set diagnostic data via an Intune policy and connect Windows Update for Business
reports (optional).

---
## Checklist
- [ ] Intune licensing assigned
- [ ] Devices enrolled / Entra-joined
- [ ] Windows 10/11 supported build — `WSUSM-Discovery.ps1`
- [ ] Current WSUS server, GPO policy, and approvals inventoried
- [ ] Network allows Windows Update + Delivery Optimization
- [ ] Conflicting WSUS/GPO update authority identified for removal
- [ ] `WUfB – Ring – Pilot` and `WUfB – Ring – Broad` Entra groups created
- [ ] (Optional) Diagnostic data + Log Analytics for WUfB reports
