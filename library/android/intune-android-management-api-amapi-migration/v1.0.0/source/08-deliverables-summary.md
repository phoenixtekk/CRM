# Deliverables Summary

## Documentation

| Document | What it covers |
|----------|----------------|
| **01 — Solution Overview** | What AMAPI is and how it differs from the legacy Play EMM API, the enrollment models affected (work profile / fully managed / corp work profile / dedicated-COSU), the web/account-driven enrollment path, the end-user / re-enrollment impact model, and the verify-first discipline. |
| **02 — Requirements** | Solution-specific prerequisites (healthy managed Google Play binding, estate inventory, **current AMAPI guidance read**, a **verified per-model impact statement**, web-enrollment readiness decision, enrollment-profile/app/CA review, pilot cohorts, Graph PowerShell) — each with Description / Why / Verify / Implement. References the category Global Requirements. |
| **03 — Implementation** | The ordered **Assess → Design → Configure → Pilot → Validate → Expand** migration procedure: inventory the estate, read current guidance, plan the wave, prepare groups/profiles, **pilot each model and OBSERVE re-enrollment/impact**, validate, then expand wave by wave — with pass/fail gates and a halt-and-hold rollback. |
| **05 — Testing** | Validation V1–V7 with expected pass/fail: binding healthy, **devices manage under AMAPI**, end-user impact matches the documented statement, **apps deliver**, **accounts add**, compliance/CA, and wave repeatability. |
| **06 — Troubleshooting** | Symptom → root-cause pointers for post-migration failures (devices not checking in, "can't add a Google account," apps not delivering, unexpected re-enrollment/reset, binding/app-sync, RBAC/scope) with the escalation path — cross-referencing the Android enrollment-troubleshooting solution. |
| **07 — Best Practices** | Verify-never-assume, estate/wave design, protecting the managed Google Play binding, end-user communication, change control/rollback, least-privilege tooling, and evidence. |
| **Executive Summary** | One-page outcome, approach, and why it is low-risk. |

## PowerShell (Microsoft Graph) tools

All scripts use modern-auth `Connect-MgGraph` (no stored secrets), request the **least** scopes,
and are **read-only or safe-by-default**. None asserts AMAPI timelines or re-enrollment behavior —
those are verified against current Microsoft guidance and observed in the pilot.

| Script | What it does | Safe default |
|--------|--------------|--------------|
| **`AMAPIMIG-Assess-AndroidEstate.ps1`** | Inventories enrolled Android devices by enrollment model, management agent, ownership, OS/OEM, compliance, and last check-in, with a stale-device list. Notes that legacy-vs-AMAPI is **not** a single Graph property — verify in the admin center. | Read-only |
| **`AMAPIMIG-New-MigrationWavePlan.ps1`** | Buckets the estate into Pilot/Wave1/Wave2/Prod cohorts per model (lowest-visibility first) and writes `AMAPIMIG-WavePlan.csv`; optionally creates the Assigned wave groups. | Read-only (group creation gated behind `-CreateGroups -Commit`) |
| **`AMAPIMIG-Test-WebEnrollmentReadiness.ps1`** | Checks prerequisite signals for web/account-driven enrollment (binding, device-owner enrollment profiles, endpoint reminders); explicitly flags that **availability must be verified against current Microsoft guidance**. | Read-only |
| **`AMAPIMIG-Get-PostMigrationValidation.ps1`** | For a wave cohort: devices check in, compliance state, ownership/account signals, and **managed-app install status** for a named app — the evidence that devices manage under AMAPI, accounts add, and apps deliver. | Read-only |
| **`AMAPIMIG-Config.ps1`** | Shared connection helper, naming/enrollment-type constants, and (`-HealthSummary`) the managed Google Play **binding health** report used before migrating. | Read-only |
