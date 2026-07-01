# 7. Best Practices — Software License Usage Reporting & Cost Dashboards (Power BI)

- Fix the KPI set first. Lock `License KPI Set – Software Assets – v1` (formula and source per KPI)
  before building anything; every page implements it. This is the single most important practice — it
  prevents two pages from defining "usage" two ways.
- Reconcile before you distribute. Always pass the reconciliation gate (`LICRPT-Validation.ps1` plus a
  manual spot-check) on a pilot scope before leadership or procurement sees a number; a wrong number
  loses the dashboard's credibility permanently.
- Separate entitled, deployed, and actively used. Report all three per product; the gap between
  deployed and actively used is the reharvesting opportunity, and the gap between entitled and deployed
  is the compliance/true-up signal.
- Name every artifact with `<Purpose> – <Scope> – <Stage>` and reuse the names verbatim across the
  dataset, pages, refresh schedule, and audience group, so the whole reporting layer is traceable.
- Sort expirations soonest-first. The expirations page exists to prevent renewal surprises; ascending
  days-to-expiration is what makes it actionable.
- Define "idle" explicitly. Document the active-usage window (for example 30 or 90 days) in the KPI set
  so reharvesting numbers are defensible to the seat owner.
- Schedule refresh to match decisions, not vanity. Daily for fast-moving SaaS, weekly for stable
  perpetual products; always set a failure-notification address so a stale dashboard does not pass unnoticed.
- Keep read-only. The reporting layer reads license and usage data; reclaiming seats and renewing
  contracts run through the intake process (global G6), never from the dashboard.
- Document the cost basis. Record whether unit cost is annualized, list, or negotiated, so cost-per-seat
  and savings figures are comparable across products and audits.
- Use a gateway for on-prem sources. Bind on-prem files/databases to the on-premises data gateway so
  scheduled refresh stays unattended instead of failing silently.
