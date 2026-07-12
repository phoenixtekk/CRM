# Executive Summary — Entra External Identities (B2B) & Cross-Tenant Access

White-label · Entra ID Solutions

Ungoverned guest sprawl and wide-open external collaboration are a data-exfiltration surface: guests
who never expire, no Conditional Access scoped to external users, and no record of who invited whom or
why. Microsoft Entra External Identities fixes this at the control plane. Cross-tenant access settings
decide which partner tenants you trust and how (B2B collaboration, B2B direct connect, and inbound MFA
trust); guest invitation and self-service sign-up controls decide who can bring guests in; entitlement
management packages external access with a policy and an expiry; Conditional Access scoped to guests
enforces MFA and device or session controls on external users; and access reviews recertify guests on
a schedule so stale external access decays on its own.

This solution stands the capability up the right way. It is written for an administrator with no prior
external-identity experience — exact, ordered, click-by-click steps in the Microsoft Entra admin
center, every object you create named with a consistent convention and reused through testing and
troubleshooting, and a pilot-first method so you prove the model on one partner and a small guest scope
before you expand tenant-wide.

## What you get
- A plain-language Solution Overview of External Identities, cross-tenant access settings (default vs organizational, inbound/outbound, trust settings), guest invitation and self-service sign-up, entitlement-managed guest access, Conditional Access for guests, cross-tenant synchronization, and the guest lifecycle (reviews, expiry, cleanup).
- A Requirements Guide with Verify / Implement-if-missing for every solution-specific prerequisite (the category-wide ones live in the separate global-requirements file), including the licensing and preview items flagged *verify*.
- An Implementation Guide of precise, ordered steps in the Entra admin center — cross-tenant settings for one partner, guest controls, a scoped Conditional Access policy in report-only first, an entitlement-management access package for external users, and a guest access review — piloted before expansion.
- Five PowerShell scripts (Microsoft Graph) for external-identity discovery, configuration validation, a guest-lifecycle report, safe cross-tenant-access configuration for a named partner (default `-WhatIf`), and safe stale-guest cleanup (default `-WhatIf`).
- Testing and Troubleshooting guides, plus Best Practices and a Deliverables Summary, for a confident rollout.

## What this delivers
Governed external collaboration: partner tenants are trusted deliberately through cross-tenant access
settings rather than by default; guests enter through invitation or self-service policy, receive access
through entitlement-management packages with an owner and an expiry date, are subject to a Conditional
Access policy that requires MFA, and are recertified by an access review that removes anyone no longer
needed. Break-glass emergency accounts are excluded from the guest-scoped policies so a
misconfiguration can never lock every administrator out.

## Scope boundary
This solution configures the External Identities and cross-tenant plane. It deliberately does **not**
re-implement the entitlement-management engine, the Conditional Access baseline, or hybrid identity —
those are separate catalog areas it plugs into (see the cross-references in the Overview and Best
Practices). Regulatory, data-classification, and partner-approval decisions belong to your
compliance, security, and business owners; this guide provides the technical controls, not the
decisions.

## The standard deployment model
Assess -> Configure -> Pilot -> Validate -> Expand.

## Outcome
External access that is deliberate, scoped, and time-bound — partners onboarded through trusted
cross-tenant settings, guests granted through packaged access with MFA and expiry, and stale guests
removed on review — proven on a pilot before you scale.
