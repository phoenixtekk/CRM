# 3. Implementation Guide — Third-Party Application Patching with Intune

Follow these steps **in order**, in the **Microsoft Intune admin center** (`https://intune.microsoft.com`).

> **Model:** Inventory installed apps, onboard catalog apps with auto-update, package non-catalog
> apps as superseding Win32 updates, then assign everything through a fast **Pilot** ring and a
> slower **Broad** ring. The pilot validates every change before the fleet receives it.
>
> **Naming convention (reuse verbatim):** every object is named `<Purpose> - <Scope> - <Stage>`.
> Example apps below use a browser and a PDF reader with placeholder versions in backticks; substitute
> your real apps and the actual current version when you build them.

## Step 1 — Create the ring groups
1. Entra -> Groups -> New group -> Security -> name `Third-Party Patching - Devices - Pilot` (a few representative devices). Create.
2. Create `Third-Party Patching - Devices - Broad` (the rest of the fleet). Create.
3. Tip: `TPP-Set-UpdateRingTargeting.ps1` can build these groups and seed pilot membership for you.

## Step 2 — Inventory what is installed
1. Run `TPP-Discovery.ps1` on representative devices to list installed third-party apps and versions.
2. In Intune -> Apps -> Monitor -> Discovered apps, corroborate the fleet-wide picture.
3. For each app you will manage, decide the path: **Path A** if it is in the Enterprise App Catalog
   (Step 3), otherwise **Path B** packaged update (Step 4).

## Step 3 — Path A: onboard Enterprise App Catalog apps (auto-update)
Do this for each app available in the catalog (example: a browser).
1. Intune -> Apps -> Windows -> Add. For **App type**, choose **Enterprise App Catalog app**. Select.
2. **Search the catalog** for the app, select the package, then Select.
3. On **App information**, keep the catalog name; set a clear display name if you wish. Next.
4. On **Program / settings**, leave the catalog-provided install/uninstall commands. **Enable
   auto-update** (Automatically update this app to the latest version) so Intune ships new versions
   as the catalog publishes them. Next through Detection (catalog-provided) and Requirements.
5. **Assignments -> Required -> Add group ->** `Third-Party Patching - Devices - Pilot`. Next.
6. Review + create. Name the assignment context so it is recognizable: this is your
   `Browser Catalog Update - Catalog - Pilot` deployment.
7. After the pilot validates (Testing Guide), add the **Required** assignment to
   `Third-Party Patching - Devices - Broad` — call this `Browser Catalog Update - Catalog - Broad`.

## Step 4 — Path B: package a non-catalog app as a superseding Win32 update
Do this for each app **not** in the catalog (example: a PDF reader at target version `<x.y.z>`).
1. **Package it.** With the Win32 Content Prep Tool, wrap the vendor silent installer for version
   `<x.y.z>` into an `.intunewin` file.
2. Intune -> Apps -> Windows -> Add -> **App type: Windows app (Win32)**. Select. Upload the `.intunewin`.
3. **App information:** display name `PDF Reader Update - Win32 - <x.y.z>` (include the version so
   each release is distinct). Next.
4. **Program:** enter the vendor **silent install** command and the **uninstall** command. Set
   **Install behavior: System**. Next.
5. **Requirements:** Operating system architecture and minimum OS. Next.
6. **Detection rules:** add a **version-aware** rule so the app is "installed" only when the target
   version is present. Use one of:
   - Registry: the app's uninstall key `DisplayVersion` value, operator **Version greater than or equal to** `<x.y.z>`; or
   - File: the installed binary's version, **greater than or equal to** `<x.y.z>`; or
   - MSI: the product code with the matching version.
   Name this rule mentally as `PDF Reader Detection - Version - <x.y.z>` for your runbook. Next.
7. **Supersedence:** add the **previous** PDF reader Win32 package as superseded, with **Update**
   (replace the old version). This makes assigned devices move from the old version to `<x.y.z>`
   automatically. (On the very first package there is nothing to supersede yet.) Next.
8. **Assignments -> Required -> Add group ->** `Third-Party Patching - Devices - Pilot`. Review + create.
   This is your `PDF Reader Update - Win32 - Pilot` deployment.
9. After the pilot validates, add the **Required** assignment to `Third-Party Patching - Devices - Broad`
   (`PDF Reader Update - Win32 - Broad`).

## Step 5 — Apply on a pilot device
1. On a pilot device, sync policy (Settings -> Accounts -> Access work or school -> Info -> Sync).
2. Let the catalog app update and the Win32 update install.
3. Run `TPP-Validation.ps1` to confirm the installed versions now meet the targets.

## Step 6 — Validate the pilot
1. Run `TPP-Validation.ps1` on pilot devices -> confirms each managed app is at (or above) its target version.
2. Run `TPP-Report.ps1` -> confirms pilot devices report no out-of-date exposure for managed apps.
3. In Intune -> Apps -> Monitor, confirm the catalog app and Win32 update show **Installed/Succeeded**
   on the pilot. Complete the Testing Guide.

## Step 7 — Expand to production
1. Add the **Broad** assignments (Steps 3.7 and 4.9) once the pilot passes.
2. Re-run `TPP-Report.ps1` to confirm broad devices converge to the target versions.
3. Use `TPP-Remediation.ps1` (default `-WhatIf`) to nudge any device whose update is stuck.

## Step 8 — Each new release (repeat)
1. For **catalog apps**, auto-update handles new versions automatically — nothing to do.
2. For **packaged apps**, package the new version as `App Update - Win32 - <newversion>`, point its
   detection rule at the new version, **supersede** the prior package, and assign Pilot then Broad.
3. Re-validate each cycle with `TPP-Validation.ps1` and `TPP-Report.ps1`.

---
### Order of operations
`Ring groups -> Inventory -> Catalog apps (auto-update) + Win32 packages (detection + supersedence) -> Assign Pilot -> Validate -> Expand to Broad -> Repeat per release`
