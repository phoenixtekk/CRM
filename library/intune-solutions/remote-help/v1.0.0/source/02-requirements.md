# 2. Requirements Guide — Remote Help

Verify **every** requirement before configuring. Each entry: **Description · Why · Verify ·
Implement-if-missing.** Category-wide prerequisites are in `global-requirements-intune-solutions.md`.

## 2.1 Remote Help licensing
**Description:** A Remote Help license — the **Intune Suite** or the standalone **Remote Help add-on**.
**Why:** Remote Help is an add-on capability; it won't enable without the license.
**Verify:** M365 admin center → **Billing → Licenses** (look for Intune Suite / Remote Help); Intune → **Tenant administration → Remote Help**.
**Implement:** Purchase the Intune Suite or Remote Help add-on and assign to helpers (and sharers as required).

## 2.2 Intune + enrollment
**Description:** Intune subscription with target devices enrolled.
**Why:** Remote Help is deployed and governed through Intune.
**Verify:** Intune → **Devices → All devices**.
**Implement:** Enable automatic enrollment; enroll devices.

## 2.3 The Remote Help app
**Description:** The Remote Help application installed on participating devices.
**Why:** Both helper and sharer run the app to connect.
**Verify:** App present at `C:\Program Files\Remote help\` (or run **`RHELP-Discovery.ps1`**).
**Implement:** Deploy the Remote Help app via Intune (Win32/Store) as **Required** to the relevant groups.

## 2.4 RBAC roles
**Description:** Intune RBAC roles defining who can help and with what capabilities.
**Why:** Least-privilege control over remote assistance.
**Verify:** Intune → **Tenant administration → Roles**.
**Implement:** Assign **Help Desk Operator** (or a custom role with Remote Help permissions) to your support staff.

## 2.5 Network access
**Description:** Outbound HTTPS to the Remote Help / Intune service endpoints.
**Why:** Sessions are brokered through the cloud service.
**Verify:** Helpers and sharers can reach the Remote Help endpoints (the app connects).
**Implement:** Allow the Remote Help service URLs through proxy/firewall.

## 2.6 Supported OS
**Description:** Windows 10/11 (Remote Help also supports certain macOS/Android scenarios).
**Why:** The app and features require supported platforms.
**Verify:** `winver`.
**Implement:** Patch/upgrade as needed.

---
## Checklist
- [ ] Remote Help license (Intune Suite / add-on) assigned
- [ ] Devices enrolled in Intune
- [ ] Remote Help app deployed — `RHELP-Discovery.ps1`
- [ ] RBAC roles assigned to help-desk staff
- [ ] Network allows Remote Help endpoints
- [ ] Supported OS
- [ ] Pilot Entra group (helpers + sharers) created
