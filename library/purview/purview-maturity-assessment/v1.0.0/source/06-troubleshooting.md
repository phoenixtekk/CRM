# 6. Troubleshooting Guide — Microsoft Purview Maturity Assessment

Use `PURVIEW-Set-ScopeTargeting.ps1 -HealthCheck` for connectivity/role/readability, `PURVIEW-Discovery.ps1`
for the raw evidence, `PURVIEW-MaturityScore.ps1` to re-score, `PURVIEW-Validation.ps1` to confirm the
quick-win baseline, and `PURVIEW-Remediation.ps1` (default `-WhatIf`) for safe baseline fixes.

## A. A domain scores L0 Absent but you know it is configured
| Symptom | Cause | Remediation |
|---|---|---|
| Domain shows `L0` / "unreadable" | The assessment account lacks the reader role for that solution | Run `-HealthCheck`; add the missing per-solution reader role (Requirement 2.1), then re-run Discovery + Score |
| A whole domain missing from Discovery | Cmdlet not available (module/plan) | Confirm licensing (Requirement 2.2); some cmdlets (`Get-InsiderRiskPolicy`, `Get-SupervisoryReviewPolicyV2`) require the feature to be licensed/enabled — flagged "verify your licensing/tenant" |
| D8/D9/D10 always L0 | These are portal/preview-surfaced, not fully cmdlet-readable | Verify DSPM, Data Map, and Compliance Manager in the Purview portal and set those scores manually per the rubric |

## B. Scores look too high or too low
- **Too high:** the rubric caps automated scoring at `L3` for most domains — `L4 Managed` and
  `L5 Optimized` require *measured/reported/automated* evidence the scripts cannot infer. Confirm L4/L5
  manually; do not let a script assert them.
- **Too low from licensing:** a domain absent only because it is unlicensed should be scored against its
  **achievable ceiling** and flagged, not counted as a failure. Record the license as a roadmap
  dependency (Requirement 2.2).
- **Overall band skewed:** check the weighting. Equal weights treat a regulated org's D3/D6/D7 the same
  as everything else — apply your agreed weights (`-Weights @{ D3=2; D6=2; D7=2 }`).

## C. Health check fails to connect
- `Connect-IPPSSession` FAIL: install/update `ExchangeOnlineManagement`; ensure the account is
  modern-auth/MFA-capable and not blocked by conditional access on the workstation.
- `Connect-MgGraph` WARN: install `Microsoft.Graph`; the group-builder and some D8/D9 signals use Graph.
  The core scorecard runs on S&C PowerShell alone.

## D. Evidence file not found when scoring
- `PURVIEW-MaturityScore.ps1` needs the JSON from Discovery. Run
  `PURVIEW-Discovery.ps1 -JsonPath .\purview-evidence.json` first, then
  `PURVIEW-MaturityScore.ps1 -EvidencePath .\purview-evidence.json`.

## E. Quick-win remediation "did nothing"
- That is the **safe default**. `PURVIEW-Remediation.ps1` runs in `-WhatIf` (preview) unless you pass
  `-Commit`. Review the `WOULD:` plan, get readout sign-off and change control, then re-run with
  `-Commit`.
- If `-Commit` reports `SKIP`, the object likely already exists or the account lacks write access —
  check the message and confirm Compliance Administrator write roles.

## F. Baseline DLP shows as enforcing (it must not)
- The baseline is created with `-Mode TestWithNotifications` (audit only). If `PURVIEW-Validation.ps1`
  reports the DLP policy in an `Enable*` (enforce) mode, something enforced it outside this solution —
  set it back with `Set-DlpCompliancePolicy '<name>' -Mode TestWithNotifications`. Enforcement is a
  separate, change-controlled roadmap step, never part of the baseline.

## G. Insider Risk / Communication Compliance (D4/D5) findings
- The assessment reads **presence only** — never case content. If a score or roadmap item implies a
  case action, stop: those are **HR/legal determinations** with strict role separation and
  privacy-by-design. Route the finding to HR/legal; do not action it from IT.

## H. Regulated retention/records/hold items (D3/D7)
- The scorecard measures whether the *capability* exists and is enforced — not whether a retention
  schedule, records file plan, or legal hold is *correct for your obligations*. That is a
  **records/compliance/legal determination**. The roadmap lists the technical step; the owning function
  makes the call.

## I. Diagnostics quick reference
```powershell
# Security & Compliance PowerShell (Exchange Online Management module)
Connect-IPPSSession
Get-Label | Select-Object DisplayName, Priority
Get-DlpCompliancePolicy | Select-Object Name, Mode, Enabled
Get-RetentionCompliancePolicy | Select-Object Name, Enabled, Mode
Get-ComplianceCase | Select-Object Name, Status
(Get-AdminAuditLogConfig).UnifiedAuditLogIngestionEnabled
```
For DSPM, Data Map, and Compliance Manager, verify in the Purview portal (these are portal/preview-
surfaced — Requirement 2.2).

## J. When to escalate
If a domain is licensed, the account holds the reader role, `-HealthCheck` shows it readable, and the
score still does not match a known-good configuration, capture the output of
`PURVIEW-Set-ScopeTargeting.ps1 -HealthCheck`, `PURVIEW-Discovery.ps1`, and
`PURVIEW-MaturityScore.ps1`, and open a Microsoft support case for the affected solution.
