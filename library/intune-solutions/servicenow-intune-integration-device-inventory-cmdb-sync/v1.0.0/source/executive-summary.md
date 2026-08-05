# Executive Summary — ServiceNow ↔ Microsoft Intune Integration (Device Inventory & CMDB Sync)

## The situation
The organization is moving endpoint management from **Workspace ONE (AirWatch) to Microsoft Intune**.
Today, ServiceNow's **CMDB** is fed device and app inventory by the Workspace ONE data feed — the data
the service desk, incident, change, and asset processes depend on. When Workspace ONE goes away, that
feed goes with it. **This solution re-establishes the same CMDB device-inventory feed from Intune**, so
the CMDB never goes dark and every device stays reconciled to one record.

## What this delivers
A repeatable, self-guided implementation that connects **ServiceNow to Microsoft Intune** so ServiceNow
**collects managed-device (and installed-app) inventory into the CMDB on a schedule**:
- **Microsoft side:** a dedicated, least-privilege **Entra app registration** with **read-only**
  Microsoft Graph device-management permissions (admin-consented) that ServiceNow authenticates to.
- **ServiceNow side:** the **Service Graph Connector for Microsoft Intune** (or a custom Integration
  Hub import where ITOM isn't licensed) configured, mapped to the correct **CMDB hardware classes**,
  and reconciled through **IRE on serial number** so Intune devices **update existing CIs** — including
  the current Workspace ONE records — instead of creating duplicates.
- **Cutover:** run the Intune feed in parallel, validate coverage, then retire the Workspace ONE feed.

## Why it matters
- **Continuity through the migration** — the CMDB inventory feed survives the WS1 → Intune change.
- **One reconciled record per device** — deduplicated across every discovery source, keyed on serial.
- **Faster incidents** — device, owner, compliance, and apps are already on the ticket.
- **Secure by design** — read-only, scoped, admin-consented Graph access; ServiceNow changes nothing in
  Intune.

## What it is not (scope discipline)
This is an **inventory data feed**, not a management integration and not a licensing project. The
**device migration** (WS1PROG), the **SAM license workflow** (SNOWSAM), and **software entitlement
reconciliation** (SWDISC) are deferred to their dedicated solutions and referenced, not reproduced.

## Approach
**Assess → Configure → Pilot → Validate → Expand** — validated with included PowerShell scripts
(preflight, Intune export, sync/reconciliation comparison, coverage report, and a guarded credential
remediation) and explicit pass/fail gates. **Delivered as click-by-click documentation plus tested
scripts** — implementable by an in-house administrator at a fraction of consulting cost.

> **Accuracy note:** ServiceNow product/app, plugin, table, and field names change across releases;
> the guide flags each release-specific name to **verify against current ServiceNow documentation**.
> The Microsoft Graph scopes are verified against Microsoft Learn.
