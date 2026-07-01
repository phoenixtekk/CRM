# 1. Solution Overview — Workspace ONE to Intune Application Rebuild & Repackaging

## What this solution is
This is a repeatable way to rebuild and repackage the application estate currently delivered by
VMware Workspace ONE UEM into Microsoft Intune. Applications do not migrate automatically between
MDM platforms: an app deployed by Workspace ONE is a package plus a set of delivery rules
(detection, requirements, assignment, configuration) that live in the source platform. To move it,
you reconstruct the same app and the same rules natively in Intune, then prove it still installs.

## Why apps are the hard part of a Workspace ONE migration
Most of a UEM migration is one-to-one (a profile here, an enrollment there). Apps are not. A single
line-of-business app can carry a custom installer, a bespoke detection rule, version supersedence,
platform-specific requirements, an app-configuration payload, and an assignment graph spanning
several groups. Multiply that by hundreds of apps across Windows, iOS/iPadOS, and Android, and the
estate becomes the longest, riskiest pole in the migration. The cost of getting it wrong is direct:
a user opens their laptop after cutover and the app they bill hours in is gone. This solution exists
to make the rebuild systematic and to gate every app behind proof that it deploys.

## How Workspace ONE app types map to Intune
Each source app type has a target equivalent in Intune. You decide the mapping per app during the
inventory step.

| Workspace ONE app type | Intune target | Notes |
|---|---|---|
| Internal Win32 app (EXE/MSI) | Windows app (Win32) `.intunewin` | Repackage source media; author detection + requirements |
| Public Windows app | Microsoft Store app (new) | Reference by Store package; no repackaging |
| Internal/Public iOS app | iOS store app or line-of-business app (`.ipa`) | Public from the App Store; internal as LOB |
| Internal/Public Android app | Managed Google Play app | Public or privately-published via managed Google Play |
| Per-app configuration | App configuration policy (managed apps / managed devices) | Recreate keys/values against the rebuilt app |
| Assignment / smart group | Microsoft Entra security group assignment | Rebuild required/available/uninstall intent parity |

> Workspace ONE internals (how the source console exports app records, smart groups, and assignment
> rules) are deferred to VMware documentation. This guide is exact on the Intune side; on the source
> side it tells you what to obtain, not how the source console produces it.

## How the rebuild works
1. Inventory the source app estate (name, type, version, install/uninstall logic, detection,
   requirements, assignments, app config) and produce a source-of-truth list.
2. Map each app to its Intune target type and prioritize by criticality and complexity.
3. Rebuild each app in Intune with correct logic: for Win32, repackage to `.intunewin` and author
   detection, requirements, and supersedence; for store and managed mobile apps, reference the
   correct store entry; recreate app configuration.
4. Recreate the deployment/assignment workflow — required, available, and uninstall intent — against
   Entra groups that mirror the source assignment, using consistent ring targeting.
5. Validate each app on a pilot device (it installs and Intune detects it) before expanding.
6. Expand to the broad ring, then decommission the source assignment per the coexistence plan.

## What you control per app
- Detection parity — the rule that tells Intune the app is installed (MSI product code, file version,
  registry value, or store presence) must match reality, not the source platform's logic.
- Requirement parity — architecture, minimum OS, and any custom requirement rule.
- Supersedence — replacing an older rebuilt version cleanly or in place.
- Assignment parity — the same users/devices get the same app, with the same required/available/
  uninstall intent, via ring-based targeting.
- App configuration parity — managed-app keys and values recreated against the rebuilt app.

## Limitations (be honest with buyers)
- Source-side export of app records is a Workspace ONE task and depends on what that platform and
  its API expose; this solution flags the data you need and defers the how to VMware docs.
- Stored installer media for internal Win32 apps must be available to repackage — if the original
  source media is lost, it must be re-obtained before rebuild.
- App configuration schemas differ between platforms; values are recreated, not byte-copied.
- During coexistence both platforms may target a device; the validation gate and uninstall-intent
  planning exist precisely to avoid double-installs and orphaned apps.

## The standard deployment model
> Inventory and map the source apps to Configure (rebuild each in Intune) to Pilot (assign to a
> pilot ring) to Validate (prove each app installs and is detected) to Expand (broad ring, then
> retire the source assignment). Model: Assess to Configure to Pilot to Validate to Expand, with a
> per-app validation gate.
