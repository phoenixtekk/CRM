# 2. Requirements Guide — Endpoint Privilege Management (EPM)

Verify **every** requirement below before you configure anything. Each entry follows the same
pattern: **Description · Why required · How to verify · How to implement if missing.** Do not
assume any prerequisite already exists.

> Category-wide prerequisites (a tenant, an Intune subscription, MDM enrollment, etc.) are
> documented once in **`global-requirements-intune-solutions.md`**. This guide lists only what
> is specific to or especially important for EPM.

---

## 2.1 EPM licensing (Intune Suite or EPM add-on) — the gating requirement
**Description:** Endpoint Privilege Management is a **paid add-on**. Each targeted user needs either
the **Microsoft Intune Suite** license or the **standalone Endpoint Privilege Management add-on**.
**Why required:** Without the license the EPM policy node is unavailable and policies will not apply
— this is the single most common blocker.
**How to verify:** Microsoft 365 admin center → **Billing → Licenses**; confirm **Intune Suite** or
**Endpoint Privilege Management** appears and is assigned to your pilot users. In Intune, confirm
**Endpoint security → Endpoint Privilege Management** is present and not gated behind a trial/upsell.
**How to implement if missing:** Purchase the **Intune Suite** or the **EPM** add-on in
**M365 admin center → Billing → Purchase services**, then assign the license to every targeted user
(or a licensing group). Allow time for the assignment to propagate before deploying.

## 2.2 EPM client (elevation extension) reachability
**Description:** The EPM client-side extension must be able to install and call its cloud service.
**Why required:** The extension is what intercepts and evaluates elevation requests on the device;
the base policy triggers its installation.
**How to verify:** After assigning the base policy, on a device check
`C:\Program Files\Microsoft EPM Agent\` exists and the **Microsoft EPM Agent Service** (service name
`EpmService`/**EPMAgent**) is running (`Get-Service` / `EPM-Discovery.ps1`).
**How to implement if missing:** Ensure the base policy is assigned and the device has synced; confirm
network access to EPM/Intune endpoints (see 2.5). The extension auto-installs once policy applies.

## 2.3 Supported Windows operating system
**Description:** Windows 10 (supported builds) or **Windows 11**, Enterprise/Pro, x64 or Arm64.
**Why required:** EPM and its client extension require modern, supported Windows builds.
**How to verify:** `winver` on the device, or Intune → device → **Hardware**. Confirm a currently
serviced Windows 10/11 build with current cumulative updates.
**How to implement if missing:** Patch via Windows Update / Update rings, or upgrade to Windows 11.

## 2.4 Device management and identity
**Description:** Devices are **Intune-managed** and **Microsoft Entra joined** (or hybrid joined).
**Why required:** EPM policies are delivered through Intune to enrolled devices and scoped to Entra
users/devices.
**How to verify:** Intune → **Devices → All devices** (device listed, compliant); on the device
`dsregcmd /status` shows `AzureAdJoined : YES`.
**How to implement if missing:** Enroll the device in Intune and join it to Entra ID (OOBE,
Autopilot, or **Settings → Accounts → Access work or school**).

## 2.5 Network access to EPM/Intune service endpoints
**Description:** Outbound HTTPS to Microsoft Intune and EPM service endpoints.
**Why required:** The client downloads policy/rules and uploads elevation reports; support-approved
requests round-trip to the service.
**How to verify:** From a device, reach `https://login.microsoftonline.com` and the Intune service;
confirm reporting appears in **Endpoint security → Endpoint Privilege Management → Reports**.
**How to implement if missing:** Allow Microsoft's published Intune/EPM URLs through proxy/firewall.

## 2.6 Application inventory for elevation rules
**Description:** Know which applications/tasks your users legitimately need to run elevated, and
their **publisher certificate** or **file hash**.
**Why required:** Each elevation rule identifies an app by file name plus certificate or hash; you
cannot author accurate rules without this.
**How to verify:** Use EPM **reporting in audit/observation** during the pilot, and/or run
**`New-EpmElevationRule.ps1`** against a target executable to read its signer and SHA-256 hash.
**How to implement if missing:** Run a pilot with reporting first to discover real elevations, then
codify them. Prefer **certificate**-based rules (survive app updates) over **hash** where signed.

## 2.7 Local administrator strategy (the end goal)
**Description:** A plan to remove standing local-admin rights from everyday users once rules cover
real usage.
**Why required:** EPM's value is realized only when users are standard users; leaving everyone a
local admin makes EPM cosmetic.
**How to verify:** On a device, `net localgroup administrators` lists who is currently a local admin.
**How to implement if missing:** Plan a phased removal (communications + a support-approved safety
valve). Removing users from the local Administrators group is managed separately (e.g. an Intune
**Account protection / Local users and groups** policy) — coordinate it with your EPM rollout.

## 2.8 Administrative roles
**Description:** The operator needs rights to create Endpoint security policies and approve
support-approved elevations.
**Why required:** Authoring EPM policies and approving elevations are privileged actions.
**How to verify:** Entra → **Roles and administrators**; confirm **Intune Administrator** (or
**Endpoint Security Manager**) for the operator.
**How to implement if missing:** Assign **Intune Administrator**/**Endpoint Security Manager**;
reserve Global Administrator for tenant-wide setup.

---

## Requirements checklist (use before configuring)
- [ ] **Intune Suite or EPM add-on license** assigned to pilot users
- [ ] Devices Intune-enrolled and Microsoft Entra joined — `dsregcmd /status`
- [ ] Supported, patched Windows 10/11 (Enterprise/Pro)
- [ ] Network/proxy allows Microsoft Intune + EPM endpoints
- [ ] EPM client extension installs and **EPMAgent** service runs — `EPM-Discovery.ps1`
- [ ] Application inventory for elevation rules (cert/hash) gathered — `New-EpmElevationRule.ps1`
- [ ] Plan to remove standing local-admin rights after rules are proven
- [ ] Pilot Entra security group created
