# 5. Testing & Validation Guide — Classification Reporting & Analytics (Microsoft Purview)

Run these tests after implementation and on a cadence thereafter. Each test has a **procedure**, a
**pass** signal, and a **fail** signal. Two conditions are **expected states, not failures** and are
called out explicitly: an **empty/baseline estate** (little is classified yet) and **ingestion lag**
(audit just enabled). The automated gate is **`CLSREPORT-Validation.ps1`**; the manual tests confirm the
portal experience.

> **Golden rule:** this solution reports; it does not classify. A low coverage number is a **finding to
> route to governance**, not a test failure. Tests validate that the *reporting* is correct and complete,
> not that the *estate* is fully classified.

## Test 1 — Licensing / surface availability
- **Procedure:** Open Content Explorer and Activity Explorer in the portal (paths in Implementation Step
  7). Run `CLSREPORT-Discovery.ps1`.
- **Pass:** Both explorers load; item-level content and activity are visible (E5/E5 Compliance present).
- **Fail:** A surface is missing or only aggregate cards show → **verify your licensing/tenant** (the
  plan gate). Note the gate in the report footnote; do not treat aggregate-only as a bug.

## Test 2 — Audit ingestion enabled
- **Procedure:** `Get-AdminAuditLogConfig | Select UnifiedAuditLogIngestionEnabled`, or read the
  Discovery output.
- **Pass:** `True`.
- **Fail:** `False` → enable via `CLSREPORT-Set-Reporting.ps1 -EnableAudit -Commit` (change-controlled),
  then re-test after the pipeline populates.

## Test 3 — Least-privilege role membership is correct
- **Procedure:** `CLSREPORT-Validation.ps1` (or `Get-RoleGroupMember "Content Explorer List Viewer"` and
  `... "Content Explorer Content Viewer"`).
- **Pass:** The intended analysts are in **List Viewer**; only the **minimal approved set** is in
  **Content Viewer**; no broad/unexpected members.
- **Fail:** Unexpected members (especially in Content Viewer, which exposes sensitive data) → remove with
  `Remove-RoleGroupMember` and investigate how they were added (role-group drift).

## Test 4 — Content Explorer returns coverage data
- **Procedure:** Run `CLSREPORT-Report.ps1 -Days 30`; open `coverage-by-tag.csv`. In the portal, drill a
  label/SIT card to a location.
- **Pass:** At least one tag returns ≥ 1 item, and the portal drill matches the export order of magnitude.
- **Fail (real):** Export errors or the analyst cannot drill despite List Viewer → re-check the role and
  `Export-ContentExplorerData` availability.
- **Expected, not fail:** All tags return 0 in a genuinely unclassified estate → record as **baseline
  coverage**; reference the labeling/SIT solutions.

## Test 5 — Activity Explorer / audit returns activity
- **Procedure:** Perform a known labeling action on a pilot item (apply/change a sensitivity label), wait
  for ingestion, then run `CLSREPORT-Report.ps1`; open `activity-summary.csv` and filter Activity
  Explorer to that user/label.
- **Pass:** The action appears as an activity row within the ingestion window.
- **Fail (real):** No activity ever appears though ingestion is on and time has passed → re-check audit
  config and the record-type filters.
- **Expected, not fail:** No rows immediately after enabling ingestion → **ingestion lag**; re-test later.

## Test 6 — Dashboard renders both views
- **Procedure:** Load `coverage-by-tag.csv` and `activity-summary.csv` into the chosen dashboard (Excel
  workbook or Power BI).
- **Pass:** The **Coverage** and **Activity** views render with the expected columns and refresh cleanly.
- **Fail:** Column/shape mismatch → confirm the CSVs came from the current `CLSREPORT-Report.ps1` (the
  dashboard binds to its column names).

## Test 7 — Revocation works (rollback proof)
- **Procedure:** Remove a test analyst from a role group (`Remove-RoleGroupMember`), have them refresh
  the portal.
- **Pass:** They lose the corresponding view (List and/or Content) after sign-in/token refresh.
- **Fail:** Access persists → confirm the removal targeted the right role group and the session was
  refreshed.

## Test 8 — Scheduled refresh + health check
- **Procedure:** Confirm the scheduled `CLSREPORT-Report.ps1` and `CLSREPORT-Scope-Health.ps1` runs
  produced fresh output and no drift/lag alerts.
- **Pass:** Fresh exports on cadence; health check clean (no unexpected Content Viewer members, audit
  current, tag inventory stable).
- **Fail:** Stale exports or a drift/lag alert → investigate the schedule and the flagged condition.

## Exit criteria (all must hold, with the two expected-states allowed)
- Both explorers available (or the licensing gate documented).
- Audit ingestion **True**.
- Role membership least-privilege and correct (Content Viewer minimal).
- Coverage export returns data **or** an explicit baseline note.
- Activity export returns data **or** an explicit ingestion-lag note.
- Dashboard renders both views; revocation proven; schedule + health check green.
