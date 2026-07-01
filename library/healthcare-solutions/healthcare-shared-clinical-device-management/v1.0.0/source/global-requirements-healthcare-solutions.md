# Global Requirements — Healthcare Solutions

These category-wide prerequisites apply to **every** Healthcare Solutions deployment. They are
generic across the category; solution-specific requirements live in each solution's
`02-requirements.md`. Each entry uses **Description · Why · Verify · Implement-if-missing** and
never assumes the prerequisite is already in place.

## G1 — Tenant and administrative roles
**Description:** A Microsoft 365 / Microsoft Entra ID tenant with appropriately scoped admin roles for the work (typically **Intune Administrator**; **Global Administrator** only when a one-time tenant-level action genuinely requires it).
**Why:** Every configuration, enrollment, and app action is authored in the Microsoft admin centers and requires the matching role.
**Verify:** Microsoft Entra admin center (`https://entra.microsoft.com`) → **Identity → Roles & admins** → confirm the deploying account's role.
**Implement-if-missing:** Assign least-privilege roles (prefer Intune Administrator over Global Administrator for routine deployment); enable just-in-time elevation if available.

## G2 — Windows licensing and supported editions
**Description:** Windows 10/11 **Pro, Enterprise, or Education** on managed clinical devices, with the licensing to support management features (Shared PC mode, Assigned Access, BitLocker, etc.).
**Why:** Clinical-device management features are not available on Windows Home, and several require a specific edition/license.
**Verify:** `winver` / **Settings → System → About → Edition**; Microsoft 365 admin center → **Billing → Licenses**.
**Implement-if-missing:** Upgrade Home editions; assign the M365 SKU (E3/E5/Business Premium) that includes the required management rights.

## G3 — HIPAA / HITRUST data-handling and change control
**Description:** A documented data-handling posture (HIPAA Security Rule, HITRUST controls) and a **formal change-control process** for changes to clinical devices.
**Why:** Clinical devices touch ePHI; configuration changes are regulated changes and must be authorized, logged, and reversible. No clinical-device change ships outside change control.
**Verify:** Confirm a change ticket/approval and a data-handling sign-off exist for the planned work; confirm logging/audit of admin actions is enabled.
**Implement-if-missing:** Open a change request with scope, risk, rollback, and approver; do not proceed without approval. Ensure ePHI is never exported to scripts/reports (the scripts in these solutions are **read-only** and report metadata, not ePHI).

## G4 — Clinical maintenance windows
**Description:** Agreed **maintenance windows** for provisioning, reconfiguring, or rebooting clinical devices, coordinated with clinical operations.
**Why:** WOWs, kiosks, and nurse-station PCs are in active patient-care use; changes outside an approved window risk disrupting care.
**Verify:** Confirm the scheduled window with clinical/nursing leadership and that affected units are aware.
**Implement-if-missing:** Schedule with clinical operations; stage changes (pilot on spare/standby devices) so floor devices change only inside the window.

## G5 — Network connectivity to Microsoft and clinical endpoints
**Description:** Network paths from the clinical device VLAN to **Microsoft cloud endpoints** (Autopilot, Intune, Entra, Windows Update, Microsoft Store) and to the organization's **clinical application servers/endpoints**.
**Why:** Cloud management and clinical apps both depend on reliable connectivity; first-boot provisioning fails without Microsoft endpoint access.
**Verify:** From the device VLAN, confirm reachability of Microsoft endpoints (per Microsoft's published Intune/M365 network requirements) and of clinical servers; confirm Wi-Fi/802.1X does not block pre-logon.
**Implement-if-missing:** Update firewall/proxy allow-lists; pre-stage Wi-Fi/Ethernet profiles; place devices on a clinical VLAN with the correct egress.

## G6 — A test device (non-production)
**Description:** At least one **non-production test device** of each clinical device type (WOW, kiosk, tablet, nurse-station PC) representative of production hardware.
**Why:** Every change is piloted on a test device before touching patient-care devices; clinical floors are not a test bed.
**Verify:** Confirm a spare/standby device exists, matches production hardware, and is enrolled in a pilot group.
**Implement-if-missing:** Designate spare hardware as the pilot device; register it to Autopilot and add it to the pilot group before configuring.

## G7 — Rollback plan
**Description:** A documented **rollback** for each change (how to revert a profile assignment, restore prior device state, or remove a kiosk lock) plus a backup of the prior configuration.
**Why:** Change control (G3) requires reversibility; a clinical device that breaks must be restorable quickly.
**Verify:** Confirm the rollback steps are written into the change ticket and that prior profile/app assignments are recorded (export before change).
**Implement-if-missing:** Record current assignments and settings (e.g. via the solution's report script) before changing; document the exact un-assign / re-image steps and validate them on the test device.

---
## Checklist
- [ ] G1 Tenant + least-privilege admin roles
- [ ] G2 Windows edition + licensing
- [ ] G3 HIPAA/HITRUST data-handling + change control approved
- [ ] G4 Clinical maintenance window scheduled
- [ ] G5 Network to Microsoft + clinical endpoints verified
- [ ] G6 Non-production test device per device type
- [ ] G7 Rollback plan documented + prior config backed up
