# 6. Troubleshooting — macOS Automated Device Enrollment with SSO (Jamf Pro + Microsoft Intune)

Work top-down: confirm the **Apple ↔ Jamf connection** (APNs/ADE token), then **assignment** (ABM →
Jamf), then the **device** (enrollment/supervision), then **Platform SSO**, then the **Jamf ↔ Intune
compliance** flow and **Conditional Access**. Most failures are an expired token, an unassigned
device, a missing integration, or a blocked network endpoint.

## The Mac never shows a "Remote Management" screen
- **Device not assigned to the Jamf MDM server.** ABM → **Devices** → confirm **MDM Server** = your
  Jamf server (R5). After fixing, Jamf → Automated Device Enrollment → **Refresh**.
- **Not scoped to a PreStage.** Jamf → **PreStage Enrollments** → confirm the serial is scoped (R6).
- **Already past Setup Assistant.** ADE only triggers during Setup Assistant — **Erase All Content
  and Settings** and try again.
- **Network blocks Apple.** Ensure `mdmenrollment.apple.com` and `gdmf.apple.com` are reachable and
  **not** TLS-inspected (R12).
- **Configurator device past 30-day window** or released by the user — re-add and re-assign.

## Enrollment fails partway / device not in Jamf
- **Jamf APNs certificate invalid/expired.** Jamf → **Push certificates** must be valid (R3). If it
  was renewed with a *different* Apple ID, devices unenroll — restore the original Apple ID.
- **ADE token expired.** Renew the ABM server token (R4); re-upload to the Jamf ADE instance.

## Device enrolled but **not Supervised**
- The **PreStage** didn't enable **Supervision** (Step 7). Correct the PreStage, then **erase and
  re-enroll** — supervision is set at enrollment and cannot be toggled on an enrolled device.

## Company Portal doesn't install
- Confirm the app is scoped to the pilot Smart Group and set to install automatically (R8/Step 9).
- Force a check-in: on the Mac, run **Self Service** or `sudo jamf recon` / `sudo jamf policy`; in
  Jamf, confirm the computer's **inventory** updates.

## Platform SSO never prompts to register
- **Company Portal missing or outdated** — it performs registration (R8); update it.
- **SSO profile not scoped** to the device (Step 10). Confirm scope and that the profile installed
  (System Settings → Privacy & Security → Profiles).
- **Extension identifiers wrong** — must be `com.microsoft.CompanyPortalMac.ssoextension` / team
  `UBF8T346G9` (Step 10).
- **macOS too old** — Platform SSO requires macOS 13+ (14+ recommended) (R7).
- After fixing, sign out/in or reboot to re-trigger the registration prompt.

## Registered, but apps still prompt for a password
- **Missing SSO URLs** — ensure all Microsoft login URLs are listed in the SSO extension (Step 10).
- **Browser without broker support** — Safari/Edge/Chrome with the Microsoft SSO extension get silent
  SSO; some third-party browsers won't.
- **Conditional Access interruption** — a policy may require interaction; review CA sign-in logs in
  Entra.

## Secure Enclave method not taking effect
- The profile may be set to **password sync**. Set **Authentication Method = Secure Enclave Key**
  (Step 10), re-scope, and **re-register** (sign out/in). Existing registrations keep their original
  method until re-registered.

## Mac doesn't appear in Intune / shows non-compliant
- **Device Compliance integration not active.** Intune → **Tenant administration → Partner device
  management** must show **Jamf = Active** (R10). Re-run consent in Jamf → **Device Compliance** if
  needed.
- **Device not in the Jamf compliance scope.** Confirm the Smart Group used for compliance includes
  the Mac (Step 12).
- **Not registered in Entra.** Registration happens via **Company Portal** — complete Test 6 first.
- **Inventory stale.** Run `sudo jamf recon` to push fresh inventory; compliance reflects on the next
  sync.

## Conditional Access blocks a Mac it shouldn't
- **Compliance not yet reported.** New devices may take a sync cycle — confirm Intune shows
  **Compliant** before enforcing.
- **Policy too broad.** Keep CA in **report-only** for the pilot; review Entra **sign-in logs** to see
  exactly which control failed before switching to **On** (Step 13).
- **Authentication strength mismatch.** If you required phishing-resistant strength, the Mac must be
  using the **Secure Enclave** method (Test 8).

## Integration renamed / steps don't match the console
- Microsoft and Jamf **superseded the legacy "Conditional Access"** integration with **Device
  Compliance / Partner device management**. If a menu label differs, follow the **current** Jamf and
  Microsoft documentation for the macOS Device Compliance integration.

## Token / certificate expiry (preventive)
- The Jamf **APNs certificate** and the **ADE token** expire **annually** and **block enrollment** if
  lapsed. Run `JAMFADE-JamfReadiness.ps1` regularly; it flags anything expiring within 30 days. Renew
  APNs with the **same Apple ID** each time.

## Useful checkpoints
- **Jamf:** Computers → (device) → **Inventory / Management / Configuration Profiles**; Settings →
  Global → **Automated Device Enrollment / Push certificates / Device Compliance**.
- **Intune/Entra:** Devices → macOS → (device) → **Compliance**; Tenant administration → **Partner
  device management**; Entra → **Conditional Access** + **Sign-in logs**.
- **On the Mac:** **System Settings → Privacy & Security → Profiles**; **Console.app** filtered for
  `AppSSO` / `DeviceManagement`; `sudo jamf recon` to refresh inventory.
- **Scripts:** re-run `JAMFADE-Validation.ps1` after each change to confirm the gate.
