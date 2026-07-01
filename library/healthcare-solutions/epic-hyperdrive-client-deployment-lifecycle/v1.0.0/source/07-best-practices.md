# 7. Best Practices — Epic Hyperdrive & Hyperspace Client Deployment & Lifecycle Management with Microsoft Intune

These practices keep the Epic client deployment safe, version-coherent with Epic, and clean over its
lifecycle on shared clinical endpoints.

## Source of truth: Epic owns the installer, you own the delivery
- **Always** take the installer, silent switches, version string, and environment configuration from
  your **Epic build team / Epic UserWeb** — never guess Epic-internal flags or version numbers.
- Re-confirm these values **each Epic upgrade**; they can change between Epic versions.
- Keep a small internal record (not in this package) mapping each `<EPIC_VERSION>` to the Epic
  environment, installer, and switches you packaged.

## Pin the version with detection — and keep detection honest
- Use a **version-pinned detection rule** (file version of `<EPIC_EXE>` is usually the most stable).
- After every package, **verify the detection value against a real install** on the test device
  (`EPICCLIENT-Discovery.ps1`) before assigning — a wrong rule causes endless re-installs or false
  "installed" states.
- Prefer **file version** over a registry DisplayVersion if the installer's registry value is
  inconsistent across builds.

## Always pilot before broad — and let supersedence respect rings
- Every release and every **upgrade** goes to **`Epic Hyperdrive – Pilot Ring`** and is fully
  validated (Testing §) **before** **`Epic Hyperdrive – Broad Ring`**.
- For upgrades, assign the **new** superseding app to the pilot ring first; supersedence respects
  assignment scope, so the broad fleet only upgrades once pilot is proven.
- Keep the pilot ring **representative** — include at least one fixed clinical workstation and one
  **WOW**, since form factors behave differently (battery, dock, network).

## Treat the WebView2 runtime as a first-class dependency (Hyperdrive)
- Deploy the **Evergreen WebView2 Runtime** as its own app and set it as a **dependency** (auto-install
  = Yes) of the Hyperdrive app, so it is present **before** Hyperdrive installs/launches.
- Do **not** assume Windows 11 already has WebView2 — verify with `EPICCLIENT-Validation.ps1`.

## Upgrade cleanly with supersedence; retire deliberately
- For upgrades, use **supersedence with "Uninstall previous version = Yes"** so the old client is
  removed before the new one installs — this prevents multiple Epic versions accreting on shared
  devices.
- For decommissioned versions not being superseded, retire via an **Uninstall assignment**, then
  verify nothing is left behind (`EPICCLIENT-Discovery.ps1`).
- Keep the **previous validated `.intunewin`** and its detection values until the new version is fully
  proven, so rollback is one assignment away.

## Respect the clinical environment
- **Install behavior = System**, **device restart behavior = No specific action** — never force a
  reboot on a shared clinical device; control restarts through the approved **maintenance window**.
- Align assignment **availability** to the maintenance window; communicate changes to clinical
  operations in advance.
- Every deploy / upgrade / retire is a **change-controlled** action with an approved window and a
  documented **rollback** (global requirements G4, G5, G8).

## Co-management clarity
- If devices are co-managed, decide **one** authority for **client apps** (Intune **or** ConfigMgr)
  and stick to it, so the Epic client is never deployed twice from two systems.

## Protect ePHI in operations
- The tools in this package are **read-only over device/app state** and must **never** capture
  patient data. Keep logs and CSV reports limited to device, version, and install-state fields.
- Restrict who can run deployment/uninstall actions; retain change records per your compliance program.

## Operate on a cadence
- Run **`EPICCLIENT-Report.ps1`** on a schedule to watch for **version drift** (devices that fell
  behind) and to confirm each ring is converged.
- After any change, sample devices with **`EPICCLIENT-Validation.ps1`**; use
  **`EPICCLIENT-Remediation.ps1`** (`-WhatIf` first, then `-Apply`) for one-off recoveries rather than
  re-broadcasting to a whole ring.
