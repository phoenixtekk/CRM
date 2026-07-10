# 3. Implementation Guide — Passwordless & Passkey (FIDO2) Rollout for Microsoft Entra — Government (GCC High)

This is the **Government (GCC High)** edition: it mirrors the commercial passwordless method, adapted
for Microsoft's US Government national cloud (Azure Government / GCC High). Follow these steps in order.
Most steps are in the **GCC High Microsoft Entra admin center** (`https://entra.microsoft.us`); end-user
credential registration is at the **GCC High security-info portal** (`https://mysignins.microsoft.us/security-info`);
discovery, reporting, validation, and the safe methods-policy change use the included scripts, which
target the US Gov cloud (`Connect-MgGraph -Environment USGov`). *Verify the current GCC High portal URLs
against Microsoft Government documentation — DoD (IL5) tenants use different endpoints (see
`gcc-high-parity-notes.md`).*

> Model: assess current methods and adoption, enable the passwordless methods and Temporary Access
> Pass for a pilot group, drive registration with a campaign, require phishing-resistant MFA for
> admins/sensitive apps in **report-only** first, validate, then expand in waves and only then retire
> the weak methods. Every change is targeted at a group, staged, and reversible; break-glass accounts
> are excluded from the enforcement policies throughout.

**Object naming convention (used everywhere below and in the scripts): `<Purpose> - <Scope> -
<Stage>`.** Create these once and reuse the exact names in testing, troubleshooting, and scripts:

| Object | Name |
|---|---|
| Pilot users group | `Passwordless Rollout - Pilot - Pilot` |
| Pilot admins group | `Passwordless Rollout - Admins - Pilot` |
| Expansion wave group (repeat per wave) | `Passwordless Rollout - Wave1 - Expand` |
| Registration campaign scope | `Passwordless Registration Campaign - Pilot - Pilot` |
| CA policy — admins | `Require Phishing-Resistant MFA - Admins - Report-Only` (later `- Enforce`) |
| CA policy — sensitive apps | `Require Phishing-Resistant MFA - SensitiveApps - Report-Only` (later `- Enforce`) |

## Step 1 — Create the rollout and campaign groups
1. Entra -> `Identity -> Groups -> All groups -> New group` -> Security ->
   `Passwordless Rollout - Pilot - Pilot`; add a few representative users. Create.
2. Repeat for `Passwordless Rollout - Admins - Pilot` (the pilot administrators),
   `Passwordless Registration Campaign - Pilot - Pilot`, and the first expansion wave
   `Passwordless Rollout - Wave1 - Expand`.
3. Or run `ENTPASSKEYG-Set-ScopeTargeting.ps1` to create and populate the groups and preview
   membership before you commit.

## Step 2 — Assess the current state (baseline)
1. Run `ENTPASSKEYG-Discovery.ps1`. It reports, read-only: which authentication methods are enabled
   and to whom they are targeted, whether FIDO2 / Passkey (Authenticator) / TAP are on, whether the
   weak methods (SMS, Voice) are still enabled, and the current CA policies that require MFA.
2. Run `ENTPASSKEYG-Report.ps1` for the adoption baseline — who is already registered for a
   phishing-resistant method versus who is still on password + weak MFA. Save both outputs; they are
   your before picture.

## Step 3 — Enable Temporary Access Pass (the safety net first)
1. Entra -> `Identity -> Protection -> Authentication methods -> Policies -> Temporary Access Pass`.
2. Set to `Enable`, target the recovery operators (help desk / `Passwordless Rollout - Admins -
   Pilot`), and set a sensible lifetime and one-time/multi-use option. Save.
3. TAP is enabled *before* passwordless so a user always has a supported way to bootstrap or recover
   a credential without a password.

## Step 4 — Enable the passwordless methods for the pilot
1. Entra -> `Identity -> Protection -> Authentication methods -> Policies -> FIDO2 security key` ->
   `Enable`; under `Target`, select `Passwordless Rollout - Admins - Pilot` (and the pilot group).
   Under `Configure`, set `Allow self-service set up = Yes`; set `Enforce attestation` and
   `Enforce key restrictions` per your policy (allow-list your vetted AAGUIDs from requirement 2.3 if
   you are restricting key models). Save.
2. `Passkey (FIDO2)` / Microsoft Authenticator passwordless method -> `Enable` -> target
   `Passwordless Rollout - Pilot - Pilot`. *Verify current passkey options and any preview status in
   your tenant* before choosing device-bound settings. Save.
3. Optionally run `ENTPASSKEYG-Set-MethodsPolicy.ps1` (preview by default, `-WhatIf`) to apply the
   same enablement + targeting from PowerShell; review the preview, then re-run with `-WhatIf:$false`.
4. **Do not disable SMS or Voice yet** — retirement is Step 9, after adoption is proven.

## Step 5 — Turn on the registration campaign for the pilot
1. Entra -> `Identity -> Protection -> Authentication methods -> Registration campaign`.
2. Set `State = Enabled`, choose to nudge users toward the passkey/Authenticator method, and target
   `Passwordless Registration Campaign - Pilot - Pilot`. Set the snooze/`days allowed to snooze`
   value. Save.
3. Send the pilot the onboarding comms (a short "you'll be asked to set up a passkey — here's how"
   email and a one-page how-to). Clear comms are what make adoption self-service instead of a ticket
   queue.

## Step 6 — Require phishing-resistant MFA for admins (report-only first)
1. Entra -> `Identity -> Protection -> Conditional Access -> Policies -> New policy` named
   `Require Phishing-Resistant MFA - Admins - Report-Only`.
2. `Users`: include the directory roles / `Passwordless Rollout - Admins - Pilot`; **exclude the two
   break-glass accounts** (and any service accounts that cannot use passwordless).
3. `Target resources`: `All cloud apps` (or the admin/portal apps you scope to first).
4. `Grant`: `Grant access -> Require authentication strength -> Phishing-resistant MFA`.
5. Set `Enable policy = Report-only`. Create. Report-only evaluates the policy and logs what it
   *would* do without blocking anyone.
6. Create a second policy `Require Phishing-Resistant MFA - SensitiveApps - Report-Only` the same way,
   scoped to the sensitive apps from requirement 2.7 and the users who reach them, also in
   report-only.

## Step 7 — Pilot: register and sign in passwordless
1. Pilot admins register a FIDO2 security key at the GCC High security-info portal
   (`https://mysignins.microsoft.us/security-info`) -> `Add sign-in method -> Security key` (use a TAP
   if they have no other method yet). *Verify the current GCC High URL.*
2. Pilot users register a passkey in Microsoft Authenticator (`Add sign-in method -> Passkey`),
   prompted by the registration campaign.
3. Each pilot user signs out and signs back in using the passwordless credential to confirm the
   end-to-end flow works. Complete the Testing Guide.

## Step 8 — Validate the pilot
1. Run `ENTPASSKEYG-Validate.ps1` -> confirms FIDO2 and Passkey (Authenticator) are enabled and
   targeted, TAP is enabled, the CA policies exist with the phishing-resistant strength and the
   break-glass exclusion, and (report-only) that the policies are evaluating.
2. Review the report-only impact in `Conditional Access -> Insights and reporting` (and
   `ENTPASSKEYG-Report.ps1`): confirm the admins policy would have required phishing-resistant MFA and
   would **not** have blocked the break-glass accounts. Only proceed to enforce when the pilot passes.

## Step 9 — Enforce for admins, then expand in waves
1. Flip `Require Phishing-Resistant MFA - Admins - Report-Only` to `Enable policy = On` (rename the
   `- Report-Only` suffix to `- Enforce`). Admin access is now passwordless-only. Do the same for the
   sensitive-apps policy once its report-only data is clean.
2. For each expansion wave: add the wave group (for example `Passwordless Rollout - Wave1 - Expand`)
   to the FIDO2/passkey method targeting and to the registration campaign, send that wave's comms,
   let them register, then bring them into the phishing-resistant CA scope in report-only -> validate
   -> enforce. Repeat wave by wave.
3. **Retire the weak methods last.** Once a wave's adoption is high (from `ENTPASSKEYG-Report.ps1`),
   scope SMS and Voice *out* for that group in the authentication methods policy. Never retire a weak
   method for users who have not yet registered a stronger one — that is the classic lock-out.

## Step 10 — Operate the recovery runbook
1. Lost/broken key or replaced phone: the help desk verifies the user's identity, revokes the lost
   credential (`My Security info` / admin removes the method), issues a **Temporary Access Pass**, and
   the user re-registers a new passkey/key. Document each step (see the lost-key runbook in Best
   Practices).

---
### Order of operations
`Groups -> assess -> enable TAP -> enable FIDO2/passkey (pilot) -> registration campaign -> CA
phishing-resistant (report-only) -> pilot register/sign-in -> validate -> enforce + expand in waves
-> retire weak methods last -> operate recovery`

### Rollback
- Method enablement: set the method back to `Disable` or remove the group from `Target` in the
  authentication methods policy (immediate).
- Registration campaign: set `State = Disabled` (immediate; users already registered keep their
  credential).
- CA policy: set `Enable policy = Report-only` or `Off`, or delete the policy — enforcement stops at
  once. Because every enforce step follows a clean report-only pilot and break-glass is always
  excluded, a bad policy never locks out admins.
- Weak-method retirement: re-add the group to SMS/Voice targeting to restore the fallback while you
  investigate.
