# 1. Solution Overview — Windows 11 Healthcare Endpoint Baseline

## What a Windows 11 endpoint baseline is
An endpoint baseline is a single, documented set of device settings that every Windows 11 endpoint
inherits, so the fleet behaves the same way no matter who set up the device. Delivered through
Microsoft Intune, the baseline is a small stack of policies — a configuration profile, a settings
catalog policy, a referenced Microsoft security baseline, an update ring, and a power/display profile
— each named and assigned to device groups. Set it once and every enrolled device inherits it.

## How it works
1. A device-restrictions configuration profile sets the broad, visible behavior — lock-screen,
   Microsoft Defender, SmartScreen, and similar device controls.
2. A settings catalog policy adds the fine-grained controls that are not exposed in the
   restrictions templates (the settings catalog is Intune's full, searchable list of device
   settings).
3. A referenced Microsoft security baseline applies Microsoft's recommended hardened security
   settings as one assignable package, so you are not hand-picking hundreds of values.
4. An update ring controls how and when quality and feature updates install per scope — a short
   deferral for clinical devices on a maintenance window, a standard deferral for corporate.
5. A power/display profile keeps shared clinical devices awake on shift (no sleep, no display-off
   mid-task) while letting personal corporate laptops conserve battery.
6. Everything is assigned to Entra device groups (clinical versus corporate, pilot versus
   production), so the right baseline reaches the right devices.

## What you can control
- Device restrictions: Defender, SmartScreen, lock-screen, and other endpoint controls.
- Settings catalog: any documented Windows setting not covered by the restriction templates.
- Security baseline: Microsoft's hardened recommended settings as one referenced package.
- Update behavior: quality/feature deferrals, deadlines, and active hours per scope.
- Power and display: sleep, hibernate, display-off, and lid behavior — tuned for shared versus
  personal use.

## Benefits
- Consistency — every Windows 11 endpoint is built to one standard, not to whoever imaged it.
- Security — a referenced baseline plus device restrictions harden the fleet uniformly.
- Clinical uptime — shared devices stay awake on shift; no PC sleeping mid-patient-encounter.
- Auditability — one documented, named baseline you can show an auditor and reproduce.
- Repeatability — assign once, inherited fleet-wide; new devices are compliant on enrollment.

## Limitations (be honest with buyers)
- A baseline standardizes Microsoft/Windows settings; third-party app configuration and patching
  are separate.
- Settings catalog and security baseline values can overlap; this solution keeps the security
  baseline authoritative for security settings and uses the catalog for the rest to avoid conflicts.
- Power settings for shared clinical devices trade battery life for always-awake behavior; that is
  intentional but should be confirmed for any battery-only device.
- The referenced security baseline is updated by Microsoft over time; review changes before adopting
  a new baseline version.

## Why a baseline matters in a clinical setting
Shared clinical workstations are used around the clock by many clinicians; an inconsistent or
unmanaged endpoint is both a security gap and a patient-safety risk when it sleeps, drifts, or
behaves differently from the device next to it. A single inherited baseline removes that variability.

## The deployment model
> Create the device groups, build the configuration profile and settings catalog policy, reference
> the security baseline, set the update ring and power profile, assign to the pilot, validate, then
> expand. The repeatable way: Assess to Configure to Pilot to Validate to Expand.
