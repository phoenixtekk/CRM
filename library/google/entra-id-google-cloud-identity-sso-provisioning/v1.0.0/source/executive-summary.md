# Executive Summary — Entra ID ↔ Google Cloud Identity: SSO Federation & Provisioning

White-label · Google Category

In a Google transformation, **identity is the backbone.** Before mail, files, or apps can move or
coexist, users have to sign in **once** and exist **consistently** across both clouds — the same
person, the same account, the same groups — with **Microsoft Entra ID** as the enterprise identity
provider and **Google Workspace / Cloud Identity** as the relying party. Left unmanaged, identity
splits: two logins, accounts present in one directory but not the other, groups that drift, and
licensing that no longer matches who is active. Everything downstream inherits that confusion.

This package stands up the identity foundation deliberately and in the right order: **federate Entra
ID to Google for single sign-on** (SAML 2.0, via the "Google Cloud / G Suite Connector by Microsoft"
gallery app), then **provision users and groups into Google** from a single source of truth — **SCIM
push** when Entra masters identity, or **Google Cloud Directory Sync (GCDS)** when on-prem Active
Directory does. Accounts, group membership, and licensing stay consistent across Microsoft and Google,
and the lifecycle **closes** — leavers are de-provisioned, not orphaned. It is deployed **pilot-first**
and **rollback-ready**.

## What you get
- A plain-language Solution Overview of the identity model — Entra as IdP federating to Google, the
  three provisioning options (SCIM push, GCDS pull, JIT-convenience), and the cardinal rule of **one
  source of truth per object**.
- A Requirements Guide with verify / implement-if-missing for every prerequisite — both control planes,
  the source-of-truth decision, the custom domain verified in **both** clouds, the SCIM admin account
  or GCDS host, a named pilot, and break-glass on both sides.
- An Implementation Guide with the exact click-by-click steps to configure **Entra→Google SAML SSO**
  (both consoles, NameID = user.mail, domain-specific issuer), **provisioning** of users and groups
  (SCIM Path A or GCDS Path B, including de-provisioning), and to **pilot** sign-in and provisioning on
  a named OU/group before expanding.
- Five PowerShell scripts for identity-readiness discovery, per-user SSO + provisioning validation, an
  identity coverage/exception report, safe remediation, and a pilot-scope builder.
- A Testing Guide of conformance gates (sign-in works, users/groups provisioned, one source of truth,
  de-provisioning removes access, break-glass intact) and a Troubleshooting Guide for a confident,
  staged rollout.

## What this delivers
A stable identity foundation: users authenticate once against Entra ID and reach Google without a
second password; users, groups, and licensing stay consistent because one directory is authoritative
and provisions the other; and access is removed when a person leaves. SSO is correctly scoped to
authentication only, provisioning to a single source of truth, and the whole thing is proven on a
pilot before it touches production — with the Google-side console steps authored from Google's own docs
and GCDS internals deferred to Google where appropriate.

## The standard deployment model
Assess → Configure → Pilot → Validate → Expand.

## Outcome
One identity across Microsoft and Google — single sign-on and consistent provisioning — underpinning
coexistence, migration, and secure access through the transformation and beyond, proven on a named
pilot and reversible at every step.
