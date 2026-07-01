# 2. Requirements Guide — Windows Firewall Management

Verify **every** requirement before configuring. Each entry: **Description · Why · Verify ·
Implement-if-missing.** Category-wide prerequisites are in `global-requirements-intune-solutions.md`.

## 2.1 Licensing
**Description:** Intune (Plan 1).
**Why:** Intune delivers and reports the firewall policy.
**Verify:** M365 admin center → **Billing → Licenses**.
**Implement:** Assign M365 E3/E5 or Business Premium (Intune included).

## 2.2 Device enrollment
**Description:** Devices enrolled in Intune.
**Why:** The firewall policy applies only to enrolled devices.
**Verify:** Intune → **Devices → All devices**.
**Implement:** Enable automatic enrollment; enroll devices.

## 2.3 Supported Windows OS
**Description:** Windows 10/11.
**Why:** The firewall CSP settings require a supported Windows build.
**Verify:** `winver`; run **`WFM-Discovery.ps1`**.
**Implement:** Patch/upgrade to a supported build.

## 2.4 Inventory of legitimate inbound needs
**Description:** Awareness of apps/services that require inbound connections.
**Why:** Default-deny inbound can block legitimate listeners (e.g. Remote Help, remote management, line-of-business servers).
**Verify:** Review current inbound rules (`WFM-Discovery.ps1` lists rule counts; export details as needed).
**Implement:** Plan explicit allow rules for required inbound services.

## 2.5 No conflicting firewall management
**Description:** No legacy GPO firewall or baseline managing the same settings.
**Why:** Two policies setting the firewall fight each other.
**Verify:** Run **`WFM-ConflictCheck.ps1`**; check the security baseline for firewall settings.
**Implement:** Make Intune the single firewall authority; disable/scope away the GPO and baseline firewall settings.

---
## Checklist
- [ ] Intune licensing assigned
- [ ] Devices enrolled
- [ ] Supported Windows build — `WFM-Discovery.ps1`
- [ ] Legitimate inbound needs documented (allow rules planned)
- [ ] No conflicting GPO/baseline firewall management — `WFM-ConflictCheck.ps1`
- [ ] Pilot Entra group created
