# 2. Requirements Guide — Third-Party Application Patching with Intune

Verify **every** requirement before configuring. Each entry: **Description · Why · Verify ·
Implement-if-missing.** Category-wide prerequisites are in `global-requirements-intune-solutions.md`.

## 2.1 Licensing
**Description:** Microsoft Intune (Plan 1), included in M365 E3/E5 or Business Premium.
**Why:** Intune delivers the catalog apps and Win32 app deployments that patch third-party software.
**Verify:** M365 admin center -> Billing -> Licenses; Intune is present and assigned.
**Implement:** Assign M365 E3/E5 or Business Premium (Intune included), or standalone Intune Plan 1.

## 2.2 Device enrollment
**Description:** Targeted Windows devices enrolled in Intune.
**Why:** Catalog apps and Win32 updates apply only to enrolled devices.
**Verify:** Intune -> Devices -> All devices; the target devices appear and are managed.
**Implement:** Enable automatic enrollment and join devices to Entra ID.

## 2.3 App inventory (what is installed)
**Description:** A current inventory of the third-party apps and versions installed across the fleet.
**Why:** You cannot patch what you have not inventoried; the inventory drives which apps to manage.
**Verify:** Intune -> Apps -> Monitor -> Discovered apps; corroborate on a device with `TPP-Discovery.ps1`.
**Implement:** Run `TPP-Discovery.ps1` on representative devices and review Discovered apps in Intune.

## 2.4 Enterprise App Catalog availability
**Description:** Access to the Enterprise App Catalog and confirmation of which of your apps it covers.
**Why:** The catalog path (auto-update, no repackaging) is preferred wherever the app is available.
**Verify:** Intune -> Apps -> Windows -> Add -> app type **Enterprise App Catalog app**; search for each target app.
**Implement:** For apps in the catalog, use Path A; for apps not in the catalog, plan the packaged path (2.5).

## 2.5 Packaging tooling for non-catalog apps
**Description:** The Microsoft Win32 Content Prep Tool to create `.intunewin` packages, plus each app's installer.
**Why:** Apps not in the catalog are patched as Win32 update apps, which require a packaged `.intunewin`.
**Verify:** `IntuneWinAppUtil.exe` is available; you can obtain each app's silent installer and version.
**Implement:** Download the Win32 Content Prep Tool from Microsoft; collect vendor silent installers.

## 2.6 Detection method per packaged app
**Description:** A reliable, version-aware way to detect whether the target version is installed.
**Why:** Supersedence and "installed" status depend on a detection rule that recognizes the current version.
**Verify:** For each app, identify a registry uninstall key (DisplayVersion), a file version, or an MSI product code.
**Implement:** Record the detection signal per app (see Implementation Step 4) before packaging.

## 2.7 System-context install (no per-user blockers)
**Description:** Packaged updates install in system context; apps must close or update silently.
**Why:** An app held open by the user, or an installer that needs the app closed, can block the update.
**Verify:** Test the silent install/update command on a device with the app installed.
**Implement:** Use the vendor's silent update switches; for apps that must be closed, plan a restart/maintenance behavior.

## 2.8 Maintenance windows / restart expectations
**Description:** Agreement on when updates may install and restart apps for users.
**Why:** Replacing a running app may require closing it; setting expectations reduces tickets.
**Verify:** Confirm with the business which rings tolerate mid-day app restarts.
**Implement:** Communicate the cadence; use the Pilot ring to validate user impact before Broad.

---
## Checklist
- [ ] Intune licensing assigned
- [ ] Devices enrolled
- [ ] App inventory captured — `TPP-Discovery.ps1` + Discovered apps
- [ ] Enterprise App Catalog coverage confirmed per app
- [ ] Win32 Content Prep Tool + vendor installers for non-catalog apps
- [ ] Detection signal recorded per packaged app
- [ ] Silent install/update validated in system context
- [ ] Maintenance/restart expectations agreed
- [ ] Pilot + Broad Entra groups created
