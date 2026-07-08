# 5. Testing Guide — Data Lineage Implementation (Microsoft Purview)

Run after each configuration step. Every test is safe (read-only or a `-WhatIf` preview). Validate on
the `Data Lineage Pilot Scope – DGLINE – Stage1` before expanding to the estate.

## Test 1 — Data-plane access and account reachability
**Do:** Run `DGLINE-ScopeHealth.ps1 -Account <account>`.
**Expected:** The account endpoint `https://<account>.purview.azure.com` is reachable, a
`purview.azure.net` data-plane token is acquired, and the collections you have roles on are listed —
confirming the least-privilege data-plane roles are in place.

## Test 2 — Source + scan + lineage-capability inventory is complete
**Do:** Run `DGLINE-Discovery.ps1 -Account <account>`; compare against **Data Map → Data sources** in
the portal.
**Expected:** Every in-scope source is listed with its **last-scan status**, and each is correctly
flagged **automatic lineage (connected)** or **needs custom lineage** — matching what the portal shows.

## Test 3 — Endpoints are scanned (assets exist as lineage endpoints)
**Do:** For a pilot path, search the pilot source/sink assets in the portal catalog (or via
`DGLINE-Validate.ps1`, which resolves them by qualified name).
**Expected:** Both endpoints resolve to scanned catalog assets with a **completed** scan — the
prerequisite for any lineage edge between them is satisfied.

## Test 4 — Custom-lineage dry-run makes no changes
**Do:** Run `DGLINE-Configure.ps1 -Account <account> -MapPath .\LineageMap.csv -WhatIf`; afterward query
the pilot sink asset's lineage with `DGLINE-Validate.ps1`.
**Expected:** The dry-run prints the exact **Atlas `Process`** it would push (inputs/outputs qualified
names) and flags any unresolved asset; the lineage graph is **unchanged** — `-WhatIf` truly changed
nothing.

## Test 5 — Automatic lineage appears after a pilot pipeline run
**Do:** With the pilot ADF/Synapse source connected to Purview, run the pilot pipeline, then run
`DGLINE-Validate.ps1 -Account <account> -Asset '<pilot sink qualified name>'`.
**Expected:** The lineage query returns an **upstream** edge from the pilot source (produced by the
pipeline run), and the asset's **Lineage** tab in the portal renders source → process → sink. (Allow for
processing delay after the run.)

## Test 6 — Custom lineage renders after -Commit
**Do:** After `DGLINE-Configure.ps1 … -Commit` on the pilot custom path, run
`DGLINE-Validate.ps1 -Account <account> -Asset '<pilot sink qualified name>'` and open the Lineage tab.
**Expected:** The pushed `Process` entity appears as a lineage node with the intended inputs/outputs; the
graph matches `Data Lineage Coverage Map – DGLINE – Design`. The script reported the created GUID (for
rollback).

## Test 7 — Lineage is correct, not just present
**Do:** With a data owner, walk the pilot path's lineage graph end to end.
**Expected:** The upstream sources and downstream consumers are **accurate** (right authoritative source,
no missing or spurious hops) — confirmed by the owner, not just rendered.

## Test 8 — Coverage report reflects the estate
**Do:** Run `DGLINE-Report.ps1 -Account <account> -CsvPath .\LineageCoverage.csv`; review
`Data Lineage Coverage – DGLINE – Report`.
**Expected:** The report accurately splits in-scope assets into **with-lineage** vs. **without-lineage**
per collection/source, and each without-lineage item corresponds to a real gap (missing scan, missing
connection, or a custom-lineage `Process` still to push) recorded as a follow-up.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| **Pilot pass** | Tests 1–7 pass on `Data Lineage Pilot Scope – DGLINE – Stage1`: data-plane access confirmed, inventory complete, endpoints scanned, `-WhatIf` inert, automatic + custom lineage render, and the pilot graph is confirmed **accurate** by an owner |
| **Expand pass** | Test 8 passes across each expansion wave — coverage measured against the target, every gap recorded as a named follow-up — with automatic/custom lineage continuing to render as sources are added |
