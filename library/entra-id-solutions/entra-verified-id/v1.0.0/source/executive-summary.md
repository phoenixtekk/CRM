# Executive Summary — Entra Verified ID — Verifiable Credentials

White-label · Entra ID Solutions

Manual identity and attribute verification — proving who a new hire is, that someone is still employed,
or that a person is entitled to a sensitive resource — is slow, inconsistent, and phishable. It leaves
paper trails and one-off email confirmations instead of proof. Microsoft Entra Verified ID replaces
that with **verifiable credentials**: your organization issues tamper-evident digital credentials to a
person's wallet, and any relying party can cryptographically verify them — without calling you, and
without the person over-sharing. The credential is issued once, held by the person, verified on demand,
and revocable when it should no longer be trusted.

This solution is a full **implementation** product, not a talk-through. It is written for an
administrator with no prior verifiable-credentials experience — exact, ordered, click-by-click steps in
the Microsoft Entra admin center and the Verified ID service — and it stands up the whole capability
end to end: the Verified ID service and its trust system, a credential type with its rules and display,
a working **issuance flow** (issue an employee/verification credential to the Microsoft Authenticator
wallet), a working **verification flow** (a relying party checks the credential), and the governance
around it (revocation, lifecycle, and privacy).

## What you get
- A plain-language Solution Overview of Verified ID: the trust system, the decentralized identifier (DID) and domain verification, credential types, rules and display definitions, the issuance and verification flows, and the Request Service API — with the feature/preview and licensing items flagged *verify*.
- A Requirements Guide with Verify / Implement-if-missing for every solution-specific prerequisite (the category-wide ones live in the separate global-requirements file), including the Azure Key Vault, domain, and app-registration prerequisites Verified ID needs.
- An Implementation Guide of precise, ordered steps: onboard the Verified ID service, verify your domain, design a credential type (rules + display), register an app for the Request Service API, issue a pilot credential to a wallet, verify it from a relying party, and revoke it — piloted before rollout.
- Five PowerShell scripts (Microsoft Graph + Verified ID Request Service API) for service/authority discovery, trust-and-domain validation, an issued/revoked credential report, a safe issuance-request builder (builds the request and only submits when told), and a safe presentation (verification) request builder.
- Testing and Troubleshooting guides, plus Best Practices and a Deliverables Summary, for a confident rollout.

## What this delivers
A working Verified ID capability: an onboarded issuer with a verified domain and a published credential
type; the ability to issue a credential (for example a Verified Employee credential) to a person's
wallet through a QR-code/deep-link flow; the ability for a relying party to request and cryptographically
verify that credential; and the governance to revoke a credential and manage its lifecycle — all proven
on a pilot before you scale. Privacy is by design: the holder consents to each presentation and shares
only the claims requested.

## Scope boundary
This solution stands up Verified ID and one issuance and one verification flow end to end. It does
**not** re-implement Conditional Access, entitlement management, or hybrid identity — those are separate
catalog areas it can plug into (for example, using a Verified ID presentation as a signal — *verify
current availability*). Decisions about which credentials are authoritative, what claims are lawful to
collect, and acceptable use belong to your compliance, legal, and security functions; this guide
provides the technical controls, not the decisions.

## The standard deployment model
Assess -> Configure -> Pilot -> Validate -> Expand.

## Outcome
Issue and verify tamper-evident digital credentials for onboarding, proof of employment, and access —
privacy-respecting by design, revocable, and standards-based — configured correctly and proven on a
pilot before you scale.
