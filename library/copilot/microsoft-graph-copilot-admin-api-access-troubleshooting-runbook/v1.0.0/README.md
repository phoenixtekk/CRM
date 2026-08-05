# Microsoft Graph Beta Copilot Admin API — Access, Permissions & Troubleshooting Runbook (CPADMDX)

**Category:** Copilot · **Version:** v1.0.0 · **Branding:** off (white-label) · **Status:** generated

A branch-based diagnostic runbook and 5 read-only PowerShell scripts for **blocked or failing requests
to the Microsoft Graph Copilot admin (beta) endpoints** (`/beta/copilot/admin/catalog/packages`,
`/policySettings`, and the wider `/beta/copilot/admin/*` surface). Decodes 401/403/404/429 into one
named root cause — scope, admin role, app-vs-delegated, consent, flighting, cloud, license, path,
throttling, or genuine limitation — each with the fix or the supported fallback.

## Pricing
| Tier | SKU | Price |
|---|---|---|
| Commercial | PTK-CPADMDX-COMM-001 | $1,995.00 |
| Non-Profit | PTK-CPADMDX-NPO-001 | $1,197.00 |
| Government | PTK-CPADMDX-GOV-001 | $1,695.75 |

## What's included
- **Docs (Word + PDF):** Executive Summary, Solution Overview, Requirements, Global Requirements
  (Copilot), Diagnostic Runbook (Step 0 + Branches A–J), Testing, Troubleshooting, Best Practices,
  Deliverables Summary.
- **5 read-only PowerShell scripts** (cloud switch `-Environment Global|USGov|USGovDoD`):
  `CPADMDX-Preflight.ps1`, `CPADMDX-Probe-Endpoint.ps1`, `CPADMDX-Resolve-Scopes.ps1`,
  `CPADMDX-Test-Fallbacks.ps1`, `CPADMDX-Report-Findings.ps1`.
- **Deliverable bundle:** `CPADMDX-Complete-Solution.zip` (PDF + Word + Scripts).

## Files
```
source/        01-solution-overview, 02-requirements, global-requirements-copilot,
               03-implementation (the runbook), 05-testing, 06-troubleshooting,
               07-best-practices, 08-deliverables-summary, executive-summary
scripts/       CPADMDX-*.ps1 (5, read-only, Microsoft Graph, cloud-aware)
listing/       hero.json, bagisto-products.json, sales-content.md
deliverables/  CPADMDX-Solution.pdf/.docx, CPADMDX-Scripts.zip, CPADMDX-Complete-Solution.zip, CPADMDX-hero.png/.svg
```

## Accuracy & scope
All endpoint paths, permission scopes, admin roles, license requirements, error semantics, and
cloud-availability facts were verified against Microsoft Learn on 2026-07-24. This is a **preview**
surface; every volatile claim is flagged *"verify against current Microsoft documentation."*

- **gov_variant: false** — the Copilot admin beta endpoints are **Global-only** (unavailable in GCC
  High / DoD / 21Vianet), so there is no distinct Government configuration to author; the Gov difference
  *is* the finding, documented inline (Requirements R6, Runbook Branch F), and the scripts target US Gov
  Graph for the fallbacks.
- **Dedupe:** deep, general troubleshooting runbook for the `/beta/copilot/admin/*` surface — distinct
  from sibling **AGBINV** (agent inventory + sharing export), which it references rather than reproduces.
- The customer's **Agent 365 licensing** was already ruled out; the runbook confirms and excludes it
  (Branch G) before moving on.

Shaping notes: this is a TROUBLESHOOTING runbook (not a feature tutorial); scripts never fabricate a
beta response — on failure they report the real error.
