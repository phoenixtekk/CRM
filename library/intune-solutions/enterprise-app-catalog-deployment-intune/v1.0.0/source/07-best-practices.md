# 7. Best Practices — Enterprise App Catalog Deployment in Microsoft Intune

- **Pick the right lane first.** Use the **Enterprise App Catalog** for common apps that are in the
  catalog; use **hand-packaged Win32** for apps that aren't or that need custom install behavior; use
  **winget / Microsoft Store** where that source fits (see the sibling "Winget & Microsoft Store App
  Management" product). Don't hand-package an app that's already curated in the catalog.
- **Assign to a pilot ring first, always.** `Catalog Apps – Pilot Devices – Ring 1` catches a bad
  rollout before it reaches `Catalog Apps – Broad Devices – Ring 2` — the single most important
  practice. The pilot is the gate.
- **Trust — but verify — the built-in detection.** Microsoft supplies the detection rule for catalog
  apps, which is a big reliability win; still confirm on-device with `ENTAPPCAT-Validate.ps1` so
  reporting is proven, not assumed.
- **Enable update management deliberately.** It keeps catalog apps current without re-wrapping — the
  headline benefit — but the **cadence and behavior are Microsoft-defined**. Verify the current
  behavior against Microsoft docs and don't promise an update SLA the service doesn't guarantee.
- **Decide install context up front.** Choose **System** for most line-of-business apps; only use
  **User** context when the app genuinely requires it, to avoid per-user reporting confusion.
- **Name everything with `<Purpose> – <Scope> – <Stage>`.** Self-describing names
  (`Catalog App – Sample App – Prod`, the ring groups) keep a growing app catalog auditable and
  searchable, and let scripts reference objects reliably.
- **Validate an update, not just an install.** The catalog's value is staying current — prove an
  update actually applies on a pilot device (Testing Test 6) before you rely on it fleet-wide.
- **Watch the report and chase laggards.** Track Installed / Failed / Not applicable with
  `ENTAPPCAT-Report.ps1`; for deep break/fix on a stuck install, hand off to the "Intune App
  Deployment Troubleshooting & Failure Remediation" product rather than guessing.
- **Check national-cloud differences.** Enterprise App Catalog availability, portal URLs, and update
  behavior can differ in GCC / GCC High / DoD — verify for your tenant before deploying.
- **Document each app's deployment record.** Record the catalog app name, install context, update
  management choice (or version pin), and ring assignments for audits and repeatability.
