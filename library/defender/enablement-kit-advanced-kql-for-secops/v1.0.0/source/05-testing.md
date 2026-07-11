# Testing & Validation — Enablement Kit: Advanced KQL for SecOps

Validate the enablement kit against explicit **pass/fail gates** — both that the **environment** supports
the labs and that the **skills** landed. Run the scripts and walk the manual checks. The automated
gates are produced by **`WSKQL-Validate.ps1`**; readiness comes from **`WSKQL-Discovery.ps1`**,
running a lab query from **`WSKQL-RunLab.ps1`**, and cohort evidence from **`WSKQL-Report.ps1`**.

Each gate lists **What good looks like / How to test / If it fails**.

---

## Gate 1 — Advanced hunting is reachable and tables have data

- **What good looks like:** Advanced hunting loads; core Defender XDR tables return recent rows.
- **How to test:** Run `WSKQL-Discovery.ps1`; confirm the freshness section shows `DeviceProcessEvents`,
  `DeviceNetworkEvents`, `IdentityLogonEvents` (and others in scope) with rows in the last 24h.
- **If it fails:** Confirm the relevant pillars are onboarded/licensed (per-pillar solutions) and
  allow ingestion time; run labs on whatever tables are live meanwhile (**R2**).

## Gate 2 — The Sentinel cross-tool labs can run (where in scope)

- **What good looks like:** A Sentinel workspace is reachable and `SigninLogs` (or another connected
  table) returns rows.
- **How to test:** In **Sentinel → Logs** run `SigninLogs | where TimeGenerated > ago(24h) | count`;
  `WSKQL-Discovery.ps1` reports the workspace as reachable.
- **If it fails:** Run the Defender-only labs in full and defer Lab 5’s Sentinel half, or use a demo
  workspace; standing up Sentinel is a separate solution (**R3**).

## Gate 3 — Each lab query resolves and returns explainable results

- **What good looks like:** Labs 1–6 from `WSKQL-Labs.kql` run without schema errors and return
  results the learner can explain.
- **How to test:** Run a representative lab query read-only:
  `pwsh -File .\WSKQL-RunLab.ps1 -Lab 6`. It executes the pack’s Lab 6 query via Graph and returns
  rows. Repeat for other labs as needed.
- **If it fails:** Correct any table/column name to your tenant’s current schema (the pack uses
  representative names that evolve); re-run.

## Gate 4 — Learners can write joins and aggregations unaided

- **What good looks like:** In the capstone, learners reproduce the Lab 6 hunt from a blank editor —
  a filtered `where`, a `summarize`, and a `join` — and explain each stage.
- **How to test:** Observe the capstone; confirm the produced query matches the intent (not
  copy-paste) and the result set is small and justified.
- **If it fails:** Re-run Labs 3 and 4 (aggregations, joins) — these are the two skills most learners
  need reinforced — before repeating the capstone.

## Gate 5 — The lab detection exists and is alert-only

- **What good looks like:** `Detect-KQLLab-Pilot` exists as a custom detection rule that **generates
  an alert only** — no automatic remediation.
- **How to test:** **Advanced hunting → Custom detection rules** lists it; its response action is
  alert-only. `WSKQL-Validate.ps1` confirms.
- **If it fails:** Recreate it from the tuned Lab 6 query (Lab 7) and set the response to alert-only.
  Never wire a lab detection to a response action.

## Gate 6 — The saved-query set and workbook exist

- **What good looks like:** The `Hunt-KQLLab-Pilot` shared-query folder holds the lab queries, and
  `Workbook-KQLLab-Pilot` renders its tiles from live data.
- **How to test:** Confirm the shared-query folder and the workbook load and populate;
  `WSKQL-Validate.ps1` checks for their presence where the API allows.
- **If it fails:** Re-save the queries (Step 1.2) and rebuild the workbook (Lab 8).

## Gate 7 — The knowledge-check passes

- **What good looks like:** Each learner passes `Check-KQLLab-Pilot` (operators, join kinds,
  aggregation functions, choosing the right surface).
- **How to test:** Run `WSKQL-Validate.ps1`; it prints the knowledge-check score per the answer key.
- **If it fails:** Revisit the specific topic a learner missed; the knowledge-check maps each question
  to the lab that teaches it.

## Gate 8 — Read-only posture held; roles least-privilege

- **What good looks like:** No response action was taken during the enablement kit; learners held read/hunt
  roles and only the instructor could author the detection.
- **How to test:** Review **Permissions & roles** (R4) and confirm least-privilege; confirm the
  enablement kit plan and audit show read-only activity only.
- **If it fails:** Tighten role assignments; reaffirm the read-only posture (**R5**).

---

### Validation summary

| Gate | Check | Pass condition |
| --- | --- | --- |
| 1 | Advanced hunting + data | Core tables return recent rows |
| 2 | Sentinel labs runnable | Workspace reachable; `SigninLogs` returns (where in scope) |
| 3 | Lab queries resolve | Labs 1–6 run without schema errors |
| 4 | Joins/aggregations unaided | Capstone reproduced from a blank editor |
| 5 | Lab detection alert-only | `Detect-KQLLab-Pilot` exists, alert-only |
| 6 | Saved set + workbook | `Hunt-KQLLab-Pilot` + `Workbook-KQLLab-Pilot` present |
| 7 | Knowledge-check passes | `Check-KQLLab-Pilot` scored to threshold |
| 8 | Read-only + least-privilege | No response actions; roles scoped |

All gates pass ⇒ the cohort is enabled; proceed to **Expand** (operationalize the skills). Any fail ⇒
reinforce the relevant lab and re-check.
