# 2. Requirements Guide — Windows Autopilot

Verify **every** requirement before configuring. Each entry: **Description · Why · Verify ·
Implement-if-missing.** Category-wide prerequisites are in `global-requirements-intune-solutions.md`.

## 2.1 Licensing
**Description:** Intune + Microsoft Entra ID P1 (or M365 E3/E5/Business Premium).
**Why:** Autopilot uses Intune for profiles/policy and Entra for join + automatic enrollment.
**Verify:** M365 admin center → **Billing → Licenses**.
**Implement:** Assign M365 E3/E5 or Business Premium to targeted users.

## 2.2 Automatic MDM enrollment
**Description:** Entra automatic enrollment scoped to your users.
**Why:** Autopilot relies on auto-enrollment to bring the device into Intune during OOBE.
**Verify:** Intune → **Devices → Enrollment → Automatic Enrollment** → MDM user scope = **All** (or a group).
**Implement:** Set MDM user scope to **All**; ensure MDM terms/discovery URLs are default.

## 2.3 Device registration (hardware hash)
**Description:** Each device's Autopilot hardware identity is uploaded to the tenant.
**Why:** Autopilot only applies to **registered** devices.
**Verify:** Intune → **Devices → Enrollment → Devices** (Windows Autopilot devices) — the device is listed.
**Implement:** Have the OEM/reseller register at purchase, or collect with **`Get-AutopilotHash.ps1`** and import the CSV.

## 2.4 Microsoft Entra company branding
**Description:** Company branding on the Entra sign-in experience.
**Why:** Confirms the user is signing into the right tenant during OOBE; required for a clean user-driven experience.
**Verify:** Entra → **Company branding**.
**Implement:** Entra → **Company branding → Customize** (add logo/text).

## 2.5 Windows operating system
**Description:** Windows 10 1809+ or Windows 11 (current build recommended).
**Why:** Autopilot OOBE features depend on a supported, patched Windows.
**Verify:** `winver`, or the device's factory image.
**Implement:** Use OEM Windows 10/11 Pro/Enterprise images.

## 2.6 Network (OOBE)
**Description:** Internet access during OOBE to Microsoft Autopilot/Entra/Intune endpoints.
**Why:** The device contacts the Autopilot service to fetch its profile.
**Verify:** A wired/Wi-Fi network reaches `https://login.microsoftonline.com` and the Autopilot endpoints.
**Implement:** Allow Microsoft 365/Autopilot URLs through proxy/firewall; provide OOBE network access (no 802.1X that blocks pre-logon, or use a provisioning network).

## 2.7 Certificates
**Description:** None required.
**Why (not):** Autopilot uses Entra identity + Intune policy.
**Implement:** N/A.

---
## Checklist
- [ ] Intune + Entra P1 licensing assigned
- [ ] Automatic MDM enrollment = All (or pilot group)
- [ ] Devices registered (hardware hash) — `Get-AutopilotHash.ps1`
- [ ] Entra company branding configured
- [ ] Windows 10 1809+/Windows 11
- [ ] OOBE network reaches Microsoft endpoints
- [ ] Pilot Entra group + dynamic Autopilot device group created
