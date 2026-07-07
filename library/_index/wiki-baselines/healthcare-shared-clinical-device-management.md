# Healthcare Shared Clinical Device Management — WOWs, Kiosks & Tablets in Microsoft Intune

> **Version 1.0.0** · Category: Healthcare Solutions · Solution code: CLINDEV

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary — Healthcare Shared Clinical Device Management — WOWs, Kiosks & Tablets in Microsoft Intune

**White-label · Healthcare Solutions**

Clinical floors don't run on personal laptops — they run on **shared devices nobody owns**:
workstations-on-wheels rolled bed to bed, registration kiosks, nurse-station PCs, and tablets
passed hand to hand. When a clinician walks up to a cart mid-round, it has to be **awake, signed in
fast, and running the same clinical apps every time**. This package makes that the default — by
provisioning, standardizing, and locking down those shared Windows devices with **Microsoft
Intune**.

This is a complete, **deploy-it-today** solution written for an administrator with no prior
shared-device experience. Devices provision **unattended** with an **Autopilot self-deploying**
profile (no user at the cart to set them up), run in **Windows Shared PC mode** so many shift users
cycle through cleanly with no personal owner, are **kiosk-locked with Assigned Access** where a
device is single-purpose, carry a **Required clinical app baseline** so every device of a type is
identical, and are tuned to **stay awake on cart battery** through a full shift.

## What you get
- A plain-language **Solution Overview** of the shared, owner-less device model.
- A **Requirements Guide** (R1–R11) with verify / implement-if-missing for every prerequisite, plus category-wide **Global Requirements** (HIPAA/HITRUST, change control, maintenance windows, rollback).
- An **Implementation Guide** of precise, click-by-click Intune steps — every object named, full navigation paths, in the required order.
- Five **PowerShell scripts** for discovery, per-device validation, fleet reporting, safe remediation, and creating the shared-device group.
- **Testing** (acceptance gate) and **Troubleshooting** guides for a confident rollout.

## What this delivers
A standardized shared-clinical-device platform: an **Autopilot self-deploying** profile that
provisions carts and kiosks with no human input, **Shared PC mode** with **no primary user**,
**Assigned Access** lockdown for single-purpose devices, a **Required clinical app baseline**, and
**always-on power on battery** for WOWs — all targeted through one **`Clinical – Shared Devices`**
group, validated against a PASS/FAIL gate, and expanded in waves under change control.

## The standard deployment model
> **Register to Autopilot → self-deploying provision → Shared PC mode standardize → kiosk
> lock-down where single-purpose → clinical app baseline → keep awake on cart → pilot → validate
> → expand.** Phase model: **Assess → Enroll/Provision → Standardize → Lock-down → Pilot →
> Validate → Expand.**

## Why it matters
Shared clinical devices are where care actually happens at the bedside. A cart that sleeps on
battery, a kiosk that breaks out to the desktop, a nurse-station PC tied to one person's identity,
or a WOW missing the Epic client all cost clinicians time at the worst moment. This solution makes
the **shared, no-owner, always-ready** model the enforced default — fast for clinicians, consistent
for IT, and defensible for compliance.


---


# 1. Solution Overview — Healthcare Shared Clinical Device Management — WOWs, Kiosks & Tablets in Microsoft Intune

## What this solution is
Clinical floors run on **shared Windows devices that no single person owns**: **WOWs**
(workstations-on-wheels rolled bed-to-bed), **kiosks** at registration and check-in,
**nurse-station PCs** used by every clinician on shift, and **clinical tablets** passed hand to
hand. This solution provisions, standardizes, and locks those devices down with **Microsoft
Intune** so any authorized clinician can walk up, sign in fast, find the same clinical apps every
time, and the device stays awake on a cart battery through a 12-hour shift.

The model is deliberately **shared and owner-less**. Devices provision **unattended** with an
**Autopilot self-deploying** profile (no user present at first boot), run in **Windows Shared PC
mode** (the SharedPC CSP, surfaced in Intune as the *Shared multi-user device* settings) so many
shift users cycle through cleanly, and — where a device has a single purpose — are hard-locked
with **Assigned Access** kiosk mode. A standardized **clinical app baseline** is delivered as
**Required** so the same software is present on every device of a given type.

## How it works
1. A device is registered to **Windows Autopilot** (by hardware hash or OEM/CSP registration) and tagged for the shared-clinical model.
2. An **Autopilot self-deploying** profile provisions the device **with no user interaction** — it joins Microsoft Entra ID and enrolls in Intune at first boot, on the cart or kiosk stand.
3. A **Shared PC mode** configuration profile (SharedPC CSP) puts the device into **Shared multi-user** state: fast guest/account handling, automatic cleanup of cycled accounts, and account-management thresholds tuned for many users per device.
4. Where the device is **single-purpose** (a check-in kiosk, a wayfinding station), an **Assigned Access** kiosk profile restricts it to one app (single-app) or a defined set (multi-app).
5. A **clinical app baseline** (Win32/store apps) is assigned **Required** to the device group, so the standard clinical software installs on every device of that type.
6. **Power and sleep** settings keep **WOWs awake on battery** (display may dim; the device does not sleep), so a clinician never returns to a locked, asleep cart mid-round.
7. Optional **tap hand-off** (Imprivata badge tap) sits on top for fast clinician switching — referenced here, configured in the dedicated Imprivata solution.
8. Intune reports each device's enrollment type, shared-PC/kiosk state, group membership, app install status, and (critically) that **no personal primary user** is bound to the shared device.

## What you can require
- **Unattended provisioning** of shared devices via an **Autopilot self-deploying** profile.
- **Shared PC mode** (Shared multi-user) for many-users-per-device account handling and cleanup.
- **Kiosk lockdown** (Assigned Access single-app or multi-app) where a device is single-purpose.
- A **Required clinical app baseline** standardized across each device type.
- **Always-on / no-sleep on battery** power behavior for WOWs and carts.
- A **no-personal-owner** posture — shared devices carry **no primary user affinity**.

## Why the shared, no-owner model matters
- **Single-user device affinity is wrong for a cart.** Intune's primary-user / user-affinity model assumes one human owns the device. A WOW used by 30 clinicians a day must have **no primary user** so it isn't tied to one person's identity, license, or compliance state.
- **Self-deploying (not user-driven) Autopilot** is the correct enrollment mode because there is no user at the cart to drive setup — the device must come up on its own.
- **Shared PC mode** exists precisely for this: it manages a large rotation of accounts, cleans up after them, and keeps the device fast and uncluttered shift after shift.

## Limitations (be honest with buyers)
- **Self-deploying Autopilot requires TPM 2.0 and attestation** — the device must support and pass it; consumer-grade hardware may not.
- **Assigned Access kiosk is for single-purpose devices only.** A WOW that must run several clinical apps should use Shared PC mode (with optional multi-app kiosk), **not** a single-app lock.
- **Epic Hyperdrive / Hyperspace and Imprivata internals are out of scope** here — this solution standardizes the shared-device platform and references the dedicated Epic and Imprivata solutions for those products.
- **True roaming profiles are not used** on shared carts; Shared PC mode favors fast, disposable sessions over persistent per-user state.

## The standard deployment model
> **Register to Autopilot → self-deploying provision → Shared PC mode standardize → kiosk
> lock-down where single-purpose → clinical app baseline → keep awake on cart → pilot → validate
> → expand.** Phase model: **Assess → Enroll/Provision → Standardize → Lock-down → Pilot →
> Validate → Expand.**


---


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

## R12 — Enrollment-time grouping owner (Intune Provisioning Client owns the Assigned shared group)
**Description:** When `Clinical – Shared Devices` is an **Assigned** security group (the deterministic **Windows Autopilot device preparation** targeting model), the **Intune Provisioning Client** first-party service principal — **AppId `f1346770-5b25-470b-88bd-d5744ab7952c`**, often shown as **`Intune Autopilot ConfidentialClient`** — must be an **Owner** of that group.
**Why:** Enrollment-time device grouping adds each newly provisioned shared clinical device to the Assigned group by way of this principal *owning* the group. Without the owner the group stays **empty at enrollment** and **none of the Shared PC / power / kiosk profiles or the clinical app baseline deploy**. This is the same first-party principal and mechanism Windows Autopilot device preparation uses. Applies when a **security group targets** the shared devices; a Dynamic (group-tag) group instead relies on its membership rule and does not use this owner.
**Verify:** Microsoft Entra admin center → **Identity → Groups → `Clinical – Shared Devices` → Owners** lists the service principal — confirm by **AppId `f1346770-5b25-470b-88bd-d5744ab7952c`**, not the display name (which varies by tenant). Verify in your tenant before each pilot.
**Implement-if-missing:** Entra → **Groups → `Clinical – Shared Devices` → Owners → Add owners**, search by the AppId, and add it. (If the principal isn't present, open the Intune portal once as Global Administrator to provision it, then add it as owner.)

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
- [ ] R12 Intune Provisioning Client (AppId `f1346770-5b25-470b-88bd-d5744ab7952c`) is an Owner of the Assigned `Clinical – Shared Devices` group


---


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


---


# 3. Implementation Guide — Healthcare Shared Clinical Device Management — WOWs, Kiosks & Tablets in Microsoft Intune

Follow these steps **in order**, primarily in the **Microsoft Intune admin center**
(`https://intune.microsoft.com`) with two steps in the **Microsoft Entra admin center**
(`https://entra.microsoft.com`). Every object is **named** and the name is reused **verbatim** in
later steps and in the testing/troubleshooting guides. Do not skip the prerequisite checks in
`02-requirements.md` and `global-requirements-healthcare-solutions.md`.

> **Model:** Register shared devices to Autopilot → provision unattended with a **self-deploying**
> profile → put them in **Shared PC mode** → **kiosk-lock** the single-purpose ones → push a
> **Required clinical app baseline** → keep WOWs **awake on battery** → pilot, validate, expand.
> Phase model: **Assess → Enroll/Provision → Standardize → Lock-down → Pilot → Validate → Expand.**

## Named objects (created in this guide)
- Entra dynamic group: **`Clinical – Shared Devices`** (whole shared fleet)
- Entra pilot group: **`Clinical – Shared Devices – Pilot`**
- Autopilot deployment profile: **`Clinical Shared – Self-Deploying – Provision`**
- Enrollment Status Page: **`Clinical Shared – ESP – Provision`**
- Shared PC config profile: **`Clinical Shared – Shared PC Mode – Standardize`**
- Power config profile: **`Clinical Shared – WOW Always-On – Standardize`**
- Kiosk config profile (single-purpose only): **`Clinical Shared – Kiosk Assigned Access – Lock-down`**
- App baseline assignment label: **`Clinical Shared – App Baseline – Standardize`**

---

## Phase 1 — Assess

## Step 1 — Inventory the current shared devices
1. Run **`CLINDEV-Discovery.ps1`** (read-only) to inventory candidate shared devices: enrollment type, current Shared PC state, group membership, and **primary user** (which on a true shared device should be **None**).
2. Record which devices are **single-purpose** (registration kiosk, wayfinding) — these get Assigned Access in Phase 4 — versus **multi-app WOWs / nurse-station PCs / tablets**, which get Shared PC mode only.
3. Confirm each device is registered to Autopilot: Intune → **Devices → Enrollment → Windows → Windows enrollment → Devices**. If a device is missing, import its hardware hash (see `02-requirements.md` R3).

---

## Phase 2 — Enroll / Provision

## Step 2 — Create the shared-fleet group (Entra)
1. In the **Microsoft Entra admin center**, go to **Identity → Groups → All groups → New group**.
2. **Group type:** Security. **Group name:** `Clinical – Shared Devices`. **Membership type:** **Dynamic Device**.
3. Click **Add dynamic query** and build a rule that matches the shared fleet — keyed on the Autopilot **group tag** / **order ID** set at registration, for example:
   `(device.devicePhysicalIds -any (_ -contains "[OrderID]:ClinicalShared"))`
   (or match enrollment profile name). Click **Save**.
4. Click **Create**. (You can also create this group, and optionally pre-stage profile/app assignments, with **`CLINDEV-Set-SharedDeviceGroup.ps1 -WhatIf`** then `-Apply`.)

> **Most reliable targeting — an Assigned group owned by the Intune Provisioning Client (enrollment-time
> device grouping).** The dynamic group tag above is convenient, but for **deterministic**
> shared-device enrollment (the **Windows Autopilot device preparation** model), make `Clinical – Shared
> Devices` an **Assigned** security group and add the **Intune Provisioning Client** first-party service
> principal — **AppId `f1346770-5b25-470b-88bd-d5744ab7952c`**, in many tenants displayed as **`Intune
> Autopilot ConfidentialClient`** — as an **Owner** of the group. In Entra: **Groups → `Clinical –
> Shared Devices` → Owners → Add owners**, and search by that **AppId** (match by AppId, **not** the
> display name, which varies by tenant). Enrollment-time device grouping works by this principal
> *owning* the Assigned group — without the owner the group stays **empty at enrollment** and **none of
> the Shared PC / power / kiosk profiles or the clinical app baseline deploy**. The group must be
> **Assigned**, never Dynamic, for this mechanism. This is the same first-party principal and mechanism
> Windows Autopilot device preparation uses. **Verify the owner is present before each pilot.** *(If the
> principal isn't present in the tenant, open the Intune portal once as Global Administrator to
> provision it, then add it as owner.)*

## Step 3 — Create the pilot group (Entra)
1. In **Identity → Groups → All groups → New group**: Security, name `Clinical – Shared Devices – Pilot`, **Membership type:** Assigned.
2. **Members → Add members →** add the **test device(s)** (one of each type — WOW, kiosk, tablet, nurse-station PC). Click **Create**.

## Step 4 — Set the Autopilot group tag at registration
1. In the **Intune admin center**, go to **Devices → Enrollment → Windows → Windows enrollment → Devices** (Windows Autopilot devices).
2. Select the shared devices → **Edit** (or **Assign group tag**) and set the group tag used by the dynamic rule in Step 2 (e.g. `ClinicalShared`). Click **Save**.
3. Confirm each device's **Profile status** will resolve once the deployment profile (Step 5) is created.

## Step 5 — Create the Autopilot self-deploying deployment profile
1. Go to **Devices → Enrollment → Windows → Windows enrollment → Deployment Profiles → Create profile → Windows PC**.
2. **Basics:** **Name:** `Clinical Shared – Self-Deploying – Provision`. **Description:** "Unattended provisioning for shared clinical devices (WOWs, kiosks, tablets, nurse-station PCs)." **Convert all targeted devices to Autopilot** = **No** (target by group). Click **Next**.
3. **Out-of-box experience (OOBE):**
   - **Deployment mode** = **Self-Deploying (preview/GA per tenant)**. *This is the key choice — there is no user at the cart to drive setup.*
   - **Join to Microsoft Entra ID as** = **Microsoft Entra joined**.
   - **Microsoft Software License Terms** = Hide. **Privacy settings** = Hide. **Hide change account options** = Hide.
   - **User account type** = Standard. **Allow pre-provisioned deployment** = as required.
   - **Apply device name template** = **Yes** → set a clear pattern, e.g. `WOW-%SERIAL%` / `KIOSK-%SERIAL%`. Click **Next**.
4. **Assignments → Add groups →** `Clinical – Shared Devices – Pilot` (add `Clinical – Shared Devices` later, at Expand). Click **Next → Create**.

## Step 6 — Create the Enrollment Status Page (ESP)
1. Go to **Devices → Enrollment → Windows → Windows enrollment → Enrollment Status Page → Create**.
2. **Name:** `Clinical Shared – ESP – Provision`. Click **Next**.
3. **Settings:** **Show app and profile configuration progress** = **Yes**; **Block device use until all apps and profiles are installed** = **Yes** (so a clinician never picks up a half-provisioned cart); set a sensible timeout; **Block device use until these required apps are installed** = select the clinical baseline apps from Step 10. Click **Next**.
4. **Assignments → Add groups →** `Clinical – Shared Devices – Pilot`. Click **Next → Create**.

## Step 7 — Self-provision the pilot devices
1. Factory-reset (or first-boot) a pilot device on the cart/kiosk stand with network reachable (see `02-requirements.md` R9).
2. The device runs **`Clinical Shared – Self-Deploying – Provision`** with **no user interaction**: it attests via TPM 2.0, joins Microsoft Entra ID, enrolls in Intune, and shows `Clinical Shared – ESP – Provision`.
3. When the ESP completes, confirm in Intune → **Devices → Windows → All devices** that the device is **Microsoft Entra joined**, **enrolled**, and shows **Primary user = None**.

---

## Phase 3 — Standardize

## Step 8 — Create the Shared PC mode configuration profile
1. Go to **Devices → Manage devices → Configuration → Create → New policy**.
2. **Platform:** Windows 10 and later. **Profile type:** **Templates → Shared multi-user device**. Click **Create**.
   *(Equivalently, the Settings-catalog **SharedPC** category exposes the same SharedPC CSP settings.)*
3. **Basics:** **Name:** `Clinical Shared – Shared PC Mode – Standardize`. **Description:** "Windows Shared PC mode for shared clinical devices: many-user account handling + cleanup, no personal owner." Click **Next**.
4. **Configuration settings — Shared PC mode:**
   - **Shared PC mode** = **Enabled**.
   - **Account management** = **Enabled** (so cycled accounts are cleaned up automatically).
   - **Delete accounts** = **At storage space threshold and inactive threshold** (keeps the device fast across shifts).
   - **Account deletion threshold (free disk space)** = e.g. start delete at **25%**, stop at **50%**.
   - **Inactive account threshold (days)** = e.g. **30** (tune to shift rotation).
   - **Local storage** = **Not configured** (or restrict per policy).
   - **Power policies** = leave to the dedicated power profile in Step 9 (do **not** let Shared PC mode sleep a WOW).
   - **Sleep timeout / Sign in on resume** = configure so the lock screen requires sign-in but the device is not put to sleep on battery (power handled in Step 9).
   - **Maintenance start time / education policies** = set maintenance to off-shift hours.
   Click **Next**.
5. **Assignments → Add groups →** `Clinical – Shared Devices – Pilot`. Click **Next → (Applicability/Review) → Create**.

## Step 9 — Create the WOW always-on power profile
1. Go to **Devices → Manage devices → Configuration → Create → New policy**.
2. **Platform:** Windows 10 and later. **Profile type:** **Settings catalog**. Click **Create**.
3. **Basics:** **Name:** `Clinical Shared – WOW Always-On – Standardize`. **Description:** "Keep WOWs/carts awake on battery so clinicians never return to an asleep, locked cart." Click **Next**.
4. **Configuration settings → Add settings →** from the **Power** category add and set, for **both On Battery and Plugged In**:
   - **Sleep / Sleep Timeout (Plugged In and On Battery)** = **0** (never sleep).
   - **Hibernate Timeout (Plugged In and On Battery)** = **0** (never hibernate).
   - **Turn Off Display / Display Timeout** = a short value (e.g. **10 min**) is fine — the screen may dim/turn off to save battery, but the **device must not sleep**.
   - **Allow Standby States When Sleeping** / **Lid Close Action** = set so closing a tablet/laptop lid does **not** sleep a cart device (e.g. **Do nothing** on AC, and on battery if cart runtime allows).
   - **Critical/Low battery action** = a graceful behavior near depletion (e.g. notify, then hibernate only at critical) so an ePHI session is not lost abruptly.
   Click **Next**.
5. **Assignments → Add groups →** `Clinical – Shared Devices – Pilot`. Click **Next → Create**.

## Step 10 — Assign the clinical app baseline (Required)
1. For **each** clinical app in the standardized set (named exactly as published — e.g. the **Epic Hyperdrive** client packaged as a Win32 app per the dedicated Epic solution, a browser, a PDF reader, a secure-messaging client), go to **Apps → All apps →** select the app (or **Add** to package it first).
2. Open the app → **Properties → Assignments → Edit**.
3. Under **Required**, click **Add group →** `Clinical – Shared Devices – Pilot`. (Use this assignment consistently; label it `Clinical Shared – App Baseline – Standardize` in your runbook.) Click **Review + save**.
4. Repeat for every app in the baseline so the **same software installs on every device of that type**. Confirm these apps are also referenced in the ESP **required apps** list (Step 6) so provisioning blocks until they install.
5. Do **not** hand-install clinical apps on individual carts — the baseline must be Intune-delivered and reportable. For the Epic Hyperdrive client and Imprivata agent, follow the **Epic Hyperdrive Client Deployment** and **Imprivata SSO** solutions respectively; reference, do not duplicate, their packaging here.

---

## Phase 4 — Lock-down (single-purpose devices only)

## Step 11 — Create the Assigned Access kiosk profile (single-purpose devices)
> Apply this **only** to devices that are genuinely single-purpose (a check-in/registration kiosk, a wayfinding station). A multi-app WOW or nurse-station PC stays on Shared PC mode and is **not** single-app locked.
1. Go to **Devices → Manage devices → Configuration → Create → New policy**.
2. **Platform:** Windows 10 and later. **Profile type:** **Templates → Kiosk**. Click **Create**.
3. **Basics:** **Name:** `Clinical Shared – Kiosk Assigned Access – Lock-down`. **Description:** "Assigned Access lockdown for single-purpose clinical kiosks." Click **Next**.
4. **Configuration settings → Kiosk mode:**
   - For a **single-app** kiosk: **Kiosk mode** = **Single app, full-screen kiosk**. **User logon type** = **Auto logon** (a locally created, auto-signed-in kiosk account). **Application type** = the exact app — for a **store** app give its **exact store name/package family name**; for a **Win32/Edge** kiosk specify the app/URL. Disambiguate from similarly named apps using the exact published name and package ID.
   - For a **multi-app** kiosk (a few clinical apps, no full desktop): **Kiosk mode** = **Multi-app kiosk**; add each allowed app by **exact name + AUMID/package family name**; choose the **Start layout** and whether the taskbar is shown.
   - Set **Maintenance window** / **restart** behavior as needed.
   Click **Next**.
5. **Scope tags / Applicability** as required, then **Assignments → Add groups →** the **single-purpose kiosk** subset only (create a child group `Clinical – Shared Devices – Kiosks` if helpful, or target specific devices). Click **Next → Create**.

---

## Phase 5 — Pilot

## Step 12 — Validate the pilot devices
1. On each pilot device, sync policy (**Settings → Accounts → Access work or school → Info → Sync**) or reboot.
2. Run **`CLINDEV-Validation.ps1`** against the pilot devices → confirms each is **enrolled**, in **`Clinical – Shared Devices`** (or the pilot group), has the **Shared PC mode** profile applied (and kiosk profile where applicable), has the **clinical apps installed**, and has **no primary user**. Expect **PASS** on each check.
3. Walk the floor scenarios with a clinician: fast multi-user sign-in on a WOW, kiosk lock holds on a single-purpose device, the cart **stays awake** when left idle on battery, and all clinical apps launch. Complete the **Testing Guide** (`05-testing.md`) and meet its acceptance gate before expanding.

---

## Phase 6/7 — Validate & Expand

## Step 13 — Expand to the full fleet
1. Add **`Clinical – Shared Devices`** to the **Assignments** of: the Autopilot profile (`Clinical Shared – Self-Deploying – Provision`), the ESP (`Clinical Shared – ESP – Provision`), the Shared PC profile (`Clinical Shared – Shared PC Mode – Standardize`), the power profile (`Clinical Shared – WOW Always-On – Standardize`), and the clinical app baseline. Roll out in **waves** within approved maintenance windows.
2. Add single-purpose kiosks to the kiosk profile assignment as they come online.
3. After each wave, run **`CLINDEV-Report.ps1`** for a fleet view (counts by device type / profile / compliance) and **`CLINDEV-Validation.ps1`** for per-device PASS/FAIL. Use **`CLINDEV-Remediation.ps1`** (`-WhatIf` first, then `-Apply`) to clear any stray primary user or re-assign missing profiles.

---
### Order of operations
`Inventory → group (Clinical – Shared Devices) + pilot group → group tag → self-deploying Autopilot profile → ESP → self-provision → Shared PC mode → WOW always-on power → Required clinical app baseline → Assigned Access kiosk (single-purpose only) → validate pilot → expand in waves`


---


# 5. Testing Guide — Healthcare Shared Clinical Device Management — WOWs, Kiosks & Tablets in Microsoft Intune

Run these tests on **pilot devices** (one of each type) before expanding to the fleet. Each test
states **how to run it**, the **expected result**, and a **PASS/FAIL** condition. The
**acceptance gate** at the end must be fully met before Phase 7 (Expand).

> Test against the named objects from `03-implementation.md`:
> `Clinical Shared – Self-Deploying – Provision`, `Clinical Shared – ESP – Provision`,
> `Clinical Shared – Shared PC Mode – Standardize`, `Clinical Shared – WOW Always-On – Standardize`,
> `Clinical Shared – Kiosk Assigned Access – Lock-down`, group `Clinical – Shared Devices`.

## T1 — Device self-provisions unattended (Autopilot self-deploying)
**How:** Factory-reset a pilot device on the cart/kiosk stand with network reachable and **no user signing in**. Let it run.
**Expected:** The device runs `Clinical Shared – Self-Deploying – Provision` with **no user interaction**, joins Microsoft Entra ID, enrolls in Intune, and completes `Clinical Shared – ESP – Provision`.
**PASS:** Device reaches the desktop/kiosk fully provisioned with **no human input**; Intune shows it Entra-joined and enrolled.
**FAIL:** Provisioning prompts for a user, stalls, or errors at OOBE/ESP.

## T2 — No personal owner (primary user = None)
**How:** Intune → **Devices → Windows → All devices →** (pilot device) → **Properties**; or run **`CLINDEV-Validation.ps1`**.
**Expected:** **Primary user = None** on every shared device.
**PASS:** No primary user is bound to any shared device.
**FAIL:** A device shows a personal primary user (run `CLINDEV-Remediation.ps1 -Apply` to clear).

## T3 — Shared PC mode is active
**How:** Run **`CLINDEV-Validation.ps1`** (checks the device's Shared PC state) and confirm in Intune → device → **Device configuration** that `Clinical Shared – Shared PC Mode – Standardize` shows **Succeeded**. On the device, `MDM Diagnostics` / registry confirms SharedPC `EnableSharedPCMode` is set.
**Expected:** Shared PC mode enabled; account management and cleanup thresholds applied.
**PASS:** Profile = Succeeded and the device reports Shared PC mode enabled.
**FAIL:** Profile shows Error/Not applicable or the device is not in Shared PC mode.

## T4 — Fast multi-user logon
**How:** On a WOW/nurse-station PC, sign in as clinician A, sign out, sign in as clinician B, then C — timing each sign-in. (If tap hand-off is in scope, use badge tap.)
**Expected:** Each clinician signs in quickly; cycled accounts are cleaned up over time per the threshold; no per-user clutter accumulates.
**PASS:** Successive different users sign in cleanly and reasonably fast; the device stays usable across many sign-ins.
**FAIL:** Sign-in is slow/blocked for new users, or stale per-user data accumulates and degrades the device.

## T5 — Kiosk lock holds (single-purpose devices)
**How:** On a single-purpose kiosk assigned `Clinical Shared – Kiosk Assigned Access – Lock-down`, attempt to leave the locked app: keyboard shortcuts, task switching, browser address bar / file dialogs, etc.
**Expected:** The device stays confined to the allowed app(s); the user cannot reach the desktop, settings, or other apps.
**PASS:** The Assigned Access lock holds against escape attempts; only the allowed app(s) are reachable.
**FAIL:** A user can break out to the desktop, other apps, settings, or a browser outside the allowed scope.

## T6 — Clinical apps present
**How:** On each device type, confirm every app in the standardized baseline is installed and launches; cross-check Intune → device → **Managed apps** / **`CLINDEV-Validation.ps1`**.
**Expected:** The full clinical app baseline (named exactly as published — e.g. the Epic Hyperdrive client, browser, PDF reader, secure messaging) is **installed (Required)** and launches.
**PASS:** Every baseline app is present and opens on every device of that type.
**FAIL:** Any baseline app is missing or fails to launch.

## T7 — Stays awake on cart battery
**How:** Unplug a WOW so it runs on battery, leave it idle past the display-off time, return after the previous sleep window would have elapsed.
**Expected:** The display may dim/turn off, but the **device does not sleep or hibernate**; it wakes instantly to the lock screen and any session/state is intact.
**PASS:** Device remains awake on battery (no sleep/hibernate); instant resume to lock screen.
**FAIL:** Device sleeps/hibernates on battery, forcing a slow resume or losing the session.

## T8 — Correct group membership and reporting
**How:** Run **`CLINDEV-Report.ps1`** and confirm each pilot device appears in **`Clinical – Shared Devices`** with the right device type, profiles, and compliance.
**Expected:** Every shared device is in the group and reported under the correct type/profile.
**PASS:** Report shows complete, correct membership and profile assignment for all pilot devices.
**FAIL:** A device is missing from the group or shows the wrong profile/type.

---
## Acceptance gate (must all PASS before Expand)
- [ ] **T1** Device self-provisions unattended (self-deploying Autopilot)
- [ ] **T2** No personal owner — primary user = None on every shared device
- [ ] **T3** Shared PC mode active (profile Succeeded)
- [ ] **T4** Fast multi-user logon works across successive clinicians
- [ ] **T5** Kiosk lock holds on single-purpose devices (where applied)
- [ ] **T6** Full clinical app baseline present and launching
- [ ] **T7** WOWs stay awake on cart battery (no sleep/hibernate)
- [ ] **T8** Correct `Clinical – Shared Devices` membership + reporting

Only when **every** applicable item is **PASS** should you proceed to **Expand** (Phase 7) and roll
out to the full fleet in waves within approved maintenance windows.


---


# 6. Troubleshooting Guide — Healthcare Shared Clinical Device Management — WOWs, Kiosks & Tablets in Microsoft Intune

Common failure modes for shared clinical devices and how to fix them. Each issue lists
**Symptoms · Likely cause · Diagnose · Fix.** Make all changes under change control, within a
clinical maintenance window. Objects referenced are the named ones from `03-implementation.md`.

## I1 — Autopilot self-deploy fails (device won't provision unattended)
**Symptoms:** OOBE prompts for a user, stalls, or errors (e.g. attestation/timeout) instead of self-provisioning; ESP never starts or fails.
**Likely cause:** Device not TPM 2.0 / not attestable; device not registered to Autopilot or missing the group tag; no network at first boot; profile set to user-driven; tenant self-deploying mode not available.
**Diagnose:** Confirm the device in **Devices → Enrollment → Windows → Windows enrollment → Devices** with the correct **group tag**; confirm the profile `Clinical Shared – Self-Deploying – Provision` shows **Deployment mode = Self-Deploying** and is assigned to the device's group; check `Get-Tpm` (TPM 2.0, ready) and TPM attestation support; verify network/Wi-Fi reaches Microsoft endpoints at OOBE (no captive portal/802.1X block).
**Fix:** Register the device / set the group tag so it lands in `Clinical – Shared Devices(– Pilot)`; ensure deployment mode is **Self-Deploying** and Entra-joined; enable TPM 2.0 in UEFI (if non-attestable hardware, fall back to user-driven Autopilot/provisioning package); pre-stage a wired/Wi-Fi connection so first boot has network.

## I2 — Shared PC mode not applying
**Symptoms:** `Clinical Shared – Shared PC Mode – Standardize` shows **Error / Not applicable**; device doesn't behave as a shared PC (no account cleanup, personal-style sessions persist).
**Likely cause:** Windows Home edition (SharedPC CSP unavailable); profile not assigned to the device's group; conflicting configuration; device not yet synced.
**Diagnose:** Check `winver` for **Pro/Enterprise/Education**; in Intune → device → **Device configuration**, confirm the profile is assigned and read its error; run **`CLINDEV-Validation.ps1`** for the Shared PC check; review SharedPC registry/`MdmDiagnostics`.
**Fix:** Upgrade Home editions; add `Clinical – Shared Devices` to the profile **Assignments**; resolve conflicting profiles (only one should own SharedPC settings); sync/reboot the device and re-check.

## I3 — Slow multi-user logon
**Symptoms:** New clinicians take a long time to sign in; the device feels sluggish after many shifts; sign-in occasionally fails.
**Likely cause:** Account management/cleanup thresholds too lax so cached accounts accumulate; low free disk; profiles not being deleted; first-time-per-user app/policy processing.
**Diagnose:** Run **`CLINDEV-Discovery.ps1`** / **`CLINDEV-Validation.ps1`** to inspect Shared PC state and free space; review the **Account deletion** and **Inactive account threshold** values in `Clinical Shared – Shared PC Mode – Standardize`; check disk free space on the device.
**Fix:** Tighten **Delete accounts** to *storage + inactive threshold*, lower the inactive-days threshold to match shift rotation, and set the disk thresholds so cleanup runs before the device fills; ensure the clinical apps are device-targeted **Required** (not per-user) so they don't reinstall per sign-in.

## I4 — Kiosk not locking (user breaks out)
**Symptoms:** On a single-purpose device, a user reaches the desktop, settings, a browser, or another app outside the allowed scope.
**Likely cause:** `Clinical Shared – Kiosk Assigned Access – Lock-down` not assigned (or assigned to the wrong device); wrong app identity (AUMID/package family name) so the lock targets nothing; multi-app misconfiguration; a Windows feature update changed Assigned Access behavior.
**Diagnose:** Confirm the kiosk profile is assigned to the **single-purpose** device/sub-group only and shows **Succeeded**; verify the app is specified by **exact name + AUMID/package family name**; test escape paths from T5 in `05-testing.md`; check recent Windows update history.
**Fix:** Correct the app identity and assignment; for a true single-purpose device use **Single app, full-screen kiosk** with **Auto logon**; re-test all escape paths after the fix and after any future feature update. Never apply this profile to a multi-app WOW.

## I5 — Clinical app install gaps
**Symptoms:** A device is missing one or more baseline apps; an app shows **Not installed / Failed** in Intune; the Epic client or secure-messaging app is absent.
**Likely cause:** App not assigned **Required** to `Clinical – Shared Devices`; app assigned per-user instead of per-device on an owner-less device; packaging/detection rule failure; app not in the ESP required list so provisioning didn't wait for it.
**Diagnose:** Intune → app → **Device install status**; run **`CLINDEV-Validation.ps1`** for the app-presence check; review the Win32 app **detection rules** and install logs; confirm the app is in the ESP required-apps list.
**Fix:** Assign each baseline app **Required** to the **device group** (`Clinical – Shared Devices`); fix detection rules; add the app to `Clinical Shared – ESP – Provision` required apps so future provisioning blocks until it installs. For the Epic Hyperdrive client / Imprivata agent, follow their dedicated solutions' packaging — don't hand-install on the cart.

## I6 — Devices sleeping on carts
**Symptoms:** A WOW is asleep/hibernated when a clinician returns; slow resume; lost session/state on battery.
**Likely cause:** `Clinical Shared – WOW Always-On – Standardize` not assigned or overridden; Shared PC mode power policy or another profile is sleeping the device; sleep/hibernate timeouts not set to 0 on battery; lid-close action sleeps the device.
**Diagnose:** In Intune → device → **Device configuration**, confirm the power profile is **Succeeded** and not in conflict; on the device run `powercfg /a` and `powercfg /query` to see active sleep/hibernate settings; check whether Shared PC mode or another profile is setting power policy.
**Fix:** Ensure `Clinical Shared – WOW Always-On – Standardize` is assigned and wins: set **Sleep** and **Hibernate** timeouts to **0** for **On Battery** (display-off is fine), set **Lid close action** to not sleep, and remove power settings from any competing profile (only the power profile should own power policy). Re-run **T7** in `05-testing.md`.

## I7 — Stray primary user on a shared device
**Symptoms:** A WOW/kiosk shows a personal **primary user**; the device appears tied to one clinician's identity/compliance.
**Likely cause:** A user-driven enrollment or affinity bound a primary user to a device that should be owner-less.
**Diagnose:** Intune → device → **Properties → Primary user**; or run **`CLINDEV-Validation.ps1`** (flags any primary user).
**Fix:** Run **`CLINDEV-Remediation.ps1 -WhatIf`** to preview, then **`-Apply`** to clear the primary user; ensure the device provisions via **self-deploying** (not user-driven) Autopilot so it stays owner-less going forward.

## I8 — Device missing from the group / wrong profiles
**Symptoms:** A device doesn't receive the Shared PC / power / app profiles; it isn't in `Clinical – Shared Devices`.
**Likely cause:** Missing or wrong Autopilot **group tag** so the dynamic rule doesn't match; dynamic-group membership still processing; rule logic doesn't match the device's attributes.
**Diagnose:** Entra → **Groups →** `Clinical – Shared Devices` → **Members** (and **Dynamic membership rules**); compare against the device's group tag in **Windows Autopilot devices**; run **`CLINDEV-Report.ps1`** to see membership/profile coverage.
**Fix:** Set the correct group tag on the device (Step 4 in `03-implementation.md`) or correct the dynamic rule; allow membership to process, then sync the device; re-run **`CLINDEV-Validation.ps1`**. Use **`CLINDEV-Set-SharedDeviceGroup.ps1`** to (re)create/verify the group rule.

## I9 — Shared device group empty after enrollment (no shared-device profiles or apps deploy)
**Symptoms:** `Clinical – Shared Devices` is **empty after devices provision**; none of the Shared PC / power / kiosk profiles or the clinical app baseline deploy, even though devices enrolled fine.
**Likely cause:** The group is an **Assigned** security group (the Windows Autopilot device preparation targeting model) but the **Intune Provisioning Client** first-party service principal (**AppId `f1346770-5b25-470b-88bd-d5744ab7952c`**, often shown as **`Intune Autopilot ConfidentialClient`**) is **not an Owner** of it, so enrollment-time device grouping can't populate it.
**Diagnose:** Entra → **Groups → `Clinical – Shared Devices` → Owners**; confirm the service principal is listed by **AppId `f1346770-5b25-470b-88bd-d5744ab7952c`** (not the display name, which varies by tenant). (If you use the **Dynamic** group-tag model instead, this owner does not apply — see I8.)
**Fix:** Entra → **Groups → `Clinical – Shared Devices` → Owners → Add owners**, search by that **AppId**, add it, then re-provision a pilot device. The group must be **Assigned**, not Dynamic, for this mechanism (the same principal Windows Autopilot device preparation uses). If the principal isn't present in the tenant, open the Intune portal once as Global Administrator to provision it, then add it as owner.

---
### Escalation
If a device still fails after these steps, capture state with **`CLINDEV-Discovery.ps1`** and
**`CLINDEV-Validation.ps1`**, record the failing profile's Intune error, and escalate with the
device serial, Autopilot group tag, and the named profile that failed — under the active change
ticket. For Epic Hyperdrive or Imprivata-specific faults, escalate via the dedicated **Epic
Hyperdrive Client Deployment** and **Imprivata SSO** solutions.


---


# 7. Best Practices — Healthcare Shared Clinical Device Management — WOWs, Kiosks & Tablets in Microsoft Intune

These practices keep shared clinical devices reliable, standardized, and audit-ready over time.
They reinforce the phase model: **Assess → Enroll/Provision → Standardize → Lock-down → Pilot →
Validate → Expand.**

## Model and ownership
- **Keep shared devices owner-less.** Never bind a primary user / user-affinity to a WOW, kiosk, or shared tablet — it ties the device to one person's identity, license, and compliance state. Sweep for stray primary users regularly with **`CLINDEV-Validation.ps1`** / **`CLINDEV-Remediation.ps1`**.
- **Use self-deploying Autopilot for shared provisioning, not user-driven.** There is no user at the cart; the device must come up on its own. Reserve user-driven Autopilot for personally assigned devices in other solutions.
- **Match the lock to the device's purpose.** Single-purpose device (registration kiosk, wayfinding) → **Assigned Access** (single- or multi-app). Multi-app clinical device (WOW, nurse-station PC) → **Shared PC mode**, optionally with a multi-app kiosk — **never** a single-app lock.

## Grouping and targeting
- **Target one group, not loose device lists.** Assign every profile and app to **`Clinical – Shared Devices`** (dynamic, keyed on the Autopilot group tag / enrollment). New devices inherit the full configuration automatically as they self-provision.
- **Keep a permanent pilot group.** `Clinical – Shared Devices – Pilot` should always hold a spare of each device type so changes are validated off the floor before fleet rollout.
- **Use a kiosk sub-group** for single-purpose devices so the Assigned Access profile never lands on a multi-app WOW.

## Provisioning and apps
- **Block device use until provisioning completes** (ESP) so a clinician never picks up a half-built cart missing clinical apps.
- **Deliver the clinical baseline as Required and reportable** — never hand-install apps on individual carts. Name each app exactly as published; for the Epic Hyperdrive client and Imprivata agent, follow the dedicated solutions and reference (don't duplicate) their packaging.
- **Standardize device naming** (`WOW-%SERIAL%`, `KIOSK-%SERIAL%`) so the floor, the report, and the help desk speak the same language.

## Power and reliability on carts
- **Never let a WOW sleep on battery.** Display-off is fine for battery life; sleep/hibernate is not — clinicians must not return to an asleep, slow-to-resume cart mid-round.
- **Size the battery to the shift,** and set a graceful critical-battery action so an ePHI session is not lost abruptly at depletion.
- **Pair power policy to hardware.** Validate the always-on profile on the actual cart model; lid-close and standby behavior differ across tablets and laptops.

## Security and compliance
- **Run all changes through change control** within clinical maintenance windows (see `global-requirements-healthcare-solutions.md`). A clinical-device change is a regulated change.
- **Keep scripts read-only and ePHI-free.** The solution's scripts report device metadata (enrollment, profile, group, primary user, app state) — never ePHI. Default them to `-WhatIf`; require `-Apply` to act.
- **Lock kiosks against escape** and re-test escape paths after Windows feature updates, which can change Assigned Access behavior.
- **Pair with the rest of the clinical-endpoint stack** — compliance policies, BitLocker, Defender, and (if used) Imprivata tap hand-off — so the shared device is both fast *and* secure.

## Operations and lifecycle
- **Report regularly.** Run **`CLINDEV-Report.ps1`** on a schedule for counts by type/profile/compliance, and **`CLINDEV-Validation.ps1`** for per-device drift; remediate stray primary users and missing profiles promptly.
- **Roll out in waves** within maintenance windows; validate each wave before the next.
- **Re-validate after Windows updates,** especially Shared PC mode and Assigned Access behavior, before assuming the lock and the cleanup still hold.
- **Document rollback** for every profile so a misbehaving change can be un-assigned and the device restored quickly.


---


# 8. Deliverables Summary — Healthcare Shared Clinical Device Management — WOWs, Kiosks & Tablets in Microsoft Intune

This solution is a complete, **deploy-it-today** package for provisioning, standardizing, and
locking down **shared clinical Windows devices** — WOWs, kiosks, nurse-station PCs, and clinical
tablets — with **Microsoft Intune**. Everything below ships in the package.

## Documents
1. **Executive Summary** (`executive-summary.md`) — the business case and what the package delivers.
2. **Solution Overview** (`01-solution-overview.md`) — what the shared-device model is and how it works, in plain language.
3. **Requirements Guide** (`02-requirements.md`) — R1–R11 with **Verify / Implement-if-missing** for every prerequisite.
4. **Global Requirements — Healthcare Solutions** (`global-requirements-healthcare-solutions.md`) — category-wide tenant, licensing, HIPAA/HITRUST, maintenance-window, network, test-device, and rollback prerequisites.
5. **Implementation Guide** (`03-implementation.md`) — ordered, click-by-click Intune steps with full navigation paths and every object named (Autopilot self-deploying profile, Shared PC profile, kiosk profile, power profile, `Clinical – Shared Devices` group).
6. **Testing Guide** (`05-testing.md`) — T1–T8 with PASS/FAIL and an acceptance gate.
7. **Best Practices** (`07-best-practices.md`) — operating the shared fleet reliably over time.
8. **Troubleshooting Guide** (`06-troubleshooting.md`) — the common failure modes and their fixes.

## PowerShell scripts (5)
All scripts default to **read-only**; the two that can change state require an explicit `-Apply`
(and support `-WhatIf`). Each carries a `.SYNOPSIS` with PURPOSE / HOW TO RUN / EXPECTED RESULTS
and a neutral `.NOTES` ("Healthcare Solutions — read-only.").

1. **`CLINDEV-Discovery.ps1`** — inventory shared clinical devices: enrollment type, Shared PC state, group membership, and primary user (should be none). *Read-only.*
2. **`CLINDEV-Validation.ps1`** — per-device PASS/FAIL: enrolled, in `Clinical – Shared Devices`, Shared PC / kiosk profile applied, clinical apps installed, no primary user. *Read-only.*
3. **`CLINDEV-Report.ps1`** — fleet report: counts by device type / profile / compliance → CSV. *Read-only.*
4. **`CLINDEV-Remediation.ps1`** — safe fixes: clear stray primary user, re-assign missing profiles. *Defaults to `-WhatIf`; `-Apply` to act.*
5. **`CLINDEV-Set-SharedDeviceGroup.ps1`** — create the dynamic `Clinical – Shared Devices` group (keyed on Autopilot profile / enrollment) and optionally assign profiles/apps. *Supports `-WhatIf`.*

## Visual
- **`CLINDEV-hero.png`** — hero image for the solution listing.

## What this delivers
A standardized shared-clinical-device platform: devices **self-provision unattended** via an
Autopilot self-deploying profile, run in **Shared PC mode** with no personal owner, are
**kiosk-locked** where single-purpose, carry a **Required clinical app baseline**, and **stay
awake on cart battery** — validated against an acceptance gate and rolled out in waves under
change control.
