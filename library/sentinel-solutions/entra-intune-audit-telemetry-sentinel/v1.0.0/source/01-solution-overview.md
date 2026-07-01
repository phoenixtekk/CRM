# 1. Solution Overview — Entra ID & Intune Audit Telemetry to Microsoft Sentinel

## What this solution is

Microsoft Sentinel is Microsoft's cloud-native SIEM. It runs on top of a Log Analytics workspace, ingests log data from many sources, retains it, and runs analytics rules that turn that data into alerts and incidents. This solution builds the specific pipeline that brings your identity and device audit telemetry into Sentinel: Entra ID and Intune audit logs are routed into a Log Analytics workspace, retention is set, and baseline analytics rules are enabled so the signal is centralized, retained, and alert-ready.

## How the pipeline works

1. A source generates audit telemetry — Entra ID produces sign-in and directory-change logs; Intune produces device, compliance, and enrollment audit events.
2. A diagnostic setting (for Entra ID) or a data connector routes the source's chosen log categories into the Log Analytics workspace. Routing the source is the switch that turns the pipeline on.
3. The Log Analytics workspace stores the data in tables (for example `SigninLogs`, `AuditLogs`) that you can query with KQL and retain for a defined period.
4. Microsoft Sentinel, enabled on that workspace, layers SIEM features on top: data connectors, analytics rules, hunting, and incidents.
5. Baseline analytics rules evaluate the incoming data and raise alerts/incidents on suspicious identity or device activity.
6. Retention keeps the data available for investigation and compliance for the window you choose.

## The log categories this pipeline routes

- Entra ID `SignInLogs` — interactive and non-interactive user sign-ins (the core identity signal).
- Entra ID `AuditLogs` — directory changes (role assignments, group and app changes, policy edits).
- Entra ID non-interactive / service-principal / managed-identity sign-in categories — for service and app activity (optional, higher volume).
- Intune device, compliance, and enrollment audit telemetry — device actions, compliance state changes, and enrollment events.

## What you can control

- Which log categories each source forwards (scope volume and cost by choosing only what you need).
- The destination Log Analytics workspace and its region (data residency).
- Retention per table or per workspace (interactive retention plus optional long-term/archive).
- Which baseline analytics rules are enabled and at what severity.
- The RBAC scope of who can read the workspace and manage Sentinel.

## Why this matters (the business case)

- Centralized signal — identity and device activity sits in one searchable place instead of two siloed portals.
- Retention for compliance — Entra ID and Intune keep audit data only for a short default window; routing it to the workspace lets you retain it for as long as policy requires.
- Alerting — baseline analytics rules turn raw logs into incidents, so risky sign-ins and directory changes are caught instead of buried.
- Investigation — when something happens, the full history is queryable with KQL rather than gone.
- Auditability — every object created is named to a convention, so the pipeline is documented and repeatable.

## Limitations (be honest with buyers)

- Sentinel and Log Analytics bill primarily on data ingested and retained; identity sign-in logs (especially non-interactive) can be high-volume, so scope and retention must be planned (see requirements).
- This solution routes the audit telemetry and enables baseline analytics; it is not a full detection-engineering or threat-hunting program (those build on this foundation).
- Diagnostic settings and connector availability depend on the source's licensing (for example some Entra ID log categories require a premium Entra plan).
- Data already routed to another destination should not be duplicated to the workspace without intent, or you pay to ingest it twice.

## The standard deployment model

> Stand up the workspace and Sentinel, enable Entra ID diagnostic settings and the data connector, route Intune audit telemetry, set retention, enable baseline analytics, validate ingestion on a pilot, then expand. Standard pattern: `Assess -> Configure -> Pilot -> Validate -> Expand`.
