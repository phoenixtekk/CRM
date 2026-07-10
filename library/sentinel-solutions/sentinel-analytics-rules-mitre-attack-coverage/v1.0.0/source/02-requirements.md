# Requirements — Microsoft Sentinel Analytics Rules & MITRE ATT&CK Detection Coverage

These are the **solution-specific** prerequisites for building and tuning detections. The **platform
baseline** — an Azure subscription, a Log Analytics workspace, Sentinel enabled, least-privilege roles,
an ingestion/retention plan, diagnostic-settings capability, and change control — is covered once in
**`global-requirements-sentinel-solutions.md`** (**G1–G7**). Read that first; the items below layer on
top of it and are not repeated here.

Each requirement is stated as **Description / Why required / How to verify / How to implement if
missing**.

---

## R1. Telemetry is already flowing (a connected workspace)

- **Description:** The detection-driving tables the rules query — e.g. `SigninLogs`, `AuditLogs`,
  `AzureActivity`, `OfficeActivity`, `SecurityAlert`/`SecurityIncident`, `CommonSecurityLog`, Defender
  `Device*` — are populated in the workspace.
- **Why required:** A rule can only detect what the workspace ingests. Enabling a rule against an empty
  table produces a detection that will never fire — a silent blind spot.
- **How to verify:** Sentinel → **Logs** → run `<TableName> | take 10` for each table your target rules
  need; rows return. Or run `SENTRULE-Discovery.ps1`, which reports which expected tables have recent
  data.
- **How to implement if missing:** Connect the missing sources first — use the companion *Deploy
  Microsoft Sentinel: Workspace, Data Connectors & Ingestion* solution. Do not enable rules against
  tables with no data.

## R2. Roles to author rules, watchlists, and read incidents

- **Description:** **Microsoft Sentinel Contributor** (to create/edit analytics rules and watchlists) for
  the detection engineer, and at least **Microsoft Sentinel Responder/Reader** for the analysts who will
  triage the resulting incidents.
- **Why required:** Rule and watchlist authoring is a contributor action; triage needs responder/reader.
  Scoping keeps change rights small.
- **How to verify:** On the workspace / `RG-Security-Sentinel` → **Access control (IAM)** → the operating
  accounts hold the required Sentinel roles.
- **How to implement if missing:** Assign the roles at workspace/resource-group scope (prefer PIM-eligible
  for Contributor where Entra ID P2 is available — *verify licensing*).

## R3. The Content hub solutions for the detections in scope

- **Description:** The Content hub solution packages that carry the **rule templates** you intend to
  enable (e.g. the Microsoft Entra ID, Defender XDR, Office 365 solutions each ship detection templates),
  installed on the workspace.
- **Why required:** Rule templates only appear under **Analytics → Rule templates** once their Content
  hub solution is installed; you cannot enable a template you have not installed.
- **How to verify:** Sentinel → **Content hub** — the relevant solutions show **Installed**; Sentinel →
  **Analytics → Rule templates** lists templates for those products.
- **How to implement if missing:** Content hub → install the solutions matching your connected sources.
  Installing adds templates only; it does **not** enable any rule.

## R4. A named enrichment data set for watchlists

- **Description:** The reference data that the watchlists will hold: **VIP / high-value users**,
  **authorized admin source IPs**, **terminated users**, and **high-value assets** — as CSVs ready to
  import into `WL-VIPUsers-Tenant`, `WL-AuthorizedAdminIPs-Tenant`, `WL-TerminatedUsers-Tenant`, and
  `WL-HighValueAssets-Tenant`.
- **Why required:** Enrichment makes detections precise (fire only for sensitive accounts) and quiet
  (suppress known-good sources). Without this reference data, rules cannot key on context and stay
  noisy.
- **How to verify:** Confirm current CSVs exist and have an owner who keeps them current (a stale
  terminated-users list is a real risk).
- **How to implement if missing:** Produce the CSVs from HR/IT sources; assign an owner and a refresh
  cadence. They are imported as watchlists in `03-implementation.md`.

## R5. An agreed detection priority and false-positive tolerance

- **Description:** A short, written statement from security leadership of **which ATT&CK tactics/techniques
  matter most** for your organization and **what false-positive rate is acceptable** before a rule may
  create incidents (e.g. "≤ X% benign-closed over a Y-day pilot").
- **Why required:** Coverage and tuning are risk decisions, not technical defaults. Without an agreed
  priority you cannot rank gaps; without a tolerance you cannot decide when a rule is "tuned enough" to
  trust.
- **How to verify:** Confirm the written priority/tolerance exists and is owned by security leadership.
- **How to implement if missing:** Facilitate a short session to rank tactics by risk and set a
  false-positive tolerance. This is a **leadership determination**; the solution provides the measured
  coverage and per-rule noise data to inform it, not the decision.

## R6. A version-control repository for detection-as-code (optional but recommended)

- **Description:** A Git repository (GitHub or Azure DevOps) to hold exported rules, connected to
  Sentinel via **Repositories** (`Repo-Detections-Main`) or fed by the export script.
- **Why required:** Detection-as-code makes rules reviewable, diffable, and portable across
  workspaces/tenants, and gives you a rollback point. Without it, tuning history lives only in the portal.
- **How to verify:** Confirm a repo exists and the operating account can push to it; if using Sentinel
  Repositories, confirm the connection is configured.
- **How to implement if missing:** Create the repo; either configure Sentinel **Repositories** or use
  `SENTRULE-Export.ps1` to export rules to files you commit. *(Sentinel Repositories availability may
  differ by cloud — verify in your tenant.)*

## R7. The PowerShell toolchain

- **Description:** A workstation with the **Az** modules (`Az.Accounts`, `Az.SecurityInsights`,
  `Az.OperationalInsights`) and **Microsoft.Graph**, signed in with an MFA-capable admin.
- **Why required:** The five delivered tools use these modules and KQL to discover rules/templates, build
  coverage, report false-positive rates, validate, and export detections as code.
- **How to verify:** `Get-Module Az.SecurityInsights,Az.OperationalInsights -ListAvailable` returns
  versions; `Connect-AzAccount` succeeds.
- **How to implement if missing:** `Install-Module Az -Scope CurrentUser`; sign in. For Government cloud,
  connect with `-Environment AzureUSGovernment` — *verify the correct endpoints for your cloud*.
