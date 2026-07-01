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
