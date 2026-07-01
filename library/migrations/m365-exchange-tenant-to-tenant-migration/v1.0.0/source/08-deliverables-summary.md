# 8. Deliverables Summary — Microsoft 365 Exchange Online Tenant-to-Tenant Migration (1:1 Domains)

This package is a complete, runbook-grade migration kit for moving Exchange Online mailboxes between Microsoft 365 tenants and performing a 1:1 domain cutover. It contains the following deliverables.

## Documentation

| Document | Purpose |
|----------|---------|
| `01-solution-overview.md` | What the solution is, the source→target 1:1 domain model, how it works, coexistence, tooling, benefits, and honest limitations. |
| `02-requirements.md` | Requirements R1–R12, each with Description / Why / How to verify / How to implement if missing. |
| `global-requirements-azure-solutions.md` | Category-wide baseline (G1–G6) common to every Azure Solutions deliverable. |
| `03-implementation.md` | The exact ordered runbook across all eight phases, with every created object named. |
| `05-testing.md` | Numbered phase-exit tests with PASS/FAIL gates and the final Acceptance Gate. |
| `06-troubleshooting.md` | Top-down diagnosis for the common failure modes. |
| `07-best-practices.md` | Migration best practices (pre-stage + delta, throttling, comms, DNS TTL, rollback, etc.). |
| `08-deliverables-summary.md` | This document. |
| `executive-summary.md` | One-page business case and outcome. |

## PowerShell scripts

All scripts carry a header block with `.SYNOPSIS`, PURPOSE / HOW TO RUN / EXPECTED RESULTS, and a neutral `.NOTES` line. Read-only by default where they could change state; changes require an explicit `-Apply` switch and support `-WhatIf`.

| Script | What it does |
|--------|--------------|
| `scripts\EXOMIG-Discovery.ps1` | Inventories the **source** tenant: mailboxes (user/shared/room/equipment), sizes, item counts, aliases, accepted domains, distribution and Microsoft 365 groups, and mailbox permissions/delegation. Exports CSVs. **Read-only.** |
| `scripts\EXOMIG-Validation.ps1` | Pre-flight and post-migration validation: target licensing present, accepted/verified domains, mailbox provisioned, and item-count parity (source vs target) for a sample user. Prints a PASS/FAIL summary. **Read-only.** |
| `scripts\EXOMIG-Report.ps1` | Migration status/throughput report: per-wave counts, completed/failed, GB moved — read from a status CSV (exported from the engine) or live from the tenant. Exports a CSV + prints a summary. **Read-only.** |
| `scripts\EXOMIG-Remediation.ps1` | Safe remediation: re-stamps the target **primary SMTP** from `mapping.csv` and re-grants **FullAccess/SendAs** from `permissions.csv`. Defaults to `-WhatIf`; changes require `-Apply`. |
| `scripts\EXOMIG-Set-Coexistence.ps1` | Creates the mail-flow coexistence connectors (`Coexistence – Source→Target Connector`, `Coexistence – Target→Source Connector`) and, optionally, the routing-domain accepted domain, via Exchange Online PowerShell. Supports `-WhatIf`. |

## Visual asset

| Asset | Purpose |
|-------|---------|
| `EXOMIG-hero.png` | Hero image for the solution listing. |

## How the deliverables fit together

1. Run **`EXOMIG-Discovery.ps1`** to build the inventory and the `mapping.csv` / `permissions.csv` that drive everything else.
2. Use **`02-requirements.md`** + **`global-requirements-azure-solutions.md`** to confirm prerequisites; verify with **`EXOMIG-Validation.ps1`** pre-flight.
3. Follow **`03-implementation.md`** phase by phase, creating the named objects and using **`EXOMIG-Set-Coexistence.ps1`** for connectors.
4. Track progress with **`EXOMIG-Report.ps1`**; re-apply addresses/permissions with **`EXOMIG-Remediation.ps1`**.
5. Gate every phase with **`05-testing.md`**; resolve issues with **`06-troubleshooting.md`**; apply **`07-best-practices.md`** throughout.
