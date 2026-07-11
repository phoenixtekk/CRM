# 8. Deliverables Summary — Cloud Adoption Security Assessment

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | The business case and what's in the box — a scored, Zero-Trust-aligned view of cloud security maturity and a phased roadmap |
| 1. Solution Overview | What the assessment is — Zero Trust + CAF, the six pillars scored, how read-only discovery, Secure Score, Conditional Access, and Defender posture roll up into a maturity score; scope and the boundary vs. the remediation solutions |
| 2. Requirements | Solution-specific prerequisites with Verify / Implement-if-missing |
| Global Requirements (Assessments) | Category-wide prerequisites, published once |
| 3. Implementation | Exact, ordered, read-only steps — validate access, discover across six pillars, pull Secure Score and CA coverage, score maturity, pilot → validate → expand, then produce the risk-ranked report and phased roadmap |
| 5. Testing | Validation gates — read-only proof, complete discovery, portal reconciliation, reproducible report |
| 6. Troubleshooting | Field issues → cause → fix |
| 7. Best Practices | Field-proven guidance and where to go next to close the gaps |

## Automation artifacts (all read-only)
| File | What it does |
|---|---|
| `CLDSEC-Discovery.ps1` | **PowerShell, read-only.** Whole-estate discovery across the six Zero-Trust pillars (identity, endpoint, data, app, infrastructure, network) via Microsoft Graph + Az — MFA/legacy-auth/PIM, device compliance + Defender for Endpoint state, label/DLP presence, app-consent/secrets + shadow-IT visibility, Defender for Cloud + policy guardrails, and public-exposure/private-endpoint posture. Writes per-pillar posture to the findings folder. |
| `CLDSEC-Validate.ps1` | **PowerShell, read-only.** Pre-flight — confirms PowerShell/module versions, the granted Graph read scopes, that the identity is Security/Global Reader + Azure Reader (no write), and lists the in-scope subscriptions. The gate that proves the run is read-only and complete before you score. |
| `CLDSEC-SecureScore.ps1` | **PowerShell, read-only.** Pulls Microsoft Secure Score, the maximum, and the per-category control profiles (identity/device/apps) with the highest-impact improvement actions — the anchor for the identity/endpoint/app pillar scores and the roadmap. |
| `CLDSEC-ConditionalAccess.ps1` | **PowerShell, read-only.** Enumerates every Conditional Access policy (enabled + report-only) and flags the coverage gaps that matter most — no admin/user MFA, legacy auth not blocked, no device-compliance grant, break-glass exclusion missing/mis-scoped. Reports gaps; changes nothing. |
| `CLDSEC-Report.ps1` | **PowerShell, read-only.** Rolls the discovery + Secure Score + CA outputs into a per-pillar maturity score (0–100) against the named baseline, tags each finding with a risk rating (impact × exposure), and emits the risk-ranked findings report with the reference baseline and run date in the header. |

Plus **read-only KQL** (saved as `CloudSecAssessment – LegacyAuth – Signal`) in the Testing guide to
corroborate the legacy-auth finding with live sign-in evidence where Sentinel / Advanced Hunting is available.

## What the buyer receives
- This assessment guide as a **Word** document and **PDF**.
- All five read-only **PowerShell** scripts plus the KQL, in a single ZIP.
- A repeatable process following the model: **Assess → Configure → Pilot → Validate → Expand** — entirely
  read-only, re-runnable to trend the maturity score, with remediation handed to the dedicated catalog
  solutions under change control.

**Delivered as a Complete Solution Package (PDF + Word + scripts).**

## Outcome
A defensible answer to "how secure is our cloud?" — a per-pillar maturity score, a risk-ranked list of the
gaps that carry the most risk, and a phased roadmap to close them — produced by a single administrator,
entirely read-only, and re-runnable to prove progress. Risk-acceptance and remediation-priority decisions
remain the customer's.
