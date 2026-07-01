# 1. Solution Overview — Group Policy to Intune Settings Migration

## What this migration is
Group Policy (GPO) is the on-premises Active Directory mechanism that pushes configuration to
domain-joined Windows devices. It is powerful, but it only applies when a device can reach a domain
controller — so cloud-joined, remote, and hybrid devices fall out of scope. **Microsoft Intune**
delivers the equivalent configuration from the cloud, to any enrolled device, anywhere. This
solution is a **structured translation** of your GPO estate into Intune policy: inventory the GPOs,
measure how much is supported, recreate the supported settings in Intune, handle the rest
deliberately, and cut over by rings.

## How GPO and Intune policy differ (why this is a translation, not a copy)
- **GPO** is processed by the device against AD on the corporate network, on a refresh interval,
  using ADMX templates and security/preferences. **Intune** delivers policy over the internet to
  enrolled devices using the **settings catalog**, **imported ADMX (administrative templates)**,
  **endpoint security**, and **compliance** profiles.
- Most ADMX-backed GPO settings have a direct Intune equivalent; many **Group Policy Preferences**,
  logon/startup scripts, drive maps, and a few security settings **do not** translate one-for-one and
  must be re-implemented another way (or retired).
- Both can apply to the same device during migration. When they conflict, you must choose a winner —
  see **coexistence and precedence** below.

## The Group Policy analytics workflow
Intune includes **Group Policy analytics**, which reads an **exported GPO backup** and tells you,
per setting, whether it **maps** to an Intune setting (supported), is **deprecated/not supported**,
or **needs review**. It produces a **migration readiness percentage** for each imported GPO — the
honest measure of how much of that GPO you can move. The standard workflow is:
1. **Export** each GPO from the domain (GPMC backup → XML/reports).
2. **Import** the export into Group Policy analytics and read the **readiness %** and per-setting
   mapping.
3. **Migrate** the supported settings — analytics can generate **settings catalog** policies
   directly from the mapped settings, which you then review, name, and assign.
4. **Handle** the unsupported settings (re-implement, replace, or retire) and document the decision.

## What you create in Intune
- **Settings catalog** policies for supported, mapped settings (the modern, searchable surface).
- **Imported ADMX** policies for in-box and third-party administrative templates (e.g. Office,
  Edge, Chrome) so ADMX-only settings have a home.
- **Coexistence control** so on-prem GPO and Intune MDM policy don't fight during the move.
- **Migration ring groups** and ringed assignments for a safe, phased cutover.

## Coexistence and precedence during migration
While a device is both domain-joined and Intune-enrolled (hybrid), **both** policy sources apply. By
default, for most ADMX-backed settings, **Group Policy wins** over MDM. To let Intune take
authority cleanly as you migrate, enable the **MDMWinsOverGP** setting (the
`ControlPolicyConflict` / "MDM wins over GP" policy) so Intune's value wins where both set the same
setting. Migrate setting areas deliberately — turn the matching GPO setting off (or scope the GPO
away from migrated devices) as you bring each area into Intune — so there is exactly one authority
per setting at the end.

## The ring-based cutover
Devices move in **rings**: a small **Pilot** ring takes the new Intune policy first and is checked
for **parity** (does Intune now enforce what the GPO used to?). Only after the parity gate passes do
you **Expand** to the broad fleet, scoping the legacy GPO away from migrated devices as you go.

## Benefits
- **Cloud reach** — policy follows remote and cloud-joined devices, not just LAN-connected ones.
- **Visibility** — you finally know what is in the GPO estate and how much is supported.
- **Safety** — parity-checked, ringed cutover catches loss on a pilot, not the fleet.
- **One authority** — coexistence handled so on-prem and cloud policy stop fighting.

## Limitations (be honest with buyers)
- Not every GPO setting maps — **Group Policy Preferences**, logon scripts, drive maps, and some
  security settings need a different Intune approach (proactive remediations, platform scripts,
  endpoint security, or retirement).
- Group Policy analytics measures **readiness**, it does not flip the switch — you still review,
  name, assign, and validate each policy.
- Coexistence requires a deliberate precedence decision (MDMWinsOverGP) and per-area cutover to
  avoid double-authority drift.

## The standard deployment model
> **Export GPOs → run Group Policy analytics → translate supported settings → handle unsupported →
> set coexistence/precedence → assign in rings → validate parity → expand.** The repeatable way:
> **Assess → Configure → Pilot → Validate → Expand.**
