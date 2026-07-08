# 8. Deliverables Summary — AI Prompt/Response Governance & Usage Monitoring (Microsoft Purview)

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | What this monitors (AI prompt/response usage, sensitive interactions) and governs (Communication Compliance for AI, DLP for Copilot/AI), the availability/licensing caveat, privacy-by-design & role separation, the outcome-vs-determination boundary, and the naming convention |
| 2. Requirements Guide | Every AI-governance prerequisite with Verify / Implement-if-missing (licensing, least-privilege roles with separation of duties, auditing, Communication Compliance readiness, DLP Copilot location, DSPM for AI, in-scope AI apps/population, pilot discipline) |
| Global Requirements (Purview) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered portal + PowerShell steps: confirm scope, inventory governance config, baseline AI usage, design the policy set, create the Communication-Compliance AI policy (pilot scope, anonymized), create DLP for AI in test, optionally stage risky-AI-usage, validate, expand/enforce, recurring review |
| 5. Testing Guide | Validation procedures with explicit pass/fail, the privacy gate, and the enforcement/expansion gate |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven recommendations for monitoring and governing AI prompts/responses safely |

## PowerShell scripts
All are safe-by-default (read-only, or `-WhatIf` / DLP **test** mode unless `-Commit`), use
`Connect-IPPSSession` / `Connect-ExchangeOnline` and/or `Connect-MgGraph`, and store **no** credentials.
| Script | What it does |
|---|---|
| `AIPROMPT-ScopeConfig.ps1` | Read-only scope/health helper: confirms sign-in, reports whether **auditing** is on, and enumerates the AI-governance features present (Communication Compliance policies, DLP, sensitivity labels, Copilot audit signal). Resolves Requirements 2.1–2.6 |
| `AIPROMPT-Discovery.ps1` | Read-only inventory of sensitivity labels, sensitive information types, DLP policies/rules (flagging Copilot/AI-scoped), and existing Communication Compliance policies. Writes `AI Governance Config – Estate – Discovery` |
| `AIPROMPT-Monitor.ps1` | Read-only AI usage/prompt-response monitoring report from Purview auditing (`CopilotInteraction` + configured AI record types): who used AI, which app, which interactions touched sensitive/labeled resources. Writes `AI Usage – Copilot – Monitor` and `Sensitive AI Interactions – Estate – Assess` |
| `AIPROMPT-Configure-Governance.ps1` | Governance configuration/remediation helper (DLP-for-AI / Communication-Compliance checklist / insider-risk check / enforce). Defaults to `-WhatIf`; with `-Commit` creates `AI Prompt DLP – Copilot – Test` in **test** mode on the parameterized Copilot location; outputs the Communication-Compliance scope/reviewer/anonymization checklist (does not silently create the privacy-sensitive policy); and (Enforce) flips the named DLP policy from test to on — never silently |
| `AIPROMPT-Validate.ps1` | Read-only validation/evidence: confirms the DLP-for-AI policy is in **test** mode, the Communication-Compliance policy is pilot-scoped, and AI interactions are being captured. Writes `AI Governance Validation – Estate – Evidence` |

## What the buyer receives
- This implementation guide as a **Word** document and **PDF**.
- All five **PowerShell scripts** in a single ZIP.
- A repeatable process following the model: **Assess → Design → Configure → Pilot (simulate/test) →
  Validate → Expand (enforce).**

## Outcome
AI prompt/response risk made **visible and governed**: usage monitored across the estate with evidence of
which prompts/responses touch sensitive data, a Communication-Compliance policy detecting sensitive/risky
AI content under privacy-by-design and strict role separation, and DLP for Copilot/AI keeping the most
sensitive material out of AI processing — every high-impact policy piloted in a limited/test scope before
enforcement. HR, regulatory, records, and legal determinations remain with the organization's governance
functions; this solution delivers the technical method and the evidence.
