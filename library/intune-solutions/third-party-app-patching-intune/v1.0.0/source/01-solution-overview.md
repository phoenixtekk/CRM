# 1. Solution Overview — Third-Party Application Patching with Intune

## What this solution is
Microsoft Intune can keep **non-Microsoft applications** current the same way it manages everything
else: as cloud-delivered apps assigned to devices. This solution builds a repeatable program that
patches the third-party software attackers target most — browsers, PDF readers, Java, conferencing
clients, archive tools — using two complementary paths inside Intune, deployed in update rings so a
small pilot validates every change before the fleet receives it.

## Why third-party apps are the prime attack surface
Windows Update for Business patches the OS, Microsoft drivers, and Microsoft Store apps — but **not**
the third-party software installed on top. Those apps publish their own security fixes on their own
cadence, and without a managed program they drift: a device can be fully patched on Windows yet run a
browser or PDF reader months behind, with public CVEs against it. Because these apps render untrusted
content from the internet, they are the most commonly exploited software on a managed device. A
patching program for them closes doors that OS patching alone leaves open.

## The two patching paths
Intune offers two ways to keep a third-party app current. Use the catalog path wherever the app is
available, and the packaged path for everything else.

### Path A — Enterprise App Catalog apps (with auto-update)
The **Enterprise App Catalog** is a Microsoft-curated, prepackaged set of common third-party Win32
apps. When you add an app from the catalog, Intune supplies the installer, detection, and update
logic; you can turn on **auto-update** so Intune ships new versions of that app to assigned devices
as the catalog publishes them — no repackaging on your part. This is the lowest-effort path and is
preferred whenever the app you need is in the catalog.

### Path B — Packaged Win32 updates (detection + supersedence)
For apps not in the catalog, you keep them current with the **Win32 app** model. You package the new
version as a Win32 app (`.intunewin`), give it a **detection rule** that returns "installed" only
when the current (or newer) version is present, and mark it to **supersede** the prior Win32 app so
assigned devices automatically replace the old version with the new one. Each time the vendor ships a
release, you package it and supersede the previous package; devices move forward on their next cycle.

## How it works end to end
1. **Inventory** the third-party apps and versions actually installed across the fleet (the
   discovery script reads installed apps; Intune's discovered-apps inventory corroborates).
2. **Onboard catalog apps** from the Enterprise App Catalog with auto-update enabled, assigned by
   ring.
3. **Package non-catalog apps** as Win32 updates with a version-aware detection rule and supersedence
   of the prior package, assigned by ring.
4. **Assign in rings** — a fast **Pilot** ring gets each change first; a slower **Broad** ring
   follows once the pilot is healthy.
5. **Validate** patch state on devices and run a fleet **exposure report** to find what is still out
   of date.
6. **Expand** to the broad ring, then repeat each release cycle.

## What you can control
- Which apps are managed, and via which path (catalog auto-update vs packaged supersedence).
- The exact target version a device must reach (through the detection rule / catalog version).
- The rollout order and pace (Pilot then Broad rings, with a gate between them).
- Install behavior (system context, restart handling) for packaged updates.
- Fleet-wide visibility of out-of-date exposure.

## Benefits
- **Security** — the most-exploited software on each device stays current on a predictable cadence.
- **Low effort where it counts** — catalog apps auto-update with no repackaging.
- **Automatic version moves** — supersedence pulls devices off old versions without manual cleanup.
- **Safe rollout** — ring-based deployment catches a bad update on the pilot before the fleet.
- **Visibility** — a fleet exposure report turns "we think we're patched" into evidence.

## Limitations (be honest with buyers)
- The **Enterprise App Catalog** covers many common apps but not every app; non-catalog apps require
  the packaged path and a tool to create the `.intunewin` package.
- Intune reports installed apps via **discovered apps**, but it does not natively scan each app
  against the latest vendor version; the exposure report compares installed versions against a target
  you supply.
- Packaged Win32 updates require a correct, version-aware **detection rule** — a weak detection rule
  is the most common cause of an update that never applies or re-applies forever.
- Some apps include their own auto-updater; decide per app whether Intune or the app's updater owns
  patching to avoid two authorities fighting.

## The standard deployment model
> **Inventory installed apps -> onboard catalog apps (auto-update) and package non-catalog updates
> (detection + supersedence) -> assign by ring -> validate on the pilot -> expand to broad.** The
> repeatable way: **Assess -> Configure -> Pilot -> Validate -> Expand.**
