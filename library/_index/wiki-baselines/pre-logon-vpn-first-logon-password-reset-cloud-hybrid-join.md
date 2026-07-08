# Pre-Logon VPN for Cloud & Hybrid-Joined Devices — First-Time Off-Network Sign-In & Password Reset

> **Version 1.0.0** · Category: Network · Solution code: PREVPN

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary — Pre-Logon VPN for Cloud & Hybrid-Joined Devices: First-Time Off-Network Sign-In & Password Reset

## The business problem
Remote-first work breaks two everyday moments that used to "just work" in the office. A **new
employee's** laptop is shipped to their home with **no cached credentials**, and they cannot complete
their **first Windows sign-in** because the device can't reach a domain controller. And a remote
user's **password expires** off-network, but they can't change it at the sign-in screen because the
password change also has to reach a domain controller. Both leave people stranded, generate help-desk
tickets, and — worst case — result in laptops being couriered around just to log in once.

## The solution
This is a complete, self-guided **decision, scenario, and validation** package for **pre-logon VPN** —
bringing the network up **before or at** Windows sign-in so a domain controller is in reach at exactly
the moment it's needed. It does the part teams actually get wrong: it **chooses the right approach**
for your fleet (Windows Always On VPN **device tunnel** vs. Cisco Secure Client **Start Before Logon /
PLAP**), explains the **two hard scenarios by device join type**, and **validates** them end to end —
proving a never-logged-on user can first-sign-in and an expired-password user can reset, both off the
network. It uses a proven method: **Assess → Configure → Pilot → Validate → Expand**, with explicit
pass/fail gates.

## What you get
- **A defensible decision** — a device-tunnel-vs-SBL/PLAP matrix by join type, OS SKU, existing VPN
  vendor, and support model, so you pick once and pick right.
- **The two scenarios covered** — first-time off-network logon and off-network password change,
  explained by join type (why it's a **hybrid/domain-joined** problem, and why **Entra-joined**
  devices largely avoid it), with SSPR positioned as the cloud complement.
- **Five PowerShell scripts** — fleet join-type + readiness discovery, on-device validation (join
  type, pre-logon path, DC reachability), a coverage report, safe remediation (preview-by-default), and
  a segmentation-group builder.
- **Requirements, testing, troubleshooting, and best-practice guides** so a competent admin can decide,
  validate, and operate it.

## Business outcomes
- **New hires sign in on day one, from anywhere** — no couriered laptops, no "log in at the office
  first" workaround.
- **Expired passwords self-resolve off-network** — the change reaches a domain controller through the
  pre-logon tunnel, cutting lockout tickets.
- **No wasted deployment** — clear guidance that cloud-only Entra-joined devices usually need neither
  approach, so you don't ship a tunnel where none is required.
- **Proven before it matters** — both scenarios validated on a pilot with explicit gates, and a
  documented break-glass fallback for the day something breaks.

## Scope and boundary
This package is the **decision + scenario + validation** layer. The **step-by-step builds** for the
device tunnel and for SBL/PLAP are **separate companion products**, referenced here by their exact
object names so the decision, the build, and the validation stay coherent — this solution does not
recreate them. VPN gateway and vendor client internals follow those products and the **vendor's
official documentation**.

## Bottom line
The two remote-work sign-in problems — first logon with no cached credentials, and password reset off
the network — solved by choosing the right pre-logon approach and proving it works, at a fraction of
the cost and time of a hands-on consulting engagement.


---


# Solution Overview — Pre-Logon VPN for Cloud & Hybrid-Joined Devices: First-Time Off-Network Sign-In & Password Reset

## What this solution is

This solution is the **decision, scenario, and validation layer** for pre-logon VPN. It answers the
two questions that a remote-first fleet actually gets stuck on:

1. **A brand-new employee's laptop is off the corporate network and has *no cached credentials* —
   how do they complete their *first* Windows sign-in?**
2. **A remote user's password has *expired* while off-network — how do they *change* it at the
   logon/lock screen when the password change has to reach a domain controller?**

Both problems have the same root cause: the network is not up *before* Windows sign-in, so the
device cannot reach a **domain controller (DC)** at the moment it needs one. **Pre-logon VPN** solves
both by bringing the tunnel up **before or at** the Windows credential prompt.

This solution does **not** re-teach the two deployment builds that create a pre-logon tunnel. Those
are **separate products** (see below). This product tells you **which approach to choose**, **how the
two scenarios actually behave** by device join type, and **how to validate end to end** that a
never-logged-on user and an expired-password user can both get in from off the network.

## What this solution is NOT (and where to get it)

- It does **not** contain the step-by-step **Always On VPN device-tunnel** build. That is the
  companion product *Always On VPN — Device Tunnel (Pre-Logon) via Intune*, which creates the
  device-tunnel profile named `AOVPN – Device Tunnel – ProfileXML – Windows` (plus its trusted-root
  and machine-certificate profiles).
- It does **not** contain the step-by-step **Start Before Logon (SBL/PLAP)** build. That is the
  companion product *Pre-Logon VPN — Cisco Secure Client (SBL/PLAP) via Intune*, which creates the
  Win32 app named `Cisco Secure Client – Pre-Logon (SBL) – Win32` (plus its SBL profile).

This product **references those objects by name** so the three pieces stay coherent, but it does not
duplicate their builds. If you have not deployed either approach yet, you run this decision guide
**first** to pick the right one, then implement the chosen companion product, then return here to
validate the two scenarios.

## The two approaches you are choosing between

Pre-logon connectivity comes from one of two mechanisms. This solution's job is to help you pick the
right one for your fleet — not to reconfigure them.

### Approach A — Windows Always On VPN **device tunnel**
- **What it is:** A machine-level IKEv2 VPN that Windows brings up **automatically at boot, before
  any user signs in**, authenticated by a **machine certificate** (no user interaction).
- **Hard requirements (facts):** the device must be **domain-joined or Entra hybrid-joined**, run
  **Windows Enterprise or Education** SKU, hold a **machine certificate** the VPN gateway trusts, and
  the gateway must support **IKEv2**.
- **Best when:** you want a *silent, always-available* DC path for every managed Windows device with
  no user action, and you own the PKI + an IKEv2-capable gateway.
- **Object it deploys (companion product):** `AOVPN – Device Tunnel – ProfileXML – Windows`.

### Approach B — Cisco Secure Client **Start Before Logon (SBL / PLAP)**
- **What it is:** A **Windows credential provider (PLAP)** that lets the user bring up the Cisco
  Secure Client VPN **at the Windows logon screen**, *before* submitting their Windows credentials.
- **Hard requirements (facts):** Windows only; the Secure Client with the **SBL/PLAP** module
  installed; a reachable Cisco head-end. It is **user-initiated at the logon screen**, not silent.
- **Best when:** you already run Cisco Secure Client (AnyConnect), you cannot meet the device-tunnel
  SKU/PKI/IKEv2 requirements, or you want the user to choose the network before signing in.
- **Object it deploys (companion product):** `Cisco Secure Client – Pre-Logon (SBL) – Win32`.

## The decision matrix (summary)

| Factor | Device tunnel (A) | SBL / PLAP (B) |
|---|---|---|
| Join type supported | Domain-joined **or** Entra hybrid-joined | Domain-joined **or** hybrid-joined (Windows) |
| OS SKU | **Enterprise / Education required** | Any Windows Pro/Enterprise (per Cisco support) |
| Auth at pre-logon | **Machine certificate (silent)** | User brings up VPN at logon screen |
| Tunnel protocol | **IKEv2** | Cisco Secure Client (per head-end) |
| User action needed | **None** (auto at boot) | User connects at the logon screen |
| Existing VPN vendor fit | Native Windows / any IKEv2 gateway | You already run Cisco Secure Client |
| Entra-joined (cloud-only) devices | Usually **not needed** (see below) | Usually **not needed** (see below) |

The full matrix, with a step-by-step "choose the approach" procedure, is in `03-implementation.md`.

## Why join type is the whole story

The first-logon / DC-reachability problem is fundamentally a **hybrid-joined / domain-joined**
problem — because those devices authenticate the user against **Active Directory**, which lives on a
**domain controller** the device must reach.

- **Entra-joined (cloud-only) devices** authenticate the user against **Entra ID in the cloud**, not
  against an on-prem DC. A first sign-in works over ordinary internet with no pre-logon tunnel, and a
  password change is a **cloud** operation. These devices **largely avoid** the classic first-logon
  and off-network password-change problems this product solves. Do not deploy a pre-logon tunnel to
  solve a problem an Entra-joined device does not have.
- **Entra hybrid-joined and domain-joined devices** still need a DC for the *interactive* logon of a
  user who has **never signed in on that device** (no cached credentials) and for an **AD password
  change**. These are the devices pre-logon VPN is for.

Getting this right up front avoids the two most common mistakes: deploying a pre-logon tunnel to
cloud-only devices that never needed it, and expecting SSPR (a cloud feature) to fix an on-prem AD
password change on a hybrid device.

## Scenario 1 — First-time off-network logon

A new hire's hybrid-joined laptop is shipped to their home. They have **never logged on** to that
device, so Windows has **no cached credential** for them. Without a DC in reach at the logon screen,
the *first* interactive logon cannot be validated and fails.

- **Cached credentials** only help a user who has **already** signed in on that device — Windows
  caches a verifier after a successful DC logon. A never-logged-on user has **nothing cached**, so
  they **require** a live DC path for the first logon.
- **Pre-logon VPN provides that path.** Device tunnel (A) brings the DC into reach automatically
  before the logon screen; SBL/PLAP (B) lets the user bring it up at the logon screen. Either way,
  the first interactive logon can now reach a DC and succeed.
- **Validation** (see `05-testing.md`, T1) proves a freshly provisioned device with a never-logged-on
  user completes first logon off-network via the pre-logon tunnel.

## Scenario 2 — Off-network password change / reset

A remote user's password has **expired**. Windows prompts them to change it at the logon/lock
screen — but an **Active Directory password change** must be written to a **domain controller**. Off
the network with no pre-logon tunnel, the change cannot reach a DC and fails.

- **The tunnel must be up so the change reaches a DC.** With device tunnel (A) the machine tunnel is
  already up at the lock screen; with SBL/PLAP (B) the user brings the tunnel up first, then changes
  the password. The Kerberos/AD password change then completes against the DC.
- **SSPR (Entra self-service password reset) is the cloud-native complement.** For **Entra-joined**
  users, SSPR changes the cloud password and there is no on-prem DC dependency. For **hybrid** users,
  SSPR with **password writeback** can reset the *directory* password, but the **Windows on-prem
  credential at the lock screen still expects an AD change that reaches a DC** — SSPR does **not**
  remove the need for a DC path for the local interactive password change on a hybrid/domain-joined
  device. Treat SSPR as complementary, not a replacement, and validate the actual behavior (T2).

## Break-glass and fallback

Pre-logon VPN is infrastructure, and infrastructure fails. This solution documents the fallbacks:

- **Local administrator account** on the device for recovery (kept per your security policy).
- **Temporary Access Pass (TAP)** in Entra for passwordless first sign-in / recovery where the flow
  is cloud-capable.
- **What to do if pre-logon VPN fails** — bring the device on-network once (office/known network),
  use SBL/PLAP as a manual fallback where a silent device tunnel did not come up, or use SSPR/TAP for
  the cloud-capable paths. Full guidance is in `06-troubleshooting.md`.

## Benefits

- **The right approach, chosen once.** A defensible device-tunnel-vs-SBL decision by join type, OS
  SKU, existing vendor, and support model — not a coin toss.
- **The two hard scenarios actually covered.** First-time off-network logon and off-network password
  change, explained by join type and validated end to end.
- **No cloud-only over-deployment.** Clear guidance that Entra-joined devices usually need neither
  approach, so you don't ship a tunnel where none is required.
- **Coherent with the deployment products.** Objects are referenced by their exact companion-product
  names, so the decision, the build, and the validation all line up.
- **Reportable readiness.** The included scripts report join types across the fleet and which devices
  already have a pre-logon path, so you know your coverage before an employee is stranded.

## Limitations and boundaries

- **This is the decision + scenario + validation layer, not a deployment build.** The device-tunnel
  and SBL/PLAP step-by-step builds live in their companion products and are referenced, not repeated.
- **Vendor and OS internals are deferred.** IKEv2/ProfileXML internals and the Cisco head-end / SBL
  module internals follow the companion products and the **vendor's official documentation**.
- **Active Directory and PKI are assumed.** A reachable DC (through the tunnel) and, for the device
  tunnel, a machine-certificate PKI path are prerequisites, not deliverables.

## The standard model

This solution follows the category-standard model, with explicit pass/fail gates — but framed around
**scenario validation** rather than profile creation:

**Assess → Configure → Pilot → Validate → Expand**

1. **Assess.** Inventory device join types and existing pre-logon capability; confirm prerequisites.
2. **Configure.** *Choose* the approach with the decision matrix and confirm the chosen companion
   product's objects exist; segment the pilot users.
3. **Pilot.** Put a representative pilot cohort (hybrid + domain-joined + one Entra-joined control)
   into `PILOT – Pre-Logon First-Logon Users`.
4. **Validate.** Run the two decisive scenario tests (first-logon, password-change) end to end.
5. **Expand.** Widen to production, monitor readiness coverage, keep the break-glass fallback ready.

Proceed to the **Requirements guide** (`02-requirements.md`) to confirm you are ready to decide and
validate.


---


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


---


# Global Requirements — Network (category-level)

These requirements apply to **every** solution in the **Network** category (SASE/SSE, secure web
gateway, Zero Trust network access, and related network-security work — Netskope-centric). They are
published once at the category level so individual listings stay small. Confirm these before deploying
*any* Network solution. Each entry: **Description · Why · Verify · Implement-if-missing.**

> **Vendor note:** these solutions are authored at the correct architectural and procedural level.
> Exact, current **Netskope console** screens, menu paths, and tenant-specific options change over
> time and are **deferred to the official Netskope documentation and your Netskope tenant** — follow
> the named step and confirm the precise control in your console.

## G1. A Netskope tenant
**Description:** An active, licensed Netskope tenant with admin access.
**Why:** It is the control plane for SWG, ZTNA, SSL inspection, and policy.
**Verify:** Sign in to your Netskope tenant admin console as an administrator.
**Implement:** Engage your Netskope account team / reseller to provision a tenant and the required modules.

## G2. Microsoft Entra ID tenant
**Description:** An active Microsoft Entra ID (Azure AD) tenant.
**Why:** Identity is the backbone for SSO, identity-based policy, and user/group steering.
**Verify:** Sign in to `https://entra.microsoft.com` as an administrator.
**Implement:** Create a Microsoft 365 / Azure subscription, which provisions a tenant.

## G3. Endpoint management (Intune)
**Description:** Microsoft Intune (or an equivalent) able to deploy the client and certificates to endpoints.
**Why:** The Netskope client, root/decryption certificates, and steering config are delivered to managed devices.
**Verify:** `https://intune.microsoft.com` loads and target devices are enrolled and compliant.
**Implement:** Assign an Intune-bearing license plan and enroll the target devices.

## G4. Administrative roles
**Description:** Appropriate admin roles in Netskope, Entra ID, and Intune for the operator.
**Why:** Creating policies, app definitions, and deployments requires elevated rights in each plane.
**Verify:** Confirm an admin role in each console (Netskope admin; Entra/Intune admin).
**Implement:** Assign least-privilege admin roles; reserve Global Administrator for tenant-wide changes.

## G5. Network and identity fundamentals in place
**Description:** Working DNS, routing/egress, and an identity source (Entra ID / Active Directory) for users and groups.
**Why:** Traffic steering, SSL inspection, and identity-based policy depend on resolvable, routable, identified traffic.
**Verify:** Endpoints resolve DNS and reach the internet; users/groups are present in Entra ID.
**Implement:** Remediate DNS/egress; sync Active Directory to Entra ID if hybrid.

## G6. A pilot group
**Description:** A Microsoft Entra security group of pilot users/devices for staged rollout.
**Why:** Every solution is piloted before fleet rollout to validate steering, policy, and performance.
**Verify:** Entra → **Groups**; the pilot group exists.
**Implement:** Entra → **Groups → New group → Security** → add members.

## G7. Change control and a rollback path
**Description:** A change window and a documented rollback (disable steering / remove client / revert policy).
**Why:** Inline proxy, decryption, and ZTNA changes affect live traffic and must be reversible.
**Verify:** A rollback procedure is written and approved before enabling inline enforcement.
**Implement:** Define the rollback (e.g. steering exception, client uninstall, policy disable) and a comms plan.

---
**The standard deployment model (all solutions):** **Assess → Configure → Pilot → Validate → Expand.**


---


# Implementation — Pre-Logon VPN: Choose the Approach & Validate the Two Scenarios

This is the ordered procedure. Follow the phases in order:
**Assess → Configure → Pilot → Validate → Expand.** Because this product is the **decision +
scenario + validation** layer, the phases are framed around **choosing an approach** and **proving
the two scenarios**, not around building VPN profiles (those builds live in the companion products).
Use the **exact object names** shown — the tests, troubleshooting, and scripts reference them verbatim.

> **Scope boundary:** the device-tunnel build (`AOVPN – Device Tunnel – ProfileXML – Windows`) and
> the SBL/PLAP build (`Cisco Secure Client – Pre-Logon (SBL) – Win32`) are **created in their
> companion products** and are **deferred to those products and the vendor's official documentation**.
> This guide chooses between them and validates the outcome; it does not re-create them.

> **Government / GCC High note:** the portal URLs below are Commercial. In US sovereign clouds use the
> `*.us` equivalents — Intune/Endpoint at `https://endpoint.microsoft.us`, Entra at
> `https://entra.microsoft.us`, and sign-in at `login.microsoftonline.us` — and **verify each step for
> GCC High**, as feature availability and portal paths can differ. Do not assume Commercial steps map
> one-to-one; confirm against Microsoft US Gov documentation.

## Object naming convention (use verbatim)

| Object | Name | Created where |
|---|---|---|
| Pilot group | `PILOT – Pre-Logon First-Logon Users` | This product (`PREVPN-Set-ScopeTargeting.ps1`) |
| Production group | `PROD – Pre-Logon First-Logon Users` | This product (`PREVPN-Set-ScopeTargeting.ps1`) |
| Device-tunnel profile (referenced) | `AOVPN – Device Tunnel – ProfileXML – Windows` | Companion device-tunnel product |
| SBL/PLAP app (referenced) | `Cisco Secure Client – Pre-Logon (SBL) – Win32` | Companion SBL/PLAP product |

---

# Phase 1 — Assess

1. Confirm every item in `02-requirements.md` passes.
2. Build the **join-type inventory** and pre-logon readiness baseline:
   `powershell -ExecutionPolicy Bypass -File .\scripts\PREVPN-Discovery.ps1`
   Review the readiness table: counts by join type (hybrid / domain-joined / Entra-joined), whether a
   device-tunnel profile **or** the SBL/PLAP app is present, and pilot/prod group membership.
3. Note which devices are **hybrid/domain-joined** (the ones the two scenarios apply to) versus
   **Entra-joined** (which usually need neither approach).

**Gate A (Assess):** You have the join-type mix, you know which devices are in scope for pre-logon,
and all requirements pass. If the fleet is overwhelmingly Entra-joined, confirm you actually need
pre-logon at all before proceeding.

---

# Phase 2 — Configure (choose the approach)

## 2.0 Create the segmentation groups

Use the script (recommended) or the portal.

- **Script:** `powershell -ExecutionPolicy Bypass -File .\scripts\PREVPN-Set-ScopeTargeting.ps1`
  (creates `PILOT – Pre-Logon First-Logon Users` and, with `-CreateProd`,
  `PROD – Pre-Logon First-Logon Users`, and adds the members you supply).
- **Portal:** Entra admin center → **Groups > New group > Security** → name
  `PILOT – Pre-Logon First-Logon Users` → add pilot members → **Create**. Repeat for the prod group.

## 2.1 Run the decision matrix — pick device tunnel or SBL/PLAP

Work down the matrix. The **first row that forces a choice wins**; use the later rows to confirm.

| # | Question | If this is true → | Approach |
|---|---|---|---|
| 1 | Are the in-scope devices **Entra-joined (cloud-only)**? | They authenticate against Entra in the cloud; a first logon and password change work without an on-prem DC. **Do not deploy a pre-logon tunnel** — use SSPR/TAP for the cloud paths. | **Neither** |
| 2 | Are devices **domain-joined / hybrid-joined**? | The scenarios apply — continue to row 3. | (continue) |
| 3 | Are all in-scope devices **Windows Enterprise / Education** with a **machine-cert PKI** and an **IKEv2** gateway? | You can run a **silent, no-user-action** machine tunnel at boot. | **Device tunnel (A)** |
| 4 | Do you **already run Cisco Secure Client**, or **cannot** meet the Enterprise/Education + machine-cert + IKEv2 bar? | Use the **logon-screen** VPN the user brings up before signing in. | **SBL / PLAP (B)** |
| 5 | Do you want the **user to choose** the network before logon, or need a manual fallback? | SBL/PLAP is user-initiated at the logon screen. | **SBL / PLAP (B)** |
| 6 | Support model: fully hands-off vs. help-desk-guided first connect? | Hands-off → device tunnel (A); guided/manual → SBL/PLAP (B). | (tie-break) |

Record the decision (approach, and why) in your runbook. If devices split across categories, you may
run **both** (device tunnel for the Enterprise/Education + PKI cohort, SBL/PLAP for the rest) — segment
each cohort with the pilot/prod groups.

## 2.2 Confirm the chosen approach's objects exist

You do **not** build the tunnel here — you confirm the companion product deployed it.

- **If you chose the device tunnel (A):** confirm `AOVPN – Device Tunnel – ProfileXML – Windows`
  exists and is assigned (deploy it via the companion device-tunnel product if not).
  `PREVPN-Discovery.ps1` flags whether a device-tunnel profile is present.
- **If you chose SBL/PLAP (B):** confirm `Cisco Secure Client – Pre-Logon (SBL) – Win32` exists and is
  assigned (deploy it via the companion SBL/PLAP product if not). `PREVPN-Discovery.ps1` flags whether
  the SBL app is present.

**Gate B (Configure):** The approach is chosen and recorded, the segmentation groups exist, and the
chosen approach's object is present and assigned. Re-run `PREVPN-Discovery.ps1` — the fleet should now
show a pre-logon path for the in-scope devices.

---

# Phase 3 — Pilot

1. Put a **representative** cohort into `PILOT – Pre-Logon First-Logon Users`:
   - at least one **hybrid-joined** device,
   - at least one **domain-joined** device (if you have any),
   - and one **Entra-joined** device as a **control** (to confirm it does *not* need pre-logon).
2. Ensure the chosen approach's object (device-tunnel profile or SBL app) is assigned so the pilot
   devices actually have the pre-logon capability.
3. On a pilot device, confirm the capability landed:
   `powershell -ExecutionPolicy Bypass -File .\scripts\PREVPN-Validation.ps1`
   It reports the join type, whether a pre-logon tunnel exists, the machine cert (if device tunnel),
   and a best-effort DC reachability check.

**Gate C (Pilot):** Every in-scope pilot device shows a pre-logon path present and a DC reachable
through it (`PREVPN-Validation.ps1` = PASS). The Entra-joined control shows *no* pre-logon path and
still signs in — confirming it did not need one. If a pilot device fails, go to `06-troubleshooting.md`.

---

# Phase 4 — Validate (the two decisive scenarios)

These are the tests this product exists for. Run both on the pilot before expanding. Full pass/fail
detail is in `05-testing.md` (T1 and T2).

1. **Scenario 1 — First-time off-network logon.** Take a **freshly provisioned** hybrid/domain-joined
   device with a **user who has never logged on to it**, keep it **off the corporate network**, and
   confirm the **first interactive logon succeeds** because the pre-logon tunnel brought a DC into
   reach (device tunnel auto-up at the logon screen, or the user brings up SBL/PLAP first).
2. **Scenario 2 — Off-network password change.** Take a user whose **password is expired** (or force a
   change), off-network, and confirm they can **change the password at the logon/lock screen** and
   sign in — because the tunnel carried the AD password change to a DC.
3. Run the fleet readiness roll-up to see pilot coverage:
   `powershell -ExecutionPolicy Bypass -File .\scripts\PREVPN-Report.ps1`

**Gate D (Validate):** On the pilot, **both** scenarios PASS on every in-scope join type, and the
Entra-joined control confirms the cloud paths (ordinary logon; SSPR/TAP for password). All Testing
gates are green. Only then expand.

---

# Phase 5 — Expand

1. Add `PROD – Pre-Logon First-Logon Users` to the chosen approach's assignment (via the companion
   product), keeping the pilot group assigned. Ensure only **hybrid/domain-joined** devices are
   targeted — do not push a pre-logon tunnel to Entra-joined devices that don't need it.
2. Expand in waves for large fleets; watch `PREVPN-Report.ps1` between waves for coverage of the
   pre-logon path across in-scope devices.
3. Remediate stragglers with `PREVPN-Remediation.ps1` (defaults to **-WhatIf** preview — it adds
   devices/users lacking a pre-logon path to the pilot group for the chosen approach and prints
   guidance; it does **not** create VPN profiles — that is the companion products' job).
4. Keep the **break-glass fallback** (R8: local admin, TAP, on-network onboarding) documented and
   ready for any device where pre-logon VPN fails.

**Rollback (any phase):** Exclude the target group from the chosen approach's assignment (in the
companion product) and fall back to on-network first onboarding / SSPR / TAP per R8. No VPN profile is
created by this product, so rollback here is purely a targeting/segmentation change.

**Gate E (Expand):** In-scope coverage meets your target (e.g. ≥ 95% of hybrid/domain-joined devices
have a validated pre-logon path); Entra-joined devices are correctly excluded; both scenarios remain
green on spot-checks. The decision is implemented and validated.


---


# Testing & Validation — Pre-Logon VPN: First-Logon & Off-Network Password Reset

Run these tests on the **pilot** before expanding, and spot-check during expansion. Each test has an
explicit **pass/fail gate**. A phase is only "done" when its gate is **PASS**. Object names match the
Implementation guide verbatim. The two decisive scenario tests are **T1 (first-time off-network
logon)** and **T2 (off-network password change)** — this product exists to prove them.

> **Scope note:** these tests validate the **outcome** — that a never-logged-on user and an
> expired-password user can get in from off the network — and that the pre-logon path and DC
> reachability are present. Building the tunnel itself is done in the companion products; deep VPN
> gateway / head-end diagnostics are deferred to those products and the vendor's documentation.

## Test matrix overview

| # | Test | Where | Pass gate |
|---|---|---|---|
| T1 | **First-time off-network logon** | Freshly provisioned pilot device | Never-logged-on user completes first logon off-network |
| T2 | **Off-network password change** | Pilot device, expired password | User changes password at logon/lock screen and signs in |
| T3 | Pre-logon path present | On-device validation script | Tunnel (device tunnel or SBL/PLAP) present |
| T4 | DC reachable through the tunnel | Pilot device | A DC is located/reachable once the tunnel is up |
| T5 | Machine cert present (device tunnel only) | Pilot device | Valid cert in LocalMachine\My, chains to trusted CA |
| T6 | Entra-joined control behaves correctly | Entra-joined device | Signs in with no pre-logon tunnel; SSPR/TAP cover password |
| T7 | Fleet readiness roll-up | Report script | In-scope coverage ≥ target |
| T8 | Break-glass / fallback | Test device | Local admin / TAP / on-network path recovers a failed device |

---

## T1 — First-time off-network logon (the decisive test #1)
**Steps:** Take a **freshly provisioned** hybrid-joined (or domain-joined) device that a specific test
user has **never signed in to** (no cached credential for that user). Keep the device **off the
corporate network** (e.g. home Wi-Fi / hotspot). Attempt the user's **first interactive Windows
logon**:
- **Device tunnel (A):** the machine tunnel should already be up at the logon screen (auto at boot);
  submit the credentials.
- **SBL / PLAP (B):** at the logon screen, use the network/VPN option to bring up
  `Cisco Secure Client – Pre-Logon (SBL) – Win32` first, then submit the credentials.
**PASS:** The first interactive logon **succeeds** off-network — the DC was reachable through the
pre-logon tunnel and validated the never-before-cached user.
**FAIL:** Logon rejected / "no logon servers available" → see Troubleshooting §First logon still fails
(tunnel not up before credential submit, DC not reachable, or wrong approach for the join type).

## T2 — Off-network password change (the decisive test #2)
**Steps:** For a pilot user, **expire the password** (or set "must change at next logon"). Off-network,
have the user reach the **logon/lock screen** and attempt the **password change**:
- **Device tunnel (A):** the machine tunnel is up at the lock screen; change the password.
- **SBL / PLAP (B):** bring up the pre-logon VPN first, then change the password.
**PASS:** The password change **completes** and the user signs in — the AD/Kerberos password change
reached a DC through the tunnel.
**FAIL:** "Unable to change password" / change not accepted → see Troubleshooting §Password change
fails (no DC path, clock skew). Note that **SSPR alone does not** satisfy a hybrid/domain-joined
device's local interactive change — confirm the DC path.

## T3 — Pre-logon path present
**Steps:** On a pilot device run `PREVPN-Validation.ps1`.
**PASS:** The script reports a pre-logon tunnel present — a **device tunnel** (`Get-VpnConnection
-AllUserConnection`) **or** the **SBL/PLAP** credential provider (`vpnplap64.dll`) — matching the
chosen approach.
**FAIL:** No pre-logon capability found → the chosen approach's object is not deployed/assigned; fix
via the companion product, then re-run.

## T4 — DC reachable through the tunnel
**Steps:** With the tunnel up on a pilot device, run `PREVPN-Validation.ps1` (it performs a
best-effort DC check), or manually `nltest /dsgetdc:<domain>` / `Test-NetConnection <dc-fqdn> -Port
389`.
**PASS:** A domain controller is located and reachable through the tunnel.
**FAIL:** No DC found / unreachable → see Troubleshooting §First logon still fails (routes/DNS/firewall
for the DC subnets through the tunnel).

## T5 — Machine certificate present (device-tunnel deployments only)
**Steps:** On a device-tunnel pilot device, confirm a valid machine certificate is in
**LocalMachine\My** and chains to a CA the gateway trusts (`PREVPN-Validation.ps1 -RequireCertificate`).
**PASS:** Certificate present, not expired, correct chain.
**FAIL:** No/invalid cert → the silent tunnel cannot authenticate; fix the machine-cert profile in the
companion device-tunnel product. (Not applicable to SBL/PLAP.)

## T6 — Entra-joined control behaves correctly
**Steps:** On the **Entra-joined** control device, confirm a first sign-in and (if applicable) a
password change work **without** any pre-logon tunnel; confirm SSPR/TAP cover the cloud password path.
**PASS:** The Entra-joined device signs in over ordinary internet with **no** pre-logon path present —
confirming cloud-only devices do not need this deployment.
**FAIL:** If it appears to need a pre-logon tunnel, re-check the join type (`dsregcmd /status`) — it
may actually be hybrid-joined, not Entra-joined.

## T7 — Fleet readiness roll-up
**Steps:** Run `PREVPN-Report.ps1`; review counts by join type and the **coverage %** of in-scope
(hybrid/domain-joined) devices that have a pre-logon path.
**PASS (pilot):** 100% of in-scope pilot devices have a validated pre-logon path.
**PASS (expand):** Coverage ≥ your target (e.g. ≥ 95%) with remaining gaps triaged.
**FAIL:** Coverage below target → remediate with `PREVPN-Remediation.ps1` (adds lacking devices/users
to the pilot group for the chosen approach) before widening.

## T8 — Break-glass / fallback verification
**Steps:** On a disposable test device, simulate a pre-logon failure (e.g. gateway unreachable) and
confirm a recovery path works: **local administrator** logon, **TAP** for a cloud-capable first
sign-in, or bringing the device **on-network** once.
**PASS:** At least one break-glass path recovers the device without stranding the user.
**FAIL:** No fallback works → establish the R8 break-glass path before expanding.

---

## Overall exit criteria (before Expand)
**T1 and T2 PASS** on every in-scope join type, T3–T5 PASS on the pilot, T6 confirms the Entra-joined
control needs no tunnel, T7 shows 100% in-scope pilot coverage, and T8 confirms a working break-glass
path. Record results against each gate; only then proceed to Phase 5 (Expand).


---


# Troubleshooting — Pre-Logon VPN: First-Logon & Off-Network Password Reset

Common failures and fixes, grouped by symptom. Object names match the Implementation guide. Work
top-down within a section — the first cause listed is the most common.

> **Scope boundary:** the pre-logon tunnel itself is built in the **companion products** (device
> tunnel / SBL-PLAP) and gateway/head-end internals are deferred to those products and the vendor's
> official documentation. This guide resolves the **decision + scenario** problems — first-logon,
> off-network password change, join-type confusion, and DC reachability — and tells you when a failure
> points back at the companion build or the network.

---

## §First logon still fails — the never-logged-on user can't sign in off-network

**Symptom:** A freshly provisioned device with a user who has never signed in shows "There are
currently no logon servers available to service the logon request" (or similar) off-network.

1. **Tunnel not up *before* credentials are submitted.** The DC path must exist **at** the credential
   prompt. For the **device tunnel**, confirm it comes up automatically at boot/logon screen
   (`Get-VpnConnection -AllUserConnection` shows it; it must be a **device/machine** tunnel, not a user
   tunnel). For **SBL/PLAP**, the user must bring up the pre-logon VPN at the logon screen **first**,
   then submit credentials — if they type credentials before connecting, there is no DC path yet.
2. **DC not reachable through the tunnel.** Even with the tunnel up, the DC subnets/DNS may not route
   through it. Run `PREVPN-Validation.ps1` (DC check) or `nltest /dsgetdc:<domain>` with the tunnel up.
   Fix routes/split-tunnel and DNS so the DC is reachable, and open the AD ports (DNS 53, Kerberos 88,
   LDAP 389, etc.) from the VPN client range to the DCs (network/companion task).
3. **Wrong approach for the join type.** If the device is **Entra-joined (cloud-only)**, it does **not**
   use an on-prem DC and does not need a pre-logon tunnel — a "failure" here usually means the device
   was mis-identified. Confirm with `dsregcmd /status` (`AzureAdJoined=YES` + `DomainJoined=NO` =
   Entra-joined). If it is genuinely hybrid/domain-joined, ensure the chosen approach's object is
   deployed and assigned.
4. **(Device tunnel) machine cert missing/invalid.** No valid **LocalMachine\My** cert that the gateway
   trusts → the silent tunnel never authenticates, so no DC path at logon. Fix the machine-cert profile
   in the companion device-tunnel product (`PREVPN-Validation.ps1 -RequireCertificate` confirms).
5. **(Device tunnel) OS SKU not Enterprise/Education.** The device tunnel is unsupported on Windows
   Pro/Home. Confirm the SKU (R6) or switch that device to SBL/PLAP.
6. **Cached-credential misunderstanding.** Cached credentials only help a user who has **already**
   signed in on that device. A never-logged-on user has nothing cached and **requires** a live DC path
   — this is expected, not a bug; the fix is the pre-logon tunnel, not cached-credential settings.

## §Password change fails — expired password won't change off-network

**Symptom:** At the logon/lock screen off-network, the user cannot change an expired password
("Unable to update the password. The value provided … does not meet …" is a *policy* error; "no DC"
is a *reachability* error).

1. **No DC path at the moment of change.** The AD password change must reach a DC. Bring the pre-logon
   tunnel up **first** (device tunnel should already be up; SBL/PLAP the user connects first), then
   change the password. Confirm DC reachability with `PREVPN-Validation.ps1`.
2. **Clock skew.** Kerberos rejects password operations when device time is too far from the DC's
   (default tolerance five minutes). Correct the device clock/time zone and retry.
3. **SSPR assumed to be enough (it isn't, for hybrid/domain-joined).** SSPR resets the **directory**
   password in the cloud; with writeback it updates the on-prem directory — but the **local interactive
   change at the Windows lock screen still expects a DC path**. Use SSPR/TAP for the cloud-capable
   paths, but for a hybrid/domain-joined device's lock-screen change, the DC path via the tunnel is
   still required. Validate the real behavior (T2).
4. **Password policy rejection (not a network problem).** If the tunnel and DC are fine but the change
   is refused on complexity/history/age, it is an AD **policy** rejection — the user must pick a
   compliant password; this is not a pre-logon-VPN issue.

## §Entra-joined confusion — "do cloud-only devices need this?"

**Symptom:** Uncertainty about whether an Entra-joined device needs a pre-logon tunnel; or a pre-logon
tunnel was deployed to cloud-only devices unnecessarily.

1. **Entra-joined devices authenticate against the cloud, not a DC.** A first sign-in works over
   ordinary internet and the password lives in Entra — **no pre-logon tunnel is needed**. Cached
   **cloud** credentials (PRT/Web Account Manager) cover subsequent sign-ins.
2. **Confirm the join type before deploying anything.** `dsregcmd /status`: `AzureAdJoined=YES`,
   `DomainJoined=NO`, `EnterpriseJoined=NO` = **Entra-joined**. `DomainJoined=YES` +
   `AzureAdJoined=YES` = **hybrid-joined** (needs a DC path). `PREVPN-Discovery.ps1` reports the mix.
3. **Remove over-deployment.** If a device tunnel/SBL was targeted at Entra-joined devices, exclude
   them from the chosen approach's assignment — they don't need it and it only adds surface/support.
4. **Password path for Entra-joined:** use **SSPR** and **TAP**; there is no on-prem DC dependency.

## §Pre-logon path not present — validation says no tunnel

**Symptom:** `PREVPN-Validation.ps1` reports no device tunnel and no SBL/PLAP provider on a device
that should have one.

1. **Chosen approach's object not deployed/assigned.** Confirm `AOVPN – Device Tunnel – ProfileXML –
   Windows` (device tunnel) or `Cisco Secure Client – Pre-Logon (SBL) – Win32` (SBL) exists and is
   assigned to the device's group — deploy/assign it via the **companion product**.
2. **Device not in the segmentation group.** Confirm the device/user is in `PILOT – Pre-Logon
   First-Logon Users` (or the prod group) so the companion product's assignment reaches it. Use
   `PREVPN-Remediation.ps1` to add lacking devices/users, then sync.
3. **Not yet synced.** Force a sync and allow time for the companion product's profile/app to land,
   then re-run validation.

## §Script / reporting issues

1. **`Connect-MgGraph` fails or lacks scopes.** Install the SDK (`Install-Module Microsoft.Graph
   -Scope CurrentUser`) and consent to the scopes each script lists in its header. Read-only scripts
   need only `.Read.All` scopes. (`PREVPN-Validation.ps1` needs no Graph — it runs locally.)
2. **Join type shows unknown.** `PREVPN-Validation.ps1` parses `dsregcmd /status`; run it in a normal
   user context on the device. `PREVPN-Discovery.ps1` derives join type from Entra device
   `trustType` — a device missing from Entra shows unknown until it registers.
3. **Remediation "made no changes."** By design — it defaults to **-WhatIf**. Re-run with
   `-WhatIf:$false` after reviewing the previewed actions. Remember it only adjusts **group
   membership** for the chosen approach; it never creates VPN profiles.

---

If first-logon or password-change still fails after the decision side is confirmed healthy (right
approach for the join type, pre-logon path present, DC reachable, clock in sync), treat it as a
**companion-product / network / vendor head-end issue** and continue with that product's
troubleshooting and the **vendor's official documentation**.


---


# Best Practices — Pre-Logon VPN: First-Logon & Off-Network Password Reset

Field-proven practices for the decision + scenario + validation layer. These keep the pre-logon
decision defensible, the scenarios reliable, and the fleet free of unnecessary tunnels.

## Decide by join type first
- **Start from the join-type inventory, always.** Run `PREVPN-Discovery.ps1` before deciding anything.
  The first-logon / DC-reachability problem is a **hybrid/domain-joined** problem; deciding without the
  join-type mix leads to over-deploying to cloud-only devices.
- **Never deploy a pre-logon tunnel to Entra-joined (cloud-only) devices.** They authenticate against
  Entra in the cloud; a first sign-in and password change work without an on-prem DC. Use SSPR/TAP for
  their cloud password paths instead.
- **Let the matrix pick the approach, and record why.** Device tunnel for the Enterprise/Education +
  machine-cert + IKEv2 cohort (silent, no user action); SBL/PLAP where you already run Cisco Secure
  Client or can't meet that bar (user-initiated at the logon screen). Write the decision down.

## Keep the three surfaces coherent
- **Reference the companion objects by their exact names.** `AOVPN – Device Tunnel – ProfileXML –
  Windows` and `Cisco Secure Client – Pre-Logon (SBL) – Win32` are created in the companion products —
  never rename or fork them here; this product only decides and validates.
- **Don't rebuild the tunnel in this layer.** If you find yourself editing a ProfileXML or the SBL
  module, you're in the wrong product — do that work in the companion product so the build stays in one
  place.
- **Segment cohorts cleanly.** Use `PILOT – Pre-Logon First-Logon Users` and `PROD – Pre-Logon
  First-Logon Users` to stage validation and expansion; keep the pilot group assigned after expansion
  as a fast test cohort.

## Validate the scenarios, not just the plumbing
- **Always run T1 and T2 end to end on the pilot.** A tunnel that "exists" is not proof — prove that a
  **never-logged-on** user completes first logon off-network and that an **expired-password** user can
  change it at the lock screen. These two tests are the whole point.
- **Include an Entra-joined control in the pilot.** Confirm it signs in with **no** pre-logon path — it
  is your evidence that cloud-only devices don't need this deployment.
- **Confirm DC reachability separately.** The tunnel coming up and a DC being reachable through it are
  two different things — validate both (T3 and T4).

## Certificates and SKU (device tunnel)
- **Verify the machine cert and SKU before promising a silent tunnel.** The device tunnel is silent
  only when a valid **LocalMachine\My** machine certificate exists and the device is
  **Enterprise/Education**. Confirm both (T5/R6) or route those devices to SBL/PLAP.
- **Watch machine-cert lifetime.** A lapsed machine cert silently breaks the pre-logon tunnel — monitor
  renewal in the companion product so devices never lose the DC path at logon.

## SSPR is a complement, not a replacement
- **Enable SSPR/TAP for the cloud-capable paths**, but do not assume they remove the DC-path
  requirement for a **hybrid/domain-joined** device's lock-screen password change. Document exactly
  where SSPR helps (Entra-joined; directory reset via writeback) and where the DC path is still needed.

## Break-glass, always ready
- **Keep a documented fallback for every stranded-user case:** local administrator recovery, a
  **Temporary Access Pass** for cloud-capable first sign-in, and a "bring it on-network once" path.
  Test the fallback (T8) before you need it.
- **Onboard the very first device on a known network when in doubt.** For a brand-new hire, a single
  first logon on a trusted network primes the cached credential and removes the off-network first-logon
  risk entirely — a pragmatic fallback when pre-logon VPN isn't ready.

## Operate and monitor
- **Run `PREVPN-Report.ps1` on a schedule** to track pre-logon coverage of in-scope devices as the
  fleet changes, and to catch cloud-only devices that were targeted by mistake.
- **Remediate safely.** `PREVPN-Remediation.ps1` defaults to **-WhatIf** and only adjusts **group
  membership** for the chosen approach — it never creates VPN profiles. Preview first, then re-run with
  `-WhatIf:$false`.
- **Least-privilege admin.** Groups Administrator + Intune Administrator for the operator; reserve
  Global Administrator for tenant-wide changes only.


---


# Deliverables Summary — Pre-Logon VPN: First-Logon & Off-Network Password Reset

This solution is a complete, self-guided **decision + scenario + validation** package for pre-logon
VPN — it helps you **choose** the right approach (Always On VPN device tunnel vs. Cisco Secure Client
SBL/PLAP) for your fleet, explains the **two hard scenarios** by device join type, and **validates**
them end to end. It **references** the two deployment products by their object names but does not
re-teach their builds. Below is everything included.

## Documentation set (source/)

| Document | What it gives you |
|---|---|
| `01-solution-overview.md` | The problem (no cached creds for first logon; expired password can't reach a DC), the two approaches, the decision matrix, why join type is the whole story, both scenarios, break-glass, and the Assess→Configure→Pilot→Validate→Expand model. |
| `02-requirements.md` | Every prerequisite with **Description / Why / Verify / Implement-if-missing** — a chosen/deployed approach (or the companion product), segmentation groups, join-type inventory, DC reachability, machine cert + SKU (device tunnel only), optional SSPR, break-glass accounts. |
| `03-implementation.md` | The ordered procedure: run readiness, **choose the approach via the decision matrix**, segment the pilot, confirm the chosen companion object, then **validate the two scenarios** — with Gates A–E framed around scenario validation. Includes the decision matrix as a table. |
| `05-testing.md` | The validation matrix (T1–T8) with explicit **PASS/FAIL** gates — the two decisive scenario tests (first-time off-network logon; off-network password change) plus pre-logon-path, DC-reachability, machine-cert, Entra-joined-control, coverage, and break-glass tests. |
| `06-troubleshooting.md` | Failure-by-symptom fixes: first logon still fails, password change fails, Entra-joined confusion, pre-logon path not present, script/reporting issues. |
| `07-best-practices.md` | Field-proven practices for deciding by join type, keeping the three surfaces coherent, validating scenarios not plumbing, certs/SKU, SSPR as a complement, and break-glass. |
| `executive-summary.md` | One-page business-outcome summary for stakeholders. |
| `global-requirements-network.md` | Category-level Network prerequisites (shared across Network solutions). |

## PowerShell scripts (scripts/)

Discovery/report use the **Microsoft Graph PowerShell SDK** (read-only); validation runs **locally on
a device** (no Graph); remediation and scope-targeting **default to `-WhatIf` (preview)** and change
nothing until you re-run with `-WhatIf:$false`. Each script's header documents its exact purpose, run
command, and required Graph scopes.

| Script | Purpose | Mode |
|---|---|---|
| `PREVPN-Discovery.ps1` | Fleet readiness: reports device **join types** (hybrid / domain-joined / Entra-joined), presence of a pre-logon capability (a device-tunnel ProfileXML profile **or** the SBL Win32 app), and pilot/prod group membership; recommends which approach fits the fleet. | Read-only |
| `PREVPN-Validation.ps1` | **On this device:** detects join type (`dsregcmd /status`), whether a pre-logon tunnel exists (device tunnel via `Get-VpnConnection -AllUserConnection` **or** PLAP `vpnplap64.dll`), the machine cert (LocalMachine\My), and a best-effort **DC reachability** check. PASS = pre-logon capability present AND a DC reachable. | Read-only (local) |
| `PREVPN-Report.ps1` | Fleet readiness roll-up — counts by join type and by pre-logon capability present/absent, with a **coverage %** of in-scope devices that have a pre-logon path. | Read-only |
| `PREVPN-Remediation.ps1` | Safely adds devices/users lacking a pre-logon path to the pilot group for the chosen approach and prints guidance. **Does NOT create VPN profiles** (that's the companion products). | Write, **default `-WhatIf`** |
| `PREVPN-Set-ScopeTargeting.ps1` | Creates/populates `PILOT – Pre-Logon First-Logon Users` (and optional PROD) as assignable security groups. Idempotent. | Write, **default `-WhatIf`** |

## The consistent object naming convention

Every artifact is named to a convention and reused verbatim across docs, tests, troubleshooting, and
scripts (so the scripts find objects deterministically):

- Segmentation groups: `PILOT – Pre-Logon First-Logon Users`, `PROD – Pre-Logon First-Logon Users`
- Referenced (created in companion products): the device-tunnel profile `AOVPN – Device Tunnel –
  ProfileXML – Windows` and the SBL app `Cisco Secure Client – Pre-Logon (SBL) – Win32`

## Scope boundary (what is deferred)

This is the **decision + scenario + validation** layer. The **step-by-step device-tunnel and SBL/PLAP
builds live in their companion products** and, with IKEv2/ProfileXML and Cisco head-end internals, are
**deferred to those products and the vendor's official documentation**. This solution chooses between
the two approaches, explains and validates the two scenarios by join type, and reports fleet readiness
— it consumes the companion products' objects rather than recreating them.
