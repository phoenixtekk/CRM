# 2. Requirements Guide — Zero Trust Architecture: Conditional Access Baseline & Rollout

Verify every requirement before configuring. Each entry: Description / Why / Verify /
Implement-if-missing. Category-wide prerequisites are in `global-requirements-entra-id-solutions.md`
(tenant, licensing, admin roles, break-glass accounts, network access) — this guide adds only what is
specific to a Conditional Access baseline.

## 2.1 Entra ID licensing for Conditional Access
Description: Microsoft Entra ID P1 for Conditional Access itself; Entra ID P2 additionally for the
risk-based conditions (sign-in risk, user risk from Identity Protection).
Why: CA is a P1 feature; the risk policies in the baseline (`CA004`, `CA005`) read Identity Protection
risk signals that require P2. *Verify current availability* — bundles change.
Verify: M365 admin center -> `Billing -> Licenses`; confirm Entra ID P1 (and P2 if you want risk
policies).
Implement: Assign M365 E3/E5, EMS E3/E5, or standalone P1/P2. If P1-only, omit `CA004`/`CA005` and
compensate with compliant-device + MFA everywhere (note the gap).

## 2.2 Administrative roles
Description: `Conditional Access Administrator` (or `Security Administrator`) to create and manage the
policies; `Global Reader` / `Security Reader` for read-only discovery; reserve `Global Administrator`
for tenant-wide first-time changes.
Why: Creating and enforcing CA policies is a high-privilege action; least privilege keeps the blast
radius small.
Verify: Entra -> `Roles and administrators`; confirm the operator holds `Conditional Access
Administrator`.
Implement: Assign the role (ideally PIM-eligible); use a `Security Reader` for the discovery scripts.

## 2.3 Persona definition and group mapping
Description: A documented set of access personas — admins, internal staff, external/guest, service
accounts — each mapped to a security group: `CA Persona - Admins - Steady`, `CA Persona - Internals -
Steady`, `CA Persona - Externals-Guests - Steady`, `CA Persona - Service-Accounts - Steady`.
Why: The baseline is built by persona; policies target these groups so the design is legible,
auditable, and rolled out group by group.
Verify: The groups exist with correct membership; run `ENTZTCA-Set-ScopeTargeting.ps1` to
create/preview.
Implement: Create the groups with `ENTZTCA-Set-ScopeTargeting.ps1` (see Implementation Step 1); use
dynamic membership where a rule fits (for example guests = `userType eq 'Guest'`).

## 2.4 Pilot ring
Description: A pilot ring group `CA Pilot Ring - Pilot - Pilot` of representative users across
personas, used to validate enforcement before a wave.
Why: Every enforce step is proven on a small ring first; the pilot ring is the gate between
report-only and wave enforcement.
Verify: The group exists with representative members; run `ENTZTCA-Set-ScopeTargeting.ps1`.
Implement: Create it with `ENTZTCA-Set-ScopeTargeting.ps1`.

## 2.5 Break-glass accounts and exclusion group
Description: Two cloud-only emergency access accounts (global requirement G4) and a dedicated
exclusion group `CA Exclusion - Break-Glass - Steady` containing them, excluded from **every** policy.
Why: A misconfigured policy could otherwise lock out all admins; break-glass excluded from every
policy is the anti-lockout guarantee.
Verify: Entra -> `Users`; two cloud-only `@onmicrosoft.com` admins exist and are members of
`CA Exclusion - Break-Glass - Steady`, which is excluded from every policy.
Implement: Create the accounts and the exclusion group; add the group as an exclusion on every policy;
store credentials securely and monitor their sign-ins.

## 2.6 Device management (for device-based controls)
Description: Intune device compliance (for `Require compliant device`) and/or Entra hybrid join (for
`Require hybrid Entra-joined device`).
Why: The device grant controls in the baseline only work if devices can actually report compliance or
be hybrid-joined. *Verify current availability in your tenant.*
Verify: Entra -> `Devices` shows compliant / hybrid-joined devices; Intune compliance policies exist.
Implement: Stand up Intune compliance or Entra hybrid join first (adjacent solutions), or use the
device control the tenant supports and note the gap.

## 2.7 Legacy authentication assessment
Description: Knowledge of which apps/clients in the tenant still use legacy (basic) authentication,
which cannot do MFA and must be blocked.
Why: The baseline blocks legacy auth (`CA007`); enforcing it blindly can break a legacy line-of-
business app or mail client.
Verify: Run `ENTZTCA-Discovery.ps1` (legacy-auth section) and review sign-in logs filtered to legacy
client apps.
Implement: Identify legacy-auth users/apps, migrate them to modern auth, then block legacy in waves.

## 2.8 Microsoft Graph PowerShell SDK
Description: The Microsoft Graph PowerShell SDK on the operator workstation, consented to the scopes
the scripts use.
Why: Discovery, reporting, validation, and the safe baseline creation read and (only when applied)
write Conditional Access policies and read sign-in logs through Microsoft Graph.
Verify: `Get-Module -ListAvailable Microsoft.Graph.Authentication` returns a version; a test
`Connect-MgGraph` succeeds.
Implement: `Install-Module Microsoft.Graph -Scope CurrentUser`; scripts request least privilege
(`Policy.Read.All`, `AuditLog.Read.All`, `Directory.Read.All`, and — only for baseline creation —
`Policy.ReadWrite.ConditionalAccess`).

## 2.9 Sensitive-apps and privileged-users decision
Description: A documented list of which applications are "sensitive" and which users/roles are
"privileged."
Why: Several baseline policies scope to these; the classification is a business/security decision, not
a technical default.
Verify: Security/business owners have named the privileged roles and sensitive apps.
Implement: Capture the list; it drives the admin and sensitive-app policy scopes. Customer
compliance/security owns the determination.

---
## Checklist
- [ ] Entra ID P1 confirmed (P2 if using risk policies `CA004`/`CA005`)
- [ ] `Conditional Access Administrator` assigned; `Security Reader` for discovery
- [ ] Persona groups created — `ENTZTCA-Set-ScopeTargeting.ps1`
- [ ] Pilot ring group created
- [ ] Break-glass accounts + `CA Exclusion - Break-Glass - Steady` group created and excluded everywhere
- [ ] Device compliance / hybrid join verified (for device controls)
- [ ] Legacy-auth assessment complete — `ENTZTCA-Discovery.ps1`
- [ ] Microsoft Graph PowerShell SDK installed and consented
- [ ] Sensitive-apps and privileged-users list documented by the business
