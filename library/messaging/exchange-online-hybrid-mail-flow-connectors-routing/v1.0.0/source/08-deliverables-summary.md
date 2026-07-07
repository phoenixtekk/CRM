# Deliverables Summary

This solution delivers a complete, run-to-implement package for designing, operating, and
troubleshooting Exchange/Microsoft 365 hybrid mail flow.

## Documentation

- **Solution Overview** — the hybrid mail-flow reference model: accepted domains and domain types
  (authoritative / internal relay / external relay), connector types (inbound/outbound, on-prem↔EXO
  hybrid, partner) and when to use each, routing topologies, the centralized-mail-transport decision,
  transport rules, and the layered trace → headers → queues diagnostic.
- **Requirements Guide** — solution-specific prerequisites (healthy HCW hybrid config, documented
  current-state routing, correct accepted-domain types, connector auth material, message-trace access,
  on-prem transport visibility, Government-cloud awareness) each with how to verify/implement, built on
  the shared Messaging global requirements.
- **Implementation Guide** — exact ordered steps following Assess → Design → Configure → Pilot →
  Validate → Expand, with every artifact named (`Accepted Domain – Primary – Prod`, `Inbound/Outbound
  Connector – OnPrem/Partner – Prod`, `Transport Rule – … – Prod`), explicit pass/fail gates
  (G1–G5), and a documented rollback.
- **Testing & Validation** — nine PASS/FAIL procedures (T1–T9) covering domain types, connectors,
  inbound/outbound/internal-relay delivery, loop detection, transport-rule scoping, header/auth checks,
  and a health-report reconciliation.
- **Troubleshooting** — common mail-flow failure modes and their resolutions, organized as a
  symptom → root-cause → fix playbook driven by the layered diagnostic.
- **Best Practices** — durable practices for resilient, diagnosable hybrid mail flow.
- **Executive Summary** — outcome, approach, and why the change is low-risk.

## PowerShell scripts (Exchange Online PowerShell V3 / Microsoft Graph — safe by default)

1. **`Invoke-MailFlowDiscovery.ps1`** — *Discovery (read-only).* Enumerates accepted domains (+ type),
   inbound/outbound connectors (+ type/source), transport rules, remote domains, hybrid state, and
   resolves public MX; flags authoritative domains as silent-NDR risks to review. Produces the
   `MailFlow Baseline – Tenant – Prod` report.
2. **`Set-MailFlowConfiguration.ps1`** — *Configuration/Remediation (`-WhatIf` by default; `-Commit` to
   apply).* Sets an accepted domain's type, creates named partner inbound/outbound connectors with
   required TLS, or creates a named, scoped transport rule. Exports a rollback baseline before any
   change. Never hand-edits HCW connectors.
3. **`Test-MailFlowValidation.ps1`** — *Validation (read-only).* Runs the T1–T8 checks — domain types
   defined, hybrid connectors still HCW-sourced, partner connectors enforce TLS, recent trace delivered,
   and a routing-loop heuristic — printing PASS/FAIL per check.
4. **`New-MailFlowHealthReport.ps1`** — *Reporting (read-only).* Consolidates accepted domains,
   connectors, transport rules, and an optional trace summary into an HTML + CSV report, with drift
   warnings (authoritative shared domains, non-HCW hybrid connectors, partner connectors without TLS).
5. **`Get-MailFlowTraceHelper.ps1`** — *Scope/diagnostic helper (read-only).* Runs a message trace,
   pulls per-hop trace detail, and parses a saved header block (Received chain, SCL, SPF/DKIM/DMARC) to
   drive the layered diagnostic; points to on-prem `Get-Queue`/SMTP logs for the legs cloud trace can't
   see.

All scripts use modern authentication (`Connect-ExchangeOnline` / `Connect-MgGraph`), contain **no
hardcoded credentials or secrets**, and are read-only or `-WhatIf` unless an explicit apply/commit
switch is passed.
