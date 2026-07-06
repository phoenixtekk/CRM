# 7. Best Practices — macOS Enterprise SSO App Extension (App/URL Scoping)

These practices keep the app/browser SSO extension precise, predictable, and reversible. They assume
the deployment model in the Solution Overview: a **redirect-type** Extensible SSO app extension for
apps and browsers, deployed via Intune, pilot-first.

## Keep it distinct from Platform SSO
- **One profile, one purpose.** Use a **Redirect** SSO app-extension profile for apps/browsers, and —
  if you also want device login — a **separate** Platform SSO (Credential) profile from the companion
  solution. Do not merge the two intents into one policy; mixing them makes troubleshooting and
  rollback harder.
- **Name for clarity.** Name the profile so its scope is obvious, e.g. **macOS SSO App Extension –
  <ring>**, never a generic "SSO" that could be confused with device login.

## Scope apps deliberately (bundle IDs)
- **Start allow-listed, not open.** Set `AppPrefixAllowList` to the prefixes you actually support
  (for example `com.microsoft.,com.apple.`) rather than leaving it empty/broad. Widen only after the
  pilot proves stable.
- **Prefer prefixes over long ID lists.** A prefix like `com.microsoft.` covers the Office suite and
  Teams without enumerating every bundle ID; add specific IDs only for outliers.
- **Record every bundle ID you add.** Keep a short table (app → bundle ID → why included) so the next
  admin understands the scope. Verify IDs from the vendor or `osascript -e 'id of app "AppName"'`.
- **Use `AppBlockList` for exceptions,** not as the primary control — block only apps that
  misbehave with the broker.

## Scope URLs to the right cloud
- **Only your cloud's Entra URLs.** Commercial uses `login.microsoftonline.com` /
  `login.microsoft.com` / `sts.windows.net` / `login.windows.net`. US Gov uses
  `login.microsoftonline.us`; 21Vianet uses `login.partner.microsoftonline.cn`. Do **not** add clouds
  you don't use — extra URLs widen the interception surface for no benefit.
- **Add app-specific auth URLs as discovered.** If a legitimate app authenticates against an Entra URL
  not in the list, add it during the pilot and re-validate — don't wildcard.

## Set browser expectations
- **Safari is the reliable path.** WebKit/Safari flows broker natively. Standardize on Safari for
  brokered web SSO where you can.
- **Enable `browser_sso_interaction_enabled = 1`** so supporting browsers can complete interactive
  broker sign-in; document that non-supporting browsers (some Chrome/Firefox builds) fall back to
  normal sign-in — set that expectation with users up front to avoid tickets.

## Deploy pilot-first and reversibly
- **Assign to a pilot group, never "All devices" first.** Expand in waves after each gate passes.
- **Rollback is unassignment.** Because this only adds a system extension profile, removing the
  assignment cleanly reverts behavior to pre-SSO — no account or login-window cleanup needed. Keep the
  profile so you can re-target quickly.
- **Prime once, then measure.** Expect one interactive sign-in per user to seed the broker; measure
  silent SSO from the *second* sign-in onward.

## Operate and monitor
- **Report before you widen.** Run `MACSSOEXT-Report.ps1` each wave; only broaden when coverage
  matches the assigned group.
- **Remediate with `-WhatIf` first.** `MACSSOEXT-Remediation.ps1` and `MACSSOEXT-Set-ScopeTargeting.ps1`
  preview by default — read the plan, then apply.
- **Keep Company Portal current.** The extension binary ships in Company Portal; keep it assigned
  **Required** and updated so the extension identifier stays valid.
- **Don't TLS-inspect Microsoft login endpoints** — it breaks the broker token exchange.

## Change control
- **Version scope changes.** When you add bundle IDs/URLs, note the date and reason; re-run Discovery
  and Report to confirm no regressions.
- **Review after macOS major upgrades.** Confirm the extension still applies and silent SSO holds
  after significant macOS releases before expanding further.
