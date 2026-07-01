# 7. Best Practices — Cloud-First Autopilot Zero-Touch Provisioning

- Default to Entra join. Make Microsoft Entra joined the standard for every device; treat domain join
  as a deliberate, documented exception, never the default.
- Register at the source. Push Autopilot registration onto the OEM/reseller at purchase so devices
  arrive pre-registered — manual hash upload does not scale.
- Use a dynamic Autopilot group. Let `Autopilot Devices – All Cloud-First – Provisioning` gather
  devices by ZTDID automatically so nothing is hand-added.
- Keep the ESP blocking set lean. Block only the must-have apps; large or non-essential apps belong as
  Available, not Required, so they don't stall provisioning.
- Assign apps and baseline to the Autopilot group, not to users. Device-targeted assignment guarantees
  the build is identical regardless of who signs in first.
- Name everything consistently. Reuse the artifact names (profile, ESP, group, app set, baseline) with
  the `<Purpose> – <Scope> – <Stage>` pattern so audits and handoffs are unambiguous.
- Pilot before you scale. Validate the full zero-touch flow on representative hardware and confirm the
  pass/fail gate before expanding.
- Measure technician touch. Track the touch rate with `CFAP-Report.ps1`; a number trending to zero is
  the whole point — chase any device that needed manual intervention.
- Prefer cloud paths for on-prem needs. Before adding domain join, try Microsoft Entra Kerberos / Cloud
  Kerberos Trust for SMB/Kerberos resource access from Entra-joined devices.
- Isolate any hybrid exception. If you must add domain join, use a separate profile and group; never
  modify the default cloud-first profile, and record the named dependency that justified it.
- Ensure OOBE internet. Confirm Wi-Fi/DHCP and the required Microsoft endpoints are reachable at first
  boot — cloud-first provisioning depends on it.
- Document the build. Record the artifact names, the app/baseline set, and any exception decisions for
  repeatability and audits.
