# Implementation — Enablement Kit: Advanced KQL for SecOps (Guided Labs)

This is the exact, ordered enablement kit — a sequence of **guided hands-on labs**. Every object you create
is **named** with a consistent convention — `<Purpose> – <Scope> – <Stage>` — and the same name is
reused in later labs, the knowledge-check, and the scripts. Run the labs against **real telemetry,
read-only**; the only change to the tenant is a single **alert-only** capstone detection.

> **Before you start:** confirm advanced-hunting access (**R1**), that tables have data (**R2**), a
> Sentinel workspace for the cross-tool labs (**R3**), the cohort and roles (**R4**), and the
> **read-only** posture (**R5**). This enablement kit **queries** the platforms; it does not deploy or
> reconfigure them.

**Named objects created in this enablement kit (verbatim — reused everywhere):**

| Object | Name | What it is |
| --- | --- | --- |
| Learner cohort group | `Grp-KQLEnablement Kit-Cohort` | Entra security group of enablement kit learners |
| Shared saved-query set | `Hunt-KQLLab-Pilot` | The lab queries saved to shared queries for reuse |
| Custom detection (capstone) | `Detect-KQLLab-Pilot` | Alert-only detection built from a tuned lab hunt |
| Workbook (lab) | `Workbook-KQLLab-Pilot` | Workbook built in the visualization lab |
| Knowledge-check | `Check-KQLLab-Pilot` | The scored end-of-enablement kit knowledge-check |

The runnable queries for every lab live in the delivered **`WSKQL-Labs.kql`** pack, organized by lab
number. You can paste them into Advanced hunting / Sentinel Logs, or run one read-only via
`WSKQL-RunLab.ps1`.

---

## Phase 0 — Assess (read-only, changes nothing)

### Step 0.1 — Confirm readiness

1. Sign in to the **Microsoft Defender portal** → `https://security.microsoft.com` and open
   **Investigation & response → Hunting → Advanced hunting**.
2. Run `DeviceInfo | take 1` — confirm it returns.
3. From PowerShell, inventory readiness across both surfaces:

   ```
   pwsh -File .\WSKQL-Discovery.ps1
   ```

   It reports which Defender XDR tables have recent data, whether a Sentinel workspace is reachable,
   and the cohort-group membership. **Read-only.**

### Step 0.2 — Create the learner cohort

1. In **Entra admin center** (`entra.microsoft.com`) → **Groups → New group**.
2. Type **Security**; **Name** `Grp-KQLEnablement Kit-Cohort`; add the learners.
3. Assign each learner a **read/hunt** role and reserve detection-authoring to the instructor (**R4**).

---

## Phase 1 — Configure (load the lab pack; nothing production yet)

### Step 1.1 — Load the KQL lab pack

1. Open `WSKQL-Labs.kql` (delivered). It is organized into labeled sections — **Lab 1 … Lab 8** plus
   the **Capstone**.
2. Confirm you can paste a query into **Advanced hunting** and run it, and (for the Sentinel labs)
   into **Sentinel → Logs**.

### Step 1.2 — Create the shared saved-query set

1. In Advanced hunting, save your first working query into **shared queries** under a folder named
   **`Hunt-KQLLab-Pilot`**. As each lab produces a good query, save it here so the cohort reuses one
   set. *Verify current shared-query behavior in your tenant.*

---

## Phase 2 — Pilot (the guided labs)

Run each lab with the cohort. Each lab states the **concept**, the **task**, and the **check**.

### Lab 1 — Fundamentals: tables and the tabular pipeline

- **Concept.** A query starts from a table and pipes rows through operators. Meet `take`, `where`,
  `project`, `sort`, `count`.
- **Task.** Run: `DeviceProcessEvents | where Timestamp > ago(24h) | project Timestamp, DeviceName,
  AccountName, FileName, ProcessCommandLine | sort by Timestamp desc | take 20`.
- **Check.** You can explain what each `|` stage does and reorder them.

### Lab 2 — Filtering and string operators

- **Concept.** `where` with `==`, `=~` (case-insensitive), `has`, `contains`, `startswith`, `in`,
  and `matches regex`. Filter early; filter cheaply (`has` before `contains`).
- **Task.** Find PowerShell executions with an encoded command:
  `DeviceProcessEvents | where FileName =~ "powershell.exe" | where ProcessCommandLine has "-enc"`.
- **Check.** You can narrow a noisy table to a specific behavior and read why `has` beats `contains`.

### Lab 3 — Aggregations with `summarize`

- **Concept.** `summarize` collapses rows into per-group signal — `count()`, `dcount()`,
  `make_set()`, `arg_max()`, and time-bucketing with `bin()`.
- **Task.** Per device, count distinct destination IPs in the last day:
  `DeviceNetworkEvents | where Timestamp > ago(1d) | summarize dcount(RemoteIP) by DeviceName | sort
  by dcount_RemoteIP desc`.
- **Task.** Trend logons by hour: `IdentityLogonEvents | summarize count() by bin(Timestamp, 1h)`.
- **Check.** You can turn raw events into a rate and a per-entity rollup.

### Lab 4 — Joins: correlating two tables

- **Concept.** `join kind=inner / leftouter / leftanti` on a shared key. Join a **small, filtered**
  left side to a larger right side.
- **Task.** Find processes on a host that then made an external network connection — join
  `DeviceProcessEvents` to `DeviceNetworkEvents` on `DeviceId` within a time window.
- **Check.** You can pick the right `join kind` and explain `leftanti` ("in A but not B") as a
  hunting tool (e.g. expected-but-missing).

### Lab 5 — Cross-tool hunting: Defender advanced hunting vs Sentinel

- **Concept.** The **same KQL** runs in both surfaces; the **tables differ**. Defender:
  `IdentityLogonEvents`, `EmailEvents`. Sentinel: `SigninLogs`, `SecurityEvent`.
- **Task.** Express "risky sign-ins in the last day" first in Defender advanced hunting, then in
  Sentinel against `SigninLogs`, and note the schema differences.
- **Check.** You can choose the right surface for a question and translate a hunt between schemas.
  *Table/column names differ and evolve — verify against your tenant.*

### Lab 6 — A real hunting pattern: suspicious sequence

- **Concept.** Chain filters, joins, and aggregation into a hunt that isolates a behavior (e.g.
  new-process → outbound connection → credential-access indicators).
- **Task.** Build the capstone-candidate query from the pack’s **Lab 6** section and tune it until it
  returns a **small, explainable** result set.
- **Check.** Every row in the result is one you can justify — the hunt is specific, not noisy.

### Lab 7 — From hunt to detection (alert-only)

- **Concept.** A tuned hunt becomes a **custom detection rule** that runs on a schedule and generates
  an **alert only** — no automatic response.
- **Task.** In Advanced hunting, open your Lab 6 query and choose **Create detection rule**. Name it
  **`Detect-KQLLab-Pilot`**, set the frequency and impacted entities, and set the response action to
  **generate an alert only**. *Do not enable any automatic remediation.*
- **Check.** `Detect-KQLLab-Pilot` exists and is alert-only.

### Lab 8 — Visualize: build a workbook

- **Concept.** A saved query bound to a workbook tile becomes a monitorable, shareable view.
- **Task.** In Sentinel (or a Defender report surface) create a workbook **`Workbook-KQLLab-Pilot`**
  with a time-chart of your Lab 3 aggregation and a table of your Lab 6 hunt. *Verify current
  workbook location/behavior in your tenant.*
- **Check.** The workbook renders both tiles from live data.

---

## Phase 3 — Validate (capstone + knowledge-check)

1. **Capstone hunt.** Each learner reproduces the Lab 6 hunt from a blank query editor, unaided, and
   explains the result.
2. **Knowledge-check.** Score the knowledge-check `Check-KQLLab-Pilot`:

   ```
   pwsh -File .\WSKQL-Validate.ps1
   ```

   It walks the pass/fail gates in `05-testing.md` — readiness, that the lab queries resolve, that
   `Detect-KQLLab-Pilot` is alert-only, and that the saved-query set and workbook exist — and prints a
   score.
3. **Cohort report.** Summarize progress for the group:

   ```
   pwsh -File .\WSKQL-Report.ps1 -OutputCsv .\wskql-cohort.csv
   ```

---

## Phase 4 — Expand (operationalize the skills)

1. **Adopt the query set.** Move the tuned queries from `Hunt-KQLLab-Pilot` into the team's standing
   shared-query library so hunts are reused, not reinvented.
2. **Promote detections deliberately.** If `Detect-KQLLab-Pilot` proves quiet and accurate, security
   operations may **document a decision** to promote it (renamed for production) — an **operations
   decision**, not a default this enablement kit flips.
3. **Feed the hunt program.** Hand the good queries to the **Threat Hunting hunt-library** solution
   so they join the maintained, operated program — the enablement kit builds skill; that product runs the
   library.
4. **Keep learning.** Schedule a follow-up on advanced topics (functions, `materialize`, `let`
   statements, parsing, Sentinel analytics-rule tuning) and re-run the enablement kit for new hires.

---

## Rollback / safe-off

- **Queries / labs:** read-only — nothing to roll back.
- **Custom detection:** disable or delete `Detect-KQLLab-Pilot` to stop it generating alerts; it is
  alert-only and never remediates.
- **Workbook / saved queries / cohort group:** delete `Workbook-KQLLab-Pilot`, the
  `Hunt-KQLLab-Pilot` folder, and `Grp-KQLEnablement Kit-Cohort` if the enablement kit was one-off; keep them if
  you are operationalizing.
