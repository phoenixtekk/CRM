# 2. Requirements Guide — Endpoint Health & Digital Experience Monitoring

Verify **every** requirement before configuring. Each entry: Description · Why · Verify ·
Implement-if-missing. Category-wide prerequisites are in `global-requirements-infrastructure.md`.

## 2.1 Licensing
Description: Microsoft Intune (Plan 1). Endpoint analytics is included at no extra cost.
Why: Endpoint analytics is delivered by Intune; proactive remediations require Intune (and, for
device-scoped remediations, an eligible Windows Enterprise/Education entitlement).
Verify: M365 admin center → **Billing → Licenses**; Intune is assigned.
Implement: Assign Microsoft 365 E3/E5, Business Premium, or standalone Intune Plan 1.

## 2.2 Device enrollment
Description: Targeted Windows devices enrolled in Intune (or Configuration Manager-attached).
Why: Endpoint analytics only scores devices it manages and that report telemetry.
Verify: Intune → **Devices → All devices**; targeted devices appear. Run `EHEM-Discovery.ps1`.
Implement: Enable automatic enrollment; Entra-join and enroll the devices.

## 2.3 Supported Windows OS
Description: Windows 10 (Pro/Enterprise/Education) or Windows 11, current build.
Why: Endpoint analytics data collection and proactive remediations require a supported build.
Verify: `winver`; run `EHEM-Discovery.ps1`.
Implement: Patch/upgrade to a supported build (deploy update rings or upgrade to Windows 11).

## 2.4 Endpoint analytics enabled
Description: Endpoint analytics is turned on for the tenant with a data source selected.
Why: No scores or reports exist until the capability is enabled and devices are onboarded.
Verify: `https://intune.microsoft.com` → **Reports → Endpoint analytics**; the dashboard loads with
a score (not the "get started" prompt).
Implement: Enable it in Implementation Step 1 (Reports → Endpoint analytics → Start).

## 2.5 Device data collection / diagnostic data
Description: Devices send the device-performance telemetry Endpoint analytics uses, with required
diagnostic data permitted by policy.
Why: Startup, reliability, and resource sub-scores depend on this telemetry; remediation output
reporting benefits from it too.
Verify: Intune → **Reports → Endpoint analytics → Settings**; devices show as **enrolled** for
analytics. Run `EHEM-Validation.ps1` on a device.
Implement: Confirm the Endpoint analytics data collection policy is assigned; ensure no policy forces
diagnostic data below the required level.

## 2.6 Network access for Endpoint analytics telemetry
Description: Outbound HTTPS from devices to the Intune/Endpoint analytics and Microsoft telemetry
endpoints.
Why: Devices must reach the service to upload performance data.
Verify: From a device, reach `https://login.microsoftonline.com` and the Microsoft telemetry/Intune
endpoints (see Microsoft's published URL list).
Implement: Allow the Microsoft 365 / Intune / connected-experiences URL and IP ranges through the
proxy/firewall.

## 2.7 Baseline period (data warm-up)
Description: A short period (typically several days) after onboarding before scores are meaningful.
Why: Scores are computed from collected telemetry; a fresh tenant has too little data to trust.
Verify: Endpoint analytics → **Startup performance** shows device counts climbing day over day.
Implement: Onboard the pilot, then wait the baseline period before judging scores (the pilot gate).

## 2.8 (Optional) Dedicated DEX platform licensing
Description: Licensing and tenant for a dedicated DEX platform (e.g. Nexthink, Tanium) — only if you
need deeper telemetry than Endpoint analytics provides.
Why: A dedicated platform is a separate product with its own collector, console, and cost.
Verify: Confirm the platform subscription and admin access exist.
Implement: Acquire the licensing, then follow the **vendor's own documentation** to deploy its
collector and dashboards. Vendor-specific steps are intentionally out of scope here.

---
## Checklist
- [ ] Intune licensing assigned
- [ ] Devices enrolled (or Configuration Manager-attached) — `EHEM-Discovery.ps1`
- [ ] Windows 10/11 supported build — `EHEM-Discovery.ps1`
- [ ] Endpoint analytics enabled with a data source
- [ ] Device data collection / diagnostic data permitted — `EHEM-Validation.ps1`
- [ ] Network allows Endpoint analytics telemetry
- [ ] Baseline period planned (data warm-up = pilot gate)
- [ ] Pilot Entra group created (`Endpoint Analytics – Pilot Devices – Monitoring`)
- [ ] (Optional) Dedicated DEX platform licensed — vendor docs for setup
