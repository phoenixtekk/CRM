# 8. Deliverables Summary — Compliance-Failure Diagnostics (Government / GCC High)

Everything included in the **Government (GCC High) edition** of the Intune Compliance-Failure
Diagnostics & Remediation solution, and how the pieces fit together. All portals are **`*.us`**; all
scripts connect to **US Gov Graph** (`Connect-MgGraph -Environment USGov`; DoD: `-Environment
USGovDoD`).

## Documents

| Deliverable | What it gives you |
| --- | --- |
| **01 — Solution Overview** | What the solution does, the deployment model, and the **Commercial vs GCC High — what's different** table (portals, endpoints, feature parity). |
| **Executive Summary** | One-page business framing: the problem, the solution, the GCC High parity gaps that matter, and the value. |
| **02 — Requirements Guide** | Every prerequisite with **Verify / Implement**, confirmed in the `*.us` portals — including the US Gov service **endpoints** (and the no-SSL-inspection rule) and Graph-PowerShell `-Environment USGov` setup. |
| **03 — Diagnostic Playbook** | The core deliverable: a **symptom-driven decision tree** (Branches A–E) from reported symptom → exact GCC High blade → safe fix → validation, with GCC High parity notes inline at each step. |
| **05 — Testing Guide** | Nine pass/fail tests proving you're in the right cloud, endpoints are reachable/uninspected, scripts match the portal, fixes turn devices Compliant, and parity gaps are handled. |
| **06 — Troubleshooting Guide** | Failures of the **tooling/environment** (wrong cloud, TLS interception, stuck "Not evaluated," MTD/Autopilot parity gaps, propagation lag) with fixes. |
| **07 — Best Practices** | Operating principles: sovereign-cloud hygiene, diagnose-before-change, pilot/`-WhatIf` safety, CA-vs-compliance separation, evidence and least privilege. |
| **GCC High Parity Notes** | The **cited** reference for every Commercial-vs-GCC High difference, sourced to Microsoft US Government docs, with unconfirmed items flagged **"verify for GCC High."** |
| **08 — Deliverables Summary** | This document. |

## PowerShell scripts (US Gov Graph)

All scripts begin with a standard header (purpose, how-to-run, expected results) and use **US Gov Graph
endpoints**. Read-only scripts make no changes; change scripts **default to `-WhatIf`** and require an
explicit execute flag.

| Script | Type | What it does |
| --- | --- | --- |
| **INTCOMPDXG-Discovery.ps1** | Read-only | Snapshots a device/tenant: enrollment state, last check-in, applied compliance policies, and each failing setting — the starting point of the Playbook. |
| **INTCOMPDXG-Validation.ps1** | Read-only | Pass/fail check that a specific device (or group) now meets its assigned compliance policy after a fix. |
| **INTCOMPDXG-Report.ps1** | Read-only | Compliance rollup across a group/tenant (compliant / non-compliant / not-evaluated / grace) to confirm scope and match the portal. |
| **INTCOMPDXG-Remediation.ps1** | Change (**`-WhatIf` default**) | Previews then (with `-Execute`) applies safe remediation actions (e.g. trigger a compliance re-evaluation / sync, clear a stale grace state) for targeted devices. |
| **INTCOMPDXG-Set-ScopeTargeting.ps1** | Change (**`-WhatIf` default**) | Previews then (with `-Execute`) adds/removes a compliance policy's **group assignment** so you can pilot a fix on the affected population. |

## How they work together

1. **Assess** — `INTCOMPDXG-Discovery.ps1` + `INTCOMPDXG-Report.ps1` capture the exact symptom and its
   spread.
2. **Diagnose** — the **Diagnostic Playbook** (03) routes the symptom to the correct `*.us` blade and
   fix, confirming the rule's feature is **supported in GCC High** first.
3. **Pilot** — `INTCOMPDXG-Set-ScopeTargeting.ps1` (`-WhatIf` → `-Execute`) scopes the fix to a pilot
   group.
4. **Validate** — `INTCOMPDXG-Validation.ps1` + the portal confirm the device turns **Compliant**.
5. **Remediate & Expand** — `INTCOMPDXG-Remediation.ps1` (`-WhatIf` → `-Execute`) applies at scale in
   waves, re-validating each wave.

## Success criteria
- You operate entirely in the **`*.us`** portals and **USGov** Graph environment.
- Affected devices move from **Not compliant / Not evaluated** to **Compliant**, and Conditional Access
  unblocks the user.
- No device is left stuck on a **GCC High parity gap**; every change was previewed (`-WhatIf`) and
  piloted before expansion.
