# Implementation

Build the pipeline in this order. Do **not** skip ahead to the whole fleet — the pilot (Steps 5–6)
proves the numbers before you widen scope. Every object you create is given an **exact name**; reuse
that name verbatim in later steps, in Testing, in Troubleshooting, and in the scripts.

**Naming convention used throughout** (`<Purpose> – <Scope> – <Stage>`):

| Object | Exact name |
|---|---|
| Entra app registration (export identity) | `App Estate Reporting – Graph Export` |
| Entra security group (pilot reporting scope) | `PILOT – App Estate Reporting` |
| Azure Storage container | `app-estate-exports` |
| Local export folder (self-hosted option) | `C:\AppEstateReporting\Exports` |
| Log Analytics workspace | `law-endpoint-ops` |
| Intune diagnostic setting | `Intune → law-endpoint-ops` |
| Power BI workspace | `Endpoint & App Reporting` |
| Power BI dataset | `App Estate Reporting – Dataset – v1` |
| Power BI report | `App Estate Reporting – Report – v1` |
| KPI set (documented) | `App Estate KPI Set – v1` |
| Scheduled task (export runner) | `App Estate Reporting – Nightly Export` |
| Azure Monitor action group | `AG – Endpoint Operations` |
| Azure Monitor alert rule (example) | `ALERT – App Failure Rate – High` |

---

## Step 0. Select your cloud (Commercial vs Government)

Before anything else, decide which cloud your tenant is in, because it changes every URL and one
script parameter.

- **Commercial:** portals at `intune.microsoft.com` / `portal.azure.com`, Graph at
  `graph.microsoft.com`, Power BI at `app.powerbi.com`. Scripts run with `-Environment Global`
  (the default).
- **GCC High:** portals at `endpoint.microsoft.us` / `portal.azure.us`, Graph at `graph.microsoft.us`,
  Power BI at `app.powerbigov.us`. Scripts run with `-Environment USGov`.
- **DoD:** as GCC High but Graph at `dod-graph.microsoft.us`; scripts run with `-Environment USGovDoD`.

The full substitution table is in Requirements R11. In every step below, use **your** cloud's URL. All
five scripts accept `-Environment` and route both `Connect-MgGraph` and the Graph base URL for you.

---

## Step 1. Confirm the KPI set and SLO (do this on paper first)

1. Open `01-solution-overview.md` and read the **KPI set** table and the **SLO** section.
2. Confirm the three SLO commitments with whoever owns the endpoint service (availability 97%,
   timeliness 90% in 96 h, currency 95% on n-1). Adjust the numbers to your reality **now**, before
   you build visuals against them — changing a target later means re-authoring alert thresholds.
3. Record the agreed numbers as the KPI set **`App Estate KPI Set – v1`** in your team wiki. Every
   later object references this by name.

**Why here:** the dashboard is only as useful as the definitions behind it. Fixing the definitions
first is what stops two people reading the same chart and computing "success" differently.

---

## Step 2. Create the pilot reporting-scope group

1. Go to **Entra admin center (`entra.microsoft.com`) > Identity > Groups > All groups > New group**.
2. **Group type:** Security. **Group name:** `PILOT – App Estate Reporting`.
   **Membership type:** Assigned.
3. **No members yet → Create.**
4. Open the group and add **5–10 representative devices** (a mix of your deployment rings) under
   **Members → Add members**. This is the population the pilot exports and dashboard cover.

**Why:** you validate the whole pipeline against a small, known set of devices whose real install
state you can read in the console by hand. Fixing definitions against a control group is far cheaper
than against the whole fleet.

---

## Step 3. Create the storage location

**Azure Storage (default):**

1. **Azure portal (`portal.azure.com`) > Storage accounts > Create** (or open an existing account).
2. Once the account exists, open it → **Data storage > Containers > + Container**.
3. **Name:** `app-estate-exports`. **Public access level:** Private (no anonymous access) → **Create**.
4. Grant access with least privilege under the container → **Access Control (IAM) > Add role
   assignment**:
   - **Storage Blob Data Contributor** → the export identity `App Estate Reporting – Graph Export`
     (added after Step 4) *and* the interactive operator who runs the extractor.
   - **Storage Blob Data Reader** → the Power BI refresh identity / gateway account.

**Self-hosted folder (alternative):** create `C:\AppEstateReporting\Exports` on the runner and
restrict its NTFS ACL to the scheduled-task service account (read/write) and the reporting owners
(read).

**Why:** decoupling extraction from presentation through durable storage is what makes the numbers
reproducible — Power BI refreshes from a stored snapshot instead of hammering Graph, and you keep an
auditable history of exactly what each report was built from.

---

## Step 4. Create the export identity and grant least-privilege scopes

The fastest and least error-prone way is the bootstrap script; the manual path is given as a fallback.

**Scripted (recommended):**

1. On the authoring workstation, open **PowerShell 7** as an account that is **Global Administrator**
   (needed once to grant admin consent).
2. Run:
   ```
   pwsh -File .\APPRPT-Bootstrap-ScheduledExport.ps1 -Environment Global -WhatIf
   ```
   Review the plan (it prints the registration name, the two application scopes from R4, and the
   scheduled task it will create). Then run it **without** `-WhatIf` to apply.
3. The script creates the app registration **`App Estate Reporting – Graph Export`**, adds a
   certificate credential, grants and admin-consents **`DeviceManagementApps.Read.All`** and
   **`DeviceManagementManagedDevices.Read.All`** (Application), and registers the scheduled task
   **`App Estate Reporting – Nightly Export`**.
4. Record the printed **Application (client) ID**, **Tenant ID**, and certificate thumbprint in your
   secret store.

**Manual (fallback):**

1. **Entra admin center > Identity > Applications > App registrations > New registration.**
2. **Name:** `App Estate Reporting – Graph Export`. **Supported account types:** single tenant →
   **Register**.
3. **Certificates & secrets > Upload certificate** (preferred) or **New client secret**; record it.
4. **API permissions > Add a permission > Microsoft Graph > Application permissions** → add
   **`DeviceManagementApps.Read.All`** and **`DeviceManagementManagedDevices.Read.All`** →
   **Grant admin consent for <tenant>** (both show green).
5. Return to Step 3 and assign this registration **Storage Blob Data Contributor** on
   `app-estate-exports`.

**Why:** app-only auth with **read-only** application scopes is the correct least-privilege posture
for an unattended reporting pipeline — it can read the whole estate but can never change a policy,
assignment, or device.

---

## Step 5. Run the first export by hand (pilot)

1. Open **PowerShell 7** as the interactive operator (delegated scopes from R3).
2. Extract install status for the pilot apps:
   ```
   pwsh -File .\APPRPT-Export-AppInstallStatus.ps1 -Environment Global `
        -OutputPath C:\AppEstateReporting\Exports -Format Both
   ```
   This connects to Graph, reads every app's `deviceStatuses`, and writes
   `app-install-status_<yyyyMMdd-HHmm>.csv` and `.json` to the output path (or, with
   `-BlobContainer app-estate-exports`, straight to Azure Storage).
3. Generate the supporting datasets:
   ```
   pwsh -File .\APPRPT-Report-TopFailures.ps1     -Environment Global -Top 20 -OutputPath <path>
   pwsh -File .\APPRPT-Report-VersionDrift.ps1    -Environment Global -OutputPath <path>
   pwsh -File .\APPRPT-Generate-KPISnapshot.ps1   -Environment Global -OutputPath <path>
   ```
4. Open the CSVs. Confirm the row counts look sane and the pilot apps you know about appear.

**Why:** a manual run proves the identity, scopes, and storage all work before you automate. If the
scheduled task later produces nothing, you already know the moving parts are sound.

---

## Step 6. Validate the export against the console (the trust gate)

This is the most important step. **Do not build the dashboard until the export matches the console.**

1. Pick one pilot app. In **Intune admin center > Apps > All apps > (the app) > Monitor > Device
   install status**, note the counts: Installed, Failed, Not applicable, Pending.
2. Open `app-install-status_*.csv`, filter to that app, and count the same states.
3. They should match (allow for a small drift if devices checked in between the two reads). If they
   diverge materially, resolve it now — the usual cause is counting "applicable" differently (see
   Troubleshooting) — before any number reaches a leader's screen.
4. Cross-check one KPI: open the KPI snapshot CSV, read **Install success rate** for that app, and
   confirm it equals `installed ÷ (installed + failed)` from the console counts.

**Pass gate:** console counts and export counts agree for the pilot app, and the KPI snapshot's
success rate matches the hand calculation. Only then proceed.

---

## Step 7. Author the Power BI dataset

1. Open **Power BI Desktop** → **Get data**.
   - **Azure Storage:** choose **Azure > Azure Blob Storage**, enter the account, select the
     `app-estate-exports` container.
   - **Folder:** choose **Folder**, point at `C:\AppEstateReporting\Exports`.
2. In **Power Query**, combine the `app-install-status_*` files into one table; set data types (dates
   as Date/Time, counts as Whole Number). Do the same for the drift and KPI-snapshot files as
   separate queries.
3. Add a small **KPI targets** table (enter data manually) holding the numbers from Step 1:
   `MetricName`, `Target`, `Direction` (higher-is-better / lower-is-better). This is what the visuals
   compare against, so a target change is a one-cell edit.
4. Build the model: relate install-status and drift by **AppId**; relate device rows to a **Ring**
   column derived from group membership (add a query that maps device → ring group).
5. Create the core **measures** (DAX), each mapping to `App Estate KPI Set – v1`:
   - `Install Success Rate = DIVIDE([Installed], [Installed] + [Failed])`
   - `Failure Rate = DIVIDE([Failed], [Applicable])`
   - `Detection Mismatch Rate = DIVIDE([InstalledButNotDetected], [Installed])`
   - `Version Drift % = DIVIDE([DevicesOffApprovedVersion], [DevicesWithApp])`
   - `Patch Currency n-1 = DIVIDE([DevicesOnCurrentOrPrevious], [DevicesWithApp])`
   - `Stale Device Rate = DIVIDE([DevicesStale7d], [DevicesTotal])`
6. **File > Save As** → name the file **`App Estate Reporting – Dataset – v1`**.

**Why:** one dataset with one set of named measures is the single source of truth. Every visual on
every page reads these measures, so no two pages can disagree.

---

## Step 8. Build the three report views

Author three report pages in the same file. Each page answers a specific audience's question.

**Page 1 — Executive view** (answers "are we meeting our promises?"):

1. Three **KPI / card** visuals for the SLO: **Availability** (Install Success Rate vs 97% target),
   **Timeliness** (P90 time-to-deploy vs 96 h), **Currency** (Patch Currency n-1 vs 95%). Colour each
   by whether it meets target (conditional formatting off the KPI targets table).
2. One **error-budget gauge**: budget remaining in the rolling 30-day window.
3. One **trend line**: overall install success rate over time (needs a few days of export history to
   populate).
4. Keep it to a single screen. No per-app tables here — executives get status, not detail.

**Page 2 — Operations view** (answers "where do I spend my day?"):

1. A **bar chart**: failure count by app (top 15), sorted descending — the day's work queue.
2. A **matrix**: failure rate by **ring** × app, conditionally formatted red where a ring exceeds
   3% or is more than 2× another ring.
3. A **column chart**: detection mismatch rate by app (the "installs but reports failed" apps).
4. A **card row**: stale device rate, pending installs older than 96 h.

**Page 3 — Per-app drill-down** (answers "what's wrong with THIS app?"):

1. A **slicer** at the top to pick one app.
2. Cards: Install Success Rate, Failure Rate, Version Drift %, Adoption (with its confidence label
   from the overview caveat).
3. A **table** of failing devices for the selected app: device name, ring, last check-in, install
   state, detection state — this is the list you hand to the troubleshooter.
4. A **version histogram**: device count by installed version, with the approved version marked.

Configure **drill-through** from Page 2's app bar to Page 3 filtered to that app, so one click on a
red bar lands the operator on the drill-down for exactly that app.

---

## Step 9. Publish, share, and schedule refresh

1. In Power BI Desktop → **Publish** → select the workspace **`Endpoint & App Reporting`**.
   *(Government cloud: sign Desktop into `app.powerbigov.us` first.)*
2. The published report is named **`App Estate Reporting – Report – v1`** and its dataset
   **`App Estate Reporting – Dataset – v1`**.
3. In the Power BI service, open the dataset → **Settings > Scheduled refresh**:
   - Configure the **data source credentials** (the Storage Blob Data Reader identity from Step 3; for
     an on-prem folder, install and bind an **on-premises data gateway**).
   - Set **refresh twice daily** (for example 06:00 and 18:00), after the nightly export window.
4. Share to consumers via **Viewer** role on the workspace, or publish an **app** from the workspace
   for the wider audience.

**Why:** scheduled refresh from stored exports is what makes the dashboard "living" without anyone
touching it, and workspace roles are how you keep the raw failing-device data on a need-to-know basis.

---

## Step 10. Turn on the nightly export

1. Confirm the scheduled task **`App Estate Reporting – Nightly Export`** exists (created in Step 4).
   Open **Task Scheduler** on the runner and check it points at
   `APPRPT-Export-AppInstallStatus.ps1` with the export identity, `-Environment` for your cloud, and
   the `-BlobContainer app-estate-exports` (or `-OutputPath`) target.
2. Set the trigger to run nightly at a quiet hour **before** the Power BI refresh times from Step 9.
3. Right-click → **Run** once to confirm it produces a fresh export file under the storage location
   using app-only auth (no interactive prompt).
4. Confirm the next scheduled Power BI refresh picks up the new file.

**Why:** the whole point of the pipeline is that nobody exports by hand again. The task is the engine;
Steps 5–6 already proved the payload is correct.

---

## Step 11. Configure alerting (Azure Monitor)

Alert only on conditions a human must act on **now**; everything else waits for the weekly review
(see Best Practices for the full alert-vs-review split).

1. Create the action group. **Azure portal > Monitor > Alerts > Action groups > + Create** → name
   **`AG – Endpoint Operations`** → add the endpoint on-call as an **Email/SMS/Push** or a **webhook**
   to your ticketing system → **Create**.
2. Create the example alert rule against the Log Analytics workspace `law-endpoint-ops` (requires R9).
   **Monitor > Alerts > + Create > Alert rule** → **Scope:** `law-endpoint-ops` → **Condition:** a
   **Custom log search** whose KQL computes install failure rate over the last 6 hours and fires when
   it exceeds **2×** the trailing 7-day baseline (or an absolute floor such as > 6%). Name the rule
   **`ALERT – App Failure Rate – High`**, severity **Sev 2**, action group **`AG – Endpoint
   Operations`**.
3. Add a second rule for **error-budget burn**: fire when more than half the 30-day error budget is
   consumed in the first 10 days of the window.
4. **Test it:** temporarily lower the threshold so the rule fires, confirm the action group notifies,
   then restore the threshold.

**Why:** paging on the wrong thing trains people to ignore the pager. Two well-chosen conditions —
a sudden failure spike and a budget-burn — are the only two that genuinely can't wait for Monday.

---

## Step 12. Stand up the supportability model

1. Assign each KPI an **owner** (Best Practices has the ownership table). Put the owner's name next to
   the KPI in `App Estate KPI Set – v1`.
2. Create the **triage queue** — a saved view/queue in your ticketing system named **`App Estate
   Triage`** — that the daily on-call works from. Alerts from Step 11 land here.
3. Define the **evidence pack** an app-failure ticket must carry (Best Practices lists the exact
   artifacts): app name + ID, ring, affected device list (from Page 3), install/detection state, and
   the relevant `IntuneManagementExtension` log excerpt. Add these as required fields/attachments on
   the ticket template.
4. Put the **cadences** on calendars: daily triage (15 min), weekly operational review (against Page
   2), monthly service review (against Page 1 and the SLO/error budget).

**Why:** a red number that has no owner and no queue is just decoration. This step is what converts
the dashboard into an operating rhythm.

---

## Step 13. Expand to the whole estate

1. Once the pilot pipeline has matched the console for a full week and the review cadences are
   running, widen scope: change the export scripts from the pilot app filter / `PILOT – App Estate
   Reporting` group to the full estate (remove the `-AppNameLike` / group filter).
2. Re-run Step 6's validation against **two or three** more apps across different rings to confirm the
   numbers still match at fleet scale.
3. Confirm scheduled-refresh duration and export runtime stay within their windows at full volume
   (Troubleshooting covers throttling and paging if they don't).
4. Announce the dashboard and the review cadences to the wider endpoint and support teams.

**Why:** widening only after the pilot proves out is what keeps a wrong definition from being
published to the whole organization at once.
