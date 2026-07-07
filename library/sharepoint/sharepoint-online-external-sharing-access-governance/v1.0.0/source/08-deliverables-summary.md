# 8. Deliverables Summary — SharePoint Online External Sharing & Access Governance

## Documentation
| Document | What it gives you |
|---|---|
| **01 — Solution Overview** | The sharing model (tenant vs OneDrive vs site), link types/defaults/expiration, allow/block domains, sensitivity-label container controls, guests/reviews, exposure reporting; the reference model of named artifacts; benefits, limitations, and the deployment model. |
| **02 — Requirements** | Solution-specific prerequisites (SharePoint Admin role, SPO Management Shell / PnP / Graph, a signed-off sharing policy, published sensitivity labels, Entra ID Governance licensing for reviews, a named pilot scope) — each with Verify / Implement, building on the SharePoint global requirements. |
| **03 — Implementation** | Exact ordered steps: Assess → Design → Configure/Pilot (per-site tightening, then tenant baseline in a change window, then guest reviews) → Validate → Expand, every artifact named, with pass/fail gates and a rollback table. |
| **05 — Testing** | 11 validation tests (T1–T11), each with how-to-run and expected PASS/FAIL, plus the go/no-go gate summary. |
| **06 — Troubleshooting** | Common failure modes (settings not taking, site can't exceed tenant, broken links after tightening, domain block not working, guest expiration missing, PnP enumeration throttled, Gov-cloud endpoints, label not applying) and their resolutions. |
| **07 — Best Practices** | Durable practices: policy first, safe link defaults, expire-everything, tighten by tier, allow-list domains, guest lifecycle reviews, cadenced exposure reporting, safe operations. |
| **Executive Summary** | One-page outcome/approach/why-low-risk for sponsors. |

## PowerShell scripts (5)
All are **safe by default** — read-only or `-WhatIf`/dry-run unless you pass `-Commit`. None store
credentials; all use modern-auth `Connect-*`. Connect to the SPO **admin** endpoint (and PnP per site /
Graph) before running.

| # | Script | Archetype | What it does |
|---|---|---|---|
| 1 | **SPOEXT-Discovery.ps1** | Discovery (read-only) | Captures the `External Exposure – SPO – Discovery` baseline: tenant + OneDrive sharing capability, default link type/permission, Anyone-link + guest expiration, domain mode/lists, per-site `SharingCapability`, and external-user count. |
| 2 | **SPOEXT-Set-Sharing.ps1** | Configuration/Remediation (`-WhatIf`/`-Commit`) | Applies `Tenant Sharing Baseline – SPO – Prod` (via `Set-SPOTenant`) and/or tightens sites in scope (`Set-SPOSite -SharingCapability`). Dry-run first; refuses to make a site looser than the tenant. |
| 3 | **SPOEXT-Validation.ps1** | Validation (read-only) | Compares live tenant + per-site settings against the expected policy values and prints PASS/FAIL per check (exit 1 on any fail). |
| 4 | **SPOEXT-ExposureReport.ps1** | Reporting (read-only) | Enumerates sharing links across the sites in scope via PnP (flags Anyone-links, no-expiration links, external principals) and optionally lists external users — the `External Exposure – SPO – Report` and the guest-review fallback. |
| 5 | **SPOEXT-Scope.ps1** | Scope/health helper (read-only) | Verifies modules, the SPO admin connection, Commercial-vs-Government cloud, that OneDrive is not looser than the tenant, and that every pilot-site URL resolves. |

## The named artifacts you end up with
`External Exposure – SPO – Discovery` · `Tenant Sharing Baseline – SPO – Prod` · `Sharing Scope – Pilot
– Stage1` / `Sharing Scope – Broad – Stage2` · `Site Sharing – <SiteName> – Prod` · `Link Default –
Specific-People-View – Prod` · `Anyone Link Expiration – 30d – Prod` · `Guest Expiration – 60d – Prod` ·
`Domain Allowlist – Partners – Prod` / `Domain Blocklist – Restricted – Prod` · `Container Label –
<Level> – Prod` · `Access Review – Guests – Quarterly` · `External Exposure – SPO – Report`.
