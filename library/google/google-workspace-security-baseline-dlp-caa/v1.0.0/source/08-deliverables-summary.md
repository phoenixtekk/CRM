# 8. Deliverables Summary — Google Workspace Security Baseline, DLP & Context-Aware Access (CAA)

Everything included in this solution and how the pieces fit together. Use this as the index and the
definition of done.

## Documents
| Document | What it gives you |
|---|---|
| `01-solution-overview.md` | The Workspace security model — hardening baseline, DLP, CAA, and how the three layers enforce Zero-Trust. |
| `02-requirements.md` | Prerequisites with verify / implement-if-missing: edition supporting DLP/CAA, super-admin, 2SV/session/context signals, DLP scope, pilot OU, change control. |
| `03-implementation.md` | Click-by-click Admin-console steps: named hardening baseline (2SV, sessions, sharing); DLP rules for Drive/Gmail; CAA access levels + assignments; pilot then expand. |
| `05-testing.md` | Pass/fail tests per layer (baseline, DLP audit→block, CAA monitor→enforce) plus coverage and rollback checks. |
| `06-troubleshooting.md` | Symptom → cause → fix for the common baseline / DLP / CAA issues. |
| `07-best-practices.md` | Staged-enforcement discipline, identity/session hygiene, DLP tuning, CAA composition, change control. |
| `executive-summary.md` | One-page business case and outcome for decision-makers. |

## Scripts (`scripts/`)
All scripts are **read-only where they read live systems**; the two that can change state default to
**`-WhatIf`**. They use the Google Admin SDK / Reports / Drive APIs where scriptable, and consume
Admin-console exports where a setting is not exposed by API.

| Script | Type | What it does |
|---|---|---|
| `GWSEC-Discovery.ps1` | Read-only | Security-posture discovery: 2SV method availability, session-control posture, Drive external-sharing settings, and presence of DLP rules / CAA access levels. |
| `GWSEC-Validation.ps1` | Read-only | Per-OU validation of the baseline, DLP rule state, and CAA assignment state (monitor vs enforce) against the intended posture. |
| `GWSEC-Report.ps1` | Read-only | Fleet posture coverage / exceptions report across OUs — what is applied, what is missing, what is a tracked exception. |
| `GWSEC-Remediation.ps1` | **Default `-WhatIf`** | Safe remediation of scriptable findings (e.g. tighten a broadly-shared Drive item); previews by default, applies only with `-Apply`. |
| `GWSEC-Set-ScopeTargeting.ps1` | **Default `-WhatIf`** | Creates/reuses the `Security Baseline - Pilot` OU (idempotent) so baseline/DLP/CAA can be scoped consistently. |

## Named objects (reuse verbatim)
| Object | Name |
|---|---|
| Pilot OU | `Security Baseline - Pilot` |
| CAA access level | `Access - Corp Network` |
| CAA access level | `Access - Managed Device` |
| DLP rule (Drive) | `DLP - Drive - Sensitive - External` |
| DLP rule (Gmail) | `DLP - Gmail - Sensitive - Outbound` |

## Definition of done
- Hardening baseline (2SV, bounded session, restricted sharing, closed legacy surfaces) applied and
  **validated** on `Security Baseline - Pilot`, then expanded OU-by-OU.
- DLP rules for **Drive** and **Gmail** authored, run through **audit → warn → block**, tested with
  synthetic data and negative tests. *(Edition-gated — verify in your tenant.)*
- CAA access levels created and assigned **monitor → enforce**, with the Admin console gated for
  privileged OUs. *(Edition-gated — verify in your tenant.)*
- `GWSEC-Validation.ps1` passes for every in-scope OU; `GWSEC-Report.ps1` shows clean coverage with
  exceptions tracked; rollback rehearsed.

## Effort tier
**T4** — Google Workspace security transformation: architecture/governance work with live-environment
care. Deployed **pilot-first** with explicit gates and a documented rollback for every production
change.
