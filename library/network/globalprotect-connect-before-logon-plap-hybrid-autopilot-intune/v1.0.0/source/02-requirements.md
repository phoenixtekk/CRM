# Requirements — GlobalProtect Connect Before Logon (PLAP) for Hybrid Azure AD Join Autopilot via Microsoft Intune

Confirm **every** requirement below before you build. Each entry follows the same shape:
**Description / Why required / How to verify / How to implement if missing.** The category-level
prerequisites (Entra tenant, Intune, admin roles, pilot group, change control) are in
`global-requirements-network.md`; the items here are specific to deploying **GlobalProtect Connect
Before Logon (PLAP)** during a **Hybrid Azure AD Join Windows Autopilot** provisioning.

> **Vendor boundary:** the **GlobalProtect portal / gateway configuration and the GlobalProtect app
> internals are deferred to Palo Alto Networks' official documentation.** Below, "obtain from Palo Alto"
> means *get the artifact/value from your Palo Alto admin or Palo Alto docs* — this guide does not
> fabricate GlobalProtect portal menu paths.

> **Government note (GCC High / DoD):** the steps below name the commercial portals
> (`https://intune.microsoft.com`, `https://entra.microsoft.com`, `https://login.microsoftonline.com`).
> In a US-Gov (GCC High / DoD) tenant use the sovereign portals instead —
> `https://intune.microsoft.us` / `https://endpoint.microsoft.us`, `https://entra.microsoft.us`, and
> `https://login.microsoftonline.us` — and **verify each step for GCC High**, as feature availability
> and rollout can differ. This guide does not invent GCC-specific menus.

---

## R1. Windows 11 scope confirmed
**Description:** The target devices are **Windows 11** devices provisioned by Windows Autopilot; Connect
Before Logon is a Windows-only feature and production here is Windows 11.
**Why required:** Connect Before Logon is implemented as a Windows credential provider (PLAP). Early
testing on Windows 10 can behave differently from Windows 11 (see Troubleshooting), so the pilot and the
log-capture runbook must run on **Windows 11**.
**How to verify:** Your in-scope device list is Windows 11; the pilot test device is Windows 11.
**How to implement if missing:** Scope the pilot and production device groups to Windows 11. If a Windows
10 estate remains, re-test the whole build separately on Windows 10 rather than assuming parity.

## R2. Microsoft Intune licensing and Autopilot-enrolled devices
**Description:** An Intune-bearing license plan (e.g. Microsoft 365 E3/E5, EMS, or Intune standalone) and
the target Windows 11 devices registered for Windows Autopilot.
**Why required:** Intune is the delivery plane for the Win32 app, the Enrollment Status Page, and any
certificate profile. Nothing deploys to a device that is not enrolled and licensed.
**How to verify:** In the **Microsoft Intune admin center** (`https://intune.microsoft.com`), go to
**Devices > Enrollment > Windows > Windows Autopilot devices** and confirm the target devices are
registered; under **Tenant administration > Licenses**, confirm Intune licenses are assigned.
**How to implement if missing:** Assign an Intune-bearing license; register the devices for Autopilot
(hardware hash import or OEM/CSP registration).

## R3. Windows Autopilot Hybrid Azure AD Join deployment profile
**Description:** A **Windows Autopilot deployment profile** configured for **Hybrid Azure AD Join**
(user-driven), assigned to the Autopilot device group.
**Why required:** This solution exists to make hybrid-join Autopilot work over a user-initiated VPN.
Without the hybrid-join Autopilot profile there is no provisioning sequence for Connect Before Logon to
support.
**How to verify:** Intune → **Devices > Enrollment > Windows > Deployment Profiles**; a profile exists
with **Join type = Hybrid Azure AD joined**, assigned to the Autopilot device group.
**How to implement if missing:** Create the deployment profile (Intune → **Devices > Enrollment >
Windows > Deployment Profiles > Create profile > Windows PC**), set **Join to Azure AD as = Hybrid Azure
AD joined**, and assign it to the Autopilot device group.

## R4. Domain Join configuration profile and on-prem Domain Join (ODJ) connector
**Description:** An Intune **Domain Join** device-configuration profile (target domain, OU) and a healthy
**Intune Connector for Active Directory** (the on-prem Domain Join / ODJ connector).
**Why required:** Hybrid Azure AD Join Autopilot completes the on-prem domain join through the ODJ
connector; the device must reach a domain controller to finish join and first logon — the reachability
that Connect Before Logon provides at the sign-in screen.
**How to verify:** Intune → **Devices > Configuration**; a **Domain Join** profile exists and is assigned.
Intune → **Devices > Enrollment > Windows > Intune Connector for Active Directory**; the connector shows
**Active**.
**How to implement if missing:** Install/repair the Intune Connector for Active Directory on a domain-joined
server, create the **Domain Join** profile (domain, OU), and assign it to the Autopilot device group.

## R5. Enrollment Status Page (ESP) configured
**Description:** A Windows **Enrollment Status Page** profile assigned to the Autopilot devices, into
which the GlobalProtect PLAP app will be added as a **blocking app**.
**Why required:** The ESP is what makes provisioning **wait** for Connect Before Logon to install and
register before the user reaches the desktop, and it is what owns the reboot the app requests with exit
code `3010`.
**How to verify:** Intune → **Devices > Enrollment > Windows > Enrollment Status Page**; a profile (other
than the disabled default, if you use a targeted one) is enabled and assigned.
**How to implement if missing:** Create/enable an ESP profile (Intune → **Devices > Enrollment > Windows
> Enrollment Status Page > Create**), set **Show app and profile installation progress = Yes**, and
assign it. You will reference it as `ESP – Autopilot – GlobalProtect PLAP Blocking` in Implementation.

## R6. GlobalProtect app installer (5.2 or later) — the MSI
**Description:** The official **GlobalProtect** Windows **MSI** installer, version **5.2 or later** (the
first release with Connect Before Logon).
**Why required:** Connect Before Logon (the PLAP credential provider) exists only in GlobalProtect 5.2+.
The MSI is the exact binary the Win32 app installs.
**How to verify:** Obtain the MSI from your Palo Alto admin / Palo Alto support portal and confirm the
version is **≥ 5.2** for the release your portal supports.
**How to implement if missing:** Obtain the correct entitled GlobalProtect MSI (5.2+) from Palo Alto. Do
not repackage or re-sign the vendor binary; use the vendor-provided MSI.

## R7. GlobalProtect portal FQDN and authentication method
**Description:** The **portal FQDN** (e.g. `portal.your-company.com`) that Connect Before Logon points at,
and the **authentication method** the portal enforces (basic credentials, certificate, or SAML).
**Why required:** The portal FQDN is written into the `PanSetup` registry (`Portal`) and the auth method
determines whether an optional device certificate (R8) is needed. These are inputs, not things this guide
configures on the Palo Alto side.
**How to verify:** Obtain from your Palo Alto admin: the **portal FQDN** and the **pre-logon auth method**.
Confirm a manual GlobalProtect connect to that portal already succeeds with the intended method.
**How to implement if missing:** Configure the GlobalProtect **portal/gateway** and its authentication
**per Palo Alto Networks' official documentation** — Palo Alto-side work outside this solution's scope.
Record the portal FQDN and auth method for Implementation.

## R8. Certificate infrastructure (only if the portal uses certificate authentication)
**Description:** A working PKI path for Intune to deliver a **device** certificate — an on-prem
**NDES/SCEP** connector, **Intune Cloud PKI**, or a supported third-party CA connector — plus the trusted
root/intermediate CA.
**Why required:** If the portal authenticates Connect Before Logon with a certificate, each device needs a
machine certificate the portal trusts, delivered by Intune, present before the sign-in screen. (Skip R8
if the portal uses basic credentials or SAML at the Connect Before Logon window.)
**How to verify:** Intune → **Devices > Configuration**; a SCEP certificate profile named
`GlobalProtect – PLAP – Device Cert (SCEP) – Windows` can be created and deploys to a test device, and the
issued cert chains to a CA the GlobalProtect portal trusts.
**How to implement if missing:** Stand up the SCEP path (NDES + Intune Certificate Connector, or enable
Intune Cloud PKI), publish the trusted root/intermediate, then create the SCEP profile. Ensure the
**issuing CA is trusted by the GlobalProtect portal/gateway** (Palo Alto-side trust config is deferred to
Palo Alto docs).

## R9. Autopilot device group — Assigned, owned by the Intune Provisioning Client service principal
**Description:** A pilot Autopilot **device** group `PILOT – GlobalProtect PLAP – Autopilot Devices` and a
production device group `PROD – GlobalProtect PLAP – Autopilot Devices`, each an **Assigned** (not Dynamic)
security group whose **Owner** includes the **Intune Provisioning Client** service principal
(**AppId `f1346770-5b25-470b-88bd-d5744ab7952c`**).
**Why required:** For a device to receive the app **at enrollment**, it must be in the target group at
enrollment time. Enrollment-time device grouping works only when the group is **Assigned** and the Intune
Provisioning Client SP **owns** the group; without that owner the assigned group stays empty at
enrollment and the app never deploys.
**How to verify:** Entra → **Groups > All groups**; `PILOT – GlobalProtect PLAP – Autopilot Devices`
exists, is **Assigned**, and under **Owners** lists the service principal with
AppId `f1346770-5b25-470b-88bd-d5744ab7952c` (search by **AppId** — the display name, often *Intune
Autopilot ConfidentialClient*, varies by tenant).
**How to implement if missing:** Entra → **Groups > New group > Security** (membership type **Assigned**);
name it exactly `PILOT – GlobalProtect PLAP – Autopilot Devices`; add the Autopilot devices; then
**Owners > Add owners** and add the SP by **AppId** `f1346770-5b25-470b-88bd-d5744ab7952c`. If the SP is
absent, provision it by opening the Intune portal once as Global Administrator. The included
`GPPLAP-Set-ScopeTargeting.ps1` creates the group, adds devices, and sets the SP owner for you.

## R10. Reboot-sequencing and return-code design confirmed
**Description:** A confirmed design that the install script **never** calls a forced `Restart-Computer`
during the ESP, **returns exit code `3010`** for reboot, uses `Start-Process … -Wait` for the MSI, and
maps the Win32 return codes (`0`/`1707` success, `3010` soft reboot, `1618` retry).
**Why required:** A scripted reboot mid-ESP interrupts the Intune Management Extension and causes install
failures/lost state — the failure mode this solution is built to remove. Returning `3010` lets Intune/ESP
own the reboot; `-Wait` stops the app reporting complete before the installer finishes.
**How to verify:** Your install script has no `Restart-Computer`; it returns `3010` after registration;
the MSI is launched with `-Wait`; the app's return-code mapping is set (Implementation §2).
**How to implement if missing:** Adopt the single-app pattern in Implementation §2 (it already encodes
this). Never reboot from the script; always return `3010` and map the codes on the app.

## R11. Antivirus exclusion for the IME content/cache path (to avoid the "unzip" 0x87D30067 failure)
**Description:** During provisioning, the Intune Management Extension content/cache path is **excluded**
from real-time antivirus scanning (Microsoft Defender or third-party), and the device has adequate free
disk space.
**Why required:** The intermittent **"unzipping"** failure is Intune error **`0x87D30067`** — the IME
failed to unzip the `.intunewin` into its content/cache path, most often because AV locked or scanned the
IMECache during extraction (or the disk was low, or the package was badly re-wrapped).
**How to verify:** Your provisioning AV policy excludes
`C:\Program Files (x86)\Microsoft Intune Management Extension\Content` (and the IMECache), and the target
devices have sufficient free disk.
**How to implement if missing:** Add the IME content/IMECache path to the AV exclusion list applied during
provisioning; ensure free disk space; and always re-wrap the `.intunewin` cleanly with the current Content
Prep Tool (R12) rather than nesting an already-wrapped payload.

## R12. Microsoft Win32 Content Prep Tool (current version)
**Description:** The **Microsoft Win32 Content Prep Tool** (`IntuneWinAppUtil.exe`), current release, on
the packaging workstation, used to wrap the GlobalProtect MSI + the install/registration script into an
`.intunewin`.
**Why required:** A single Win32 app that installs the MSI, writes the registry, waits for the service, and
registers PLAP is best delivered as an `.intunewin`. A stale tool or a nested/already-wrapped payload is a
known cause of the `0x87D30067` unzip failure.
**How to verify:** `IntuneWinAppUtil.exe` runs and reports its version; you wrap a **clean** source folder
(the MSI + the script), not an already-wrapped file.
**How to implement if missing:** Download the current Win32 Content Prep Tool from Microsoft's official
`microsoft-Win32-Content-Prep-Tool` release and place it on the packaging workstation.

## R13. Administrative roles for building the deployment
**Description:** Intune admin rights to create Win32 apps, the ESP, and certificate profiles; Entra rights
to create/populate groups and set group owners (Groups Administrator or better).
**Why required:** Packaging the app, editing the ESP, creating cert profiles, and setting the service-principal
group owner all require elevated roles.
**How to verify:** In Intune you can reach **Apps > Add** and **Devices > Enrollment**; in Entra you can
create groups and add owners.
**How to implement if missing:** Have a Global Administrator assign **Intune Administrator** and **Groups
Administrator** (least-privilege) to the operator; setting the first-party SP as a group owner may require
a Global Administrator the first time.

## R14. Microsoft Graph PowerShell SDK (to run the included scripts)
**Description:** The **Microsoft.Graph** PowerShell SDK installed on the operator workstation, used by the
discovery/report/scope-targeting scripts (the on-device validation and log-capture scripts run locally and
need no Graph).
**Why required:** The scripts call Microsoft Graph (Intune/Entra) to inventory the app, the ESP, the cert
profile, the device groups, group membership, and the group owner.
**How to verify:** In PowerShell, `Get-Module Microsoft.Graph -ListAvailable` returns a version.
**How to implement if missing:** Run `Install-Module Microsoft.Graph -Scope CurrentUser`. The scripts call
`Connect-MgGraph` with the specific delegated scopes each one documents in its header.

## R15. Change control and rollback (category requirement, restated)
**Description:** An approved change window and a written rollback (exclude the group / remove the app from
the ESP blocking list / uninstall the app / unregister PLAP).
**Why required:** Adding a blocking app to the Autopilot ESP and a credential provider to the sign-in
screen changes the provisioning and logon experience for real users; changes must be reversible.
**How to verify:** A rollback procedure exists and is approved; you know how to exclude
`PILOT – GlobalProtect PLAP – Autopilot Devices`, remove the app from the ESP blocking list, and flip the
Win32 app to **Uninstall** (which can also run `PanGPS.exe -unregisterplap`).
**How to implement if missing:** Document the rollback (assignment exclusion, remove from ESP blocking
apps, app **Uninstall** intent incl. `-unregisterplap`, cert removal) and the comms plan before you
assign anything.

---

When all requirements pass, proceed to `03-implementation.md`.
