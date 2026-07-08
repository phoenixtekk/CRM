# Requirements — Pre-Logon VPN: First-Time Off-Network Sign-In & Password Reset

Confirm **every** requirement below before you decide and validate. Each entry follows the same shape:
**Description / Why required / How to verify / How to implement if missing.** The category-level
prerequisites (Entra tenant, Intune, admin roles, pilot group, change control) are in
`global-requirements-network.md`; the items here are specific to choosing a pre-logon approach and
validating the first-logon and off-network password-change scenarios.

> **Scope boundary:** this product is the **decision + scenario + validation** layer. The
> step-by-step device-tunnel and SBL/PLAP builds are **separate companion products** and are
> referenced by their object names — this guide does **not** re-teach them and does not fabricate
> vendor menus. Where a requirement says "from the companion product," it means the object is created
> there, not here.

---

## R1. A chosen (or deployed) pre-logon approach
**Description:** Either a working **Always On VPN device tunnel** or a working **Cisco Secure Client
Start Before Logon (SBL/PLAP)** deployment — or a firm decision to deploy one of them, made with the
decision matrix in `03-implementation.md`.
**Why required:** This product validates that a pre-logon path exists and works for the two scenarios.
It cannot validate a capability the fleet does not have.
**How to verify:** On a representative device, confirm a pre-logon tunnel exists —
`Get-VpnConnection -AllUserConnection` shows a device tunnel, **or** the SBL/PLAP credential provider
(`vpnplap64.dll`) is present. The included `PREVPN-Validation.ps1` checks both.
**How to implement if missing:** Run the decision matrix (`03-implementation.md`, Phase 2) to choose,
then deploy the chosen **companion product** — *Always On VPN — Device Tunnel (Pre-Logon) via Intune*
(creates `AOVPN – Device Tunnel – ProfileXML – Windows`) **or** *Pre-Logon VPN — Cisco Secure Client
(SBL/PLAP) via Intune* (creates `Cisco Secure Client – Pre-Logon (SBL) – Win32`).

## R2. Entra ID security groups (pilot and production)
**Description:** A pilot group `PILOT – Pre-Logon First-Logon Users` and one or more production target
groups (e.g. `PROD – Pre-Logon First-Logon Users`) containing the users/devices in scope.
**Why required:** Segmentation and reporting target Entra groups. The scenario validation is run
against a small, named pilot cohort before expanding.
**How to verify:** In the **Microsoft Entra admin center** (`https://entra.microsoft.com`) →
**Groups > All groups**, confirm `PILOT – Pre-Logon First-Logon Users` exists with the intended
members.
**How to implement if missing:** Entra → **Groups > New group > Security**; name it exactly
`PILOT – Pre-Logon First-Logon Users`; add 3–10 representative members. The included
`PREVPN-Set-ScopeTargeting.ps1` creates and populates these groups for you.

## R3. A device join-type inventory
**Description:** A current inventory of how your Windows devices are joined — **domain-joined**,
**Entra hybrid-joined**, or **Entra-joined (cloud-only)** — because the pre-logon decision and the
scenario behavior differ entirely by join type.
**Why required:** The first-logon / DC-reachability problem is a **hybrid/domain-joined** concern;
Entra-joined devices largely avoid it. Choosing an approach or scoping a pilot without the join-type
mix leads to over-deploying to cloud-only devices.
**How to verify:** Run `PREVPN-Discovery.ps1` for a fleet join-type report, or spot-check a device
with `dsregcmd /status` (look at `AzureAdJoined`, `DomainJoined`, `EnterpriseJoined`).
**How to implement if missing:** Produce the inventory with `PREVPN-Discovery.ps1` before deciding.
Record the counts of each join type; this drives the decision matrix.

## R4. A reachable domain controller through the tunnel (hybrid/domain-joined)
**Description:** At least one **Active Directory domain controller** that a pre-logon device can reach
**once the tunnel is up** — for the first interactive logon and for AD password changes.
**Why required:** Both scenarios depend on the device reaching a DC. A pre-logon tunnel that comes up
but has **no route to a DC** solves nothing.
**How to verify:** With the tunnel up on a test device, `nltest /dsgetdc:<domain>` locates a DC, or
`Test-NetConnection <dc-fqdn> -Port 389` succeeds. `PREVPN-Validation.ps1` performs a best-effort DC
reachability check.
**How to implement if missing:** Ensure the VPN gateway's routes/split-tunnel include the DC subnets
and that DNS resolves the domain through the tunnel (companion-product/network task). Confirm firewall
allows the AD ports (DNS 53, Kerberos 88, LDAP 389, etc.) from the VPN client range to the DCs.

## R5. Machine/device certificate path (only if choosing the device tunnel)
**Description:** A working PKI that issues each device a **machine certificate** the VPN gateway
trusts — delivered by the companion device-tunnel product (SCEP/PKCS via NDES, Intune Cloud PKI, or a
third-party CA connector).
**Why required:** The device tunnel authenticates **silently with a machine certificate** over IKEv2.
No machine cert → no silent pre-logon tunnel.
**How to verify:** On a device, a valid certificate is present in **LocalMachine\My** and chains to a
CA the gateway trusts (`PREVPN-Validation.ps1` checks for a LocalMachine\My cert).
**How to implement if missing:** Deploy the machine-cert profile from the companion device-tunnel
product (`AOVPN – Device Tunnel – Machine Cert (SCEP) – Windows`) and the trusted-root profile. **Skip
R5 entirely if you choose SBL/PLAP** (Approach B), which does not require a machine certificate.

## R6. Windows Enterprise / Education SKU (only if choosing the device tunnel)
**Description:** The **Windows Enterprise or Education** edition on devices that will run the Always On
VPN **device tunnel**.
**Why required:** The device tunnel is a **hard OS-SKU requirement** — it is supported only on
Enterprise/Education, not on Windows Pro/Home.
**How to verify:** `Get-ComputerInfo | Select WindowsProductName`, or **Settings > System > About**,
shows Enterprise or Education.
**How to implement if missing:** Move affected devices to a qualifying SKU, **or** choose **SBL/PLAP**
(Approach B), which does not have this SKU restriction.

## R7. Entra SSPR (optional — cloud password complement)
**Description:** **Entra self-service password reset (SSPR)**, optionally with **password writeback**
for hybrid users, as the cloud-native complement to the on-prem password-change scenario.
**Why required:** SSPR resolves the password path for **Entra-joined** users and, with writeback, the
directory password for hybrid users — reducing (but not eliminating) DC-path dependence at the lock
screen. Understanding where it does and does not help prevents wrong expectations.
**How to verify:** Entra → **Protection > Password reset** shows SSPR enabled and (for hybrid)
on-premises writeback configured and healthy.
**How to implement if missing:** Enable SSPR (Entra → **Password reset**) and, for hybrid, configure
password writeback via Entra Connect. **Note:** SSPR does **not** remove the need for a DC path for a
hybrid/domain-joined device's local interactive password change — validate the real behavior in T2.

## R8. Break-glass / recovery accounts
**Description:** A documented fallback: a **local administrator** account for on-device recovery and a
**Temporary Access Pass (TAP)** policy in Entra for passwordless first sign-in / recovery where the
flow is cloud-capable.
**Why required:** Pre-logon VPN can fail (bad cert, gateway down, DC unreachable). A break-glass path
prevents a stranded new hire or a locked-out remote user.
**How to verify:** A local admin account exists per policy; Entra → **Authentication methods >
Temporary Access Pass** is enabled for the appropriate users.
**How to implement if missing:** Establish the local-admin recovery policy; enable TAP in Entra and
document who may issue one. Capture the fallback procedure in your runbook.

## R9. Administrative roles
**Description:** Entra rights to create/populate groups (Groups Administrator or better) and read
device/join information, plus Intune read access to confirm the companion objects.
**Why required:** Segmenting the pilot cohort, reading join types, and confirming the pre-logon
objects require appropriate roles.
**How to verify:** In Entra you can create groups and read devices; in Intune you can view apps and
configuration profiles.
**How to implement if missing:** Have a Global Administrator assign **Groups Administrator** and
**Intune Administrator** (least-privilege) to the operator.

## R10. Microsoft Graph PowerShell SDK (to run the included scripts)
**Description:** The **Microsoft.Graph** PowerShell SDK on the operator workstation, used by the
discovery, report, remediation, and scope-targeting scripts. (`PREVPN-Validation.ps1` runs locally on
a device and needs no Graph.)
**Why required:** The scripts call Microsoft Graph (Entra/Intune) to report join types, pre-logon
capability presence, and group membership.
**How to verify:** `Get-Module Microsoft.Graph -ListAvailable` returns a version.
**How to implement if missing:** `Install-Module Microsoft.Graph -Scope CurrentUser`. Each script's
header lists the exact delegated scopes it uses.

## R11. Change control and rollback (category requirement, restated)
**Description:** An approved change window and a written rollback for any pre-logon change you make as
a result of this decision (revert the chosen approach's assignment, fall back to on-network onboarding).
**Why required:** Pre-logon connectivity affects how real users sign in; any change must be reversible
and must never strand a remote user.
**How to verify:** A rollback and comms plan exist and are approved before you change targeting.
**How to implement if missing:** Document the rollback (exclude the group from the companion product's
assignment; use the break-glass path from R8) before you expand.

---

When all requirements pass, proceed to `03-implementation.md` to choose the approach and validate the
two scenarios.
