# Testing

Use these gates to prove a Win32 app is **actually removed** — not merely that Intune says so, and
not merely that it left one stage. Removal is only "fixed" when it passes **all four** gates on a
device in `APPUNIN – Uninstall – Pilot`. Run `APPUNIN-Validation.ps1` to read state from Graph and
`APPUNIN-Discovery.ps1` on the device to confirm the on-disk reality, and check both against the IME
log.

The gates deliberately test the two things the console alone cannot tell you: that the software is
**physically gone from the device**, and that Intune **stops trying to remove it**.

---

## Gate 1 — Gone from the device (the software is physically removed)

**What it proves:** the uninstall command actually ran and removed the app — the console's word is
not enough (Branch B fails here even when Intune reports success).

**Pass:**
- On the device, `APPUNIN-Discovery.ps1` finds **no** registered ProductCode / UninstallString for
  the app under either `HKLM` or `HKCU`.
- The app's install directory and primary executable are gone.
- No leftover service or scheduled task for the app remains.

**Fail:** The app is still registered or its files remain → the uninstall never ran (**Branch B**:
detection said "gone" pre-emptively) or the command failed (**Branch D/E/G**).

---

## Gate 2 — Uninstall command returned success

**What it proves:** the uninstall command executed and Windows Installer / the vendor uninstaller
returned a success (or legitimate reboot) code.

**Pass:**
- `AppWorkload.log` shows the uninstall command line running and returning **0**, **1707**, **3010**
  (soft reboot), or **1641** (hard reboot).
- Any code the vendor documents as success is **mapped as success** in
  **Properties > Return codes**.

**Fail:**
- **1605** → wrong/stale ProductCode → **Branch D**.
- **1603** or vendor non-zero → wrong command/switches → **Branch E**.
- **1618** or files-in-use → app running / installer busy → **Branch G**.

---

## Gate 3 — Intune agrees it is gone (state = Not installed)

**What it proves:** post-uninstall detection returned **not detected**, so Intune reports the removal
as successful.

**Pass:**
- Intune → **Apps > All apps > _<your app>_ > Device install status** shows the device as
  **Not installed**.
- `APPUNIN-Validation.ps1` reports `installState = notInstalled` for the device.
- The IME log shows the post-uninstall detection rule returning **not detected**.

**Fail:**
- Reports **Uninstall failed** with a success exit code just above it → detection still matches a
  remnant → **Branch C**.
- Reports **Installed** with no uninstall attempt → intent conflict → **Branch A**.

---

## Gate 4 — It stays gone (no re-attempt on the next cycle)

**What it proves:** the removal is stable — Intune is not stuck in a re-uninstall loop, and the app
does not reappear.

**Pass:**
- Run `APPUNIN-Validation.ps1` again after **a second** sync cycle: the device is still
  **Not installed**, and the IME log shows **no** new uninstall attempt for the app on that cycle.
- `APPUNIN-Report.ps1` shows the app's **uninstallFailed** count at **0** and the **notInstalled**
  count rising as the pilot completes.

**Fail:** The uninstall runs again on the next cycle → detection loop → **Branch C**; or the app
reappears → an intent conflict re-installed it → **Branch A**.

---

## Full-removal regression check (run on the pilot before expanding)

1. Confirm the device is in `APPUNIN – Uninstall – Pilot` and **not** in any Required/Available group
   for the app (`APPUNIN-Validation.ps1 -CheckConflicts`).
2. Force a sync (`APPUNIN-Remediation.ps1 -Action Resync -WhatIf:$false`, or the device **Sync**
   button).
3. After one cycle, run `APPUNIN-Validation.ps1` and `APPUNIN-Discovery.ps1` — confirm **Gates 1–3**.
4. After a **second** cycle, re-run both — confirm **Gate 4** (stable, no re-attempt).
5. Run `APPUNIN-Report.ps1` and confirm the pilot group's **notInstalled** count is complete and
   **uninstallFailed** is zero.

Only when **all four gates** pass on the pilot should you move the Uninstall assignment from
`APPUNIN – Uninstall – Pilot` to `APPUNIN – Uninstall – Production`.
