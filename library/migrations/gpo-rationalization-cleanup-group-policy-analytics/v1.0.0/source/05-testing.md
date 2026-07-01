# 5. Testing Guide — GPO Rationalization & Cleanup with Group Policy Analytics

Run after classification and conflict resolution (Implementation Steps 4 to 7) and again before
expanding from the pilot scope. Reuse the artifact names from the Implementation Guide exactly.

## Test 1 — Every GPO is inventoried
**Do:** Run `GPORAT-Discovery.ps1`; compare the count to GPMC's GPO list.
**Expected:** Every GPO in the domain has an XML export and a row in
`Rationalization Register – All GPOs – Assess`.

## Test 2 — Readiness scored for every GPO
**Do:** Intune > **Reports > Group Policy analytics**; or run `GPORAT-Report.ps1 -UseGraph`.
**Expected:** Each imported GPO shows a migration readiness percentage and a
supported / not-supported / needs-review breakdown, captured in the register.

## Test 3 — Full rationalization coverage
**Do:** Run `GPORAT-Validation.ps1`.
**Expected:** 100% rationalization coverage — every GPO has a disposition (keep / retire /
consolidate / replace); the unclassified list is empty.

## Test 4 — Redundant audit settings resolved
**Do:** Run `GPORAT-Report.ps1` and review `Conflict Resolution Log – Audit & Overlaps – Configure`.
**Expected:** Each audit area has a single authoritative GPO; no duplicated audit settings remain in
the report.

## Test 5 — Conflicts resolved
**Do:** Run `GPORAT-Report.ps1`.
**Expected:** No setting is configured with different values across linked GPOs; every prior conflict
is recorded as resolved in the conflict log.

## Test 6 — Dead/duplicate links removed safely
**Do:** Run `GPORAT-Remediation.ps1` (preview), then with `-Apply` in the change window.
**Expected:** Preview lists exactly the retire/consolidate-away GPOs from the register; after apply,
those GPOs are unlinked (present, not deleted) and the retained exports remain as rollback.

## Test 7 — Sequenced backlog produced
**Do:** Run `GPORAT-Set-MigrationBacklogTargeting.ps1`.
**Expected:** `Migration Backlog – Sequenced – Configure` lists keep/consolidate GPOs ordered by
readiness, replace items tagged with a re-implementation surface, retire items excluded; and both
`Rationalization Scope – Devices – Pilot` and `Rationalization Scope – Devices – Broad` exist.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| **Pilot-scope pass** | Tests 1 to 6 pass for `Rationalization Scope – Devices – Pilot`; the backlog (Test 7) is produced and reviewed by the rationalization owner |
| **Expand pass** | Tests 1 to 7 pass across the full estate before the settings-migration phase begins |
