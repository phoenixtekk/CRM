# Enterprise Application Management Governance & Operating Model (Microsoft Endpoint / Intune) — v1.0.0

| | |
|---|---|
| Category | Intune |
| Solution code | APPOPS |
| Commercial | $2,995.00 (`PTK-APPOPS-COMM-001`) |
| Non-Profit | $1,797.00 (`PTK-APPOPS-NPO-001`) |
| Government | $2,545.75 (`PTK-APPOPS-GOV-001`) |
| Pricing tier | T4 — multi-workstream org-wide operating model |
| Branding | off (white-label) |
| Government variant | No (identical process; portal/Graph URLs differ, scripts take `-GraphEnvironment USGov`) |

The **governance and operating model** for a Microsoft Intune application estate — the accountability
layer above packaging and deployment. Defines ownership & RACI, an intake workflow, an Application
Review Board with real decision rights, published standards, risk-tiered change control with a CAB
interface, a tiered support model, and the metrics that prove it works — with every governance
decision expressed as a concrete Intune/Entra object (scope tags, a least-privilege custom role,
deployment-ring groups, audit evidence).

## Scope

This is the governance **anchor** product. It deliberately does **not** re-teach packaging mechanics
(covered by WIN32), third-party patching (TPP), or install troubleshooting (INTAPPDX) — it describes
how governance plugs into Intune and the security stack (App Control / WDAC, Defender for Endpoint,
App Protection), not their configuration steps.

## What's included

- **Documents:** solution overview, global requirements, ten solution requirements, fourteen-step
  implementation, eight testing gates, troubleshooting, best practices, deliverables summary,
  executive summary.
- **Five PowerShell scripts** (Microsoft Graph SDK; four read-only, one gated `-WhatIf`):
  `APPOPS-Discovery.ps1`, `APPOPS-Validation.ps1`, `APPOPS-Report.ps1`,
  `APPOPS-Export-ApprovalEvidence.ps1`, `APPOPS-Remediation.ps1`.

## Deliverables (built)

- `APPOPS-Solution.pdf`
- `APPOPS-Solution.docx`
- `APPOPS-Scripts.zip`
- `APPOPS-Complete-Solution.zip` (the bundle referenced by the listing)
- `APPOPS-hero.png` / `APPOPS-hero.svg`

All deliverables are white-label (`branding: off`).
