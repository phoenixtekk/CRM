# Executive Summary — Enterprise App & Service Principal Governance (Government / GCC High)

White-label · Entra ID Solutions · US Sovereign Cloud (GCC High)

Every SaaS integration and internal app you connect leaves behind three things in your tenant: an
enterprise application, a service principal, and a set of API permissions. Over time they pile up —
apps nobody owns, dangerous consented permissions, and app secrets or certificates quietly expiring
or lingering forever. Attackers love them: an over-permissioned or consent-phished app is a quiet,
persistent foothold that survives password resets and MFA. On a GCC High tenant handling CUI or ITAR
data, that foothold is a controlled-data exposure.

This is the **Government (GCC High)** edition of a complete, deploy-it-today package for governing
enterprise apps and service principals in Microsoft Entra, written for an administrator with no prior
app-governance experience. It is authored for the **US sovereign cloud** — every portal path is the
`*.us` variant (`entra.microsoft.us`, `portal.azure.us`, `portal.office365.us`), sign-in is
`login.microsoftonline.us`, and every script connects to US Gov Microsoft Graph
(`graph.microsoft.us`, `Connect-MgGraph -Environment USGov`). The Commercial-vs-GCC-High differences
are called out where they matter, so you configure a government tenant correctly instead of running
Commercial steps that silently fail.

## What you get
- A plain-language Solution Overview of the Entra app model — app registrations vs. enterprise
  apps and service principals, delegated vs. application permissions, admin and user consent, the
  over-permission and consent-phishing risk, and the secret/certificate lifecycle — with an explicit
  **Commercial vs GCC High — what's different** section.
- A cited **GCC High parity reference** so you never build a step on a feature that is not in the
  sovereign cloud.
- A Requirements Guide with verify / implement-if-missing for every prerequisite, in US Gov terms.
- An Implementation Guide of precise, click-by-click steps using the GCC High portals, with the
  sovereign-cloud caveats inline at the step where they matter.
- Five PowerShell scripts for app and service-principal discovery, risky-consent and expiring-secret
  validation, an over-permission and expiring-secret report, safe remediation of risky grants, and a
  governance-scope group builder — all connecting to `graph.microsoft.us` via `-Environment USGov`.
- Testing and Troubleshooting guides for a confident, staged rollout, with GCC-High-specific gotchas.

## What this delivers
A governed application estate on a sovereign tenant — every enterprise app and service principal
inventoried, API permissions and consents reviewed for over-privilege, a user-consent policy that
stops consent-phishing, an admin-consent workflow so users can request access safely, risky grants
remediated, and app secrets and certificates on a managed lifecycle — proven on a pilot scope before
you touch the whole tenant.

## The standard deployment model
Assess -> Configure -> Pilot -> Validate -> Expand.

## Outcome
Every enterprise app and service principal inventoried and governed on GCC High — right portals,
right endpoints, parity gaps handled — over-permissioned grants and risky consents remediated, user
consent controlled, and app secrets and certs on a managed lifecycle — closing a favorite attacker
foothold, validated on a pilot before you scale.
