# 7. Best Practices — Secure Microsoft 365 Copilot: Oversharing & SharePoint Permissions Remediation

Keep the corrected boundary clean over time, and know where to go next in the catalog.

## Keep it clean
- **Fix access, don't just fence it.** RSS and RCD are **interim stopgaps** to buy time — the durable win
  is removing the broad grant and scoping the site. Remove interim controls once the underlying access is
  correct; a permanent search fence hides the problem instead of solving it.
- **Pilot before you enforce, always.** Preview every reduction with `-WhatIf`, remediate a ring first,
  validate (including the Copilot-side test), then expand. Never remove broad access tenant-wide in one
  step.
- **Let owners own access.** *Who should have access* is a data-owner decision. Drive cleanup through
  **site access reviews** so owners confirm membership; you supply the discovery and the remediation
  method, not the access verdict.
- **Default to least privilege at creation.** Prevent new oversharing: disable/limit **"Anyone" links**
  tenant-wide, set the default sharing link to **specific people** or **people in your org**, and use
  **site creation policies** so new sites start scoped, not broad.
- **Watch EEEU specifically.** "Everyone Except External Users" is the single most common Copilot
  oversharing source. Track it in the **Data Access Governance** EEEU report and keep it near zero on
  content-bearing sites.
- **Reinforce with information protection.** Sensitivity labels with **encryption/usage rights** are
  honored by Copilot at item level — defense in depth beyond sharing settings. Keep the label + DLP layer
  aligned (see the Copilot data-governance solution).
- **Re-measure on a cadence.** Sharing drifts as people collaborate. Run the read-only `Discovery →
  Validate → Report` chain monthly (`Oversharing Review – Tenant – Recurring`) and treat any new EEEU /
  anonymous link on a content site as a finding.
- **Mind Copilot indexing latency.** A permission change is not instantly reflected in Copilot results;
  allow the re-index window before trusting a negative test, and record the test time.
- **Keep the evidence.** Retain the before/after exports and the Copilot-side verification — they are your
  defensible record that oversharing was closed before broad Copilot rollout.
- **Least-privilege the operator.** Use SharePoint Administrator for remediation and read scopes for
  discovery; reserve Global Administrator for tenant-wide changes.

## Where to go next (adjacent catalog areas)
- **Copilot — Data Governance & DLP Guardrails:** the information-protection counterpart to this
  solution — sensitivity labels on Copilot-accessible content, **DLP for Microsoft 365 Copilot**, prompt/
  response guardrails, and audit/eDiscovery of Copilot interactions. Build it alongside this one.
- **Purview — Information Protection & Sensitivity Labels:** design and publish the label taxonomy,
  auto-labeling, and container labeling that reinforce corrected access.
- **Purview — Data Loss Prevention:** the broader DLP program (endpoint, cloud, email) that the
  Copilot-scoped DLP sits within.
- **Purview — Copilot Data-Protection Readiness / DSPM for AI:** the Purview-centric readiness and
  exposure-insight view that complements this SharePoint-permissions remediation.
- **Entra — Identity & Conditional Access:** harden the identity plane Copilot honors (MFA, CA, PIM) so
  access decisions are enforced end to end.
- **SharePoint / M365 governance:** site lifecycle, external sharing policy, and guest governance to stop
  oversharing recurring at the source.
