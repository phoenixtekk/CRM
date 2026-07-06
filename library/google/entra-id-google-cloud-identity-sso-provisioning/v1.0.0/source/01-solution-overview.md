# 1. Solution Overview — Entra ID ↔ Google Cloud Identity: SSO Federation & Provisioning

## Why identity is the foundation of a Google transformation
When an organization adopts Google Workspace / Cloud Identity while Microsoft Entra ID remains the
enterprise identity provider, the first thing that has to work is **identity**. Users must sign in
**once** and exist **consistently** across both clouds — the same person, the same account, the same
groups — or every downstream workload (mail, Drive, Meet, third-party apps) inherits the confusion.
The failure mode is a **split identity**: two logins, accounts that exist in one directory but not the
other, groups that drift, and licensing that no longer matches who is actually active.

This solution stands up the identity foundation deliberately and in the right order:
**federate Entra ID to Google for single sign-on**, then **provision users and groups into Google**
from a single source of truth — so accounts, group membership, and licensing stay consistent across
Microsoft and Google. It is the base layer that coexistence and migration are built on, deployed
**pilot-first** and **rollback-ready**.

> **Vendor boundary.** The **Microsoft / Entra** side (the "Google Cloud / G Suite Connector by
> Microsoft" gallery application) and the **Google Admin console / Cloud Identity** side are authored
> at exact click-by-click detail from the vendors' current public documentation. **Google Cloud
> Directory Sync (GCDS)** is Google's supported tool for AD/LDAP-sourced provisioning; its internal
> configuration is deferred to Google's own docs where noted. Any capability that is preview or
> rolling out is flagged "verify in your tenant" — never invented.

## The identity model
Two decisions define the whole design. Make them explicitly, up front.

**1. Who authenticates the user (SSO / federation).**
Entra ID acts as the **identity provider (IdP)**; Google Workspace / Cloud Identity is the
**relying party (SP)**. Sign-in is federated over **SAML 2.0** using the Entra gallery app
**"Google Cloud / G Suite Connector by Microsoft."** The user authenticates against Entra ID once;
Google trusts the SAML assertion. This is **authentication only** — it does not create the Google
account and it does not decide Google authorization (OU/group/admin role); those are Google-side.

**2. Where the account comes from (provisioning) — one source of truth.**
An account has to **exist** in Google before (or as) SSO federates a user into it. Choose exactly one
authoritative source per object and one mechanism to move it into Google:

- **SCIM push (Entra → Google)** — Entra ID is the source of truth. The same gallery app's
  **Provisioning** capability creates, updates, and de-provisions Google users and groups over SCIM.
  Choose this when **Entra ID / Microsoft 365** masters identity.
- **GCDS pull (AD/LDAP → Google)** — **Google Cloud Directory Sync** runs on a host with LDAP access
  to on-prem Active Directory and syncs users/groups into Google on a schedule. Choose this when
  **on-prem Active Directory** remains authoritative.
- **JIT (just-in-time)** — SAML JIT can create a Google user on first SSO. Treat JIT as a
  **convenience, not the source of truth** — for lifecycle, and especially **de-provisioning of
  leavers**, use SCIM push or GCDS so removals actually flow through.

The cardinal rule: **one source of truth per object.** Never let SCIM push (Entra) and GCDS pull
(AD) master the same users — they fight and the directories drift.

## How the pieces fit together
```
                 authentication (SAML 2.0)
   Entra ID  ───────────────────────────────────►  Google Workspace /
  (IdP, SSO)        gallery app: "Google Cloud /       Cloud Identity
      │             G Suite Connector by Microsoft"       (relying party)
      │
      │  provisioning — choose ONE source of truth per object
      │
      ├─ SCIM push  (Entra is source of truth) ──────►  users + groups in Google
      │
   AD/LDAP ── GCDS pull (AD is source of truth) ─────►  users + groups in Google
```
SSO federates the **sign-in**; provisioning keeps the **accounts and groups** consistent. Both are
required — SSO with no provisioning strands users at a login page with no account; provisioning with
no SSO leaves two separate passwords.

## What you can control
- **Federation** — Entra ID as IdP, Google as relying party, over SAML 2.0, with a NameID that matches
  the verified Google domain.
- **Provisioning** — one source of truth (Entra via SCIM, or AD via GCDS), moving users and groups
  into Google, with de-provisioning that removes leavers.
- **Consistency** — the same people, groups, and licensing state across Microsoft and Google.
- **Coverage** — per-user visibility into who is federated, who is provisioned, and where the
  exceptions are.

## Benefits
- **Sign in once** — users authenticate against Entra ID and reach Google without a second password.
- **Consistent accounts and groups** — one source of truth provisions Google; membership and licensing
  stay aligned instead of drifting.
- **Lifecycle that closes** — de-provisioning through SCIM/GCDS removes access when a person leaves,
  instead of orphaning accounts.
- **A foundation to build on** — coexistence and migration inherit stable identity instead of fixing
  it under pressure later.
- **Pilot-first and reversible** — federation and provisioning are proven on a named pilot OU/group
  before org-wide enforcement, with a documented rollback.

## Limitations (be honest with buyers)
- SSO is **authentication only.** It does not create Google accounts (provisioning does) and does not
  grant Google admin — Google decides authorization by OU/group/admin role.
- **One source of truth is mandatory.** SCIM push and GCDS pull must not master the same objects.
  JIT is not a lifecycle mechanism — leavers must be de-provisioned by SCIM or GCDS.
- The NameID / unique identifier in the SAML assertion **must match the verified Google domain and the
  Google account's email**, or users cannot sign in.
- The scripts inventory and validate the **Microsoft / Entra side** through Microsoft Graph
  (read-only). **Google-side** state — the SSO profile, provisioned users/groups, GCDS runs — is
  confirmed in the Google Admin console and GCDS.
- Some Entra provisioning, conditional-access, and PIM-for-groups capabilities require **Entra ID
  P1/P2** licensing (see Requirements).

## The standard deployment model
> Assess the identity estate and pick the source of truth → configure Entra→Google SSO federation and
> provisioning → pilot both on a named OU/group → validate sign-in and provisioning end-to-end →
> expand across the organization, tracking exceptions. Repeatable pattern:
> **Assess → Configure → Pilot → Validate → Expand**, with explicit pass/fail gates and a documented
> rollback for every production change.
