# 7. Best Practices — iOS iPhone Entra ID Shared Device Mode (Frontline)

These practices keep the shared-iPhone identity model correct, predictable, and safe across users.
They assume the deployment model in the Solution Overview: no-affinity ABM/ADE enrollment into an
assigned device group, shared-mode registration via Microsoft Authenticator, and SDM-aware apps
(Teams + MSAL LOB), deployed pilot-first.

## Get the enrollment-time grouping right (the #1 pitfall)
- **Assigned group, not Dynamic.** Shared/no-affinity devices have no user to drive dynamic rules —
  use an **Assigned** security group (**iPhone SDM – Devices**).
- **Make the Intune Provisioning Client an owner.** Add AppId
  `f1346770-5b25-470b-88bd-d5744ab7952c` as an **owner** of that group (search by AppId, not the
  display name). Without it, devices never populate the group at enrollment and nothing deploys.
- **One group, everything targeted to it.** Point the ADE profile assignment, the apps, the
  restriction profile, and compliance at the same **iPhone SDM – Devices** group so a device is fully
  configured the moment it lands.

## Treat app scope as the security boundary
- **Only SDM-aware apps belong on a shared iPhone.** Global sign-out clears data **only** for apps
  that implement SDM. Anchor on **Microsoft Teams**; add LOB apps **only** after confirming SDM
  support with the vendor / current Microsoft docs.
- **Keep non-SDM, personal-data apps off the pool.** Use the **iPhone SDM – Restrictions** profile to
  ensure no app that caches personal data — but doesn't participate in global sign-out — is present.
  This is the difference between "clean hand-off" and "the next worker sees the last one's data."
- **Don't confuse this with kiosk lockdown.** Lockdown limits *which* app runs; SDM manages *whose
  identity* is active. If the requirement is a single-purpose appliance phone, use the lockdown
  solution instead; if it's per-user frontline sign-in, use SDM.

## Provisioning discipline
- **Dedicated, least-privilege provisioning account.** Grant **Cloud Device Administrator** to a
  dedicated account used only to register devices into shared mode — not a personal admin identity.
- **Make shared-mode registration part of the runbook.** Registration is **per device** via
  Authenticator; script/track it so no device silently skips it and falls back to single-user
  behavior.
- **Verify iOS app support before each wave.** SDM app coverage on iOS is narrower than Android and
  evolves — re-confirm Teams and any LOB apps before widening.

## Pilot-first and prove the hand-off
- **Always test with two real users.** The acceptance test is user A signs out → user B signs in
  **clean**. Never expand on a single-user test.
- **Pilot by location/shift.** Roll out to one site or shift, validate with `IOSSDMFL-Report.ps1`,
  then widen.

## Operate and monitor
- **Report before you widen.** Run `IOSSDMFL-Report.ps1` each wave; confirm no-affinity enrollment and
  SDM apps across the pool.
- **Remediate with `-WhatIf` first.** `IOSSDMFL-Remediation.ps1` and `IOSSDMFL-Set-ScopeTargeting.ps1`
  preview by default — read the plan, then apply.
- **Tune Conditional Access to the shift model.** Shared devices re-authenticate per user per shift;
  set sign-in frequency accordingly rather than fighting it.
- **Don't TLS-inspect Microsoft login endpoints** — it breaks registration and sign-out.

## Change control
- **Re-verify after iOS major upgrades** and after adding any app to the pool — confirm the two-user
  clean-hand-off test still passes before expanding.
- **Record app SDM-support decisions.** Keep a short table (app → bundle ID → SDM supported? → source)
  so the next admin knows the boundary.
