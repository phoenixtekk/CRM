# 3. Implementation Guide — Entra Identity Protection & Advanced Conditional Access

Follow these steps in order, in the Microsoft Entra admin center (`https://entra.microsoft.com`),
mainly under `Protection`. Every new policy is created in **Report-only** mode first; you enforce only
after the Testing Guide passes. Break-glass accounts (via the `CA Break-Glass Exclusion` group) are
excluded from every policy in this guide.

> Model: configure the risk engine and advanced controls in report-only, pilot against a small scope,
> validate the report-only results against real traffic, then flip to enforce in stages, then expand.
> Every object you create uses the convention `<Purpose> – <Scope> – <Stage>` and is reused by name in
> Testing and Troubleshooting.

## Naming convention (create/verify these exact names)
| Object | Name |
|---|---|
| Pilot scope group | `IDP Pilot – Risk Scope – Pilot` |
| Break-glass exclusion group | `CA Break-Glass Exclusion` |
| Named location | `Named Location – Trusted Egress – Pilot` |
| Authentication strength | `Auth Strength – Phishing-Resistant – Pilot` |
| Authentication context | `Auth Context c1 – Sensitive Actions – Pilot` |
| Sign-in risk policy | `CA – Sign-In Risk – Pilot (Report-Only)` |
| User risk policy | `CA – User Risk – Pilot (Report-Only)` |
| Step-up (context) policy | `CA – Step-Up Sensitive Apps – Pilot (Report-Only)` |
| Token protection policy | `CA – Token Protection – Pilot (Report-Only)` |

## Step 1 — Assess and record the starting state
1. Run `ENTIDP-Discovery.ps1` to inventory current Conditional Access policies, Identity Protection availability, named locations, authentication strengths, and authentication contexts. Keep the output as your before-state.
2. Entra -> `Protection -> Identity Protection`; confirm the `Risky users`, `Risky sign-ins`, and `Risk detections` reports show data (confirms P2 signal is flowing). *Verify P2 licensing if the reports are empty.*
3. Confirm your Conditional Access baseline is On and that `CA Break-Glass Exclusion` exists and is excluded from the baseline. Do not proceed until break-glass exclusion is confirmed.

## Step 2 — Create the pilot scope and confirm break-glass exclusion
1. Entra -> `Groups -> New group` -> Security -> name `IDP Pilot – Risk Scope – Pilot`; add a few representative users (at least one non-admin and one admin who is not break-glass). Create.
2. Confirm `CA Break-Glass Exclusion` contains both cloud-only break-glass accounts. You will add this group to the Exclude tab of every policy below.

## Step 3 — Create a named location and an authentication strength
1. Entra -> `Protection -> Conditional Access -> Named locations -> + Countries location` or `+ IP ranges location`; create `Named Location – Trusted Egress – Pilot` with your organisation's known-good egress IP ranges. Mark as trusted only if you are confident in the ranges. Save.
2. Entra -> `Protection -> Authentication methods -> Authentication strengths -> + New authentication strength`; name it `Auth Strength – Phishing-Resistant – Pilot`; select phishing-resistant methods (FIDO2 security key, passkey, Windows Hello for Business, certificate-based). Save. *Verify the methods you select are registered for your pilot users (Requirement 2.5).*

## Step 4 — Create the authentication context and map a sensitive action
1. Entra -> `Protection -> Conditional Access -> Authentication context -> + New authentication context`; name it `Auth Context c1 – Sensitive Actions – Pilot`; tick "Publish to apps"; save (it takes an ID such as `c1`).
2. Map the context to something sensitive: for a sensitive app, you will reference the context in the step-up policy (Step 6). To protect a sensitive *action*, map the context where the action is defined — for example PIM role activation (`Identity governance -> PIM -> Roles -> Settings -> require authentication context on activation`) or a sensitive SharePoint site. *Verify current authentication-context integration points for your target service.*

## Step 5 — Create the risk-based policies (Report-only)
1. Entra -> `Protection -> Conditional Access -> Policies -> + New policy`; name `CA – Sign-In Risk – Pilot (Report-Only)`.
   - Assignments -> Users: include `IDP Pilot – Risk Scope – Pilot`; exclude `CA Break-Glass Exclusion`.
   - Target resources: All cloud apps.
   - Conditions -> Sign-in risk: select `High` and `Medium`.
   - Grant: Require multi-factor authentication (optionally require `Auth Strength – Phishing-Resistant – Pilot`).
   - Enable policy: **Report-only**. Create.
2. `+ New policy`; name `CA – User Risk – Pilot (Report-Only)`.
   - Users: include the pilot group; exclude `CA Break-Glass Exclusion`.
   - Target resources: All cloud apps.
   - Conditions -> User risk: select `High`.
   - Grant: Require multi-factor authentication AND Require password change.
   - Enable policy: **Report-only**. Create.

## Step 6 — Create the step-up (authentication context) policy (Report-only)
1. `+ New policy`; name `CA – Step-Up Sensitive Apps – Pilot (Report-Only)`.
   - Users: include the pilot group; exclude `CA Break-Glass Exclusion`.
   - Target resources: change the selector to `Authentication context` and select `Auth Context c1 – Sensitive Actions – Pilot`.
   - Grant: Require authentication strength -> `Auth Strength – Phishing-Resistant – Pilot` (or Require MFA if you are not ready for phishing-resistant).
   - Enable policy: **Report-only**. Create.

## Step 7 — Create the token protection policy (Report-only)
1. `+ New policy`; name `CA – Token Protection – Pilot (Report-Only)`.
   - Users: include the pilot group; exclude `CA Break-Glass Exclusion`.
   - Target resources: select the supported workloads (for example Office 365 / Exchange Online and SharePoint Online) — *verify current token-protection-supported apps and clients in your tenant.*
   - Conditions -> Client apps / Device platforms: restrict to the supported scenario (currently specific Windows sign-in scenarios).
   - Session: tick **Require token protection for sign-in sessions**.
   - Enable policy: **Report-only**. Create.
2. Confirm Continuous Access Evaluation is enabled (it is on by default for supported services). You do not create a separate CAE policy; it is honoured by supported resource providers. Verify with `ENTIDP-Validate.ps1`.

## Step 8 — Pilot and read the report-only results
1. Have pilot users sign in and exercise the sensitive app/action, and (where safe) simulate a risky sign-in condition. Run `ENTIDP-Validate.ps1` to confirm all four policies exist, are report-only, and exclude break-glass.
2. Entra -> `Sign-in logs`; open a pilot sign-in -> `Report-only` tab; confirm each policy shows "Would apply" / "Would block" as intended and that **no break-glass account** shows an apply. Run `ENTIDP-Report.ps1` for the aggregate risk-and-coverage picture.
3. This is the pass/fail gate. Do not enforce until the report-only results match intent (see Testing Guide).

## Step 9 — Flip to enforcement in stages (staged rollout)
1. Enforce the least-disruptive policy first. In each policy, set `Enable policy` to **On**, or use `ENTIDP-Set-PolicyState.ps1` (default `-WhatIf` preview) to flip a named policy from report-only to enabled after review. Recommended order: sign-in risk -> user risk -> step-up -> token protection.
2. After each flip, watch `Sign-in logs` (now the real `Conditional Access` tab, not report-only) and the risky-sign-ins report for unexpected blocks; keep a break-glass account ready. Rename each policy by dropping the `(Report-Only)` suffix once enforced (for example `CA – Sign-In Risk – Pilot`).
3. If a flip causes unexpected blocks, set the policy back to Report-only immediately (or re-run `ENTIDP-Set-PolicyState.ps1` to revert) and investigate.

## Step 10 — Expand to production
1. Broaden each policy's Users assignment from `IDP Pilot – Risk Scope – Pilot` to All users (keeping `CA Break-Glass Exclusion` on the Exclude tab), re-validating in report-only for the wider scope before enforcing.
2. Extend token protection and step-up to additional supported apps/actions as their prerequisites are met.
3. Stand up the ongoing risk operations loop: triage risky users/sign-ins, dismiss false positives, confirm compromises, and run `ENTIDP-RiskHunt.ps1` (KQL or Graph fallback) on a schedule.

---
### Order of operations
`Assess/discovery -> Pilot + break-glass exclusion -> Named location + auth strength -> Auth context -> Risk policies (report-only) -> Step-up policy (report-only) -> Token protection (report-only) -> Read report-only results -> Staged enforce -> Expand`
