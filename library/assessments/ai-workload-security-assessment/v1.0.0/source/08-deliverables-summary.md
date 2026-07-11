# 8. Deliverables Summary — AI Workload Security Assessment

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | The business case and what's in the box — a scored security picture of your Azure AI workloads and a prioritized findings report |
| 1. Solution Overview | What the assessment is — the AI attack surface, the review areas (discovery, network isolation, keyless identity, content safety, RAG exposure, responsible-AI governance), and the boundary vs. the paired AI build solutions and Copilot governance |
| 2. Requirements | Solution-specific prerequisites with Verify / Implement-if-missing |
| Global Requirements (Assessments) | Category-wide prerequisites, published once |
| 3. Implementation | Exact, ordered, read-only steps — validate access, discover the AI estate, review network isolation, keyless identity, content safety, RAG exposure and secrets, then pilot → validate → expand and produce the risk-ranked report and roadmap |
| 5. Testing | Validation gates — read-only proof, complete discovery, portal reconciliation, no preview false positives, reproducible report |
| 6. Troubleshooting | Field issues → cause → fix |
| 7. Best Practices | Field-proven guidance and where to go next (the paired AI solutions) |

## Automation artifacts (all read-only)
| File | What it does |
|---|---|
| `AIWLSEC-Discovery.ps1` | **PowerShell, read-only.** AI estate discovery across Azure OpenAI / Cognitive Services, AI Foundry, AI Search, and Azure ML — public access, local-auth (keys) state, custom subdomain, model deployments + content-filter policies, private endpoints, diagnostics, and search indexes/data-sources indicating a RAG pattern. Writes per-resource posture to the findings folder. |
| `AIWLSEC-Validate.ps1` | **PowerShell, read-only.** Pre-flight — confirms PowerShell/module versions, Azure + Graph connected, the identity is Azure Reader + Security Reader (no Contributor/write), AI resource providers registered, and lists the AI resources in scope. The gate that proves the run is read-only and complete. |
| `AIWLSEC-NetworkIsolation.ps1` | **PowerShell, read-only.** Per-AI-resource network-isolation review — public network access (Enabled = finding), private-endpoint presence, and private-DNS path — the highest-frequency AI findings. |
| `AIWLSEC-ContentSafety.ps1` | **PowerShell, read-only.** Per-model-deployment content-safety posture — whether a content-filter (RAI) policy is attached and its default state — and flags prompt-shield / jailbreak / groundedness protections as "verify availability" (several are preview). Never asserts a gap for an unavailable feature. |
| `AIWLSEC-Report.ps1` | **PowerShell, read-only.** Rolls the discovery + network + content-safety outputs (and recorded RAG/secrets findings) into per-resource posture, tags each finding Critical/High/Medium/Low (impact × exposure), names the baseline and run date, flags preview-dependent items, and maps each finding to a paired build solution (AIFOUNDRY/AIRAG/AISAFETY/AILZ). |

Plus **read-only KQL** (saved as `AIWorkloadSec – KeyAuth – Signal`) in the Testing guide to corroborate the
keyless finding with live authentication evidence where Log Analytics / Sentinel is available.

## What the buyer receives
- This assessment guide as a **Word** document and **PDF**.
- All five read-only **PowerShell** scripts plus the KQL, in a single ZIP.
- A repeatable process following the model: **Assess → Configure → Pilot → Validate → Expand** — entirely
  read-only, re-runnable to trend the AI security posture, with remediation handed to the paired AI build
  solutions under change control.

**Delivered as a Complete Solution Package (PDF + Word + scripts).**

## Outcome
A defensible answer to "is the AI we're building secure?" — an inventory of every Azure AI workload, a
risk-ranked list of the prompt-injection, data-leakage, identity, network, and governance gaps that carry
the most risk, and a clear hand-off to the paired build solutions — produced by a single administrator,
entirely read-only, and re-runnable to prove progress. Acceptable-use, data-classification, and
risk-acceptance decisions remain the customer's.
