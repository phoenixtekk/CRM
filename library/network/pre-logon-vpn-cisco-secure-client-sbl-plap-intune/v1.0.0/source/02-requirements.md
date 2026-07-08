# Requirements — Pre-Logon VPN Connectivity with Cisco Secure Client Start Before Logon (SBL/PLAP) via Microsoft Intune

Confirm **every** requirement below before you build. Each entry follows the same shape:
**Description / Why required / How to verify / How to implement if missing.** The category-level
prerequisites (Entra tenant, Intune, admin roles, pilot group, change control) are in
`global-requirements-network.md`; the items here are specific to deploying Cisco Secure Client with
**Start Before Logon (SBL/PLAP)** and the device certificate that makes silent pre-logon possible.

> **Vendor boundary:** the **Cisco Secure Client console, the VPN Profile Editor / XML internals, and
> the VPN head-end (ASA / Firepower FTD / ISE) configuration are deferred to Cisco's official
> documentation.** Below, "obtain from Cisco" means *get the artifact/value from your Cisco admin or
> Cisco docs* — this guide does not fabricate Cisco menu paths.

> **Government note (GCC High / DoD):** the steps below name the commercial portals
> (`https://intune.microsoft.com`, `https://entra.microsoft.com`, `https://login.microsoftonline.com`).
> In a US-Gov (GCC High / DoD) tenant use the sovereign portals instead —
> `https://intune.microsoft.us`, `https://entra.microsoft.us`, and
> `https://login.microsoftonline.us` — and **verify each step for GCC High**, as feature availability
> and rollout can differ. This guide does not invent GCC-specific menus.

---

## R1. Windows-only scope confirmed
**Description:** The target devices for pre-logon VPN are **Windows** (Windows 10/11) devices; Start
Before Logon is a Windows-only feature.
**Why required:** SBL is implemented as a Windows credential provider (PLAP). macOS/iOS/Android have no
equivalent and cannot receive this build.
**How to verify:** Your in-scope device list is Windows only.
**How to implement if missing:** Scope the pilot and production groups to Windows devices/users. If you
also need after-logon VPN on macOS/iOS/Android, deploy that with the separate multi-platform Secure
Client VPN solution — it is out of scope here.

## R2. Microsoft Intune licensing and enrolled Windows devices
**Description:** An Intune-bearing license plan (e.g. Microsoft 365 E3/E5, EMS, or Intune standalone)
and the target Windows devices already enrolled and shown in Intune.
**Why required:** Intune is the delivery plane for the app, the VPN profile, and the certificate
profiles. Nothing deploys to a device that is not enrolled and licensed.
**How to verify:** In the **Microsoft Intune admin center** (`https://intune.microsoft.com`), go to
**Devices > All devices** and confirm the target Windows devices are present and *Compliant/Managed*.
Under **Tenant administration > Licenses**, confirm Intune licenses are assigned to the pilot users.
**How to implement if missing:** Assign an Intune-bearing license to the pilot users (Microsoft 365
admin center → **Users** → assign licenses). Enroll Windows devices via Autopilot / Company Portal.

## R3. Entra ID security groups (pilot and production)
**Description:** A pilot group `PILOT – Pre-Logon VPN (SBL) Users` and a production target group
`PROD – Pre-Logon VPN (SBL) Users`, containing the users to receive the pre-logon build.
**Why required:** Intune assignments target Entra groups. The pilot-first model requires a small, named
pilot group distinct from the eventual production audience.
**How to verify:** In the **Microsoft Entra admin center** (`https://entra.microsoft.com`), go to
**Groups > All groups** and confirm `PILOT – Pre-Logon VPN (SBL) Users` exists with the intended members.
**How to implement if missing:** Entra → **Groups > New group > Security**; name it exactly
`PILOT – Pre-Logon VPN (SBL) Users`; add 3–10 representative pilot members. The included
`SBLVPN-Set-ScopeTargeting.ps1` script creates and populates these groups for you.

## R4. A Cisco VPN head-end (ASA / Firepower FTD) — with ISE where used
**Description:** A reachable Cisco VPN termination point (ASA or Firepower Threat Defense) with a
configured **tunnel group / connection profile** that accepts a **certificate**-authenticated
connection, plus **Cisco ISE** if you use posture or identity-based authorization.
**Why required:** The pre-logon client needs something to connect *to*, and the head-end must accept the
device certificate at the logon screen (no user context). The gateway FQDN, tunnel-group name, and
accepted auth method are inputs to the Intune VPN profile and the SBL-enabled XML.
**How to verify:** Obtain from your Cisco/network team: the **gateway FQDN** (e.g.
`vpn.your-company.com`), the **tunnel-group / connection-profile name**, and confirmation that the
tunnel-group accepts **certificate** auth for machine/pre-logon connections.
**How to implement if missing:** Stand up / configure the ASA or FTD head-end (and optionally ISE) with
a certificate-accepting tunnel-group **per Cisco's official documentation** — Cisco-side work outside
this solution's scope. Record the FQDN, connection-profile name, and auth method for R7/Implementation.

## R5. Cisco Secure Client installers — Core VPN **and** Start Before Logon modules
**Description:** The official Cisco Secure Client Windows installers, including **both** the **Core VPN**
module and the **Start Before Logon** module (the SBL module that registers the PLAP credential
provider, `vpnplap64.dll`).
**Why required:** SBL is a separate module layered on Core VPN. Without the Start Before Logon module
the PLAP DLL is never installed and the logon-screen "Network sign-in" option cannot appear.
**How to verify:** Download the installers from your **Cisco Software Download** entitlement and confirm
the package set includes the **Start Before Logon** module for the version your head-end supports.
**How to implement if missing:** Obtain the correct entitled version (Core VPN + Start Before Logon
modules) from Cisco. Do not repackage or re-sign Cisco binaries; use the vendor-provided modules.

## R6. Cisco VPN client profile (XML) with SBL enabled
**Description:** The Cisco **VPN client profile** (an XML file authored in Cisco's **VPN Profile
Editor** or delivered from the head-end) that contains
**`<UseStartBeforeLogon>true</UseStartBeforeLogon>`** and references the correct gateway.
**Why required:** The Start Before Logon module only activates the PLAP credential provider when the
deployed profile sets `UseStartBeforeLogon` to `true`. This XML is bundled into the Win32 package and
dropped into the Secure Client profile directory on install.
**How to verify:** Open the `.xml` and confirm it contains
`<UseStartBeforeLogon>true</UseStartBeforeLogon>` (inside the preferences block) and the correct
gateway FQDN from R4.
**How to implement if missing:** Have your Cisco admin author/export the VPN client profile with Start
Before Logon enabled **per Cisco's VPN Profile Editor documentation** (deferred to Cisco). Store the XML
with your Win32 packaging inputs.

## R7. VPN connection parameters recorded
**Description:** A recorded set of connection values: **gateway FQDN**, **tunnel-group / connection
profile**, **authentication method** (device certificate for silent pre-logon), tunnel mode
(**split** vs **full**), and any **trusted-network / connect-on-logon** behavior.
**Why required:** These are the exact fields that go into the SBL-enabled XML and the Intune VPN
profile. Consistency here is what makes every device identical.
**How to verify:** You have a single sheet listing each value; a manual client connect using those
values succeeds against the head-end with certificate auth.
**How to implement if missing:** Collect the values from R4/R6 and your security requirements. Decide
split vs full tunnel with the network/security owner before building the profile.

## R8. Device-certificate decision — device (machine) cert, not user cert
**Description:** A decision, recorded, to authenticate pre-logon with a **Device (machine)
certificate** issued to the **LocalMachine** store — not a user certificate.
**Why required:** At the logon screen there is **no user context**, so a *user* certificate is not
available to the pre-logon tunnel. Only a **machine** certificate present in `LocalMachine\My` can
authenticate before Windows sign-in.
**How to verify:** Your design specifies **Certificate type = Device** for the SCEP/PKCS profile.
**How to implement if missing:** Choose **Device** for the certificate profile (Implementation §2.2).
Only use a user certificate if you have deliberately chosen interactive post-logon connect, which does
not satisfy true first-logon pre-logon connectivity.

## R9. Certificate infrastructure (PKI / NDES-SCEP or Intune Cloud PKI)
**Description:** A working PKI path for Intune to deliver a **device** certificate — an on-prem
**NDES/SCEP** connector, **Intune Cloud PKI**, or a supported third-party CA connector — plus the
**trusted root/intermediate CA** you will publish to devices.
**Why required:** Silent pre-logon depends on each device receiving a machine certificate the head-end
trusts, delivered by Intune, chaining to a root the device also trusts.
**How to verify:** Intune → **Devices > Configuration**; a SCEP (or PKCS) certificate profile can be
created and the SCEP/connector infrastructure is healthy; you have the root/intermediate CA cert file
to publish.
**How to implement if missing:** Stand up the SCEP/PKCS path (NDES + Intune Certificate Connector, or
enable Intune Cloud PKI), and obtain the trusted root/intermediate CA certificate. Ensure the **issuing
CA is trusted by the Cisco head-end** (Cisco-side trust config is deferred to Cisco docs).

## R10. Certificate renewal policy defined
**Description:** A defined **certificate validity period** and **renewal threshold** (percentage of
lifetime remaining, or days) for the device certificate profile so certificates renew *before* expiry.
**Why required:** Pre-logon silently breaks the moment the device certificate expires. A renewal
threshold comfortably ahead of expiry keeps the tunnel authenticating at every logon.
**How to verify:** Your SCEP/PKCS profile design records a validity period and a renewal threshold
(e.g. renew at 20% remaining lifetime).
**How to implement if missing:** Set a renewal threshold in the certificate profile (Implementation
§2.2) and include the certificate in the coverage report so expiries are caught early.

## R11. Administrative roles for building the deployment
**Description:** Intune admin rights to create Win32 apps, VPN configuration profiles, and certificate
profiles, and Entra rights to create/populate groups (Groups Administrator or better).
**Why required:** Packaging apps, creating VPN/cert profiles, and assigning groups all require elevated
roles.
**How to verify:** In Intune, you can reach **Apps > Add** and **Devices > Configuration > Create**; in
Entra you can create groups.
**How to implement if missing:** Have a Global Administrator assign **Intune Administrator** and
**Groups Administrator** (least-privilege) to the operator.

## R12. Microsoft Win32 Content Prep Tool
**Description:** The **Microsoft Win32 Content Prep Tool** (`IntuneWinAppUtil.exe`) on the packaging
workstation, used to wrap the Core + SBL modules and the SBL-enabled XML into an `.intunewin`.
**Why required:** Multi-module install with an enforced order (Core then Start Before Logon) plus the
profile-XML drop is best delivered as a Win32 app, which requires the `.intunewin` package.
**How to verify:** `IntuneWinAppUtil.exe` runs and reports its version.
**How to implement if missing:** Download the Win32 Content Prep Tool from Microsoft's official
`microsoft-Win32-Content-Prep-Tool` release and place it on the packaging workstation.

## R13. Microsoft Graph PowerShell SDK (to run the included scripts)
**Description:** The **Microsoft.Graph** PowerShell SDK installed on the operator workstation, used by
the discovery/report/remediation/targeting scripts (the on-device validation script runs locally and
needs no Graph).
**Why required:** The scripts call Microsoft Graph (Intune/Entra) to inventory the app, profiles,
certificate profiles, assignments, and group membership.
**How to verify:** In PowerShell, `Get-Module Microsoft.Graph -ListAvailable` returns a version.
**How to implement if missing:** Run `Install-Module Microsoft.Graph -Scope CurrentUser`. The scripts
call `Connect-MgGraph` with the specific delegated scopes each one documents in its header.

## R14. Change control and rollback (category requirement, restated)
**Description:** An approved change window and a written rollback (exclude the group / uninstall the app
/ remove the profiles).
**Why required:** Pushing a pre-logon VPN client, an SBL credential provider, and a machine certificate
touches the logon experience for real users; changes must be reversible.
**How to verify:** A rollback procedure exists and is approved; you know how to exclude
`PILOT – Pre-Logon VPN (SBL) Users` and how to flip the Win32 app to **Uninstall** if needed.
**How to implement if missing:** Document the rollback (Intune assignment exclusion, app Uninstall
intent, profile/cert removal) and the comms plan before you assign anything.

---

When all requirements pass, proceed to `03-implementation.md`.
