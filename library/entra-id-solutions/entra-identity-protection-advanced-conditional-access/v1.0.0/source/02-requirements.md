# 2. Requirements Guide — Entra Identity Protection & Advanced Conditional Access

Verify every requirement before configuring. Each entry: Description · Why · Verify ·
Implement-if-missing. Category-wide prerequisites (tenant, base licensing, admin roles, break-glass
accounts, network) are in `global-requirements-entra-id-solutions.md` — do not repeat them here;
confirm them first.

## 2.1 Entra ID P2 licensing (risk-based policies)
Description: Microsoft Entra ID P2 for the users who will be covered by risk-based Conditional Access and seen in risky users/sign-ins.
Why: Risk-based Conditional Access, the full risky-users/risky-sign-ins reports, and risk remediation are P2 features; with only P1 you get limited risk signal and cannot use risk as a policy condition.
Verify: M365 admin center -> `Billing -> Licenses`; confirm Entra ID P2 (often bundled in EMS E5 / M365 E5). In Entra -> `Protection -> Identity Protection`, confirm the risky users/sign-ins reports show data. *Verify current licensing availability in your tenant.*
Implement: Assign Entra ID P2 (or a bundle that includes it) to the in-scope users, then run `ENTIDP-Discovery.ps1`.

## 2.2 A Conditional Access baseline already in place
Description: An existing Conditional Access baseline (require MFA for admins/users, block legacy authentication, require compliant/hybrid-joined device where used).
Why: This solution is the risk/advanced *layer* — it assumes the baseline exists. Risk-based and step-up policies complement the baseline; they do not replace require-MFA or block-legacy-auth.
Verify: Entra -> `Protection -> Conditional Access -> Policies`; confirm baseline policies exist and are On; run `ENTIDP-Discovery.ps1` to inventory them.
Implement: Deploy the Conditional Access baseline first (see the Conditional Access baseline solution / "where to go next" in Best Practices), then return here.

## 2.3 Break-glass exclusion group
Description: A security group containing your two cloud-only break-glass accounts, excluded from every risk and enforcement policy created here.
Why: A misconfigured risk policy or a premature enforcement flip could otherwise lock out all administrators; break-glass accounts must always retain a path in.
Verify: Entra -> `Groups`; confirm a group (for example `CA Break-Glass Exclusion`) contains both break-glass accounts; confirm it is on the Exclude list of your baseline policies; run `ENTIDP-Discovery.ps1`.
Implement: Create `CA Break-Glass Exclusion`, add both cloud-only break-glass accounts, and add it to the Exclude tab of every policy in this solution.

## 2.4 Legacy authentication blocked
Description: Legacy/basic authentication protocols blocked by Conditional Access (part of the baseline).
Why: Legacy authentication bypasses modern controls including risk evaluation, token protection, and CAE; leaving it open undermines every control in this solution.
Verify: Entra -> `Protection -> Conditional Access`; confirm a policy blocks legacy authentication; check `Sign-in logs` for legacy-auth sign-ins; run `ENTIDP-Report.ps1`.
Implement: Add/confirm a Conditional Access policy blocking legacy authentication for all users (with break-glass excluded) before enforcing risk policies.

## 2.5 Strong authentication methods registered
Description: In-scope users (especially pilot users) have modern MFA registered; for authentication-strength policies, phishing-resistant methods (FIDO2 security key, passkey, Windows Hello for Business, or certificate) are available.
Why: A risk-based challenge or a step-up that demands a method the user has not registered will block them; phishing-resistant strengths require the corresponding method to exist.
Verify: Entra -> `Protection -> Authentication methods -> Activity` (registration report); run `ENTIDP-Report.ps1`.
Implement: Drive MFA/passwordless registration first (see the passwordless / passkey solutions); for phishing-resistant strengths, enable and register FIDO2/passkey/WHfB for pilot users.

## 2.6 Pilot scope group
Description: A small security group of representative users to validate risk policies, step-up, token protection, and strengths before tenant-wide rollout.
Why: The identity plane is high risk; a report-only pilot proves the blast radius and the user experience before enforcement expands.
Verify: Entra -> `Groups`; confirm the pilot group exists; run `ENTIDP-Validate.ps1`.
Implement: Create `IDP Pilot – Risk Scope – Pilot` and add a few representative users (include at least one non-admin and one admin who is *not* break-glass).

## 2.7 Sign-in log export for KQL risk hunting (optional)
Description: Entra sign-in and risk logs exported to a Log Analytics workspace / Microsoft Sentinel, if you want to run the included KQL risk-hunting queries.
Why: `ENTIDP-RiskHunt.ps1` runs KQL against exported sign-in/risk logs for trend and hunting queries; without export, use the Graph-based fallback in the same script and the Identity Protection portal.
Verify: Entra -> `Identity -> Monitoring & health -> Diagnostic settings`; confirm `SignInLogs`, `RiskyUsers`, and `UserRiskEvents` are exported to a workspace. *Verify current diagnostic category availability in your tenant.*
Implement: Add a diagnostic setting exporting the sign-in and risk log categories to a Log Analytics workspace (Sentinel-enabled if you use Sentinel).

---
## Checklist
- [ ] Entra ID P2 assigned to in-scope users — `ENTIDP-Discovery.ps1` *(verify availability)*
- [ ] Conditional Access baseline in place and On
- [ ] `CA Break-Glass Exclusion` group contains both break-glass accounts
- [ ] Legacy authentication blocked — `ENTIDP-Report.ps1`
- [ ] Modern / phishing-resistant methods registered for pilot users — `ENTIDP-Report.ps1`
- [ ] `IDP Pilot – Risk Scope – Pilot` group created — `ENTIDP-Validate.ps1`
- [ ] (Optional) Sign-in/risk logs exported for KQL — `ENTIDP-RiskHunt.ps1`
