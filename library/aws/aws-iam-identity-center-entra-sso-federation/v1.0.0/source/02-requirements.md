# 2. Requirements — AWS IAM Identity Center + Microsoft Entra SSO Federation

The AWS category prerequisites (management/root access, least-privilege deployment identity, AWS CLI + Terraform toolchain, source control + CI/CD with OIDC, remote state, region/tagging standards, an identity provider, and a non-production account with change control) are published once in **Global Requirements — AWS** and are not repeated here. Confirm those first. Below are the prerequisites **specific to federating IAM Identity Center with Entra ID**. Each item: Description / Why required / How to verify / How to implement if missing.

## R1. AWS Organizations enabled with all features
Description: The AWS account you run this from must be part of an organization created in AWS Organizations, with **all features** enabled (not just consolidated billing).
Why required: IAM Identity Center is an organization-level service; org-wide enablement, delegated administration, and multi-account assignments require Organizations with all features.
How to verify: In the AWS Organizations console the management account shows "All features" enabled; `aws organizations describe-organization` returns `"FeatureSet": "ALL"`.
How to implement if missing: Enable all features in AWS Organizations (management account) and accept the invitation from member accounts, or deploy the AWS landing-zone solution first. *Enabling all features is a one-way action approved by the org owner.*

## R2. IAM Identity Center available in your chosen home Region
Description: A single AWS Region designated as the IAM Identity Center "home" (identity store) Region, supported in your partition.
Why required: IAM Identity Center has one instance per organization anchored to a home Region; the SAML/SCIM endpoints and identity store live there.
How to verify: In the IAM Identity Center console you can enable the service and it reports a home Region; `aws sso-admin list-instances` returns an instance ARN. *Verify current IAM Identity Center Region/feature availability for your partition (commercial vs GovCloud differ).*
How to implement if missing: Choose a supported home Region aligned to your data-residency standard (Global Requirements G6) and enable IAM Identity Center there.

## R3. Microsoft Entra ID tenant with app + provisioning rights
Description: An Entra ID tenant and an admin who can create an enterprise application, configure SAML SSO, assign users/groups, and configure provisioning.
Why required: Entra ID is the SAML IdP and the SCIM provisioning source; building the app and turning on provisioning both require these rights.
How to verify: You can open **Entra admin center -> Enterprise applications -> New application** and, on an app, see the **Single sign-on** and **Provisioning** blades. Role is Application Administrator/Cloud Application Administrator or higher.
How to implement if missing: Have an Entra Global/Application Administrator grant the role, or perform the app-creation steps. Confirm plan-dependent features (see R7).

## R4. AWS access portal URL and SAML/SCIM exchange readiness
Description: Ability to exchange federation metadata both directions — download AWS's IAM Identity Center SAML metadata, and take the Entra SAML metadata / SCIM tenant URL + secret token back into AWS.
Why required: SAML trust and SCIM provisioning each require configuration values to be copied between the two consoles in the correct order.
How to verify: In IAM Identity Center **Settings -> Identity source** you can change the identity source to "External identity provider" and download the AWS SAML metadata; on the Entra app you can retrieve the SCIM **Tenant URL** and **Secret Token** fields.
How to implement if missing: Nothing to pre-build — this readiness is confirmed during implementation. Ensure both admins are available in the same change window so values can be exchanged without stale tokens.

## R5. A non-production ("sandbox") member account for the pilot
Description: A dedicated non-production AWS account in the organization to receive the pilot permission-set assignments.
Why required: The pilot assigns `SSO-Admin – Sandbox – Pilot` here so administrative testing never touches production, satisfying the pilot-first gate.
How to verify: The account exists in Organizations and is in a non-production OU; you can assign access to it from IAM Identity Center.
How to implement if missing: Create or designate a sandbox account (Global Requirements G8) before the pilot.

## R6. Defined access tiers and group-to-role mapping (customer decision)
Description: A documented decision on which access tiers exist and which people/groups belong in each (admin, power-user, read-only, billing, break-glass).
Why required: Permission sets and assignments encode an access policy; the technical mapping is only as safe as the entitlement decision behind it.
How to verify: A short RACI/entitlement matrix exists naming the Entra groups and the intended AWS scope for each.
How to implement if missing: The customer's security/identity owners define the tiers and membership. *This entitlement determination is the customer's decision; this solution implements the mapping, not the policy.*

## R7. Entra ID licensing for the provisioning/protection features you intend to use
Description: The Entra ID plan (Free/P1/P2) that covers the provisioning, Conditional Access, and identity-protection features you plan to apply to the AWS app.
Why required: SCIM app provisioning and Conditional Access targeting of the AWS app depend on plan level; identity-protection/PIM features require premium plans.
How to verify: In the Entra admin center check the tenant's licensing; confirm the specific feature (e.g. Conditional Access, group-based assignment) is available on your plan. *Verify current licensing — Entra plan names and feature gating change; premium features such as Conditional Access and Identity Protection typically require Entra ID P1/P2.*
How to implement if missing: Acquire the appropriate Entra plan for the features you require, or scope the design to what your current plan supports.

## R8. Inventory of existing IAM users and access keys (for decommissioning)
Description: A current inventory of standalone IAM users, their access keys, last-used dates, and what depends on them (scripts, CI, service accounts).
Why required: Legacy IAM users are only disabled/removed after SSO is proven; you must know which are human logins (replaced by SSO) versus programmatic identities (which move to roles/OIDC, not SSO).
How to verify: Run the provided `AWSSSO-Discovery.sh` (or `aws iam generate-credential-report`) to list users, keys, and last-used data.
How to implement if missing: Generate the inventory before the Expand stage; classify each user as human (retire via SSO) or workload (migrate to a role/OIDC separately, out of scope here).

---
Once R1–R8 are confirmed alongside the AWS Global Requirements, proceed to the Implementation Guide. Everything is done in the sandbox account and a small pilot group first.
