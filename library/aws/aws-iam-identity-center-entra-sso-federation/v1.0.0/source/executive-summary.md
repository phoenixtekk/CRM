# Executive Summary — AWS IAM Identity Center + Microsoft Entra SSO Federation

**AWS**

Standalone IAM users are the oldest and leakiest way to get into AWS: each is a static credential with its own password and access keys, created and deleted by hand, with no tie to your corporate identity and no automatic offboarding. When someone leaves, their AWS logins linger until a human remembers to remove them. This solution replaces that model with federated single sign-on: AWS IAM Identity Center is enabled org-wide, Microsoft Entra ID becomes the identity provider over SAML, users and groups are pushed into AWS automatically over SCIM, and Entra groups are mapped to least-privilege permission sets across every AWS account.

This is a complete, deploy-it-carefully package for federating AWS IAM Identity Center with Microsoft Entra ID, written for an administrator who knows the Microsoft side but is new to AWS Organizations and IAM Identity Center.

## What you get

- A plain-language Solution Overview of how federation works — Entra ID (SAML IdP) to IAM Identity Center (service provider), SCIM for user/group provisioning, permission sets mapped to Entra groups, and account assignments across the organization.
- A Requirements Guide with verify / implement-if-missing for every solution-specific prerequisite (the AWS category prerequisites are published once in the separate Global Requirements).
- An Implementation Guide of precise, ordered steps on both consoles — enable IAM Identity Center and delegated admin, build the Entra enterprise app (SAML + SCIM), create named permission sets, and assign access — always in a sandbox account first.
- Five automation artifacts: an AWS CLI discovery script, an Entra-side validation script (Microsoft.Graph, read-only), an AWS CLI reporting script, a Terraform configuration for permission sets and assignments (plan-first), and a gated Entra provisioning helper (`-WhatIf` by default).
- Testing and Troubleshooting guides for a confident rollout, plus break-glass and legacy-IAM-user decommissioning.

## What this delivers

One Microsoft identity signing in to every AWS account: Entra users authenticate once, land in the AWS access portal, and see only the accounts and roles their Entra group membership grants — least-privilege permission sets, auto-provisioned and auto-deprovisioned, with a tested emergency break-glass path and no standalone IAM users left to leak.

## The standard deployment model

`Assess -> Configure -> Pilot -> Validate -> Expand`, with a pilot gate that validates SSO sign-in and SCIM provisioning against a sandbox account and a small pilot group before any production account is assigned or any legacy IAM user is disabled.

> IAM Identity Center feature availability, region support, and any premium Entra ID licensing (for example Entra ID P1/P2 for certain provisioning and Conditional Access capabilities) change over time — *verify current availability and licensing in your own tenant and AWS organization before you rely on a specific capability.*

## Outcome

Corporate identities from Entra ID federated into AWS with least-privilege, automatically provisioned access across the organization — proven on a pilot, with break-glass in place, before legacy IAM users are retired.
