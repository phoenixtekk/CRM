# 5. Testing Guide — Risk & Compliance Dashboard (Microsoft Purview)

Run after the config is written and a pilot collection/render has completed (Implementation Steps 6–8),
and again after each scheduled run or added signal. Back each test with **`CMPDASH-Discovery.ps1`**
(readiness), **`CMPDASH-Scope.ps1`** (role/feed health), **`CMPDASH-Report.ps1`** (collect + render), and
**`CMPDASH-Validation.ps1`** (reconcile). All are read-only except the `-Commit` config write.

## Test 1 — Signal availability is reported honestly
**Do:** Run **`CMPDASH-Discovery.ps1`**.
**Expected:** Each of the eight signals is reported **present/enabled** or **not licensed / verify your
tenant**; E5-gated signals are flagged. No signal is reported as a number the tenant can't produce.

## Test 2 — Role separation holds
**Do:** Run **`CMPDASH-Scope.ps1`** as the collector identity.
**Expected:** The identity can read the **live** feeds (DLP/label/retention/audit) and is **NOT** shown
with Insider Risk / Communication Compliance investigator access; those feeds report
**"aggregate/owner-captured — not read by this account."**

## Test 3 — Unified audit-log ingestion state is correct
**Do:** Run **`CMPDASH-Discovery.ps1`**; check the Audit tile.
**Expected:** Ingestion **on** (or, if just enabled by `-Commit`, shown enabled with a "capturing from
<date>" note); Standard vs Premium and retention reported. If off, the DLP/label volume tiles correctly
show "no audit source."

## Test 4 — Config validates (tiles, thresholds, sources)
**Do:** Run **`CMPDASH-Set-Configuration.ps1 -WhatIf`**.
**Expected:** `RiskComplianceDashboard.config.json` parses; every in-scope signal has a metric, RAG
thresholds, a **source** (`live` / `owner-captured`), a cadence, and (for owner-captured) a named owner.

## Test 5 — Collection writes a normalized dataset
**Do:** Run **`CMPDASH-Report.ps1`**.
**Expected:** `RiskComplianceDashboard.data.json` is written with one record per in-scope signal —
value, RAG status, **source badge**, and timestamp; live feeds populated from Graph / S&C PowerShell,
owner-captured feeds populated from the config.

## Test 6 — Dashboard renders with RAG and source badges
**Do:** Open `RiskComplianceDashboard.html`.
**Expected:** One tile per signal with **value + RAG colour + source badge** (`live` vs `owner-captured`);
unlicensed/unreadable signals read **"not licensed / verify your tenant"**; the CSV mirrors the tiles.

## Test 7 — HR-sensitive tiles are aggregate-only
**Do:** Inspect the Insider Risk and Communication Compliance tiles in the HTML and the dataset.
**Expected:** **Counts only** (e.g. policies active, open alerts) — **no** user names, case content, or
reviewable items anywhere in the artifacts. Source badge = `owner-captured`.

## Test 8 — Live tiles reconcile against the portal
**Do:** Run **`CMPDASH-Validation.ps1`**; spot-check one live tile (e.g. DLP policy count) against Purview
→ **Data loss prevention → Policies**.
**Expected:** The dashboard's live values **match** the portal within tolerance; validation reports
**PASS** for each reconciled live signal, with any mismatch listed to fix.

## Test 9 — Owner-captured figures are current
**Do:** Run **`CMPDASH-Validation.ps1`**.
**Expected:** Each owner-captured tile has a **"captured on"** date within its cadence; any figure past
cadence is flagged **STALE** with the owner to chase. No owner-captured figure is silently defaulted.

## Test 10 — Scheduled run reproduces the result
**Do:** Trigger the scheduled **`CMPDASH-Report.ps1`**, then run **`CMPDASH-Validation.ps1`**.
**Expected:** The automated run produces the dataset + HTML/CSV under the service identity, and the
numbers still reconcile — proving the dashboard is repeatable, not a one-off.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| **Readiness pass** | Tests 1–3 pass (signals reported honestly; role separation holds; audit state correct) |
| **Build pass** | Tests 4–7 pass (config validates; dataset written; dashboard renders with source badges; HR tiles aggregate-only) |
| **Trust pass** | Tests 8–10 pass (live tiles reconcile; owner-captured figures current; scheduled run reproduces) |

> Do not distribute the dashboard for decisions until all three gates pass. Re-run Tests 5–10 after each
> scheduled run or added signal. **Regulatory/records/legal determinations remain deferred** — the
> dashboard evidences posture; it does not decide it.
