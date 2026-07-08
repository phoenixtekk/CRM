# Troubleshooting — Enable Microsoft Intune (Quick-Start)

Work the symptom to the most specific cause. All checks here are read-only; you never need to delete the
tenant configuration to diagnose. Run `ITSTART-Discovery.ps1` first — it surfaces most of these states at
a glance.

## Enrollment fails immediately with a licensing error
- **Symptom:** the user sees "Your account is not configured for enrollment" / "You need an Intune
  license."
- **Most likely:** the enrolling user has **no Intune-bearing license**, or the license lacks free seats.
- **Fix:** in **Entra admin center → Users → (user) → Licenses**, confirm an Intune-bearing plan is
  assigned and **Microsoft Intune** shows as an enabled service plan. Assign one if missing. This is the
  #1 cause of failed enrollment.

## Windows device joins Entra but never enrolls in Intune
- **Cause:** the device (or its user) is **out of scope** for MDM auto-enrollment, or is not actually
  Entra-*joined* (only "registered"/Workplace-joined).
- **Fix:** in **Entra admin center → Devices → Mobility (MDM and MAM) → Microsoft Intune**, confirm **MDM
  user scope** includes the user (Some → your pilot group, or All). On the PC, **Settings → Accounts →
  Access work or school** should show it **joined to Microsoft Entra ID**, not just "Connected." Trigger a
  sync and re-check `Devices → All devices` in Intune.

## iPhone enrollment stops — "Cannot connect to the server" or profile won't install
- **Cause:** the **Apple MDM push certificate** is missing or expired, or the management profile wasn't
  installed in iOS Settings.
- **Fix:** in **Intune admin center → Devices → Enrollment → Apple → Apple MDM Push certificate**, confirm
  a **valid** certificate (not expired). If expired, renew it **with the same Apple ID** that created it.
  On the device, complete **Settings → Profile Downloaded → Install**. `ITSTART-Discovery.ps1` reports the
  certificate's presence and expiry.

## Apple push certificate can't be renewed
- **Cause:** renewal was attempted with a **different Apple ID** than the one that created it.
- **Fix:** the APNs certificate must be renewed by the **original Apple ID** (recorded in the certificate
  blade). Using a new Apple ID creates a *new* certificate and **un-enrolls every existing Apple device** —
  avoid this. Always use a dedicated organizational Apple ID and store its credentials safely.

## MDM authority shows "None" and can't be changed
- **Cause:** on legacy or co-managed tenants the authority may be set elsewhere (e.g. Configuration
  Manager) or a role limitation.
- **Fix:** confirm you are a **Global Administrator**. On current tenants the authority is Intune by
  default; if it truly reads None, set it on the **Tenant administration → Overview / MDM authority**
  control. If co-management with Configuration Manager is in play, that is a deeper scenario beyond this
  Quick-Start — see the catalog co-management solutions.

## Device enrolls but never shows Compliant (stuck "In grace period" / "Not evaluated")
- **Cause:** the compliance policy isn't **assigned** to a group the device's user is in, or the device
  hasn't checked in yet.
- **Fix:** confirm `Compliance – Windows – Baseline` / `Compliance – iOS – Baseline` are **assigned** to
  `INTUNE – QuickStart – Pilot`, and the enrolled user is a **member**. Force a sync from the device; first
  evaluation can take a few minutes. `ITSTART-Validate.ps1` flags an unassigned baseline.

## "Personally owned iOS enrollment is blocked"
- **Cause:** an **enrollment restriction** blocks personally owned iOS, or blocks the iOS platform.
- **Fix:** in **Intune admin center → Devices → Enrollment → Enrollment device platform restrictions**,
  confirm **iOS/iPadOS** is **Allow** and **personally owned** is permitted for the pilot scope (or use the
  `Enrollment – QuickStart – Pilot` restriction described in implementation Step 5).

## Company Portal keeps asking to sign in / redirect loop
- **Cause:** the user isn't licensed, MFA is interrupting first enrollment, or the device time/date is
  wrong.
- **Fix:** confirm licensing (above), complete any MFA prompt, and verify the device clock is correct.
  Sign out fully in Company Portal and retry.

## New tenant — users can't sign in on devices
- **Cause:** the custom domain isn't verified, or the pilot user has no usable password/UPN.
- **Fix:** confirm the domain is **Verified** under **Entra → Settings → Domain names**, and that the pilot
  user's UPN uses a verified domain and has a known password.

---

*If licensing is assigned, the MDM authority is Intune, the Apple push certificate is valid, auto-enrollment
is scoped, and baselines are assigned — but a specific device still won't enroll — capture the on-device
error (Windows: `Access work or school → Info → Sync`; iOS: Company Portal diagnostics) and match it to the
symptom above before escalating. Deeper, at-scale enrollment and compliance troubleshooting is its own
catalog solution.*
