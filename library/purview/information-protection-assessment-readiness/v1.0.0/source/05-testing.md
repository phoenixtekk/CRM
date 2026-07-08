# 5. Testing Guide — Information Protection Assessment & Readiness (Microsoft Purview)

Run after the discovery, scoring, and roadmap are produced (Implementation Steps 2–5) and after the one
simulation pilot (Step 6). Back each test with **`IPASSESS-ScopeHealth.ps1`** (connectivity/licensing),
**`IPASSESS-Discovery.ps1`** (estate), **`IPASSESS-Validation.ps1`** (scoring), and
**`IPASSESS-Report.ps1`** (gap register / roadmap). Everything except Test 8 is **read-only**.

## Test 1 — Sessions and read access are healthy
**Do:** Run **`IPASSESS-ScopeHealth.ps1`**.
**Expected:** `Connect-IPPSSession` and (if used) `Connect-MgGraph` are connected; `Get-Label` returns;
the report lists which capabilities are **readable** and flags any as **not available — verify your
licensing/tenant** (a valid finding, not a failure).

## Test 2 — Estate discovery is complete
**Do:** Run **`IPASSESS-Discovery.ps1`** (add `-IncludeSensitiveTypes`).
**Expected:** `Information Protection - Estate - Discovery` (CSV) lists labels (with encryption/marking
settings), label policies, DLP policies + rules (with Mode/Workload), auto-labeling policies (with Mode),
and — with the switch — sensitive information types. Nothing was changed in the tenant.

## Test 3 — Label posture is captured accurately
**Do:** Cross-check three labels from the CSV against Purview → **Information Protection → Labels**.
**Expected:** For each, `Enabled`, `EncryptionEnabled`, `EncryptionProtectionType`, and content-marking
flags match the portal; the label's `ContentType` (scope) is recorded. A label that classifies but does
**not** encrypt where it should is visible for review.

## Test 4 — Publishing/coverage gaps are visible
**Do:** Compare `Get-Label` count vs. the labels named across `Get-LabelPolicy` in the CSV; check Content
explorer for distribution.
**Expected:** Any **created-but-unpublished** label is identifiable; the scorecard's
publishing/coverage dimension reflects it. Unpublished labels are the classic "we have labels but nobody
uses them" gap.

## Test 5 — DLP coverage and mode are correct
**Do:** In the CSV, review each DLP policy's **Mode** and **Workload**; compare to the in-scope workloads
(Requirement 2.4).
**Expected:** Policies stuck in **Test** and in-scope workloads with **no DLP** are both surfaced;
**`IPASSESS-Validation.ps1`** marks a no-coverage in-scope workload **FAIL** and an all-test policy set
**WARN**.

## Test 6 — Scoring reflects the agreed baseline
**Do:** Run **`IPASSESS-Validation.ps1`**; review the PASS/WARN/FAIL per dimension.
**Expected:** Each of the six dimensions scores against the baseline targets (Requirement 2.5); changing
a target and re-running changes the score predictably. No dimension is silently skipped — a
licensing-gated one reports **not available**, not PASS.

## Test 7 — Gap register and roadmap are actionable
**Do:** Run **`IPASSESS-Report.ps1 -Section GapRegister`** then **`-Section Roadmap`**.
**Expected:** `Information Protection - Gaps - Register` has one row per gap with severity, recommended
action, effort, and owner-function; `Information Protection - Roadmap - Scorecard` ranks them into quick
wins vs. strategic with a per-dimension scorecard. Every gap maps to an accountable function
(compliance/records/security) — determinations are attributed, not decided.

## Test 8 — The pilot fix validates in SIMULATION (and nothing is enforced)
**Do:** Run **`IPASSESS-PilotRemediation.ps1 -Action AutoLabelSim -SensitivityLabel "Confidential"
-WhatIf`** (preview), then `-Commit`; review the policy in Purview → **Information Protection →
Auto-labeling → Information Protection - Pilot - Simulation → Simulation**.
**Expected:** With `-WhatIf`, nothing is created. With `-Commit`, the policy exists in **simulation**
(`Mode = TestWithoutNotifications`) and, after its rule runs, shows content it **would** label — while
applying **no label to anything**. No DLP is enabled. `IPASSESS-Validation.ps1` confirms the object is in
simulation mode.

## Test 9 — Rollback leaves no residue
**Do:** `Remove-AutoSensitivityLabelPolicy "Information Protection - Pilot - Simulation"` (and unpublish
the pilot label policy if used); re-run **`IPASSESS-Discovery.ps1`**.
**Expected:** The pilot object is gone; because it labeled nothing, there is nothing to revert; the estate
matches the pre-pilot baseline.

## Test 10 — The assessment is repeatable
**Do:** Re-run **`IPASSESS-Discovery.ps1`** + **`IPASSESS-Validation.ps1`** + **`IPASSESS-Report.ps1`**.
**Expected:** The same posture reproduces; after a real (follow-on) fix the relevant dimension score
improves — the scorecard is a repeatable measure of progress.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| **Discovery pass** | Tests 1–3 pass (sessions healthy; estate + label posture captured accurately) |
| **Assessment pass** | Tests 4–7 pass (coverage/DLP gaps visible; scoring matches baseline; register + roadmap actionable) |
| **Pilot pass** | Tests 8–10 pass (fix validates in simulation; nothing enforced; clean rollback; repeatable) |

> Do not present the roadmap as final until the Assessment gate passes, and do not proceed to any
> enforcement (follow-on) until the Pilot gate proves the fix path in **simulation**.
