# 8. Deliverables Summary — Microsoft 365 Purview eDiscovery Administration

## Documentation
- **01 – Solution Overview** — the eDiscovery model (Content Search vs Standard vs Premium), cases,
  holds/custodians, review sets, analytics, export, and how it differs from Purview DLP/labels/
  retention; the reference design and deployment model.
- **02 – Requirements Guide** — every prerequisite (licensing/tier, eDiscovery roles, audit,
  in-scope workloads, legal owner, modules, pilot matter, compliance boundary, change control) with
  Verify / Implement steps and a checklist.
- **03 – Implementation Guide** — the ordered **Assess → Design → Configure → Pilot → Validate →
  Expand** build: create the case, design the KQL/condition query, run and refine Content Searches,
  place holds, and (Premium) add custodians, collect a review set, run analytics/de-dup, and export —
  every artifact named, with pass/fail gates and rollback.
- **05 – Testing & Validation** — nine procedures with expected pass/fail (search scoped, hold
  effective, export complete + defensible, audit present) and a gate summary.
- **06 – Troubleshooting** — common failure modes and resolutions (no hits, missing Teams content,
  hold not preserving, Premium features absent, export errors, boundary issues).
- **07 – Best Practices** — durable practices for defensible, least-privilege, repeatable eDiscovery.
- **Executive Summary** — outcome, approach, and why the approach is low-risk.

## PowerShell scripts (5) — safe-by-default (read-only or `-WhatIf`; modern auth; no secrets)
1. **`MSEDISC-Discovery.ps1`** — **read-only** eDiscovery posture & readiness check. Reports
   eDiscovery role-group membership (Manager/Administrator), existing cases, Content Searches, and
   case holds, and whether the unified audit log is on — the "what exists / am I ready" assessment.
2. **`MSEDISC-Search.ps1`** — **Content Search builder/runner, dry-run by default.** Echoes the
   `New-ComplianceSearch`/`Start-ComplianceSearch` it would run for `Content Search –
   <Matter>-Keywords – <Stage>` with your KQL and locations; creates and starts only with `-Apply`.
3. **`MSEDISC-CaseHold.ps1`** — **case + hold configuration helper, dry-run by default.** Creates the
   case and a case-hold policy/rule (`New-ComplianceCase`, `New-CaseHoldPolicy`, `New-CaseHoldRule`)
   named to the matter; previews by default, commits with `-Apply`. Never removes holds silently.
4. **`MSEDISC-Report.ps1`** — **search / hold / export status report (read-only).** Summarizes
   Content Search statistics and actions, case-hold status, and (where the Graph Security module is
   present) Premium case/export status, plus eDiscovery audit activity — the evidence pack.
5. **`MSEDISC-Scope.ps1`** — **scope / config helper, dry-run by default.** Reports and (with
   `-Apply`) creates a **compliance security filter** (`New-ComplianceSecurityFilter`) to enforce an
   eDiscovery boundary, and validates that the matter's named objects exist. The boundary *policy* is
   a legal/HR determination; the script only implements it.

All scripts print clear, named output referencing the same artifact names used in the Implementation
and Testing guides, so the docs and automation stay in lockstep.
