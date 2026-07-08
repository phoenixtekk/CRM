# 8. Deliverables Summary — eDiscovery Readiness Assessment (Microsoft Purview)

## Documentation
- **01 – Solution Overview** — what a readiness assessment is (and how it differs from operating
  matters via the eDiscovery Administration solution), why readiness is the risk, the four-domain
  rubric (**Roles / Holds / Scope / Process**), the assessment model, the reference naming for the
  readiness proof, and what legal owns.
- **02 – Requirements Guide** — the solution-specific prerequisites (eDiscovery tier/licensing,
  least-privilege assessor roles, audit log, data-source + inactive-mailbox scope, named legal owner +
  intake, modules, a dedicated **test account** for the proof, change control) with Verify / Implement
  steps and a checklist — referencing the six shared **Purview category Global Requirements**.
- **03 – Implementation Guide** — the ordered **Assess → Design → Configure → Pilot (readiness proof
  in test) → Validate → Expand** build: inventory current state, score R/H/S/P into a **scorecard +
  gap register**, remediate **dry-run first**, prove the capability **non-destructively on a test
  account** (case → hold → search → confirm preservation → remove hold), validate, then operate — with
  pass/fail gates and rollback.
- **05 – Testing & Validation** — nine procedures with expected pass/fail (roles least-privilege +
  coverage, audit on, hold **proven** to preserve, proof hold **removed**, scope complete, search
  returns seeded content, process artifacts adopted, audit trail present, tier recorded honestly) and
  a gate summary.
- **06 – Troubleshooting** — common readiness failure modes and resolutions (audit off, no role-group
  members / Global-Admin dependency, hold not preserving on the proof, inactive-mailbox coverage gaps,
  missing Teams/M365-Group scope, Premium features absent, proof cleanup).
- **07 – Best Practices** — durable practices for a ready, least-privilege, defensible capability that
  is re-assessed and rehearsed rather than assumed.
- **Executive Summary** — the outcome (an evidenced answer to "are we ready?"), the approach, and why
  it is low-risk.

## PowerShell scripts (5) — safe-by-default (read-only or `-WhatIf`; modern auth; no secrets)
1. **`EDREADY-Discovery.ps1`** — **read-only current-state inventory.** Reports eDiscovery role-group
   membership (Manager/Administrator, and whether Global Admin appears), existing cases / Content
   Searches / case-hold policies, unified-audit-log status, and case-type/tier signals — the raw
   evidence for the **Roles** and **Holds** domains.
2. **`EDREADY-Remediation.ps1`** — **gap remediation, dry-run (`-WhatIf`) by default.** Previews (and
   with **`-Commit`** applies) enabling the unified audit log, adding named operators to the eDiscovery
   role groups, and standing up the **readiness-proof** case + hold on the test account
   (`New-ComplianceCase` / `New-CaseHoldPolicy` / `New-CaseHoldRule`). Never removes holds or members
   silently; prints every action.
3. **`EDREADY-Validation.ps1`** — **read-only rubric validation.** Runs the R/H/S/P gate checks — roles
   least-privilege + coverage, audit on, proof hold enabled then removed, scope accounted for — and
   emits pass/fail for each, matching Section 5.
4. **`EDREADY-Reporting.ps1`** — **read-only scorecard / gap register / evidence pack.** Renders the
   readiness scorecard and gap register and summarizes the proof search statistics, hold status, and
   eDiscovery audit activity — the deliverable evidence pack.
5. **`EDREADY-Scope.ps1`** — **read-only scope/health helper.** Reports mailbox coverage and
   litigation-hold state, **inactive/legacy mailboxes**, existing retention holds, and the workload
   checklist (Exchange incl. Teams chat, SharePoint, OneDrive, Teams/M365 Group sites) — the
   **Scope/coverage** domain evidence.

All scripts print clear, named output referencing the same artifact names (`eDiscovery Readiness –
Proof – Pilot`, `Readiness Hold Policy – Proof – Pilot`, `Readiness Search – Proof – Pilot`) used in
the Implementation and Testing guides, so the docs and automation stay in lockstep. **Regulatory,
records, and legal determinations are deferred to the relevant governance functions** — the scripts
provide method and evidence, not the determination.
