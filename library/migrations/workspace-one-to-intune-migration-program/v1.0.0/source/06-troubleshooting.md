# 6. Troubleshooting — Workspace ONE to Microsoft Intune Migration Program (Windows, iOS/iPadOS, Android, macOS)

Failure modes and fixes, grouped by area. Most migration problems trace back to two root causes: **a device still (partly) enrolled in Workspace ONE while Intune tries to take over**, and **a profile/app that was never rebuilt to parity** in the target. Workspace ONE console actions below are named by action only — exact menus are deferred to current VMware documentation.

---

## A. Enrollment — device won't enroll into Intune

**Symptom:** Windows device released from Workspace ONE but does not appear in Intune.
- **Cause:** Windows automatic enrollment / MDM user scope not set, or the device hasn't re-signed in to Entra.
- **Fix:** Confirm `https://entra.microsoft.com` → **Mobility (MDM and MAM) → Microsoft Intune** MDM user scope (R3); on the device, **Access work or school → Connect** or sign out/in; re-run `WS1PROG-Remediation.ps1 -Mode RetryEnrollmentSync`.

**Symptom:** iOS/macOS device fails to enroll or shows an APNs error.
- **Cause:** APNs certificate missing/expired, or it was **recreated** instead of renewed (which orphans existing devices).
- **Fix:** In `https://intune.microsoft.com` → **Devices → Enrollment → Apple → Apple MDM Push certificate**, confirm **Active**; if expired, **renew** the same certificate (never recreate). Re-attempt enrollment.

**Symptom:** Android device won't enroll in the expected mode.
- **Cause:** managed Google Play not connected, or the wrong enrollment profile/mode for the device's ownership.
- **Fix:** Confirm **Devices → Enrollment → Android** managed Google Play is connected; select the correct mode (work profile / fully managed / dedicated) for the cohort; for fully managed/dedicated, the device must be factory reset and enrolled via the corporate method.

---

## B. Coexistence — dual management / single-MDM violations

**Symptom:** Device shows managed by both Workspace ONE and Intune (or behaves erratically with conflicting policy).
- **Cause:** The device was assigned the Intune production state before being released from Workspace ONE — both platforms targeting the same device.
- **Fix:** A device is single-MDM by design. Release it from Workspace ONE (action named; deferred to VMware docs), confirm only the Intune enrollment remains, then re-validate (T6.1). Target only migrated devices via `Wave NN Devices – <Scope> – Wave NN`.

**Symptom:** Un-migrated users in the same wave window lose access during coexistence.
- **Cause:** Conditional Access was tightened to require Intune compliance before those devices migrated.
- **Fix:** Restore the do-no-harm posture (R8): set the tightening CA policy to **report-only**, and enforce Intune-compliance requirements **only** for cohorts that have cut over (Phase 9).

---

## C. Apple Business Manager / ADE assignment

**Symptom:** Corporate Apple device re-enrolls but lands unmanaged or on the wrong MDM.
- **Cause:** The device's MDM server in Apple Business Manager still points at the source, or no Intune ADE enrollment profile is assigned.
- **Fix:** In `https://business.apple.com` → **Devices**, re-assign the device's **MDM server** to the Intune MDM server; in `https://intune.microsoft.com` → **Devices → Enrollment → Apple → Enrollment program tokens → (open the ADE token) → Profiles**, confirm `ADE Enrollment Profile – iOS – Target` / `ADE Enrollment Profile – macOS – Target` is assigned; reset the device so Setup Assistant re-enrolls it into Intune.

**Symptom:** ADE token shows no devices / devices missing after sync.
- **Cause:** Token not synced, or devices not yet released by the source.
- **Fix:** Sync the ADE token in Intune; release the devices from Workspace ONE / re-assign in ABM; re-sync. Releasing the source DEP/ADE token entirely is a Phase 10 (decommission) step, not a per-device one.

---

## D. Parity profiles — applied in Intune but access broken

**Symptom:** Device shows compliant/enrolled but loses Wi-Fi, VPN, or a certificate-gated resource after leaving Workspace ONE.
- **Cause:** The Wi-Fi / VPN / certificate profile was not rebuilt to parity, or the certificate connector (SCEP/PKCS) isn't issuing.
- **Fix:** Check `Parity Policy Set – <Platform> – Target` for the missing profile; rebuild it in **Devices → Configuration** to match the source exactly; if cert-based, confirm the SCEP/PKCS connector is healthy and the profile chains correctly. A profile that shows **Succeeded** but doesn't grant access is still a FAIL (T*.2) — test real access.

**Symptom:** Profile shows **Error** / conflict in Intune.
- **Cause:** Two profiles set conflicting values, or a residual Workspace ONE profile remains on the device.
- **Fix:** Resolve the conflicting Intune profiles; confirm the Workspace ONE management profile was fully removed at cutover; re-sync the device.

---

## E. App delivery

**Symptom:** Required apps don't install after migration.
- **Cause:** App not rebuilt/assigned in Intune, missing VPP/managed-Google-Play licensing, or a bad Win32 detection rule/silent command.
- **Fix:** Confirm the app exists in **Apps → All apps** and is assigned to the wave group; for store apps confirm VPP/managed Google Play licensing; for Win32 verify the `.intunewin`, silent install/uninstall, and **detection rule**. Identify store apps by exact publisher + bundle/package ID to avoid the wrong app.

**Symptom:** App installs but per-app config (mail, per-app VPN) is missing.
- **Cause:** Managed app configuration that Workspace ONE delivered was not rebuilt.
- **Fix:** Add the Intune managed app configuration policy for that app; re-assign; re-validate (T*.4).

---

## F. Compliance & Conditional Access

**Symptom:** Migrated device shows **Not compliant**.
- **Cause:** `Compliance Policy – <Platform> – Target` not assigned, OS below minimum, or encryption/jailbreak/root check failing.
- **Fix:** Confirm the compliance policy is assigned to the wave group; remediate the failing setting (OS update, enable encryption); use `WS1PROG-Remediation.ps1 -Mode ReEvaluateCompliance` to force a re-check.

**Symptom:** User blocked from resources right after a successful migration.
- **Cause:** Compliance not yet evaluated, or CA enforcing before the grace evaluation completes.
- **Fix:** Allow compliance evaluation to complete; confirm the device is Compliant (T*.3); keep CA report-only for the wave until devices evaluate, then enforce (Phase 9).

---

## G. Identity / targeting

**Symptom:** Device enrolls but receives no policy or apps.
- **Cause:** The device/user isn't in the wave group, or the user didn't reconcile to an Entra user (UPN mismatch from Discovery).
- **Fix:** Confirm membership of `Wave NN Devices – <Scope> – Wave NN`; fix the UPN reconciliation flagged in Phase 1; re-add with `WS1PROG-Remediation.ps1 -Mode AddToWaveGroup`.

**Symptom:** Hybrid Windows device won't Entra-hybrid-join.
- **Cause:** SCP/Entra Connect hybrid-join config incomplete, or the device hasn't synced.
- **Fix:** Confirm Entra Connect sync and the hybrid-join SCP/GPO (R4); allow the join task to run; verify in `https://entra.microsoft.com` → **Devices**.

---

## H. Rollback

**Symptom:** A migrated device must be reverted to Workspace ONE.
- **Cause:** Failed parity/access on a production device inside the change window.
- **Fix:** Execute the documented per-device rollback (R13): revert/remove the Intune assignment, re-enroll the device into Workspace ONE (action named; deferred to VMware docs). Only possible while the source assignment is still warm — which is why the grace period exists before decommission (Phase 10).

**Symptom:** Rollback fails because the source already released the device/token.
- **Cause:** Workspace ONE was decommissioned (or the device released) before the grace period elapsed.
- **Fix:** Do not decommission until the wave passes and the grace period elapses (Phase 10 discipline). If already released, treat the device as a fresh Intune enrollment and remediate forward rather than rolling back.

---

## I. Reporting / evidence gaps

**Symptom:** Wave status is unclear or a device's state is ambiguous.
- **Cause:** The program register / wave plan isn't current, or reporting wasn't run per wave.
- **Fix:** Run `scripts\WS1PROG-Report.ps1` after each wave; keep the named-object list, wave plan, and per-gate results current as you go (best practice §07) — backfilling after the fact is unreliable and undermines rollback decisions.
