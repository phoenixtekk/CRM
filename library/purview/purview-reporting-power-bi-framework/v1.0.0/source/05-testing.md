# 5. Testing & Validation — Microsoft Purview Reporting & Power BI Framework

Testing proves two things: the pipeline pulls the **right** data, and the dashboards show it
**accurately**. Every test is read-only against Purview/Graph. Run the gates in order; a solution is
"done" only when every gate passes and the reconciliation evidence is recorded. Tolerances exist because
portal aggregation and export aggregation can differ slightly by latency and grouping — a variance is
acceptable **only when explained**, never when unexplained.

## Test matrix

| # | Test | How | Pass | Fail action |
|---|---|---|---|---|
| T1 | Source reachability | `OPSREPORT-Discovery.ps1` | Every intended source = available (or marked *not licensed — verify tenant*); scopes consented | Fix licensing/roles (Req 2.1–2.4) |
| T2 | Scope recorded | `OPSREPORT-Set-ScopeHealth.ps1 -ShowScope` | `Reporting Scope – Purview – Config` lists capabilities, workloads, date window | Define scope before building |
| T3 | Export set produced | `OPSREPORT-Report.ps1 -StartDate ... -EndDate ...` | One table per licensed source, columns match the dataset contract | Fix scope/date/column mapping |
| T4 | Dataset contract conformance | Inspect export headers vs `Purview Compliance Dataset – Report` | Every table has exactly the contracted columns | Correct the export shaping |
| T5 | DLP/label reconciliation | `OPSREPORT-Validation.ps1` vs Activity Explorer | Counts match portal within tolerance | Investigate scope/window mismatch |
| T6 | Alert reconciliation | Validation vs Purview **Alerts** page | Counts by severity match | Check policy scope / time filter |
| T7 | Audit reconciliation | Validation vs matching `Search-UnifiedAuditLog` | Operation counts match | Align RecordType/date filters |
| T8 | Posture reconciliation | Validation vs Graph `security/secureScores` | Score % matches the source value | Confirm the score date pulled |
| T9 | Pipeline health | `OPSREPORT-Set-ScopeHealth.ps1 -HealthCheck` | Fresh, populated, connections OK → `Purview Pipeline Health – Report` green | Fix the failing source before scheduling |
| T10 | Pilot render | Open pilot report | All six pages render with data | Rebuild the failing page/model |
| T11 | Privacy check | Inspect `RiskAggregate` export | Counts only — no subjects, no case content | Remove any non-aggregate field immediately |
| T12 | Scheduled refresh | After Stage 5, check next-day run | Export refreshed on cadence; dataset refreshed; dashboards current | Re-check the scheduled task / capacity refresh |

## Reconciliation method (T5–T8)
For each figure, run the dashboard for a fixed window (e.g. last 7 days) and pull the **same** window
from the portal source. Record: dashboard value, portal value, variance, and the reason for any
variance (latency, grouping, scope). File this as the reporting **evidence** — it is the answer to "how
do you know these numbers are right."

## Acceptance criteria (all must hold)
- T1–T4: pipeline produces a contract-conformant export set for every licensed source.
- T5–T8: every dashboard figure reconciles to its portal source within the documented tolerance, with
  variances explained.
- T9: pipeline health is green (fresh, populated, connected).
- T10: all six dashboard pages render.
- T11: HR-sensitive sources are **aggregate-only** — verified, no subject/content fields present.
- T12: the scheduled refresh keeps production current.

## What testing does NOT cover (deferred by design)
- **Whether a number is "good."** Testing proves the number is *accurate*, not whether the DLP rate,
  retention coverage, or risk count is acceptable — that judgment is the compliance/records/privacy/
  legal stakeholders'.
- **Regulatory sufficiency.** Whether the reported posture satisfies a regulation is a legal/compliance
  determination, not a test result here.
- **Insider-risk / communication-compliance case detail** — out of scope; only aggregate counts are
  tested for privacy conformance.
