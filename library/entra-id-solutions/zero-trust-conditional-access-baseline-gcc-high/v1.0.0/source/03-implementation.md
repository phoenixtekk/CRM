# 3. Implementation Guide — Zero Trust Architecture: Conditional Access Baseline & Rollout

Follow these steps in order. Most steps are in the **GCC High Microsoft Entra admin center** — the
Azure Government portal (`https://portal.azure.us` → **Microsoft Entra ID**); *verify the current GCC
High Entra admin-center URL for your tenant*. Sign-in is via `login.microsoftonline.us`. Discovery,
reporting, validation, and the safe baseline creation use the included scripts, which connect to the
US Gov cloud (`Connect-MgGraph -Environment USGov`).

> **National cloud (GCC High):** all portal navigation paths below (`Identity -> Protection ->
> Conditional Access`, `What If`, `Insights and reporting`) are the same, but reached through the
> Azure Government portal. **Feature parity can lag commercial** — risk-based CA (`CA004`/`CA005`, Entra
> ID P2 / Identity Protection), authentication strengths, and device controls **may be delayed,
> unavailable, or different** in GCC High/DoD. **Verify each against current Microsoft Government
> documentation** for your cloud (GCC High vs DoD/IL5) and omit/substitute where not available, noting
> the gap. DoD/IL5 Graph host is `dod-graph.microsoft.us` and the SDK environment is `USGovDoD`.

> Model: define personas as groups, build a numbered baseline of policies **all in report-only** with
> break-glass excluded, validate every policy with report-only insights and the What-If tool on a
> pilot ring, then enforce wave by wave with rollback ready. No policy is ever created straight into
> enforcement, and break-glass is excluded from every policy from the first save.

**Object naming convention (used everywhere below and in the scripts): `<Purpose> - <Scope> -
<Stage>` for groups, and `CA0nn <Purpose> - <Persona> - <Stage>` for policies.** Create these once and
reuse the exact names in testing, troubleshooting, and scripts:

| Object | Name |
|---|---|
| Break-glass exclusion group | `CA Exclusion - Break-Glass - Steady` |
| Admins persona | `CA Persona - Admins - Steady` |
| Internal staff persona | `CA Persona - Internals - Steady` |
| External / guest persona | `CA Persona - Externals-Guests - Steady` |
| Service accounts persona | `CA Persona - Service-Accounts - Steady` |
| Pilot ring | `CA Pilot Ring - Pilot - Pilot` |

Baseline policies (each created `- Report-Only`, later renamed `- Enforce`):

| # | Policy | Persona | Control | License |
|---|---|---|---|---|
| CA001 | `CA001 Require MFA - Internals - Report-Only` | Internals | Require MFA | P1 |
| CA002 | `CA002 Require Phishing-Resistant MFA - Admins - Report-Only` | Admins | Auth strength: phishing-resistant | P1 |
| CA003 | `CA003 Require Compliant or Hybrid Device - Internals - Report-Only` | Internals | Require compliant OR hybrid device | P1 + Intune/hybrid |
| CA004 | `CA004 Sign-in Risk MFA - Internals - Report-Only` | Internals | Require MFA on medium+ sign-in risk | **P2** |
| CA005 | `CA005 User Risk Password Change - Internals - Report-Only` | Internals | Require secure password change on high user risk | **P2** |
| CA006 | `CA006 App-Enforced Restrictions - Externals-Guests - Report-Only` | Guests | Session: app-enforced restrictions | P1 |
| CA007 | `CA007 Block Legacy Authentication - All Users - Report-Only` | All (break-glass excluded) | Block | P1 |
| CA008 | `CA008 Sign-in Frequency + No Persistent Browser - Admins - Report-Only` | Admins | Session controls | P1 |

> `CA004`/`CA005` require Entra ID P2; `CA003` requires Intune compliance or hybrid join. *Verify
> availability in your tenant* and omit/substitute where you are not licensed, noting the gap.

## Step 1 — Create the persona, exclusion, and pilot groups
1. Entra -> `Identity -> Groups -> All groups -> New group` -> Security -> create
   `CA Exclusion - Break-Glass - Steady` and add the two break-glass accounts.
2. Create the persona groups `CA Persona - Admins - Steady`, `CA Persona - Internals - Steady`,
   `CA Persona - Externals-Guests - Steady` (dynamic rule `user.userType -eq "Guest"` works well),
   `CA Persona - Service-Accounts - Steady`, and the `CA Pilot Ring - Pilot - Pilot`.
3. Or run `ENTZTCAG-Set-ScopeTargeting.ps1` to create and preview all groups before you commit.

## Step 2 — Assess the current state (baseline)
1. Run `ENTZTCAG-Discovery.ps1`. It reports, read-only: existing CA policies and their states, which
   policies exclude break-glass, detected legacy-authentication sign-ins, per-persona sign-in volume,
   and whether the tenant is P1 or P2 (so you know if the risk policies apply).
2. Save the output — it is your before picture and your legacy-auth migration list.

## Step 3 — Build the baseline in report-only
1. For each policy in the table above: Entra -> `Identity -> Protection -> Conditional Access ->
   Policies -> New policy`, name it exactly (`CA00n ... - Report-Only`), set its assignments,
   conditions, and control per the table, and **exclude `CA Exclusion - Break-Glass - Steady`** under
   `Users -> Exclude`.
2. Set `Enable policy = Report-only` on every one. Create.
3. Or run `ENTZTCAG-Set-Baseline.ps1` (preview by default, `-WhatIf`) to create the whole numbered
   baseline in report-only with the break-glass exclusion already applied. Review the preview, then
   re-run with `-WhatIf:$false`.
4. Key details per policy:
   - `CA002`: `Grant -> Require authentication strength -> Phishing-resistant MFA` for the Admins
     persona and All cloud apps.
   - `CA003`: `Grant -> Require device to be marked compliant` OR `Require hybrid Entra joined device`
     (select "Require one of the selected controls").
   - `CA004`/`CA005`: under `Conditions -> Sign-in risk` / `User risk` (P2 only).
   - `CA006`: `Session -> Use app enforced restrictions` for the Externals-Guests persona.
   - `CA007`: `Conditions -> Client apps -> Exchange ActiveSync clients + Other clients`, `Grant ->
     Block`, include All users, exclude break-glass (and any confirmed legacy exception, documented).
   - `CA008`: `Session -> Sign-in frequency` + `Persistent browser session = Never` for Admins.

## Step 4 — Validate every policy with What-If and report-only data
1. `Conditional Access -> What If`: for each persona pick a representative user, an app, and a device
   state, and confirm the expected policies apply and the break-glass account has **no** policy
   applied. Fix scope/exclusions until What-If matches the design.
2. Let report-only run for a representative period (a few days of normal sign-ins). Review
   `Conditional Access -> Insights and reporting` and `ENTZTCAG-Report.ps1`: confirm each policy
   *would* apply to the right persona, *would not* block break-glass or service accounts, and does not
   produce unexpected blocks.

## Step 5 — Pilot enforcement on the pilot ring
1. Clone the persona policies you are ready to enforce (or add the `CA Pilot Ring - Pilot - Pilot`
   include and set `Enable policy = On`) so only the pilot ring is enforced first.
2. Have pilot users exercise real sign-ins (managed device, unmanaged device, guest, admin). Complete
   the Testing Guide. Watch for unexpected blocks; keep break-glass ready.

## Step 6 — Enforce wave by wave
1. For each baseline policy that passed: flip `Enable policy = On` and rename the suffix `-
   Report-Only` to `- Enforce`. Enforce in a sensible order — usually `CA007` (block legacy) and
   `CA001` (MFA) first for a wave, then device (`CA003`), then admin hardening (`CA002`, `CA008`),
   then risk (`CA004`/`CA005`).
2. Roll persona by persona / wave by wave: enforce for `CA Pilot Ring - Pilot - Pilot`, then a first
   wave of `CA Persona - Internals - Steady`, then the rest. Re-run `ENTZTCAG-Report.ps1` between waves
   to confirm no spike in blocks.
3. Keep each policy's report-only twin (or the ability to revert to report-only) until the wave is
   proven.

## Step 7 — Operate and review
1. Re-run `ENTZTCAG-Discovery.ps1` and `ENTZTCAG-Validate.ps1` on a cadence: confirm break-glass is
   still excluded from every policy, no policy drifted to an overbroad scope, and no new legacy-auth
   or risky sign-ins are slipping through.
2. Review exclusions quarterly — every exclusion is a documented exception with an owner and an expiry
   intent; remove the ones no longer needed.

---
### Order of operations
`Groups (personas + break-glass + pilot) -> assess -> build baseline in report-only (break-glass
excluded) -> validate with What-If + report-only data -> pilot enforce on the ring -> enforce wave by
wave -> operate/review`

### Rollback
- Any policy: set `Enable policy = Report-only` (or `Off`), or delete it — enforcement stops
  immediately. Because every policy is validated in report-only first and break-glass is excluded
  everywhere, a bad policy never locks out admins.
- If a wave causes unexpected blocks: revert that policy to report-only, use `ENTZTCAG-Report.ps1` to
  find the affected users/apps, fix the scope or exclusion, re-validate, then re-enforce.
- Emergency: sign in with a break-glass account (excluded from all policies) and set the offending
  policy to report-only.
