# 7. Best Practices — Intune Win32 Application Packaging & Deployment

- **Assign to a pilot ring first, always.** A small `App Deployment – Pilot Devices – Ring 1` catches
  a bad package before it reaches `App Deployment – Broad Devices – Ring 2` — the single most
  important practice. The pilot is the gate.
- **Make detection deterministic.** Use an MSI product code, or a file path + version, or a registry
  value — never a vague guess. A wrong detection rule is the number-one cause of "installed but shows
  failed" and reinstall loops.
- **Requirement rules gate; detection rules confirm.** Use requirements (x64, minimum OS) to keep the
  app off devices that can't run it (reported Not applicable), and detection only to confirm presence.
- **Test the command lines on a clean VM first.** Confirm the silent install and uninstall both return
  exit code `0` before you ever package — Intune runs them verbatim.
- **Model dependencies, don't hope.** Package a required runtime as its own Win32 app and declare it as
  a dependency with auto-install, so it always lands first.
- **Use supersedence for upgrades.** Replace the prior version via supersedence rather than deploying a
  second app — it prevents duplicates and orphaned old versions.
- **Name everything with `<Purpose> – <Scope> – <Stage>`.** Self-describing names (apps, groups,
  detection/requirement rules) make a growing app catalog auditable and searchable.
- **Version your packages and source.** Keep each `.intunewin` and its source folder in an
  `App\Version\` store so you can rebuild and trace exactly what is deployed.
- **Honor `/norestart`.** Let return codes (`3010` soft reboot, `1641` hard reboot) and your restart
  policy control reboots; avoid surprise restarts mid-day.
- **Watch the report and chase laggards.** Track Installed / Failed / Not applicable with
  `WIN32-Report.ps1` and remediate failures with `WIN32-Remediation.ps1` (default `-WhatIf` first).
- **Document each app's deployment record.** Record the install/uninstall commands, detection value,
  requirements, dependencies, and ring assignments for audits and repeatability.
