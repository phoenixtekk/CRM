# Requirements

Before you build the pipeline or run the scripts, confirm the items below. The **category-level
global requirements** (Entra tenant, Intune subscription, enrolled devices, supported Windows
baseline, network access) are in `global-requirements-intune-solutions.md` and are assumed here. This
file covers the requirements specific to **monitoring, reporting, and supportability for the
application estate**.

Each requirement is written as **Description / Why / Verify / Implement if missing.** Where a
Microsoft Graph permission is needed, the **exact scope string** is given. Where a paid SKU is
needed, it is called out so there are no surprises.

---

## R1. Intune role that can read apps and device install status

**Description:** An Entra/Intune role granting **read** access to **Apps**, their **assignments**,
and per-device **install status** — plus device inventory. **Intune Administrator** covers
everything; **Help Desk Operator**, or a custom role with **Managed apps → Read** and
**Organization → Read**, is enough for the read-only extractor, report, drift, and KPI-snapshot
scripts.

**Why:** Every metric reads app configuration, install/detection state, and detected-app inventory.
Without app-and-device read rights the console shows nothing and the scripts return empty results.

**Verify:** Sign in to `https://intune.microsoft.com`, open **Apps → All apps**, open any app →
**Monitor → Device install status**. If you see the app list and per-device status, you have read
access. For roles: **Tenant administration → Roles → All roles** and confirm your assignment.

**Implement:** **Tenant administration → Roles → All roles** → select **Help Desk Operator** (read)
or **Intune Administrator** → **Assignments → Assign** → add your account and a scope group.

---

## R2. Microsoft Entra app registration for unattended export (app-only auth)

**Description:** A dedicated Entra **app registration**, named **`App Estate Reporting – Graph
Export`**, with a client secret or (preferred) a certificate, used by the scheduled export to
authenticate to Graph **without a signed-in user**.

**Why:** A scheduled task cannot rely on an interactive `Connect-MgGraph` sign-in. App-only
(client-credentials) authentication with **application permissions** is what lets the export run
unattended overnight. Naming it consistently is what lets you audit and revoke it later.

**Verify:** Entra → **App registrations → All applications**; the registration
**`App Estate Reporting – Graph Export`** exists and shows a valid credential under **Certificates &
secrets** that has not expired.

**Implement:** Entra → **App registrations → New registration** → name it exactly **`App Estate
Reporting – Graph Export`** → **Register**. Then **Certificates & secrets → New client secret** (or
upload a certificate) and record the value in your secret store. The bootstrap script
(`APPRPT-Bootstrap-ScheduledExport.ps1`) creates this registration and grants the scopes in R4 for
you; do it by hand only if you cannot run the script as a Global Administrator.

---

## R3. Delegated Graph scopes for the read-only (interactive) scripts

**Description:** For the four read-only scripts run interactively by an operator, delegated Microsoft
Graph permissions: **`DeviceManagementApps.Read.All`** and
**`DeviceManagementManagedDevices.Read.All`**.

**Why:** The extractor, report, drift, and KPI-snapshot scripts read app definitions, assignments,
per-device install/detection state, and detected-app inventory through Graph. These are read scopes;
none of the four writes anything.

**Verify:** Run any read-only script; at the first `Connect-MgGraph` prompt, sign in and **consent**
to the listed scopes. If it returns data, access works. Confirm granted delegated permissions in
Entra → **Enterprise applications → Microsoft Graph Command Line Tools → Permissions**.

**Implement:** `Install-Module Microsoft.Graph -Scope CurrentUser`. Each script calls
`Connect-MgGraph` with the scopes it needs; an Intune Administrator can consent on first use. If your
tenant requires admin consent for the Graph Command Line Tools app, have a Global Administrator grant
it once.

---

## R4. Application Graph scopes for the unattended export identity

**Description:** For the app registration in R2, **application** (not delegated) Microsoft Graph
permissions, admin-consented: **`DeviceManagementApps.Read.All`** and
**`DeviceManagementManagedDevices.Read.All`**. If you also drive the Graph **exportJobs** report API
from the service identity, that same `DeviceManagementApps.Read.All` /
`DeviceManagementManagedDevices.Read.All` pair covers it.

**Why:** Application permissions are what let the export identity read the whole estate unattended.
Granting only **read** scopes to the automation identity is the least-privilege posture for a
reporting pipeline — it never needs to write.

**Verify:** Entra → **App registrations → `App Estate Reporting – Graph Export` → API permissions**;
both scopes are listed as **Application** type with a green **Granted for <tenant>** status.

**Implement:** App registration → **API permissions → Add a permission → Microsoft Graph →
Application permissions** → add the two scopes → **Grant admin consent for <tenant>**. The bootstrap
script does this for you.

---

## R5. Power BI Pro (or Premium/Fabric) licensing

**Description:** Each person who **publishes or refreshes** the dataset and **consumes** the report in
a Power BI workspace needs a **Power BI Pro** license (included in Microsoft 365 E5; otherwise a
per-user add-on). Sharing to a large read-only audience without per-user Pro requires **Power BI
Premium** capacity or a **Microsoft Fabric** capacity (F-SKU).

**Why:** Scheduled dataset refresh, workspace sharing, and app distribution are Pro/Premium features.
Power BI Desktop is free for authoring, but publishing to the service and scheduling refresh is not.

**Verify:** In `https://app.powerbi.com` your account can **create a workspace** and, on a dataset,
open **Settings → Scheduled refresh**. If those are available, licensing is sufficient for a small
team.

**Implement:** Assign **Power BI Pro** to the pipeline owner and each report consumer (Microsoft 365
admin center → **Users → Licenses**), or provision **Premium/Fabric** capacity for broad
distribution. **Government note:** Power BI has a **separate US Government cloud** — see R11.

---

## R6. A storage location for the exports

**Description:** A destination the scheduled export writes CSV/JSON to and Power BI reads from.
Default: an **Azure Storage** account with a blob container named **`app-estate-exports`**.
Alternative for a self-hosted runner: a local/UNC folder **`C:\AppEstateReporting\Exports`**.

**Why:** The pipeline decouples *extraction* (runs on a schedule) from *presentation* (Power BI
refresh). A durable, access-controlled storage layer between them is what makes the numbers
reproducible and auditable, and lets Power BI refresh without re-querying Graph.

**Verify:** For Azure Storage: `https://portal.azure.com` → the storage account → **Containers** →
`app-estate-exports` exists. For a folder: the path exists and the task's service account can write
to it.

**Implement:** Azure portal → **Storage accounts → Create** (or reuse one) → **Containers → +
Container** → name **`app-estate-exports`**, private access. Grant the export identity **Storage Blob
Data Contributor** on that container, and the Power BI refresh identity **Storage Blob Data Reader**.
For the folder option, create `C:\AppEstateReporting\Exports` and restrict its ACL to the task
account and the reporting owners.

---

## R7. Power BI Desktop for authoring the dataset and report

**Description:** The free **Power BI Desktop** app installed on the authoring workstation.

**Why:** The dataset (**`App Estate Reporting – Dataset – v1`**) and report (**`App Estate Reporting
– Report – v1`**) are authored in Desktop, then published to the service.

**Verify:** Power BI Desktop opens and can connect to your storage location via **Get data**.

**Implement:** Install from the Microsoft Store or `https://powerbi.microsoft.com/desktop`. Keep it
current; the connectors for Azure Blob and folder sources ship in-box.

---

## R8. A Power BI workspace for the reporting artifacts

**Description:** A dedicated Power BI **workspace** named **`Endpoint & App Reporting`** that holds
the dataset, report, and (optionally) a published app.

**Why:** A named workspace is the unit of access control and scheduled refresh. Publishing into "My
workspace" cannot be shared or governed properly.

**Verify:** `https://app.powerbi.com` → **Workspaces** → **`Endpoint & App Reporting`** exists and you
are at least a **Member**.

**Implement:** Power BI service → **Workspaces → New workspace** → name **`Endpoint & App Reporting`**
→ add the reporting owners as **Members**, consumers via a published app or **Viewer** role.

---

## R9. (Optional but recommended) Log Analytics workspace + Intune diagnostic settings

**Description:** An Azure **Log Analytics** workspace named **`law-endpoint-ops`** with Intune
**diagnostic settings** streaming operational logs to it, used for retention, KQL queries, and
Azure Monitor alerts.

**Why:** The Graph install-status data is a point-in-time snapshot. Diagnostic-setting logs give you
**history and alerting** — the ability to say "failure rate doubled at 02:00" and to page someone
automatically. This is what turns reporting into monitoring.

**Verify:** `https://portal.azure.com` → Log Analytics workspace **`law-endpoint-ops`** exists; and
Intune admin center → **Tenant administration → Diagnostic settings** shows a setting named
**`Intune → law-endpoint-ops`** sending logs.

**Implement:** Azure portal → **Log Analytics workspaces → Create** → name **`law-endpoint-ops`**.
Then Intune admin center → **Tenant administration → Diagnostic settings → + Add diagnostic setting**
→ name it **`Intune → law-endpoint-ops`** → select the log categories available in your tenant
(at minimum `AuditLogs`, `DeviceComplianceOrg`, `Devices`; add app/operational categories where your
tenant exposes them) → **Destination: Send to Log Analytics workspace → law-endpoint-ops → Save**.
Log ingestion and retention are billed by Azure Monitor (see Best Practices → cost).

---

## R10. PowerShell 7 with the Microsoft Graph SDK

**Description:** A workstation (and the export runner) running **PowerShell 7** with the
**Microsoft.Graph** module installed. PowerShell 5.1 works for the interactive scripts but
PowerShell 7 is recommended for the scheduled runner.

**Why:** All five scripts use the Microsoft Graph PowerShell SDK. The bootstrap and export scripts
use app-only authentication that is most reliable on PowerShell 7.

**Verify:** `$PSVersionTable.PSVersion` (expect 7.x) and `Get-Module Microsoft.Graph -ListAvailable`
(expect a version listed).

**Implement:** Install PowerShell 7 from `https://aka.ms/powershell`, then `Install-Module
Microsoft.Graph -Scope CurrentUser`. Run scripts with `pwsh -File .\<script-name>.ps1`.

---

## R11. Government cloud endpoints (GCC High / DoD) — if applicable

**Description:** If your tenant is in a **US Government** cloud, every service URL differs, and one
script parameter (`-Environment`) selects the cloud. The substitution table:

| Service | Commercial | GCC High | DoD |
|---|---|---|---|
| Microsoft Graph | `graph.microsoft.com` | `graph.microsoft.us` | `dod-graph.microsoft.us` |
| `Connect-MgGraph -Environment` | `Global` | `USGov` | `USGovDoD` |
| Intune admin center | `intune.microsoft.com` / `endpoint.microsoft.com` | `endpoint.microsoft.us` | `endpoint.microsoft.us` |
| Azure portal | `portal.azure.com` | `portal.azure.us` | `portal.azure.us` |
| Entra sign-in authority | `login.microsoftonline.com` | `login.microsoftonline.us` | `login.microsoftonline.us` |
| Power BI service | `app.powerbi.com` | `app.powerbigov.us` | `app.powerbigov.us` |

**Why:** Sovereign clouds are network-isolated. A script pointed at `graph.microsoft.com` from a GCC
High tenant fails to authenticate; a Power BI report built against the commercial service cannot be
published to the Government cloud. Endpoint parity also lags — some Graph report endpoints and Power
BI features arrive in the Government cloud later than in Commercial.

**Verify:** Confirm your cloud in the Azure portal (**Microsoft Entra ID → Overview** shows the cloud
instance). Reach the Government Graph endpoint from the runner, e.g. `Connect-MgGraph -Environment
USGov` returns a context.

**Implement:** Pass `-Environment USGov` (or `USGovDoD`) to every script; the scripts route
`Connect-MgGraph` and the Graph base URL accordingly. Author the Power BI dataset against the
Government storage endpoint and publish to `app.powerbigov.us`. Where a Graph report endpoint or a
Power BI feature is not yet available in your Government cloud, **verify for GCC High** against
Microsoft's US-sovereign-cloud documentation before relying on it — do not assume commercial parity.
