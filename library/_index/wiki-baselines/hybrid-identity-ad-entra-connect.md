# Hybrid Identity with Active Directory & Microsoft Entra Connect

> **Version 1.0.0** · Category: Entra · Solution code: HYBID

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary — Hybrid Identity with Active Directory & Microsoft Entra Connect

White-label · Entra ID Solutions

Most organizations still run Active Directory on-premises while their apps, devices, and security
live in the cloud. When the bridge between them is misconfigured you get duplicate accounts, broken
sign-ins, and devices that will not join. This solution establishes solid hybrid identity with
Active Directory and Microsoft Entra Connect: reliable synchronization, the right authentication
method, hybrid Entra join, and the health monitoring to keep it that way.

This is a complete, deploy-it-today package for implementing hybrid identity, written for an
administrator with no prior identity-integration experience — and it treats the identity plane as
the high-risk surface it is.

## What you get
- A plain-language Solution Overview of synchronization, Connect Sync vs. Cloud Sync, the three
  authentication methods (password hash sync, pass-through authentication, federation), Seamless SSO,
  and hybrid Entra join.
- A Requirements Guide with verify / implement-if-missing for every prerequisite.
- An Implementation Guide of precise, click-to-implement steps in the required order.
- Five PowerShell scripts for readiness discovery, sync and sign-in validation, sync-health and
  object-coverage reporting, safe remediation of sync errors and duplicates, and a sync-scope helper.
- Testing and Troubleshooting guides for a confident, staged rollout.

## What this delivers
A clean, reliable hybrid identity: Microsoft Entra Connect synchronizing a scoped set of AD objects,
the right authentication method (password hash sync recommended, with PTA or federation where
required and PHS as a backup), Seamless SSO for corporate-network users, hybrid Entra join for
domain-joined Windows devices, and ongoing synchronization-health monitoring.

## The deployment model
Assess -> Configure -> Pilot -> Validate -> Expand — rehearsed in staging mode, with break-glass
accounts ready throughout.

## Outcome
One reliable identity spanning Active Directory and Entra ID — synchronized cleanly, authenticated by
the right method, with hybrid join and healthy sync — deployable by a single administrator and
validated on a pilot before fleet rollout.


---


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


---


# 2. Requirements Guide — Hybrid Identity with Active Directory & Microsoft Entra Connect

Verify every requirement before configuring. Each entry: Description / Why / Verify /
Implement-if-missing. Category-wide prerequisites are in `global-requirements-entra-id-solutions.md`.

## 2.1 Entra ID licensing
Description: Microsoft Entra ID P1 (P2 if you also want risk-based sign-in or PIM).
Why: Hybrid features (Seamless SSO, password writeback, Conditional Access for hybrid join) need P1+.
Verify: M365 admin center -> `Billing -> Licenses`.
Implement: Assign M365 E3/E5, EMS, or standalone Entra ID P1/P2.

## 2.2 Entra Connect host server
Description: A dedicated, patched, domain-joined Windows Server 2016 or later for Connect Sync.
Why: The sync engine runs as a service here and must reach AD and Entra ID over HTTPS.
Verify: Server is domain-joined, patched, TLS 1.2 enabled; run `HYBID-Discovery.ps1`.
Implement: Provision a server (not a production domain controller), patch it, enable TLS 1.2, and install the ActiveDirectory PowerShell module.

## 2.3 Healthy Active Directory
Description: AD replication, DNS, and time sync are healthy across domain controllers.
Why: Sync reads from AD; replication or DNS faults stall or corrupt synchronization.
Verify: `dcdiag` and `repadmin /replsummary` clean on a DC; run `HYBID-Discovery.ps1`.
Implement: Resolve replication, DNS, and time-sync errors before synchronizing.

## 2.4 UPN and domain hygiene
Description: User UPNs use a public, verified, routable domain (no `.local`); no duplicate UPNs or proxyAddresses.
Why: Non-routable or duplicate UPNs/proxyAddresses cause sign-in failures and sync errors (merged/split accounts).
Verify: Entra -> `Identity -> Settings -> Domain names` shows the public domain Verified; run `HYBID-Discovery.ps1` (flags `.local` UPNs and duplicates).
Implement: Add and verify the public domain in Entra; add the matching UPN suffix in AD; update user UPNs; resolve duplicates with `HYBID-Remediation.ps1`.

## 2.5 Authentication method decision
Description: A decision on the primary authentication method — PHS, PTA, or federation.
Why: It is the single most consequential design choice and drives the install options.
Verify: A documented decision (default PHS) and whether Seamless SSO and password writeback are wanted.
Implement: Default to password hash sync with Seamless SSO; choose PTA or federation only for a stated requirement, and keep PHS enabled as a backup.

## 2.6 Administrative roles
Description: Hybrid Identity Administrator for ongoing work; Global Administrator for the first-sync consent.
Why: Configuring directory sync and authentication needs these roles.
Verify: Entra -> `Roles and administrators`.
Implement: Assign `Hybrid Identity Administrator`; use a `Global Administrator` only for the one-time first-sync grant.

## 2.7 Break-glass accounts
Description: Two cloud-only emergency access accounts excluded from broad policies.
Why: An identity change can lock out admins; break-glass accounts restore access.
Verify: Entra -> `Users`; two cloud-only `@onmicrosoft.com` admins exist.
Implement: Create them, exclude from Conditional Access/MFA-broad policies, store credentials securely, and monitor their sign-ins.

## 2.8 Pilot scope group
Description: An AD organizational unit (or group) of representative pilot users/devices.
Why: Every change is validated on a pilot before the fleet.
Verify: An OU such as `Hybrid Pilot Sync Scope - Pilot - Pilot` exists with representative members.
Implement: Create the pilot OU and place pilot users/devices in it; see Implementation Step 1.

## 2.9 Network access
Description: Outbound HTTPS (443) from the Connect host to Entra ID and Microsoft 365 endpoints.
Why: Sync, authentication agents, and tokens depend on these endpoints.
Verify: From the host, reach `https://login.microsoftonline.com`; Microsoft 365 URL/IP ranges allowed.
Implement: Allow the Microsoft 365 / Entra published URL and IP ranges through proxy/firewall.

---
## Checklist
- [ ] Entra ID P1/P2 licensing assigned
- [ ] Entra Connect host server ready (domain-joined, patched, TLS 1.2) — `HYBID-Discovery.ps1`
- [ ] Active Directory healthy (`dcdiag`, `repadmin`)
- [ ] UPN/domain hygiene fixed (public verified domain, no duplicates) — `HYBID-Discovery.ps1`
- [ ] Authentication method decided (default PHS) and Seamless SSO/writeback choices made
- [ ] Hybrid Identity Administrator role assigned; Global Admin available for first sync
- [ ] Two break-glass accounts created and excluded from broad policies
- [ ] Pilot sync scope OU/group created
- [ ] Network allows Entra/Microsoft 365 endpoints from the host


---


# Global Requirements — Entra ID Solutions (category-level)

These requirements apply to every solution in the Entra ID Solutions category. They are
published once at the category level so individual listings stay small. Confirm these before
deploying any identity solution. Each entry: Description / Why / Verify / Implement-if-missing.

> The identity plane is high risk. A mistake here breaks sign-in for everyone, so every change is
> staged and a break-glass account is kept ready before you touch anything.

## G1. Microsoft Entra ID tenant
Description: An active Microsoft Entra ID tenant.
Why: It is the cloud identity backbone every other identity service builds on.
Verify: Sign in to `https://entra.microsoft.com` as an administrator.
Implement: Create a Microsoft 365 or Azure subscription, which provisions a tenant.

## G2. Entra ID licensing (P1, P2 where noted)
Description: Microsoft Entra ID P1 (or P2 for risk-based and PIM features).
Why: Hybrid features such as seamless sign-in, password writeback, and Conditional Access require P1+.
Verify: M365 admin center -> `Billing -> Licenses`; confirm Entra ID P1/P2 (often bundled in M365 E3/E5 or EMS).
Implement: Assign M365 E3/E5, EMS E3/E5, or standalone Entra ID P1/P2.

## G3. Administrative roles
Description: Hybrid Identity Administrator and Global Administrator for the operator.
Why: Configuring directory synchronization and authentication methods needs these elevated roles.
Verify: Entra -> `Roles and administrators`; confirm `Hybrid Identity Administrator` (and a Global Administrator for the one-time first-sync consent).
Implement: Assign `Hybrid Identity Administrator`; reserve `Global Administrator` for tenant-wide and first-sync changes.

## G4. Break-glass (emergency access) accounts
Description: At least two cloud-only emergency access accounts, excluded from Conditional Access and MFA-broad policies.
Why: If sync, federation, or an auth-method change locks out admins, break-glass accounts get you back in.
Verify: Entra -> `Users`; confirm two cloud-only accounts (`@onmicrosoft.com`) with strong stored credentials and documented use.
Implement: Create two cloud-only Global Administrator accounts; exclude them from policies; store credentials securely and monitor sign-ins.

## G5. Healthy on-premises Active Directory
Description: A functional AD forest/domain with healthy replication and DNS.
Why: Synchronization reads from AD; replication or DNS faults corrupt or stall the sync.
Verify: Run `dcdiag` and `repadmin /replsummary` on a domain controller with no errors; run `HYBID-Discovery.ps1`.
Implement: Resolve AD replication, DNS, and time-sync issues before synchronizing.

## G6. An Entra Connect host server
Description: A domain-joined Windows Server (2016+), patched, for Microsoft Entra Connect Sync (or a lightweight host with the Cloud Sync agent).
Why: Connect Sync runs as a service on this host and must reach both AD and Entra ID.
Verify: A supported, domain-joined server with TLS 1.2, .NET, and PowerShell available; run `HYBID-Discovery.ps1`.
Implement: Provision a dedicated server (not a domain controller for production), patch it, and enable TLS 1.2.

## G7. UPN / domain hygiene
Description: User principal names use a public, verified, routable domain (not `.local`).
Why: A non-routable UPN suffix produces sign-in problems and `onmicrosoft.com` fallbacks in the cloud.
Verify: Entra -> `Identity -> Settings -> Domain names` shows the public domain Verified; AD UPN suffixes match it; run `HYBID-Discovery.ps1`.
Implement: Add and verify the public domain in Entra; add the matching UPN suffix in AD and update user UPNs.

## G8. Network access to Microsoft cloud endpoints
Description: Outbound HTTPS (443) from the Connect host to Entra ID, plus required Microsoft 365 service URLs.
Why: Synchronization, authentication-agent traffic, and tokens depend on these endpoints.
Verify: From the Connect host, reach `https://login.microsoftonline.com` and the Microsoft 365 published URL/IP ranges.
Implement: Allow the Microsoft 365 / Entra service URLs and IP ranges through the proxy/firewall.

---
The deployment model (all solutions): Assess -> Configure -> Pilot -> Validate -> Expand.


---


# 3. Implementation Guide — Hybrid Identity with Active Directory & Microsoft Entra Connect

Follow these steps in order. Work happens in two places: the Microsoft Entra Connect wizard on the
host server, and the cloud portal at `https://entra.microsoft.com` (Identity -> Hybrid management).

> Model: rehearse in staging mode, validate on a pilot scope, then expand to the whole directory.
> The identity plane is high risk — keep your break-glass accounts to hand before every change.

Objects you will create (name them exactly as written and reuse verbatim):
- AD organizational unit: `Hybrid Pilot Sync Scope - Pilot - Pilot`
- AD organizational unit: `Hybrid Production Sync Scope - All-Domains - Expand`
- Entra security group: `Hybrid Join Devices - Pilot - Pilot`
- Hybrid join service connection point config: `Hybrid Entra Join - Domain - Configure`

## Step 1 — Prepare AD and the pilot scope
1. On a domain controller, open `Active Directory Users and Computers`.
2. Create an OU named `Hybrid Pilot Sync Scope - Pilot - Pilot` and move a handful of representative
   pilot users (and test devices) into it.
3. Create an OU (or confirm the existing structure) named
   `Hybrid Production Sync Scope - All-Domains - Expand` to represent the full production scope for
   later expansion.
4. Run `HYBID-Discovery.ps1` and resolve every flagged item (`.local` UPNs, duplicate UPNs/proxyAddresses, AD health).

## Step 2 — Verify the public domain in Entra
1. In `https://entra.microsoft.com`, go to `Identity -> Settings -> Domain names`.
2. Confirm your public domain shows Verified (add and verify it with the displayed DNS TXT record if not).
3. Ensure AD user UPN suffixes match that public domain (fix in `Active Directory Domains and Trusts` if needed).

## Step 3 — Install Microsoft Entra Connect on the host
1. On the Connect host server, download Microsoft Entra Connect and launch the installer.
2. Accept the license, then choose `Customize` (so you can scope the sync and pick the auth method).
3. On `Install required components`, leave the defaults and click `Install`.

## Step 4 — Choose the authentication method (in the wizard)
1. On the `User sign-in` page, select the primary method:
   - `Password Hash Synchronization` (recommended default), or
   - `Pass-through authentication`, or
   - `Federation with AD FS` (only for a stated requirement).
2. Tick `Enable single sign-on` (Seamless SSO) for domain-joined corporate-network users.
3. Click `Next`.

## Step 5 — Connect to Entra ID and AD
1. On `Connect to Microsoft Entra ID`, sign in with a `Global Administrator` (the one-time first-sync consent).
2. On `Connect your directories`, add your AD forest with an enterprise-admin (or delegated sync) credential. Click `Next`.
3. On `Microsoft Entra sign-in configuration`, confirm the UPN suffix is the verified public domain (resolve any warning here before continuing).

## Step 6 — Scope the synchronization
1. On `Domain and OU filtering`, choose `Sync selected domains and OUs`.
2. Select only `Hybrid Pilot Sync Scope - Pilot - Pilot` for the pilot. Click `Next`.
3. On `Uniquely identifying your users`, accept the default (`Users are represented once`) unless you have a multi-forest match attribute.
4. On `Filter users and devices`, keep `Synchronize all users and devices`. Click `Next`.

## Step 7 — Optional features, then stage the first sync
1. On `Optional features`, enable what you need — for example `Password writeback` and (if PTA/federation primary) keep `Password hash synchronization` ticked as a backup. Click `Next`.
2. On `Ready to configure`, tick `Enable staging mode` so the first run imports and rehearses without exporting to the cloud. Click `Install`.
3. When it finishes, run `HYBID-Validation.ps1` and `HYBID-Report.ps1` on the host to review what would export, the connector-space object counts, and any sync errors — fix errors before going live.

## Step 8 — Take the server out of staging mode (go live for the pilot)
1. Re-run the Microsoft Entra Connect wizard, choose `Configure staging mode`, and clear the
   `Enable staging mode` checkbox. Finish the wizard.
2. Force a sync cycle: on the host run `Start-ADSyncSyncCycle -PolicyType Delta`.
3. In `https://entra.microsoft.com -> Identity -> Hybrid management -> Microsoft Entra Connect ->
   Connect Sync`, confirm sync status is healthy and the pilot users now appear under
   `Identity -> Users`.

## Step 9 — Enable Seamless SSO and confirm the auth method
1. In `Identity -> Hybrid management -> Microsoft Entra Connect`, confirm the chosen sign-in method
   shows Enabled and (for PTA) at least two healthy authentication agents.
2. For Seamless SSO, ensure the `AZUREADSSO` computer object exists in AD and roll out the two browser
   settings via Group Policy to pilot devices (Microsoft documents the exact registry/policy values).

## Step 10 — Enable hybrid Entra join (devices)
1. Create an Entra security group named `Hybrid Join Devices - Pilot - Pilot` for pilot devices.
2. Re-run the Microsoft Entra Connect wizard -> `Configure device options` -> `Configure Hybrid Azure AD join`; this writes the service connection point named `Hybrid Entra Join - Domain - Configure`. Select your device OS/platform and finish.
3. On a pilot device, run `dsregcmd /status` and confirm `AzureAdJoined : YES` and `DomainJoined : YES` (allow a policy cycle and a sign-in).

## Step 11 — Validate the pilot
1. Run `HYBID-Validation.ps1` -> confirms sync ran, pilot objects exported, and a test sign-in works.
2. Run `HYBID-Report.ps1` -> confirms sync health, object coverage, and zero unresolved sync errors.
3. Complete the Testing Guide. Do not expand until the pilot gate passes.

## Step 12 — Expand to production
1. Re-run the wizard -> `Customize synchronization options` -> `Domain and OU filtering` and add
   `Hybrid Production Sync Scope - All-Domains - Expand` to the sync scope. Finish.
2. Run `Start-ADSyncSyncCycle -PolicyType Initial` for a full sync of the new scope.
3. Re-run `HYBID-Report.ps1` to confirm coverage and health across the full directory; add
   `Hybrid Join Devices - Pilot - Pilot` members (or a production device group) as you expand hybrid join.

---
### Order of operations
`Prepare AD + pilot scope -> verify domain -> install Connect -> choose auth method -> connect directories -> scope sync -> stage first sync -> exit staging (pilot live) -> Seamless SSO -> hybrid join -> validate -> expand`


---


# 5. Testing Guide — Hybrid Identity with Active Directory & Microsoft Entra Connect

Run after the pilot goes live (Implementation Step 11) and after each change to scope, auth method,
or hybrid join.

## Test 1 — Sync engine healthy and running
Do: On the host run `Get-ADSyncScheduler` and `HYBID-Validation.ps1`.
Expected: `SyncCycleEnabled : True`, the server is not in staging mode, and a delta cycle completes.

## Test 2 — Pilot objects synchronized
Do: In `https://entra.microsoft.com -> Identity -> Users`, search for a pilot user; run `HYBID-Report.ps1`.
Expected: Pilot users from `Hybrid Pilot Sync Scope - Pilot - Pilot` appear in Entra ID with the correct UPN.

## Test 3 — No sync errors / no duplicates
Do: Run `HYBID-Report.ps1` (and `HYBID-Validation.ps1`).
Expected: Zero unresolved sync errors; no duplicate-attribute (UPN/proxyAddress) errors.

## Test 4 — Authentication method works
Do: Sign a pilot user in at `https://myapps.microsoft.com` (incognito), then on a domain-joined corporate device.
Expected: Sign-in succeeds; for PHS the cloud validates; for PTA an agent shows the auth in `Hybrid management`; Seamless SSO does not re-prompt on the corporate network.

## Test 5 — Password writeback (if enabled)
Do: Have a pilot user reset their password via self-service password reset; then sign in on-premises.
Expected: The new password works against AD — writeback succeeded.

## Test 6 — Hybrid Entra join
Do: On a pilot device run `dsregcmd /status`.
Expected: `AzureAdJoined : YES` and `DomainJoined : YES`; the device appears in `Identity -> Devices`.

## Test 7 — Staging-mode failover rehearsal (optional)
Do: If a second Connect server exists in staging mode, run `HYBID-Report.ps1` against it.
Expected: It imports and previews the same objects without exporting — ready to promote on failover.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| Pilot pass | Tests 1-4 pass; zero unresolved sync errors; a pilot user signs in cloud and on a hybrid-joined device |
| Expand pass | Tests 1-3, 6 pass across the production scope before declaring complete |


---


# 6. Troubleshooting Guide — Hybrid Identity with Active Directory & Microsoft Entra Connect

Use `HYBID-Validation.ps1` / `HYBID-Discovery.ps1` for host and identity state, `HYBID-Report.ps1`
for sync health and coverage, and `HYBID-Remediation.ps1` (`-WhatIf` by default) for safe fixes.
Keep your break-glass accounts ready before any change.

## A. Synchronization not running / stalled
| Symptom | Cause | Remediation |
|---|---|---|
| No new objects appear in Entra | Server in staging mode, or scheduler disabled | Run `Get-ADSyncScheduler`; exit staging mode (wizard); `Set-ADSyncScheduler -SyncCycleEnabled $true`; `Start-ADSyncSyncCycle -PolicyType Delta` |
| Cycle errors immediately | AD replication/DNS fault, or credentials expired | Run `HYBID-Discovery.ps1`; fix `dcdiag`/`repadmin` issues; refresh the connector account |
| Nothing in scope | OU/domain filter excludes the objects | Review with `HYBID-Set-SyncScopeHelper.ps1`; widen the sync scope in the wizard |

## B. Duplicate or merged accounts / sync errors
| Symptom | Cause | Remediation |
|---|---|---|
| Duplicate-attribute error | Two objects share a UPN or proxyAddress | Run `HYBID-Report.ps1` to list them; resolve with `HYBID-Remediation.ps1` (review the `-WhatIf` output first) |
| Cloud account separate from on-prem | Soft-match failed (UPN/proxyAddress mismatch) | Align the on-prem UPN/proxyAddress to the cloud value, or hard-match by `ImmutableId`; re-sync |
| `.onmicrosoft.com` UPN in cloud | Non-routable `.local` UPN on-premises | Add the verified public domain and matching UPN suffix; update user UPNs; re-sync |

## C. Sign-in failures
- Password hash sync: confirm PHS is enabled in `Hybrid management`; force a full sync if a single user is stale.
- Pass-through authentication: confirm at least two healthy authentication agents; an offline agent breaks PTA sign-in (PHS backup, if enabled, keeps users working).
- Federation: check the AD FS service and token-signing certificate validity; an expired certificate blocks all federated sign-in.
- Seamless SSO: confirm the `AZUREADSSO` computer object exists and the browser policies are applied to the device.

## D. Hybrid Entra join not completing
| Symptom | Cause | Remediation |
|---|---|---|
| `dsregcmd /status` shows `AzureAdJoined : NO` | Service connection point missing, or device not synced | Re-run the wizard `Configure device options`; confirm the `Hybrid Entra Join - Domain - Configure` SCP; let a policy cycle + sign-in complete |
| Join works for users but not devices | Computer objects out of sync scope | Add the device OU to the sync scope (`HYBID-Set-SyncScopeHelper.ps1`); re-sync |

## E. Accidental-deletion safeguard tripped
- A large scope change can trip the export deletion threshold (a safety feature). Confirm the deletes are intended, then `Enable-ADSyncExportDeletionThreshold` / re-run with the threshold raised only after verifying with `HYBID-Report.ps1`.

## F. Diagnostics quick reference
```powershell
Get-ADSyncScheduler                                  # sync schedule + staging mode
Start-ADSyncSyncCycle -PolicyType Delta              # trigger a delta sync
Get-ADSyncConnectorRunStatus                         # is a run in progress
dsregcmd /status                                     # device hybrid-join state
dcdiag /q ; repadmin /replsummary                    # AD health
```
Connector and run-profile detail is in the Synchronization Service Manager (`miisclient.exe`) on the host.

## G. When to escalate
If sync runs clean, AD is healthy, the auth method is enabled with healthy agents/certificates, and a
user still cannot sign in or hybrid-join after a full sync and a policy cycle, collect the
`HYBID-Report.ps1` output and the connector run details and open a Microsoft support case.


---


# 7. Best Practices — Hybrid Identity with Active Directory & Microsoft Entra Connect

- Treat the identity plane as high risk. Rehearse every change in staging mode, validate on a pilot
  scope, and only then expand — this is the single most important practice.
- Keep break-glass accounts ready. Two cloud-only emergency admins, excluded from broad policies,
  before you touch sync, auth methods, or hybrid join.
- Prefer password hash sync. PHS is the simplest, most resilient method and keeps cloud sign-in
  working if the on-premises servers are down; keep it enabled as a backup even under PTA/federation.
- Fix UPN and domain hygiene first. A verified public routable domain and no duplicate
  UPN/proxyAddress values prevent the most common sync errors and broken sign-ins.
- Scope synchronization deliberately. Use OU/domain filters so test, service, and stale objects stay
  out of the cloud; name your scopes with the `<Purpose> - <Scope> - <Stage>` convention and reuse them.
- Run one active sync server, one in staging. The staging server is your rehearsal surface and your
  failover; never run two active exporters.
- Don't reach for federation by default. AD FS is a large ongoing commitment (certificates, a farm,
  its own outage surface); choose PHS or PTA unless a requirement forces federation.
- Monitor sync health continuously. Check `HYBID-Report.ps1` and the `Hybrid management` blade for
  errors and export latency; chase duplicate-attribute and large-delete safeguards promptly.
- Respect the export deletion threshold. Keep the accidental-deletion safeguard on so a bad filter
  change cannot mass-delete cloud objects; investigate before overriding it.
- Document the design. Record the auth method, sync scopes, writeback settings, and hybrid-join
  configuration for audits and repeatability.


---


# 8. Deliverables Summary — Hybrid Identity with Active Directory & Microsoft Entra Connect

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what is in the box |
| 1. Solution Overview | Hybrid identity, Connect Sync vs. Cloud Sync, auth methods, Seamless SSO, hybrid join, sync health |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing |
| Global Requirements (Entra ID Solutions) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered steps (prepare AD, install Connect, auth method, scope, hybrid join, expand) |
| 5. Testing Guide | Validation procedures with pass/fail gates |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven recommendations |

## PowerShell scripts
| Script | What it does |
|---|---|
| `HYBID-Discovery.ps1` | AD/identity readiness: AD health, `.local`/duplicate UPNs, host and TLS readiness (read-only) |
| `HYBID-Validation.ps1` | Confirms the sync ran, objects exported, and a test sign-in works (read-only) |
| `HYBID-Report.ps1` | Sync health + object coverage across AD and Entra ID via ADSync and Microsoft Graph (read-only) |
| `HYBID-Remediation.ps1` | Safely fixes sync errors and duplicate UPN/proxyAddress values; `-WhatIf` by default |
| `HYBID-Set-SyncScopeHelper.ps1` | Helper to review and stage OU/domain sync-scope changes for the wizard |

## What the buyer receives
- This implementation guide as a branded Word document and PDF.
- All five PowerShell scripts in a single ZIP.
- A repeatable process: Assess -> Configure -> Pilot -> Validate -> Expand.

## Outcome
One reliable identity spanning Active Directory and Entra ID — synchronized cleanly, authenticated by
the right method, with hybrid join and healthy sync, proven on a pilot before you scale.
