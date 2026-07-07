# Executive Summary

## The outcome

Make **Google Cloud Identity / Workspace the single sign-on identity provider for the entire SaaS
estate** — hundreds of third-party applications — through a **repeatable app-integration factory**
rather than hundreds of one-off projects. New apps federate to Google SSO **fast, consistently, and
auditably**, with access and account lifecycle driven from one directory lever.

## The problem

In a Google-first enterprise, Google becomes the natural IdP for every SaaS app employees use. But
onboarding each SAML/OIDC app individually — hand-crafting metadata, deciding provisioning, granting
access per user — is slow, inconsistent, and hard to audit. The result is uneven security posture,
orphaned SaaS accounts at offboarding, and no single view of who can reach what.

## The approach

A standard **onboarding pattern** (`SSO Onboarding Pattern – SaaS – v1`) applied to every app, four
building blocks deep:

- **One repeatable pattern** for SAML and OIDC alike — the same checklist every time.
- **Group-based assignment** — apps are turned on for governed directory groups, never per user, so
  joiner-mover-leaver automatically grants and revokes SaaS access.
- **Automatic provisioning** (Google auto-provisioning / SCIM) where the app supports it, scoped to the
  same group, so accounts in the app follow directory reality.
- **An app catalog** (`App Catalog – Federated SaaS – v1`) that records every integration's config,
  owner, provisioning method, and certificate expiry — the audit surface for access reviews.

## Why it is safe and governed

The build follows a strict **Assess → Design → Configure → Pilot → Validate → Expand** model:
**pilot-first**, with explicit pass/fail gates and a documented per-app rollback. No app is turned on
for its full audience until it passes validation against a pilot cohort — SSO works, provisioning
creates *and* deactivates correctly, and access is provably group-driven. Five Python tools (Admin SDK
/ `gcloud`) automate discovery, validation, and guardrail checks; all are **read-only or dry-run by
default**, with **no credentials or keys in code**. Regulatory and legal determinations remain with the
organization's security and compliance functions; this solution supplies the technical method and the
evidence.

## The bottom line

Google as the single sign-on IdP for the whole SaaS estate — apps onboarded by a repeatable factory,
provisioned and assigned by group — **fast, consistent, and auditable**, at a fraction of the cost of
bespoke consulting.
