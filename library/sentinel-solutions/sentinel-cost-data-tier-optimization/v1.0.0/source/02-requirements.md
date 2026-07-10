# 2. Requirements Guide — Microsoft Sentinel Cost & Data-Tier Optimization

Verify **every** requirement before configuring. Each entry: **Description / Why / Verify / Implement-if-missing.** Category-wide prerequisites (Azure subscription, Log Analytics workspace, Microsoft Sentinel enabled, RBAC, ingestion/retention cost plan, diagnostic-settings capability, change control) are in `global-requirements-sentinel-solutions.md`; do not repeat them — confirm them there first. The requirements below are specific to cost and data-tier optimization.

## 2.1 At least ~31 days of ingestion history in the workspace

- **Description:** The workspace should have roughly a month (or more) of representative ingestion so the audit reflects real, steady volume rather than a partial or atypical window.
- **Why:** Tiering, DCR, and commitment-tier decisions are only as good as the volume data behind them; a short or unusual window produces misleading recommendations.
- **Verify:** `Microsoft Sentinel`/`Log Analytics` → `Logs` → run `Usage | summarize sum(Quantity) by bin(TimeGenerated, 1d) | order by TimeGenerated asc` and confirm ~30 days of data. Run `SENTCOST-Audit.ps1`.
- **Implement-if-missing:** Wait until enough history accrues, or scope the audit to the window available and note it as an estimate to be revisited.

## 2.2 Read access to workspace usage and billing data

- **Description:** A role that can query the `Usage` table and read the workspace's pricing/retention configuration (Log Analytics Reader is enough for the read-only audit/report/forecast).
- **Why:** The audit, tiering analysis, and forecast all read the `Usage` table and the table/workspace configuration; without read access nothing can be measured.
- **Verify:** On the workspace, `Access control (IAM)` → confirm Log Analytics Reader (or higher). In `Logs`, `Usage | take 5` returns rows. Run `SENTCOST-Audit.ps1`.
- **Implement-if-missing:** Assign Log Analytics Reader (read-only work) or Contributor (to also apply changes) on the workspace, scoped per least privilege.

## 2.3 Contributor rights to change table plan, retention, and DCRs

- **Description:** Contributor (or a role that can edit table plans, table/workspace retention, and Data Collection Rules) — needed only for the *apply* steps, not the read-only audit.
- **Why:** Moving a table to Basic/Auxiliary, changing retention/archive, and editing a DCR transformation all require write access to those resources.
- **Verify:** On the workspace and the relevant DCRs, `Access control (IAM)` → confirm Contributor. Opening a table's `Manage table` blade shows editable plan/retention.
- **Implement-if-missing:** Assign the minimum write role at the workspace/DCR scope; prefer PIM-eligible activation over standing access.

## 2.4 An inventory of what your detections and hunting depend on

- **Description:** A list of which tables your active analytics rules, workbooks, and saved hunting queries actually query — so you never retier or filter data a detection needs.
- **Why:** Moving a table to Basic/Auxiliary or filtering it at the DCR can break a scheduled analytics rule or a hunt. Knowing the dependency is what makes the optimization safe.
- **Why tier limits matter:** Basic/Auxiliary tables cannot run scheduled analytics rules the same way Analytics tables can — a rule pointed at a retiered table may silently stop. *Verify current tier query limitations in your tenant.*
- **Verify:** `Microsoft Sentinel` → `Analytics` → review each active rule's query for the tables it uses; check workbooks and hunting queries. Run `SENTCOST-Tiering.ps1`, which cross-references high-volume tables against a supplied rule-table list.
- **Implement-if-missing:** Export the active analytics rules and note the tables each references; mark those tables as "keep on Analytics" in the tier decisions.

## 2.5 A retention and archive policy decision (owned by the customer)

- **Description:** A written decision on how long each class of data must remain queryable (interactive) and how long it must be retained at all (archive/long-term), with the compliance/records owner identified.
- **Why:** Retention drives a large share of cost, but how long data must be kept is a compliance/legal/records determination — the guide provides the levers and the cost of each, not the policy.
- **Verify:** A written retention policy exists per table class, with an owner. Run `SENTCOST-Validate.ps1` to compare configured retention against the policy.
- **Implement-if-missing:** Have the compliance/records owner set required interactive and total retention per data class; record it before changing any table's retention.

## 2.6 A budget owner and a target

- **Description:** The person who owns the Sentinel/Log Analytics budget and an agreed savings target or spend ceiling to optimize toward.
- **Why:** The forecast and commitment-tier decision need a target to be measured against; "cheaper" is not actionable without a number.
- **Verify:** The budget owner and target are documented. Run `SENTCOST-Forecast.ps1` to produce the current-vs-optimized monthly projection.
- **Implement-if-missing:** Identify the budget owner; agree a target or ceiling; record it with the forecast (`Cost Forecast - Workspace - Pilot`).

## 2.7 A pilot table chosen

- **Description:** A single high-volume, low-value table selected as the pilot for the first tier/DCR/retention change, with success criteria (cost drops and no dependent detection breaks).
- **Why:** The standard model proves the pattern on one table before touching the rest, so a mistake affects one table, not the whole workspace.
- **Verify:** The pilot table and its pass criteria are written down; the audit confirms it is high-volume and the dependency check confirms it is low-value to detections. Run `SENTCOST-Audit.ps1` and `SENTCOST-Tiering.ps1`.
- **Implement-if-missing:** From the ranked audit, pick the largest table that no active analytics rule queries as the pilot; record the gate before changing it.

---

## Checklist

- [ ] Azure subscription, Log Analytics workspace, and Microsoft Sentinel enabled — see global requirements
- [ ] ~31 days of representative ingestion history — `SENTCOST-Audit.ps1`
- [ ] Read access to `Usage`/billing data — `SENTCOST-Audit.ps1`
- [ ] Contributor rights for the apply steps (table plan, retention, DCR)
- [ ] Inventory of tables your detections/hunting depend on — `SENTCOST-Tiering.ps1`
- [ ] Retention/archive policy decided by the compliance/records owner — `SENTCOST-Validate.ps1`
- [ ] Budget owner and savings target agreed — `SENTCOST-Forecast.ps1`
- [ ] Pilot table chosen with pass criteria — `SENTCOST-Audit.ps1` / `SENTCOST-Tiering.ps1`
