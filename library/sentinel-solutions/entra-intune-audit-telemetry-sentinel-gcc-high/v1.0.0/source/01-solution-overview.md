# 1. Solution Overview — Entra ID & Intune Audit Telemetry to Microsoft Sentinel (Government / GCC High)

## What this solution is

Microsoft Sentinel is Microsoft's cloud-native SIEM. It runs on top of a Log Analytics workspace, ingests log data from many sources, retains it, and runs analytics rules that turn that data into alerts and incidents. This solution builds the specific pipeline that brings your identity and device audit telemetry into Sentinel — but authored for the **US sovereign cloud (GCC High)**: Entra ID and Intune audit logs are routed into a Log Analytics workspace **in Azure Government**, retention is set, and baseline analytics rules are enabled so the signal is centralized, retained, and alert-ready.

This is the **Government (GCC High) edition**. In GCC High the admin portals, service endpoints, and some Sentinel capabilities differ from Commercial. A GCC High tenant is paired with **Microsoft Entra ID in Azure Government**, so Entra ID and Intune logs stay inside the sovereign boundary and land in a Sentinel workspace that also runs in Azure Government — there is no cross-cloud egress to Commercial Azure. This edition uses the `.us` portals and US Gov endpoints throughout, and calls out where a Commercial step would silently fail on a Gov tenant.

## Commercial vs GCC High — what's different

| Area | Commercial | GCC High (this edition) |
|---|---|---|
| Azure / Sentinel portal | `portal.azure.com` | `portal.azure.us` |
| Entra admin center | `entra.microsoft.com` | `entra.microsoft.us` |
| Intune admin center | `intune.microsoft.com` | `intune.microsoft.us` |
| Microsoft Defender portal (unified SecOps) | `security.microsoft.com` | `security.microsoft.us` |
| Sign-in / auth endpoint | `login.microsoftonline.com` | `login.microsoftonline.us` |
| Microsoft Graph endpoint | `graph.microsoft.com` | `graph.microsoft.us` |
| Graph PowerShell environment | `-Environment Global` (default) | `-Environment USGov` |
| Az PowerShell environment | `AzureCloud` (default) | `AzureUSGovernment` |
| Underlying identity plane | Entra ID in Commercial Azure | Entra ID in **Azure Government** |

Sources: Microsoft Graph national cloud deployments (learn.microsoft.com/graph/deployments); Microsoft Defender portal service support for US Government customers (learn.microsoft.com/unified-secops/gov-support); Connect-MgGraph reference.

**Feature-parity gaps that matter for this pipeline (verified against Microsoft's "Microsoft Sentinel feature support for Azure commercial/other clouds", learn.microsoft.com/azure/sentinel/feature-availability, dated 2026-05-14):**

- **Microsoft Entra ID connector is GA in Azure Government** — the core of this solution is supported. The Entra ID Protection connector and Office 365 connector are also GA in Gov.
- **Microsoft Defender XDR connector and Defender XDR incident integration are GA in Azure Government.** (In *China 21Vianet* they are not — that is a different national cloud, out of scope here.)
- **Repositories (CI/CD), Codeless Connectors Platform, SIEM migration experience, Summary rules, and SOC optimizations are NOT available in Azure Government.** If your Commercial runbook uses any of these to deploy or manage the pipeline, they will not be present on a GCC High tenant — deploy analytics and content from Content hub / Analytics templates directly instead.
- **Some threat-intelligence enrichments are not in Gov:** GeoLocation/WhoIs enrichment, URL detonation, and MDTI matching analytics are Commercial-only. TAXII and flat-file TI import are available.
- **`Hunts` (the newer hunting experience) is not in Azure Government;** classic Bookmarks, Queries, Livestream, Search, and Restore are.
- All of the above are point-in-time; **treat any capability not confirmed present in your tenant as "verify for GCC High"** before you promise it.

## How the pipeline works

1. A source generates audit telemetry — Entra ID (in Azure Government) produces sign-in and directory-change logs; Intune produces device, compliance, and enrollment audit events.
2. A diagnostic setting (for Entra ID) or a data connector routes the source's chosen log categories into the Log Analytics workspace **in Azure Government**. Routing the source is the switch that turns the pipeline on.
3. The Log Analytics workspace stores the data in tables (for example `SigninLogs`, `AuditLogs`, `IntuneAuditLogs`) that you can query with KQL and retain for a defined period.
4. Microsoft Sentinel, enabled on that workspace, layers SIEM features on top: data connectors, analytics rules, hunting, and incidents.
5. Baseline analytics rules evaluate the incoming data and raise alerts/incidents on suspicious identity or device activity.
6. Retention keeps the data available for investigation and compliance for the window you choose.

## The log categories this pipeline routes

- Entra ID `SignInLogs` — interactive and non-interactive user sign-ins (the core identity signal). *In Azure Government the Entra ID connector supports sign-in logs and audit logs.*
- Entra ID `AuditLogs` — directory changes (role assignments, group and app changes, policy edits).
- Entra ID non-interactive / service-principal / managed-identity sign-in categories — for service and app activity (optional, higher volume; confirm each category is exposed by your Gov tenant's Entra plan).
- Intune audit telemetry — `IntuneAuditLogs` (every change: create, update, delete, assign, remote actions) and `IntuneOperationalLogs` (enrollment success/failure), routed via Intune **Reports → Diagnostics settings** in `intune.microsoft.us`.

## What you can control

- Which log categories each source forwards (scope volume and cost by choosing only what you need).
- The destination Log Analytics workspace and its **Azure Government region** (data residency — Gov data stays on US soil).
- Retention per table or per workspace (interactive retention plus optional long-term/archive).
- Which baseline analytics rules are enabled and at what severity.
- The RBAC scope of who can read the workspace and manage Sentinel.

## Why this matters (the business case)

- Centralized signal — identity and device activity sits in one searchable place inside the sovereign boundary instead of two siloed portals.
- Retention for compliance — Entra ID and Intune keep audit data only for a short default window; routing it to the workspace lets you retain it for as long as policy (and CMMC / DFARS / FedRAMP obligations) require.
- Alerting — baseline analytics rules turn raw logs into incidents, so risky sign-ins and directory changes are caught instead of buried.
- Investigation — when something happens, the full history is queryable with KQL rather than gone.
- Sovereignty — the entire pipeline runs in Azure Government; nothing leaves the US Gov cloud.

## Limitations (be honest with buyers)

- Sentinel and Log Analytics bill primarily on data ingested and retained; identity sign-in logs (especially non-interactive) can be high-volume, so scope and retention must be planned (see requirements).
- This solution routes the audit telemetry and enables baseline analytics; it is not a full detection-engineering or threat-hunting program (those build on this foundation).
- **Some Commercial Sentinel features are absent in Azure Government** (see the parity table above); do not design the pipeline around a feature that is Commercial-only.
- Diagnostic settings and connector availability depend on the source's licensing (for example some Entra ID log categories require a premium Entra plan — G3/G5 Gov SKUs where applicable). Confirm the Gov SKU exposes each category.
- Data already routed to another destination should not be duplicated to the workspace without intent, or you pay to ingest it twice.

## The standard deployment model

> Stand up the workspace and Sentinel in Azure Government, enable Entra ID diagnostic settings and the data connector, route Intune audit telemetry from `intune.microsoft.us`, set retention, enable baseline analytics, validate ingestion on a pilot, then expand. Standard pattern: `Assess -> Configure -> Pilot -> Validate -> Expand`.
