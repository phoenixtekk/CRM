# 5. Testing — Cloud Adoption Security Assessment

Testing an assessment means proving the **evidence is trustworthy** before anyone acts on it: the access is
truly read-only, the discovery is complete (no pillar silently empty), the scores reconcile with the live
portals, and the report is reproducible. Work the gates in order; each has an explicit **pass/fail**. All
tests are read-only.

Scripts referenced (all read-only): **`CLDSEC-Validate.ps1`**, **`CLDSEC-Discovery.ps1`**,
**`CLDSEC-SecureScore.ps1`**, **`CLDSEC-ConditionalAccess.ps1`**, **`CLDSEC-Report.ps1`**.

## Gate 1 — Access is valid and read-only
Run **`CLDSEC-Validate.ps1`**.
- **Pass:** PowerShell ≥ 7; required modules present; Graph read scopes granted; identity resolves to
  **Security/Global Reader** and **Azure Reader**; in-scope subscriptions listed; **no write scope present**.
- **Fail:** Any missing module/scope, or a write/admin role detected. Fix per Requirements R1–R4 before
  continuing — a missing scope makes a pillar score falsely zero; a write role breaks the read-only guarantee.

## Gate 2 — Discovery is complete (no empty pillars)
Run **`CLDSEC-Discovery.ps1`** on the pilot scope.
- **Pass:** All six pillars (identity, endpoint, data, app, infra, network) return non-empty posture rows,
  and the output CSV/JSON lands in **`CloudSecAssessment – Estate – Findings`**.
- **Fail:** A pillar returns empty. Check the matching prerequisite — e.g. an empty Infrastructure pillar
  usually means Azure **Reader** (R2) is missing; an empty Data pillar means the Purview/Graph scope (R3) is
  missing. Re-run after fixing.

## Gate 3 — Secure Score reconciles with the portal
Run **`CLDSEC-SecureScore.ps1`**, then open `security.microsoft.com` → **Secure Score**.
- **Pass:** The score, maximum, and top improvement actions returned by the script **match** the portal
  (allowing for the portal's own refresh lag).
- **Fail:** Numbers diverge materially. Confirm Secure Score is populated (R6) and that you are reading the
  same tenant; re-run.

## Gate 4 — Conditional Access gaps are real
Run **`CLDSEC-ConditionalAccess.ps1`**, then open Entra admin center → **Conditional Access**.
- **Pass:** Every gap the script flags (no admin MFA, legacy auth not blocked, no device-compliance grant,
  break-glass exclusion missing) is confirmed by inspecting the live policies; the policy count matches.
- **Fail:** A flagged gap is actually covered by a policy the script misread (e.g. a report-only policy about
  to be enabled). Record it as a validated false positive in the report with the reason — do not delete it silently.

## Gate 5 — (Optional) KQL corroboration
If you have Advanced Hunting / Sentinel (R7), run the saved query
**`CloudSecAssessment – LegacyAuth – Signal`**:
```kql
// Read-only. Legacy-authentication sign-ins in the assessment window — corroborates the CA "legacy auth
// not blocked" finding with live evidence. *Verify table/column names for your workspace.*
SigninLogs
| where TimeGenerated > ago(7d)
| where ClientAppUsed in ("Other clients","IMAP4","POP3","SMTP","Exchange ActiveSync","Authenticated SMTP")
| summarize Attempts = count(), Users = dcount(UserPrincipalName) by ClientAppUsed
| order by Attempts desc
```
- **Pass:** The query runs read-only and either confirms legacy-auth is still occurring (supports the finding)
  or returns zero (note as a compensating signal).
- **Fail:** Query errors on table/column names — adjust to your workspace schema (*verify current schema*) or
  skip; KQL corroboration is optional and does not gate the score.

## Gate 6 — Report is complete and reproducible
Run **`CLDSEC-Report.ps1`** for the labelled run.
- **Pass:** The report contains a per-pillar maturity score (0–100), an overall rating, every finding tagged
  with a risk rating, and the **named reference baseline and run date** in the header; re-running on the same
  inputs produces the same scores.
- **Fail:** Missing scores, no baseline named, or non-reproducible numbers. Confirm all Stage-2 outputs are
  present in the input folder and re-run.

## Gate 7 — Whole-estate expand run
Repeat Gates 2–6 with the full scope labelled **`CloudSecAssessment – Estate – Full`**.
- **Pass:** All gates pass at full scope; the roadmap **`CloudSecAssessment – Estate – Roadmap`** sequences
  the findings into Phase 1/2/3 and each item maps to a remediation solution.
- **Fail:** A pillar that passed at pilot scope now fails at full scope — usually a subscription where Reader
  wasn't assigned. Fix the scope coverage (R2, R5) and re-run.

> Passing all gates means the evidence is defensible. It does **not** authorize any change — remediation is
> separate, pilot-first, and change-controlled, and risk-acceptance is the customer's decision.
