# 7. Best Practices — Third-Party Application Patching with Intune

- **Prefer the catalog.** Wherever an app is in the Enterprise App Catalog, use it with **auto-update**
  — it is the lowest-effort path and removes per-release repackaging entirely.
- **Use rings, always.** A small fast **Pilot** ring catches a bad app update before it reaches the
  **Broad** fleet — the single most important practice.
- **Make detection version-aware.** A Win32 update is only as reliable as its detection rule; key it
  to `DisplayVersion` / file version greater-than-or-equal-to the target so it applies once and stops.
- **Supersede, do not stack.** Mark each new package to supersede and replace the prior one so devices
  move off old versions automatically instead of accumulating installs.
- **Name everything consistently.** Use `<Purpose> - <Scope> - <Stage>` for every group, app, and
  update (e.g. `PDF Reader Update - Win32 - Broad`) so the next release and the next admin are obvious.
- **Pick one updater per app.** If an app has its own auto-updater, decide whether Intune or the app
  owns patching — running both invites conflicts and false "out of date" reports.
- **Patch the high-risk apps first.** Browsers, PDF readers, Java, and conferencing clients render
  untrusted content and are exploited most; manage them before lower-risk utilities.
- **Report on exposure.** Run `TPP-Report.ps1` each cycle to turn "we think we're patched" into a
  per-device list of what is still behind, and chase the laggards.
- **Validate silent installs in system context.** Confirm the vendor silent switches work with the app
  closed before assigning broadly; an installer that needs the app closed will stall otherwise.
- **Document the cadence.** Record each managed app, its path, target version, and ring assignments
  for audits and repeatability.
