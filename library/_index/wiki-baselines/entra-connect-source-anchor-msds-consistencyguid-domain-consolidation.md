# Migrating the Microsoft Entra Connect Source Anchor to mS-DS-ConsistencyGuid for AD Domain Consolidation & Cross-Forest Migration (Quest On Demand Migration)

> **Version 1.0.0** · Category: Entra · Solution code: SRCANCHOR

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary — Migrating the Microsoft Entra Connect Source Anchor to mS-DS-ConsistencyGuid for AD Domain Consolidation & Cross-Forest Migration

Entra ID Solutions

You are consolidating Active Directory — remapping accounts into a target domain or forest and up into
Microsoft Entra ID — and moving the objects with the Quest On Demand Migration (ODM) tooling. But your
existing Microsoft Entra Connect Sync deployment still uses **objectGUID** as its source anchor. That
older default is a landmine: objectGUID is regenerated when an object moves to a new domain or forest,
so every migrated account looks like a brand-new identity to Entra — producing duplicate or orphaned
cloud accounts and users who lose their mailbox, licenses, and Teams. This solution changes the source
anchor to **mS-DS-ConsistencyGuid** safely, on a live deployment, without re-syncing users or creating
duplicates — so the consolidation does not orphan your Entra identities.

This is a complete, do-it-safely package for the specific, high-risk switch from objectGUID to
mS-DS-ConsistencyGuid, written for an administrator with no prior experience of the operation — and it
treats the identity link as the near-irreversible surface it is.

## What you get
- A plain-language Solution Overview of why objectGUID breaks on migration, why mS-DS-ConsistencyGuid
  survives (and how Quest ODM stamps it onto the target), what the wizard switch actually does, and why
  it is seamless for existing users.
- A Requirements Guide with verify / implement-if-missing for every prerequisite — a current Connect
  build, the current anchor, the empty-attribute precondition, the connector-account write permission,
  a configuration backup, the Quest ODM stamp, AD FS ports (if federated), roles, and the tenant.
- An Implementation Guide of precise, click-to-implement steps in five phases with explicit Gates A-E.
- Five read-only PowerShell scripts for assessment, precondition testing, permission checking,
  post-change validation, and coverage reporting. (The anchor change itself is done in the wizard, by
  design — never scripted.)
- Testing and Troubleshooting guides, including the decisive Quest ODM hard-match test.

## What this delivers
The source anchor migrated from objectGUID to mS-DS-ConsistencyGuid: Connect seeds each in-scope
object's existing objectGUID value into mS-DS-ConsistencyGuid, so the immutableId does not change,
there is no re-sync, and no duplicates appear. Quest ODM then carries that attribute across each move,
letting Entra Connect hard-match every migrated object to its existing Entra user.

## The deployment model
Assess -> Configure -> Pilot -> Validate -> Expand — with an explicit gate between phases and a
pre-change configuration backup taken before the wizard runs.

## Outcome
A migration-safe identity link: the same user, mailbox, and licenses survive the domain consolidation,
proven by a Quest ODM hard-match on a pilot before the production waves — deployable by a single
administrator, without orphaning a single Entra identity.


---


# 1. Solution Overview — Migrating the Microsoft Entra Connect Source Anchor to mS-DS-ConsistencyGuid for AD Domain Consolidation & Cross-Forest Migration

## The scenario this solves
You are consolidating Active Directory — remapping accounts into a target domain or forest and up
into Microsoft Entra ID — and you are moving the objects with the Quest On Demand Migration (ODM)
Active Directory tooling. But your existing Microsoft Entra Connect Sync deployment uses **objectGUID**
as its source anchor (the older default). That single design choice will break every migrated
identity's link to the cloud unless you change it first. This solution changes the source anchor to
**mS-DS-ConsistencyGuid** safely, on a live deployment, without re-syncing your users or creating
duplicates — so the domain consolidation does not orphan your Entra identities.

## Why objectGUID breaks on migration (the why lives here)
The source anchor (also called the immutableId) is the value Entra Connect uses to say "this on-prem
object *is* that cloud object." objectGUID is stamped by Active Directory and is unique to an object
**within a single domain**. When Quest ODM migrates (or you otherwise re-create) an account into a
different domain or forest, the target domain issues the object a **brand-new objectGUID**. With
objectGUID as the anchor, Entra Connect then sees the migrated object as a **completely new identity**:
it can no longer match it to the existing Entra user. The result is a duplicate or orphaned cloud
account — and the user loses their mailbox, licenses, Teams, and everything else tied to the original
Entra object. On a domain consolidation, objectGUID is a landmine.

## Why mS-DS-ConsistencyGuid is the fix
mS-DS-ConsistencyGuid is a writable AD attribute whose value is **preserved across a migration**
when the migration tool carries it forward. Quest ODM **stamps (copies) the mS-DS-ConsistencyGuid
value onto the target object** as part of the move. Because the anchor value survives the move,
Entra Connect can **hard-match** the migrated AD object to the *existing* Entra user — same identity,
same mailbox, same licenses. The on-prem ↔ Entra link survives the consolidation. This is exactly why
Microsoft recommends mS-DS-ConsistencyGuid as the source anchor for any environment that will migrate
or restructure AD.

## What the switch actually does (and why it is seamless)
Switching the anchor on a live objectGUID deployment is a supported wizard operation. When you select
mS-DS-ConsistencyGuid in the Microsoft Entra Connect wizard, for **each in-scope object whose
mS-DS-ConsistencyGuid is currently empty**, Connect **writes that object's own objectGUID value into
its mS-DS-ConsistencyGuid attribute** (a write-back into AD). Because the value it seeds is the *same*
objectGUID the anchor already used, the computed immutableId does **not change** for your existing
users. So there is **no re-sync, no duplicate accounts, and no user impact** at cutover — the anchor
simply moves from a domain-scoped attribute to a migration-safe one, carrying the same value.

## The precondition that makes it safe
The wizard will only seed mS-DS-ConsistencyGuid where it is **empty**. It analyzes all in-scope objects
first, and **if any in-scope object already has a value in mS-DS-ConsistencyGuid, the wizard refuses
by default** — because a pre-existing value could mean the object was matched by something else, and
overwriting it would break the link. That refusal is a safety feature, not a bug: it forces you to
find and understand what populated the attribute before you proceed. Confirming the attribute is empty
across scope is therefore the central go/no-go check of this solution.

## What you can control
- The **source anchor** itself — objectGUID today, mS-DS-ConsistencyGuid after this change.
- The **AD scope** the change applies to — the `Source Anchor – In-Scope OUs` that Connect syncs.
- The **AD DS connector (sync) account's** write permission to mS-DS-ConsistencyGuid (required to seed it).
- The **backup** taken before the change — the exported Connect configuration in your
  `Source Anchor – Change & Backup Record`.
- The **pilot proof** — a `PILOT – Source Anchor – Validation Users` set migrated through Quest ODM to
  prove the hard-match survives before you run production waves.

## The standard deployment model
> Assess the current anchor, version, permissions, and whether mS-DS-ConsistencyGuid is empty ->
> Configure the switch in the Entra Connect wizard -> Pilot one migrated user through Quest ODM and
> confirm a hard-match -> Validate no duplicates/orphans and unchanged immutableId -> Expand into the
> full Quest ODM migration waves. The repeatable way: Assess -> Configure -> Pilot -> Validate -> Expand.

## Limitations (be honest with buyers)
- The anchor switch is effectively **permanent and one-way**. Once objects are seeded and migrations
  begin, you do **not** revert to objectGUID mid-migration — the safety net is the pre-change backup
  and the empty-attribute precondition, not a rollback.
- It requires a **current Microsoft Entra Connect Sync** build (mS-DS-ConsistencyGuid has been the
  default source anchor since Azure AD Connect 1.1.524; an old build may not offer the operation).
- mS-DS-ConsistencyGuid is a **single-forest linking attribute**; a genuine multi-forest topology
  needs additional matching planning (called out where relevant).
- The **actual attribute-carry across the migration is Quest ODM's job** — this solution states the
  coordination point (Quest must stamp/copy mS-DS-ConsistencyGuid onto the target object) and consumes
  it; the Quest ODM console configuration itself is documented by Quest.

## Scope of this solution (what it is and is not)
This is the **source-anchor migration** for a domain consolidation — the specific, high-risk switch
from objectGUID to mS-DS-ConsistencyGuid on an existing deployment, plus the precondition, permission,
backup, pilot, and validation work around it. It does **not** re-teach general Microsoft Entra Connect
or hybrid-identity setup (installing Connect, choosing PHS/PTA/federation, hybrid join) — that is the
companion Hybrid Identity solution. Start here when Connect is already running on objectGUID and a
migration is coming.


---


# 2. Requirements Guide — Migrating the Microsoft Entra Connect Source Anchor to mS-DS-ConsistencyGuid

Verify every requirement before changing the source anchor. Each entry: Description / Why / Verify /
Implement-if-missing. Category-wide prerequisites are in `global-requirements-entra-id-solutions.md`.

> The anchor switch is effectively permanent. Confirm the version, the empty-attribute precondition,
> the connector-account permission, and the backup **before** you open the wizard.

## 2.1 A current Microsoft Entra Connect Sync build
Description: Microsoft Entra Connect Sync at a build that supports mS-DS-ConsistencyGuid as the source anchor.
Why: mS-DS-ConsistencyGuid has been the default source anchor since Azure AD Connect 1.1.524; an older build may not offer the Configure Source Anchor operation.
Verify: On the Connect server run `SRCANCHOR-Assess.ps1` (reports the installed version); or check `Add or remove programs` for the Microsoft Azure AD Connect / Microsoft Entra Connect version.
Implement: Upgrade Microsoft Entra Connect Sync to the current release before proceeding, then re-run `SRCANCHOR-Assess.ps1`.

## 2.2 Current source anchor confirmed as objectGUID
Description: Confirmation that the deployment's current source anchor is `objectGUID` (the older method).
Why: This solution is the switch *from* objectGUID; if the anchor is already mS-DS-ConsistencyGuid there is nothing to change.
Verify: Run `SRCANCHOR-Assess.ps1` (reads the source anchor from `Get-ADSyncGlobalSettings`); it reports the current `Microsoft.SourceAnchorAttribute`.
Implement: If already mS-DS-ConsistencyGuid, stop — the migration prerequisite is already met; proceed to the Quest ODM coordination check (2.6).

## 2.3 mS-DS-ConsistencyGuid EMPTY on all in-scope objects (the precondition)
Description: No object in the `Source Anchor – In-Scope OUs` currently has a value in mS-DS-ConsistencyGuid.
Why: The wizard only seeds the attribute where it is empty; if ANY in-scope object already has a value, the wizard refuses by default (a pre-existing value can mean the object is matched by something else, and overwriting it would break the link).
Verify: Run `SRCANCHOR-Test-Preconditions.ps1 -IncludeOU "<OU DN>"` — it lists any in-scope objects whose mS-DS-ConsistencyGuid is already set (count + sample distinguishedNames). Zero = ready.
Implement: Investigate whatever populated the attribute (a prior Connect install, a previous migration, or a manual stamp). Either clear it after confirming it is safe to do so, or exclude those objects from scope, until the count is zero. Do not blindly clear it.

## 2.4 AD DS connector (sync) account WRITE permission to mS-DS-ConsistencyGuid
Description: The AD DS connector (sync) account has Write permission to the mS-DS-ConsistencyGuid attribute across the `Source Anchor – In-Scope OUs`.
Why: To seed the anchor, Connect writes each object's objectGUID value into its mS-DS-ConsistencyGuid attribute (a write-back into AD); without Write permission the seed fails with access-denied.
Verify: Run `SRCANCHOR-Check-Permissions.ps1 -ConnectorAccount "<DOMAIN\account>" -IncludeOU "<OU DN>"` — it reports per-OU PASS/FAIL for Write mS-DS-ConsistencyGuid.
Implement: Delegate Write mS-DS-ConsistencyGuid to the AD DS connector (sync) account on each in-scope OU (see Implementation Step 4 — `dsacls` or the ADUC Delegation of Control wizard).

## 2.5 A full backup / configuration export of Microsoft Entra Connect
Description: An exported Microsoft Entra Connect configuration captured before the change, recorded in the `Source Anchor – Change & Backup Record`.
Why: The switch is effectively permanent; the export is your documented pre-change state and the reference if you need Microsoft support.
Verify: A saved configuration export file exists and its filename, the Connect server name, and the change date are written into the `Source Anchor – Change & Backup Record`.
Implement: In the Microsoft Entra Connect wizard choose `View or export current configuration` and save the export; record it (see Implementation Step 5).

## 2.6 Quest On Demand Migration configured to stamp mS-DS-ConsistencyGuid on targets
Description: Quest ODM (or Quest Migration Manager) is configured so that each migrated/target object carries the source object's mS-DS-ConsistencyGuid value.
Why: The anchor only survives the move if the migration tool copies mS-DS-ConsistencyGuid onto the target; that carry is what lets Entra Connect hard-match the migrated object to the existing Entra user.
Verify: Confirm in Quest ODM that the matching/attribute mapping carries mS-DS-ConsistencyGuid to the target (per Quest's documentation), then prove it end-to-end with the pilot in Implementation Step 8.
Implement: Configure the mS-DS-ConsistencyGuid carry in Quest ODM per Quest's official documentation. (Quest console internals are documented by Quest; this solution consumes the stamped attribute as its coordination point and does not configure the Quest console.)

## 2.7 AD FS network path — ONLY if AD FS is the sign-in method
Description: If sign-in uses AD FS (federation), direct network connections on TCP 80, 443, and 5985 from the Connect server to the **primary AD FS server**.
Why: Changing the source anchor updates the AD FS issuance/claim rules, which the wizard performs against the primary AD FS server over these ports; without them that step fails.
Verify: Confirm the sign-in method (Entra admin center -> `Identity -> Hybrid management -> Microsoft Entra Connect`); if AD FS, test TCP 80/443/5985 from the Connect server to the primary AD FS server.
Implement: Open TCP 80/443/5985 from the Connect server to the primary AD FS server before running the wizard. If sign-in is PHS, PTA, or cloud authentication, this requirement does **not** apply.

## 2.8 Administrative roles
Description: Enterprise/Domain Admin (or delegated) rights to set the AD permission, plus Global Administrator / Hybrid Identity Administrator for the Entra side.
Why: Delegating Write mS-DS-ConsistencyGuid needs AD rights; the wizard's Entra connection needs the Entra role.
Verify: You can run `dsacls`/Delegation of Control on the in-scope OUs, and sign in to the wizard's Entra connection with the required role.
Implement: Obtain Enterprise/Domain Admin (or a delegated equivalent) for the OU permission and Global Administrator / Hybrid Identity Administrator for the Entra connection.

## 2.9 The Microsoft Entra tenant
Description: The Microsoft Entra ID tenant the Connect server already synchronizes to.
Why: The anchor change is applied by the same Connect deployment against the same tenant.
Verify: Sign in to `https://entra.microsoft.com` (Gov: `https://entra.microsoft.us`) as an administrator; confirm the tenant matches the Connect deployment.
Implement: Use the existing tenant; no new tenant is created by this solution.

> **Government (GCC High) note:** In US Government (GCC High) tenants, use the Microsoft Entra admin
> center at `https://entra.microsoft.us` and sign in at `https://login.microsoftonline.us`. The
> mS-DS-ConsistencyGuid source-anchor mechanics are identical; **verify for GCC High** that your Entra
> Connect build and endpoints are the US-Government variants before you run the wizard.

---
## Checklist
- [ ] Current Microsoft Entra Connect Sync build (supports mS-DS-ConsistencyGuid) — `SRCANCHOR-Assess.ps1`
- [ ] Current source anchor confirmed as `objectGUID` — `SRCANCHOR-Assess.ps1`
- [ ] mS-DS-ConsistencyGuid EMPTY on all in-scope objects — `SRCANCHOR-Test-Preconditions.ps1`
- [ ] AD DS connector (sync) account has Write mS-DS-ConsistencyGuid on each in-scope OU — `SRCANCHOR-Check-Permissions.ps1`
- [ ] Microsoft Entra Connect configuration exported into the `Source Anchor – Change & Backup Record`
- [ ] Quest ODM configured to stamp mS-DS-ConsistencyGuid on targets (per Quest docs)
- [ ] AD FS ports TCP 80/443/5985 to the primary AD FS server (ONLY if AD FS sign-in)
- [ ] Admin roles available (Enterprise/Domain Admin for delegation; Global Admin / Hybrid Identity Admin for Entra)
- [ ] Correct Microsoft Entra tenant confirmed


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


# 3. Implementation Guide — Migrating the Microsoft Entra Connect Source Anchor to mS-DS-ConsistencyGuid

Follow these steps in order. Work happens in three places: PowerShell on the Microsoft Entra Connect
server, `Active Directory Users and Computers` on a domain controller, and the Microsoft Entra Connect
wizard on the Connect server.

> Model: Assess -> Configure -> Pilot -> Validate -> Expand, with an explicit gate between phases.
> The anchor switch is effectively permanent — do not open the wizard until Gate A passes.

Objects and artifacts you will use (name them exactly as written and reuse verbatim):
- AD scope: `Source Anchor – In-Scope OUs` (the OUs Microsoft Entra Connect synchronizes)
- Pilot user set: `PILOT – Source Anchor – Validation Users` (a small set used to prove the hard-match)
- Sync account: `the AD DS connector (sync) account` (the MSOL_/ADSync service account Connect uses)
- Record: `Source Anchor – Change & Backup Record` (the config export + the change date)

---
## Phase 1 — Assess

## Step 1 — Read the current state on the Connect server
1. Sign in to the Microsoft Entra Connect server as an administrator.
2. Open an elevated PowerShell and run `SRCANCHOR-Assess.ps1`.
3. Confirm it reports: the current source anchor is `objectGUID`, the installed Microsoft Entra Connect
   Sync version supports mS-DS-ConsistencyGuid, and the count of in-scope objects that already have
   mS-DS-ConsistencyGuid populated.

## Step 2 — Confirm the empty-attribute precondition
1. Identify the OUs that make up `Source Anchor – In-Scope OUs` (the OUs Connect syncs).
2. Run `SRCANCHOR-Test-Preconditions.ps1 -IncludeOU "<OU distinguishedName>"` for each in-scope OU.
3. Confirm the reported count of objects with mS-DS-ConsistencyGuid already set is **zero**. If it is
   non-zero, **STOP** — investigate what populated the attribute (a prior Connect install, an earlier
   migration, or a manual stamp). Clear it only after confirming it is safe, or exclude those objects
   from scope, until the count is zero. Do not proceed with any value present.

## Step 3 — Confirm the connector-account permission
1. Identify the AD DS connector (sync) account (the MSOL_/ADSync service account Connect uses to read
   and write AD).
2. Run `SRCANCHOR-Check-Permissions.ps1 -ConnectorAccount "<DOMAIN\account>" -IncludeOU "<OU distinguishedName>"`.
3. Note any OU reporting FAIL for Write mS-DS-ConsistencyGuid — you grant it in Step 4.

## Step 4 — Grant Write mS-DS-ConsistencyGuid where missing
1. On a domain controller, open `Active Directory Users and Computers`, and turn on
   `View -> Advanced Features`.
2. For each OU that failed Step 3, right-click the OU -> `Delegate Control...` -> `Next` ->
   `Add...` the AD DS connector (sync) account -> `Next` -> `Create a custom task to delegate` ->
   `Only the following objects in the folder` -> tick `User objects` -> `Next` -> under `Permissions`
   tick `Property-specific`, then tick `Write mS-DS-ConsistencyGuid` -> `Next` -> `Finish`.
   (Equivalent command line, run as a Domain Admin:
   `dsacls "OU=<in-scope OU>,DC=corp,DC=example,DC=com" /I:S /G "<DOMAIN\account>:WP;mS-DS-ConsistencyGuid;user"`.)
3. Re-run `SRCANCHOR-Check-Permissions.ps1` and confirm every in-scope OU now reports PASS.

## Step 5 — Back up the Connect configuration
1. On the Connect server, launch the Microsoft Entra Connect wizard.
2. On the tasks page choose `View or export current configuration`, then export/save the configuration
   file.
3. Record the export filename, the Connect server name, its ADSync database (SQL/LocalDB) location, and
   the planned change date in the `Source Anchor – Change & Backup Record`.

> ### Gate A — Assess complete
> Proceed only when: source anchor is `objectGUID`; the Connect build supports mS-DS-ConsistencyGuid;
> `SRCANCHOR-Test-Preconditions.ps1` reports **zero** in-scope objects with mS-DS-ConsistencyGuid set;
> `SRCANCHOR-Check-Permissions.ps1` reports **PASS** on every in-scope OU; and the configuration export
> is recorded in the `Source Anchor – Change & Backup Record`. If AD FS is your sign-in method, also
> confirm TCP 80/443/5985 to the primary AD FS server (Requirement 2.7).

---
## Phase 2 — Configure

## Step 6 — Switch the source anchor in the wizard
1. On the Connect server, launch the Microsoft Entra Connect wizard.
2. On the tasks page choose `Configure` -> `Configure Source Anchor`.
3. When prompted, sign in to Microsoft Entra ID with a `Global Administrator` /
   `Hybrid Identity Administrator` (Gov: sign in at `https://login.microsoftonline.us`).
4. Let the wizard analyze mS-DS-ConsistencyGuid across the in-scope objects. When it offers
   `mS-DS-ConsistencyGuid` as the source anchor, select it and continue.
5. Complete the wizard. For each in-scope object whose mS-DS-ConsistencyGuid is empty, Connect writes
   that object's objectGUID value into its mS-DS-ConsistencyGuid attribute (the seed). Because the
   seeded value equals the existing objectGUID, the immutableId does not change and no re-sync occurs.

> If the wizard reports that mS-DS-ConsistencyGuid is **not empty** and refuses, do not force it —
> return to Step 2, clear or exclude the flagged objects, then retry. If it reports **access denied**
> writing the attribute, return to Step 4 and re-grant the connector-account permission.

## Step 7 — Confirm the seed landed
1. On the Connect server run `SRCANCHOR-Validate.ps1`.
2. Confirm it reports the current source anchor is now `mS-DS-ConsistencyGuid`, sampled in-scope objects
   have mS-DS-ConsistencyGuid populated, and each sampled object's mS-DS-ConsistencyGuid (Base64) equals
   its prior immutableId (the objectGUID Base64) — i.e. the anchor value did not change.

> ### Gate B — Configure complete
> Proceed only when the source anchor reads `mS-DS-ConsistencyGuid`, in-scope objects are seeded, and
> the seeded value equals the previous immutableId (no anchor change, no duplicates).

---
## Phase 3 — Pilot

## Step 8 — Migrate one pilot user through Quest ODM and prove the hard-match
1. Assemble a small `PILOT – Source Anchor – Validation Users` set (a handful of representative users
   whose migration you can safely rehearse).
2. Confirm the mS-DS-ConsistencyGuid values are populated for the pilot users (`SRCANCHOR-Validate.ps1`
   or a spot check).
3. Using Quest ODM, perform a test migration of one `PILOT – Source Anchor – Validation Users` object
   into the target domain **with mS-DS-ConsistencyGuid stamped onto the target object** (per Quest's
   documentation and Requirement 2.6).
4. Let a Connect delta sync run (`Start-ADSyncSyncCycle -PolicyType Delta` on the Connect server).
5. In `https://entra.microsoft.com -> Identity -> Users` (Gov: `https://entra.microsoft.us`), confirm
   the migrated pilot user is the **same** Entra object updated in place — **not** a new/duplicate
   account — and it retains its mailbox, licenses, and sign-in.

> ### Gate C — Pilot passes
> Proceed only when a pilot object migrated through Quest ODM (with mS-DS-ConsistencyGuid stamped)
> hard-matches the existing Entra user: one object, updated in place, no duplicate, licenses/mailbox
> intact.

---
## Phase 4 — Validate

## Step 9 — Full validation and report
1. On the Connect server run `SRCANCHOR-Validate.ps1` and `SRCANCHOR-Report.ps1`.
2. Confirm: the anchor is `mS-DS-ConsistencyGuid`; the seeded/populated count matches the in-scope
   object count; there are no unresolved ADSync run errors; the duplicate-risk check is clean; and (if
   Microsoft Graph is available) the matched Entra users' `onPremisesImmutableId` values are unchanged.
3. Complete the Testing Guide. Do not begin production waves until the validate gate passes.

> ### Gate D — Validate passes
> Proceed only when validation shows the anchor migrated, no duplicate/orphaned Entra objects, sign-in
> working, and immutableId unchanged for existing users.

---
## Phase 5 — Expand

## Step 10 — Run the production migration waves
1. Proceed with the full Quest ODM migration waves against the target domain, keeping the
   mS-DS-ConsistencyGuid stamp configured for every wave.
2. After each wave, run `SRCANCHOR-Report.ps1` and confirm no duplicates/orphans and no new ADSync
   errors before starting the next wave.
3. Keep the `Source Anchor – Change & Backup Record` up to date with each wave's date and result.

> ### Gate E — Expand complete
> All migration waves finished; `SRCANCHOR-Report.ps1` clean across the migrated population; every
> migrated user hard-matched with identity, mailbox, and licenses intact.

> **Rollback note:** the anchor switch is effectively permanent. Do **not** attempt to revert to
> objectGUID mid-migration — doing so would re-break the link for already-migrated users. Your safety
> is the pre-change backup (`Source Anchor – Change & Backup Record`) and the empty-attribute
> precondition proven at Gate A, not a mid-flight rollback.

---
### Order of operations
`Assess (version, anchor, empty precondition, permission, backup) -> Gate A -> Configure Source Anchor
(wizard, seed) -> Gate B -> Pilot one Quest ODM migration + hard-match -> Gate C -> Validate (no
duplicates, immutableId unchanged) -> Gate D -> Expand (production waves, monitor) -> Gate E`


---


# 5. Testing Guide — Migrating the Microsoft Entra Connect Source Anchor to mS-DS-ConsistencyGuid

Run these after the wizard change (Implementation Step 6) and after the pilot migration (Step 8). Each
test states what to Do and the Expected result. The decisive test is Test 5.

## Test 1 — Precondition was clean before the change
Do: Review the `SRCANCHOR-Test-Preconditions.ps1` output captured at Gate A for each in-scope OU.
Expected: Zero in-scope objects had mS-DS-ConsistencyGuid populated before the switch (the wizard could seed every object).

## Test 2 — Connector-account permission is in place
Do: Run `SRCANCHOR-Check-Permissions.ps1 -ConnectorAccount "<DOMAIN\account>" -IncludeOU "<OU DN>"`.
Expected: Every in-scope OU reports PASS for Write mS-DS-ConsistencyGuid.

## Test 3 — Source anchor is now mS-DS-ConsistencyGuid
Do: On the Connect server run `SRCANCHOR-Validate.ps1` (reads the anchor from `Get-ADSyncGlobalSettings`).
Expected: The current source anchor reads `mS-DS-ConsistencyGuid` (no longer `objectGUID`).

## Test 4 — Anchor value did NOT change (seamless for existing users)
Do: Run `SRCANCHOR-Validate.ps1` and review the per-object check.
Expected: Sampled in-scope objects have mS-DS-ConsistencyGuid populated, and each object's mS-DS-ConsistencyGuid (Base64) equals its prior immutableId (objectGUID Base64) — the anchor value is unchanged, so no re-sync and no duplicates.

## Test 5 — Migrated pilot user hard-matches (the decisive test)
Do: Migrate one `PILOT – Source Anchor – Validation Users` object into the target domain via Quest ODM **with mS-DS-ConsistencyGuid stamped on the target**, let a delta sync run, then find the user in `https://entra.microsoft.com -> Identity -> Users` (Gov: `https://entra.microsoft.us`).
Expected: The **same** Entra user object is updated in place (hard-matched) — **not** duplicated — and retains its mailbox, licenses, and sign-in.

## Test 6 — No duplicates or orphans across scope
Do: Run `SRCANCHOR-Report.ps1`.
Expected: In-scope object count matches the count with mS-DS-ConsistencyGuid populated; the duplicate-risk check is clean; no unresolved ADSync run errors.

## Test 7 — Sign-in still works (and AD FS, if used)
Do: Sign a migrated pilot user in at `https://myapps.microsoft.com` (incognito). If sign-in uses AD FS, also confirm federated sign-in succeeds after the wizard updated the claim rules.
Expected: Sign-in succeeds; for AD FS environments the issuance/claim rule update completed (TCP 80/443/5985 to the primary AD FS server were open).

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| Configure pass (Gate B) | Tests 3-4 pass: anchor is mS-DS-ConsistencyGuid and the seeded value equals the prior immutableId |
| Pilot pass (Gate C) | Test 5 passes: a Quest-migrated pilot user hard-matches — one object, no duplicate, licenses/mailbox intact |
| Validate pass (Gate D) | Tests 1-7 pass: clean precondition, permission PASS, anchor migrated, no duplicates/orphans, sign-in working |


---


# 6. Troubleshooting Guide — Migrating the Microsoft Entra Connect Source Anchor to mS-DS-ConsistencyGuid

Use `SRCANCHOR-Assess.ps1` and `SRCANCHOR-Test-Preconditions.ps1` for the pre-change state,
`SRCANCHOR-Check-Permissions.ps1` for the connector-account permission, and `SRCANCHOR-Validate.ps1` /
`SRCANCHOR-Report.ps1` for the post-change state. The anchor switch is effectively permanent — work
these issues before and immediately after the wizard, not after production waves.

## A. Wizard won't offer / won't allow mS-DS-ConsistencyGuid
| Symptom | Cause | Remediation |
|---|---|---|
| Wizard says mS-DS-ConsistencyGuid is "not empty" and refuses | One or more in-scope objects already have a value in mS-DS-ConsistencyGuid (prior Connect install, earlier migration, or manual stamp) | Run `SRCANCHOR-Test-Preconditions.ps1 -IncludeOU "<OU DN>"` to list them; investigate what populated the attribute, then either clear it after confirming it is safe, or exclude those objects from scope, until the count is zero — then retry the wizard |
| `Configure Source Anchor` is not offered at all | Microsoft Entra Connect Sync build too old to support the mS-DS-ConsistencyGuid operation | Confirm the version with `SRCANCHOR-Assess.ps1`; upgrade Entra Connect Sync to the current release (mS-DS-ConsistencyGuid is the default since Azure AD Connect 1.1.524), then retry |

## B. "Access denied" writing mS-DS-ConsistencyGuid (seed fails)
| Symptom | Cause | Remediation |
|---|---|---|
| Wizard/sync errors with access-denied when seeding the attribute | The AD DS connector (sync) account lacks Write permission to mS-DS-ConsistencyGuid on an in-scope OU | Run `SRCANCHOR-Check-Permissions.ps1 -ConnectorAccount "<DOMAIN\account>" -IncludeOU "<OU DN>"`; delegate Write mS-DS-ConsistencyGuid on the failing OU (Implementation Step 4 — ADUC Delegation of Control or `dsacls ... /G "<DOMAIN\account>:WP;mS-DS-ConsistencyGuid;user"`); re-run the check until every OU is PASS, then re-run the wizard |

## C. Duplicate or orphaned Entra objects after a migration
| Symptom | Cause | Remediation |
|---|---|---|
| A migrated user appears as a NEW/duplicate Entra account; the original is orphaned | Quest ODM did not stamp mS-DS-ConsistencyGuid onto the target object, or stamped a mismatched value | Confirm the mS-DS-ConsistencyGuid carry in Quest ODM (per Quest's docs, Requirement 2.6); for the affected user, align mS-DS-ConsistencyGuid on the target to the original immutableId, let a delta sync run, then hard-match/soft-match remediate the duplicate in Entra |
| Duplicates appeared for users migrated BEFORE the switch | Objects were migrated while the anchor was still objectGUID — their new objectGUID broke the match | Set mS-DS-ConsistencyGuid on the migrated (target) object to the original object's objectGUID Base64 value, re-sync, and remediate the resulting duplicate (hard-match by immutableId); migrate no further waves until the anchor switch and pilot pass |
| Cloud account separate from on-prem after migration | Soft-match failed (attribute mismatch) | Verify the migrated object's mS-DS-ConsistencyGuid equals the existing Entra user's onPremisesImmutableId; correct the attribute, re-sync, and hard-match by immutableId |

## D. AD FS sign-in breaks after the change
- If sign-in uses AD FS, changing the source anchor updates the issuance/claim rules against the
  **primary AD FS server**. If that update did not complete, federated sign-in can fail.
- Confirm direct network connections on **TCP 80, 443, and 5985** from the Connect server to the
  primary AD FS server (Requirement 2.7), then re-run the wizard's source-anchor/claim-rule step.
- If sign-in is PHS, PTA, or cloud authentication, this section does not apply — the claim-rule update
  is not performed.

## E. Version too old
- `SRCANCHOR-Assess.ps1` reports a Microsoft Entra Connect Sync build that predates mS-DS-ConsistencyGuid
  support (older than Azure AD Connect 1.1.524). Upgrade Entra Connect Sync to the current release, then
  re-run `SRCANCHOR-Assess.ps1` and proceed.

## F. Multi-forest conflicts
- mS-DS-ConsistencyGuid is a **single-forest** linking attribute. In a genuine multi-forest topology,
  the same anchor value could collide or fail to match across forests. Plan the multi-forest matching
  (which forest is authoritative, how objects are joined) before relying on mS-DS-ConsistencyGuid, and
  treat that planning as out of scope for this single-forest switch.

## G. Diagnostics quick reference
```powershell
Get-ADSyncGlobalSettings | Select-Object -ExpandProperty Parameters   # current source anchor
Start-ADSyncSyncCycle -PolicyType Delta                                # trigger a delta sync
Get-ADObject -LDAPFilter "(mS-DS-ConsistencyGuid=*)" -SearchBase "<OU DN>"  # objects already stamped
Get-ADSyncRunProfileResult -NumberRequested 10                         # recent run results/errors
```
Connector and run-profile detail is in the Synchronization Service Manager (`miisclient.exe`) on the
Connect host.

## H. When to escalate
If the version supports the operation, the precondition count is zero, the connector account has Write
mS-DS-ConsistencyGuid, and the wizard still refuses or the seed still fails, capture the
`SRCANCHOR-Assess.ps1` and `SRCANCHOR-Validate.ps1` output and the wizard/connector error, and open a
Microsoft support case before migrating any further objects.


---


# 7. Best Practices — Migrating the Microsoft Entra Connect Source Anchor to mS-DS-ConsistencyGuid

- Change the anchor BEFORE you migrate a single production object. objectGUID is regenerated on a
  domain/forest move; if you migrate first, the migrated objects look new to Entra and duplicate. The
  switch to mS-DS-ConsistencyGuid is the precondition for the whole consolidation, not a follow-up.
- Prove the empty-attribute precondition, don't assume it. The wizard only seeds mS-DS-ConsistencyGuid
  where it is empty; a single pre-existing value stops it. Run `SRCANCHOR-Test-Preconditions.ps1` on
  every in-scope OU and reach a zero count before opening the wizard.
- Never blindly clear mS-DS-ConsistencyGuid. If it is already populated, find out what put it there (a
  prior Connect install, an earlier migration, a manual stamp) and confirm it is safe before clearing
  or excluding — clearing a live anchor breaks the link.
- Grant the AD DS connector (sync) account exactly the permission it needs. Write mS-DS-ConsistencyGuid
  on the in-scope OUs — no more. Delegate it at the OU, verify with `SRCANCHOR-Check-Permissions.ps1`,
  and remove it later only if your change control requires it.
- Back up the Connect configuration first and record it. The switch is effectively permanent; export
  the configuration and log it in the `Source Anchor – Change & Backup Record` with the server, the
  ADSync database location, and the change date.
- Confirm the seed is a no-op for existing users. After the wizard, verify the seeded
  mS-DS-ConsistencyGuid equals each object's prior immutableId (objectGUID Base64) — that equality is
  what guarantees no re-sync and no duplicates at cutover.
- Treat Quest ODM's attribute stamp as a coordination contract. The anchor only survives the move if
  Quest copies mS-DS-ConsistencyGuid onto the target; confirm that mapping in Quest (per Quest's docs)
  and prove it on the pilot before any production wave.
- Pilot the end-to-end hard-match, not just the wizard. Migrate one `PILOT – Source Anchor –
  Validation Users` object through Quest and confirm Entra updates the *same* user — the wizard
  succeeding is necessary but not sufficient.
- Do not revert mid-migration. The anchor switch is one-way in practice; reverting to objectGUID after
  waves have started re-breaks already-migrated users. Rely on the pre-change backup and the gates, not
  a rollback.
- Mind AD FS only when it applies. If sign-in is AD FS, open TCP 80/443/5985 to the primary AD FS
  server so the wizard can update the claim rules; if sign-in is PHS/PTA/cloud auth, this does not
  apply — don't over-scope firewall changes.
- Remember it is a single-forest linking attribute. mS-DS-ConsistencyGuid links within one forest; a
  genuine multi-forest topology needs additional matching planning before you rely on it.


---


# 8. Deliverables Summary — Migrating the Microsoft Entra Connect Source Anchor to mS-DS-ConsistencyGuid

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case: why objectGUID breaks on a domain consolidation and what the switch delivers |
| 1. Solution Overview | The scenario, why objectGUID breaks and mS-DS-ConsistencyGuid survives, what the switch does, why it is seamless, and clear scope |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing (version, current anchor, empty precondition, connector permission, backup, Quest stamp, AD FS ports, roles, tenant) |
| Global Requirements (Entra ID Solutions) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered steps with Gates A-E: Assess -> Configure -> Pilot -> Validate -> Expand |
| 5. Testing Guide | Validation procedures with pass/fail gates, incl. the decisive Quest hard-match test |
| 6. Troubleshooting Guide | Field issues and remediation (wizard refusal, access denied, duplicates, AD FS, version, multi-forest) |
| 7. Best Practices | Field-proven recommendations for a safe, one-way anchor migration |

## PowerShell scripts
| Script | What it does |
|---|---|
| `SRCANCHOR-Assess.ps1` | Reports the current source anchor, the installed Entra Connect Sync version, and whether mS-DS-ConsistencyGuid is populated anywhere in-scope, with a readiness verdict (read-only) |
| `SRCANCHOR-Test-Preconditions.ps1` | Enumerates the in-scope OUs and lists any objects whose mS-DS-ConsistencyGuid is already set — the blocker (read-only) |
| `SRCANCHOR-Check-Permissions.ps1` | Verifies the AD DS connector (sync) account has Write mS-DS-ConsistencyGuid on each in-scope OU, per-OU PASS/FAIL (read-only) |
| `SRCANCHOR-Validate.ps1` | Post-change: confirms the anchor is now mS-DS-ConsistencyGuid, the seed equals the prior immutableId, and (if Graph) the Entra user's onPremisesImmutableId is unchanged (read-only) |
| `SRCANCHOR-Report.ps1` | Run/coverage report: in-scope object count, count populated, recent ADSync run errors, and a duplicate-risk check; optional CSV (read-only) |

## What the buyer receives
- This implementation guide as a PDF (`SRCANCHOR-Solution.pdf`).
- All five PowerShell scripts in a single ZIP (`SRCANCHOR-Scripts.zip`).
- A repeatable process: Assess -> Configure -> Pilot -> Validate -> Expand, with explicit Gates A-E.

## Outcome
A source anchor migrated from objectGUID to mS-DS-ConsistencyGuid on a live deployment — seamlessly for
existing users, with the connector permission and backup in place, proven by a Quest ODM hard-match on
a pilot before the production waves run. The domain consolidation proceeds without orphaning a single
Entra identity.
