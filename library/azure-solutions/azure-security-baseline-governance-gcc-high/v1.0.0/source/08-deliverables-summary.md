# Deliverables Summary — Azure Security Baseline & Governance (Government / GCC High)

Everything included in this solution package, and what each piece is for. All content is authored for **Azure Government / GCC High** — sovereign `*.us` portals and US Gov endpoints throughout.

---

## Documentation

| Document | Purpose |
| --- | --- |
| `executive-summary.md` | One-page business framing: why Gov differs from Commercial and what the solution delivers. |
| `01-solution-overview.md` | The solution, the deployment model, and an explicit **Commercial vs Azure Government — what's different** section. |
| `02-requirements.md` | Solution-specific prerequisites (Gov subscription, Gov licensing, roles, MG access, Defender scope, Log Analytics, endpoints, modules) — each with Description / Why / Verify / Implement-if-missing. |
| `03-implementation.md` | Exact ordered steps using `portal.azure.us`, Assess→Configure→Pilot→Validate→Expand, with Gov caveats inline and named objects. |
| `05-testing.md` | Pass/fail test matrix and procedures, validated against US Gov endpoints. |
| `06-troubleshooting.md` | Gov-specific gotchas (wrong cloud, endpoint/redirect errors, unavailable plans, region traps) and fixes. |
| `07-best-practices.md` | Ongoing operating guidance for the baseline on a Gov tenant. |
| `gcc-high-parity-notes.md` | Concise Commercial-vs-Gov reference; every row cited to a Microsoft doc or flagged **verify for Azure Government**. |
| `global-requirements-azure-solutions.md` | Shared platform prerequisites common to all Azure solutions. |

## Scripts (`scripts/`)

All scripts connect to **US Gov endpoints** (`Connect-AzAccount -Environment AzureUSGovernment` / `Connect-MgGraph -Environment USGov`) and fail fast if the context is not Azure Government.

| Script | Mode | Purpose |
| --- | --- | --- |
| `AZSECG-Discovery.ps1` | Read-only | Inventory current MGs, RBAC, policy, Defender plans, Secure Score — the pre-change baseline. |
| `AZSECG-Validation.ps1` | Read-only | Run the pass/fail test matrix against the deployed baseline. |
| `AZSECG-Report.ps1` | Read-only | Produce an HTML evidence report (compliance, Defender plans, Secure Score, log flow). |
| `AZSECG-Remediation.ps1` | **`-WhatIf` by default** | Trigger policy remediation / bring resources into compliance; requires `-Apply` to commit. |
| `AZSECG-Set-ScopeTargeting.ps1` | **`-WhatIf` by default** | Tag/move subscriptions into the governance stage (pilot/expand); requires `-Apply` to commit. |

## Named objects the solution creates

| Object | Name |
| --- | --- |
| Governance root MG | `Governance Root MG` |
| Platform MG | `Platform MG` |
| Landing zones MG | `Landing Zones MG` |
| Custom RBAC role | `Governance Operator – Landing Zones – Pilot` |
| Policy initiative assignment | `Security Baseline Initiative – Governance Root – Pilot` |
| Log Analytics workspace | `Governance Logs Workspace – Platform – Pilot` |
| Pilot subscription tag | `governance-stage = pilot` |

## How to use the package

1. Read `executive-summary.md` and `01-solution-overview.md` (especially the Commercial-vs-Gov section).
2. Work through `02-requirements.md`; verify each item in `portal.azure.us`.
3. Follow `03-implementation.md` stage by stage; run the scripts where indicated.
4. Validate with `05-testing.md`; keep `AZSECG-Report.ps1` output as audit evidence.
5. Consult `06-troubleshooting.md` and `gcc-high-parity-notes.md` whenever behavior differs from Commercial expectations.

## Definition of done

Named governance hierarchy in place; least-privilege RBAC assigned; policy initiative enforced and proven on the pilot; Gov-available Defender plans on with Secure Score tracked; audit logs flowing to the Gov-region workspace; validation + report evidence captured; rollback rehearsed.
