# 1. Solution Overview — Endpoint Reporting & Dashboards for Intune and Configuration Manager

## What this solution is
This is a **repeatable endpoint reporting layer** that sits on top of the endpoint data you already
own in **Microsoft Intune** and **Microsoft Configuration Manager**. Instead of three consoles and a
hand-built spreadsheet, you get a defined set of **endpoint KPIs** (patch compliance, device
compliance, encryption coverage, app deployment success, device health) sourced the same way every
time, plus a scheduled **Microsoft Graph data export** so the numbers leadership and auditors see are
consistent and reproducible.

## How it works
1. You **define a fixed KPI set** with one authoritative data source per KPI, so the same question
   always returns the same number.
2. **Intune built-in reports** (`intune.microsoft.com` → **Reports**: Device compliance, Microsoft
   Defender, Windows updates, etc.) provide the on-screen numbers and ad-hoc views.
3. **Microsoft Graph data export** (`deviceManagement` reports / `exportJobs`) pulls the same report
   data on a schedule into CSV/JSON for dashboards and archiving — the same payload the portal shows,
   but automatable.
4. **Configuration Manager reporting** (Configuration Manager console → **Monitoring → Reporting**,
   backed by SQL Server Reporting Services / SSRS) covers any devices still managed by Configuration
   Manager so the fleet view is complete.
5. **Reporting-scope groups** in Microsoft Entra ID let you target reporting and exports to the right
   population (pilot first, then the whole fleet).
6. A **distribution schedule** delivers the consolidated KPI report to the people who need it on a
   recurring cadence.

## The endpoint KPI set (what "good" looks like)
| KPI | Definition | Primary source |
|---|---|---|
| Patch compliance % | Devices on the current/approved quality update ÷ all in-scope devices | Intune **Windows updates** report / Graph export; Configuration Manager software-update SSRS report |
| Device compliance % | Devices marked **Compliant** ÷ all in-scope devices | Intune **Device compliance** report / Graph export |
| Encryption coverage % | Devices with disk encryption (BitLocker/FileVault) on ÷ all in-scope devices | Intune **Encryption report** / Graph export |
| App deployment success % | App install **Succeeded** ÷ targeted installs | Intune **App install status** report / Graph export |
| Device health % | Devices checked in recently and not in error/quarantine ÷ all in-scope devices | Intune managed-device + Defender data / Graph export |

## Why a reporting layer (not just the consoles)
The consoles answer "right now, on this screen." A reporting layer answers "the same way, every
time, for everyone" — which is what an audit, a board slide, or a monthly operations review needs.
Defining the KPI and its single source removes the disagreement about whose number is right.

## Benefits
- **Trust** — one defined source per KPI; the same number every time it is asked.
- **Repeatable** — scheduled Graph exports reproduce the figures without manual console work.
- **Complete** — Intune and Configuration Manager devices both counted.
- **Audit-ready** — exports are archived with a timestamp and scope.
- **Targeted** — reporting-scope groups keep pilot and production numbers separate until validated.

## Limitations (be honest with buyers)
- This is a **reporting/visibility** layer over existing data — it does not change patching,
  compliance, or encryption policy; it measures them.
- Intune reports surface data already collected; a device that has not checked in recently is counted
  as last-known, not real-time.
- Configuration Manager reporting requires a working **SSRS** reporting point; this solution shows
  where to read it, not how to stand up Configuration Manager.
- Graph exports return the same data as the portal, so a KPI is only as accurate as the underlying
  Intune/Configuration Manager data feeding it.
- Dashboards can be built in your tool of choice (Power BI, Excel, etc.); this solution standardizes
  the **data and KPIs**, not a specific dashboard product.

## The standard deployment model
> **Define KPIs → enable/locate the built-in reports → set up the Graph export app → assemble the
> dashboard → schedule distribution → validate the numbers reconcile → expand.** The repeatable way:
> **Assess → Configure → Pilot → Validate → Expand**, with a pilot gate that proves the numbers
> reconcile before broad distribution.
