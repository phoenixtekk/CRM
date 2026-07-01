# 3. Implementation Guide — Device Enrollment, Identity Association & Asset Inventory

Follow these steps **in order**, in the **Microsoft Intune admin center** (`https://intune.microsoft.com`).

> **Model:** Enable only the enrollment methods you support, gate them with restrictions and an
> enrollment status page, set the primary-user rule, then enroll/import a **pilot**, reconcile the
> inventory, and only then expand. Object names below use the `<Purpose> – <Scope> – <Stage>`
> convention; **reuse each name verbatim** wherever it appears.

## Step 1 — Create the device groups
1. Entra → **Groups → New group** → **Security** → name `Enrollment – Pilot Devices – Pilot`
   (a few representative devices). **Create**.
2. Create `Enrollment – All Managed Devices – Production` (a dynamic device group, or the rest of the
   fleet). **Create**.
3. Create `Enrollment – Shared Devices – Production` for shared/kiosk hardware that will have **no**
   primary user. **Create**.

## Step 2 — Turn on automatic enrollment (Windows)
1. Intune → **Devices → Enrollment → Automatic Enrollment**.
2. Set **MDM user scope** to **Some** and add `Enrollment – Pilot Devices – Pilot`'s users for the
   pilot (expand to **All** at Step 9). Leave **MDM terms of use URL / discovery URL** at defaults.
3. **Save**.

## Step 3 — Set enrollment restrictions (the gate)
1. Intune → **Devices → Enrollment → Enrollment restrictions → Create restriction → Device platform
   restriction**.
2. **Name:** `Enrollment Restriction – Supported Platforms – Production`. **Next**.
3. **Platform settings:** **Allow** the platforms you support (e.g. Windows MDM), set **Personally
   owned** to **Block** if you only allow corporate, leave others **Block**. **Next**.
4. **Assignments → Add groups →** `Enrollment – All Managed Devices – Production`. **Next → Create**.
5. (Optional) **Device limit restriction →** `Enrollment Restriction – Device Limit – Production`,
   set the per-user device cap, assign, **Create**.

## Step 4 — Create the BYOD enrollment profile (only if you support personal devices)
1. Intune → **Devices → Enrollment → Enrollment restrictions**; ensure **Personally owned** is
   **Allow** in a restriction scoped to your BYOD users only.
2. Communicate the **Company Portal** enrollment path to those users (Company Portal → **Add device**).

## Step 5 — Configure the enrollment status page (Windows/Autopilot)
1. Intune → **Devices → Enrollment → Enrollment Status Page → Create profile**.
2. **Name:** `Enrollment Status Page – Corporate Windows – Production`. **Next**.
3. **Settings:** **Show app and profile configuration progress = Yes**; **Block device use until all
   apps and profiles are installed = Yes** (recommended for corporate); set a reasonable timeout.
   **Next**.
4. **Assignments → Add groups →** `Enrollment – Pilot Devices – Pilot`. **Next → Create**.

## Step 6 — Create the Windows Autopilot deployment profile (new corporate hardware)
1. Intune → **Devices → Enrollment → Windows → Deployment Profiles → Create profile → Windows PC**.
2. **Name:** `Autopilot Profile – Corporate Windows – Production`. **Next**.
3. **Out-of-box experience (OOBE):** **Deployment mode = User-driven**; **Join to Entra ID as = Entra
   joined**; set privacy/EULA/account-type per policy. **Next**.
4. **Assignments → Add groups →** `Enrollment – Pilot Devices – Pilot`. **Next → Create**.
5. Register corporate devices (OEM/CSP registration, or **Windows → Devices → Import** a hardware-hash
   CSV) so they pick up this profile.

## Step 7 — Set the device-scope targeting group (primary-user / shared)
1. Run `ENROLLID-Set-DeviceScopeTargeting.ps1` to populate `Enrollment – Shared Devices – Production`
   with devices that should have **no** primary user (kiosks/shared), and to confirm pilot devices
   are in `Enrollment – Pilot Devices – Pilot`.
2. This keeps shared devices out of per-user app/primary-user logic.

## Step 8 — Enroll the pilot and set primary users
1. Enroll the pilot devices via the method you chose (Autopilot self-deploy, or Entra join → auto
   enroll).
2. Intune → **Devices → All devices →** open a pilot device → **Properties → Primary user**; confirm
   it is the daily user. For shared devices, set primary user to **None**
   (**Properties → Primary user → Remove**).
3. Run `ENROLLID-Validation.ps1` on/against a pilot device to confirm it is enrolled and the primary
   user is correct.

## Step 9 — Reconcile inventory and validate the pilot
1. Run `ENROLLID-Discovery.ps1` for the current enrollment posture.
2. Run `ENROLLID-Report.ps1 -ExpectedCsv <list>` to reconcile Intune against your "should exist" list
   and surface stale records, duplicates, missing primary users, and not-yet-enrolled devices.
3. Fix exceptions with `ENROLLID-Remediation.ps1` (runs with `-WhatIf` by default — review first).
   Complete the **Testing Guide**.

## Step 10 — Expand to production
1. Set **Automatic Enrollment → MDM user scope = All** (Step 2).
2. Assign `Enrollment Status Page – Corporate Windows – Production` and
   `Autopilot Profile – Corporate Windows – Production` to
   `Enrollment – All Managed Devices – Production`.
3. Enroll/import the rest of the fleet, then re-reconcile with `ENROLLID-Report.ps1` each cycle.

---
### Order of operations
`Groups → Automatic enrollment → Enrollment restrictions → BYOD profile → Enrollment status page →
Autopilot profile → Device-scope targeting → Pilot enroll + primary users → Reconcile + validate →
Expand`
