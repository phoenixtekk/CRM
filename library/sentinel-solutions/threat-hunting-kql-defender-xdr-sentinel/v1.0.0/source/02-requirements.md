# Requirements — Threat Hunting with KQL: Microsoft Defender XDR & Sentinel

These are the **solution-specific** prerequisites for running a proactive hunt program. The **platform
baseline** — an Azure subscription, a Log Analytics workspace, Sentinel enabled, least-privilege roles,
an ingestion/retention plan, diagnostic-settings capability, and change control — is covered once in
**`global-requirements-sentinel-solutions.md`** (**G1–G7**). Read that first; the items below layer on
top of it and are not repeated here.

Each requirement is stated as **Description / Why required / How to verify / How to implement if
missing**.

---

## R1. Microsoft Defender XDR onboarded, with advanced hunting available

- **Description:** Microsoft Defender XDR (Defender for Endpoint / Identity / Office 365 / Cloud Apps as
  applicable) is onboarded so its telemetry populates the **advanced hunting** schema (e.g.
  `DeviceProcessEvents`, `DeviceNetworkEvents`, `IdentityLogonEvents`, `EmailEvents`, `CloudAppEvents`).
- **Why required:** Roughly half the delivered hunt library runs on the Defender XDR side; those hunts
  can only find what Defender ingests. Advanced hunting also requires the appropriate license
  (commonly Microsoft 365 E5 / Defender for Endpoint Plan 2 or equivalent) — *verify current licensing
  in your tenant.*
- **How to verify:** `security.microsoft.com` → **Hunting → Advanced hunting** → run
  `DeviceProcessEvents | where Timestamp > ago(1d) | count` → rows return. `THREATHUNT-Discovery.ps1`
  also reports which advanced-hunting tables have recent data.
- **How to implement if missing:** Onboard the relevant Defender XDR workloads and endpoints; confirm
  licensing; wait for telemetry to populate before hunting on that table.

## R2. A connected Sentinel workspace with the hunting tables populated

- **Description:** The Sentinel-side tables the library queries — e.g. `SigninLogs`, `AuditLogs`,
  `OfficeActivity`, `CommonSecurityLog`, and the Defender `Device*` tables **if** the Defender connector
  streams them to the workspace — have recent data.
- **Why required:** The Sentinel-side hunts (and longer-retention hunts beyond advanced hunting's ~30
  days) run against the workspace. A hunt against an empty table silently finds nothing.
- **How to verify:** Sentinel → **Logs** → `SigninLogs | where TimeGenerated > ago(1d) | count` (repeat
  per table). `THREATHUNT-Discovery.ps1` reports freshness for the expected Sentinel tables.
- **How to implement if missing:** Connect the missing sources first — use the *Deploy Microsoft
  Sentinel: Workspace, Data Connectors & Ingestion* solution. Note which platform holds which table so
  you run each hunt on the surface that has the data.

## R3. Least-privilege, read-only hunting access (the hunter RBAC group)

- **Description:** A scoped access model that lets hunters **query broadly but change nothing** — a
  security group `Threat Hunters - Tenant - Group` granted **Security Reader** (Defender portal /
  advanced hunting) and **Microsoft Sentinel Reader** (workspace). Promotion of a hunt to a detection is
  a separate, elevated action performed by a smaller set of admins (Sentinel Contributor / Defender
  security settings), not by every hunter.
- **Why required:** Hunting is inherently read-only; granting hunters standing write/response power
  violates least privilege and widens blast radius. Separating **hunt** (read) from **promote** (write)
  keeps the program safe and auditable.
- **How to verify:** In Entra → **Groups**, confirm `Threat Hunters - Tenant - Group` exists with the
  intended members; on the workspace **Access control (IAM)** it holds **Microsoft Sentinel Reader**;
  in the Defender portal the members have **Security Reader**.
- **How to implement if missing:** Create the group; assign **Microsoft Sentinel Reader** at
  workspace/resource-group scope and **Security Reader** in the Defender portal; keep a separate,
  smaller admin set for promotion. Prefer PIM-eligible activation for the elevated promotion role where
  Entra ID P2 is available — *verify licensing.*

## R4. An agreed hunt backlog and priority (which techniques matter)

- **Description:** A short, written statement from security leadership of **which ATT&CK
  tactics/techniques matter most** for your organization (crown-jewel systems, likely adversaries,
  recent threat intel), used to order the hunt backlog.
- **Why required:** You cannot hunt everything at once; hypothesis-driven hunting needs a **prioritized
  backlog**. Which techniques to hunt first is a **risk decision**, not a technical default.
- **How to verify:** Confirm a written, owned priority list exists (even a ranked shortlist of ATT&CK
  techniques is enough to start).
- **How to implement if missing:** Facilitate a short session to rank techniques by risk (map
  crown-jewel assets and current threat intel to ATT&CK). This is a **leadership determination**; the
  solution supplies the library and method to execute against it.

## R5. A findings-documentation home (hunt register + bookmarks)

- **Description:** A place to record each hunt's **hypothesis, scope, query, outcome, and decision** —
  the `Hunt Register - Tenant - Main` (a document, wiki page, or tracking list) — plus the use of
  **Sentinel bookmarks** to preserve evidence rows.
- **Why required:** A hunt whose result lives in a browser tab is lost. Documentation is what turns
  hunting from a one-off into a **program** — it prevents re-hunting the same ground and is the raw
  material for promotion and for the incident hand-off.
- **How to verify:** Confirm the register exists and has an owner; confirm hunters know to bookmark
  findings in Sentinel (**Hunting/Logs → Add bookmark**).
- **How to implement if missing:** Create the register (start from the template referenced in
  `03-implementation.md`); assign an owner; establish the bookmark convention `Bookmark-<Hunt>-Finding`.

## R6. A defined hunt-to-incident hand-off (the reactive boundary)

- **Description:** An agreed path for what happens when a hunt **confirms a true positive**: it becomes
  an **incident** and enters your reactive incident-response process — the companion *M365 & Azure
  Incident Response & Escalation Runbook*. Hunters do **not** take response actions themselves.
- **Why required:** Hunting is read-only by design. A confirmed finding must reach responders through a
  clean, documented hand-off — not an ad-hoc scramble, and not a hunter improvising containment without
  authority or a change record.
- **How to verify:** Confirm the hand-off is written down (who to notify, how to create the incident,
  what evidence to attach) and that it references your IR runbook.
- **How to implement if missing:** Document the hand-off (see `03-implementation.md`, Phase 3): promote
  the bookmark to a Sentinel **incident**, attach the evidence, and trigger the IR runbook's intake.

## R7. The PowerShell toolchain

- **Description:** A workstation with **Microsoft.Graph** (`Microsoft.Graph.Security`) for Defender XDR
  advanced hunting via `Invoke-MgSecurityRunHuntingQuery`, and the **Az** modules (`Az.Accounts`,
  `Az.OperationalInsights`, `Az.SecurityInsights`) for Sentinel — signed in with an MFA-capable admin.
- **Why required:** The delivered tools run the KQL hunt library across both platforms, discover the
  hunting surface, validate the program, and report metrics using these modules.
- **How to verify:** `Get-Module Microsoft.Graph.Security, Az.OperationalInsights, Az.SecurityInsights
  -ListAvailable` returns versions; `Connect-MgGraph -Scopes ThreatHunting.Read.All` and
  `Connect-AzAccount` both succeed.
- **How to implement if missing:** `Install-Module Microsoft.Graph, Az -Scope CurrentUser`; sign in.
  Consent the **`ThreatHunting.Read.All`** Graph scope for advanced hunting. For Government cloud,
  connect Graph with the matching national-cloud endpoint and Az with `-Environment AzureUSGovernment`
  — *verify the correct endpoints and scopes for your cloud.*

## R8. Awareness of advanced-hunting limits (schema, retention, quotas)

- **Description:** An understanding that Defender XDR advanced hunting has a **defined schema** (table
  and column names change as products evolve), **~30-day retention**, and **per-query and per-tenant
  rate/row limits**; the `runHuntingQuery` API has its own throttling.
- **Why required:** Hunts that assume a column that was renamed, a lookback beyond retention, or a
  result set beyond the row cap will fail or silently truncate — and a throttled API run looks like a
  "broken" script when it is really a quota.
- **How to verify:** In advanced hunting, hover a table to see its current columns; run a small
  `| count` first; note any truncation or throttling messages. *Verify current schema, retention, and
  limits in your tenant.*
- **How to implement if missing:** Keep hunts within the retention window, scope them (time, device,
  identity) before widening, and let the runner (`THREATHUNT-RunHuntLibrary.ps1`) handle paging/back-off
  — it treats limits as expected, not as errors.
