# 2. Requirements Guide — Healthcare Shared Clinical Device Management — WOWs, Kiosks & Tablets in Microsoft Intune

Verify **every** requirement before provisioning. Each entry: **Description · Why · Verify ·
Implement-if-missing.** Never assume a prerequisite is already in place. Category-wide
prerequisites (tenant, roles, HIPAA/HITRUST data-handling, change control, maintenance windows,
rollback) are in `global-requirements-healthcare-solutions.md`.

## R1 — Microsoft Intune licensing
**Description:** Microsoft Intune (Plan 1), included in M365 E3/E5 or Business Premium.
**Why:** Intune delivers the Autopilot profile, Shared PC / kiosk configuration profiles, and the clinical app baseline, and reports device state.
**Verify:** Microsoft 365 admin center (`https://admin.microsoft.com`) → **Billing → Licenses** → confirm an Intune-bearing SKU.
**Implement-if-missing:** Assign M365 E3/E5 or Business Premium to the service/admin account that owns enrollment.

## R2 — Microsoft Entra ID and admin roles
**Description:** A Microsoft Entra ID tenant with an account holding **Intune Administrator** (and the ability to create groups and Autopilot/enrollment profiles).
**Why:** Self-deploying Autopilot joins the device to Entra ID; the configuration and app profiles are authored and assigned in Intune.
**Verify:** Microsoft Entra admin center (`https://entra.microsoft.com`) → **Identity → Roles & admins** → confirm role assignment.
**Implement-if-missing:** Assign **Intune Administrator** to the deploying account (least-privilege; avoid Global Administrator for routine work).

## R3 — Windows Autopilot registration (hardware hash / OEM)
**Description:** Each shared device is registered to **Windows Autopilot** by **hardware hash** (CSV import) or by **OEM/CSP/reseller** registration.
**Why:** Self-deploying provisioning only runs for devices Autopilot knows about; registration is what makes a device "ours" at first boot.
**Verify:** Intune admin center (`https://intune.microsoft.com`) → **Devices → Enrollment → Windows → Windows enrollment → Devices** (Windows Autopilot devices) → confirm the device serial/hash is listed.
**Implement-if-missing:** Capture the hash with `Get-WindowsAutopilotInfo` (or run **`CLINDEV-Discovery.ps1`** to inventory) and import the CSV at **Devices → Enrollment → Windows → Windows enrollment → Devices → Import**; or have the OEM/reseller register the order.

## R4 — Windows edition supporting Shared PC mode and Assigned Access
**Description:** Windows 10 or Windows 11 **Pro, Enterprise, or Education** on each device.
**Why:** **Shared PC mode (SharedPC CSP)** and **Assigned Access** kiosk are not available on Windows Home.
**Verify:** `winver` or **Settings → System → About → Windows specifications → Edition**.
**Implement-if-missing:** Upgrade Home editions to Pro/Enterprise/Education (Subscription Activation via licensing, or a fresh image) before enrollment.

## R5 — TPM 2.0 and attestation (for self-deploying Autopilot)
**Description:** A **TPM 2.0** chip, enabled in UEFI, that supports Autopilot **device attestation**.
**Why:** **Autopilot self-deploying** mode requires TPM 2.0 attestation to provision with no user present; without it the device cannot self-deploy.
**Verify:** `Get-Tpm` (`TpmPresent : True`, `TpmReady : True`) and confirm TPM 2.0 in UEFI; vendor must support attestation.
**Implement-if-missing:** Enable TPM/PTT/fTPM in UEFI; if hardware is TPM 1.2 or non-attestable, use **user-driven** Autopilot or provisioning packages instead (note: that reintroduces a setup interaction).

## R6 — Entra device group for the shared fleet
**Description:** A dynamic security group named **`Clinical – Shared Devices`** that collects all shared clinical devices.
**Why:** Every configuration profile, kiosk profile, and app in this solution is **assigned to this group**; the group is the single targeting surface.
**Verify:** Microsoft Entra admin center → **Identity → Groups → All groups** → search **`Clinical – Shared Devices`**.
**Implement-if-missing:** Create it dynamically (keyed on the Autopilot deployment profile / enrollment) with **`CLINDEV-Set-SharedDeviceGroup.ps1`**, or in Entra → **Groups → New group → Security**, Membership type **Dynamic Device**.

## R7 — Shared-PC account model (no personal owner)
**Description:** A decision on the account model for shared sign-in — **Shared PC mode account management** (guest/Entra accounts cycled and cleaned), with **no primary user** bound to the device.
**Why:** A WOW used by dozens of clinicians per shift must not be tied to one person's identity, license, or compliance state; Shared PC mode is built for the high account-turnover case.
**Verify:** Intune → **Devices → All devices →** (a shared device) → **Properties → Primary user** = should be **None**; run **`CLINDEV-Validation.ps1`** to flag any stray primary user.
**Implement-if-missing:** Apply the Shared PC mode profile (see R-section in Implementation); clear any stray primary user with **`CLINDEV-Remediation.ps1`** (`-Apply`).

## R8 — Standardized clinical app set
**Description:** The defined list of **clinical apps** that must be present on each device type (e.g. the Epic Hyperdrive/Hyperspace client, browser, PDF reader, secure messaging) packaged as **Win32** or **store** apps in Intune.
**Why:** Standardization is the point — every device of a type must carry the same software, deployed **Required**, not manually installed.
**Verify:** Intune → **Apps → All apps** → confirm each clinical app exists and is assignable.
**Implement-if-missing:** Package/import each app (name it exactly as published) and prepare it for **Required** assignment; do not depend on the Epic/Imprivata clients being installed — reference the dedicated **Epic Hyperdrive Client Deployment** and **Imprivata SSO** solutions for those.

## R9 — Network connectivity to Microsoft and clinical endpoints
**Description:** Network access from the device subnet/VLAN to **Microsoft Autopilot/Intune/Entra endpoints** and to the **clinical application servers** (Epic, imaging, messaging).
**Why:** Self-deploying Autopilot needs Microsoft endpoints at first boot; the clinical apps are useless without reach to their back-end servers.
**Verify:** From the device VLAN, confirm reachability of Microsoft endpoints (per the Microsoft 365/Intune network requirements) and the clinical app servers; check captive-portal/802.1X does not block first boot.
**Implement-if-missing:** Open the required egress (or place devices on a clinical VLAN with the correct allow-list); pre-stage Wi-Fi/Ethernet profiles so a cart connects before user sign-in.

## R10 — Imprivata present (only if using tap hand-off)
**Description:** **Imprivata** (OneSign / badge-tap) infrastructure and agent, **only if** fast tap hand-off between clinicians is in scope.
**Why:** Tap hand-off rides on Imprivata, not on Intune; it is layered on top of the shared-device baseline.
**Verify:** Confirm the Imprivata appliance/agent is reachable and the badge readers are present on the carts.
**Implement-if-missing:** Deploy per the dedicated **Imprivata SSO — Badge Tap & EPCS for Clinical Endpoints** solution; **this** solution does not configure Imprivata internals.

## R11 — Hardware for WOWs / carts (battery, reader, mount)
**Description:** Cart hardware sized for clinical use — sufficient **battery** for a shift, a **badge reader** (if tapping), and a stable device mount.
**Why:** Always-on power behavior is meaningless if the cart battery cannot last; tap hand-off needs the reader.
**Verify:** Confirm cart battery runtime against shift length; confirm reader model; confirm the PC's power profile can keep the device awake on battery.
**Implement-if-missing:** Procure/replace cart batteries; add badge readers; standardize the cart/PC pairing so power settings apply uniformly.

---
## Checklist
- [ ] R1 Intune licensing assigned
- [ ] R2 Entra tenant + Intune Administrator role
- [ ] R3 Devices registered to Windows Autopilot (hash / OEM)
- [ ] R4 Windows Pro/Enterprise/Education (Shared PC + Assigned Access capable)
- [ ] R5 TPM 2.0 + attestation (self-deploying capable)
- [ ] R6 `Clinical – Shared Devices` group exists
- [ ] R7 Shared-PC account model decided; no primary user
- [ ] R8 Clinical app set packaged in Intune
- [ ] R9 Network to Microsoft + clinical endpoints verified
- [ ] R10 Imprivata present (only if using tap hand-off)
- [ ] R11 Cart hardware (battery / reader / mount) ready
