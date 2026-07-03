# 7. Best Practices — MAM App Protection Policies for BYOD (Government / GCC High)

- **Confirm the cloud first.** Before any change, run `MAMAPPG-Discovery.ps1` and confirm the Graph
  environment is **USGov** (`graph.microsoft.us`) and you are in the `*.us` portals. A single
  Commercial-cloud action does nothing for a GCC High tenant — the #1 GCC High mistake.
- **Pilot first, always.** Assign to `MAM Users - BYOD - Pilot` and validate on a real unenrolled
  device before touching production.
- **Enforce with Conditional Access.** App Protection Policies protect data, but only
  `CA - Require APP - M365 (Gov)` guarantees corporate resources are reachable only from a protected
  app. The CA grant is available in GCC High — deploy both, and start the grant in **Report-only**
  with break-glass accounts excluded.
- **Install the right broker.** Android needs **Company Portal** (`portal.manage.microsoft.us`); iOS
  needs **Microsoft Authenticator**. Without the broker the policy silently never applies — bake this
  into user onboarding.
- **Keep iOS and Android policies in sync.** Mirror the same data-protection and access settings
  across `BYOD - App Protection - iOS (Gov)` and `BYOD - App Protection - Android (Gov)` so behavior
  is consistent.
- **Limit save-as to org locations.** Block save-as except OneDrive/SharePoint so corporate data
  does not land in personal cloud or the camera roll.
- **Require an app PIN and encryption.** These are the baseline that makes a lost phone a non-event
  for corporate data.
- **Set a sensible offline grace period.** Too short frustrates travelers; too long weakens the wipe
  guarantee.
- **Prefer selective (app) wipe over device wipe on BYOD.** Remove corporate data only; never wipe an
  employee's personal phone. Communicate this clearly to build trust and adoption.
- **Do not depend on non-FedRAMP Outlook extras.** Location services, Play My Emails, and To Do are
  not available for US Gov — don't build a configuration or user expectation around them.
- **Assume features lag.** New MAM capabilities generally arrive in GCC High weeks–months after
  Commercial (and quiet time policies are not supported in sovereign clouds). **Verify for GCC High**
  in your own tenant before designing around a recently announced feature.
- **Assign to groups, not users.** Add new BYOD users to the scope groups; they inherit protection
  automatically.
- **Watch coverage.** Track which users/apps report a policy with `MAMAPPG-Report.ps1` and chase the
  gaps with `MAMAPPG-Remediation.ps1` (default `-WhatIf`).
- **Document the settings.** Record the data-protection and access values, the app list, and the CA
  grant for audits and repeatability.
