# 8. Deliverables Summary

Everything included in this solution, on one page.

## Documentation
- **Solution Overview** — the three Teams-specific controls (information barriers, Teams chat/channel
  retention, Teams DLP), how each works, the named reference design, benefits, and honest limitations,
  plus how they align to the broader Purview program.
- **Requirements Guide** — solution-specific prerequisites (compliance licensing, Purview role groups,
  `Connect-IPPSSession`, the IB segment attribute, scoped directory search, no conflicting ABPs,
  existing Purview posture, and the compliance/records/legal determinations) — each with Verify /
  Implement steps, building on the Teams category global requirements.
- **Implementation Guide** — ordered Assess → Design → Configure → Pilot → Validate → Expand steps for
  each control, every artifact named, with per-control pass/fail gates and rollback.
- **Testing & Validation** — eight tests, each with an expected pass/fail signal.
- **Troubleshooting** — common failure modes (IB not enforcing, application stuck, retention not
  applying, DLP not matching, licensing/role errors) and their resolutions.
- **Best Practices** — durable practices for scope, determinations, IB, retention, DLP, and safe
  operations.
- **Executive Summary** — outcome, approach, and why the rollout is low-risk.

## PowerShell scripts (5) — Security & Compliance PowerShell / MicrosoftTeams / Graph
All are **safe by default** (read-only or `-WhatIf`; config helpers require `-Commit` to write) and use
modern-auth connect cmdlets with **no credentials in code**.

1. **TEAMSCOMP-Assessment.ps1** — *Discovery / posture (read-only).* Inventories the Teams compliance
   posture: existing IB segments and policies with application status, retention policies that touch
   the Teams locations, Teams-location DLP policies with their mode, and whether scoped directory
   search is enabled. The "what exists today" read used to plan.

2. **TEAMSCOMP-Configure-InformationBarriers.ps1** — *IB config helper (`-WhatIf` by default).* Creates
   the named organization segments and the block/allow IB policy from parameters, defaulting to a
   dry-run; writes only when `-Commit` is passed. Optionally starts policy application with an explicit
   switch.

3. **TEAMSCOMP-Configure-RetentionDlp.ps1** — *Retention + DLP config helper (`-WhatIf` by default).*
   Creates the Teams-only retention policy + rule (compliance-defined duration/action) and the Teams
   DLP policy + rule in a **test** mode referencing approved sensitive-information types; dry-run
   unless `-Commit` is passed.

4. **TEAMSCOMP-Validation.ps1** — *Compliance-control validation report (read-only).* Checks the
   expected named artifacts and their states — segments present, IB policy Active and application
   Completed, retention policy Enabled with the correct rule, DLP policy/rule mode — and reports
   PASS/FAIL per control.

5. **TEAMSCOMP-ScopeHelper.ps1** — *Scope / health helper (read-only).* Resolves and previews the IB
   segment membership for sample users, reports `Get-InformationBarrierRecipientStatus`, and checks the
   IB prerequisites (scoped directory search, conflicting address book policies) so scope is verified
   before application.
