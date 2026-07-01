# Migrating Cisco VPN Client Deployment from SCCM/GPO to Intune

> **Version 1.0.0** · Category: Migrations · Solution code: CVPNMIG

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary — Migrating Cisco VPN Client Deployment from SCCM/GPO to Intune

**Workplace Marketplace · Migrations**

Many organizations still push the **Cisco Secure Client (AnyConnect)** and its VPN profile through
**Configuration Manager (SCCM) packages** and **Group Policy** — on-prem plumbing that assumes a
domain-joined device on the corporate network and breaks for remote and cloud-managed endpoints. Moving
that delivery to **Microsoft Intune** means every piece — the client install, the VPN connection
profile, and the certificate the VPN authenticates with — has to be rebuilt in Intune and validated so
nobody loses their VPN mid-migration. Done by hand it is slow and risky: the classic failure is a
**double-deployment conflict** where SCCM/GPO and Intune fight over the same client, causing reinstall
loops or a profile that flip-flops.

This is a complete, deploy-it-today package for migrating the Cisco VPN client deployment from SCCM/GPO
to Intune, written for an administrator carrying out the move without prior migration experience.

## What you get
- A plain-language Solution Overview of how the SCCM/GPO delivery maps to Intune, the rebuild-and-
  validate model, coexistence, ringed wave cutover, and — critically — how to keep exactly one delivery
  authority per device so the two paths never conflict.
- A Requirements Guide with verify / implement-if-missing for every prerequisite.
- An Implementation Guide of precise, ordered steps: inventory the SCCM package and GPO(s), rebuild the
  client as a Win32 app, deliver the VPN profile and the SCEP/PKCS certificate, pilot, validate the
  tunnel, cut over wave by wave, and retire the SCCM package and GPOs.
- Five PowerShell scripts for current-state discovery, per-device migration validation, a fleet
  legacy-vs-Intune progress report, safe legacy cleanup, and the wave-group builder.
- Testing and Troubleshooting guides with explicit parity, no-conflict, and legacy-gone gates.

## What this delivers
A repeatable inventory → rebuild → validate loop: the Cisco client, VPN profile, and certificate become
Intune-delivered with parity; SCCM/GPO keep working during coexistence; each device moves to Intune only
as its legacy delivery is removed; and the SCCM package and GPOs are retired ring by ring only after
Intune is proven.

## Vendor boundary
The Cisco Secure Client installer, the VPN profile XML schema, the head-end (ASA/Firepower), and ISE
posture are configured per **Cisco's official documentation**. This solution rebuilds *delivery* in
Intune at exact click-by-click detail and defers the Cisco product's own internals to the vendor.

## The deployment model
**Assess → Configure → Pilot → Validate → Expand → Retire legacy.**

## Outcome
Your Cisco VPN client, profile, and certificate delivered from Intune instead of SCCM/GPO — migrated
wave by wave, validated for parity, and proven on a pilot before you retire the legacy path — with the
VPN never going dark and no device ever double-managed.


---


# 1. Solution Overview — Migrating Cisco VPN Client Deployment from SCCM/GPO to Intune

## What this migration is
Many fleets still deliver the **Cisco Secure Client (AnyConnect)** and its VPN connection profile
through **Configuration Manager (SCCM/MECM) packages** and **Group Policy (GPO)** — on-prem plumbing
that assumes a domain-joined device on (or VPN-tunnelled back to) the corporate network. That model
breaks for remote, cloud-managed, and Entra-joined devices. This solution is the disciplined
migration that re-homes three things to **Microsoft Intune**:

1. the **Secure Client install** (today an SCCM package/application or a GPO software-install),
2. the **VPN connection profile** (today the AnyConnect profile XML delivered by SCCM or a GPO), and
3. any **certificate delivery** the VPN depends on (today an Active Directory Certificate Services
   auto-enrolment GPO or an SCCM step),

so the same client and the same VPN profile land on the same devices — delivered from the cloud,
without anyone losing their VPN mid-move.

> **Vendor boundary.** The internals of the Cisco Secure Client / AnyConnect installer, the VPN
> **head-end** (ASA / Firepower / Secure Firewall), and Cisco ISE posture are **Cisco's domain**.
> This solution authors the **Intune / Entra / SCCM / GPO / certificate** side at exact click-by-click
> detail and treats the Cisco client build and head-end configuration at the architectural level,
> pointing to Cisco's official documentation for the product's own menus and profile-editor internals.

## Why this is its own project (not net-new deployment)
Deploying the client fresh into Intune is a blank slate. Migrating an SCCM/GPO estate is not: a working
client version, a specific profile XML (server list, protocols, split-tunnel rules), and a certificate
chain already exist and are relied on daily. The work here is to **inventory** exactly what SCCM and
GPO deliver today, **rebuild** each of those pieces in Intune with parity, run **both paths side by
side (coexistence)** while you cut over wave by wave — critically **avoiding a double-deployment
conflict** where SCCM/GPO and Intune both try to install or configure the client at once — **validate**
that the VPN still connects, and only then **retire** the legacy SCCM package and GPO. The value is
parity and proof, at fleet scale, with the VPN never going dark.

## How it works
1. **Assess (inventory).** Discover, per device and centrally, how the Secure Client and its VPN
   profile arrive today: the SCCM package/application + collection, the GPO(s) that install the client
   and/or drop the profile XML, and the certificate-enrolment GPO/template. Capture the installed
   client **version**, the **profile XML**, and the **certificate** the profile uses.
2. **Configure (rebuild in Intune).** Package the Cisco-provided Secure Client installer as an Intune
   **Win32 app**, deliver the **VPN profile** (the Cisco profile XML, delivered as configuration), and
   deliver the **client certificate** via an Intune **SCEP/PKCS** certificate profile.
3. **Pilot.** Assign the rebuilt client + profile + cert to a small named wave group and prove the VPN
   connects from an Intune-only path.
4. **Validate (parity).** Confirm the Intune-delivered client version, profile, and certificate match
   the legacy path and the tunnel establishes — pass/fail gate.
5. **Expand (wave cutover).** Migrate wave by wave. For each wave, **remove that wave from the legacy
   delivery as you add it to the Intune delivery** so only one authority manages the client at a time.
6. **Retire legacy.** Once all waves are on Intune and validated, retire the SCCM package/deployment
   and unlink the GPO(s).

## Avoiding double-deployment conflicts (the core risk)
The failure mode of this migration is **two authorities managing one client**: SCCM/GPO reinstalling or
re-writing the profile while Intune does the same, causing reinstall loops, a profile that flip-flops,
or a version tug-of-war. The rule that prevents it:

- **A device is managed by exactly one path at a time.** When you add a device (wave) to the Intune
  delivery, you **remove it from the SCCM collection and move it out of the GPO scope** (security-group
  filter or OU) in the same change — never leave both live for the same device beyond the brief
  validation overlap.
- **Coexistence is fleet-wide, not device-wide.** During transition the *fleet* runs both paths (some
  waves legacy, some Intune), but any single *device* is only ever on one.
- **Match versions and profile content** so that even a momentary overlap is a no-op rather than a
  fight (same client version, byte-identical profile XML).

## What maps to what (SCCM/GPO → Intune)
- Cisco Secure Client **install** (SCCM package/application, or GPO software-install/startup script)
  → Intune **Win32 app** (`.intunewin` wrapping the Cisco installer).
- **VPN profile XML** (SCCM script/package that drops the `.xml`, or a GPO file/preference)
  → Intune-delivered **VPN profile** (the Cisco profile XML delivered as configuration to the client's
  profile directory).
- **Client certificate** (AD CS auto-enrolment GPO / certificate template, or an SCCM step)
  → Intune **SCEP** (or **PKCS**) certificate profile bound to the VPN.
- **Deployment to an SCCM collection / GPO-linked OU** → **assignment** to an Entra **wave group**.
- **Trusted root / issuing CA** (GPO-distributed) → Intune **Trusted certificate** profile.

## What you can control
- Which Cisco-provided client **version** is authoritative for the migration.
- The **profile XML** delivered (identical to legacy, or an updated head-end list) — one source of truth.
- **Certificate delivery** method (SCEP vs PKCS) and the template it maps to.
- **Wave size and order** of cutover, and the coexistence window per wave.
- The **rollback** point per wave (re-add to the SCCM collection / GPO scope).

## Benefits
- The VPN client and profile delivered from the cloud — works for remote and Entra-joined devices.
- No lost connectivity — each device keeps a working VPN across the move (coexistence + parity gate).
- No double-deployment conflict — one authority per device, enforced at cutover.
- Repeatable — the same inventory → rebuild → validate loop runs for every wave.
- Auditable — a progress report proves how much of the fleet is Intune-managed vs still legacy.

## Limitations (be honest with buyers)
- The Cisco Secure Client installer, its command-line switches, the profile XML schema, the VPN
  head-end (ASA/Firepower), and ISE posture are **Cisco's** — this solution rebuilds *delivery* in
  Intune but defers the product's own configuration to Cisco's documentation.
- Intune wraps and delivers the Cisco installer; it does not fix a broken installer or an invalid
  profile — the Cisco-provided source must already work.
- Certificate parity is exact work: the Intune SCEP/PKCS profile must issue a certificate the head-end
  accepts (same template, EKUs, subject/SAN) — validate before cutover.
- SCCM/GPO and Intune must not both enforce the client on the same device; coexistence is per-fleet,
  and each device moves to Intune only as its legacy delivery is removed.

## The standard deployment model
> Inventory the SCCM/GPO client + profile + cert delivery → rebuild the client (Win32), VPN profile,
> and certificate in Intune with parity → assign to a pilot wave → validate the tunnel connects →
> expand wave by wave, removing each wave from the legacy path as it joins Intune → retire the SCCM
> package and unlink the GPO. Pattern: **Assess → Configure → Pilot → Validate → Expand → Retire legacy.**


---


# 2. Requirements Guide — Migrating Cisco VPN Client Deployment from SCCM/GPO to Intune

Verify **every** requirement before you rebuild anything in Intune. Each entry:
**Description · Why · Verify · Implement-if-missing.** Category-wide prerequisites (target Entra
tenant, Intune licensing, source access, inventory, enrollment, pilot/waves, change control) are in
`global-requirements-migrations.md` and are assumed here.

> **Vendor boundary:** the Cisco Secure Client installer, its VPN profile XML schema, the VPN head-end
> (ASA/Firepower/Secure Firewall), and ISE posture are configured per **Cisco's documentation**. This
> guide covers what you need on the **Intune / Entra / SCCM / GPO / certificate** side.

## 2.1 Intune enrollment and admin rights (target)
Description: Devices enrolled in Intune, an Intune-bearing license plan, and the roles to create apps,
VPN profiles, and certificate profiles.
Why: You cannot deliver the client, profile, or certificate from Intune to unenrolled devices, or build
those objects without rights.
Verify: `https://intune.microsoft.com` loads; **Devices** shows the in-scope devices as enrolled; you
hold **Intune Administrator**; **Apps → Windows** and **Devices → Configuration** are reachable.
Implement: Assign M365 E3/E5, Business Premium, or Intune Plan 1; enable Windows automatic enrolment
(global requirement G5); grant least-privilege admin roles.

## 2.2 The Cisco Secure Client installer (from Cisco)
Description: The Cisco-provided Secure Client (AnyConnect) installer media and its **silent install
command line**, at the version you are standardizing on.
Why: Intune wraps this exact installer into a Win32 app; without clean Cisco media and known switches
you cannot rebuild the install.
Verify: `CVPNMIG-Discovery.ps1` reports the installed client version on sample devices; you have the
matching installer and a documented silent command from Cisco.
Implement: Obtain the installer and command line from Cisco's official download/documentation; confirm
it installs silently on a clean test device. (Installer internals and switches are per Cisco docs.)

## 2.3 The current VPN profile XML (source of truth)
Description: The AnyConnect / Secure Client **VPN profile XML** delivered today (server/head-end list,
protocol, split-tunnel, and connection settings).
Why: Intune must deliver a profile with parity so the tunnel behaves identically after the move.
Verify: `CVPNMIG-Discovery.ps1` locates the profile XML in the client profile directory on a sample
device; you can open it and read the head-end list.
Implement: Recover the authoritative profile XML from the SCCM package/source share, the GPO that
drops it, or the Cisco profile editor; treat one copy as the single source of truth for the migration.

## 2.4 The current SCCM/GPO deployment details (source)
Description: Exactly how the client and profile arrive today — the SCCM **package/application +
deployment + target collection**, and/or the **GPO(s)** that install the client, drop the profile XML,
and their linked OUs / security-group filters.
Why: You must know each legacy delivery mechanism to rebuild it in Intune *and* to remove it cleanly at
cutover so the two paths never conflict.
Verify: In the Configuration Manager console, `Software Library → Application Management` shows the app/
package and its deployment; in **Group Policy Management** you can identify the GPO(s), their links,
and scope; `CVPNMIG-Discovery.ps1` flags SCCM- and GPO-delivered artifacts on a device.
Implement: Obtain Configuration Manager **read** access and **Group Policy Management** read access
(global requirement G3); document each mechanism and its scope before migrating.

## 2.5 Certificate delivery for the VPN
Description: How the VPN **client certificate** and its **trusted root / issuing CA** reach devices
today (typically AD CS auto-enrolment via GPO and a certificate template), and the target Intune
**SCEP** (or **PKCS**) delivery.
Why: If the VPN authenticates with a certificate, the Intune-issued certificate must be one the head-end
accepts — same template intent (subject/SAN, EKUs, key usage).
Verify: On a sample device, `CVPNMIG-Discovery.ps1` reports the VPN client certificate (issuer,
template, EKUs) in the user/computer store; in Intune, a **Certificate connector** (for SCEP/PKCS) shows
**Active** under **Tenant administration → Connectors and tokens**.
Implement: Stand up the Intune Certificate connector and an SCEP/PKCS **certificate profile** plus a
**Trusted certificate** profile for the root, mapped to the same template intent as the legacy AD CS
template. (NDES/SCEP setup follows Microsoft documentation.)

## 2.6 Entra wave groups and a pilot group
Description: Microsoft Entra security groups for the migration **pilot wave** and subsequent **waves**,
used to assign the Intune client + profile + cert.
Why: Every wave is piloted and validated before the next; assignment is by group so cutover is
controlled and reversible.
Verify: Entra → **Groups** shows the pilot/wave groups; `CVPNMIG-Set-ScopeTargeting.ps1` can create/
populate them.
Implement: Create the groups (or run `CVPNMIG-Set-ScopeTargeting.ps1`); name the first
`PILOT – VPN Migration Wave 1` (see Implementation for the full naming set).

## 2.7 Coexistence and rollback plan
Description: A written plan for running SCCM/GPO and Intune side by side **per fleet** while keeping any
single device on **one** path, plus a documented rollback (re-add the wave to the SCCM collection and
GPO scope).
Why: Migrations touch live production VPN; cutover must be reversible and must never double-manage a
device (global requirement G7).
Verify: The coexistence rule ("a device leaves the legacy scope in the same change it joins the Intune
wave") and the rollback steps are written and approved before any cutover.
Implement: Document the per-wave order of operations (add to Intune wave → remove from SCCM collection →
move out of GPO scope) and the reverse for rollback.

---
## Checklist
- [ ] Intune enrolment + Intune Administrator — Apps/Configuration reachable
- [ ] Cisco Secure Client installer + silent command (from Cisco)
- [ ] Current VPN profile XML recovered (single source of truth)
- [ ] SCCM package/deployment + GPO(s) and their scope documented
- [ ] Certificate delivery mapped; Intune Certificate connector Active; SCEP/PKCS + Trusted-root planned
- [ ] Entra pilot/wave groups exist (`PILOT – VPN Migration Wave 1`)
- [ ] Coexistence + rollback plan written (one authority per device)


---


# Global Requirements — Migrations (category-level)

These requirements apply to **every** solution in the **Migrations** category (platform-to-platform
migration programs — e.g. Workspace ONE → Microsoft Intune, Configuration Manager → Intune, Group
Policy → Intune, Exchange/Microsoft 365 tenant moves). They are published once at the category level
so individual listings stay small. Confirm these before running *any* Migrations solution. Each entry:
**Description · Why · Verify · Implement-if-missing.**

## G1. Target Microsoft Entra ID tenant
**Description:** An active, correctly-configured Microsoft Entra ID (Azure AD) tenant — the migration target's identity backbone.
**Why:** Every modern endpoint/identity workload binds to Entra ID; users and devices must resolve there before migration.
**Verify:** Sign in to `https://entra.microsoft.com` as an administrator.
**Implement:** Create/confirm the Microsoft 365 / Azure subscription that provisions the tenant.

## G2. Target platform licensing & admin access (Intune)
**Description:** An Intune-bearing license plan and the admin roles to build/assign policies and apps in the target.
**Why:** You can't rebuild apps, profiles, or enrollment in the target without licensing and rights.
**Verify:** `https://intune.microsoft.com` loads; **Tenant administration → Tenant status** active; you hold **Intune Administrator**.
**Implement:** Assign Microsoft 365 E3/E5, Business Premium, or standalone Intune Plan 1; grant least-privilege admin roles.

## G3. Access to the SOURCE platform
**Description:** Administrative read (and, for cutover, change) access to the platform you are migrating *from* (e.g. Workspace ONE UEM, Configuration Manager, Active Directory, the source tenant).
**Why:** Migration begins by inventorying and exporting the source's apps, profiles, policies, and device assignments.
**Verify:** You can sign in to the source console and export/inventory its configuration for a sample.
**Implement:** Obtain the source admin role / API credentials from the platform owner.

## G4. A current inventory / source of truth
**Description:** An accurate inventory of in-scope devices, users, apps, and policies on the source platform.
**Why:** Wave planning, parity validation, and decommission all depend on knowing exactly what is in scope.
**Verify:** You can produce a device/app/policy export from the source for the migration scope.
**Implement:** Build the inventory from the source console / discovery before scoping waves.

## G5. Enrollment prerequisites for the target
**Description:** The enrollment plumbing for each in-scope platform — e.g. Apple MDM Push (APNs) certificate and Apple Business Manager for iOS/iPadOS/macOS, managed Google Play for Android, automatic enrollment for Windows.
**Why:** Devices cannot move to the target MDM until its enrollment channels are live.
**Verify:** In Intune, the relevant connector/cert/token shows **Active** for each platform in scope.
**Implement:** Configure the APNs certificate, ABM/ADE token, managed Google Play, and Windows automatic enrollment as needed.

## G6. A pilot group and wave structure
**Description:** A Microsoft Entra security group for the pilot, and a planned set of migration waves/rings.
**Why:** Every migration is piloted and ringed before fleet cutover to contain risk.
**Verify:** Entra → **Groups**; the pilot group exists and the wave plan is documented.
**Implement:** Entra → **Groups → New group → Security**; define waves by department/region/device type.

## G7. Change control, coexistence, and a rollback path
**Description:** A change window, a defined coexistence approach (both platforms managed during transition), and a documented rollback (re-enroll to source / revert assignment).
**Why:** Migrations touch live, enrolled production devices; cutover must be reversible and coordinated.
**Verify:** A rollback procedure and coexistence plan are written and approved before any cutover.
**Implement:** Define rollback per platform, a comms plan, and the order of operations for coexistence → cutover → decommission.

---
**The standard deployment model (all solutions):** **Assess → Configure → Pilot → Validate → Expand.**


---


# 3. Implementation Guide — Migrating Cisco VPN Client Deployment from SCCM/GPO to Intune

Follow these steps **in order**. Inventory (Step 1) runs against the **Configuration Manager console**
(`Software Library → Application Management`) and **Group Policy Management**. Everything on the target
side is in the **Microsoft Intune admin center** (`https://intune.microsoft.com`) and **Microsoft
Entra** (`https://entra.microsoft.com`).

> **Model:** Inventory the SCCM/GPO client + profile + cert delivery, rebuild each in Intune with
> parity, assign to a pilot wave, validate the tunnel, then expand wave by wave — removing each wave
> from the legacy path as it joins Intune — and finally retire the SCCM package and unlink the GPO. The
> pilot wave is the gate; a device is only ever on **one** delivery path at a time (no double-deploy).

> **Vendor boundary:** the Cisco Secure Client installer/switches, the VPN profile XML schema, and the
> head-end (ASA/Firepower) are configured per **Cisco documentation**. Steps below cover Intune/Entra/
> SCCM/GPO/certificate actions at exact detail and reference the Cisco-provided artifacts by role.

## Named objects (reuse these names verbatim everywhere)
We name every object so it is self-describing and searchable.

| Object | Name to create |
|---|---|
| Pilot wave group | `PILOT – VPN Migration Wave 1` |
| Later wave group (example) | `VPN Migration – Wave 2` |
| Intune Win32 app (client) | `Cisco Secure Client – Win32` |
| Intune VPN profile | `Cisco VPN – Profile` |
| Intune SCEP certificate profile | `Cisco VPN – Client Cert (SCEP)` |
| Intune Trusted certificate profile | `Cisco VPN – Trusted Root CA` |

## Step 1 — Assess: inventory the legacy delivery
1. **SCCM:** In the Configuration Manager console, `Software Library → Application Management →
   Applications` (or `Packages`). Identify the Cisco Secure Client app/package, its **deployment**, and
   the **target collection**. Note the install command and content source.
2. **GPO:** In **Group Policy Management**, find the GPO(s) that (a) install the client (software-install
   or startup script), (b) drop the **VPN profile XML**, and (c) auto-enrol the **VPN certificate** (AD
   CS auto-enrolment + template). Record each GPO's **links (OUs)** and **security-group filtering**.
3. **Device-level:** Run `CVPNMIG-Discovery.ps1` on sample devices to capture the installed **client
   version**, the **profile XML** path/content, and the **VPN certificate** (issuer/template/EKUs), and
   to flag whether each artifact came from SCCM or GPO.
4. Confirm you now hold: the Cisco installer + silent command (Req 2.2), the authoritative profile XML
   (Req 2.3), the legacy mechanisms + scope (Req 2.4), and the certificate mapping (Req 2.5).

## Step 2 — Plan waves
1. Group in-scope devices into waves (start small: a pilot wave of representative devices that use the
   VPN daily). Record the wave order.
2. Decide the coexistence rule up front: **each device leaves the SCCM collection and the GPO scope in
   the same change it is added to its Intune wave** (Req 2.7). Never both, per device.

## Step 3 — Create the wave groups
1. Entra → **Groups → New group → Security** → name `PILOT – VPN Migration Wave 1`; add the pilot
   devices. **Create**.
2. Create later wave groups (e.g. `VPN Migration – Wave 2`) as needed. (Or run
   `CVPNMIG-Set-ScopeTargeting.ps1`.)

## Step 4 — Configure: package the client as an Intune Win32 app
1. On a packaging workstation, wrap the **Cisco-provided** Secure Client installer into an
   `.intunewin` with the Microsoft Win32 Content Prep Tool. (Installer switches per Cisco docs.)
2. Intune → **Apps → Windows → Add** → app type `Windows app (Win32)` → **Select**.
3. Upload the `.intunewin`. **App information:** `Name` = `Cisco Secure Client – Win32`; set
   `Publisher` = `Cisco` and a short description. **Next**.
4. **Program:** set the **Install command** and **Uninstall command** from Cisco's silent switches;
   `Install behavior` = `System`. **Next**.
5. **Requirements:** OS architecture `64-bit`, a minimum OS floor. **Next**.
6. **Detection rules:** `Manually configure` → add a rule proving the client is installed (e.g. the
   Secure Client MSI product code, or the client `.exe` file+version, or its uninstall registry key —
   use the evidence captured in Step 1). **Next**.
7. Do **not** assign yet. **Review + create → Create.** (Assignment is Step 8.)

## Step 5 — Configure: deliver the VPN profile
1. Take the authoritative **profile XML** from Step 1 (single source of truth).
2. Deliver it from Intune so it lands in the Secure Client profile directory on the device, named
   `Cisco VPN – Profile`. Two supported approaches (pick one and use it consistently):
   - **Win32/packaged delivery:** wrap the profile XML in a small Win32 app or add it to the client
     package so it is written to the profile directory (the same location the legacy SCCM/GPO delivery
     used — confirm the path from Step 1).
   - **Custom configuration profile:** deliver the profile via **Devices → Configuration → Create →
     Windows → Templates** as a configuration payload that writes the profile.
3. Ensure the delivered XML is **byte-identical** to the legacy profile so an overlap is a no-op.
   (Profile XML schema and any edits are per Cisco docs.) Do **not** assign yet.

## Step 6 — Configure: deliver the VPN certificate
1. Confirm the Intune **Certificate connector** is **Active** (Req 2.5).
2. Create the **Trusted certificate** profile `Cisco VPN – Trusted Root CA`: Intune → **Devices →
   Configuration → Create → Windows → Templates → Trusted certificate** → upload the root/issuing CA.
   Do not assign yet.
3. Create the **SCEP** profile `Cisco VPN – Client Cert (SCEP)`: **Templates → SCEP certificate** →
   set `Certificate type`, `Subject name format` and `SAN` to match the legacy AD CS template intent,
   the correct **EKUs** (e.g. Client Authentication), key usage, and the SCEP URI. Reference the Trusted
   root above. Do not assign yet. (Use **PKCS** instead if that matches your PKI.)

## Step 7 — Bind the certificate to the VPN profile
1. Ensure the `Cisco VPN – Profile` delivery references (or the client is configured to use) the
   certificate issued by `Cisco VPN – Client Cert (SCEP)` for authentication, matching how the legacy
   profile selected its certificate. (Certificate-matching behavior in the profile is per Cisco docs;
   the **certificate delivery** is the Intune SCEP profile above.)

## Step 8 — Pilot: assign the four objects to Wave 1
Assign all four to `PILOT – VPN Migration Wave 1` so a pilot device gets a complete Intune-delivered
VPN:
1. `Cisco Secure Client – Win32` → **Assignments → Required → Add group →** `PILOT – VPN Migration
   Wave 1`.
2. `Cisco VPN – Trusted Root CA` → assign to the wave group.
3. `Cisco VPN – Client Cert (SCEP)` → assign to the wave group.
4. `Cisco VPN – Profile` → assign to the wave group.
5. **Coexistence guard:** the pilot devices are still in the SCCM collection / GPO scope at this moment
   — this is the brief validation overlap only. Because the client version and profile XML match, the
   overlap is a no-op. Proceed straight to validation, then remove them from legacy in Step 10.

## Step 9 — Validate parity on the pilot (gate)
1. On a pilot device, sync policy (**Settings → Accounts → Access work or school → Info → Sync**).
2. Run `CVPNMIG-Validation.ps1` to confirm the **Intune-delivered** client version, profile, and
   certificate are present and the **tunnel establishes**. Complete the **Testing Guide**.
3. Run `CVPNMIG-Report.ps1` to confirm the wave shows Intune-managed.
4. **Gate:** the wave passes only when the Intune-delivered client + profile + cert are present and the
   VPN connects. If it fails, fix and re-validate — the legacy path is still live so the VPN never
   drops.

## Step 10 — Cut over Wave 1 (remove from legacy — no double-deploy)
Only after the pilot passes, remove the pilot devices from the **legacy** delivery so the device is on
Intune alone:
1. **SCCM:** remove the pilot devices/collection from the Cisco Secure Client **deployment** (or remove
   them from the target collection). Confirm SCCM no longer targets them.
2. **GPO:** move the pilot devices out of the GPO scope — either remove them from the security group the
   GPO is filtered to, or move their computer objects out of the linked OU. Confirm the client-install,
   profile, and cert-enrolment GPOs no longer apply (`gpresult`).
3. Re-run `CVPNMIG-Discovery.ps1` on a pilot device and confirm the artifacts now show **Intune** as the
   only source (no SCCM/GPO tags).

## Step 11 — Expand: repeat per wave
For each subsequent wave (`VPN Migration – Wave 2`, …):
1. Add the wave group to the four objects' **Assignments** (Steps 8.1–8.4).
2. Validate the wave (Step 9).
3. Cut it over — remove that wave from the SCCM collection and GPO scope (Step 10).
4. Re-run `CVPNMIG-Report.ps1` each cycle to track legacy-vs-Intune coverage; chase laggards with
   `CVPNMIG-Remediation.ps1` (default `-WhatIf`).

## Step 12 — Retire the legacy delivery
Once **all** waves are Intune-managed and validated:
1. **SCCM:** delete/retire the Cisco Secure Client **deployment**, then the package/application and its
   now-empty collection.
2. **GPO:** unlink (then delete, per change control) the GPO(s) that installed the client, dropped the
   profile XML, and auto-enrolled the VPN certificate. Confirm no device still receives them
   (`gpresult`).
3. Run `CVPNMIG-Report.ps1` for a final sweep — **100% Intune-managed, zero legacy artifacts** — and
   spot-check with `CVPNMIG-Discovery.ps1`.

---
### Order of operations
`Inventory SCCM package + GPO(s) + device state → plan waves → wave groups → package client (Win32) →
deliver profile → deliver cert (Trusted root + SCEP) → bind cert to profile → assign pilot (brief
overlap) → validate tunnel → remove pilot from SCCM + GPO (cutover) → expand wave by wave →
retire SCCM package + unlink GPOs`


---


# 5. Testing Guide — Migrating Cisco VPN Client Deployment from SCCM/GPO to Intune

Run per wave after the Intune objects apply (Implementation Step 9) and **before** removing that wave
from the legacy path. Each wave must clear the parity gate before cutover, and the final tests confirm
the legacy path is gone with no conflict.

> The VPN **tunnel-establishment** test exercises the Cisco head-end, which is out of scope to
> configure here; the test confirms the **Intune-delivered** client + profile + cert produce a working
> connection with parity to the legacy path.

## Test 1 — Client delivered by Intune (version parity)
Do: On a wave device, run `CVPNMIG-Validation.ps1`; confirm `Cisco Secure Client – Win32` installed and
the version matches the standardized version from inventory.
Expected: Client present at the expected version; Intune → app → `Device install status` = `Installed`.

## Test 2 — VPN profile delivered by Intune (profile parity)
Do: Confirm the profile XML is present in the client profile directory and matches the authoritative
source (`CVPNMIG-Validation.ps1` reports the profile and head-end list).
Expected: The Intune-delivered profile is byte-identical to the legacy profile; head-end list correct.

## Test 3 — Certificate delivered by Intune (cert parity)
Do: Confirm the SCEP-issued VPN client certificate is present with the right template intent (subject/
SAN, EKUs) and the trusted root is installed.
Expected: Certificate present from `Cisco VPN – Client Cert (SCEP)`; EKUs/subject match legacy; root
trusted.

## Test 4 — Tunnel establishes (functional parity)
Do: Initiate a VPN connection on the wave device using only the Intune-delivered client/profile/cert.
Expected: The tunnel connects and passes traffic exactly as it did under SCCM/GPO delivery.

## Test 5 — No double-deployment conflict
Do: On a **cut-over** device, run `CVPNMIG-Discovery.ps1`.
Expected: The client/profile/cert show **Intune** as the only source — **no** SCCM deployment targeting
the device and **no** GPO applying (`gpresult` clean); no reinstall loop in the IME log.

## Test 6 — Wave targeting parity
Do: Run `CVPNMIG-Set-ScopeTargeting.ps1` (or check `Assignments`) — the current wave group is targeted
and cut-over waves have left the SCCM collection / GPO scope.
Expected: The same devices that had the legacy VPN are in the Intune wave; legacy scope shrinks each
wave.

## Test 7 — Fleet progress / coexistence report
Do: Run `CVPNMIG-Report.ps1`.
Expected: A legacy-vs-Intune count per wave; the Intune-managed share rises each cycle; laggards flagged.

## Test 8 — Legacy retired (final)
Do: After the last wave, confirm the SCCM deployment/package is removed and the GPO(s) are unlinked;
run `CVPNMIG-Report.ps1` and `CVPNMIG-Discovery.ps1` across a sample.
Expected: 100% Intune-managed; **zero** legacy SCCM/GPO artifacts remain.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| **Per-wave parity pass** | Tests 1–4 pass on the wave (client + profile + cert present, tunnel connects) before removing the wave from legacy |
| **No-conflict pass** | Test 5 passes on every cut-over device — exactly one delivery authority, no reinstall loop |
| **Migration-complete pass** | Test 8 passes — all waves Intune-managed and the SCCM package + GPO(s) retired with no residue |


---


# 6. Troubleshooting Guide — Migrating Cisco VPN Client Deployment from SCCM/GPO to Intune

Use `CVPNMIG-Discovery.ps1` to re-read the current state and delivery source, `CVPNMIG-Validation.ps1`
for per-device client/profile/cert/tunnel parity, `CVPNMIG-Report.ps1` for fleet legacy-vs-Intune
progress, and `CVPNMIG-Remediation.ps1` (default `-WhatIf`) for safe local cleanup.

> The Cisco client, its profile XML, and the head-end (ASA/Firepower) are Cisco's domain — for
> connect-failure internals follow Cisco's documentation. The issues below are the **migration-side**
> problems: double management, profile/version conflict, reinstall loops, and legacy residue.

## A. Double-managed device (SCCM/GPO **and** Intune both delivering)
| Symptom | Cause | Remediation |
|---|---|---|
| Client reinstalls repeatedly / version flip-flops | The device is still in the SCCM collection **and** the GPO scope while Intune also targets it — two authorities fighting | Enforce one-authority-per-device: in the SCCM console remove the device from the target collection, and in GPMC remove it from the GPO's security-group filter or move its computer object out of the linked OU; then `CVPNMIG-Remediation.ps1 -Execute` and `gpupdate /force`; re-check with `CVPNMIG-Discovery.ps1` |
| `CVPNMIG-Discovery.ps1` reports "SCCM + GPO (legacy — double source!)" after cutover | Legacy targeting was never removed at cutover | Complete Implementation Step 10 for that device before considering it migrated |

## B. VPN profile conflict (wrong or flip-flopping profile)
| Symptom | Cause | Remediation |
|---|---|---|
| Profile keeps reverting / two profiles present | A stale legacy profile XML remains alongside the Intune-delivered one, or the GPO still drops its copy | `CVPNMIG-Remediation.ps1` lists duplicate profile XML; confirm which is Intune-delivered, remove the stale legacy file, and stop the GPO from dropping it (descope/unlink) |
| Head-end list / split-tunnel differs after migration | The Intune-delivered XML is not byte-identical to the authoritative source | Re-deliver the authoritative profile (Implementation Step 5); `CVPNMIG-Validation.ps1 -ReferenceProfile` must report profile parity MATCH |

## C. Client reinstall loops
| Symptom | Cause | Remediation |
|---|---|---|
| Intune app cycles install → uninstall → install | Detection rule doesn't match how the client actually installs, so Intune thinks it's never installed | Fix the Win32 detection rule to match the real install evidence (MSI product code / client `.exe` version / uninstall key) captured by `CVPNMIG-Discovery.ps1`; re-sync |
| Loop persists after detection fix | SCCM/GPO still reinstalling under Intune (see A), or a stuck IME evaluation | Remove legacy targeting (A); then `CVPNMIG-Remediation.ps1 -Execute` restarts the Intune Management Extension so the app re-evaluates once |

## D. Certificate not accepted by the head-end
| Symptom | Cause | Remediation |
|---|---|---|
| Client installs and profile loads but the tunnel is refused | The Intune SCEP/PKCS certificate doesn't match the template intent the head-end trusts (subject/SAN, EKUs) | Compare the legacy AD CS template to the SCEP profile; align subject/SAN format, EKUs (Client Authentication), and key usage; confirm the Trusted-root profile installed the issuing CA. Certificate acceptance rules on the head-end are per Cisco docs |
| No client certificate present | SCEP profile not assigned to the wave, or the Certificate connector is down | Confirm `Cisco VPN – Client Cert (SCEP)` is assigned to the wave and the **Certificate connector** shows Active; `CVPNMIG-Validation.ps1` must report the cert present |

## E. Leftover GPO after cutover
- A device still receives the old client-install, profile-drop, or cert-enrolment GPO → it was never
  descoped. Remove the device from the GPO's security-group filter or OU, run
  `CVPNMIG-Remediation.ps1 -Execute` (which runs `gpupdate /force`), and verify with `gpresult /r` that
  the Cisco GPO no longer applies. When all waves are migrated, **unlink** the GPO(s) (Implementation
  Step 12).

## F. Rollback (a wave misbehaves)
- Re-add the wave's devices to the SCCM target collection and back into the GPO scope, and remove the
  Intune wave assignment — coexistence means the VPN never disappears. Fix the Intune delivery
  (client/profile/cert parity) and re-validate with `CVPNMIG-Validation.ps1` before retrying cutover.

## G. Diagnostics quick reference
```powershell
# Delivery source + artifacts on the device
powershell -File .\CVPNMIG-Discovery.ps1

# What GPOs still apply (look for the Cisco client/profile/cert GPOs)
gpresult /r /scope:computer

# Is the SCCM client present (legacy authority)?
Get-Service CcmExec -ErrorAction SilentlyContinue

# Intune Win32 app install + detection results
Get-Content "$env:ProgramData\Microsoft\IntuneManagementExtension\Logs\IntuneManagementExtension.log" -Tail 200

# Cisco profile XML files (duplicate = potential conflict)
Get-ChildItem "$env:ProgramData\Cisco" -Recurse -Filter *.xml -ErrorAction SilentlyContinue
```

## H. When to escalate
If the Intune-delivered client version, profile, and certificate all show parity (`CVPNMIG-Validation.ps1`
PASS), the device is confirmed Intune-only (`CVPNMIG-Discovery.ps1` shows no SCCM/GPO source), and the
tunnel still won't establish, the remaining issue is on the **Cisco** side (head-end configuration,
certificate acceptance, or client behavior) — collect the Cisco Secure Client logs and the
IntuneManagementExtension log and engage **Cisco support** per their documentation.


---


# 7. Best Practices — Migrating Cisco VPN Client Deployment from SCCM/GPO to Intune

- **Inventory before you touch anything.** Capture the installed client **version**, the authoritative
  **profile XML**, the **certificate** template intent, and every SCCM/GPO mechanism and its scope
  first — the legacy delivery encodes working connectivity you must not lose.
- **One source of truth for the profile.** Treat a single copy of the profile XML as authoritative and
  deliver that same XML from Intune, byte-identical, so a coexistence overlap is a no-op rather than a
  fight.
- **One authority per device — always.** The cardinal rule against double-deployment: a device leaves
  the SCCM collection and the GPO scope **in the same change** it joins its Intune wave. Coexistence is
  fleet-wide, never device-wide.
- **Match versions before you overlap.** Standardize on one Cisco-provided client version so that any
  brief pilot overlap does not trigger a reinstall or version tug-of-war.
- **Migrate in waves, pilot first.** Prove the full Intune-delivered VPN (client + profile + cert +
  tunnel) on a small `PILOT – VPN Migration Wave 1` before expanding — a bad rebuild never reaches the
  fleet.
- **Certificate parity is exact work.** The Intune SCEP/PKCS profile must issue a certificate the
  head-end accepts — same subject/SAN, EKUs, and key usage as the legacy AD CS template. Validate
  issuance and acceptance before cutover.
- **Validate the tunnel, not just the files.** The gate is a working connection, not merely the client
  and profile being present — always confirm the VPN actually connects on Intune-only delivery.
- **Cut over and clean up together.** As each wave passes, remove it from SCCM and GPO immediately;
  don't let legacy targeting linger and re-assert itself.
- **Name everything and reuse the names.** `Cisco Secure Client – Win32`, `Cisco VPN – Profile`,
  `Cisco VPN – Client Cert (SCEP)`, `Cisco VPN – Trusted Root CA`, `PILOT – VPN Migration Wave 1` — so
  the migration is searchable and auditable.
- **Prove progress with a report.** Track legacy-vs-Intune coverage each cycle with
  `CVPNMIG-Report.ps1`; chase laggards with `CVPNMIG-Remediation.ps1` (default `-WhatIf`) before
  decommissioning legacy.
- **Have a rollback per wave.** If a wave misbehaves, re-add it to the SCCM collection / GPO scope and
  remove the Intune assignment — coexistence means the VPN never disappears. Fix, then retry cutover.
- **Retire legacy last.** Remove the SCCM deployment/package and unlink the GPO(s) only after every
  wave is Intune-managed and validated — never both authorities enforcing the client at once.
- **Defer Cisco internals to Cisco.** Installer switches, profile XML schema, head-end (ASA/Firepower)
  and ISE posture are Cisco's domain — rebuild *delivery* in Intune and follow Cisco's documentation
  for the product's own configuration.


---


# 8. Deliverables Summary — Migrating Cisco VPN Client Deployment from SCCM/GPO to Intune

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | The migration model (inventory SCCM/GPO delivery → rebuild in Intune → coexist → retire legacy) and how to avoid double-deployment conflicts |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing |
| Global Requirements (Migrations) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered steps: inventory, rebuild client + VPN profile + certificate in Intune, coexistence, pilot, validate parity, wave cutover, retire SCCM package + unlink GPO |
| 5. Testing Guide | Per-wave parity + no-conflict + legacy-gone gates |
| 6. Troubleshooting Guide | Field issues and remediation (double-managed device, profile conflict, reinstall loops, leftover GPO) |
| 7. Best Practices | Wave-based cutover and rollback recommendations |

## PowerShell scripts
| Script | What it does |
|---|---|
| `CVPNMIG-Discovery.ps1` | Current-state discovery: detects the SCCM/GPO-delivered Cisco VPN client + profile + cert on a device and the Intune-side apps/profiles (Graph + local). Read-only |
| `CVPNMIG-Validation.ps1` | Confirms the Intune-delivered client + VPN profile + certificate are present and the tunnel connects on this device. Read-only |
| `CVPNMIG-Report.ps1` | Fleet migration-progress / coexistence report — legacy vs Intune-managed (Microsoft Graph). Read-only |
| `CVPNMIG-Remediation.ps1` | Safely cleans up legacy artifacts / fixes conflicts; default `-WhatIf` |
| `CVPNMIG-Set-ScopeTargeting.ps1` | Creates/populates the migration-wave Entra group(s) |

## What the buyer receives
- This implementation guide as a branded Word document and PDF.
- All five PowerShell scripts in a single ZIP.
- A repeatable process: **Assess → Configure → Pilot → Validate → Expand → Retire legacy.**

## Outcome
The Cisco Secure Client and its VPN profile and certificate delivered from Intune instead of SCCM/GPO —
rebuilt with parity, validated wave by wave with the legacy path live for coexistence, and one delivery
authority per device throughout — so the VPN never drops during the move and the SCCM package and GPOs
are retired only once Intune is proven.
