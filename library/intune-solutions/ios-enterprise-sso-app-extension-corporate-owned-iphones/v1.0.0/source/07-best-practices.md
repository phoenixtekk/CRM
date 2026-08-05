# 7. Best Practices — iOS/iPadOS Enterprise SSO App Extension (App/URL Scoping)

These practices keep the app/browser SSO extension precise, predictable, and reversible on
corporate-owned iPhones/iPads. They assume the deployment model in the Solution Overview: a
**redirect-type** Extensible SSO app extension hosted in **Microsoft Authenticator**, deployed via
Intune, pilot-first.

## Get the broker host right
- **Deploy Microsoft Authenticator first, Required.** On iOS the extension lives in Authenticator (not
  Company Portal). Make it a **Required** app assigned to the same group as the SSO profile so the
  extension binary is always present before the profile lands.
- **Add Company Portal where Conditional Access needs compliance.** Authenticator brokers the token;
  Company Portal carries MDM compliance. If CA gates the target apps on a compliant device, deploy
  both.

## Prefer managed-app-wide SSO, scope only when you must
- **Start with `Enable_SSO_On_All_ManagedApps = 1`.** On iOS this is the cleanest coverage: every
  Intune-managed app gets SSO without enumerating bundle IDs. Use an `AppPrefixAllowList` only if you
  deliberately want a narrower set.
- **If you allow-list, prefer prefixes over long ID lists.** A prefix like `com.microsoft.` covers the
  Office suite and Teams without listing every bundle ID; add specific IDs only for outliers.
- **Record every bundle ID you add.** Keep a short table (app → bundle ID → why included) so the next
  admin understands the scope.

## Scope URLs to the right cloud
- **Only your cloud's Entra URLs.** Commercial uses `login.microsoftonline.com` /
  `login.microsoft.com` / `sts.windows.net` / `login.windows.net`. US Gov uses
  `login.microsoftonline.us`; 21Vianet uses `login.partner.microsoftonline.cn`. Do **not** add clouds
  you don't use — extra URLs widen the interception surface for no benefit.
- **Use the "Microsoft Entra ID" template type** to auto-populate identifiers, then **verify** them
  against current Microsoft docs before you widen the rollout.

## Set browser and MFA expectations
- **Safari is the reliable path.** Safari flows broker natively. Standardize on Safari for brokered
  web SSO where you can.
- **Enable `browser_sso_interaction_enabled = 1`** so supporting browsers can complete interactive
  broker sign-in; document that non-supporting browsers fall back to normal sign-in.
- **Prime once, then measure.** Expect one interactive sign-in (with MFA) per user to seed the broker;
  measure silent SSO from the *second* sign-in onward. Use `disable_explicit_app_prompt = 1` to cut
  redundant app prompts.

## Deploy pilot-first and reversibly
- **Assign to a pilot group, never "All devices" first.** Expand in waves after each gate passes.
- **Rollback is unassignment.** Because this only adds a configuration profile, removing the
  assignment cleanly reverts behavior to pre-SSO — no enrollment or account cleanup needed. Keep the
  profile so you can re-target quickly.

## Operate and monitor
- **Report before you widen.** Run `IOSSSOEXT-Report.ps1` each wave; only broaden when coverage
  matches the assigned group.
- **Remediate with `-WhatIf` first.** `IOSSSOEXT-Remediation.ps1` and `IOSSSOEXT-Set-ScopeTargeting.ps1`
  preview by default — read the plan, then apply.
- **Keep Microsoft Authenticator current.** The extension binary ships in Authenticator; keep it
  assigned **Required** and updated so the extension identifier stays valid.
- **Don't TLS-inspect Microsoft login endpoints** — it breaks the broker token exchange.

## Change control
- **Version scope changes.** When you add bundle IDs/URLs or flip a coverage key, note the date and
  reason; re-run Discovery and Report to confirm no regressions.
- **Review after iOS major upgrades.** Confirm the extension still applies and silent SSO holds after
  significant iOS/iPadOS releases before expanding further.
