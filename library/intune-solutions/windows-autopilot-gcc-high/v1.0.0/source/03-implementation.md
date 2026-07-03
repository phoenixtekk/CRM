# Implementation Guide — Windows Autopilot (Government / GCC High)

This guide builds the solution **step by step in the GCC High portals**, entirely on the
**supported** technology — **Windows Autopilot device preparation** (user-driven, Microsoft
Entra join). It assumes the **Assess** gate in `02-requirements.md` passed. Object names are
used **verbatim** from `01-solution-overview.md` — reuse them exactly. GCC-High-only caveats
appear **inline at the step where they matter**, boxed like this:

> **GCC High caveat:** …

**Portals used (bookmark these):**
- Intune admin center: **`https://intune.microsoft.us`**
- Entra admin center: **`https://entra.microsoft.us`** *(verify for GCC High)*
- Azure portal: **`https://portal.azure.us`**
- Microsoft 365 admin: **`https://portal.office365.us`**
- Sign-in: **`https://login.microsoftonline.us`**

> **GCC High caveat (applies to the whole guide):** Every navigation path below is written for
> the **`*.us`** portals. If a screen or blade shown in a Commercial Autopilot tutorial is
> missing here, it is almost always because the feature **is not available in GCC High** (see
> the parity table in `01-solution-overview.md` and `gcc-high-parity-notes.md`) — it is **not
> a bug**. In particular, **do not** look for **"Windows Autopilot" / "Deployment Profiles" /
> "Windows Autopilot devices" (hardware-hash import)**: **classic Autopilot does not exist in
> GCC High.** Use **Windows Autopilot device preparation** throughout.

---

## Phase A — Configure (build the objects)

### Step 1 — Create the Microsoft Entra security groups

Sign in to **`https://entra.microsoft.us`** *(verify for GCC High)* as Intune Administrator.

1. **Groups → All groups → New group.**
2. Create **`WAPG-Provisioning-Users`**
   - **Group type:** Security · **Membership type:** Assigned
   - Add the pilot users who will provision devices. Select **Create**.
3. **New group** again → create **`WAPG-Pilot`**
   - **Group type:** Security · **Membership type:** Assigned
   - Add the same pilot users (this group targets policies/apps to the pilot). **Create.**
4. **New group** again → create **`WAPG-Autopilot-Devices`**
   - **Group type:** Security
   - **Membership type:** **Assigned** — **not** Dynamic.

     > **GCC High caveat:** The device group **must** be **Assigned**. Enrollment Time
     > Grouping (how devices land in the group during OOBE) works by the provisioning service
     > principal *owning* an assigned group; a **dynamic** group breaks it.

   - Do **not** add members. Select **Create**.

### Step 2 — Add the Intune Provisioning Client as owner of the device group

This is the step most often missed, and it is the single reason "nothing deploys during OOBE."

1. Still in **`https://entra.microsoft.us`** → **Groups → All groups** →
   **`WAPG-Autopilot-Devices`** → **Owners → Add owners**.
2. Search for **Intune Provisioning Client**.

   > **GCC High caveat:** In some tenants this principal is named **Intune Autopilot
   > ConfidentialClient**. Match by **AppId `f1346770-5b25-470b-88bd-d5744ab7952c`**, not by
   > name. If it is not present at all, open `https://intune.microsoft.us` once as Global
   > Administrator to provision it (R6), then return.

3. Select it and **Add**. Confirm it now appears under **Owners**.

Run `WAPG-Validation.ps1` later to confirm the ownership programmatically against US Gov Graph.

### Step 3 — Allow users to join devices to Entra + enable automatic enrollment

1. **`https://entra.microsoft.us`** *(verify for GCC High)* → **Devices → Device settings** →
   **Users may join devices to Microsoft Entra** → set **Selected** and add
   **`WAPG-Provisioning-Users`** (or **All**). **Save.**
2. **`https://intune.microsoft.us`** → **Devices → Enrollment → Automatic Enrollment** → set
   **MDM user scope** to **Some** and select **`WAPG-Provisioning-Users`** (or **All**). Leave
   the MDM terms/discovery URLs at default. **Save.**

   > **GCC High caveat:** The enrollment/discovery URLs default to the sovereign
   > `*.manage.microsoft.us` service — do **not** paste Commercial `*.manage.microsoft.com`
   > values.

### Step 4 — Create the least-privilege RBAC role `WAPG Device Preparation Administrator`

1. **`https://intune.microsoft.us`** → **Tenant administration → Roles → All roles** →
   **Create → Intune role**.
2. **Basics:** Name = **`WAPG Device Preparation Administrator`**; add a description.
3. **Permissions** — set exactly (all others **No**):
   - **Device configurations:** Read = Yes, Create = Yes, Update = Yes, Delete = Yes, Assign = Yes
   - **Enrollment programs:** **Enrollment time device membership assignment = Yes**
   - **Managed apps:** Read = Yes
   - **Mobile apps:** Read = Yes
   - **Organization:** Read = Yes
4. **Scope tags:** add **`WAPG`** (create it if prompted). **Next → Create.**
5. **Assignments → Assign** → members = your admin group; scope (groups) = `WAPG-Pilot`; scope
   tags = `WAPG`.

(Permission set: Microsoft, *Autopilot device preparation requirements → RBAC*.)

### Step 5 — Create the Enrollment Status Page (ESP) profile

1. **`https://intune.microsoft.us`** → **Devices → Enrollment → Enrollment Status Page →
   Create**.
2. Name = **`WAPG-ESP-Provisioning`**.
3. **Settings:**
   - **Show app and profile configuration progress** = **Yes**
   - **Block device use until all apps and profiles are installed** = **Yes**
   - Set a **timeout** (e.g. 60 minutes) and allow reset/retry.
   - **Only show page to devices provisioned by out-of-box experience (OOBE)** = **Yes**
   - Optionally require selected apps to install before desktop access (keep the list **short**).

     > **GCC High caveat:** Keep the OOBE-blocking app count small. Microsoft deliberately
     > limits how many apps run during device-preparation OOBE "to increase stability and
     > achieve a higher success rate." Heavy app lists reduce success rates.

4. **Assignments:** assign to **`WAPG-Pilot`**. **Create.**

### Step 6 — Create a Windows update ring (the GCC High servicing mechanism)

> **GCC High caveat:** Do **not** create Feature/Quality/Expedite/Driver update policies or
> plan **Windows Autopatch** — **none are available in GCC High.** Use **Update rings**.

1. **`https://intune.microsoft.us`** → **Devices → Windows → Update rings for Windows 10 and
   later → Create profile**.
2. Name = **`WAPG-UpdateRing-Pilot`**. Configure a conservative pilot ring (e.g. quality
   deferral 0–7 days, feature deferral per your policy, active hours).
3. **Assignments:** assign to **`WAPG-Pilot`**. **Create.**

### Step 7 — Create a compliance policy

1. **`https://intune.microsoft.us`** → **Devices → Compliance → Create policy** → Platform =
   **Windows 10 and later**.
2. Name = **`WAPG-Compliance-Win11`**. Set baseline rules (e.g. BitLocker required, Secure
   Boot, minimum OS version matching R4, firewall on, Defender healthy).

   > **GCC High caveat:** Do **not** rely on a compliance rule that requires **Device Health
   > Attestation** results — DHA is **not available in GCC High**. Use settings that evaluate
   > **locally** (BitLocker, Secure Boot, OS build, Defender status).

3. **Assignments:** assign to **`WAPG-Pilot`**. **Create.**

### Step 8 — (Optional) Windows Hello for Business policy

1. **`https://intune.microsoft.us`** → **Devices → Enrollment → Windows → Windows Hello for
   Business**, or a device-configuration WHfB profile targeted to `WAPG-Pilot`.
2. Configure PIN/biometric per your standard.

   > **GCC High caveat:** WHfB provisioning works, but the **Microsoft hosted PIN reset
   > service is not available in Azure Government**. Plan PIN recovery via allowed sign-in URLs
   > (Intune/CSP/GPO) rather than the hosted PIN-reset service. *(Verify for GCC High for your
   > exact Windows build.)*

### Step 9 — Add the applications/scripts to deploy during OOBE

1. **`https://intune.microsoft.us`** → **Apps → Windows → Add** — add your Win32 /
   line-of-business apps and **assign** them to **`WAPG-Autopilot-Devices`**.
2. **Devices → Scripts and remediations** (or **Devices → Windows → PowerShell scripts**) —
   add any provisioning PowerShell scripts and assign to **`WAPG-Autopilot-Devices`**.

   > **GCC High caveat:** Do **not** plan **Microsoft Store for Business** app provisioning
   > (not available in GCC High) and do **not** rely on **Delivery Optimization for Win32
   > apps** peer caching (not available). Apps download from the cloud per device.

Only the apps/scripts you **also select inside the device preparation profile** (next step)
run during OOBE; anything else assigned to the group installs **after** provisioning completes.

### Step 10 — Create the Autopilot **device preparation** profile

> **This replaces classic Autopilot deployment profiles**, which do not exist in GCC High.

1. **`https://intune.microsoft.us`** → **Devices → Windows → Enrollment** → tile **Windows
   Autopilot device preparation → Device preparation policies → Create**.

   (If you do not see this tile, re-confirm R1 — you may be on a Commercial/GCC tenant.)

2. **Basics:** Name = **`WAPG-DevicePrep-UserDriven-EntraJoin`**. **Next.**
3. **Configuration settings:**
   - **Deployment settings → Deployment mode:** **User-driven**

     > **GCC High caveat:** Choose **User-driven**. **Self-deploying** and **pre-provisioning**
     > (white-glove) modes are **not yet supported in GCC High** (planned).

   - **Join type:** **Microsoft Entra join** (the only supported type — **Hybrid Entra join is
     not available** in device preparation).
   - **Device group:** select **`WAPG-Autopilot-Devices`** (the assigned group owned by the
     Intune Provisioning Client from Step 2).
   - **Deployment settings → Allowed apps / scripts:** select the specific apps and PowerShell
     scripts (from Step 9) to run **during OOBE**. Keep the list short.
   - Leave **device rename during OOBE** unset.

     > **GCC High caveat:** Renaming the device during OOBE based on org structure is **not yet
     > supported in GCC High** (planned). Rename post-provisioning if needed.

4. **Assignments:** assign the profile to **`WAPG-Provisioning-Users`** (device preparation
   profiles target the **users** who provision, not a device group). **Next → Create.**

### Step 11 — (Optional) Corporate identifiers, only if blocking personal devices

If you use **enrollment restrictions** to block personal Windows enrollment, pre-upload
trusted devices so they can still provision:

1. **`https://intune.microsoft.us`** → **Devices → Enrollment → Corporate device identifiers →
   Add** → upload manufacturer/model/serial for the trusted devices.

> **GCC High caveat:** This is **not** the classic Autopilot hardware-hash import (which does
> not exist here). Corporate identifiers are only needed when enrollment restrictions would
> otherwise block the device.

---

## Phase B — Pilot (provision real devices)

1. Confirm a pilot user is in **`WAPG-Provisioning-Users`** and **`WAPG-Pilot`**, is
   Gov-licensed (R2), and may join devices (R7).
2. On a supported Windows 11 device (R4), **factory-fresh or reset**, begin OOBE:
   - Connect to a network that reaches the sovereign endpoints (R9).
   - At sign-in, enter the pilot user's **GCC High** account and authenticate at
     `https://login.microsoftonline.us`.
3. The device Entra-joins, MDM-enrolls, is added to `WAPG-Autopilot-Devices` **at enrollment
   time**, shows the **`WAPG-ESP-Provisioning`** progress percentage, installs the selected
   apps/scripts, applies `WAPG-Compliance-Win11` and `WAPG-UpdateRing-Pilot`, and lands on the
   desktop.

> **GCC High caveat:** If OOBE finishes but the group is empty and nothing installed, the
> Intune Provisioning Client owner (Step 2) is almost certainly missing or wrong — see
> `06-troubleshooting.md`, symptom #1.

Proceed to `05-testing.md` for the **Validate** gate, then `WAPG-Set-ScopeTargeting.ps1`
(default `-WhatIf`) to **Expand**.

## Sources

- Microsoft, *Overview / requirements of Windows Autopilot device preparation* (Entra-join
  only, user-driven only in GCC High, assigned device group, Intune Provisioning Client owner,
  RBAC permission set, OOBE app limit, corporate identifiers).
- Microsoft, *Intune Government Service overview* (features not available/planned in GCC High:
  classic Autopilot, Autopatch/update policies, DFCI, DHA, Store for Business,
  self-deploying/pre-provisioning, OOBE rename).
- Microsoft, *Network endpoints for US government deployments* (portals, `*.us` endpoints).
