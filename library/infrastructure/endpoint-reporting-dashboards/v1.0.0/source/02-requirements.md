# 2. Requirements Guide — Endpoint Reporting & Dashboards

Verify **every** requirement before configuring. Each entry: **Description · Why · Verify ·
Implement-if-missing.** Category-wide prerequisites are in `global-requirements-infrastructure.md`.

Named objects this solution creates (reuse these names verbatim):

- App registration: `Endpoint Reporting Export – Tenant – Prod`
- Reporting-scope group (pilot): `Endpoint Reporting Scope – Pilot – Stage`
- Reporting-scope group (fleet): `Endpoint Reporting Scope – Fleet – Prod`
- KPI report definition: `Endpoint KPI Report – Fleet – Prod`
- Distribution schedule: `Endpoint KPI Distribution – Leadership – Prod`

## 2.1 Licensing
**Description:** Intune (Plan 1, included in M365 E3/E5 or Business Premium). Reporting is built in.
**Why:** Intune produces the device/compliance/update/encryption reports this solution consumes.
**Verify:** M365 admin center → **Billing → Licenses**.
**Implement:** Assign M365 E3/E5 or Business Premium (Intune included).

## 2.2 Devices reporting into Intune
**Description:** Targeted devices are enrolled in Intune and checking in.
**Why:** Reports only count enrolled, checked-in devices.
**Verify:** Intune → **Devices → All devices**; run `EPRPT-Discovery.ps1`.
**Implement:** Enable automatic enrollment; enroll/sync devices.

## 2.3 Reporting permissions (read-only Graph scopes)
**Description:** An operator/app with read scopes: `DeviceManagementManagedDevices.Read.All`,
`DeviceManagementConfiguration.Read.All`, `DeviceManagementApps.Read.All`, `Group.Read.All`.
**Why:** The discovery, validation, and report scripts read Intune data through Microsoft Graph.
**Verify:** Run `EPRPT-Discovery.ps1` (it confirms it can sign in and read each data source).
**Implement:** Sign in interactively with an Intune-read admin, or grant the app registration below.

## 2.4 Microsoft Graph export app registration
**Description:** An Entra app registration `Endpoint Reporting Export – Tenant – Prod` with
application permission `DeviceManagementManagedDevices.Read.All` (and the read scopes above),
admin-consented, used for unattended scheduled exports.
**Why:** Scheduled, unattended Graph `exportJobs` need an app identity, not an interactive user.
**Verify:** Entra → **App registrations** → the app exists with consented permissions; run
`EPRPT-Export-Scheduled.ps1` in its default dry single-run mode.
**Implement:** Entra → **App registrations → New registration** → name it exactly as above → **API
permissions → Add → Microsoft Graph → Application permissions** → add the read scopes → **Grant admin
consent** → create a client secret or certificate stored as an environment secret (never in code).

## 2.5 Reporting-scope groups
**Description:** Two Entra security groups: `Endpoint Reporting Scope – Pilot – Stage` and
`Endpoint Reporting Scope – Fleet – Prod`.
**Why:** Pilot validation must be measured separately from the full fleet until the numbers reconcile.
**Verify:** Entra → **Groups**; both exist. Run `EPRPT-Set-ReportingScopeTargeting.ps1` (read-mode).
**Implement:** Run `EPRPT-Set-ReportingScopeTargeting.ps1` to create/populate them, or create
manually (**Groups → New group → Security**).

## 2.6 A reporting destination
**Description:** A location to receive exports and host the dashboard (a secured file share/SharePoint
library plus your dashboard tool, e.g. Power BI or Excel).
**Why:** Scheduled exports and the consolidated KPI report need somewhere consistent to land.
**Verify:** Confirm the export path is writable; confirm the dashboard tool can read it.
**Implement:** Provision the share/library and point `EPRPT-Export-Scheduled.ps1` `-OutputPath` at it.

## 2.7 (If applicable) Configuration Manager reporting point
**Description:** A working Configuration Manager **Reporting Services point** (SSRS) for any
Configuration-Manager-managed devices.
**Why:** Devices still managed by Configuration Manager are reported via SSRS, not Intune.
**Verify:** Configuration Manager console → **Monitoring → Reporting → Reports** opens and renders a
built-in software-update/compliance report.
**Implement:** Install/repair the Reporting Services point role; confirm the SSRS URL resolves.

## 2.8 Defined KPI set agreed with stakeholders
**Description:** The five KPIs and their single source (see Overview) signed off by the report owner.
**Why:** A KPI without an agreed definition and source is where "whose number is right" starts.
**Verify:** The KPI definitions in `Endpoint KPI Report – Fleet – Prod` match this document.
**Implement:** Adopt the KPI table from the Solution Overview; record it in the report definition.

---
## Checklist
- [ ] Intune licensing assigned
- [ ] Devices enrolled and checking in — `EPRPT-Discovery.ps1`
- [ ] Read-only Graph scopes available — `EPRPT-Discovery.ps1`
- [ ] App registration `Endpoint Reporting Export – Tenant – Prod` consented
- [ ] Reporting-scope groups (Pilot / Fleet) created
- [ ] Reporting destination provisioned and writable
- [ ] (If applicable) Configuration Manager SSRS reporting point working
- [ ] KPI set defined and agreed
