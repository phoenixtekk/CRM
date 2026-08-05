# 2. Requirements — Microsoft Intune First-Time Setup for Windows

Confirm each requirement below **before** you start. For every item: what it is, why it is required,
how to verify it, and how to put it in place if it is missing. Do not assume anything already exists.

---

## 1. Intune is enabled for the tenant
- **Description:** Intune is switched on and is the MDM authority for the tenant.
- **Why required:** There is nothing to enroll a Windows device into until Intune is active. This
  solution is the step *after* enablement.
- **How to verify:** Sign in at `https://intune.microsoft.com`; **Tenant administration → Tenant status**
  shows the tenant active. **Devices → Enrollment** is reachable.
- **How to implement if missing:** Complete the **Enable Microsoft Intune (Quick-Start)** first — it
  turns Intune on for a new or existing tenant. This guide does not reproduce that first-mile detail.

## 2. Global Administrator (or Intune Administrator) access
- **Description:** A role with permission to configure enrollment, Autopilot, and groups.
- **Why required:** Setting the auto-enrollment scope, creating Autopilot profiles/ESP, and making a
  service principal a group owner are tenant-level actions.
- **How to verify:** In **Entra admin center → Roles & admins**, confirm your account holds **Global
  Administrator** or **Intune Administrator**. (Making the Intune Provisioning Client an *owner* of a
  group needs sufficient Entra rights — Global Administrator, or a role that can edit group owners.)
- **How to implement if missing:** Have an existing Global Administrator assign the role.

## 3. Intune license assigned to the enrolling user
- **Description:** An Intune entitlement, standalone or bundled in **Enterprise Mobility + Security (EMS)**
  or a **Microsoft 365** plan (Business Premium, E3/E5).
- **Why required:** A user cannot enroll a device unless they are licensed for Intune. This is the single
  most common reason enrollment fails.
- **How to verify:** In **Entra admin center → Billing → Licenses**, confirm you own Intune-bearing
  licenses with free seats, then confirm the pilot user is assigned one under the user's **Licenses**
  blade.
- **How to implement if missing:** Purchase/trial an Intune-bearing plan and assign a license to each
  pilot user (directly or via the `INTBASE - Windows Users - Pilot` group). A **30-day trial** is
  sufficient — *verify current trial availability in your tenant*.

## 4. A pilot user (cloud identity)
- **Description:** A cloud user who will perform user-driven enrollment and sign in on the Autopilot
  device.
- **Why required:** Enrollment binds a device to a signed-in, licensed user.
- **How to verify:** In **Entra admin center → Users**, confirm a non-admin cloud user exists, is
  licensed (item 3), and can sign in.
- **How to implement if missing:** Create one under **Users → New user**, name it clearly (e.g.
  `Windows Pilot User 01`), assign an Intune license, and set a password for the test devices.

## 5. Pilot Entra security groups
- **Description:** Two Microsoft Entra security groups: a **user** group and an Autopilot **device** group.
- **Why required:** Auto-enrollment scope and compliance target the **user** group
  (`INTBASE - Windows Users - Pilot`); the Autopilot profile and ESP target the **device** group
  (`INTBASE - Autopilot Devices`).
- **How to verify:** In **Entra admin center → Groups**, confirm both groups exist with the exact names.
- **How to implement if missing:** Create them in the implementation steps. The user group is **Assigned**
  with the pilot user as a member; the device group is **Assigned** (see item 6).

## 6. Intune Provisioning Client is an OWNER of the Autopilot device group
- **Description:** The first-party service principal **Intune Provisioning Client** (AppId
  `f1346770-5b25-470b-88bd-d5744ab7952c`, often displayed as *Intune Autopilot ConfidentialClient*) must
  be an **Owner** of the **Assigned** device group `INTBASE - Autopilot Devices`.
- **Why required:** Enrollment-time device grouping works by this principal *owning* the assigned group.
  Without the owner, the group stays empty at enrollment and the Autopilot profile/ESP never deploy.
- **How to verify:** **Entra → Groups → `INTBASE - Autopilot Devices` → Owners** lists a principal whose
  AppId is `f1346770-5b25-470b-88bd-d5744ab7952c`. Search by **AppId**, not the display name (which
  varies by tenant).
- **How to implement if missing:** Add it as an owner (implementation Step 6). If the service principal
  does not exist yet, provision it by **opening the Intune admin center once as a Global Administrator**,
  then retry. *(Tenant-verifiable: the display name varies; match on the AppId.)*

## 7. Supported Windows test devices
- **Description:** For user-driven — a Windows 10 (1809+) or Windows 11 PC that can be Entra-joined. For
  Autopilot — a **new or factory-reset** PC of the same editions.
- **Why required:** To prove both enrollment paths. Autopilot needs a device at the OOBE screen.
- **How to verify:** Confirm the edition is **Pro, Enterprise, or Education** (`winver`) — **not Home** —
  and the device can reach the internet.
- **How to implement if missing:** Use spare PCs or cloud VMs. For Autopilot, plan to reset the device so
  it starts at OOBE.

## 8. Autopilot hardware hash for the Autopilot device
- **Description:** The device's Autopilot hardware identity (4K hardware hash) registered in Intune.
- **Why required:** Autopilot only applies a profile to a **registered** device.
- **How to verify:** **Intune → Devices → Enrollment → Devices** (Windows Autopilot devices) lists the
  device serial after import.
- **How to implement if missing:** Collect it with the included `INTBASE-Get-AutopilotHash.ps1` (or
  Microsoft's `Get-WindowsAutopilotInfo`) and import the CSV, **or** have your OEM/reseller register the
  device to your tenant at purchase.

## 9. Network access from devices
- **Description:** Devices must reach Microsoft Intune, Entra, and Windows notification endpoints.
- **Why required:** Enrollment, OOBE provisioning, and check-in are cloud calls.
- **How to verify:** From a device, reach `https://login.microsoftonline.com` and
  `https://enrollment.manage.microsoft.com` (Commercial). On restricted networks, allow the documented
  Microsoft Intune/Autopilot endpoints — *verify against current Microsoft endpoint documentation*.
- **How to implement if missing:** Allow the documented Microsoft 365/Intune URL & IP ranges through the
  proxy/firewall.

---

### Government (GCC / GCC High / DoD) variance
For US Government tenants the portals and endpoints differ — Intune `https://intune.microsoft.us`, Entra
`https://entra.microsoft.us`, sign-in `login.microsoftonline.us`, Graph `https://graph.microsoft.us`
(`Connect-MgGraph -Environment USGov`). The Intune Provisioning Client AppId is the **same**. Autopilot
and enrollment **feature timing can differ in GCC High/DoD**; where uncertain, follow the Commercial path
and **verify for GCC High** against Microsoft's US sovereign-cloud documentation.
