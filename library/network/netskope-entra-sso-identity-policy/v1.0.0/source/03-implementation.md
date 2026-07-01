# 3. Implementation Guide — Netskope + Entra ID SSO & Identity-Based Policy Enforcement

Follow these steps **in order**. The Entra ID side is documented click-by-click in the Microsoft
Entra admin center (`https://entra.microsoft.com`). The Netskope side is named at the procedural
level and the exact console controls are deferred to the official Netskope documentation and your
tenant.

> **Model:** Configure SAML SSO, then SCIM provisioning, then identity-based policy — and prove the
> whole chain on `Netskope Identity - Pilot - Stage` before expanding to `Netskope Identity - Corp - Prod`.

> **Artifact names (use verbatim):** enterprise app `Netskope SSO - Corp - Prod`; provisioning
> `Netskope SCIM Provisioning - Corp - Prod`; pilot group `Netskope Identity - Pilot - Stage`;
> production group `Netskope Identity - Corp - Prod`; policy `Identity Steering Policy - Corp - Prod`.

## Step 1 — Create the scope groups and the enterprise application
1. Entra → Groups → New group → Security → `Netskope Identity - Pilot - Stage` (a few representative users). Create.
2. Entra → Groups → New group → Security → `Netskope Identity - Corp - Prod` (the full population). Create.
3. Entra → Identity → Applications → Enterprise applications → New application. Add Netskope from the gallery (or create a non-gallery application) and name it `Netskope SSO - Corp - Prod`. Create.

## Step 2 — Configure SAML single sign-on (Entra side)
1. Entra → Identity → Applications → Enterprise applications → open `Netskope SSO - Corp - Prod` → Single sign-on → select SAML.
2. In Basic SAML Configuration, enter the Identifier (Entity ID) and Reply URL (ACS URL) for your Netskope tenant. The exact values come from Netskope — see the Netskope documentation for its SAML/SSO settings (deferred).
3. Review Attributes and Claims so the user identifier and any group claim Netskope expects are issued (confirm the required claim format in the Netskope docs).
4. In the SAML Signing Certificate section, download the Base64 certificate and copy the Login URL / App Federation Metadata URL — these are handed to Netskope in Step 3.

## Step 3 — Complete SAML on the Netskope side (deferred to Netskope docs)
1. In the Netskope admin console, configure SAML SSO using the Entra Login URL, Entra identifier, and the signing certificate from Step 2 (the exact Netskope screen/fields are deferred to the official Netskope documentation).
2. Provide Netskope's Entity ID and ACS URL back into the Entra Basic SAML Configuration if they were not known in Step 2; save on both sides.

## Step 4 — Assign the pilot group to the application
1. Entra → Enterprise applications → `Netskope SSO - Corp - Prod` → Users and groups → Add user/group.
2. Add `Netskope Identity - Pilot - Stage`. Assign. Only assigned users will get SSO and (in Step 5) be provisioned.

## Step 5 — Enable SCIM user/group provisioning (Entra side)
1. Entra → Enterprise applications → `Netskope SSO - Corp - Prod` → Provisioning → Get started → set Provisioning Mode to Automatic.
2. Under Admin Credentials, enter the Netskope SCIM Tenant URL and Secret Token. These are issued by Netskope — generate/copy them in the Netskope console (the exact location is deferred to the Netskope documentation).
3. Test Connection; when it succeeds, treat this provisioning configuration as `Netskope SCIM Provisioning - Corp - Prod`.
4. Under Mappings, confirm the user and group attribute mappings (at minimum a stable user identifier and group membership) match what Netskope expects per the Netskope docs.
5. Under Settings, set Scope to "Sync only assigned users and groups," then Save.

## Step 6 — Start provisioning to the pilot scope
1. On the Provisioning page, set Provisioning Status to On.
2. Provisioning runs on a recurring cycle; the first cycle provisions the members of `Netskope Identity - Pilot - Stage` into Netskope. Monitor Provisioning logs for success.
3. Run `NSSSO-Validation.ps1` to confirm the app's SSO is configured and provisioning is enabled; run `NSSSO-Report.ps1` for SSO/SCIM/group coverage.

## Step 7 — Build the identity-based policy (Netskope side, deferred)
1. In Netskope, create `Identity Steering Policy - Corp - Prod` and target it by the provisioned group (the pilot group first), so steering/real-time controls apply by identity rather than by IP (exact Netskope policy screens deferred to the Netskope documentation).
2. Keep this distinct from Entra Conditional Access: this policy governs Netskope's inline controls on the user's traffic, not the authentication gate (see Overview).

## Step 8 — Validate the pilot
1. Have a pilot user sign in to Netskope via SSO; confirm the Entra-issued identity is recognized.
2. Confirm the pilot users/groups appear in Netskope (provisioned by SCIM); confirm `Identity Steering Policy - Corp - Prod` matches by group.
3. Run `NSSSO-Validation.ps1` (SSO + provisioning enabled) and `NSSSO-Report.ps1` (coverage). Complete the Testing Guide pilot gate before expanding.

## Step 9 — Expand to production
1. Entra → Enterprise applications → `Netskope SSO - Corp - Prod` → Users and groups → add `Netskope Identity - Corp - Prod`. Assign — SSO and SCIM now cover the full population.
2. Confirm a provisioning cycle completes for the larger scope (Provisioning logs); re-run `NSSSO-Report.ps1`.
3. Extend `Identity Steering Policy - Corp - Prod` (and any per-group policies) to the production groups only after the pilot gate passes.

---
### Order of operations
`Scope groups + enterprise app -> SAML SSO (Entra) -> SAML SSO (Netskope) -> assign pilot -> SCIM provisioning -> start provisioning -> identity policy -> validate pilot -> expand`
