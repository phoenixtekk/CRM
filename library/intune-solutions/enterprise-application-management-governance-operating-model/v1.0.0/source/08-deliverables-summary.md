# Deliverables Summary

This solution delivers a complete application management **operating model** — the governance layer
above packaging and deployment — for a Microsoft Intune / Entra ID estate, with the tooling to stand
it up and keep it measured.

## Documents

| Document | What it gives you |
|---|---|
| **Solution Overview** (`01-solution-overview.md`) | The seven components of the operating model, how each governance decision maps to a concrete Intune/Entra object, the interface to WDAC/MDE/App Protection, and the honest scope boundaries. |
| **Global Requirements** (`global-requirements-intune-solutions.md`) | Category-level prerequisites (tenant, Intune, enrolment, Windows baseline, network). |
| **Requirements** (`02-requirements.md`) | Ten solution-specific prerequisites — executive sponsor, admin and least-privilege roles, group-creation rights, Graph SDK, a system of record, the CAB position, discovery sources, named role holders, and licence data — each with Description / Why / Verify / Implement. |
| **Implementation** (`03-implementation.md`) | Fourteen ordered steps: baseline the estate, build the register, define the RACI, create the four role groups, the two scope tags and the least-privilege custom role, the three deployment rings, the standards document, the intake workflow, the review board, the change classification matrix and CAB interface, the support model and runbook standard, stamp governance onto the existing estate, pilot for two board cycles, and expand to steady state. |
| **Testing** (`05-testing.md`) | Eight pass/fail gates — four structural (automated) and four behavioural — that prove the model holds under real traffic before you expand. |
| **Troubleshooting** (`06-troubleshooting.md`) | Fixes for the ways the model stalls in practice — script access, missing objects, quorum failures, bypass attempts, orphan reconciliation. |
| **Best Practices** (`07-best-practices.md`) | The ten disciplines that keep the model alive past month six, each countering a specific failure mode. |
| **Executive Summary** (`executive-summary.md`) | The business case in one page, for securing the sponsor. |

## PowerShell scripts

All scripts use the Microsoft Graph PowerShell SDK and accept `-GraphEnvironment USGov` for
Government tenants. Four of the five are strictly **read-only**; only Remediation writes, and it
defaults to `-WhatIf`.

| Script | Purpose | Access |
|---|---|---|
| **APPOPS-Discovery.ps1** | Inventory the estate and surface the governance gaps (orphaned, broad-target, unowned, unscoped). Seeds the register and the baseline. | Read-only |
| **APPOPS-Validation.ps1** | Test the estate against the model's structural gates — scope tags, custom role, the seven groups, and per-app naming/owner/targeting conformance. | Read-only |
| **APPOPS-Report.ps1** | Produce the monthly Application Governance Scorecard — ownership, scope-tag, and naming coverage plus broad-target and orphaned risk counts, appendable for trending. | Read-only |
| **APPOPS-Export-ApprovalEvidence.ps1** | Export the change-approval evidence trail (owner block, scope tags, ring assignments, audit events) as the ARB/audit evidence pack. | Read-only |
| **APPOPS-Remediation.ps1** | Stamp owner + ARB reference + scope tag onto existing applications from a CSV. Changes no deployment behaviour. | `-WhatIf` default |

## Artefacts the model produces (and you keep)

The Application Register, the ARB Decision Record, the RACI matrix, the Application Standards
Document, the Change Classification Matrix, the Support Matrix, the per-application Runbook, and the
Governance Scorecard — all defined in the implementation guide with exact schemas and named objects.

## How the pieces fit

1. Confirm **Requirements** — above all, secure the executive sponsor.
2. Run **Discovery** to baseline the estate and quantify the gaps.
3. Build the **objects** (register, RACI, groups, scope tags, role, rings, standards, intake, board,
   change matrix, support model) per the implementation guide.
4. Stamp governance onto the existing estate with **Remediation** (gated).
5. **Pilot** on one business unit for two board cycles; prove it with the **Testing** gates via
   **Validation**.
6. **Expand** tenant-wide; run **Report** monthly and **Export-ApprovalEvidence** for audit, and
   drive the estate down through deliberate retirement.
