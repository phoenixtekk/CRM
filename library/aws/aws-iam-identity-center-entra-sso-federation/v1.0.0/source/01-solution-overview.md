# 1. Solution Overview — AWS IAM Identity Center + Microsoft Entra SSO Federation

## What this solution is

AWS IAM Identity Center (formerly AWS SSO) is the AWS service that gives your workforce a single sign-on portal into every AWS account in your organization. Instead of each account holding its own IAM users and passwords, IAM Identity Center sits at the organization level and hands out short-lived, role-based access. This solution connects IAM Identity Center to Microsoft Entra ID as the external identity provider (IdP): Entra ID authenticates the user (SAML) and pushes user and group objects into AWS (SCIM), and you map each Entra group to a least-privilege permission set that applies to the AWS accounts you choose.

The result is that identity lives in one place — Entra ID. AWS trusts Entra to say who the user is, and AWS decides what that user can do based on their Entra group membership.

## How federation works

1. **Authentication (SAML).** A user opens the AWS access portal URL. IAM Identity Center redirects them to Entra ID, which authenticates them (with your existing MFA and Conditional Access), then returns a signed SAML assertion. AWS trusts the assertion and signs the user in. No AWS password exists.
2. **Provisioning (SCIM).** Entra ID's provisioning service pushes the assigned users and groups into IAM Identity Center over SCIM on a schedule. When you add a user to an Entra group, that user appears in AWS automatically; when you remove them, they are deprovisioned automatically. This is what replaces manual IAM-user lifecycle.
3. **Authorization (permission sets + assignments).** A **permission set** is a named collection of AWS permissions (managed and/or inline policies plus a session duration) that IAM Identity Center materializes as an IAM role inside each account it is assigned to. An **account assignment** links *Entra group -> permission set -> AWS account*. Group membership therefore drives exactly which accounts and roles a person sees.
4. **Access.** In the portal the user sees a tile per account/role they are entitled to, clicks it, and gets a time-boxed console session or CLI credentials — never a static key.

## The objects this solution creates (naming convention)

Every object follows `<Purpose> – <Scope> – <Stage>` so the same names appear in the steps, the scripts, the tests, and troubleshooting. The pilot set is:

- **Entra enterprise application:** `AWS IAM Identity Center – Federation – SSO` (the SAML + SCIM app).
- **Permission sets (materialize as IAM roles per account):**
  - `SSO-Admin – Sandbox – Pilot` — administrative access, **sandbox/non-production account only**, for the pilot.
  - `SSO-ReadOnly – AllAccounts – Prod` — read-only across assigned accounts.
  - `SSO-PowerUser – Workloads – Prod` — power-user (no IAM/billing) on workload accounts.
  - `SSO-Billing – Management – Prod` — billing/cost access scoped to the management account.
  - `SSO-BreakGlass – Management – Emergency` — emergency administrative access, assigned to a tiny, monitored group (see break-glass).
- **Entra security groups (mapped 1:1 to the permission sets):** `AWS-SSO-Admin-Sandbox-Pilot`, `AWS-SSO-ReadOnly-AllAccounts`, `AWS-SSO-PowerUser-Workloads`, `AWS-SSO-Billing-Management`, `AWS-SSO-BreakGlass-Emergency`.
- **Delegated administration:** a designated member account (referred to as the **Identity account**) registered as the IAM Identity Center delegated administrator so day-to-day SSO administration does not require the management account.

## The standard deployment model

> Assess the current IAM-user footprint and org readiness, configure IAM Identity Center + the Entra app + permission sets, pilot SSO and SCIM against the sandbox account with one pilot group, validate sign-in/provisioning/least-privilege at explicit gates, then expand to production accounts and decommission legacy IAM users. Standard pattern: `Assess -> Configure -> Pilot -> Validate -> Expand`.

- **Assess** — inventory IAM users, access keys, and existing roles; confirm Organizations, Entra rights, and licensing.
- **Configure** — enable IAM Identity Center, register delegated admin, build the Entra enterprise app (SAML + SCIM), create the named permission sets.
- **Pilot** — assign only `SSO-Admin – Sandbox – Pilot` and `SSO-ReadOnly – AllAccounts – Prod` to the pilot group against the sandbox account; prove sign-in and provisioning end to end.
- **Validate** — run the pass/fail gates in the Testing Guide (SAML sign-in, SCIM sync, least-privilege boundary, break-glass).
- **Expand** — assign production accounts group by group, then disable and remove legacy IAM users on a schedule with rollback.

## Scope

- Enabling AWS IAM Identity Center at the organization level and registering a delegated administrator.
- Configuring Microsoft Entra ID as the SAML IdP and enabling SCIM user/group provisioning into IAM Identity Center.
- Creating least-privilege permission sets and mapping Entra groups to them across selected AWS accounts.
- Session controls (session duration, sign-in experience) and a tested break-glass path.
- A staged decommissioning plan for legacy standalone IAM users and their access keys.

## What is out of scope

- Designing the AWS Organizations structure, OUs, and SCPs themselves (that is the AWS landing-zone solution — see *Where to go next*).
- Full Entra ID governance (PIM, access reviews, entitlement management) — this solution consumes Entra groups; it does not build the governance program around them.
- Application-level SSO to non-AWS SaaS, and customer-managed permission policies beyond the permission sets defined here.
- The customer's decision on *which* people belong in *which* access tier — that access-governance determination belongs to the customer's security and identity owners; this guide provides the technical mapping, not the entitlement policy.

## Authentication and connections used

- **AWS side:** an assumed, least-privilege role or IAM Identity Center permission set in the management/Identity account with rights to Organizations and `sso-admin` / `identitystore` APIs — never root, never long-lived admin keys (see Global Requirements G1/G2).
- **Entra side:** an admin with rights to create and configure an enterprise application, assign users/groups, and configure provisioning (Application Administrator or higher). The provided PowerShell uses **Microsoft.Graph** with delegated, read-only scopes for validation and an explicitly gated scope for the optional provisioning helper.
- **Terraform:** the AWS provider using the assumed role above, run **plan-first** through source control against a non-production account before production (Global Requirements G3–G5, G8).

> Some capabilities referenced here (certain SCIM group-provisioning behaviors, Conditional Access, and identity-protection features) depend on your Entra ID plan and on current AWS region/feature support. *Verify current availability and licensing in your tenant and organization before relying on a specific capability.*
