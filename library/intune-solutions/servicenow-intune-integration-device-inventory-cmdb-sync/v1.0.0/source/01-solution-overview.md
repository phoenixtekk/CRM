# 1. Solution Overview — ServiceNow ↔ Microsoft Intune Integration (Device Inventory & CMDB Sync)

## What this integration is
Microsoft Intune is the source of truth for who owns which managed device, its hardware, its
compliance state, and the apps installed on it. The ServiceNow **CMDB** is the source of truth the
service desk, change, incident, and asset processes run against. This solution connects the two so
**ServiceNow collects the Intune managed-device (and installed-app) inventory into the CMDB on a
schedule** — the Intune equivalent of the Workspace ONE (AirWatch) MDM feed many organizations run
today. When a technician opens an incident, the affected device, its owner, its compliance, and its
apps are already in ServiceNow, reconciled against every other discovery source.

This is an **inventory / data-feed** integration (Intune → ServiceNow CMDB). It is **not** a
management integration — ServiceNow reads Intune; it does not push policy back to Intune.

## How it works (the data flow)
1. ServiceNow authenticates to **Microsoft Graph** as a registered **Microsoft Entra application**
   (client-credentials OAuth 2.0 — Client ID, Client Secret, Tenant ID).
2. On a schedule, the connector's **data streams** call Graph and pull:
   - **Managed devices** — `…/deviceManagement/managedDevices` (hardware, OS, ownership, compliance,
     serial number, last check-in).
   - **Detected / installed applications** — `…/deviceManagement/detectedApps` (the app inventory per
     device).
3. The payload is staged and passed through ServiceNow's **Identification and Reconciliation Engine
   (IRE)**, which **matches each Intune device to an existing CI** (by identifier — typically serial
   number) or creates a new one, so records are **deduplicated**, not duplicated.
4. Devices land in the CMDB **hardware classes** — laptops/desktops in `cmdb_ci_computer` and mobile
   devices in the handheld/mobile class — with ServiceNow **Intune** recorded as the discovery source.
5. Downstream ServiceNow processes (Incident, Problem, Change, Request, Asset) now see a current,
   reconciled device record with its owner and compliance.

> **Verify the exact connector data-stream names and CMDB target classes against the current
> ServiceNow product documentation for your release** — ServiceNow has renamed and reworked these
> across releases (see §2 and §3). The functional model above is stable; the object names drift.

## The supported product path
The current, supported way ServiceNow ingests Intune managed-device data is the
**Service Graph Connector for Microsoft Intune** (published on the ServiceNow Store). It is built on
ServiceNow's **Integration Hub / Flow Designer** data-stream framework and writes through **IRE** into
the CMDB. It requires an **ITOM Visibility or ITOM Discovery** subscription (see §2). Where an
organization cannot license the Store connector, the same Graph endpoints and CMDB tables can be
driven with a **custom Integration Hub / REST + Transform Map** import — the Microsoft-side setup and
the CMDB target model in this guide apply to both. **Confirm the current product name, packaging, and
prerequisites on the ServiceNow Store / docs for your instance release before you buy or build.**

## Replacing the Workspace ONE (AirWatch) feed
Organizations moving from Workspace ONE to Intune already feed the CMDB from the **Service Graph
Connector for VMware Workspace ONE UEM** (the same Service Graph framework, same CMDB hardware
classes). This solution **re-establishes that same data feed from Intune** so the CMDB never goes
dark during the change:
- Stand up the **Intune** connector **in parallel** with the existing Workspace ONE feed.
- Because both feeds identify devices through **IRE on the same identifier (serial number)**, an
  Intune record **reconciles onto the existing Workspace ONE CI** rather than creating a duplicate.
- Once the Intune feed is validated and coverage matches, **retire the Workspace ONE connector's
  schedule** — the CI survives; only its discovery source changes.

## What data flows in
- **Device identity & hardware** — name, manufacturer, model, serial number, OS + version.
- **Ownership** — the Intune **primary user** / enrolled user, and corporate vs. personal ownership.
- **Compliance** — Intune compliance state and last check-in / last sync time.
- **Installed / detected applications** — the per-device app inventory from Intune.

## Benefits
- **One reconciled inventory** — Intune devices join every other discovery source under one CI per
  device, deduplicated by IRE.
- **Faster incident handling** — the device, owner, compliance, and apps are already on the ticket.
- **Continuity through the WS1 → Intune change** — the CMDB feed is re-established, not lost.
- **Least-privilege, read-only** — ServiceNow reads Intune through scoped, admin-consented Graph
  permissions; it changes nothing in Intune.

## Limitations (be honest with buyers)
- **Inventory only.** ServiceNow reads Intune device/app data; it does not manage Intune or push
  policy. Remote actions still happen in Intune.
- **Store connector needs ITOM.** The Service Graph Connector requires an **ITOM Visibility or
  Discovery** subscription; without it you use the custom Integration Hub import path.
- **Only enrolled devices appear.** A device that never enrolled in Intune is not in the Graph feed
  and will not appear in the CMDB until it enrolls.
- **App inventory ≠ license position.** The detected-app feed lists what is installed; it is **not**
  a software-entitlement or license-compliance calculation (see Out of scope).
- **Sovereign clouds differ.** US Gov (GCC High / DoD) tenants use different Graph and sign-in
  endpoints — see the Government note in §2/§3.

## Out of scope (deferred to dedicated solutions — referenced, not reproduced)
- **ServiceNow Software Asset Management (SAM) license workflow** — publisher/license models,
  entitlements, true-up, reclamation. Deferred to the dedicated **SNOWSAM** solution.
- **Software entitlement reconciliation** — matching installed apps to purchased entitlements and
  computing an effective license position. Deferred to the dedicated **SWDISC** solution.
- **The Workspace ONE → Intune device migration** itself (un-enrolling from WS1, enrolling into
  Intune, profile/app parity). Deferred to the **WS1PROG** Workspace ONE migration program. This
  solution re-establishes the **CMDB data feed** after that migration; it does not perform the
  device migration.

## The standard deployment model
> **Register the Entra app + consent the read-only Graph scopes → configure the ServiceNow
> connection → map the field/CMDB model and IRE identifier → schedule the import → assign a pilot →
> validate devices land and reconcile → expand.** repeatable pattern:
> **Assess → Configure → Pilot → Validate → Expand.**
