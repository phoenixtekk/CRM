# Deliverables Summary — Exchange Online Tenant-to-Tenant Migration (Government / GCC High)

Everything included in this Government (GCC High) edition, and how the pieces fit together.

---

## Documents (`source/`)

| File | Purpose |
|---|---|
| `01-solution-overview.md` | What the solution does, the deployment model, and **Commercial vs GCC High — what's different** (with the cross-cloud-unsupported caveat up front). |
| `02-requirements.md` | Prerequisites R0–R8 (each with GCC High verify/implement steps), plus the category baseline G1–G6. |
| `03-implementation.md` | Ordered Assess→Configure→Pilot→Validate→Expand steps using the `*.us` portals, with GCC-High caveats inline. |
| `05-testing.md` | Pass/fail gates for every phase (Gate 0–6). |
| `06-troubleshooting.md` | GCC-High-specific failure diagnosis (wrong-cloud, licensing, ExchangeGUID, DNS, endpoints). |
| `07-best-practices.md` | Field guidance for running the move safely inside the sovereign boundary. |
| `gcc-high-parity-notes.md` | **Cited** Commercial→GCC High map: endpoints, portals, licensing, roles, support status. |
| `executive-summary.md` | One-page brief for decision-makers. |
| `global-requirements-azure-solutions.md` | Category baseline (G1–G6). |

---

## Scripts (`scripts/`)

All connect to **US Gov Graph / EXO** endpoints (`-Environment USGov`, `-ExchangeEnvironmentName O365USGovGCCHigh`). Read-only scripts make **no** changes. Change-capable scripts default to **`-WhatIf`**.

| Script | Type | What it does |
|---|---|---|
| `EXOMIGG-Discovery.ps1` | **Read-only** | Inventories both tenants: cloud/environment, mailboxes/sizes, licensing, DNS (MX/Autodiscover/SPF/DKIM/DMARC), roles. Writes the `EXOMIGG-baseline\`. |
| `EXOMIGG-Validation.ps1` | **Read-only** | Verifies modules, Gov connectivity, roles, license counts, endpoint reachability; reports pass/fail per check. |
| `EXOMIGG-Report.ps1` | **Read-only** | Per-mailbox migration status, item/folder counts, permissions — for pilot/wave validation and closeout. |
| `EXOMIGG-Remediation.ps1` | **Change (default `-WhatIf`)** | Safe fixes for common blockers (e.g., clear stale ExchangeGUID, reset default addresses, re-stamp proxies). Requires explicit `-Execute` to act. |
| `EXOMIGG-Set-ScopeTargeting.ps1` | **Change (default `-WhatIf`)** | Builds pilot/wave target groups (`EXOMIGG-Pilot`, `EXOMIGG-Wave1..N`) from a mapping CSV. Requires explicit `-Execute` to act. |

---

## How the deliverables work together

1. **Assess** — run `EXOMIGG-Discovery.ps1` (+ `EXOMIGG-Validation.ps1`) to capture the baseline and pass Gate 1.
2. **Configure** — assign roles/licensing in the `*.us` portals, set up the engine (native org relationship or vendor tool), re-run `EXOMIGG-Validation.ps1` to pass Gate 2.
3. **Pilot** — build `EXOMIGG-Pilot` with `EXOMIGG-Set-ScopeTargeting.ps1`, move it, validate with `EXOMIGG-Report.ps1` to pass Gate 3.
4. **Expand** — build waves, move, validate each with `EXOMIGG-Report.ps1` (Gate 4), then cut over DNS (Gate 5) and close out (Gate 6).
5. `EXOMIGG-Remediation.ps1` (`-WhatIf` first) resolves blockers surfaced by validation/testing at any point.

---

## Scope boundaries

- **In scope:** tenant preparation, identity/licensing/endpoint configuration, DNS cutover, pilot/wave orchestration, and validation for a **1:1-domain Exchange Online move within GCC High**.
- **Out of scope / deferred:** the **internals of any third-party migration tool** (deferred to that vendor's GCC High documentation); DoD (L5) endpoints (this edition targets GCC High L4); SharePoint/OneDrive/Teams data migration (Exchange-focused).
- **Hard constraint:** native cross-cloud (Commercial↔GCC High) mailbox migration is **not supported** — use a third-party tool or PST for cross-cloud mail data.
