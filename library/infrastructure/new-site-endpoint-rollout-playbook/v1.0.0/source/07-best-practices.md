# 7. Best Practices — New-Site Endpoint Rollout Playbook

- Pilot the first site, always. Run the very first location as the pilot and pass the full go-live
  gate before you scale — the single most important practice for a repeatable rollout.
- Respect the dependency order. Confirm network/identity before provisioning, baseline before apps,
  apps/printers before validation. Doing stages out of order is the usual cause of a chaotic go-live.
- One site, one device group. Scope every assignment to a per-site device group so one site's
  rollout can never disturb another site or the wider fleet.
- Name everything consistently. Use `<Purpose> – <Site> – <Stage>` (e.g.
  `New Site – Site A – Pilot`) for groups and assignments so the tenant stays readable as sites add
  up.
- Reuse the baseline, never re-author it. The site inherits your existing compliance policy and
  security baseline; building a new baseline per site defeats the repeatability.
- Validate per device, not just per policy. A policy showing "Succeeded" is not the same as a user
  being able to sign in, open the apps, and print — run `NEWSITE-Validation.ps1` on each device.
- Make go-live a gate, not a hope. Only open the site when the go-live checklist is fully ticked and
  `NEWSITE-Report.ps1` shows full coverage.
- Remediate before go-live, safely. Use `NEWSITE-Remediation.ps1` (default `-WhatIf`) to preview
  fixes for stuck devices, then re-validate — never improvise on go-live morning.
- Clone, do not rebuild. For the next site, clone the group and assignment pattern and change only
  the site name and Stage; the second site should be faster than the first.
- Document each site's set. Record the site's app set, printer set, and go-live date so the program
  is auditable and the next operator can repeat it.
