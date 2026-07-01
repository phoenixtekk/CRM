# 6. Troubleshooting Guide — Healthcare Shared Clinical Device Management — WOWs, Kiosks & Tablets in Microsoft Intune

Common failure modes for shared clinical devices and how to fix them. Each issue lists
**Symptoms · Likely cause · Diagnose · Fix.** Make all changes under change control, within a
clinical maintenance window. Objects referenced are the named ones from `03-implementation.md`.

## I1 — Autopilot self-deploy fails (device won't provision unattended)
**Symptoms:** OOBE prompts for a user, stalls, or errors (e.g. attestation/timeout) instead of self-provisioning; ESP never starts or fails.
**Likely cause:** Device not TPM 2.0 / not attestable; device not registered to Autopilot or missing the group tag; no network at first boot; profile set to user-driven; tenant self-deploying mode not available.
**Diagnose:** Confirm the device in **Devices → Enrollment → Windows → Windows enrollment → Devices** with the correct **group tag**; confirm the profile `Clinical Shared – Self-Deploying – Provision` shows **Deployment mode = Self-Deploying** and is assigned to the device's group; check `Get-Tpm` (TPM 2.0, ready) and TPM attestation support; verify network/Wi-Fi reaches Microsoft endpoints at OOBE (no captive portal/802.1X block).
**Fix:** Register the device / set the group tag so it lands in `Clinical – Shared Devices(– Pilot)`; ensure deployment mode is **Self-Deploying** and Entra-joined; enable TPM 2.0 in UEFI (if non-attestable hardware, fall back to user-driven Autopilot/provisioning package); pre-stage a wired/Wi-Fi connection so first boot has network.

## I2 — Shared PC mode not applying
**Symptoms:** `Clinical Shared – Shared PC Mode – Standardize` shows **Error / Not applicable**; device doesn't behave as a shared PC (no account cleanup, personal-style sessions persist).
**Likely cause:** Windows Home edition (SharedPC CSP unavailable); profile not assigned to the device's group; conflicting configuration; device not yet synced.
**Diagnose:** Check `winver` for **Pro/Enterprise/Education**; in Intune → device → **Device configuration**, confirm the profile is assigned and read its error; run **`CLINDEV-Validation.ps1`** for the Shared PC check; review SharedPC registry/`MdmDiagnostics`.
**Fix:** Upgrade Home editions; add `Clinical – Shared Devices` to the profile **Assignments**; resolve conflicting profiles (only one should own SharedPC settings); sync/reboot the device and re-check.

## I3 — Slow multi-user logon
**Symptoms:** New clinicians take a long time to sign in; the device feels sluggish after many shifts; sign-in occasionally fails.
**Likely cause:** Account management/cleanup thresholds too lax so cached accounts accumulate; low free disk; profiles not being deleted; first-time-per-user app/policy processing.
**Diagnose:** Run **`CLINDEV-Discovery.ps1`** / **`CLINDEV-Validation.ps1`** to inspect Shared PC state and free space; review the **Account deletion** and **Inactive account threshold** values in `Clinical Shared – Shared PC Mode – Standardize`; check disk free space on the device.
**Fix:** Tighten **Delete accounts** to *storage + inactive threshold*, lower the inactive-days threshold to match shift rotation, and set the disk thresholds so cleanup runs before the device fills; ensure the clinical apps are device-targeted **Required** (not per-user) so they don't reinstall per sign-in.

## I4 — Kiosk not locking (user breaks out)
**Symptoms:** On a single-purpose device, a user reaches the desktop, settings, a browser, or another app outside the allowed scope.
**Likely cause:** `Clinical Shared – Kiosk Assigned Access – Lock-down` not assigned (or assigned to the wrong device); wrong app identity (AUMID/package family name) so the lock targets nothing; multi-app misconfiguration; a Windows feature update changed Assigned Access behavior.
**Diagnose:** Confirm the kiosk profile is assigned to the **single-purpose** device/sub-group only and shows **Succeeded**; verify the app is specified by **exact name + AUMID/package family name**; test escape paths from T5 in `05-testing.md`; check recent Windows update history.
**Fix:** Correct the app identity and assignment; for a true single-purpose device use **Single app, full-screen kiosk** with **Auto logon**; re-test all escape paths after the fix and after any future feature update. Never apply this profile to a multi-app WOW.

## I5 — Clinical app install gaps
**Symptoms:** A device is missing one or more baseline apps; an app shows **Not installed / Failed** in Intune; the Epic client or secure-messaging app is absent.
**Likely cause:** App not assigned **Required** to `Clinical – Shared Devices`; app assigned per-user instead of per-device on an owner-less device; packaging/detection rule failure; app not in the ESP required list so provisioning didn't wait for it.
**Diagnose:** Intune → app → **Device install status**; run **`CLINDEV-Validation.ps1`** for the app-presence check; review the Win32 app **detection rules** and install logs; confirm the app is in the ESP required-apps list.
**Fix:** Assign each baseline app **Required** to the **device group** (`Clinical – Shared Devices`); fix detection rules; add the app to `Clinical Shared – ESP – Provision` required apps so future provisioning blocks until it installs. For the Epic Hyperdrive client / Imprivata agent, follow their dedicated solutions' packaging — don't hand-install on the cart.

## I6 — Devices sleeping on carts
**Symptoms:** A WOW is asleep/hibernated when a clinician returns; slow resume; lost session/state on battery.
**Likely cause:** `Clinical Shared – WOW Always-On – Standardize` not assigned or overridden; Shared PC mode power policy or another profile is sleeping the device; sleep/hibernate timeouts not set to 0 on battery; lid-close action sleeps the device.
**Diagnose:** In Intune → device → **Device configuration**, confirm the power profile is **Succeeded** and not in conflict; on the device run `powercfg /a` and `powercfg /query` to see active sleep/hibernate settings; check whether Shared PC mode or another profile is setting power policy.
**Fix:** Ensure `Clinical Shared – WOW Always-On – Standardize` is assigned and wins: set **Sleep** and **Hibernate** timeouts to **0** for **On Battery** (display-off is fine), set **Lid close action** to not sleep, and remove power settings from any competing profile (only the power profile should own power policy). Re-run **T7** in `05-testing.md`.

## I7 — Stray primary user on a shared device
**Symptoms:** A WOW/kiosk shows a personal **primary user**; the device appears tied to one clinician's identity/compliance.
**Likely cause:** A user-driven enrollment or affinity bound a primary user to a device that should be owner-less.
**Diagnose:** Intune → device → **Properties → Primary user**; or run **`CLINDEV-Validation.ps1`** (flags any primary user).
**Fix:** Run **`CLINDEV-Remediation.ps1 -WhatIf`** to preview, then **`-Apply`** to clear the primary user; ensure the device provisions via **self-deploying** (not user-driven) Autopilot so it stays owner-less going forward.

## I8 — Device missing from the group / wrong profiles
**Symptoms:** A device doesn't receive the Shared PC / power / app profiles; it isn't in `Clinical – Shared Devices`.
**Likely cause:** Missing or wrong Autopilot **group tag** so the dynamic rule doesn't match; dynamic-group membership still processing; rule logic doesn't match the device's attributes.
**Diagnose:** Entra → **Groups →** `Clinical – Shared Devices` → **Members** (and **Dynamic membership rules**); compare against the device's group tag in **Windows Autopilot devices**; run **`CLINDEV-Report.ps1`** to see membership/profile coverage.
**Fix:** Set the correct group tag on the device (Step 4 in `03-implementation.md`) or correct the dynamic rule; allow membership to process, then sync the device; re-run **`CLINDEV-Validation.ps1`**. Use **`CLINDEV-Set-SharedDeviceGroup.ps1`** to (re)create/verify the group rule.

---
### Escalation
If a device still fails after these steps, capture state with **`CLINDEV-Discovery.ps1`** and
**`CLINDEV-Validation.ps1`**, record the failing profile's Intune error, and escalate with the
device serial, Autopilot group tag, and the named profile that failed — under the active change
ticket. For Epic Hyperdrive or Imprivata-specific faults, escalate via the dedicated **Epic
Hyperdrive Client Deployment** and **Imprivata SSO** solutions.
