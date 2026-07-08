# Requirements — Windows Always On VPN — Device Tunnel Before User Logon (IKEv2, Machine-Certificate Auth) via Intune

Confirm **every** requirement below before you build. Each entry follows the same shape:
**Description / Why required / How to verify / How to implement if missing.** The category-level
prerequisites (Entra tenant, Intune, admin roles, pilot group, change control) are in
`global-requirements-network.md`; the items here are specific to deploying the Always On VPN device
tunnel and its machine-certificate lifecycle.

> **Vendor boundary:** the **VPN gateway head-end** — Windows Server **Routing and Remote Access
> (RRAS)** or **Azure VPN Gateway** — is configured **per Microsoft's official documentation**. Below,
> "obtain from the head-end" means *get the value from the gateway configuration your network team
> built per Microsoft docs* — this guide does not fabricate head-end menu paths.

---

## R1. Microsoft Intune licensing and enrolled Windows devices
**Description:** An Intune-bearing license plan (e.g. Microsoft 365 E3/E5, EMS, or Intune standalone)
and the target Windows devices already enrolled and shown in Intune.
**Why required:** Intune is the delivery plane for the certificate profiles and the ProfileXML.
Nothing deploys to a device that is not enrolled and licensed.
**How to verify:** In the **Microsoft Intune admin center** (`https://intune.microsoft.com`), go to
**Devices > All devices** and confirm the target devices are present and *Compliant/Managed*. Under
**Tenant administration > Licenses**, confirm Intune licenses are assigned.
**How to implement if missing:** Assign an Intune-bearing license (Microsoft 365 admin center →
**Users** → assign licenses). Enroll Windows devices via Autopilot / Company Portal / hybrid-join
enrollment.

## R2. Supported Windows edition and join type (device-tunnel prerequisite)
**Description:** The target devices run **Windows 10 or Windows 11 Enterprise or Education, version
1709 or later**, and are **domain-joined** or **Entra hybrid-joined**.
**Why required:** The Always On VPN **device tunnel is supported only** on Enterprise/Education
(1709+) devices that are domain-joined or hybrid-joined. Home/Pro SKUs and (currently) pure
Entra-joined devices are not supported targets — the device tunnel will not deploy/connect reliably.
**How to verify:** On a target device, run `winver` (edition + version) and
`dsregcmd /status` (confirm `DomainJoined : YES` or `AzureAdJoined : YES` **with**
`DomainJoined : YES` for hybrid). In Intune, **Devices > All devices > (device) > Hardware** shows the
OS edition and join type.
**How to implement if missing:** Move devices to Enterprise/Education licensing and to a
domain-joined or hybrid-joined state. **Pure Entra-joined device-tunnel support is emerging/edge —
verify for your build** before targeting Entra-joined-only devices; do not assume it.

## R3. A VPN gateway head-end that supports the IKEv2 device tunnel
**Description:** A reachable **RRAS** server or **Azure VPN Gateway** configured for the Always On VPN
**device tunnel** — **IKEv2**, **machine-certificate** authentication, and an address pool / routes
for the machine-context connection.
**Why required:** The device tunnel needs something to connect *to*. The gateway address/FQDN, the
IKEv2 settings, the CA it trusts, and the server certificate it presents are inputs to the ProfileXML
and the certificate profiles.
**How to verify:** Obtain from your network team (per Microsoft docs): the **gateway external
address/FQDN** (e.g. `vpn.your-company.com`), confirmation that **IKEv2** and **machine-certificate**
auth are enabled for the device tunnel, and the **root/issuing CA** the head-end trusts.
**How to implement if missing:** Stand up / configure the RRAS or Azure VPN Gateway device tunnel
**per Microsoft's official documentation** — this is head-end work outside this solution's scope.
Record the address/FQDN, IKEv2 settings, and CA trust for use in R4–R6 and Implementation.

## R4. Certificate infrastructure for machine certificates (SCEP/PKCS)
**Description:** A working PKI path for Intune to deliver **device (machine) certificates** — an
on-prem **NDES/SCEP** connector (**Intune Certificate Connector**), **Intune Cloud PKI**, or a
supported third-party CA connector.
**Why required:** The device tunnel authenticates with a machine certificate in `LocalMachine\My`.
There is no user at boot, so a **device** certificate must be delivered by Intune before the tunnel
can connect.
**How to verify:** Intune → **Devices > Configuration**; a **SCEP certificate** profile can be created
and reaches devices. The NDES/Certificate Connector (if on-prem) shows healthy in **Tenant
administration > Connectors and tokens**.
**How to implement if missing:** Stand up the SCEP/PKCS path (NDES + Intune Certificate Connector, or
enable Intune Cloud PKI). Ensure the **issuing CA is trusted by the VPN head-end** (head-end trust
config is deferred to Microsoft docs).

## R5. The issuing CA's root/intermediate certificate (for the Trusted Root CA profile)
**Description:** The exported **root (and any intermediate) CA certificate** of the CA that issues the
machine certificates, in `.cer` form, to deploy via Intune's **Trusted certificate** profile.
**Why required:** The device must trust the chain of its own machine certificate (and the chain the
head-end presents) for IKEv2 machine-cert auth to succeed.
**How to verify:** You have the CA's root `.cer` file and can confirm it matches the chain the SCEP
profile will issue from and the chain the head-end trusts.
**How to implement if missing:** Export the root/intermediate CA certificate from your PKI, ready to
upload into the `AOVPN – Device Tunnel – Trusted Root CA – Windows` profile.

## R6. Server certificate on the VPN gateway (head-end side)
**Description:** The VPN gateway presents a **server authentication** certificate whose chain the
client trusts and whose subject matches the gateway address/FQDN the ProfileXML targets.
**Why required:** IKEv2 mutual authentication requires the gateway to present a valid server
certificate (Server Authentication EKU); a mismatch or untrusted chain breaks the tunnel.
**How to verify:** Obtain from your network team confirmation that the gateway presents a server cert
with **Server Authentication** EKU, a subject/SAN matching the gateway address/FQDN, and a chain the
client's Trusted Root CA profile (R5) covers.
**How to implement if missing:** Issue/install the gateway server certificate **per Microsoft's
official documentation** (RRAS/Azure VPN Gateway). This is head-end work; this solution consumes the
fact that it exists and trusts the same CA family.

## R7. VPN connection parameters recorded
**Description:** A recorded set of values for the ProfileXml: **gateway address/FQDN**, the **routes /
traffic filters** the device tunnel should carry (typically only the domain-controller / management
subnets), **trusted network detection** (DNS suffixes), and any **DNS (NRPT)** rules.
**Why required:** These are the exact values that go inside the ProfileXML. Consistency here is what
makes every device identical. Route/policy specifics on the head-end side are deferred to Microsoft
docs, but the ProfileXML must reflect them.
**How to verify:** You have a single sheet with each value; the routes match what the head-end
advertises for the device tunnel.
**How to implement if missing:** Collect the values from R3 and your network/security owner. Decide
which subnets the device tunnel carries (keep it minimal — DC/management reachability, not full
tunnel) before authoring the ProfileXML.

## R8. Administrative roles for building the deployment
**Description:** Intune admin rights to create configuration profiles (Custom + certificate), and
Entra rights to create/populate **device** groups (Groups Administrator or better).
**Why required:** Creating the Custom OMA-URI profile, the certificate profiles, and the device groups
all require elevated roles.
**How to verify:** In Intune, you can reach **Devices > Configuration > Create**; in Entra you can
create groups.
**How to implement if missing:** Have a Global Administrator assign **Intune Administrator** and
**Groups Administrator** (least-privilege) to the operator.

## R9. Microsoft Graph PowerShell SDK (to run the included scripts)
**Description:** The **Microsoft.Graph** PowerShell SDK installed on the operator workstation, used by
the discovery / report / remediation / targeting scripts.
**Why required:** The scripts call Microsoft Graph (Intune/Entra) to inventory the Custom profile, the
certificate profiles, assignments, and device-group membership.
**How to verify:** In PowerShell, `Get-Module Microsoft.Graph -ListAvailable` returns a version.
**How to implement if missing:** Run `Install-Module Microsoft.Graph -Scope CurrentUser`. The scripts
call `Connect-MgGraph` with the specific delegated scopes each one documents in its header. (The
on-device validation script runs locally and needs **no** Graph scopes.)

## R10. Change control and rollback (category requirement, restated)
**Description:** An approved change window and a written rollback (remove the assignment / push a
remove-profile for the device tunnel).
**Why required:** The device tunnel touches the **pre-logon boot path** — an irreversible-feeling area
for users if it misbehaves — so changes must be reversible.
**How to verify:** A rollback procedure exists and is approved; you know how to unassign
`PILOT – AOVPN Device Tunnel – Devices` and how to push a remove profile if needed.
**How to implement if missing:** Document the rollback (Intune assignment removal; a Custom profile
that removes the VPNv2 profile) and the comms plan before you assign anything.

---

## Commercial vs Government (GCC / GCC High)

This guide uses the **commercial** endpoints. On **US Government** tenants the portals differ — use
`https://intune.microsoft.us` / `https://entra.microsoft.us` and sign-in at `login.microsoftonline.us`
(and equivalent `.us` service endpoints). Feature availability and rollout timing can differ on
GCC High; **verify each step for GCC High** against Microsoft's US Government documentation before
relying on it. No Government-specific device-tunnel behavior is invented here.

---

When all requirements pass, proceed to `03-implementation.md`.
