# 2. Requirements Guide — Microsoft Defender for Endpoint Integration

Verify **every** requirement before configuring. Each entry: **Description · Why · Verify ·
Implement-if-missing.** Category-wide prerequisites are in `global-requirements-intune-solutions.md`.

## 2.1 Defender for Endpoint licensing
**Description:** Microsoft Defender for Endpoint P1/P2, Microsoft 365 E5 / E5 Security, or Defender for Business.
**Why:** MDE onboarding and EDR require an MDE plan.
**Verify:** M365 admin center → **Billing → Licenses**; the Defender portal (`security.microsoft.com`) loads.
**Implement:** Assign M365 E5/E5 Security, standalone Defender for Endpoint, or Defender for Business (with Business Premium).

## 2.2 Intune + enrollment
**Description:** Intune subscription with target devices enrolled.
**Why:** Intune delivers the onboarding policy and reads the risk score.
**Verify:** Intune → **Devices → All devices**.
**Implement:** Enable automatic enrollment; enroll devices.

## 2.3 Access to the Defender portal
**Description:** Security Administrator access to `https://security.microsoft.com`.
**Why:** The Intune connection is enabled from the Defender portal settings.
**Verify:** The portal loads; **Settings → Endpoints → Advanced features** is accessible.
**Implement:** Assign **Security Administrator** (or Global Admin for setup).

## 2.4 Supported Windows OS
**Description:** Windows 10/11 (Defender sensor built in).
**Why:** Onboarding and EDR require a supported, patched Windows.
**Verify:** `winver`; the **Sense** service exists (`Get-Service Sense`).
**Implement:** Patch/upgrade to a supported build.

## 2.5 Network (Defender endpoints)
**Description:** Outbound HTTPS to Defender for Endpoint service URLs.
**Why:** The sensor reports telemetry and receives configuration from the service.
**Verify:** From a device, the MDE connectivity test passes (or run **`MDE-Validation.ps1`**).
**Implement:** Allow Microsoft Defender for Endpoint URLs/IPs through proxy/firewall; do not SSL-inspect MDE traffic.

## 2.6 Compliance + Conditional Access (for risk enforcement)
**Description:** Device compliance and Conditional Access in place.
**Why:** To turn the MDE risk score into access enforcement.
**Verify:** Intune → **Devices → Compliance**; Entra → **Conditional Access**.
**Implement:** Deploy the **Device Compliance** and **Conditional Access** solutions.

---
## Checklist
- [ ] Defender for Endpoint licensing assigned
- [ ] Devices enrolled in Intune
- [ ] Defender portal access (Security Administrator)
- [ ] Windows 10/11 with the Sense service — `MDE-Discovery.ps1`
- [ ] Network allows MDE endpoints (no SSL inspection)
- [ ] (For enforcement) Compliance + Conditional Access solutions in place
- [ ] Pilot Entra group created
