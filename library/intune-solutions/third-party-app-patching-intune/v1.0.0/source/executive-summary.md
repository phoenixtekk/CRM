# Executive Summary — Third-Party Application Patching with Intune (Microsoft Intune)

Windows Update keeps the operating system current, but the software that attackers exploit most —
browsers, PDF readers, Java, conferencing clients, archive utilities — quietly drifts out of date on
every device. Each stale version is an open door, and most organizations have no fleet-wide view of
which apps are behind. This package gives you a **repeatable third-party patching program in
Microsoft Intune**: keep non-Microsoft apps current automatically, using the Enterprise App Catalog
where the app is available, and a packaged update method (detection plus supersedence) for
everything else, deployed in rings.

This is a complete, **deploy-it-today** package, written for an administrator with no prior
app-packaging experience. Every step is click-by-click against the current Intune admin center.

## What you get
- A plain-language **Solution Overview** of why third-party apps are the prime attack surface, the
  Enterprise App Catalog (catalog apps with auto-update) model, and the packaged/superseded Win32
  update method for everything else.
- A **Requirements Guide** with verify / implement-if-missing for every prerequisite.
- An **Implementation Guide** of precise, ordered Intune steps covering both update paths.
- Five **PowerShell scripts** for installed-app discovery, patch-state validation, fleet exposure
  reporting, safe remediation of stuck updates, and an update-ring group builder.
- **Testing** and **Troubleshooting** guides for confident rollout.

## What this delivers
A **ring-based third-party patching strategy** — catalog apps onboarded with auto-update enabled,
non-catalog apps packaged as Win32 updates with detection rules and supersedence so devices move to
the current version automatically, all assigned through a fast **Pilot** ring and a slower **Broad**
ring, with a fleet exposure report that shows what is still out of date.

## The repeatable deployment model
**Assess -> Configure -> Pilot -> Validate -> Expand.**

## Outcome
Your highest-risk third-party apps kept current automatically across the fleet — catalog apps
auto-updating, everything else packaged and superseded, deployed in rings — proven on a pilot before
you scale.
