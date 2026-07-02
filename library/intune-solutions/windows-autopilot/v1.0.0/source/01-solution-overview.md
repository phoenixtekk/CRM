# 1. Solution Overview — Windows Autopilot

## What Windows Autopilot is
Windows Autopilot is a cloud-driven service that provisions new (and reset) Windows devices into
a fully managed state with no manual imaging. The device registers itself to your tenant by its
hardware identity, receives a **deployment profile** from Intune, and configures itself during
the out-of-box experience (OOBE). The user signs in once and the device auto-enrolls into
Microsoft Entra ID and Intune, then applies your policies and apps.

## How it works
1. The device's **hardware hash** is registered as an Autopilot device (by OEM, CSV import, or `Get-WindowsAutopilotInfo`).
2. A dynamic Entra group collects Autopilot devices; an Intune **deployment profile** and **Enrollment Status Page (ESP)** are assigned to it.
3. The user powers on the new device, connects to the internet, and signs in with their work account.
4. OOBE applies the profile (branding, account type, skipped screens). The device **Entra-joins** and **MDM-enrolls** automatically.
5. The ESP tracks required policies/apps until the device is ready to use.

## Deployment modes (this solution standardizes on the first)
- **User-driven, Microsoft Entra joined** — the user drives OOBE; simplest and most common. **(Used here.)**
- Self-deploying (kiosk/shared, no user).
- Pre-provisioning ("white glove") for IT/partner staging.
- Autopilot Reset to return an existing device to a managed clean state.

## Benefits
- **Zero-touch** — ship devices straight to users; no technician imaging.
- **Consistent builds** — every device provisions identically from policy.
- **Faster onboarding** — ready in minutes, not hours.
- **Lower cost** — no imaging infrastructure or re-imaging labor.

## Limitations (be honest with buyers)
- Devices must be **registered** (hardware hash) before Autopilot applies.
- OOBE requires **internet** and reachable Entra/Intune endpoints.
- First-run app/policy delivery time depends on what you require in the ESP.
- Hybrid Entra join is supported but more complex (out of scope; this solution uses cloud Entra join).

## The standard deployment model
> **Register device → assign deployment profile + ESP to an Autopilot device group → user
> completes OOBE → device auto-enrolls → policies/apps apply.**
Every step follows the repeatable pattern: **Assess → Configure → Pilot → Validate → Expand.**
