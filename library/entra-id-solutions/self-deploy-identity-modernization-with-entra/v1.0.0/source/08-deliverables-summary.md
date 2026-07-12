# 8. Deliverables Summary — Self-Deploy: Identity Modernization with Entra

## Documentation (source guides)
1. **executive-summary.md** — what the kit is, the training outcome, the boundary, and the effort.
2. **01-solution-overview.md** — concepts: the legacy→modern journey, the Entra target-state
   architecture (the building blocks), scope, out-of-scope, and the deployment model.
3. **02-requirements.md** — enablement-specific prerequisites (lab pilot group, sample identities,
   Graph SDK, licensing awareness, optional Log Analytics) with verify / implement-if-missing. The
   category-level prerequisites are in `global-requirements-entra-id-solutions.md`.
4. **03-implementation.md** — the guided hands-on labs (0–7): CA report-only, Identity Protection,
   passwordless, governance, Global Secure Access, migration & coexistence, and scoring — every object
   named and reused.
5. **05-testing.md** — lab-validation procedures, the knowledge-check, and the take-home runbook.
6. **06-troubleshooting.md** — symptom → cause → fix for the common lab failures.
7. **07-best-practices.md** — clean-lab guidance, modernization principles, and where to go next.
8. **08-deliverables-summary.md** — this file.

Plus the category file **global-requirements-entra-id-solutions.md** (shared prerequisites).

## Scripts / lab helpers (5)
1. **EKIDMOD-Discovery.ps1** — read-only baseline of the modernization posture (legacy auth usage,
   per-user MFA vs Conditional Access, registered authentication methods, federated domains).
2. **EKIDMOD-Validate.ps1** — read-only check that the lab prerequisites are met (pilot group, sample
   users, Graph module, detected licensing).
3. **EKIDMOD-Report.ps1** — modernization scorecard exported to CSV + HTML across the building blocks.
4. **EKIDMOD-LabSetup.ps1** — safe lab-setup helper that creates/removes the pilot group and sample
   users; **preview / -WhatIf by default**, `-Commit` to apply, `-Remove` to tear down.
5. **EKIDMOD-Signals.kql** — KQL query pack for Log Analytics / Microsoft Sentinel (legacy-auth
   sign-ins, risky sign-ins, Conditional Access gaps, passwordless adoption).

All scripts are white-label and read-only except the clearly gated, preview-first `EKIDMOD-LabSetup.ps1`.

## How it is delivered
Delivered as a **Complete Solution Package (PDF + Word + scripts)** — the guides as a Word document
and PDF, plus all five lab helpers, in a single ZIP the team keeps and reuses.
