# Deliverables Summary — Exchange Edge Transport Server Deployment & Hardening (Hybrid)

Everything included in this solution, at a glance.

## Documentation

| Document | What it covers |
|---|---|
| **Solution Overview** | The Edge Transport role in a hybrid perimeter — EdgeSync, connectors, anti-spam agents, TLS, the reference design, benefits/limits, and the Assess→Design→Configure→Pilot→Validate→Expand model. |
| **Requirements Guide** | Solution-specific prerequisites (perimeter host, AD LDS + Exchange prereqs, DNS both directions, firewall ports 50636/25, SMTP certificate, healthy internal org, change window/pilot/rollback), each with verify/implement — on top of the shared Messaging requirements. |
| **Implementation Guide** | Exact ordered steps: install the Edge role, create + import the Edge Subscription (EdgeSync), configure connectors + accepted domains, apply anti-spam/connection filtering, harden OS/TLS and close the open relay — pilot-first, every artifact named, with pass/fail gates and rollback. |
| **Testing & Validation** | Seven procedures each with expected pass/fail, mapped to Gates A–D (host readiness, EdgeSync health, no open relay, TLS enforced, anti-spam posture, mail flow, post-cut sanity). |
| **Troubleshooting** | Common failure modes (EdgeSync failed, one-way mail flow, open relay found, TLS/cert errors, over-blocking hygiene) with root cause and resolution. |
| **Best Practices** | Durable practices — standalone perimeter host, EdgeSync ownership of connectors, no anonymous external relay, TLS enforcement, hygiene split with EOP, change control/monitoring, and Commercial-vs-Government notes. |
| **Executive Summary** | One-page outcome/approach/why-low-risk for decision-makers. |

## PowerShell scripts (5) — safe-by-default (read-only or `-WhatIf`), no credentials in code

| # | Script | What it does | Safe default |
|---|---|---|---|
| 1 | **`Get-EdgeReadiness.ps1`** | Read-only readiness/discovery — OS/version, workgroup-vs-domain state, AD LDS presence, ports 50636/25 reachability, DNS both directions, and existing EdgeSync state. Backs **Gate A**. | Read-only |
| 2 | **`Set-EdgeConfig.ps1`** | EdgeSync/connector setup helper — reports the subscription, EdgeSync-managed connectors, and accepted domains; can stage a partner mutual-TLS Send connector. Report-only unless `-Commit`, and every write honors `-WhatIf`. Backs **Gate B**. | Report-only / `-WhatIf` |
| 3 | **`Test-OpenRelay.ps1`** | Open-relay + TLS validator — probes the Edge SMTP listener to confirm anonymous external relay is **denied** and (optionally) STARTTLS is advertised. Non-delivering (stops before DATA). Backs **Gate C**. | Read-only / non-delivering |
| 4 | **`Get-AntiSpamReport.ps1`** | Read-only anti-spam / connection-filter report — transport agents, IP Allow/Block lists + providers, and filtering configs; optional JSON snapshot of `Hygiene – Edge Baseline – Prod`. | Read-only |
| 5 | **`Get-EdgeScopeHealth.ps1`** | Scope/health helper — consolidated read-only scorecard: EdgeSync status, connector scope, SMTP certificate expiry, and queue depth, mapped to the gates. Re-run after each CU. | Read-only |

> All scripts use modern-auth interactive sign-in where cloud/EXO is involved and contain **no
> hardcoded credentials or secrets**. On-prem cmdlets run in the **Exchange Management Shell** on the
> correct server (Edge vs internal). **Exchange behavior is version/CU-dependent — verify for your
> version** before applying any change.
