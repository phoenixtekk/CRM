# Microsoft 365 Exchange Online Tenant-to-Tenant Migration (1:1 Domains) — v1.0.0

| | |
|---|---|
| **Category** | Azure Solutions |
| **Solution code** | EXOMIG |
| **Version** | 1.0.0 |
| **Slug** | `m365-exchange-tenant-to-tenant-migration` |
| **Pricing tier** | **T4 — Project / Migration** |
| **Commercial** | $3,495.00 (`PTK-EXOMIG-COMM-001`) |
| **Non-Profit** | $2,097.00 (`PTK-EXOMIG-NPO-001`, 40% off) |
| **Government** | $2,970.75 (`PTK-EXOMIG-GOV-001`, 15% off) |
| **Branding** | off (white-label) |

**Shaping notes:** _"Drive a Microsoft 365 Exchange migration 1 to 1 domains."_ → Exchange Online
mailbox tenant-to-tenant migration (source M365 tenant → target) with a **1:1 primary-domain cutover**
and mail-flow coexistence, driven by **Quest On Demand** (native MRS / ShareGate / BitTitan as
alternatives). Email-focused; SharePoint/Teams/Azure are covered by the separate
`commercial-to-gcc-high-migration-program` product.

## What it is
A phased migration runbook — **Assess → Plan → Prepare → Pilot → Migrate → Cutover → Validate →
Decommission** — to move every mailbox to a new tenant and move the primary domain 1:1, keeping mail
flowing throughout and validating at every gate.

## What's included
**Documentation (Word + PDF):** Executive Summary · Solution Overview · Requirements (+ category
Global Requirements) · Implementation Runbook (8 phases) · Testing · Troubleshooting · Best Practices ·
Deliverables Summary.

**PowerShell scripts (`EXOMIG-Scripts.zip`):** Discovery · Validation · Report · Remediation · Set-Coexistence.

**Hero image:** `EXOMIG-hero.png` (1200×1200, white-label).

## Next
Build deliverables + hero, then `/publish-solution m365-exchange-tenant-to-tenant-migration`.
