# Global Requirements — Copilot (category-level)

These requirements apply to every solution in the Copilot category. They are published once at the
category level so individual listings stay small. Confirm these before deploying any Microsoft 365
Copilot solution. Each entry: Description / Why / Verify / Implement-if-missing.

> Copilot inherits the tenant's existing identity, permission, and data-governance posture. It creates
> no new access — but it surfaces everything a user already has. Treat data readiness (oversharing,
> labeling) as a prerequisite, not an afterthought, and pilot before broad enablement.

## G1. Microsoft 365 tenant with supported workloads
Description: A Microsoft 365 tenant with Exchange Online, SharePoint Online, OneDrive, and Teams in use.
Why: Copilot reasons over Microsoft Graph content across these workloads; they must be provisioned and healthy.
Verify: Microsoft 365 admin center shows the services active; users have mailboxes and OneDrive provisioned.
Implement: Provision/enable the M365 workloads and confirm users are licensed for them before adding Copilot.

## G2. Microsoft 365 Copilot licensing
Description: Microsoft 365 Copilot licenses for the target users (a prerequisite base M365 plan applies).
Why: Copilot is a per-user add-on; a user cannot use Copilot without an assigned license on a qualifying base plan.
Verify: Admin center -> `Billing -> Licenses`; confirm Copilot licenses and free seats. *Verify current base-plan prerequisites in your tenant.*
Implement: Purchase/assign Microsoft 365 Copilot licenses to the pilot cohort; assign via group where possible.

## G3. Microsoft Entra ID identity and MFA
Description: Cloud identities in Entra ID with MFA and healthy sign-in.
Why: Copilot honors identity and Conditional Access; a weak or broken identity plane undermines both access and security.
Verify: Users sign in at `https://entra.microsoft.com` resources; MFA is enforced for the cohort.
Implement: Ensure licensed, MFA-protected Entra accounts (see the Entra category solutions for identity hardening).

## G4. Data readiness — permissions & oversharing controls
Description: A known state of SharePoint/OneDrive permissions and sharing (no unmanaged broad access).
Why: Copilot can surface any content the user has access to; oversharing becomes AI data exposure.
Verify: Review sharing reports / SharePoint Advanced Management signals; run the solution's discovery script. *SAM/Restricted Content Discovery availability varies — verify in your tenant.*
Implement: Remediate broad-access sites and links before broad Copilot enablement (see the oversharing-remediation solution).

## G5. Information protection baseline (sensitivity labels)
Description: A published sensitivity-label taxonomy (even minimal) in Microsoft Purview.
Why: Labels are how you keep sensitive content out of AI processing where required and audit what Copilot uses.
Verify: Purview compliance portal -> Information Protection shows published labels.
Implement: Publish a baseline label set (see the Purview information-protection solutions) before enforcing AI guardrails.

## G6. Administrative roles
Description: Global Administrator (or scoped admin roles: SharePoint Admin, Security/Compliance Admin) for the operator.
Why: Enabling Copilot, remediating SharePoint, and configuring Purview DLP/labels require these roles.
Verify: Entra -> `Roles and administrators`; confirm the required roles.
Implement: Assign least-privilege roles for the task; reserve Global Administrator for tenant-wide changes.

## G7. Network and client readiness
Description: Supported Microsoft 365 Apps clients and network access to Microsoft 365/Copilot endpoints.
Why: Copilot experiences in Word/Excel/Outlook/Teams require current clients and connectivity.
Verify: Clients on a supported channel/build; Microsoft 365 endpoints reachable. *Verify current client requirements.*
Implement: Update the M365 Apps channel/build and allow the required endpoints.

## G8. Governance & responsible-use policy
Description: An organizational position on acceptable AI use, data handling, and auditability.
Why: Copilot generates and surfaces content; the organization must define what is acceptable and keep an audit trail.
Verify: A documented AI-use/acceptable-use policy exists; Copilot interactions are auditable (Purview audit).
Implement: Adopt an AI-use policy; enable audit/eDiscovery for Copilot. *Governance and acceptable-use determinations are the customer's compliance/legal decision — this guide covers the technical controls only.*

---
The deployment model (all solutions): Assess -> Configure -> Pilot -> Validate -> Expand.
