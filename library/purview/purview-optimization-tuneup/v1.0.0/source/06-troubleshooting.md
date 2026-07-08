# 6. Troubleshooting — Microsoft Purview Optimization & Tune-Up

The failure modes you'll hit baselining noise and tuning policies. Each: **symptom → likely cause →
fix.** Most "the tuning broke something" reports are a change that skipped simulation, a rollback
baseline that wasn't captured, or a true-positive probe that was never run — this guide separates those
from real faults. PowerShell is **Security & Compliance PowerShell** (`Connect-IPPSSession`) plus
**Exchange Online PowerShell** (`Connect-ExchangeOnline` for `Search-UnifiedAuditLog`).

## `OPSOPT-Report.ps1` produces an empty or tiny noise baseline
- **Cause A — audit ingestion off.** `UnifiedAuditLogIngestionEnabled = False`, so there's little data
  to rank. **Fix:** enable unified audit (Requirement 2.4), allow activation time, re-run over a fresh
  window. An empty window is a **data gap, not "no noise."**
- **Cause B — `Get-DlpDetailReport` unavailable / short retention.** The detail report is
  licensing-/tenant-dependent (E5 / E5 Compliance) and has a limited retention window. **Fix:** confirm
  licensing; shorten `-Days` to the available window; **verify your tenant.**
- **Cause C — no matches yet.** Policies genuinely aren't matching in the window. **Fix:** widen
  `-Days`; confirm the policies are actually scoped to active locations.

## `Get-DlpDetailReport` / `Search-UnifiedAuditLog` "term is not recognized"
- **Cause:** wrong endpoint. `Get-DlpDetailReport`, `Get-DlpComplianceRule`, `Get-ProtectionAlert` are
  **S&C PowerShell** (`Connect-IPPSSession`); `Search-UnifiedAuditLog` / `Get-AdminAuditLogConfig` are
  **Exchange Online** (`Connect-ExchangeOnline`). **Fix:** connect the right endpoint; both ship in
  `ExchangeOnlineManagement`.

## A tuning `-Commit` changed a policy but there's no rollback file
- **Cause:** the change bypassed the pipeline (a manual portal/`Set-*` edit), so no prior value was
  captured. **Fix:** run `OPSOPT-Scope-Health.ps1 -Policies "…"` to snapshot the **current** value as a
  baseline **before** the next change; going forward only tune through `OPSOPT-Tune.ps1`, which records
  the prior value first. Note the first-captured baseline is never overwritten.

## `OPSOPT-Tune.ps1 -Rollback` throws "No rollback baseline"
- **Cause:** no `rollback-<policy>.json` exists for that policy/rule (never captured, or the
  `-OutputFolder` differs). **Fix:** point `-OutputFolder` at the folder that holds the baselines;
  confirm the file exists. If it was never captured, the prior value can only come from your own change
  record — **do not guess**; restore from documented values.

## A policy is still enforcing while you tune it
- **Cause:** it was never moved to simulation, or the mode change didn't commit. **Fix:** run
  `OPSOPT-Tune.ps1 -Policy "…" -ToSimulation -Commit`; confirm `Get-DlpCompliancePolicy | Select
  Name,Mode` shows a **Test** mode. Never tune a rule while the policy enforces — you'd change live
  blocking behavior.

## Simulation shows no matches for content you tightened
- **Cause A — propagation latency.** Mode/rule changes take time to propagate before they evaluate.
  **Fix:** allow time, re-check.
- **Cause B — you tightened too far.** Raising confidence/instance count can push a genuinely sensitive
  item below the threshold. **Fix:** this is exactly what the **true-positive probe** (Test 7) catches —
  run `OPSOPT-Validation.ps1 -ProbeRule "…" -ProbeMatched:$false` and **roll back**; you removed
  **signal**, not noise.

## The true-positive probe fails after tuning
- **Cause:** the tuned condition no longer matches a known-sensitive sample. **Fix:** this is a **hard
  stop** — do **not** re-enforce. Roll back (`OPSOPT-Tune.ps1 -Policy "…" -Rollback -Commit`), loosen the
  change (lower the confidence/instance step, narrow the exception), re-pilot, and re-probe. *Whether a
  sample is genuinely sensitive is the data owner's determination.*

## False positives didn't drop after tuning
- **Cause A — window too short.** Fresh match data hasn't accrued under the new settings. **Fix:** let
  the observation window run, re-run `OPSOPT-Report.ps1`, compare before/after.
- **Cause B — wrong lever.** The noise was single-instance, but you raised confidence (or vice-versa).
  **Fix:** re-read `dlp-noise-by-rule.csv` — raise **instance count** for single-instance noise, raise
  **confidence** for low-confidence noise, add an `ExceptIf` for a specific legitimate workflow.

## Adding an exception is rejected — "requires -Justification"
- **Cause:** by design — every `-ExceptIfFrom` exception must carry a written `-Justification` with a
  named owner (Requirement 2.8). **Fix:** re-run with `-Justification "…"`; it's recorded to
  `exception-justifications.tsv` as evidence.

## Alert volume didn't fall after raising the threshold / aggregating
- **Cause:** the change didn't commit, or recipients weren't trimmed. **Fix:** confirm
  `Get-ProtectionAlert "…" | Select Threshold,AggregationType`; re-run `OPSOPT-Report.ps1` and compare
  `alert-volume.csv`; trim the notification list to those who act on the alert.

## Insider-risk noise won't tune from PowerShell
- **Cause:** insider-risk policy tuning is **portal-driven** and role-separated — there are no supported
  IRM configuration cmdlets here (Implementation Step 9). **Fix:** as the **separate** Insider Risk
  Management role holder, adjust indicators/thresholds and confirm **pseudonymization/anonymization** in
  the portal; capture before/after as evidence. **Any case outcome is HR/legal's — never a verdict from
  this solution.**

## When to escalate beyond this solution
- **Whether a new exception is acceptable, or whether a detection pattern is a real risk** → the owning
  **data owner / compliance / security** function (this solution reduces and evidences noise; it does not
  rule on acceptability).
- **Insider-risk / communication-compliance case outcomes** → **HR / legal**, with privacy-by-design and
  role separation intact.
- **A capability genuinely missing despite correct licensing** → verify against current Microsoft
  documentation and open a Microsoft support case; Purview surfaces and cmdlets evolve.
