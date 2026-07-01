# Executive Summary — Netskope + Entra ID SSO & Identity-Based Policy Enforcement

**Network Solutions · SASE/SSE**

Network-security policy that is not tied to identity is blunt. You cannot write a rule that says
"this group may use this app and that group may not," admins juggle a separate login for the
security console, and users are provisioned and de-provisioned by hand — so access drifts out of
sync with who actually works here. This solution integrates Netskope with Microsoft Entra ID as the
identity provider: SAML single sign-on for the admin console and for users, SCIM user and group
provisioning into Netskope, and policy that steers and enforces by identity and group — so the right
controls follow the right people everywhere.

This is a complete, repeatable package for connecting Netskope to Entra ID for SSO and
identity-based policy, written for an administrator with no prior Netskope/IdP-integration
experience. Netskope console specifics are deferred to the official Netskope documentation; the
Entra ID side is documented click-by-click.

## What you get
- A plain-language Solution Overview of the IdP integration model — SAML SSO, SCIM provisioning,
  identity-based steering and policy — and how it complements (not duplicates) Entra Conditional Access.
- A Requirements Guide with verify / implement-if-missing for every prerequisite.
- An Implementation Guide of precise, ordered steps: configure SAML SSO, enable SCIM provisioning,
  map groups, build identity-based policy, then pilot, validate, and expand.
- Five PowerShell scripts for SSO/SCIM-readiness discovery, sign-in and provisioning validation, an
  identity-policy coverage report, safe remediation of provisioning gaps, and an identity-scope group builder.
- Testing and Troubleshooting guides for a confident rollout.

## What this delivers
A single identity backbone for Netskope: one sign-in for admins and users via SAML, users and groups
kept in sync by SCIM, and policies that target by Entra group — proven on a pilot group before the
fleet, with a documented rollback path.

## The deployment model
**Assess → Configure → Pilot → Validate → Expand.**

## Outcome
Netskope policy that follows the user — Entra ID single sign-on, SCIM-provisioned users and groups,
and identity-based steering and enforcement — so the right controls reach the right people
everywhere, validated on a pilot before you scale.
