# Solution Overview — Workshop: Advanced KQL for SecOps

## What this is

A complete, self-guided **enablement workshop** that takes an admin or SOC analyst from **KQL
fundamentals** to **advanced joins, aggregations, cross-table threat hunting, custom-detection
authoring, and workbook building** across **Microsoft Defender XDR advanced hunting** and
**Microsoft Sentinel**. It is delivered as concepts, **guided hands-on labs**, a **runnable KQL lab
pack**, a **take-home runbook**, and a **knowledge-check**.

It is a **skills** product — the outcome is people who can drive the tools. It is **adjacent to** the
catalog's **Threat Hunting hunt-library** solution: that product delivers and operates a curated,
maintained *hunt program*; this workshop builds the *capability* to hunt and to author detections.
The two are complementary and are cross-referenced, not duplicated.

## How the technology works (the mental model)

- **KQL is a tabular pipeline.** A query starts from a **table** (a data source), then passes rows
  through a sequence of **operators** joined by the pipe `|` — each operator takes a table in and
  emits a table out. Master a dozen operators (`where`, `project`, `extend`, `summarize`, `join`,
  `sort`, `top`, `count`, `parse`, `mv-expand`) and you can express almost any hunt.
- **Two query surfaces, one language.** The **Defender advanced hunting** surface
  (`security.microsoft.com → Hunting → Advanced hunting`) queries the Defender XDR schema —
  `DeviceProcessEvents`, `DeviceNetworkEvents`, `IdentityLogonEvents`, `EmailEvents`, `AlertInfo`,
  `AlertEvidence`, and more. **Microsoft Sentinel** (in the Azure/Defender portal) queries a **Log
  Analytics workspace** — `SecurityEvent`, `SigninLogs`, `AuditLogs`, `CommonSecurityLog`, plus any
  connected data. The **same KQL** runs in both; the **tables differ**. *Table and column names
  evolve and can differ by cloud — verify against your tenant's schema.*
- **Joins are how you correlate.** Real hunts span tables — "processes on a host that later made a
  suspicious network connection", "the sign-in that preceded a mailbox rule change". `join kind=inner
  / leftouter / leftanti` on a shared key (device id, account, `NetworkMessageId`, time-window) is
  the core hunting skill this workshop builds.
- **Aggregations turn events into signal.** `summarize` with `count()`, `dcount()`, `make_set()`,
  `arg_max()`, and `bin()` collapses raw events into rates, first-seen/last-seen, and per-entity
  rollups — the shape most detections and workbooks are built on.
- **From hunt to detection.** A hunting query that reliably isolates malicious behavior becomes a
  **custom detection rule** (Defender) or an **analytics rule** (Sentinel) that generates an alert on
  a schedule — the loop that turns a one-time find into durable coverage.
- **Workbooks visualize.** A saved query bound to a **workbook** tile (time chart, table, tile)
  turns a hunt into a monitorable, shareable view for the team.

## The standard deployment model

Every solution in this program follows the same five stages; here they structure the workshop:

1. **Assess.** Confirm the learners and tenant are ready — advanced-hunting access, a Sentinel
   workspace where used, and that the tables have data (run `WSKQL-Discovery.ps1`).
2. **Configure.** Create the learner cohort group `Grp-KQLWorkshop-Cohort`; agree a **safe,
   read-only lab posture**; load the KQL lab pack `WSKQL-Labs.kql` and save the starter shared query
   set `Hunt-KQLLab-Pilot`.
3. **Pilot.** Run the **guided labs** (Labs 1–8) with the cohort against real telemetry, **read-only**
   — fundamentals → filtering → aggregation → joins → cross-table hunting → detection → workbook.
4. **Validate.** Run the **capstone** hunt and score the **knowledge-check** `Check-KQLLab-Pilot`
   (`WSKQL-Validate.ps1`), and confirm the built detection `Detect-KQLLab-Pilot` is **alert-only**.
5. **Expand.** Fold the skills, the saved query set, the alert-only detection, and the workbook
   `Workbook-KQLLab-Pilot` into the **live hunting and detection program** — and decide, as an
   operations decision, which lab detections to promote to production.

## Scope — what this workshop covers

- **KQL fundamentals** — tables, the tabular pipeline, `where` / `project` / `extend` / `sort` /
  `take` / `count`, and reading the schema.
- **Aggregations** — `summarize`, `count` / `dcount` / `make_set` / `arg_max`, `bin()` time-bucketing.
- **Joins & correlation** — `join` kinds across Defender XDR tables and across Sentinel tables.
- **Cross-tool hunting patterns** — the same hunt expressed in Defender advanced hunting and in
  Sentinel; when to use which surface.
- **Detection authoring** — turning a tuned hunt into an **alert-only** custom detection / analytics
  rule.
- **Workbooks** — binding a query to a workbook tile for a monitorable view.
- **A take-home runbook + knowledge-check** — so the skills persist and can be proven.

## Out of scope (handled elsewhere)

- **Standing up the platforms.** Onboarding Defender XDR, connecting data to Sentinel, and licensing
  the pillars are the **Defender XDR onboarding**, **Sentinel deployment**, and per-pillar catalog
  solutions. This workshop **queries** those platforms; it does not deploy them.
- **A maintained, operated hunt library / program.** The **Threat Hunting hunt-library** solution
  delivers and runs a curated hunt program on a cadence. This workshop teaches the skill and ships a
  **learning** lab pack — it is not a replacement for that ongoing library.
- **SOAR / automated response.** Building Sentinel playbooks and automated response is the Sentinel
  SOAR catalog area; the labs stop at **alert-only** detections.
- **The security-operations decisions.** Which detections to promote, acceptable false-positive
  rates, and every production change are **the customer's SOC / security-leadership determinations**;
  this workshop provides the skill, the labs, and the data.

## Authentication and connections used

- **Microsoft Defender portal** (`security.microsoft.com`) for **Advanced hunting**, custom
  detection rules, and (where integrated) Sentinel.
- **Microsoft Sentinel** on a **Log Analytics workspace** for KQL over connected logs, analytics
  rules, and workbooks.
- **PowerShell** with **Microsoft.Graph** (security — advanced hunting via the
  `security/runHuntingQuery` endpoint) and, where the Sentinel/Log Analytics labs are run
  programmatically, the **Az** modules — used only to **run lab queries read-only**, check readiness,
  score the knowledge-check, and report progress.
- All helpers authenticate **interactively** with an MFA-capable account holding at least read/hunt
  scopes; **no credentials are stored in code**. Government-cloud tenants pass the matching endpoints
  — *verify endpoints for your cloud*.
