# 7. Best Practices — Microsoft 365 Copilot Data Governance & DLP Guardrails

Keep the Copilot data boundary governed over time, and know where to go next in the catalog.

## Keep it clean
- **Simulate before you enforce, always.** Auto-labeling starts in **simulation**, DLP-for-Copilot starts
  in **test/disabled**. Review the matches for false positives, then move to enforce — never enable a
  block that hasn't been evaluated against real content.
- **Let compliance own classification.** *What is "sensitive," acceptable for AI, or must be blocked* is a
  compliance/records/legal determination. Implement their decisions; don't invent classification rules in
  the admin console.
- **Labels first, DLP second.** Sensitivity labels with **encryption/usage rights** are honored by Copilot
  at item level and travel with the content — they are the durable control. DLP-for-Copilot is the
  policy layer on top; where DLP-for-Copilot is unavailable, label encryption is the interim equivalent.
- **Keep the "keep out of AI" tier small and precise.** A tight, well-defined highly-confidential tier
  produces fewer false positives and cleaner enforcement than a broad, fuzzy one.
- **Tune, don't over-block.** An over-broad DLP-for-Copilot policy erodes trust in Copilot. Prefer precise
  label/sensitive-info-type conditions and iterate from the simulation data.
- **Prove the audit trail.** Confirm Copilot prompts/responses are recorded and eDiscoverable **before**
  you rely on the guardrails — the evidence path is part of the control, not an afterthought.
- **Re-measure on a cadence.** Content, labels, and Copilot usage drift. Run the read-only `Discovery →
  AuditSearch → Validate → Report` chain monthly (`Copilot Governance Review – Tenant – Recurring`) and
  treat new unlabeled-sensitive content Copilot can reach as a finding.
- **Verify preview/licensing before you commit.** DLP-for-Copilot and related capabilities are
  licensing-gated and some are in preview — confirm current availability in your tenant rather than
  assuming a blade or behavior.
- **Least-privilege the operator.** Use scoped Information Protection / DLP compliance roles and
  eDiscovery Manager; reserve Global Administrator for tenant-wide changes.
- **Keep the evidence.** Retain the coverage before/after, the simulation review, the audit-capture
  confirmation, and the governance report — the defensible record that Copilot use is governed.

## Where to go next (adjacent catalog areas)
- **Copilot — Oversharing & SharePoint Permissions Remediation:** the access counterpart to this
  solution — fix *who can reach what* in SharePoint/OneDrive so Copilot honors the real boundary. Build it
  alongside this one; access + governance together are defense in depth.
- **Purview — Information Protection & Sensitivity Labels:** design and publish the label taxonomy,
  container labeling, and auto-labeling this solution enforces around Copilot.
- **Purview — Data Loss Prevention (endpoint/cloud/email):** the broader DLP program the Copilot-scoped
  policy sits within.
- **Purview — Audit (Standard/Premium) & eDiscovery:** deepen the investigation and retention capabilities
  behind the Copilot audit trail.
- **Purview — DSPM for AI / Copilot Data-Protection Readiness:** exposure-insight and readiness views that
  complement these guardrails.
- **Entra — Identity & Conditional Access:** harden the identity plane Copilot honors so governance is
  enforced end to end.
