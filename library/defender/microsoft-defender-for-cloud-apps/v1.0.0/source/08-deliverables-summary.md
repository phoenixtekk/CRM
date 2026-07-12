# 8. Deliverables Summary — Microsoft Defender for Cloud Apps

The complete Defender for Cloud Apps lifecycle in one package — **Connect & Govern → Enable the team → Prove value**.

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box — the three-phase lifecycle |
| 1. Solution Overview | What MDCA is — app connectors, Cloud Discovery, app governance/OAuth policies, session/access control; the three phases; benefits, limitations |
| 2. Requirements Guide | Solution-specific prerequisites with Verify / Implement-if-missing |
| Global Requirements (Defender) | Category-wide prerequisites, published once |
| 3. Implementation Guide | All three phases — Phase A connect & govern, Phase B the five enablement labs, Phase C the guided PoC — with named objects |
| 5. Testing Guide | Part A deployment validation, Part B enablement knowledge-check, Part C PoC gates |
| 6. Troubleshooting Guide | Field issues and remediation across all phases |
| 7. Best Practices | Field-proven recommendations per phase and where to go next |

## Deliverables (PowerShell — Microsoft Graph Security / Entra + KQL)
| File | What it does |
|---|---|
| `MDCAFULL-Discovery.ps1` | Read-only readiness — MDCA activation, plan hints, admin roles, existing app connectors, Cloud Discovery source, app-governance status, Conditional Access availability, MDCA alert count. Makes no changes. |
| `MDCAFULL-Validate.ps1` | Targeted validation (`-Check Connectors\|Discovery\|Policy\|Signal\|PoC\|All`) — confirms connectors, discovery flow, report-only/pilot-scoped policies, `CloudAppEvents` streaming, and the PoC observations (discovery report, policy match, alert). Read-only. |
| `MDCAFULL-Report.ps1` | Coverage report by section (`-Section OAuth\|Policies\|All`, `-SaveBaseline`) — risky OAuth apps, policy inventory/posture, shadow-IT / OAuth shortlist templates, and drift versus a saved baseline. Read-only. |
| `MDCAFULL-OAuthRisk.ps1` | Read-only enumeration of OAuth service principals and consent grants with risk hints (high-privilege scopes, unverified publisher, broad consent); prints the **approval-gated** revoke steps as a **preview only** — revokes nothing. |
| `MDCAFULL-PoC.ps1` | `-WhatIf`-gated proof-of-concept helper (`-Action Enable\|Signal\|Score\|Teardown`) — previews readiness and guides the audit-mode policy, generates **benign** test signal (sample discovery log + benign policy-matching activity), scores against your criteria, and cleanly tears the PoC down. Safe preview by default. |
| `MDCAFULL-LabQueries.kql` | Advanced-hunting KQL pack — shadow-IT / discovery, connected-app activity, OAuth apps, anomaly investigation, single-user pivot, and the `MDCA Signal Validation` query. Read-only telemetry. |

## Take-home runbook artifacts (produced during the labs)
- Saved hunting queries: `Discovery-ShadowIT – CloudApps – Pilot`, `OAuthApps – CloudApps – Pilot`, `Anomaly-Investigation – CloudApps – Pilot`, `MDCA Signal Validation – Tenant – Validate`.
- The report-only session policy `MDCA Session Control – Pilot Users – Report`.
- The `ShadowIT-Shortlist – CloudApps – Pilot` and `OAuthRisk-Shortlist – CloudApps – Pilot`.
- The `Investigation – CloudApps – Pilot` findings document.
- The `MDCA PoC Scorecard – Pilot Users – Validate` decision record.

## What the buyer receives
- This solution as a **Word** document and **PDF**.
- All six deliverables (five PowerShell scripts with embedded KQL, plus the standalone KQL pack) in a single ZIP.
- A repeatable process following the model **Assess → Configure → Pilot → Validate → Expand** — pilot-scoped, monitor-first onboarding, hands-on team enablement, and a benign, reversible PoC, with enforcing/revoke/teardown actions kept approval-gated or `-WhatIf`-gated until trusted.

Delivered as a **Complete Solution Package (PDF + Word + scripts)**.

## Outcome
A fully connected, team-ready, value-proven Defender for Cloud Apps delivering CASB — connectors streaming from priority SaaS apps, Cloud Discovery surfacing shadow IT, app governance and OAuth policies watching risky consents, session/access policies enforcing real-time control on a pilot scope, a team that can operate all of it with a runbook they keep, and a scorecard that proves the value — the whole lifecycle in one package.
