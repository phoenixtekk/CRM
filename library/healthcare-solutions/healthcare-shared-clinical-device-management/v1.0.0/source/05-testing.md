# 5. Testing Guide — Healthcare Shared Clinical Device Management — WOWs, Kiosks & Tablets in Microsoft Intune

Run these tests on **pilot devices** (one of each type) before expanding to the fleet. Each test
states **how to run it**, the **expected result**, and a **PASS/FAIL** condition. The
**acceptance gate** at the end must be fully met before Phase 7 (Expand).

> Test against the named objects from `03-implementation.md`:
> `Clinical Shared – Self-Deploying – Provision`, `Clinical Shared – ESP – Provision`,
> `Clinical Shared – Shared PC Mode – Standardize`, `Clinical Shared – WOW Always-On – Standardize`,
> `Clinical Shared – Kiosk Assigned Access – Lock-down`, group `Clinical – Shared Devices`.

## T1 — Device self-provisions unattended (Autopilot self-deploying)
**How:** Factory-reset a pilot device on the cart/kiosk stand with network reachable and **no user signing in**. Let it run.
**Expected:** The device runs `Clinical Shared – Self-Deploying – Provision` with **no user interaction**, joins Microsoft Entra ID, enrolls in Intune, and completes `Clinical Shared – ESP – Provision`.
**PASS:** Device reaches the desktop/kiosk fully provisioned with **no human input**; Intune shows it Entra-joined and enrolled.
**FAIL:** Provisioning prompts for a user, stalls, or errors at OOBE/ESP.

## T2 — No personal owner (primary user = None)
**How:** Intune → **Devices → Windows → All devices →** (pilot device) → **Properties**; or run **`CLINDEV-Validation.ps1`**.
**Expected:** **Primary user = None** on every shared device.
**PASS:** No primary user is bound to any shared device.
**FAIL:** A device shows a personal primary user (run `CLINDEV-Remediation.ps1 -Apply` to clear).

## T3 — Shared PC mode is active
**How:** Run **`CLINDEV-Validation.ps1`** (checks the device's Shared PC state) and confirm in Intune → device → **Device configuration** that `Clinical Shared – Shared PC Mode – Standardize` shows **Succeeded**. On the device, `MDM Diagnostics` / registry confirms SharedPC `EnableSharedPCMode` is set.
**Expected:** Shared PC mode enabled; account management and cleanup thresholds applied.
**PASS:** Profile = Succeeded and the device reports Shared PC mode enabled.
**FAIL:** Profile shows Error/Not applicable or the device is not in Shared PC mode.

## T4 — Fast multi-user logon
**How:** On a WOW/nurse-station PC, sign in as clinician A, sign out, sign in as clinician B, then C — timing each sign-in. (If tap hand-off is in scope, use badge tap.)
**Expected:** Each clinician signs in quickly; cycled accounts are cleaned up over time per the threshold; no per-user clutter accumulates.
**PASS:** Successive different users sign in cleanly and reasonably fast; the device stays usable across many sign-ins.
**FAIL:** Sign-in is slow/blocked for new users, or stale per-user data accumulates and degrades the device.

## T5 — Kiosk lock holds (single-purpose devices)
**How:** On a single-purpose kiosk assigned `Clinical Shared – Kiosk Assigned Access – Lock-down`, attempt to leave the locked app: keyboard shortcuts, task switching, browser address bar / file dialogs, etc.
**Expected:** The device stays confined to the allowed app(s); the user cannot reach the desktop, settings, or other apps.
**PASS:** The Assigned Access lock holds against escape attempts; only the allowed app(s) are reachable.
**FAIL:** A user can break out to the desktop, other apps, settings, or a browser outside the allowed scope.

## T6 — Clinical apps present
**How:** On each device type, confirm every app in the standardized baseline is installed and launches; cross-check Intune → device → **Managed apps** / **`CLINDEV-Validation.ps1`**.
**Expected:** The full clinical app baseline (named exactly as published — e.g. the Epic Hyperdrive client, browser, PDF reader, secure messaging) is **installed (Required)** and launches.
**PASS:** Every baseline app is present and opens on every device of that type.
**FAIL:** Any baseline app is missing or fails to launch.

## T7 — Stays awake on cart battery
**How:** Unplug a WOW so it runs on battery, leave it idle past the display-off time, return after the previous sleep window would have elapsed.
**Expected:** The display may dim/turn off, but the **device does not sleep or hibernate**; it wakes instantly to the lock screen and any session/state is intact.
**PASS:** Device remains awake on battery (no sleep/hibernate); instant resume to lock screen.
**FAIL:** Device sleeps/hibernates on battery, forcing a slow resume or losing the session.

## T8 — Correct group membership and reporting
**How:** Run **`CLINDEV-Report.ps1`** and confirm each pilot device appears in **`Clinical – Shared Devices`** with the right device type, profiles, and compliance.
**Expected:** Every shared device is in the group and reported under the correct type/profile.
**PASS:** Report shows complete, correct membership and profile assignment for all pilot devices.
**FAIL:** A device is missing from the group or shows the wrong profile/type.

---
## Acceptance gate (must all PASS before Expand)
- [ ] **T1** Device self-provisions unattended (self-deploying Autopilot)
- [ ] **T2** No personal owner — primary user = None on every shared device
- [ ] **T3** Shared PC mode active (profile Succeeded)
- [ ] **T4** Fast multi-user logon works across successive clinicians
- [ ] **T5** Kiosk lock holds on single-purpose devices (where applied)
- [ ] **T6** Full clinical app baseline present and launching
- [ ] **T7** WOWs stay awake on cart battery (no sleep/hibernate)
- [ ] **T8** Correct `Clinical – Shared Devices` membership + reporting

Only when **every** applicable item is **PASS** should you proceed to **Expand** (Phase 7) and roll
out to the full fleet in waves within approved maintenance windows.
