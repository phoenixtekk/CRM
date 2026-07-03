# Deliverables Summary — Egress Filtering for M365/Intune Endpoints (Government / GCC High)

Everything included in this solution, and exactly what each item does. All artifacts are authored for
the **US Government GCC High** cloud and derive Microsoft's required set from the **`USGovGCCHigh`**
instance of the IP/URL web service — **no Microsoft IPs are hardcoded.**

## Documents (`source/`)

| Document | What it gives you |
| --- | --- |
| `01-solution-overview.md` | What the solution does, the governing "query the right instance" rule, and a full **Commercial vs GCC High — what's different** table |
| `02-requirements.md` | Every prerequisite (R1–R9) with **Verify** and **Implement-if-missing**, GCC High–specific, plus the no-inspect and fixed-FQDN facts |
| `03-implementation.md` | Step-by-step: derive the Gov set → build the allow-list/URL/no-inspect objects → pilot → validate → expand → keep current, with a gate per phase |
| `05-testing.md` | Pass/fail gates for each phase and a post-change regression test |
| `06-troubleshooting.md` | GCC High–specific symptoms, causes, and fixes (wrong instance, `.com` vs `.us`, inspected no-inspect endpoints, 429s) |
| `07-best-practices.md` | Operating discipline: right cloud, no hardcoding, honor bypass list, pilot first, 30-day window |
| `08-deliverables-summary.md` | This inventory |
| `executive-summary.md` | One-page business case for a decision-maker |
| `gcc-high-parity-notes.md` | Cited reference: instance names, Gov portals/FQDNs, no-inspect endpoints, and Commercial-vs-GCC-High parity gaps |
| `global-requirements-network.md` | Category-level prerequisites (G1–G7) shared across Network solutions |

## Scripts (`scripts/`)

All scripts query the **`USGovGCCHigh`** instance, use **`-Environment USGov`** for any Graph call,
and confirm the returned instance before doing work. Read-only scripts make no changes; change-capable
scripts default to **`-WhatIf`**.

| Script | Role | Changes anything? |
| --- | --- | --- |
| `EGRESSG-Discovery.ps1` | Derives the current GCC High required set from the web service; writes `EGRESSG-Endpoints-USGovGCCHigh.json` + summary; detects version changes vs `EGRESSG-latestversion.txt` and emits a diff | **No** (read-only) |
| `EGRESSG-Validation.ps1` | From a real endpoint, tests reachability to representative Gov endpoints per service area; PASS/FAIL | **No** (read-only) |
| `EGRESSG-Report.ps1` | Produces a dated, point-in-time audit report of the derived set and its categories/ports | **No** (read-only) |
| `EGRESSG-Remediation.ps1` | Regenerates the corrected derived allow-list export and flags drift; **`-WhatIf` by default**, writes only with `-Execute` | Only with `-Execute` |
| `EGRESSG-Set-ScopeTargeting.ps1` | Creates/populates the `EGRESSG-Pilot` Entra group via Graph (`-Environment USGov`); **`-WhatIf` by default**, applies only with `-Execute` | Only with `-Execute` |

## Named objects you will create

| Object | Where | Purpose |
| --- | --- | --- |
| `EGRESSG-Endpoints-USGovGCCHigh.json` | Script host | Raw derived GCC High set (source of truth for the allow-list) |
| `EGRESSG-M365-GCCHigh-Allow` | Egress device | IP address group (derived CIDR ranges) |
| `EGRESSG-M365-GCCHigh-URLs` | Egress device | URL category / bypass for required FQDNs |
| `EGRESSG-NoInspect-GCCHigh` | Egress device | SSL-inspection bypass list (no-inspect endpoints) |
| `EGRESSG-Pilot` | Entra | Staged-rollout group |
| `EGRESSG-latestversion.txt` | Script host | Version + ClientRequestId checkpoint |

## Compiled deliverables (produced by the build, not by this authoring)

- `EGRESSG-Solution.pdf` — the full solution document.
- `EGRESSG-Scripts.zip` — the five PowerShell scripts packaged for distribution.

## Definition of done

A deployment is "done" when: the tenant is confirmed GCC High; the allow-list, URL category, and
no-inspect list are built **from the derived `USGovGCCHigh` set**; the pilot validated with all checks
PASS; the fleet is covered; and the monthly keep-current job runs and reports "up to date" or a
reviewed change set.
