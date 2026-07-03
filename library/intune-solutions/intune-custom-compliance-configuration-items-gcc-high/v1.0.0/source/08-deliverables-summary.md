# Deliverables Summary — Intune Custom Compliance & Configuration Items (Scripted), Government (GCC High) Edition

Everything included in this solution, and how the pieces fit together for a **GCC High** deployment.

## Documents

| Document | What it gives you |
| --- | --- |
| `executive-summary.md` | The problem, the sovereign-cloud solution, and the outcome — for decision-makers. |
| `01-solution-overview.md` | What custom compliance is on GCC High, named objects to reuse, and the **Commercial vs GCC High — what's different** map. |
| `02-requirements.md` | GCC-High-specific prerequisites (R1–R8) with Verify / Implement steps. Category-level basics live in `global-requirements-intune-solutions.md`. |
| `03-implementation.md` | Ordered, click-by-click deployment in the `*.us` portals, with GCC-High caveats inline. Assess → Configure → Pilot → Validate → Expand. |
| `05-testing.md` | Nine pass/fail validation tests (T1–T9) run against the pilot group. |
| `06-troubleshooting.md` | GCC-High-specific failure modes and fixes (silent "no result," wrong cloud, TLS inspection, scope-tag block). |
| `07-best-practices.md` | Sovereign-cloud discipline, discovery-script hygiene, JSON design, rollout safety, operations. |
| `gcc-high-parity-notes.md` | Cited Commercial-vs-GCC-High reference; every row cited or flagged "verify for GCC High." |
| `08-deliverables-summary.md` | This document. |

## Scripts (all connect to US Gov Graph with `-Environment USGov`)

| Script | Mode | Purpose |
| --- | --- | --- |
| `CUSTCOMPG-Discovery.ps1` | **Read-only** | Inventory discovery scripts, custom-compliance policies, and target groups in the GCC High tenant. Your API-recon tool (Graph Explorer is unavailable for `graph.microsoft.us`). |
| `CUSTCOMPG-Validation.ps1` | **Read-only** (local) | Pre-flight the discovery script + JSON: single-line compressed output, key/DataType alignment (case-sensitive), and Intune size/runtime limits — before upload. |
| `CUSTCOMPG-Report.ps1` | **Read-only** | Per-device compliance status for the policy, highlighting "not evaluated" devices (the GCC High TLS-inspection symptom); optional CSV. |
| `CUSTCOMPG-Remediation.ps1` | **`-WhatIf` by default** | Reconcile the tenant to your source-controlled discovery script; confirm policy linkage. Previews unless run with `-WhatIf:$false`. |
| `CUSTCOMPG-Set-ScopeTargeting.ps1` | **`-WhatIf` by default** | Stage devices into the pilot/production target groups in controlled waves. Previews membership changes unless run with `-WhatIf:$false`. |

**Safety model:** the three read-only scripts never change tenant state. The two change-making scripts (`Remediation`, `Set-ScopeTargeting`) **preview by default** and only write when you explicitly pass `-WhatIf:$false`. Every script verifies `(Get-MgContext).Environment = USGov` before trusting or changing anything.

## Companion artifacts you create

| Artifact | Where | Notes |
| --- | --- | --- |
| `CUSTCOMPG-Rules.json` | Uploaded into the compliance policy | The JSON rules file (SettingName / Operator / DataType / Operand / MoreInfoUrl / RemediationStrings). Validate with `CUSTCOMPG-Validation.ps1`. |
| Discovery script (`CUSTCOMPG-Discovery-Win`) | Intune → Endpoint security → Device compliance → Scripts | Windows PowerShell; ends in `ConvertTo-Json -Compress`. |
| `CUSTCOMPG-Pilot-Devices` / `CUSTCOMPG-Prod-Devices` | Entra (`entra.microsoft.us`) → Groups | Assignment targets for the policy. |

## The order to use them

1. **Assess** — `02-requirements.md`; confirm `Connect-MgGraph -Environment USGov` returns `USGov`; validate the discovery script + JSON with `CUSTCOMPG-Validation.ps1`.
2. **Configure** — `03-implementation.md` Phase 1; use `CUSTCOMPG-Discovery.ps1` to confirm objects; optionally `CUSTCOMPG-Remediation.ps1 -WhatIf` to preview reconciliation.
3. **Pilot** — assign to `CUSTCOMPG-Pilot-Devices`; check results with `CUSTCOMPG-Report.ps1`.
4. **Validate** — run all of `05-testing.md` (T1–T9).
5. **Expand** — stage waves with `CUSTCOMPG-Set-ScopeTargeting.ps1` (preview, then apply); add `CUSTCOMPG-Prod-Devices` to the policy; wire Conditional Access last.

Every URL and behavior in these deliverables is cited to current Microsoft Learn documentation or flagged **"verify for GCC High."** See `gcc-high-parity-notes.md`.
