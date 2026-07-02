# Testing

Use these gates to prove an app deployment is actually fixed — not just that it moved past one stage.
An app is only "fixed" when it passes **all three** gates on a representative device. Run
`INTAPPDX-Validation.ps1` to read each state from Graph, and confirm against the device logs and the
Intune console.

---

## Gate 1 — Requirement met (the app applies)

**What it proves:** the device is in scope and every requirement rule passes, so the app will
attempt to install.

**Pass:**
- Intune → app → **Device install status** shows the device as anything other than **Not
  applicable** (it should progress to installing/installed).
- `INTAPPDX-Validation.ps1` reports the device is targeted by an assignment and the requirement state
  is not "not applicable."
- The Management Extension log shows the requirement evaluation returning **applicable / true**.

**Fail:** Device shows **Not applicable** — return to Diagnostic Playbook **Branch A**.

---

## Gate 2 — Installed (the installer succeeded)

**What it proves:** content downloaded and the installer returned a success exit code.

**Pass:**
- `AppWorkload.log` shows the install command line running and returning a **success** code
  (0, 1707, 3010, or 1641).
- Intune → **Device install status** advances past **Waiting for install status**.
- The application's files/registry entries are present on the device.

**Fail:**
- Stuck at **Waiting for install status** with download activity → **Branch D**.
- **Failed (0x…)** with a non-success exit code → **Branch E**.
- Blocked by a dependency/supersedence link → **Branch C**.

---

## Gate 3 — Detected (Intune confirms it is present)

**What it proves:** the detection rule matches the installed app, so Intune reports success and stops
re-installing.

**Pass:**
- Intune → **Device install status** shows **Installed**.
- `INTAPPDX-Validation.ps1` reports `installState = installed` and detection satisfied.
- The Management Extension log shows the detection rule returning **detected** immediately after the
  success exit code, and the app is **not** re-attempted on the next cycle.

**Fail:** Installer succeeded but status is **Failed** or the app re-installs every cycle →
**Branch B** (detection wrong).

---

## Full-pipeline regression check

After a fix, run this end-to-end on a pilot device:

1. Force a sync (`INTAPPDX-Remediation.ps1` or the device **Sync** button).
2. Run `INTAPPDX-Validation.ps1` for the device.
3. Confirm all three gates pass in one run.
4. Run `INTAPPDX-Report.ps1` for the app and confirm the pilot group's **coverage** improves and the
   **failure** count for that app drops.

Only when Gates 1–3 all pass on the pilot should you expand the assignment to the broader fleet.
