# 8. Deliverables Summary — Enablement Kit: Microsoft Entra Identity Fundamentals

Everything included in this kit, and what each piece is for.

## Documentation

| Document | Purpose |
| --- | --- |
| **Executive Summary** (`executive-summary.md`) | One-page framing: the "inherited a tenant, nobody knows how it works" problem, the enablement solution (concepts + guided labs + take-home runbook/glossary + knowledge-check), and the boundary (skills product; adjacent to the implementation solutions; practices on a cloud-only sandbox, report-only for CA). |
| **1. Solution Overview** (`01-solution-overview.md`) | What it is, how Entra works (tenant, identities, groups, roles/RBAC, app registrations vs enterprise apps, sign-in/MFA/CA, licensing), the Assess→Configure→Pilot→Validate→Expand model, scope, out-of-scope, and connections used. |
| **2. Requirements Guide** (`02-requirements.md`) | Solution-specific prerequisites (portal access, cohort + least-privilege roles, cloud-only sandbox posture, break-glass, licensing awareness, toolchain) — layered on the shared `global-requirements-entra-id-solutions.md` (G1–G8). |
| **Global Requirements** (`global-requirements-entra-id-solutions.md`) | Category-wide prerequisites, published once (tenant, licensing, admin roles, break-glass, network access). |
| **3. Implementation Guide** (`03-implementation.md`) | The guided labs: assess readiness, create the cohort and lab sandbox, run Labs 1–6 (tenant tour → users → groups → roles/RBAC → app registrations → sign-in/MFA/report-only CA), then capstone + knowledge-check, then operate with confidence — every object named, with rollback. |
| **5. Testing & Validation** (`05-testing.md`) | Eight pass/fail gates covering both sandbox setup and skills landed (read a user/group/role/app unaided, sign-in labs, CA lab report-only, break-glass excluded, knowledge-check passes), referencing the scripts by name. |
| **6. Troubleshooting** (`06-troubleshooting.md`) | The common failure modes (portal/permission errors, sandbox object issues, dynamic-membership lag, CA lab not report-only, sign-in-log gaps, licensing surprises) as symptom → cause → fix. |
| **7. Best Practices** (`07-best-practices.md`) | Learn-on-a-sandbox, treat-identity-as-high-risk, build-the-right-mental-model, verify-don't-assume, run-it-as-a-program — plus where to go next in the catalog. |

## Lab helpers (5)

All helpers authenticate **interactively** (no credentials in code) and use the **Microsoft Graph
PowerShell SDK**; the KQL pack runs over Entra sign-in/audit logs. The discovery, validation, and
report helpers are **read-only**; the sandbox setup is **preview (`-WhatIf`) by default** and gated.
Government-cloud tenants pass the matching environment — *verify endpoints for your cloud*.

| File | Type | What it does |
| --- | --- | --- |
| **`EKIDFUND-Discovery.ps1`** | Read-only | Inventories the tenant fundamentals: user/guest counts, group counts (security vs M365, assigned vs dynamic), directory-role assignments (flags Global-Admin over-assignment), app registration / enterprise-app counts, licensing tier (P1/P2), MFA-registration coverage, and existing CA policies. Changes nothing. |
| **`EKIDFUND-LabSetup.ps1`** | Gated write (preview by default) | Creates the cloud-only lab sandbox — `Grp-EntraFund-LabTeam-Pilot`, `Grp-EntraFund-DynamicDept-Pilot`, `Lab-EntraFund-User1`, `App-EntraFund-LabApp-Pilot`. Defaults to `-WhatIf` (preview); `-Remove` tears the sandbox down. Never touches production objects. |
| **`EKIDFUND-Labs.kql`** | KQL lab pack | The runnable sign-in/audit query pack for the sign-in and MFA labs — sign-ins by method and result, MFA-registration coverage, Conditional Access "would-apply" results, and audit trail of the sandbox changes. Read-only; the take-home query starter. |
| **`EKIDFUND-Validate.ps1`** | Read-only | Runs the `05-testing.md` gates as PASS/FAIL/MANUAL lines: sandbox objects present and cloud-only, the CA lab policy is report-only with break-glass excluded, licensing as expected — and prints the knowledge-check `Check-EntraFund-Pilot` answer key for scoring. |
| **`EKIDFUND-Report.ps1`** | Read-only | Reports the fundamentals picture and cohort progress (objects created, CA lab state, knowledge-check results) and exports to CSV. |

## Named objects (verbatim — used across docs, scripts, and tests)

- **Learner cohort group:** `Grp-EntraFund-Cohort`
- **Lab practice team group:** `Grp-EntraFund-LabTeam-Pilot`
- **Lab dynamic group:** `Grp-EntraFund-DynamicDept-Pilot`
- **Lab cloud-only test user:** `Lab-EntraFund-User1`
- **Lab app registration:** `App-EntraFund-LabApp-Pilot`
- **Lab Conditional Access policy:** `CAFund-RequireMFA-LabTeam-ReportOnly` (report-only)
- **Knowledge-check:** `Check-EntraFund-Pilot`

## What this kit deliberately does NOT do

- It does **not** design or roll out a production Conditional Access baseline — that is **ENTZTCA** and
  **Conditional Access Integration**. This kit builds one **report-only** teaching policy.
- It does **not** deploy PIM, passwordless, governance, or hybrid sync — those are **ENTPIM**,
  **ENTPASSKEY**, **ENTIGA**, and **Hybrid Identity**. It introduces the concepts and cross-references.
- It does **not** change production identity — labs run on a **cloud-only sandbox** and any CA object
  is **report-only**.
- It does **not** decide business/security policy — which roles are "privileged," which MFA methods
  are mandated, which apps are sanctioned are the customer's determinations; the kit provides the
  skill and the labs.
- It does **not** invent licensing or preview facts — where availability may differ by tenant/cloud
  (P1/P2, Governance, Global Secure Access, Verified ID, preview features) it says **verify in your
  tenant**.

## How it is delivered

This kit is delivered as a **Complete Solution Package (PDF + Word + scripts)** — the documentation as
a formatted Word document and PDF, plus the KQL lab pack and all five lab helpers, in a single ZIP
(`EKIDFUND-Complete-Solution.zip`) — yours to keep and re-run for every new admin.

## Outcome

A team grounded in Microsoft Entra fundamentals — able to read the directory, manage users and groups,
apply least-privilege roles, recognize app registrations, and trace a sign-in through MFA and
Conditional Access — ready to operate the tenant safely and to progress to the advanced identity
solutions.

Delivered as a Complete Solution Package (PDF + Word + scripts).
