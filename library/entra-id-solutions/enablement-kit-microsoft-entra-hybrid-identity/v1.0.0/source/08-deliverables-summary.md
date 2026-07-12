# 8. Deliverables Summary — Enablement Kit: Microsoft Entra Hybrid Identity

## Documentation (source guides)
1. **executive-summary.md** — what the kit is, how it differs from the HYBID implementation product,
   the training outcome, and the effort.
2. **01-solution-overview.md** — concepts: hybrid identity, Connect Sync vs Cloud Sync, sync scope,
   source anchor, UPN hygiene, PHS/PTA/federation, hybrid join and hybrid CA, scope, out-of-scope, and
   the deployment model.
3. **02-requirements.md** — enablement-specific prerequisites (read-only vantage point, hybrid
   environment to inspect, Graph SDK, RSAT AD module, licensing awareness, optional Log Analytics) with
   verify / implement-if-missing. Category-level prerequisites are in
   `global-requirements-entra-id-solutions.md`.
4. **03-implementation.md** — the guided, read-only / inspection-first labs (0–7): engine choice; sync
   scope / source anchor / UPN hygiene; authentication-method trade-offs and the staged-rollout move;
   hybrid join; hybrid Conditional Access (report-only); the health-check lab; and scoring.
5. **05-testing.md** — lab-validation procedures, the knowledge-check, and the take-home runbook.
6. **06-troubleshooting.md** — symptom → cause → fix for the common lab failures.
7. **07-best-practices.md** — clean-lab guidance, hybrid-identity principles, and where to go next.
8. **08-deliverables-summary.md** — this file.

Plus the category file **global-requirements-entra-id-solutions.md** (shared prerequisites).

## Scripts / lab helpers (5)
1. **EKHYBID-Discovery.ps1** — read-only baseline of the hybrid estate (directory-sync state, last sync
   time, sync engine hint, federated vs managed domains, UPN-hygiene flags).
2. **EKHYBID-Validate.ps1** — read-only check that the lab prerequisites are met (Graph module, read
   role, AD module presence, detected licensing).
3. **EKHYBID-Report.ps1** — hybrid-health scorecard exported to CSV + HTML (engine, sync health, auth
   method, federated domains, UPN hygiene, hybrid-join coverage).
4. **EKHYBID-HealthCheck.ps1** — read-only hybrid health-check (sync enabled, last sync within window,
   federated-domain count, PTA/Seamless SSO hints, UPN issues) — the routine from the health-check lab.
5. **EKHYBID-Signals.kql** — KQL query pack for Log Analytics / Microsoft Sentinel (sign-ins by
   authentication method, hybrid-join device sign-ins, sync-related sign-in errors).

All scripts are white-label and **read-only**.

## How it is delivered
Delivered as a **Complete Solution Package (PDF + Word + scripts)** — the guides as a Word document and
PDF, plus all five lab helpers, in a single ZIP the team keeps and reuses.
