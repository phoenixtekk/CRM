# 1. Solution Overview — Hybrid Identity with Active Directory & Microsoft Entra Connect

## What hybrid identity is
Most organizations keep user accounts in on-premises Active Directory (AD) while their apps,
devices, and security live in Microsoft Entra ID (the cloud directory). Hybrid identity is the
bridge between the two: a synchronization engine copies AD users, groups, and contacts into Entra
ID, and an authentication method decides where the password is actually checked. Done well, a user
has one identity and one password that works on-premises and in the cloud. Done badly, you get
duplicate accounts, broken sign-ins, and devices that will not join.

## How it works
1. Microsoft Entra Connect runs on a host server and synchronizes objects from AD to Entra ID on a
   schedule (every 30 minutes by default).
2. A synchronization scope (domain and organizational-unit filters) decides which AD objects are in
   scope, so test or service objects stay out of the cloud.
3. An authentication method decides how sign-in is validated: password hash sync (PHS),
   pass-through authentication (PTA), or federation.
4. Seamless single sign-on (Seamless SSO) lets domain-joined users on the corporate network sign in
   to cloud apps without re-typing a password.
5. Hybrid Entra join registers domain-joined Windows devices into Entra ID so they satisfy
   Conditional Access and cloud device management.
6. Synchronization health and sign-in are monitored so a stalled sync or an auth-method fault is
   caught before users feel it.

## Connect Sync vs. Cloud Sync (which engine)
- Entra Connect Sync is the full-featured engine: complex filtering, device writeback, password
  writeback, and large or multi-forest environments. It runs on a dedicated server.
- Entra Cloud Sync uses a lightweight agent and the cloud does the heavy lifting; it suits simpler
  or disconnected-forest scenarios and multiple small domains, with fewer advanced options.
- This solution implements Connect Sync as the primary path because it covers hybrid join and
  writeback; Cloud Sync is noted where it is the better fit.

## Authentication methods (choose one primary)
- Password hash sync (PHS) synchronizes a (hashed, salted) representation of the password so Entra
  ID validates sign-in itself. Simplest and most resilient — the cloud keeps working if the
  on-premises servers are down. Recommended default.
- Pass-through authentication (PTA) validates the password against AD in real time via lightweight
  agents, so no password representation leaves the network. Requires the agents (and AD) to be
  available for cloud sign-in.
- Federation (AD FS) hands authentication to an on-premises federation farm. Most complex and
  highest-maintenance; choose it only for a specific requirement (for example a third-party MFA at
  the federation layer or strict on-premises sign-in control).
- PHS is recommended as a backup even when PTA or federation is primary, so cloud sign-in survives
  an on-premises outage.

## What you can control
- Which AD objects synchronize (sync scope, OU and domain filters).
- The authentication method (PHS, PTA, or federation) and whether Seamless SSO is on.
- Password writeback (self-service password reset writing back to AD) and other writeback options.
- Hybrid Entra join for domain-joined Windows devices.
- The synchronization schedule and staging-mode (a parallel, no-export rehearsal server).

## Benefits
- One identity — the same account and password on-premises and in the cloud.
- Reliable sign-in — the right authentication method with PHS resilience as a safety net.
- Devices that just work — hybrid Entra join satisfies Conditional Access and cloud management.
- Clean directory — scoped sync and UPN hygiene prevent duplicate and orphaned accounts.
- Visibility — sync health and object coverage are monitored and reportable.

## Limitations (be honest with buyers)
- Synchronization is one-way for most attributes (AD to Entra ID); AD stays the source of truth.
- A misconfigured sync scope or duplicate UPN/proxyAddress causes sync errors and merged or split
  accounts; UPN/domain hygiene is a prerequisite, not an afterthought.
- Federation is a significant ongoing commitment (certificates, the AD FS farm, its own outage
  surface); prefer PHS or PTA unless a requirement forces federation.
- One active sync server exports at a time; a second server runs in staging mode for failover.

## Why this matters (the why lives here)
The identity plane underpins every other security and management control — Conditional Access, MFA,
device compliance, and app access all read from it. That is exactly why this solution treats it as
high risk: changes are rehearsed in staging mode, rolled out to a pilot group first, validated, and
only then expanded, with break-glass accounts ready throughout. The remaining guides are
click-to-implement and avoid re-explaining the why.

## The standard deployment model
> Prepare AD and domains -> install and configure Entra Connect -> choose and enable the
> authentication method -> scope synchronization -> enable hybrid Entra join -> validate sign-in and
> sync health, on a pilot first. The repeatable way: Assess -> Configure -> Pilot -> Validate -> Expand.
