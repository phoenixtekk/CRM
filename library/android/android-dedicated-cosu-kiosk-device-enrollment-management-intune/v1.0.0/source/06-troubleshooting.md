# 6. Troubleshooting Guide — Android Dedicated (COSU) / Kiosk Device Enrollment & Management

Symptom → likely root cause → fix. Use **`COSU-Discovery.ps1`** (readiness),
**`COSU-Validation.ps1`** (only-allowed-apps), and **`COSU-Report.ps1`** (fleet health) to confirm
before and after each fix. Where enrollment/kiosk behavior is **version-dependent, verify against
current Microsoft guidance / your tenant** rather than assuming.

## A. Enrollment

### "Can't set up device / provisioning failed" when scanning the QR (or afw#setup)
- **Managed Google Play not bound.** Dedicated enrollment requires the managed Google Play connection
  (category G2). **Fix:** run **`COSU-Discovery.ps1`**; if the binding is not active, establish it first.
- **Device not factory-reset / already has an account.** Device-owner enrollment needs a **clean**
  device with no Google account added. **Fix:** factory-reset and enroll **before** any account is added.
- **Network blocks provisioning.** The setup path downloads the DPC and registers the device. **Fix:**
  allow the documented Google/Microsoft endpoints on the device VLAN/SSID (category G5).
- **Token expired.** The enrollment profile's token has a lifetime. **Fix:** `COSU-Discovery.ps1` reports
  the expiry; extend/rotate the token in the profile and regenerate the QR.

### QR reader won't start on the Welcome screen
- **Wrong gesture / device variant.** The QR reader is launched by **tapping the same spot ~6 times** on
  the first setup screen; some OEMs vary. **Fix:** follow the OEM's device-owner QR steps; on older
  devices use **`afw#setup`** + token instead.

### Enrollment is blocked even with a valid token
- **Enrollment restriction blocks corporate-owned Android.** **Fix:** Intune → **Devices → Enrollment →
  Enrollment restrictions → Device platform restrictions**; allow Android Enterprise (corporate-owned)
  for the scope. `COSU-Discovery.ps1` flags a blocking default.

### NFC or zero-touch device doesn't auto-enroll
- **NFC payload/tooling issue** — the NFC bump payload is OEM/tooling-specific. **Fix:** defer to the OEM
  NFC-provisioning steps and confirm the token in the payload is current.
- **Zero-touch not assigned** — the reseller must assign your **zero-touch configuration** to the device
  serials in the **zero-touch portal**. **Fix:** confirm with the reseller (portal deferred to
  Google/reseller docs); the device must be purchased through a zero-touch reseller.

## B. Device group / targeting

### Device enrolled but got no kiosk or apps
- **Not in the device group yet.** Kiosk + apps are assigned to `Android Dedicated - Devices - Pilot`;
  dynamic membership can take a few minutes. **Fix:** wait, then `COSU-Report.ps1` / check Entra group
  membership.
- **Dynamic rule doesn't match the profile.** The rule must be
  `(device.enrollmentProfileName -eq "Android Dedicated - COSU - Pilot")` — exact profile name. **Fix:**
  run **`COSU-Set-ScopeTargeting.ps1`**; it flags a rule that doesn't reference the profile.
- **Assigned to a user instead of the device group.** Dedicated devices have **no user**; user-targeted
  assignments never land. **Fix:** re-target apps/kiosk to the **device** group.

## C. Kiosk / apps

### A kiosk app is missing on the device
- **App named in the kiosk but not assigned.** The allow-list must reference apps that are **Required to
  the device group**. **Fix:** run **`COSU-Validation.ps1`** — it lists "in kiosk but not assigned";
  assign each as Required, then re-check.
- **App still installing.** Managed Google Play installs can lag enrollment. **Fix:** give it time / force
  a **Sync**; confirm in `COSU-Report.ps1`.

### Multi-app kiosk shows a blank/black home screen
- **Managed Home Screen not deployed.** Multi-app uses `com.microsoft.launcher.enterprise` as the
  launcher. **Fix:** assign **Managed Home Screen** Required to the device group; `COSU-Validation.ps1`
  FAILs when it's missing on a multi-app kiosk.

### Extra apps are visible / device isn't as locked as expected
- **Assigned-but-not-in-kiosk apps.** An app Required to the group but absent from the allow-list can be
  reachable. **Fix:** `COSU-Validation.ps1` lists these as WARN — add them to the kiosk or remove the
  assignment.
- **Restrictions too loose.** **Fix:** tighten the device-restrictions profile (block add-accounts,
  factory reset by user, USB transfer, safe boot) and re-test (Testing Test 8).

### Single-app kiosk doesn't launch the app on boot
- **Wrong package or app not installed.** **Fix:** confirm the exact **packageId** in the kiosk matches
  an installed app (`COSU-Validation.ps1`); correct the package and ensure it's assigned Required.

## D. Remote management / health

### Device won't take remote actions / looks offline
- **Stale check-in.** The device is likely powered off or off-network. **Fix:** `COSU-Report.ps1` flags
  stale devices (no check-in within `-StaleDays`); investigate connectivity/power before assuming failure.
- **Retired/wiped.** A device removed from management won't respond. **Fix:** confirm state in Intune;
  re-enroll (factory reset) if needed.

### A policy/kiosk change didn't apply
- **Waiting on check-in, reboot, or re-enrollment.** Some changes apply on next check-in, some need a
  reboot, and **enrollment-model changes require a factory reset + re-enrollment**. **Fix:** force
  **Sync**; reboot; and **verify against current Microsoft guidance / your tenant** whether the specific
  change requires re-enrollment before rolling it fleet-wide.

## E. OEM / rugged (pattern level)
- **Scanner / OEM setting not taking effect.** These are delivered by the **OEM's OEMConfig app + app
  configuration**, not native kiosk settings. **Fix:** confirm the OEMConfig app is assigned Required to
  the device group and its configuration is correct; the schema is the OEM's — defer to Zebra/Samsung
  docs.

---
## Escalation checklist
1. `COSU-Discovery.ps1` — binding active, profile + token valid, apps present, no blocking restriction?
2. `COSU-Set-ScopeTargeting.ps1` — device group exists, rule matches the profile, device is a member?
3. `COSU-Validation.ps1` — kiosk allow-list matches assigned apps (only allowed apps), MHS present for multi-app?
4. `COSU-Report.ps1` — device compliant, checked in recently, expected OEM/OS?
5. Still stuck → capture the enrollment/kiosk symptom and **verify the current Microsoft guidance** for
   dedicated (COSU) / AMAPI behavior in your tenant before a fleet-wide change.
