# Requirements — Windows Always On VPN: User Tunnel with Conditional Access via Microsoft Intune

Confirm **every** requirement below before you build. Each entry follows the same shape:
**Description / Why required / How to verify / How to implement if missing.** The category-level
prerequisites (Entra tenant, Intune, admin roles, pilot group, change control) are in
`global-requirements-network.md`; the items here are specific to deploying the Always On VPN **user
tunnel** and its Conditional Access gate.

> **Vendor boundary:** the **VPN gateway / head-end (Windows Server RRAS or an Azure VPN Gateway) and its
> IKEv2/SSTP + EAP configuration are deferred to Microsoft's official documentation.** Below, "obtain
> from the head-end" means *get the value from your network/VPN admin or Microsoft docs* — this guide
> does not fabricate RRAS/Azure gateway menu paths.

> **Companion product boundary:** the **device tunnel** and the **full certificate lifecycle** (PKI
> design, SCEP/NDES or Cloud PKI stand-up, issuing-CA trust, renewal/revocation) are covered in depth by
> the **companion device-tunnel product**. Here the **user** certificate is configured **leanly** (R4/R5)
> and cross-referenced to that product for the full lifecycle.

---

## R1. Microsoft Intune licensing and enrolled Windows devices
**Description:** An Intune-bearing license plan (e.g. Microsoft 365 E3/E5, EMS, or Intune standalone) and
the target **Windows 10/11 Enterprise or Education** devices already enrolled and shown in Intune.
**Why required:** Intune is the delivery plane for the VPN profile and the user certificate. Nothing
deploys to a device that is not enrolled and licensed.
**How to verify:** In the **Microsoft Intune admin center** (`https://intune.microsoft.com`), go to
**Devices > All devices** and confirm the target devices are present and *Compliant/Managed*. Under
**Tenant administration > Licenses**, confirm Intune licenses are assigned to the pilot users.
**How to implement if missing:** Assign an Intune-bearing license to the pilot users (Microsoft 365
admin center → **Users** → assign licenses). Enroll devices via Autopilot / Company Portal / Entra join.

## R2. Entra ID USER security groups (pilot and production)
**Description:** A pilot **user** group `PILOT – AOVPN User Tunnel Users` and a production **user** group
`PROD – AOVPN User Tunnel Users`, containing the **users** who receive the user tunnel.
**Why required:** The **user** tunnel and the user certificate are **user-assigned**, and the Conditional
Access policy is scoped to users. The pilot-first model needs a small, named pilot user group distinct
from the eventual production audience.
**How to verify:** In the **Microsoft Entra admin center** (`https://entra.microsoft.com`), go to
**Groups > All groups** and confirm `PILOT – AOVPN User Tunnel Users` exists with the intended user
members.
**How to implement if missing:** Entra → **Groups > New group > Security**; name it exactly
`PILOT – AOVPN User Tunnel Users`; add 3–10 representative pilot **users**. The included
`AOVUT-Set-ScopeTargeting.ps1` script creates and populates these user groups for you.

## R3. A VPN gateway / head-end for the user tunnel (RRAS or Azure VPN Gateway)
**Description:** A reachable Always On VPN termination point — a Windows Server **RRAS** VPN server or an
**Azure VPN Gateway** — configured to accept the **user tunnel** over **IKEv2 (with SSTP fallback)** using
**certificate/EAP** authentication.
**Why required:** The deployed profile needs something to connect *to*. The gateway FQDN, the accepted
authentication (user cert/EAP), the IKEv2/SSTP listener, and the routes/IP pool are inputs to the Intune
VPN profile.
**How to verify:** Obtain from your network/VPN team: the **gateway public FQDN** (e.g.
`vpn.your-company.com`), confirmation that **IKEv2 and SSTP** are listening, and the **EAP/certificate**
method accepted. Confirm a test user can already connect manually to that gateway with a user cert.
**How to implement if missing:** Stand up / configure the RRAS server or Azure VPN Gateway for the user
tunnel **per Microsoft's official documentation** — this is head-end work outside this solution's scope.
Record the FQDN, auth method, and routes for R6/Implementation.

## R4. User certificate path (SCEP/PKCS) — configured leanly here
**Description:** A working certificate path for Intune to deliver a **user** certificate — an on-prem
**NDES/SCEP** connector, **Intune Cloud PKI**, or a supported third-party CA connector — and a **SCEP
(or PKCS) user certificate profile** in Intune.
**Why required:** The user tunnel authenticates with a **user** certificate in `CurrentUser\My`; Intune
must be able to issue it to each pilot user's device.
**How to verify:** Intune → **Devices > Configuration**; a user SCEP certificate profile named
`AOVPN – User Tunnel – User Cert (SCEP) – Windows` deploys successfully to a test user, and the issued
cert chains to a CA the VPN gateway trusts.
**How to implement if missing:** Stand up the SCEP/PKCS path (NDES + Intune Certificate Connector, or
enable Intune Cloud PKI). **The full certificate lifecycle — PKI design, issuing-CA trust, renewal and
revocation — is covered in depth by the companion device-tunnel product;** provision at least a basic
working SCEP path here so R5 and the VPN profile can reference a user cert.

## R5. Trusted root / issuing CA available to Intune
**Description:** The **root (and issuing) CA certificate(s)** exported so Intune can deploy them as a
**Trusted certificate** profile, and the chain the VPN gateway trusts.
**Why required:** A Windows device must **trust the CA chain** before the SCEP user certificate succeeds
and before the tunnel can validate the gateway/EAP. The trusted-root profile establishes that trust.
**How to verify:** Intune → **Devices > Configuration**; a **Trusted certificate** profile named
`AOVPN – User Tunnel – Trusted Root CA – Windows` deploys *Succeeded* to a test device, and the SCEP cert
in R4 then chains cleanly.
**How to implement if missing:** Export the root/issuing CA (`.cer`) from your PKI and create the Trusted
certificate profile (Implementation §2.1). Ensure the **VPN gateway trusts the same issuing CA** (head-end
trust config is deferred to Microsoft docs). Full PKI trust design is the companion device-tunnel product.

## R6. VPN connection parameters recorded
**Description:** A recorded set of connection values: **gateway FQDN**, **connection type** (Automatic —
IKEv2 with SSTP fallback), **authentication** (user certificate/EAP), **split-tunnel routes**, **DNS
suffix/servers**, and the **Trusted Network Detection** DNS suffix that suppresses the tunnel on the
corporate LAN.
**Why required:** These are the exact fields you type into the Intune VPN template profile. Consistency
here is what makes every user's tunnel identical.
**How to verify:** You have a single sheet listing each value; a manual client connect using those values
succeeds against the head-end.
**How to implement if missing:** Collect the values from R3/R5 and your network design. Decide split-tunnel
routes and the trusted-network DNS suffix with the network owner before building the profile.

## R7. Microsoft Entra Conditional Access available
**Description:** Conditional Access is available in the tenant (Entra ID **P1** or higher) and you can
create policies under **Entra > Protection > Conditional Access**.
**Why required:** The tunnel is gated by a Conditional Access policy (`CA – AOVPN User Tunnel Access`)
that requires a compliant/hybrid-joined device and MFA before the user reaches corporate resources.
**How to verify:** Entra admin center → **Protection > Conditional Access > Policies** loads and you can
select **New policy**.
**How to implement if missing:** Ensure Entra ID P1+ licensing is assigned to the pilot users (Conditional
Access requires it), then confirm access to the Conditional Access blade.

## R8. A device compliance policy for Windows
**Description:** An Intune **compliance policy** for Windows assigned to the pilot users/devices, so
"device is compliant" is a meaningful signal Conditional Access can require.
**Why required:** The Conditional Access grant "**Require device to be marked as compliant**" only works if
a compliance policy defines and evaluates compliance for those devices.
**How to verify:** Intune → **Devices > Compliance** shows a Windows compliance policy assigned to the
pilot audience, and pilot devices report *Compliant*.
**How to implement if missing:** Create a Windows compliance policy (Intune → **Devices > Compliance >
Create policy > Windows 10 and later**), set your baseline rules, and assign it to
`PILOT – AOVPN User Tunnel Users`.

## R9. Administrative roles for building the deployment
**Description:** Intune admin rights to create configuration/certificate profiles, Entra rights to create
Conditional Access policies (**Conditional Access Administrator** or **Security Administrator**), and
rights to create/populate groups (**Groups Administrator** or better).
**Why required:** Building VPN/cert profiles, creating the Conditional Access policy, and assigning groups
all require elevated roles.
**How to verify:** In Intune you can reach **Devices > Configuration > Create**; in Entra you can reach
**Protection > Conditional Access > New policy** and create groups.
**How to implement if missing:** Have a Global Administrator assign **Intune Administrator**,
**Conditional Access Administrator**, and **Groups Administrator** (least-privilege) to the operator.

## R10. Microsoft Graph PowerShell SDK (to run the included scripts)
**Description:** The **Microsoft.Graph** PowerShell SDK installed on the operator workstation, used by the
five discovery/validation/report/remediation/targeting scripts.
**Why required:** The scripts call Microsoft Graph (Intune/Entra) to inventory profiles, the Conditional
Access policy, assignments, and group membership.
**How to verify:** In PowerShell, `Get-Module Microsoft.Graph -ListAvailable` returns a version.
**How to implement if missing:** Run `Install-Module Microsoft.Graph -Scope CurrentUser`. The scripts call
`Connect-MgGraph` with the specific delegated scopes each one documents in its header (the discovery script
additionally needs `Policy.Read.All` to read the Conditional Access policy).

## R11. Change control and rollback (category requirement, restated)
**Description:** An approved change window and a written rollback (unassign the profiles / set the
Conditional Access policy to **report-only**).
**Why required:** Pushing an always-on tunnel and a Conditional Access gate touches remote-access and
sign-in for real users; changes must be reversible.
**How to verify:** A rollback procedure exists and is approved; you know how to exclude
`PILOT – AOVPN User Tunnel Users` from the profiles and how to flip `CA – AOVPN User Tunnel Access` to
**Report-only**.
**How to implement if missing:** Document the rollback (profile unassignment, Conditional Access
report-only) and the comms plan before you assign anything.

> **Government (GCC / GCC High / DoD) note:** in US Government tenants the admin portals are on different
> hosts — Intune at **`https://endpoint.microsoft.us`**, Entra at **`https://entra.microsoft.us`**, and
> sign-in/Graph at **`login.microsoftonline.us`** (Graph at `graph.microsoft.us`). Substitute these
> endpoints throughout, and **verify feature parity and endpoint availability for GCC High** before you
> build — Conditional Access, certificate connectors, and VPN template options can differ or roll out
> later than in Commercial.

---

When all requirements pass, proceed to `03-implementation.md`.
