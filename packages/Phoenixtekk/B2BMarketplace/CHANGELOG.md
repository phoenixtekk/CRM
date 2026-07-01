# Changelog — Phoenixtekk B2B Marketplace

All notable changes to this package are documented here. Format loosely follows Keep a Changelog;
versioning is semantic.

## [1.0.0] — 2026-06-14
### Added
- Native Bagisto package scaffold (`Phoenixtekk\B2BMarketplace`) with service provider, routes,
  views, config, and migrations — no Bagisto core modifications.
- **Supplier companies**: `pt_b2b_suppliers` with statuses pending / approved / rejected / suspended,
  approval metadata (approved_by, approved_at, rejected_reason, status_changed_at).
- **Supplier registration** (storefront): authenticated customers apply; duplicate active
  applications prevented; new applications default to pending.
- **Admin approval**: admin pages to review applications and approve / reject / suspend / reactivate;
  admin menu + ACL entries.
- **RFQ system**: `pt_b2b_rfqs` + items, messages, and supplier quotes; statuses draft → submitted →
  supplier_review → quoted → accepted / rejected / cancelled / expired.
- **Supplier dashboard**: approved suppliers view their profile, browse open RFQs, and submit quotes;
  pending suppliers are blocked from dashboard actions.
- **Company accounts**: `pt_b2b_companies` + `pt_b2b_company_users` with roles owner / admin / buyer /
  viewer; owners/admins manage the company profile and users; company users create RFQs.
- Authorization policies (Supplier, Company, RFQ) + FormRequest validation for all writes.
- README, this changelog, and a manual test checklist.
