# 1. Solution Overview — SCCM Application Migration to Intune Win32 (Repackaging)

## What this migration is
Configuration Manager (SCCM/MECM) delivers software as `Application` objects, each with one or more
`deployment types` (MSI, script/EXE, App-V, etc.), a `detection method`, `requirement rules`,
`dependencies`, and (optionally) `supersedence`. Intune delivers the same software as
`Win32 apps` (`.intunewin` packages) with their own detection, requirement, dependency, and
supersedence model. This solution is the disciplined migration that takes each SCCM application and
repackages it into an Intune Win32 app with parity — so the same software installs on the same
devices, detected the same way, without anyone losing an app mid-move.

## Why this is its own project (not net-new packaging)
Packaging a brand-new app for Intune is a blank-slate exercise. Migrating an SCCM estate is not: the
detection methods, requirements, dependency chains, and supersedence relationships already exist and
encode years of decisions. The work here is to inventory what SCCM already does for every app,
translate each of those constructs faithfully into the Intune equivalent, run both systems in
coexistence while you cut over ring by ring, validate that each app still deploys, and only then
retire the SCCM deployment. The value is parity and proof, at estate scale.

## How it works
1. Inventory the SCCM application estate — applications, their deployment types, detection methods,
   requirements, dependencies, and supersedence — with the Configuration Manager module.
2. Prioritize apps into migration waves (start with simple, high-value, low-risk apps).
3. Repackage each app's authoritative deployment type into an `.intunewin` file with the Win32
   Content Prep Tool, carrying over the install/uninstall commands.
4. Recreate detection, requirement, dependency, and supersedence rules in Intune to match SCCM.
5. Recreate assignments as Intune ring groups (pilot then broad), mirroring the SCCM collections.
6. Run SCCM/Intune coexistence during transition — SCCM keeps deploying until the Intune app is
   validated on the same devices — then cut over by ring.
7. Validate install and detection parity per app, expand to broad, and retire the SCCM deployment.

## What maps to what (SCCM → Intune Win32)
- `Application` + authoritative `deployment type` → one `Win32 app` (`.intunewin`).
- `Install/uninstall program` (deployment type) → Win32 `Install/uninstall command`.
- `Detection method` (MSI product code / file / registry / script) → Win32 `detection rule`.
- `Requirements` (OS, architecture, disk, custom) → Win32 `requirement rules`.
- `Dependencies` → Win32 `Dependencies` (auto-install the prerequisite app).
- `Supersedence` → Win32 `Supersedence` (uninstall-previous or in-place upgrade).
- `Deployment to a collection` → `assignment` to an Entra ring group (Required or Available).

## What you can control
- Which deployment type is authoritative when an SCCM app has several.
- Detection parity — the same product code / file / registry / script logic in Intune.
- Assignment model — Required (mandatory) vs Available (Company Portal), by ring.
- Coexistence duration per app and the order of cutover across rings.
- Supersedence behavior — clean replace vs in-place upgrade — matching the installer.

## Benefits
- No lost software — every user keeps every app across the move.
- Detection parity — Intune reports Installed for the same devices SCCM did.
- Repeatable — the same inventory-repackage-validate loop runs for every app.
- Safe — coexistence plus ringed cutover means a bad build never reaches the fleet.
- Auditable — a coverage report proves how much of the estate is migrated and deploying.

## Limitations (be honest with buyers)
- App-V, script-heavy, or user-context deployment types may need rework, not a straight repackage;
  this solution flags them for a packaging decision rather than auto-converting them.
- The Win32 Content Prep Tool wraps content; it does not fix a broken installer or a bad silent
  switch — the source install must already be reliable.
- Detection must be authored deliberately — Intune's auto-detect is less reliable than a captured
  MSI product code / file / registry / script rule.
- SCCM and Intune must not both *enforce* the same app on the same device at the same time in a
  conflicting way; coexistence means SCCM deploys until Intune is validated, then you stop the SCCM
  deployment for that ring.

## The standard deployment model
> Inventory SCCM apps → repackage into `.intunewin` with detection/requirement/dependency parity →
> assign to a pilot ring → validate install + detection per app → expand to broad and retire the
> SCCM deployment. repeatable pattern: Assess → Configure → Pilot → Validate → Expand.
