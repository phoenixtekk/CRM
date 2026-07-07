# 5. Testing & Validation — Microsoft 365 Purview eDiscovery Administration

Run these against the **pilot matter** (`eDiscovery Case – Matter-A – Pilot` and its named
artifacts) before applying the pattern to any live matter. Each test states the **procedure** and the
**expected pass/fail**. `MSEDISC-Report.ps1` produces the evidence pack for most of them.

## Test 1 — Roles are least-privilege
**Procedure:** Run `MSEDISC-Discovery.ps1`; or Purview → **Settings → Roles & scopes** → check
**eDiscovery Manager** / **eDiscovery Administrator** membership.
**Pass:** Operators are in eDiscovery Manager; the lead is in eDiscovery Administrator; no standing
Global Admin is used to run matters.
**Fail:** Matters are run as Global Admin, or operators lack the role group (see Requirement 2.2).

## Test 2 — Case exists and is scoped
**Procedure:** Portal → **eDiscovery → Cases**; or `Get-ComplianceCase -Identity "eDiscovery Case –
Matter-A – Pilot"`.
**Pass:** The case exists with the exact name and the expected members/custodians.
**Fail:** No case, wrong name, or unexpected members.

## Test 3 — Search is scoped and returns expected hits
**Procedure:** Run `MSEDISC-Report.ps1` (or portal search **Statistics**) for `Content Search –
Matter-A-Keywords – Pilot`; **preview** a sample.
**Pass:** Item count/size are in the expected order of magnitude for the seeded pilot content;
preview shows on-topic items across the in-scope workloads (including Teams messages via the mailbox).
**Fail:** Zero hits when content was seeded, an implausibly large count (over-broad query), or a
workload with no hits that should have some (query/location scope wrong — refine per Implementation
Step 8).

## Test 4 — Query correctness (over/under-collection)
**Procedure:** Compare preview results against the known seeded pilot items.
**Pass:** In-scope items are found; obvious out-of-scope items (wrong date range, wrong subject) are
**not** returned.
**Fail:** Known in-scope items are missing (under-collection) or clearly out-of-scope items appear
(over-collection). Tune KQL/conditions and re-run `MSEDISC-Search.ps1 -Apply`.

## Test 5 — Hold is effective (preservation)
**Procedure:** Run `MSEDISC-Report.ps1` to confirm `Hold Policy – Matter-A – Pilot` /
`Hold Rule – Matter-A – Pilot` are **enabled**; then, as the pilot custodian, delete a seeded held
item and confirm it is still recoverable/preserved (recoverable items / preservation hold).
**Pass:** Hold policy and rule are enabled over the correct locations; the deleted item remains
preserved and discoverable.
**Fail:** Hold shows disabled/error, or a held item is permanently gone (see Troubleshooting).

## Test 6 — (Premium) Review set collected and analytics ran
**Procedure:** In the Premium case, open `Review Set – Matter-A – Pilot`; confirm items were added and
that **Analytics** (threading / near-dup) and **de-duplication** completed.
**Pass:** The review set contains the collected items; analytics/de-dup show completed and reduced
the duplicate/near-dup count.
**Fail:** Empty review set, or analytics failed/incomplete (check licensing — Requirement 2.1 — and
job status).

## Test 7 — Export is complete and defensible
**Procedure:** Run/inspect `Export – Matter-A – Pilot` (Premium) or the Content Search
`-Export` action; download the package and open the **export/results report** and the metadata
**load file**.
**Pass:** Export status **Completed**; item counts match the review-set/search estimate; the load
file and export report are present and readable.
**Fail:** Export errored or partial, item counts do not reconcile, or no load file/report (not
defensible — investigate before producing anything to legal).

## Test 8 — Audit trail present
**Procedure:** Run `MSEDISC-Report.ps1` (audit section) or Purview → **Audit** and search for the
case/search/hold/export activity for `Matter-A`.
**Pass:** Audit records exist for case creation, search runs, hold changes, and export.
**Fail:** No audit activity (audit disabled — Requirement 2.3 — or insufficient time to populate).

## Test 9 — (If configured) Compliance boundary enforced
**Procedure:** As a scoped eDiscovery Manager, attempt to search a population **outside** the
boundary; check `Get-ComplianceSecurityFilter` via `MSEDISC-Scope.ps1`.
**Pass:** The filter exists and the out-of-boundary search returns no out-of-scope custodians.
**Fail:** A scoped operator can search outside their boundary (filter missing/misconfigured).

---
## Validation gate summary (all must pass before a live matter)
- [ ] Roles least-privilege (Test 1)
- [ ] Case scoped correctly (Test 2)
- [ ] **Search scoped**, plausible hits, right workloads (Tests 3–4)
- [ ] **Hold effective** / preservation proven (Test 5)
- [ ] (Premium) Review set + analytics/de-dup complete (Test 6)
- [ ] **Export complete + defensible** (load file + report) (Test 7)
- [ ] Audit trail present (Test 8)
- [ ] Compliance boundary enforced, if configured (Test 9)
