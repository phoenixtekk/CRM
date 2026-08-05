# Best Practices

These practices stop the removal failures the Diagnostic Playbook exists to fix. Apply them when you
first **package and assign** an app, and most removals later just work.

---

## Author the uninstall command at package time — not at removal time

- **Record the correct silent uninstall command the day you package the app**, and store it in the
  app's **Properties > App information > Notes**. The worst time to discover the right switch is
  during an emergency fleet removal.
- **For MSI apps, never hard-code a single ProductCode if the app will ever be upgraded.** Major
  upgrades change the ProductCode. Prefer an uninstall command that **resolves the ProductCode by
  UpgradeCode or DisplayName at run time** (the wrapper in Branch D), so removal survives version
  drift across the fleet.
- **For EXE apps, get the silent-uninstall switch from the vendor's documentation** and confirm it —
  install and uninstall switches are frequently different. Test the uninstall by hand, as SYSTEM,
  and confirm it exits **0** with no UI.
- **Quote every path with spaces** in the uninstall command, and prefer environment variables
  (`%ProgramFiles%`) over hard-coded drive paths.

---

## Detection rules decide removal — make them match reality on both ends

- **Detect the primary artifact the uninstaller removes** — the main executable (with a version
  operator) or the MSI ProductCode — **not** a config file, log, or registry key the uninstaller
  leaves behind. A remnant-based rule causes the infinite re-uninstall loop (Branch C).
- **Set the version operator deliberately.** "Greater than or equal to" survives auto-updates for
  *install* detection, but for a clean removal make sure the artifact disappears entirely so
  detection flips to not-detected.
- **Mind 32-bit vs 64-bit.** Point file rules at the correct `Program Files` / `Program Files (x86)`
  location and set the **32-bit registry view** checkbox to match where the app writes — or SYSTEM
  detection will look in the wrong hive (Branch B/F).
- **Test custom detection scripts as SYSTEM.** They must print to STDOUT and exit 0 only when the app
  is present. Run them with `PsExec -s` before shipping.

---

## Keep intents unambiguous — never target install and uninstall together

- **A device must never be in both a Required/Available group and an Uninstall group for the same
  app.** `Required` wins, and the uninstall silently does nothing (Branch A). Maintain removal
  through the dedicated **Assigned** group `APPUNIN – Uninstall – Production`, and ensure those
  devices are not members of any install group for that app.
- **Watch nested groups.** A device can be in a Required group transitively. Resolve effective
  membership (`APPUNIN-Validation.ps1 -CheckConflicts`) before you trust an assignment.
- **Use `APPUNIN – Uninstall – Exclusions`** for the devices that must keep the app (break-fix, labs,
  executives), and exclude that group from the Uninstall assignment.

---

## Map return codes so benign outcomes are not failures

- **Map 3010 and 1641 as success (soft / hard reboot).** A removal that needs a reboot to finish
  deleting files is a success, not a failure.
- **Map 1618 as Retry**, not Failure — it just means Windows Installer was busy.
- **Do not map 1605 or 1603 as success** to hide a problem — those mean the removal genuinely did not
  happen; fix the command (Branch D/E) instead.

---

## Stop the app before removing it

- **For apps with a running process or service, wrap the uninstall to stop them first**
  (`Stop-Service`, `Stop-Process`) so the uninstaller is not blocked by files in use (Branch G).
- **Prefer per-machine installs.** A per-user install can never be cleanly removed for all users by a
  single SYSTEM uninstall (Branch F); if you control the packaging, install per-machine.

---

## Remove the right way — assignment first, delete the object last

- **Never delete the Intune app object to "force" removal.** Deleting the object removes your ability
  to target the app; devices that had not yet processed the Uninstall intent are orphaned with the
  software still on them (Branch I). Always assign **Uninstall**, confirm removal on the fleet, and
  only then delete the object.
- **Pilot every removal.** Assign Uninstall to `APPUNIN – Uninstall – Pilot` first, pass all four
  gates in `05-testing.md`, then expand to `APPUNIN – Uninstall – Production`. Removal is destructive
  and often not reversible without data loss.

---

## Operational hygiene

- **Schedule the read-only reporter.** Run `APPUNIN-Report.ps1` regularly to catch rising
  `uninstallFailed` counts before users notice software that should be gone.
- **Read the IME log before changing settings.** `IntuneManagementExtension.log`,
  `AppWorkload.log`, and `AgentExecutor.log` are authoritative for intent, exit code, and detection —
  check them first.
- **Keep remediation gated.** `APPUNIN-Remediation.ps1` defaults to **-WhatIf**; review the planned
  change, then re-run with `-WhatIf:$false` to apply.
