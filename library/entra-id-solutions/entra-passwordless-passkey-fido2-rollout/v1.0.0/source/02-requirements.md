# 2. Requirements Guide — Passwordless & Passkey (FIDO2) Rollout for Microsoft Entra

Verify every requirement before configuring. Each entry: Description / Why / Verify /
Implement-if-missing. Category-wide prerequisites are in `global-requirements-entra-id-solutions.md`
(tenant, licensing, admin roles, break-glass accounts, network access) — this guide adds only what is
specific to a passwordless rollout.

## 2.1 Entra ID licensing for enforcement
Description: Microsoft Entra ID P1 to require a phishing-resistant method through Conditional Access;
P2 if you also want risk-based conditions in the same policy set. Passwordless *registration and
sign-in* work on any tenant; the Conditional Access *enforcement* needs P1+.
Why: The Conditional Access authentication-strength grant control (require phishing-resistant MFA) is
a P1 feature; sign-in/user-risk conditions are P2.
Verify: M365 admin center -> `Billing -> Licenses`; confirm Entra ID P1/P2. *Verify current
availability* — licensing bundles change.
Implement: Assign M365 E3/E5, EMS E3/E5, or standalone Entra ID P1/P2.

## 2.2 Administrative roles
Description: `Authentication Policy Administrator` to edit the authentication methods policy and
registration campaign; `Conditional Access Administrator` (or `Security Administrator`) for the CA
policies; `Authentication Administrator` to issue a Temporary Access Pass. Reserve `Global
Administrator` for the first-time tenant-wide changes only.
Why: These are the least-privilege roles that can enable methods, run the registration campaign,
create the CA policy, and issue recovery TAPs — without over-granting.
Verify: Entra -> `Roles and administrators`; confirm the operator holds `Authentication Policy
Administrator` and `Conditional Access Administrator`.
Implement: Assign the roles above; keep them in PIM/eligible where possible.

## 2.3 FIDO2 security keys (for the key-based users)
Description: Physical FIDO2 security keys for admins, shared workstations, and anyone who needs a
portable credential. Prefer keys whose Authenticator Attestation GUID (AAGUID) you can allow-list.
Why: Admins and kiosk/shared devices need a credential not tied to one personal phone; AAGUID
allow-listing lets you accept only vetted key models.
Verify: Keys are on hand for the pilot admins; you have their AAGUIDs (from the vendor) if you intend
to restrict key models.
Implement: Procure FIDO2 keys from a reputable vendor; record AAGUIDs for the optional allow-list in
the FIDO2 method settings.

## 2.4 Microsoft Authenticator (for passkey / device-bound passkeys)
Description: A current version of Microsoft Authenticator on pilot users' phones for the
Passkey (FIDO2) / passwordless-phone-sign-in method.
Why: The lowest-friction workforce credential is a passkey in Authenticator; it requires the app
installed, updated, and the device meeting the app's platform requirements.
Verify: Pilot users have the latest Authenticator installed. *Verify current passkey availability and
any preview status in your tenant* under the authentication methods policy.
Implement: Deploy/update Microsoft Authenticator (via Intune or the app store) to pilot users before
the registration campaign.

## 2.5 Temporary Access Pass (TAP) enabled
Description: The Temporary Access Pass method enabled in the authentication methods policy, scoped to
the help desk / admins who will issue it.
Why: TAP is how a user bootstraps their first passwordless credential and how you recover a lost key
without falling back to a password — it is the safety net for the whole rollout.
Verify: Entra -> `Identity -> Protection -> Authentication methods -> Policies -> Temporary Access
Pass` is enabled and targeted appropriately.
Implement: Enable TAP; set lifetime/one-time options; scope issuance to the recovery operators.

## 2.6 Pilot and rollout groups
Description: Security groups for the staged rollout — a pilot group `Passwordless Rollout - Pilot -
Pilot`, an admin group `Passwordless Rollout - Admins - Pilot`, and per-wave groups (for example
`Passwordless Rollout - Wave1 - Expand`).
Why: Every method-enable, registration campaign, and CA policy is targeted at a group so the rollout
is staged and reversible — never tenant-wide on day one.
Verify: The groups exist with the intended members; run `ENTPASSKEY-Set-ScopeTargeting.ps1` to
create/preview them.
Implement: Create the groups with `ENTPASSKEY-Set-ScopeTargeting.ps1` (see Implementation Step 1).

## 2.7 Sensitive-apps and privileged-users decision
Description: A documented list of which applications are "sensitive" and which users/roles are
"privileged" — the first targets for required phishing-resistant MFA.
Why: Conditional Access enforcement is scoped to these; the decision is a business/security call, not
a technical default.
Verify: Security/business owners have named the privileged roles and sensitive apps.
Implement: Capture the list; it drives the CA policy scope in Implementation Step 6. This is a
customer compliance/security decision — the guide provides the control, not the determination.

## 2.8 Microsoft Graph PowerShell SDK
Description: The Microsoft Graph PowerShell SDK on the operator workstation, consented to the scopes
the scripts use.
Why: Discovery, reporting, validation, and the safe methods-policy change read and (only when
applied) write the authentication methods policy and registration state through Microsoft Graph.
Verify: `Get-Module -ListAvailable Microsoft.Graph.Authentication` returns a version; a test
`Connect-MgGraph` succeeds.
Implement: `Install-Module Microsoft.Graph -Scope CurrentUser`; scripts request least privilege
(`Policy.Read.All`, `UserAuthenticationMethod.Read.All`, `AuditLog.Read.All`, and — only for the
policy change — `Policy.ReadWrite.AuthenticationMethod`).

## 2.9 Break-glass accounts (from global requirements)
Description: Two cloud-only emergency access accounts, excluded from the phishing-resistant CA
policies at all times.
Why: A method-policy or CA change could interfere with normal admin sign-in; break-glass restores
access. See global requirement G4.
Verify: Entra -> `Users`; two cloud-only `@onmicrosoft.com` admins exist and are excluded from the CA
policies you create.
Implement: Create them, exclude from the CA policies, store credentials securely, monitor sign-ins.

---
## Checklist
- [ ] Entra ID P1/P2 licensing confirmed (P1 for CA enforcement, P2 for risk conditions)
- [ ] Roles assigned — `Authentication Policy Administrator`, `Conditional Access Administrator`, `Authentication Administrator`
- [ ] FIDO2 security keys on hand (AAGUIDs recorded if allow-listing)
- [ ] Microsoft Authenticator deployed/updated for pilot users (passkey availability verified)
- [ ] Temporary Access Pass method enabled and scoped to recovery operators
- [ ] Pilot / admin / wave groups created — `ENTPASSKEY-Set-ScopeTargeting.ps1`
- [ ] Sensitive-apps and privileged-users list documented by the business
- [ ] Microsoft Graph PowerShell SDK installed and consented
- [ ] Two break-glass accounts created and excluded from the CA policies
