# Deliverables Summary

Everything included in this solution and how the pieces fit together.

## Documentation

| Deliverable | Purpose |
|-------------|---------|
| **Solution Overview** | What the archiving strategy delivers, how mailbox archive / retention / tiering work in Purview and Exchange Online, and the Assess → Design → Configure → Pilot → Validate → Expand model. |
| **Requirements Guide** | Solution-specific prerequisites (archiving licensing, least-privilege roles, MRM/MFA toolchain, in-scope mailboxes and tiering intent, records/legal sign-off, pilot scope) referencing the category Global Requirements. |
| **Implementation Guide** | Exact ordered steps to enable archive mailboxes, create the `MTA-2yr` move-to-archive tag and `RP-Corp-Archive` policy, assign to the pilot, run the Managed Folder Assistant, optionally stage the `DLM-Exchange-Keep` retention policy, validate, and expand — each step with pass/fail gates and rollback. |
| **Testing & Validation** | Six pass/fail gates proving the archiving strategy took effect, with the evidence to capture. |
| **Troubleshooting** | Common failure signatures (archive not provisioning, items not moving, MFA lag, policy not distributing) and resolutions. |
| **Best Practices** | Keeping the strategy healthy, cost-effective, and defensible; move-vs-delete separation; change discipline. |
| **Executive Summary** | One-page business framing for decision-makers. |

## PowerShell scripts (5)

All scripts use interactive modern-auth (`Connect-ExchangeOnline` / `Connect-IPPSSession` /
`Connect-MgGraph`), contain **no credentials or secrets**, and are **read-only or `-WhatIf` by
default** — writes require an explicit `-Commit` switch.

| Script | Role | Default safety |
|--------|------|----------------|
| `Get-ArchiveScopeHealth.ps1` | Scope/health helper — connectivity, module, role and pilot-group preflight | Read-only |
| `Invoke-ArchiveDiscovery.ps1` | Discovery — archive status, mailbox sizes, MRM tags/policies, DLM retention policies, org auto-expanding setting | Read-only |
| `Set-ArchiveStrategy.ps1` | Configuration/Remediation — enable archives, create/assign MRM tag & policy, run MFA | `-WhatIf` unless `-Commit` |
| `Test-ArchiveStrategy.ps1` | Validation — runs the pass/fail gates and reports PASS/FAIL | Read-only |
| `Export-ArchiveReport.ps1` | Reporting — adoption, archive growth, and primary-store reduction to CSV/HTML | Read-only |

## How to use them together

1. `Get-ArchiveScopeHealth.ps1` — confirm you can proceed (licensing, roles, modules, pilot group).
2. `Invoke-ArchiveDiscovery.ps1` — capture the **baseline**.
3. `Set-ArchiveStrategy.ps1 -WhatIf` → review → `-Commit` — configure the **pilot** scope.
4. `Test-ArchiveStrategy.ps1` — confirm the pilot passes every gate.
5. `Export-ArchiveReport.ps1` — evidence of adoption and reduction; repeat per expansion ring.

## Boundaries

- The **retention timeline and any disposition (delete)** are **records / compliance / legal
  determinations** — deferred to those functions; this solution provides the technical method and
  evidence only.
- Purview/Exchange **licensing, auto-expanding archive, and Microsoft 365 Archive tiering** are
  plan-/billing-gated and evolving — **verify your licensing/tenant**.
- Automation is **PowerShell** (Exchange Online + Security & Compliance PowerShell / Graph); no
  hardcoded credentials.
