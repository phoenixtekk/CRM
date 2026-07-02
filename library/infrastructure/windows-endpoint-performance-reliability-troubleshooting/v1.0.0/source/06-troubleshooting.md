# Troubleshooting

This section is for when the **diagnostic tooling itself** does not behave — the measurements you rely
on in the playbook are missing, empty, or throwing errors. Fix these first, or the numbers you read
will be wrong. (For fixing the *device's* performance, use **03 — Diagnostic Playbook**; this is about
fixing your ability to *measure* it.)

---

## The scripts report "NOT READY" / prerequisite failures

**Symptom:** WINPERF-Discovery.ps1 prints NOT READY, or a script errors on access.

- **Not elevated.** Re-launch PowerShell **as administrator** (R1). Verify with the `IsInRole`
  check in **05 — Testing → T1**. When running via Intune Scripts/Remediations you run as SYSTEM
  (already elevated).
- **Execution policy blocks the script.** Launch with
  `powershell -ExecutionPolicy Bypass -File .\WINPERF-Discovery.ps1` (per-process, permanent nothing).
- **Wrong PowerShell version.** `$PSVersionTable.PSVersion` must be ≥ 5.1.

---

## Boot timing is empty (no event 100)

**Symptom:** the Diagnostics-Performance query returns nothing.

- The **Diagnostics-Performance/Operational** log is disabled. Enable it:
  `wevtutil sl "Microsoft-Windows-Diagnostics-Performance/Operational" /e:true`, then perform a normal
  power-off/power-on cycle (not just a reboot) so boot events are written; re-query afterwards.
- The device has not had a full boot recently — event 100 is written at boot. Reboot and re-check.
- On some VMs, boot performance eventing is limited; note "boot timing unavailable (virtual)" rather
  than recording a false pass, and lean on the Sign-in and Resource branches.

---

## Sign-in duration unavailable

**Symptom:** no Endpoint analytics sign-in data, or the User Profile Service log is empty.

- **Endpoint analytics not onboarded / not licensed** (R5). Use the local User Profile Service log
  instead: `Get-WinEvent -LogName 'Microsoft-Windows-User Profile Service/Operational'`. If that log
  is also empty, enable it via `wevtutil` and re-test after a sign-out/sign-in.
- Analytics data lags onboarding by a few days — if you just enabled it, wait for collection.

---

## Performance counters return errors or nonsense

**Symptom:** `Get-Counter` throws, or values are obviously wrong (e.g., negative, or always 0).

- **Corrupt counters.** Rebuild them elevated: `lodctr /R` (and, for WMI-exposed counters,
  `winmgmt /resyncperf`), then retry.
- **Localized counter names.** On non-English Windows, counter paths differ. Use the language-neutral
  index form or run the Validation script, which resolves counters by ID.
- **Service disabled.** Ensure **Performance Counter DLL Host** / **Performance Logs & Alerts** are not
  disabled.

---

## Storage health / SMART shows nothing

**Symptom:** `Get-PhysicalDisk` HealthStatus is blank, or `MSStorageDriver_FailurePredictStatus`
throws.

- **Virtual disk / VM** — SMART is not passed through. Record "SMART unavailable (virtual)"; rely on
  free-space and disk-% signals instead. Do not report a false PASS.
- **Storage driver too old** — update the storage controller/disk driver so the health APIs populate.
- **Namespace/class access** — run elevated; the `root\wmi` class requires administrator context.

---

## Remediation appears to "do nothing"

**Symptom:** WINPERF-Remediation.ps1 runs but nothing changes.

- **This is by design.** Remediation **defaults to `-WhatIf`** — it *previews* changes without making
  them. Read the preview output; when satisfied, re-run in apply mode (drop `-WhatIf` / confirm).
- **Nothing met the safety criteria** — the script only touches non-essential startup items, safe temp
  paths, and profile caches. If there is nothing safe to clean, it correctly reports "no action".

---

## Set-ScopeTargeting cannot connect to Graph

**Symptom:** WINPERF-Set-ScopeTargeting.ps1 fails at `Connect-MgGraph`.

- **Module missing** — `Install-Module Microsoft.Graph -Scope CurrentUser` (R7).
- **Scope not consented** — an admin must consent to `Group.ReadWrite.All`. Re-run
  `Connect-MgGraph -Scopes 'Group.ReadWrite.All'`.
- **Preview mode masking intent** — the script defaults to `-WhatIf`; it will *describe* the group
  changes without making them. Confirm the plan, then re-run in apply mode.

---

## The fix didn't hold / the symptom returned

- **You isolated the wrong branch.** Re-run **WINPERF-Validation.ps1** and follow the next-most-likely
  branch in the root-cause tree (**01 — Solution Overview**).
- **The real cause is hardware** (failing drive, insufficient RAM, thermal/power). Software fixes will
  not stick — deliver the measured hardware recommendation instead (see **07 — Best Practices §7**).
- **A fleet-wide cause** (a bad driver or app in the image) reappears per device — fix it at the image
  / policy level, not one machine at a time.
