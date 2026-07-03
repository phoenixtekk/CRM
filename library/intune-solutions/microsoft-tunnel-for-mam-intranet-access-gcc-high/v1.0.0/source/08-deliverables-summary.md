# Deliverables Summary — Microsoft Tunnel for MAM — Government (GCC High) Edition

**Solution code:** TUNMAMG · **Platform:** Microsoft Intune · **Cloud:** US Sovereign (GCC High / DoD)

Everything included in this solution package and what each piece is for.

---

## Documents (source)
| File | Purpose |
| --- | --- |
| `executive-summary.md` | Business framing, the availability finding, and the no-FIPS caveat for decision-makers. |
| `01-solution-overview.md` | What Tunnel for MAM is on GCC High, the **Commercial vs GCC High — what's different** comparison, and the availability caveat up front. |
| `02-requirements.md` | Every prerequisite (R1–R11) with **verify** + **implement** steps and the object naming convention. |
| `03-implementation.md` | Ordered, click-by-click steps in the **`*.us`** portals — gateway install with `intune_env=FXP`, server config, site, and the three MAM policies per platform — with Government caveats inline. |
| `05-testing.md` | Automated (control-plane) + manual (data-plane) tests with explicit **pass/fail gates**, plus Government-specific verification. |
| `06-troubleshooting.md` | Symptom → cause → fix, weighted toward GCC-High-specific gotchas. |
| `07-best-practices.md` | Operational guidance; Government-specific items marked **[GOV]**. |
| `gcc-high-parity-notes.md` | Cited Commercial-vs-Government parity reference (availability, FIPS, portals, Graph endpoints, Cloud PKI, licensing). |
| `08-deliverables-summary.md` | This file. |

*(Category-level prerequisites are published once in `global-requirements-intune-solutions.md`.)*

---

## PowerShell scripts (`scripts/`)
All connect to **US Government Microsoft Graph** (`-Environment USGov`; pass DoD parameters for `USGovDoD`). Discovery/Validation/Report are **read-only**; Remediation and Set-ScopeTargeting default to **`-WhatIf`** (no change until you add `-Commit`).

| Script | Type | What it does |
| --- | --- | --- |
| `TUNMAMG-Discovery.ps1` | Read-only | Inventories the Government tenant: Tunnel sites/server configs, Tunnel-for-MAM app config/protection policies, target groups, and confirms the Graph context is a US Gov endpoint. |
| `TUNMAMG-Validation.ps1` | Read-only | Checks the deployment against this solution's expected state (gates A1–A9 in `05-testing.md`): site/server present & online, all three policies per platform exist and share assignment groups, single Defender policy, no MDM/MAM collision, licensing present. |
| `TUNMAMG-Report.ps1` | Read-only | Produces a point-in-time summary/evidence report (console + optional CSV/JSON) of the Tunnel-for-MAM configuration for audits and change records. |
| `TUNMAMG-Remediation.ps1` | Safe write (`-WhatIf` default) | Proposes and (with `-Commit`) applies safe fixes — e.g., aligning assignment groups across the three policies, flagging duplicate Defender policies. Never deletes gateway infrastructure. |
| `TUNMAMG-Set-ScopeTargeting.ps1` | Safe write (`-WhatIf` default) | Creates/populates the pilot and production groups (`GRP-TUNMAMG-Pilot` / `GRP-TUNMAMG-Prod`) and can align policy assignments to them. |

**Run pattern:**
```
powershell -ExecutionPolicy Bypass -File .\scripts\TUNMAMG-Discovery.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\TUNMAMG-Validation.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\TUNMAMG-Report.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\TUNMAMG-Set-ScopeTargeting.ps1   # add -Commit to apply
powershell -ExecutionPolicy Bypass -File .\scripts\TUNMAMG-Remediation.ps1          # add -Commit to apply
```

---

## Named objects this solution creates
`SC-TUNMAMG-Gov` (server config) · `SITE-TUNMAMG-Gov` (site) · `AC-TUNMAMG-Defender-Android`, `AC-TUNMAMG-Edge-Android`, `AP-TUNMAMG-Edge-Android` (Android policies) · `AC-TUNMAMG-Edge-iOS`, `AP-TUNMAMG-iOS` (iOS policies) · `CERT-TUNMAMG-Root` (trusted root, if needed) · `GRP-TUNMAMG-Pilot`, `GRP-TUNMAMG-Prod` (groups).

---

## Deployment model
**Assess → Configure → Pilot → Validate → Expand**, with a go/no-go gate between phases (including a Government compliance gate for the no-FIPS decision).

---
*White-label solution. Verify all GCC-High/DoD specifics against current Microsoft US Government documentation at deployment time.*
