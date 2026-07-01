# 3. Implementation Guide — Endpoint Reporting & Dashboards

Follow these steps **in order**. Intune work is in the **Microsoft Intune admin center**
(`https://intune.microsoft.com`); Configuration Manager work is in the **Configuration Manager
console**.

> **Model:** Define the KPI set once, source each KPI from the right built-in report, automate the
> pull with a Graph export, then validate the exported numbers reconcile against the consoles on a
> **pilot** scope before distributing broadly. The repeatable way:
> **Assess → Configure → Pilot → Validate → Expand.**

Objects you will create, named with the `<Purpose> – <Scope> – <Stage>` convention (reuse verbatim):

- `Endpoint Reporting Scope – Pilot – Stage` (Entra group)
- `Endpoint Reporting Scope – Fleet – Prod` (Entra group)
- `Endpoint Reporting Export – Tenant – Prod` (app registration)
- `Endpoint KPI Report – Fleet – Prod` (report definition)
- `Endpoint KPI Distribution – Leadership – Prod` (distribution schedule)

## Step 1 — Confirm readiness
1. Run `EPRPT-Discovery.ps1`. Confirm it signs in and reads each data source (managed devices,
   compliance, configuration, apps) and reports device counts. Resolve any source it cannot read
   before continuing.

## Step 2 — Define the KPI set
1. Adopt the five KPIs and their single sources from the Solution Overview (patch compliance %,
   device compliance %, encryption coverage %, app deployment success %, device health %).
2. Record the definitions in the report definition `Endpoint KPI Report – Fleet – Prod` (a documented
   sheet/notes file that the KPI report script and dashboard both reference).

## Step 3 — Create the reporting-scope groups
1. Run `EPRPT-Set-ReportingScopeTargeting.ps1` to create and populate
   `Endpoint Reporting Scope – Pilot – Stage` (a few representative devices) and
   `Endpoint Reporting Scope – Fleet – Prod` (the rest), or create them manually in Entra →
   **Groups → New group → Security** with those exact names.

## Step 4 — Locate and confirm the built-in Intune reports
1. Intune → **Reports**. Open each source report and confirm it renders for your tenant:
   - **Device compliance** (Reports → **Device compliance**) → device compliance %.
   - **Windows updates** (Reports → **Windows updates**) → patch compliance %.
   - **Endpoint security → Encryption report** (or Reports) → encryption coverage %.
   - **Apps → Monitor → App install status** → app deployment success %.
   - **Microsoft Defender** / **Device health** views → device health %.
2. Note that these are the on-screen, authoritative numbers you will reconcile the exports against.

## Step 5 — Register the Graph export app
1. Entra → **App registrations → New registration** → name it `Endpoint Reporting Export – Tenant – Prod`.
2. **API permissions → Add → Microsoft Graph → Application permissions** → add
   `DeviceManagementManagedDevices.Read.All`, `DeviceManagementConfiguration.Read.All`,
   `DeviceManagementApps.Read.All`, `Group.Read.All` → **Grant admin consent**.
3. Create a client secret (or upload a certificate). Store the tenant ID, client ID, and secret as
   environment secrets for the export script — never in the script file.

## Step 6 — Set up the scheduled export (dry run first)
1. Run `EPRPT-Export-Scheduled.ps1` with no schedule flag — it defaults to a **dry single run**:
   it requests the Intune report `exportJobs`, polls until ready, downloads the CSV/JSON, and writes
   it to `-OutputPath` (your reporting destination).
2. Confirm the export files land in the reporting destination and open cleanly.
3. Only after the dry run succeeds, schedule it (Windows Task Scheduler / Azure Automation) on your
   chosen cadence using the app registration credentials — this becomes
   `Endpoint KPI Distribution – Leadership – Prod`'s data feed.

## Step 7 — (If applicable) Locate the Configuration Manager reports
1. Configuration Manager console → **Monitoring → Reporting → Reports**.
2. Open the built-in **Software Updates – A Compliance** and device-collection compliance reports;
   confirm they render from the SSRS reporting point. These cover Configuration-Manager-managed
   devices and are folded into the consolidated view.

## Step 8 — Build the consolidated KPI report
1. Run `EPRPT-Report.ps1` against the **pilot** scope first (`-Group "Endpoint Reporting Scope – Pilot – Stage"`).
   It produces the consolidated endpoint KPI report (patch / compliance / encryption / app / health)
   from Graph, and a per-device CSV.
2. Point your dashboard tool (Power BI / Excel) at the report CSV + the scheduled export files to
   render the dashboard for `Endpoint KPI Report – Fleet – Prod`.

## Step 9 — Validate the pilot (the gate)
1. Run `EPRPT-Validation.ps1` for the pilot scope. It reconciles the report/export counts against the
   live Intune source counts and flags any KPI whose numbers do not match within tolerance.
2. Spot-check each KPI in the Intune **Reports** portal (Step 4) against the report figure.
3. **Do not distribute broadly** until every KPI reconciles. This is the pilot gate.

## Step 10 — Expand and distribute
1. Re-run `EPRPT-Report.ps1` against `Endpoint Reporting Scope – Fleet – Prod`.
2. Run `EPRPT-Validation.ps1` for the fleet scope and confirm reconciliation.
3. Turn on the recurring distribution `Endpoint KPI Distribution – Leadership – Prod` (the scheduled
   export from Step 6 plus dashboard refresh). Re-validate each cycle.

---
### Order of operations
`Discovery → Define KPIs → Scope groups → Locate built-in reports → Register export app → Dry export → Configuration Manager reports → Build KPI report → Validate pilot (gate) → Expand + distribute`
