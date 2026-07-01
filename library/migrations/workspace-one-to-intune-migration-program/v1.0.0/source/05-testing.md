# 5. Testing & Acceptance — Workspace ONE to Microsoft Intune Migration Program (Windows, iOS/iPadOS, Android, macOS)

Testing is organized as numbered tests, each with an explicit **PASS/FAIL gate**, grouped by platform plus program-level groups. Each platform also has an **acceptance gate** — the combined condition that must be met before that platform's wave is declared complete and before the corresponding Workspace ONE devices may be decommissioned (Phase 10). The pilot wave must clear **all** gates before any production wave begins (the pilot-wave gate).

> Run `scripts\WS1PROG-Validation.ps1` to automate the scripted portions; the manual gates below are operator-verified on a device. Record results in `Validation Results – Program – <Wave NN>`.

---

## Group 0 — Target readiness (run before any cutover)

**T0.1 — Enrollment plumbing.** In `https://intune.microsoft.com` → **Devices → Enrollment**, APNs is **Active** (not near expiry), the ADE token is synced (corporate Apple), managed Google Play is connected (Android), and Windows automatic enrollment is set.
- PASS: every in-scope platform's channel is Active. FAIL: any required channel missing/expired.

**T0.2 — Parity & compliance built.** `Parity Policy Set – <Platform> – Target` and `Compliance Policy – <Platform> – Target` exist for each in-scope platform.
- PASS: present for all in-scope platforms. FAIL: any missing.

**Target-readiness gate:** T0.1–T0.2 PASS before assigning to any wave.

---

## Group 1 — Windows

**T1.1 — Enrollment state.** The device shows in `https://intune.microsoft.com` → **Devices → Windows** as Intune-managed and Entra-joined/hybrid-joined, and is no longer managed by Workspace ONE.
- PASS: Intune-managed, single MDM. FAIL: not enrolled or dual-managed.

**T1.2 — Parity profiles.** Wi-Fi, VPN, certificate, and restriction profiles from `Parity Policy Set – Windows – Target` show **Succeeded**.
- PASS: all applied. FAIL: any profile error / missing access (e.g. Wi-Fi cert).

**T1.3 — Compliance.** Device evaluates **Compliant** against `Compliance Policy – Windows – Target`.
- PASS: Compliant. FAIL: Not compliant.

**T1.4 — Apps.** Required Windows apps (Win32/Store/MSI) install and report **Installed**.
- PASS: all required apps installed. FAIL: install failure.

**Windows acceptance gate:** T1.1–T1.4 PASS for 100% of the wave's Windows devices.

---

## Group 2 — iOS/iPadOS

**T2.1 — Enrollment state.** Device shows Intune-managed under **Devices → iOS/iPadOS**; corporate devices show enrolled via `ADE Enrollment Profile – iOS – Target`; no Workspace ONE management profile remains.
- PASS: Intune-managed, single MDM. FAIL: still on source / unmanaged.

**T2.2 — Parity profiles.** Wi-Fi, VPN, certificate, and restriction profiles apply (delivered via APNs).
- PASS: profiles present and effective. FAIL: missing profile / broken access.

**T2.3 — Compliance.** Device is **Compliant** against `Compliance Policy – iOS – Target`.
- PASS: Compliant. FAIL: Not compliant.

**T2.4 — Apps.** VPP/managed apps install with correct managed app config.
- PASS: apps installed, config applied. FAIL: app/config missing.

**iOS/iPadOS acceptance gate:** T2.1–T2.4 PASS for the wave's iOS devices.

---

## Group 3 — Android

**T3.1 — Enrollment state & mode.** Device shows Intune-managed under **Devices → Android** in the correct mode (work profile / fully managed / dedicated); no Workspace ONE work profile remains.
- PASS: correct mode, single MDM. FAIL: wrong mode / still on source.

**T3.2 — Parity profiles.** Android policies (restrictions, Wi-Fi, certificate) apply.
- PASS: applied. FAIL: missing.

**T3.3 — Compliance.** Device is **Compliant** against `Compliance Policy – Android – Target`.
- PASS: Compliant. FAIL: Not compliant.

**T3.4 — Apps.** managed Google Play apps install with managed config.
- PASS: apps installed. FAIL: install failure.

**Android acceptance gate:** T3.1–T3.4 PASS for the wave's Android devices.

---

## Group 4 — macOS

**T4.1 — Enrollment state.** Mac shows Intune-managed under **Devices → macOS**; corporate Macs show enrolled via `ADE Enrollment Profile – macOS – Target`; no Workspace ONE profile remains.
- PASS: Intune-managed, single MDM. FAIL: still on source / unmanaged.

**T4.2 — Parity profiles.** Wi-Fi, VPN, certificate, and configuration profiles (and any shell scripts) apply.
- PASS: applied. FAIL: missing / broken access.

**T4.3 — Compliance.** Mac is **Compliant** (e.g. FileVault, OS minimum) against `Compliance Policy – macOS – Target`.
- PASS: Compliant. FAIL: Not compliant.

**T4.4 — Apps.** PKG/DMG/managed-store apps install.
- PASS: apps installed. FAIL: install failure.

**macOS acceptance gate:** T4.1–T4.4 PASS for the wave's Macs.

---

## Group 5 — Identity & Access (program-level, per wave)

**T5.1 — Sign-in & MFA.** A migrated user signs in and satisfies MFA on the migrated device.
- PASS: authenticates. FAIL: auth error.

**T5.2 — Conditional Access.** Migrated, compliant devices retain access; the do-no-harm posture has not locked out un-migrated cohorts in the same wave window.
- PASS: migrated devices access resources, un-migrated cohorts unaffected. FAIL: lockout of either.

**Access acceptance gate:** T5.1–T5.2 PASS for the wave.

---

## Group 6 — Coexistence integrity (program-level)

**T6.1 — Single-MDM check.** No in-scope device is simultaneously managed by Workspace ONE and Intune.
- PASS: every migrated device is single-MDM (Intune). FAIL: any dual-managed device.

**T6.2 — Rollback rehearsal (pilot only).** On a pilot device, the documented per-device rollback (re-enroll to Workspace ONE / revert assignment) is exercised successfully.
- PASS: rollback restores source management. FAIL: rollback fails.

**Coexistence acceptance gate:** T6.1 PASS for the wave; T6.2 PASS once during pilot.

---

## Program-level exit (per wave)

A wave is **complete** only when **every** platform acceptance gate plus the access and coexistence gates above are PASS, and `scripts\WS1PROG-Report.ps1` shows the wave 100% migrated-and-compliant. **No Workspace ONE device or assignment may be decommissioned** (Phase 10) until its wave's gates pass and the grace period defined in `07-best-practices.md` has elapsed. The **pilot wave** must clear all of the above before any production wave begins.
