# 6. Troubleshooting — macOS Automated Device Enrollment with SSO

Work top-down: confirm the **connection** (APNs/token), then **assignment** (ABM → Intune), then the
**device** (enrollment), then **Platform SSO**. Most failures are an expired token, an unassigned
device, or a blocked network endpoint.

## The Mac never shows a "Remote Management" screen
- **Device not assigned to the Intune MDM server.** ABM → **Devices** → confirm **MDM Server** = your
  Intune server (R5). After fixing, Intune → token → **Sync**.
- **Profile not assigned.** Intune → token → **Devices** → select serial → **Assign profile**.
- **Already past Setup Assistant.** ADE only triggers during Setup Assistant — **Erase All Content
  and Settings** and try again.
- **Network blocks Apple.** Ensure `mdmenrollment.apple.com` and `gdmf.apple.com` are reachable and
  **not** TLS-inspected (R9).
- **Configurator device past 30-day window** or released by the user — re-add and re-assign.

## Enrollment fails partway / device not in Intune
- **APNs certificate invalid/expired.** Intune → Apple MDM Push certificate must be **Active** (R2).
  If it was renewed with a *different* Apple ID, devices unenroll — restore the original Apple ID.
- **Enrollment token expired.** Renew the ABM server token (R3); re-upload to Intune.
- **macOS blocked by enrollment restriction.** Allow macOS for the target group (R10).

## Device enrolled but **not Supervised**
- The enrollment profile didn't enable **Supervised** (Step 7). Correct the profile, then **erase and
  re-enroll** — supervision is set at enrollment and cannot be toggled on an enrolled device.

## Company Portal doesn't install
- Confirm the app is **Required** and assigned to the **user/group** that owns the device (R7).
- Force a check-in: on the Mac, open **Company Portal** (if present) or **System Settings → Privacy &
  Security → Profiles**, and confirm management; in Intune, use **Sync** on the device.

## Platform SSO never prompts to register
- **Company Portal missing or outdated** — it performs registration (R7); update it.
- **SSO profile not assigned** to the signed-in user (Step 11). Confirm assignment and that the
  enrollment used **user affinity** (Step 7).
- **Extension identifiers wrong** — must be `com.microsoft.CompanyPortalMac.ssoextension` / team
  `UBF8T346G9` (Step 11).
- **macOS too old** — Platform SSO requires macOS 13+ (14+ recommended) (R6).
- After fixing, sign out/in or reboot to re-trigger the registration prompt.

## Registered, but apps still prompt for a password
- **Missing SSO URLs** — ensure all Microsoft login URLs are listed in the SSO extension (Step 11).
- **Browser without broker support** — Safari/Edge/Chrome with the Microsoft SSO extension get silent
  SSO; some third-party browsers won't.
- **Conditional Access interruption** — a policy may require interaction; review CA sign-in logs in
  Entra.

## Secure Enclave method not taking effect
- The profile may be set to **password sync**. Set **Authentication Method = Secure Enclave Key**
  (Step 11), re-assign, and **re-register** (sign out/in). Existing registrations keep their original
  method until re-registered.

## "Awaiting configuration" / device stuck at Setup Assistant
- Usually a transient Apple/Intune sync delay or a network hiccup. Confirm endpoints (R9), **Sync**
  the token, and allow several minutes; if persistent, erase and retry.

## Token / certificate expiry (preventive)
- Both the **APNs certificate** and the **ADE token** expire **annually** and **block enrollment** if
  lapsed. Run `ADEMAC-Discovery.ps1` (or `ADEMAC-Remediation.ps1`) regularly; it flags anything
  expiring within 30 days. Renew with the **same Apple ID** each time.

## Useful checkpoints
- **Intune:** Devices → macOS → (device) → **Hardware / Compliance / Configuration**; Enrollment →
  Apple → token → **Devices**.
- **On the Mac:** **System Settings → Privacy & Security → Profiles** (MDM profile present);
  **Console.app** filtered for `AppSSO` / `DeviceManagement` for SSO and enrollment logs.
- **Scripts:** re-run `ADEMAC-Validation.ps1` after each change to confirm the gate.
