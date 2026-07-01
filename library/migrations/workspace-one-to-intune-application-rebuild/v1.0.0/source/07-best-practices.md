# 7. Best Practices — Workspace ONE to Intune Application Rebuild & Repackaging

- Gate every app on a pilot. No app reaches the broad ring until it installs and Intune detects it on
  a pilot device — the single most important practice in an app rebuild.
- Rebuild detection from reality, not the source record. Author each Intune detection rule from what
  the installer actually leaves on disk (MSI product code, file version, or registry value), not from
  the Workspace ONE detection entry. A wrong rule causes reinstall loops or false "installed".
- Use exactly one authoritative detection rule per app. Multiple rules invite ambiguity; pick the
  most reliable signal and use it alone.
- Prioritize by criticality and reach. Rebuild critical line-of-business apps and the most-assigned
  apps first; one-off apps last. This front-loads the risk reduction.
- Name everything with `<Purpose> – <Scope> – <Stage>`. Consistent, self-describing names for apps,
  detection rules, requirement rules, and ring groups keep a large estate searchable and auditable.
- Recreate assignment intent exactly. Required, available, and uninstall intent must match the source
  workflow so the same users/devices get the same apps — assignment parity is what users feel.
- Rebuild dependencies before the apps that need them. Create the runtime app first and auto-install
  it via the main app's dependency declaration, rather than assigning runtimes separately.
- Plan supersedence deliberately. Choose uninstall-previous (clean replace) or in-place upgrade per
  the installer's real behavior; do not guess.
- Avoid double-installs during coexistence. Retire the Workspace ONE assignment for an app only after
  the Intune deployment is confirmed healthy, so a device managed by both platforms is not served the
  app twice.
- Keep the source installer media and silent switches. Repackaging needs the original media; store it
  in a software repository so a future rebuild does not stall hunting for the installer.
- Report and chase laggards every cycle. Track install status with `WS1APP-Report.ps1` and remediate
  Failed devices with `WS1APP-Remediation.ps1` (default `-WhatIf`) before expanding.
- Document the mapping. Record the source-to-target app type and group mapping, detection rule, and
  assignment intent per app for audits and repeatability.
