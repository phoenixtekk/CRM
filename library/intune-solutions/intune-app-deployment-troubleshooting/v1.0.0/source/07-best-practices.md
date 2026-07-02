# Best Practices

These practices prevent the failures the Diagnostic Playbook exists to fix. Apply them when you
package and assign apps, and most deployments never reach a symptom branch.

---

## Detection rules — make them match reality

- **Detect what the installer actually leaves behind.** Before you author a detection rule, install
  the app on a clean device and confirm the exact product code, file path + version, or registry
  value it creates. Author the rule from the real artifact, not from the vendor's documentation.
- **Prefer stable artifacts.** A registry value or a versioned key under `Uninstall` is more stable
  than a loose file whose path or name can change between builds.
- **Mind the 32-bit vs 64-bit split.** Point file rules at `Program Files` vs `Program Files (x86)`
  correctly, and set the **32-bit registry view** checkbox to match where the app writes.
- **Use version operators deliberately.** "Greater than or equal to" survives minor updates; an
  "equals" rule breaks the moment the app auto-updates and must be maintained.
- **Custom detection scripts:** write a value to STDOUT and **exit 0** to signal detected; print
  nothing on not-detected. Test the script as SYSTEM before shipping it.
- **Keep detection and requirement rules distinct.** Requirement = "should this install?"; detection
  = "did it install?". Mixing them causes the "Not applicable" and "installs but shows failed"
  confusion.

---

## Return codes and reboots

- **Map benign codes correctly.** Add the installer's documented success/reboot codes to the app's
  **Return codes** table so a soft-reboot code (3010) is not mistaken for a failure.
- **Handle reboots explicitly.** For apps that require a reboot to finish, use the correct return-
  code mapping rather than forcing a hard reboot mid-deployment.

---

## Dependencies and supersedence — keep them shallow

- **Keep supersedence to a single hop.** Chains deeper than one hop are unsupported and stall.
  Retire old versions cleanly rather than stacking supersedence.
- **Assign dependencies too.** A dependency must be assigned (or auto-install) and must succeed
  first; an unassigned or failing dependency silently blocks the dependent app.
- **Avoid circular links.** Never let two apps depend on each other.

---

## Phased rollout — pilot before fleet

- **Always pilot first.** Use `INTAPPDX-Set-ScopeTargeting.ps1` to assign new or changed apps to a
  small **pilot** security group before the fleet. Validate all three gates on the pilot.
- **Expand in rings.** Pilot → early adopters → broad → all. Watch `INTAPPDX-Report.ps1` coverage
  and failure counts after each ring before widening.
- **Change one thing at a time.** When fixing a failing app, change the single root-cause setting,
  re-validate, then move on — so you always know what fixed it.
- **Prefer Available over Required for optional apps.** Required apps that are Not applicable on some
  hardware generate noise; scope Required apps only to devices they truly apply to, especially in
  the ESP block list.

---

## ESP discipline

- **Only block on universal apps.** Every app in the ESP "block device use" list must apply to
  **every** enrolling device; a Not-applicable app there blocks enrollment forever.
- **Set a realistic timeout.** Give slow-but-legitimate installs enough time; too short a timeout
  fails good deployments.
- **Test enrollment end to end.** Re-image a test device after any ESP or blocking-app change.

---

## Operational hygiene

- **Keep the read-only scripts scheduled.** Run `INTAPPDX-Report.ps1` regularly to catch rising
  failure rates before users report them.
- **Read the log, don't guess.** The Management Extension log is authoritative for requirement,
  download, exit code, and detection — check it before changing settings.
- **Keep remediation gated.** Run `INTAPPDX-Remediation.ps1` and `INTAPPDX-Set-ScopeTargeting.ps1`
  in the default **-WhatIf** mode first, review the planned change, then re-run to apply.
