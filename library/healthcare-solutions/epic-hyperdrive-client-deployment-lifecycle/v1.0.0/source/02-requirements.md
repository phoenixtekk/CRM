# 2. Requirements Guide — Epic Hyperdrive & Hyperspace Client Deployment & Lifecycle Management with Microsoft Intune

Verify **every** requirement below before you package or deploy anything. Each entry follows the same
pattern: **Description · Why required · How to verify · How to implement if missing.** Do **not**
assume any prerequisite already exists.

> Category-wide prerequisites (a tenant, Intune subscription, device enrollment, HIPAA / HITRUST
> change control, clinical maintenance windows, a test device, rollback posture, etc.) are documented
> once in **`global-requirements-healthcare-solutions.md`**. This guide lists what is **specific to**
> deploying the Epic client.

---

## R1. Microsoft Intune licensing and app-management rights
**Description:** An Intune subscription and an operator with rights to create and assign **Windows
apps** (Intune Administrator or Application Manager).
**Why required:** The Epic client is delivered as an Intune **Win32 app**; without app-management
rights you cannot create the package, detection rules, or assignments.
**How to verify:** `https://intune.microsoft.com` → **Apps → Windows** loads and **+ Add** is
available; Entra → **Roles and administrators** shows the operator's role.
**How to implement if missing:** Assign an Intune-bearing license and the **Intune Administrator** (or
**Application Manager**) role to the operator. See global requirement G1.

## R2. Microsoft Win32 Content Prep Tool
**Description:** The **Microsoft Win32 Content Prep Tool** (`IntuneWinAppUtil.exe`), used to wrap the
Epic installer and its files into a single `.intunewin` package.
**Why required:** Intune Win32 apps are deployed only as `.intunewin` packages; this is the only
supported way to wrap them.
**How to verify:** `IntuneWinAppUtil.exe -v` runs from your packaging workstation.
**How to implement if missing:** Download the Win32 Content Prep Tool from Microsoft's official
GitHub repository (`microsoft/Microsoft-Win32-Content-Prep-Tool`) onto a clean packaging
workstation. Keep it current.

## R3. The Epic installer — obtained from Epic Technical Services / UserWeb
**Description:** The exact **Epic client installer** (Hyperdrive and/or Hyperspace), its **silent
install / uninstall command lines**, the target **client version string**, the **install directory**,
the **launch executable**, and the **environment / connection configuration** for your Epic
environment.
**Why required:** These values drive the install command, the version-pinned detection rule, the
requirement rule, and the supersedence relationship. They are **Epic-specific and customer-only** —
they are not documented here and must not be guessed.
**How to verify:** Confirm with your **Epic build / Technical Services team** that you have the
correct installer and switches for your environment, sourced from **Epic UserWeb / Galaxy**. Run the
installer's silent command on the test device once, by hand, to confirm it installs cleanly and
unattended.
**How to implement if missing:** Request the installer package, silent switches, version string, and
environment configuration from your Epic build team / Epic UserWeb. Record them as the placeholder
values `<EPIC_INSTALLER>`, `<EPIC_SILENT_ARGS>`, `<EPIC_VERSION>`, `<EPIC_INSTALL_DIR>`,
`<EPIC_EXE>`, and `<EPIC_UNINSTALL_CMD>` used throughout the Implementation Guide.

## R4. Target operating system — Windows 10 / Windows 11
**Description:** Clinical endpoints run a supported, patched **Windows 10 (21H2+)** or **Windows 11**,
x64.
**Why required:** The Epic client and the WebView2 runtime (for Hyperdrive) require a current,
supported Windows build; the Win32 app **requirement rule** will target these OS versions.
**How to verify:** `winver` on a device, or Intune → device → **Hardware**.
**How to implement if missing:** Patch via Update rings or upgrade devices. See global requirement G2.

## R5. WebView2 runtime (Hyperdrive prerequisite)
**Description:** The **Microsoft Edge WebView2 Runtime** present on every device that will run
**Hyperdrive** (Hyperdrive is Chromium / WebView2-based).
**Why required:** Hyperdrive will not launch or render without the WebView2 runtime; this is the most
common Hyperdrive launch failure.
**How to verify:** Run **`EPICCLIENT-Validation.ps1`** (checks for the WebView2 runtime), or check
**Apps & features** / the registry for *Microsoft Edge WebView2 Runtime*.
**How to implement if missing:** Deploy the **Evergreen WebView2 Runtime** as its own Intune Win32 /
Microsoft Store app and set it as a **dependency** of the Epic Hyperdrive app (Implementation Step 6),
so WebView2 installs first. Modern Windows 11 includes WebView2, but **do not assume it** — verify.

## R6. Configuration Manager co-management (only if applicable)
**Description:** If clinical endpoints are **co-managed** with Microsoft Configuration Manager (SCCM),
confirm which authority owns **client apps** — Intune or ConfigMgr.
**Why required:** With co-management, the **Client apps** workload must be pointed at Intune (or at
ConfigMgr) so app assignments take effect from the expected authority and you do not deploy the same
client twice.
**How to verify:** Intune → **Devices → Configuration Manager → Co-management**, review the
**Client apps** workload slider; or in the ConfigMgr console, review co-management settings.
**How to implement if missing:** Decide the authority. To deploy via Intune, move the **Client apps**
workload to **Intune** (or **Pilot Intune** scoped to the pilot collection). If you keep apps in
ConfigMgr, deploy the same package as a ConfigMgr Application with equivalent detection / supersedence.

## R7. Entra device groups for deployment rings
**Description:** Microsoft Entra **device** groups for the population and the rings:
**`EPIC – Clinical Workstations`** (all in-scope clinical endpoints),
**`Epic Hyperdrive – Pilot Ring`**, and **`Epic Hyperdrive – Broad Ring`**.
**Why required:** Ring-based rollout is how a bad client build is contained to a few validated devices.
Assignments target these named groups.
**How to verify:** Entra → **Groups → All groups**; the three groups exist with intended membership.
**How to implement if missing:** Create them in Entra (or run
**`EPICCLIENT-Set-DeploymentRings.ps1`**), which creates `Epic Hyperdrive – Pilot Ring` and
`Epic Hyperdrive – Broad Ring` and can wire ring assignments via Microsoft Graph.

## R8. Detection / version strategy
**Description:** A decided, reliable way for Intune to detect "the target Epic version is installed" —
a **file version** of `<EPIC_EXE>` in `<EPIC_INSTALL_DIR>`, a **registry** uninstall key/version, or
an **MSI product code** — matching how `<EPIC_INSTALLER>` actually registers.
**Why required:** The detection rule is what tells Intune the app is installed and at the right
version; a wrong rule causes endless re-installs or false "installed" states.
**How to verify:** On the test device after a manual install, inspect the file version of
`<EPIC_EXE>` and the registry uninstall key; run **`EPICCLIENT-Discovery.ps1`** to read the installed
version. Confirm those values match what your detection rule will assert.
**How to implement if missing:** Choose the most stable signal (file version is usually best for the
Epic client), and record the exact detection values for the Implementation Guide.

## R9. A test clinical device (not in patient care)
**Description:** A representative, enrolled, non-production clinical device (ideally one fixed
workstation and one WOW) in **`Epic Hyperdrive – Pilot Ring`**.
**Why required:** Packaging, detection, launch, and Imprivata-tap validation must be proven before any
device in care receives the client.
**How to verify:** The device is enrolled, compliant, and a member of `Epic Hyperdrive – Pilot Ring`.
**How to implement if missing:** Set aside the device and add it to the pilot ring group. See global
requirement G7.

## R10. Approved clinical change window and rollback plan
**Description:** A change-control approval, an agreed **clinical maintenance window** for the broad
deployment, and a documented **rollback** (revert to the previously validated package/version).
**Why required:** Deploying or reverting the EHR client touches patient-care devices; it must be
change-managed, windowed, and reversible.
**How to verify:** A CAB-approved change ticket exists with window and back-out plan, naming the
previously validated package to revert to.
**How to implement if missing:** Route through your CAB; keep the prior validated `.intunewin` and its
detection values for rollback. See global requirements G4, G5, G8.

## R11. Imprivata present (only if integrating SSO / badge-tap)
**Description:** If your clinical endpoints use **Imprivata** for single sign-on / badge-tap into
Epic, confirm the Imprivata agent is installed and healthy on the test device **before** changing the
Epic client.
**Why required:** A new Epic client version can change launch behavior; you must confirm
tap-to-launch into Epic still works after the change. (Imprivata configuration itself is a separate
solution; here it is a **validation touchpoint** only.)
**How to verify:** On the test device, confirm the Imprivata agent service is running and a badge tap
launches into Epic prior to the change; re-test after (Testing §, Test 6).
**How to implement if missing:** Engage the separate Imprivata solution / your Imprivata
administrators. If you do **not** use Imprivata, this requirement is N/A — skip the related test.

---

## Requirements checklist (use before packaging)
- [ ] **R1** Intune app-management rights (Intune Administrator / Application Manager)
- [ ] **R2** Win32 Content Prep Tool (`IntuneWinAppUtil.exe`) available
- [ ] **R3** Epic installer + silent switches + version + install dir + exe + uninstall cmd from Epic TS/UserWeb
- [ ] **R4** Supported, patched Windows 10/11 (x64)
- [ ] **R5** WebView2 runtime present (Hyperdrive) — `EPICCLIENT-Validation.ps1`
- [ ] **R6** Co-management **Client apps** workload authority decided (if co-managed)
- [ ] **R7** Entra groups `EPIC – Clinical Workstations`, `Epic Hyperdrive – Pilot Ring`, `Epic Hyperdrive – Broad Ring`
- [ ] **R8** Detection / version strategy chosen and verified — `EPICCLIENT-Discovery.ps1`
- [ ] **R9** Test clinical device (fixed + WOW) in the pilot ring
- [ ] **R10** CAB-approved change window + rollback to prior validated package
- [ ] **R11** Imprivata agent healthy on test device (only if integrating badge-tap)
