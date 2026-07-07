# Deliverables Summary

Everything included in this solution, on one page.

## Documentation

- **Solution Overview** (`01-solution-overview.md`) — the IA + provisioning model: hub-and-site
  structure, site archetypes and templates, the request→approve→provision workflow, naming
  policy, managed-metadata taxonomy, lifecycle, benefits, limitations, and the deployment model.
- **Requirements Guide** (`02-requirements.md`) — solution-specific prerequisites (PnP app
  registration, tenant creation settings, term store admin, content type gallery, governance
  approver, reference build sites), each with how to verify and how to implement — building on the
  shared SharePoint global requirements.
- **Implementation Guide** (`03-implementation.md`) — exact ordered steps across Assess → Design →
  Configure → Pilot → Validate → Expand, every hub/site/template/taxonomy artifact named, with
  pass/fail gates and a documented rollback for the high-impact tenant changes.
- **Testing & Validation** (`05-testing.md`) — nine validation procedures, each with an expected
  pass/fail signal.
- **Troubleshooting** (`06-troubleshooting.md`) — common failure modes and resolutions.
- **Best Practices** (`07-best-practices.md`) — durable practices for architecture, provisioning,
  taxonomy, lifecycle, and safe operations.
- **Executive Summary** (`executive-summary.md`) — outcome, approach, and why the work is low-risk.

## PowerShell tools (5)

All are safe by default (read-only or `-WhatIf`), use modern-auth `Connect-*` cmdlets with no
stored credentials, and reuse the named artifacts from the implementation guide.

1. **`Invoke-SPOArchitectureAssessment.ps1`** — *Discovery (read-only).* Inventories every site
   collection, hub, base template, storage, sharing capability, and owner across the tenant and
   flags orphaned/owner-less and un-associated sites — the assessment baseline for Stage 1.

2. **`New-SPOSiteFromTemplate.ps1`** — *Provisioning helper (`-WhatIf` by default, `-Commit` to
   apply).* Computes the site name from `Naming Policy – Sites – Prod`, provisions the correct
   archetype from a PnP template, associates the target hub, applies the taxonomy, and sets owners.
   Dry-runs by default; changes nothing until `-Commit`.

3. **`Set-SPOHubAndMetadata.ps1`** — *Configuration/remediation (`-WhatIf` by default, `-Commit`).*
   Associates an existing site to its hub and applies naming/metadata (department, region) to bring
   a site into compliance with the architecture. Reversible.

4. **`Get-SPOGovernanceComplianceReport.ps1`** — *Reporting (read-only).* Checks in-scope sites for
   naming-policy compliance, hub association, presence of `Content Type – Governed Document – Prod`,
   taxonomy columns, and owners, and writes a per-site + summary compliance report.

5. **`Get-SPOScopeConfig.ps1`** — *Scope/health helper (read-only).* Verifies the toolchain and
   connection (modules, PnP app, admin role, tenant creation settings, term store/content-type
   availability) and resolves the working scope (pilot vs production hubs) before you run the
   other tools.
