# 8. Deliverables Summary — SharePoint Online Search & Information Architecture

## Documentation
- **01 — Solution Overview:** how SPO/Microsoft Search works (crawling, the search schema, result
  sources/verticals, promoted results) and the IA that feeds it; the reference design, limitations, naming
  convention, and deployment model.
- **02 — Requirements:** solution-specific prerequisites (Search Administrator access, term-store rights,
  content-type publishing surface, findability intent + query inventory, refinable-property register, pilot
  scope, reindex/change window) building on the shared SharePoint global requirements.
- **03 — Implementation:** the ordered runbook — Assess → Design → Configure metadata/content types →
  Configure search schema → Configure result sources/verticals/bookmarks → Pilot → Validate → Expand — with
  every artifact named and explicit pass/fail gates plus a documented rollback.
- **05 — Testing & Validation:** twelve tests (metadata, crawled/managed properties, queryable/retrievable/
  refinable, known-item queries, result source, vertical, bookmark, no-regression, rollback) each with
  pass/fail.
- **06 — Troubleshooting:** common failure modes (empty refiners, mapping not taking effect, crawled property
  missing, vertical/bookmark not showing, alias collisions) and resolutions.
- **07 — Best Practices:** durable practices for IA, schema discipline, change/reindex management, the search
  experience, sustainment, and safety/compliance boundaries.
- **Executive Summary:** outcome, approach, and why it is low-risk.

## PowerShell scripts (5) — SharePoint Online Management Shell / PnP / Graph, safe-by-default
1. **`Get-SearchIAAssessment.ps1`** — *Discovery (read-only).* Enumerates term sets, published content types,
   site columns, and the current managed-property → crawled-property mappings with their flags; captures the
   tenant search-config **rollback baseline**. Produces `Findability Assessment – Tenant – Discovery`.
2. **`Set-ManagedPropertyMapping.ps1`** — *Configuration helper (`-WhatIf` by default).* Maps crawled →
   refinable managed properties with alias and searchable/queryable/retrievable/refinable flags from a CSV;
   dry-runs unless `-Commit` is passed; always exports a baseline first and re-imports the edited schema at
   the chosen scope.
3. **`Set-SearchSourceVertical.ps1`** — *Experience config helper (`-WhatIf` by default).* Creates scoped
   **result sources** and enumerates the **verticals** and **promoted results / bookmarks** to configure in
   the Microsoft Search & Intelligence admin center; dry-runs unless `-Commit` is passed.
4. **`Test-Findability.ps1`** — *Validation (read-only).* Runs the test-query inventory with
   `Submit-PnPSearchQuery`, checks each returns its expected top result and required managed properties, and
   writes `Findability Validation – Pilot – Validation` with a pass count (Gate 5 / Gate 6).
5. **`Get-SearchHealthScope.ps1`** — *Scope/health helper (read-only).* Reports content-type/metadata
   coverage across sites, confirms expected managed-property aliases exist in the tenant schema, and checks
   bookmark-target reachability — for scheduled monitoring and drift detection.

All scripts use modern-auth `Connect-*` (no stored credentials or secrets), default to read-only or
`-WhatIf`, and require an explicit `-Commit`/`-Apply` switch before any change.
