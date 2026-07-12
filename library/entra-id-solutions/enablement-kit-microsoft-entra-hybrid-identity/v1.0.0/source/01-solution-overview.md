# 1. Solution Overview — Enablement Kit: Microsoft Entra Hybrid Identity

## What this kit is
This is a self-guided **enablement kit**: a training deliverable that teaches an admin team how hybrid
identity works on Microsoft Entra and lets them rehearse each part hands-on. It is the team-enablement
companion to the **implementation** solution *Hybrid Identity with AD & Entra Connect* (HYBID) — it
builds understanding and diagnostic skill, and points to HYBID for production build-out. It is not
itself a production implementation project.

## What hybrid identity is
Most organizations keep user accounts in on-premises **Active Directory (AD)** while their apps,
devices, and security controls live in **Microsoft Entra ID** (the cloud directory). Hybrid identity
is the bridge: a **synchronization engine** copies AD users, groups, and contacts into Entra ID, and
an **authentication method** decides where the password is actually validated. Done well, a user has
one identity and one password that works on-premises and in the cloud. Done badly, you get duplicate
accounts, broken sign-in, and devices that will not join.

## How it works (the moving parts the team must master)
1. **Synchronization engine** — either **Entra Connect Sync** (full-featured, runs on a dedicated
   server) or **Entra Cloud Sync** (lightweight agent, cloud-driven). It copies AD objects to Entra
   ID on a schedule.
2. **Sync scope** — domain and organizational-unit (OU) filters decide which AD objects are in scope,
   keeping test/service objects out of the cloud.
3. **Source anchor** — the immutable attribute that ties an AD object to its Entra object (modern
   default: `ms-DS-ConsistencyGuid`). Choosing/mismatching it wrong causes duplicate or orphaned
   objects and painful re-joins.
4. **UPN / domain hygiene** — user principal names must use a public, verified, routable domain (not
   `.local`) or sign-in breaks and falls back to `onmicrosoft.com`.
5. **Authentication method** — **Password Hash Sync (PHS)**, **Pass-through Authentication (PTA)**, or
   **Federation (AD FS)**. Seamless SSO can accompany PHS/PTA.
6. **Hybrid Entra join** — registers domain-joined Windows devices into Entra ID so they satisfy
   Conditional Access and cloud management.
7. **Hybrid Conditional Access** — CA policies that require hybrid-joined / compliant devices, tying
   the on-premises device estate to cloud access decisions (requires Entra ID P1 — *verify*).
8. **Health monitoring** — sync status, last-sync time, sync errors, and agent health, so a stalled
   sync or auth-method fault is caught before users feel it.

## Connect Sync vs Cloud Sync (which engine)
- **Entra Connect Sync** — the full engine: complex filtering, device writeback, password writeback,
  and large or multi-forest environments. Runs on a dedicated server. Required for hybrid join +
  writeback scenarios.
- **Entra Cloud Sync** — a lightweight agent; the cloud does the heavy lifting. Suits simpler or
  disconnected-forest scenarios and multiple small domains, with fewer advanced options.
- The kit teaches how to choose, and inspects whichever is present in your environment.

## Authentication methods (choose one primary; PHS as backup)
- **Password Hash Sync (PHS)** — a hashed representation of the password syncs to Entra ID, which then
  validates sign-in itself. Simplest and most resilient; cloud sign-in survives an on-premises outage.
  Recommended default and recommended backup even when PTA/federation is primary.
- **Pass-through Authentication (PTA)** — lightweight agents validate the password against AD in real
  time; no password representation leaves the network. Requires the agents (and AD) to be available.
- **Federation (AD FS)** — hands authentication to an on-premises federation farm. Most complex and
  highest-maintenance; choose only for a specific requirement, and plan to migrate to cloud auth.

## The standard deployment model
Every solution in this catalog follows the same shape; the kit teaches the team to apply it to hybrid
identity work:

> **Assess → Configure → Pilot → Validate → Expand.**

- **Assess** — run the read-only discovery and health check; capture engine, source anchor, auth
  method, UPN hygiene, and sync health.
- **Configure** — plan the change (engine, scope, auth method, hybrid join) — in the kit this is
  rehearsed/inspected, not applied to production.
- **Pilot** — apply to a small pilot / staged-rollout group first (in HYBID for real work).
- **Validate** — confirm sync, sign-in, and hybrid join with the health check and What-If.
- **Expand** — widen scope in staged rings only after validation.

## Scope of this kit
- **In scope:** teaching hybrid identity concepts; guided, read-only / inspection-first labs on engine
  choice, sync scope, source anchor, UPN hygiene, PHS/PTA/federation trade-offs and the staged-rollout
  move, hybrid join, hybrid Conditional Access, and a health-check lab; a take-home runbook and a
  knowledge-check; read-only discovery, validation, reporting, health-check, and KQL analysis helpers.
- **Out of scope (by design — use the HYBID implementation solution):** installing/configuring Entra
  Connect, converting a domain's authentication method, changing production sync scope, or enabling
  hybrid join for the real fleet. This kit deliberately does **not** duplicate the HYBID build steps.
  Cross-reference:
  - **Hybrid Identity with AD & Entra Connect** (HYBID) — the production implementation.
  - **Entra Connect source-anchor / ConsistencyGuid / domain consolidation** — deep source-anchor work.
  - **Entra Cloud Sync provisioning troubleshooting** — Cloud Sync join/provisioning issues.
  - **Zero Trust Conditional Access baseline** (ENTZTCA) — for the CA side of hybrid CA.
  - **Enablement Kit — Identity Modernization** (EKIDMOD) — the broader modernization journey this fits into.
- **Not covered / deferred to the customer:** regulatory, records, legal, and data-classification
  determinations, and production change-approval sign-off. The kit provides technical understanding and
  read-only tooling, not those decisions.

## Authentication and connections used
- **Microsoft Entra admin center** (`https://entra.microsoft.com`) for portal labs.
- **On-premises tools** where a hybrid environment exists: the AD PowerShell module (RSAT) and, if
  present, the Entra Connect host (for read-only inspection of sync status).
- **Microsoft Graph PowerShell SDK** (`Microsoft.Graph`) for read-only discovery, validation, reporting,
  and health checks — using delegated, least-privilege read scopes.
- **Log Analytics / Microsoft Sentinel** (optional) for the KQL signal pack against `SigninLogs` —
  *requires diagnostic settings to export Entra logs; verify in your tenant.*
