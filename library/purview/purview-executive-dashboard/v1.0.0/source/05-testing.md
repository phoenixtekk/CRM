# 5. Testing & Validation — Microsoft Purview Executive Dashboard

Work through every gate. Each has a **method**, an **expected result (pass)**, and a **fail action**.
Tests are read-only — the scripts collect and render; they change no Purview policy. Do not distribute
the C-suite one-pager until every gate passes for the pilot draft, then re-confirm on each refresh.

> **Remember:** the dashboard is a **reporting layer**. These gates prove the page is **accurate,
> complete, and reconciles to its Purview sources** — they do not prove the underlying posture is
> *adequate* (that is a compliance/records/legal determination), nor do they create history the trend
> section did not yet accrue.

## Gate 1 — Sources are reachable and licensing is known
- **Method:** `OPSEXEC-Discovery.ps1` (and `OPSEXEC-Scope.ps1` for permission health).
- **Pass:** each KPI source is classified *reachable-by-API*, *portal-read*, or *not licensed*, with the licensing read from Graph `subscribedSkus`.
- **Fail:** assign the missing read role (Requirement 2.2) or license (2.1); a *not-licensed* source is shown as such on the page, not fabricated.

## Gate 2 — The metric definition is complete and approved
- **Method:** open `Exec Metrics – Compliance Signals – Definition`; run `OPSEXEC-Validate.ps1` against it.
- **Pass:** every KPI has a source, an owner, a threshold band, and (for portal-only values) a read date; the in-scope set (workloads/labels/policies/assessments) is named.
- **Fail:** complete the definition (Implementation Steps 2–3) and re-validate.

## Gate 3 — The pilot one-pager renders with all three sections
- **Method:** `OPSEXEC-Report.ps1 ... -Stage Pilot` → open `Exec Dashboard – Pilot – Stage1`.
- **Pass:** compliance posture, data risk, and trend sections all render; every KPI shows a value **or** an explicit *"not licensed / portal-read pending,"* each with a data-source and as-of timestamp.
- **Fail:** check the collector output for the empty KPI; confirm the source is reachable (Gate 1) and in the definition (Gate 2).

## Gate 4 — Every number reconciles to its Purview source
- **Method:** for each KPI, compare the page value to its portal blade (Compliance Manager, Content Explorer, DLP Alerts/Activity Explorer, retention policies, Insider Risk aggregate, DSPM) — Implementation Step 5.
- **Pass:** each value matches its source within the expected refresh/latency window, or is honestly labeled *"verify licensing/tenant."*
- **Fail:** fix the cause — wrong denominator/scope, stale portal value, a filter difference, or an unlicensed source being counted — and re-render.

## Gate 5 — Coverage denominators are correct
- **Method:** confirm label/retention coverage uses the agreed in-scope workloads/labels/policies (Requirement 2.5), via `OPSEXEC-Scope.ps1`.
- **Pass:** the coverage percentages use the defined denominator; adding/removing an in-scope item changes the percentage as expected.
- **Fail:** correct the in-scope set in the definition and re-collect.

## Gate 6 — Portal-only values are current (not stale)
- **Method:** `OPSEXEC-Validate.ps1` staleness check against each portal-only value's read date.
- **Pass:** Compliance Manager score, Insider-Risk aggregate, and DSPM recommendations were read within the refresh window and their read dates are recorded.
- **Fail:** the owner re-reads the value from the portal, updates the definition and read date, and re-validates.

## Gate 7 — Insider Risk is aggregate and de-identified
- **Method:** inspect the rendered page and the snapshot for any Insider Risk detail.
- **Pass:** only **aggregate counts by severity** appear — **no user names, no case detail**; the Insider Risk source is read under a **separate** role from the dashboard author.
- **Fail:** remove any identifying detail; confirm role separation (Requirement 2.2) before re-rendering.

## Gate 8 — Thresholds colour correctly
- **Method:** compare each KPI's colour band to the agreed green/amber/red thresholds in the definition.
- **Pass:** each KPI is coloured against its **agreed** threshold (a low score reads red, good coverage reads green) — the colours reflect the definition, not the tool's opinion.
- **Fail:** correct the threshold band in the definition and re-render.

## Gate 9 — Trend accrues across refreshes
- **Method:** run the collection on two (or more) cycles and inspect `Exec Trend – Monthly Snapshot – Baseline`.
- **Pass:** each run appends a dated snapshot; the trend section shows direction across the accrued points (and honestly shows "insufficient history" until enough points exist).
- **Fail:** confirm the scheduled collection is committed (Implementation Step 7) and appending to the trend store, not overwriting.

## Gate 10 — Scheduled refresh and distribution work end to end
- **Method:** let `Exec Collector – Purview Signals – Scheduled` run on cadence; confirm `Exec Dashboard – Posture-Risk-Trend – OnePage` reaches `Exec Dashboard – C-Suite – Distribution`.
- **Pass:** the schedule fires, the page rebuilds, validation is green, and the one-pager is delivered to the C-suite channel.
- **Fail:** check the scheduled task, the output path, and the distribution step; re-run `OPSEXEC-Validate.ps1`.

## Evidence to retain
- `OPSEXEC-Discovery.ps1` / `OPSEXEC-Scope.ps1` outputs (source + licensing inventory).
- The approved `Exec Metrics – Compliance Signals – Definition` (KPIs, thresholds, scope, portal-value owners).
- The reconciliation notes (Gate 4) showing each number matched to its source.
- `OPSEXEC-Validate.ps1` output per cycle and the accruing snapshots.

> Whether the posture the dashboard reports is **adequate** — a good-enough compliance score, sufficient
> label/retention coverage, an acceptable risk level — is a **compliance/records/privacy/legal
> determination**. These gates prove the page is **accurate**, not that the posture is **sufficient**.
