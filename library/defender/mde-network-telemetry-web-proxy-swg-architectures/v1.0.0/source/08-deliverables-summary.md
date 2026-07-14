# 8. Deliverables Summary — Defender for Endpoint Network Telemetry in Web Proxy / SWG Architectures

Everything included in this solution, and how it fits together.

## Documentation (source guides)
- **Executive Summary** — what the assessment is, the outcome (tenant-specific evidence + supported-topology plan + Microsoft advisory case), the boundary, and effort.
- **01 · Solution Overview** — how loopback/forward-proxy steering obscures endpoint destination telemetry, where in the Defender stack it matters, scope, out-of-scope (with cross-references), and the connections/auth used.
- **02 · Requirements** — the solution-specific prerequisites (P2 + advanced hunting, behind-the-SWG onboarded devices, Security Reader read-only access, SWG-mode identification, the proxy address set, Graph modules, the device sample, a support entitlement, optional SIEM export). Category-level prerequisites are in the separate **Global Requirements — Defender** file.
- **03 · Implementation** — the exact, ordered, **read-only** steps (Assess → Configure → Pilot → Validate → Expand), every object named `<Purpose> – <Scope> – <Stage>`, plus the **XFF clarification** text, the **feature-impact matrix** structure, the **supported-topology remediation** options, and the **Microsoft advisory ticket template**.
- **05 · Testing** — pass/fail gates for measurement validity and honest deliverable framing (including "keep the Confirm-with-Microsoft column open" and "XFF is reasoning, not ruling").
- **06 · Troubleshooting** — symptom → cause → fix for the common visibility-gap and measurement failures.
- **07 · Best Practices** — keep-it-read-only, make-the-measurement-defensible, never-invent-Microsoft's-answers, defer-the-non-technical-decisions, operate-the-loop, and where to go next.

## Scripts (read-only assessment + reporting)
All scripts are **read-only**: they sample, measure, and report. **None** changes the SWG, the agent, the endpoints, or the tenant.

- **`MDEPROXY-Discovery.ps1`** — read-only readiness: signed-in context, MDE plan (P2) hints, onboarded devices, `DeviceNetworkEvents` freshness, and **which network Advanced Hunting tables are populated**. Confirms the environment is ready to measure.
- **`MDEPROXY-Validate.ps1`** — the core measurement: over the device sample and window, the **share of outbound `DeviceNetworkEvents` whose `RemoteIP` is a loopback/proxy address vs a true remote** (destination obfuscation), the missing-`RemoteUrl` count, and `DeviceNetworkEvents` completeness. Writes the telemetry baseline.
- **`MDEPROXY-FeatureImpact.ps1`** — enumerates the network-dependent surface: custom detections/hunts referencing `RemoteIP`/`RemoteUrl`/`RemotePort`, the IP/URL/domain TI indicators exposed to obfuscation, and the portal-only Network Protection / SmartScreen checks. Seeds the feature-impact matrix.
- **`MDEPROXY-Hunt.kql`** — the Advanced Hunting KQL query pack: destination-obfuscation share, `DeviceNetworkEvents` completeness, network-table population, and network-dependent detection coverage — run interactively in the portal or via the scripts.
- **`MDEPROXY-Report.ps1`** — compiles the **assessment report** from the saved measurement outputs: obfuscation/completeness summary, feature-impact matrix, XFF clarification, and the open questions for the Microsoft advisory case.

## Named objects produced (documents, not changes)
`MDEPROXY Device Sample – Proxy Ring – Assess` · `MDEPROXY Proxy Address Set – Tenant – Assess` · `MDEPROXY Telemetry Baseline – Proxy Ring – Pilot` · `MDEPROXY Feature-Impact Matrix – Tenant – Validate` · `MDEPROXY XFF Clarification – Tenant – Validate` · `MDEPROXY Remediation Plan – Tenant – Expand` · `MDEPROXY Advisory Case – Microsoft – Expand` · `MDEPROXY Assessment Report – Tenant – Validate`.

## How it is delivered
Delivered as a **Complete Solution Package (PDF + Word + scripts)** — the documentation as a Word document and PDF, plus all five scripts (four PowerShell + one KQL pack) in a single ZIP, yours to keep and reuse on every re-assessment.
