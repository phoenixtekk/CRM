# 2. Requirements Guide — Microsoft Defender for Endpoint for macOS (Deployment & Onboarding via Intune)

Verify **every** requirement before configuring. Each entry: **Description · Why required · How to
verify · How to implement if missing.** Category-wide prerequisites are in
`global-requirements-intune-solutions.md`.

Object names used throughout this solution (reuse them verbatim in Intune):
- System Extensions profile: `MDE macOS – System Extensions`
- Full Disk Access (PPPC/TCC) profile: `MDE macOS – Full Disk Access`
- Network filter (web content filter) profile: `MDE macOS – Network Filter`
- Background services (managed login items) profile: `MDE macOS – Background Services`
- Notifications profile: `MDE macOS – Notifications`
- Onboarding profile (custom `.mobileconfig`): `MDE macOS – Onboarding`
- Microsoft Defender app deployment: `MDE macOS – Defender App`
- Device groups: `MDE macOS – Pilot Devices` and `MDE macOS – Production Devices`
- Tag (put in every profile/app description): `MDE-macOS`

> **Order rule (applies to the whole solution):** the five capability profiles above are delivered and
> confirmed applying **before** the onboarding profile and app. Onboarding a Mac whose extensions,
> Full Disk Access, and network filter are not yet approved produces a **silently degraded** agent.

## 2.1 Microsoft Defender for Endpoint licensing
**Description:** A Microsoft Defender for Endpoint plan that covers macOS (for example Microsoft 365 E5 / E5 Security, Microsoft Defender for Endpoint Plan 1 or Plan 2, or Microsoft 365 Business Premium where eligible).
**Why required:** Without an MDE license the onboarding package will not be available and the device cannot report to the Microsoft Defender portal.
**How to verify:** `https://security.microsoft.com` loads and **Settings → Endpoints → Onboarding** offers **macOS** as an operating system; Microsoft 365 admin center → **Billing → Licenses** shows an MDE-bearing plan.
**How to implement if missing:** Assign an MDE-bearing license, then confirm macOS onboarding is available in the Microsoft Defender portal.

## 2.2 Apple MDM Push (APNs) certificate
**Description:** A valid Apple Push Notification service (APNs) certificate configured in Intune.
**Why required:** Apple devices (including Macs) cannot be managed by Intune without an APNs certificate — no configuration profiles, apps, or onboarding payloads reach the Mac until it exists.
**How to verify:** Intune → **Devices → Enrollment → Apple → Apple MDM Push certificate**; confirm present and **not expired**.
**How to implement if missing:** Intune → **Devices → Enrollment → Apple → Apple MDM Push certificate → download the CSR**, create the certificate at `https://identity.apple.com` with a long-lived Apple ID, upload it back, and record the renewal date.

## 2.3 macOS enrollment configured
**Description:** A working macOS enrollment method so target Macs are enrolled and manageable — Automated Device Enrollment (ADE/DEP), Account-driven enrollment, or Company Portal device enrollment.
**Why required:** Profiles, apps, and the onboarding payload apply only to enrolled Macs. Note that **supervised** Macs (ADE) allow the smoothest silent approval of extensions and network filters.
**How to verify:** Intune → **Devices → macOS → macOS devices**; the Mac appears as managed. Run `MACMDE-Discovery.ps1` for tenant/device readiness signals.
**How to implement if missing:** Configure **Automated Device Enrollment** (Apple Business/School Manager token + an enrollment profile) for corporate Macs, or **Account-driven**/Company Portal enrollment for user-owned Macs; then enrol the devices.

## 2.4 Supported macOS version
**Description:** A currently supported macOS major version on the target Macs (MDE for macOS supports the current and recent macOS releases).
**Why required:** MDE's system extensions, network extension, and TCC behavior depend on a supported macOS version; older, unsupported versions may fail to load extensions or expose payloads differently.
**How to verify:** On a Mac, **Apple menu → About This Mac**; or Intune → device → **Hardware**. Run `MACMDE-Discovery.ps1` for the fleet macOS-version spread.
**How to implement if missing:** Update the Macs to a supported macOS version before onboarding.

## 2.5 The MDE onboarding package (from the Microsoft Defender portal)
**Description:** The macOS onboarding package downloaded from the Microsoft Defender portal — it contains the tenant-specific `WindowsDefenderATPOnboarding.plist` / onboarding `.mobileconfig`.
**Why required:** This blob tells the installed MDE agent which Microsoft Defender tenant to report to. It is tenant-specific and is the authoritative onboarding source — do not hand-craft it.
**How to verify:** `https://security.microsoft.com` → **Settings → Endpoints → Onboarding** → operating system **macOS** → deployment method **Mobile Device Management / Microsoft Intune** → **Download onboarding package**; you have the extracted onboarding profile.
**How to implement if missing:** Download the onboarding package from the Microsoft Defender portal as above and extract the onboarding configuration profile for use in `MDE macOS – Onboarding` (Implementation Step 8).

## 2.6 Microsoft Defender extension identifiers and code requirements
**Description:** The Microsoft Defender **team identifier**, **system extension bundle identifiers**, **network extension identifier**, and the **PPPC code requirement string** used to pre-approve the extensions and Full Disk Access.
**Why required:** The System Extensions, Network filter, and Full Disk Access profiles must name the exact Microsoft-published identifiers or macOS will not silently approve the extensions.
**How to verify:** You have the current identifier/code-requirement values from Microsoft's macOS deployment documentation (or the Settings catalog exposes a Microsoft Defender preset that carries them).
**How to implement if missing:** Obtain the current identifiers and code requirement from Microsoft's official *Deploy Microsoft Defender for Endpoint on macOS with Intune* documentation, or use the Intune Settings-catalog Microsoft Defender presets where available. *(These are Microsoft-published values — use the current ones; this solution does not invent them.)*

## 2.7 Pilot and production device groups
**Description:** Two Entra ID security groups: `MDE macOS – Pilot Devices` (a small representative sample of Macs) and `MDE macOS – Production Devices` (the rest of the Mac fleet).
**Why required:** Onboarding is piloted before fleet rollout so a missing approval or a degraded agent is caught on a few Macs, not the whole fleet.
**How to verify:** Entra → **Groups**; both groups exist.
**How to implement if missing:** Entra → **Groups → New group → Security**; add representative pilot Macs to one and the remaining Macs to the other.

## 2.8 Network access to Microsoft Defender endpoints
**Description:** Outbound HTTPS from the Macs to the Microsoft Defender for Endpoint service URLs (in addition to the general Microsoft cloud endpoints in the global requirements).
**Why required:** The onboarded agent must reach the MDE cloud to report health, telemetry, and EDR data; blocked endpoints leave the agent installed but inactive in the portal.
**How to verify:** From a Mac, the MDE connectivity test passes (`mdatp connectivity test`), or the device reports **active** in the Microsoft Defender portal after onboarding.
**How to implement if missing:** Allow the Microsoft Defender for Endpoint published service URLs through the proxy/firewall (per Microsoft's documented MDE endpoint list).

## 2.9 (Optional) Local admin / Terminal access for on-device validation
**Description:** The ability to run `mdatp` commands in Terminal on a pilot Mac (for example `mdatp health`).
**Why required:** The definitive health proof (extensions running, real-time protection on) is read on the device with the `mdatp` CLI; the Intune-side scripts prove the management prerequisites but not the live agent state.
**How to verify:** On a pilot Mac, `mdatp health` returns output.
**How to implement if missing:** Ensure a pilot operator can open Terminal on a pilot Mac to run the validation commands in the Testing Guide.

---
## Checklist
- [ ] Microsoft Defender for Endpoint licensing assigned; macOS onboarding available in the Defender portal
- [ ] Apple MDM Push (APNs) certificate present and not expired
- [ ] macOS enrollment configured (ADE / Account-driven / Company Portal); Macs enrolled — `MACMDE-Discovery.ps1`
- [ ] Supported macOS version on target Macs
- [ ] MDE macOS onboarding package downloaded from the Defender portal
- [ ] Microsoft Defender extension identifiers / PPPC code requirement obtained (Microsoft-published)
- [ ] `MDE macOS – Pilot Devices` and `MDE macOS – Production Devices` groups created
- [ ] Network access to Microsoft Defender service endpoints allowed
- [ ] (Optional) Terminal access on a pilot Mac for `mdatp` health validation
