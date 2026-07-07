# Deliverables Summary

Everything included in this solution, on one page.

## Documentation

- **Solution Overview** — external access (federation) vs guest access vs shared channels (B2B direct
  connect), allow/block domains, guest lifecycle, sensitivity, and the deployment model.
- **Requirements Guide** — solution-specific prerequisites (Entra External ID/B2B, cross-tenant access
  settings, guest-lifecycle and sensitivity licensing, admin roles, and a governance-approved policy),
  building on the shared Teams category requirements.
- **Implementation Guide** — exact ordered steps: assess posture, design the policy, configure external
  access / guest / shared channels / cross-tenant settings / access reviews / sensitivity, pilot-first,
  with pass/fail gates and a documented rollback. Every artifact is named.
- **Testing & Validation** — eight tests, each with expected pass/fail, mapped to the validation gates.
- **Troubleshooting** — common failure modes across federation, guests, shared channels, cross-tenant
  settings, reviews, and sensitivity, with resolutions.
- **Best Practices** — durable practices for safe, governed external collaboration.
- **Executive Summary** — outcome, approach, and why the change is low-risk.

## PowerShell scripts (5)

All are **safe-by-default** (read-only or `-WhatIf`), use modern-auth `Connect-*` cmdlets, and contain
**no hardcoded credentials**.

1. **`Get-TeamsExternalGuestPosture.ps1`** — *Discovery / assessment (read-only).* Captures the full
   external-collaboration posture in one pass: federation configuration (allowed/blocked domains,
   open-federation state), external access policies, Teams guest configuration, channels policy
   (shared-channel switches), cross-tenant access **Default** + partner settings, guest count, and a
   **stale-guest assessment**. Writes a JSON baseline.

2. **`Set-TeamsExternalGuestConfig.ps1`** — *Configuration / remediation (`-WhatIf` by default).*
   Applies the designed external access / guest / shared-channel settings and creates the named
   policies (`External Access Policy – Pilot`, `Teams Channels Policy – SharedCh-Pilot`). Dry-runs
   unless `-Commit` is passed; supports reapplying a captured baseline for rollback.

3. **`New-GuestAccessReview.ps1`** — *Guest access-review + expiration helper (`-WhatIf` by default).*
   Creates a recurring Entra access review of guests (`Guest Access Review – Recert – Pilot`) with
   auto-remove on non-approval — the expiration mechanism. Reports existing reviews. Requires Entra ID
   Governance/P2 (verified at runtime).

4. **`Get-TeamsExternalExposureReport.ps1`** — *External-exposure report (read-only).* Enumerates
   guests and external-facing settings, flags guests inactive ≥ a threshold and those from
   non-approved domains, and exports a governance-ready CSV.

5. **`Test-TeamsExternalGuestBaseline.ps1`** — *Validation / scope-health helper (read-only).* Compares
   the live posture against a target baseline (federation model, guest config, channels policy,
   cross-tenant direct-connect defaults) and reports **PASS/FAIL** per setting — the automated form of
   the validation gates.
