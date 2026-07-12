# 8. Deliverables Summary — Enablement Kit: Multi-Factor Authentication & Conditional Access

Everything included in this kit, and what each piece is for.

## Documentation

| Document | Purpose |
| --- | --- |
| **Executive Summary** (`executive-summary.md`) | One-page framing: the "too timid or too reckless with MFA/CA" problem, the enablement solution (concepts + report-only labs + take-home runbook + knowledge-check), and the boundary (skills product; **distinct from** the ENTZTCA / Conditional Access Integration *implementation* solutions; practices report-only, never enforces). |
| **1. Solution Overview** (`01-solution-overview.md`) | What it is, how MFA methods and the Conditional Access model work (signals, conditions, grant/session controls, personas, report-only + What-If, break-glass), the Assess→Configure→Pilot→Validate→Expand model, scope, out-of-scope, and connections used. |
| **2. Requirements Guide** (`02-requirements.md`) | Solution-specific prerequisites (CA licensing P1/P2, cohort + least-privilege roles, lab persona groups, break-glass + exclusion group, methods/sign-in-log access, toolchain) — layered on the shared `global-requirements-entra-id-solutions.md` (G1–G8). |
| **Global Requirements** (`global-requirements-entra-id-solutions.md`) | Category-wide prerequisites, published once (tenant, licensing, admin roles, break-glass, network access). |
| **3. Implementation Guide** (`03-implementation.md`) | The guided labs: assess readiness, create the cohort/persona/exclusion groups, run Labs 1–6 (MFA methods & registration → CA anatomy → design patterns & personas → build **report-only** policies → What-If testing → sign-in/CA-evaluation troubleshooting), then capstone + knowledge-check, then move to the enforced-baseline solutions — every object named, every policy report-only, with rollback. |
| **5. Testing & Validation** (`05-testing.md`) | Eight pass/fail gates covering safe lab setup and skills landed (lab policies report-only, break-glass excluded everywhere, What-If matches design, read a sign-in and explain CA, knowledge-check passes), referencing the scripts by name. |
| **6. Troubleshooting** (`06-troubleshooting.md`) | The common failure modes (MFA registration gaps, policy not report-only, break-glass not excluded, What-If surprises, report-only vs real failures, legacy-auth confusion, connection/permission errors) as symptom → cause → fix. |
| **7. Best Practices** (`07-best-practices.md`) | Report-only-before-enforce, protect-break-glass, choose-methods-by-strength, design-by-persona, troubleshoot-from-the-log, verify-don't-assume, run-it-as-a-program — plus where to go next in the catalog. |

## Lab helpers (5)

All helpers authenticate **interactively** (no credentials in code) and use the **Microsoft Graph
PowerShell SDK**; the KQL pack runs over Entra sign-in logs. The discovery, validation, and report
helpers are **read-only**; the lab-policy builder is **preview (`-WhatIf`) by default**, gated, and
creates **report-only policies only** — it can never enforce. Government-cloud tenants pass the
matching environment — *verify endpoints for your cloud*.

| File | Type | What it does |
| --- | --- | --- |
| **`EKMFACA-Discovery.ps1`** | Read-only | Inventories the MFA/CA picture: enabled MFA methods and registration coverage, existing Conditional Access policies and states, which policies exclude break-glass (flags "all users, no exclusions" lock-out risk), detected legacy-auth sign-ins, and the licensing tier (P1/P2). Changes nothing. |
| **`EKMFACA-LabPolicy.ps1`** | Gated write (preview by default) | Creates the persona/exclusion groups if absent, then the report-only lab policies `CALab001` (Require MFA - Internals), `CALab002` (Phishing-Resistant MFA - Admins), `CALab003` (Block Legacy - All Users) — every one **report-only** with break-glass excluded. Defaults to `-WhatIf`; `-Remove` tears the lab down. Creates report-only ONLY; never enforces. |
| **`EKMFACA-Labs.kql`** | KQL lab pack | The runnable sign-in-log query pack for the CA-evaluation and troubleshooting labs — CA policy "would-apply" results (incl. report-only), top sign-in failure reasons, which MFA method satisfied the requirement, and legacy-auth observation. Read-only; the take-home query starter. |
| **`EKMFACA-Validate.ps1`** | Read-only | Runs the `05-testing.md` gates as PASS/FAIL/MANUAL lines: lab policies present and **report-only**, break-glass excluded from every one, personas scoped correctly — and prints the knowledge-check `Check-MfaCa-Pilot` answer key for scoring. |
| **`EKMFACA-Report.ps1`** | Read-only | Reports what the report-only policies *would* have done (would-grant / would-require / would-block per policy, per persona) and cohort progress + MFA-registration coverage; exports to CSV. |

## Named objects (verbatim — used across docs, scripts, and tests)

- **Learner cohort group:** `Grp-MfaCa-Cohort`
- **Break-glass exclusion group:** `Grp-MfaCa-Excl-BreakGlass`
- **Lab persona groups:** `Grp-MfaCa-Persona-Admins-Pilot`, `Grp-MfaCa-Persona-Internals-Pilot`,
  `Grp-MfaCa-Persona-Guests-Pilot`
- **Report-only lab policies:** `CALab001 Require MFA - Internals - ReportOnly`,
  `CALab002 Require Phishing-Resistant MFA - Admins - ReportOnly`,
  `CALab003 Block Legacy Authentication - AllUsers - ReportOnly`
- **Knowledge-check:** `Check-MfaCa-Pilot`

## What this kit deliberately does NOT do

- It does **not** design or roll out a production, enforced Conditional Access baseline — that is
  **ENTZTCA** and **Conditional Access Integration**. Every policy here is **report-only** and cannot
  enforce.
- It does **not** deploy phishing-resistant methods at scale — that is **Passwordless & Passkey
  (ENTPASSKEY)**. It teaches the methods and cross-references.
- It does **not** build risk-based (P2), PIM, governance, or hybrid — those are **Identity
  Protection**, **ENTPIM**, **ENTIGA**, and **Hybrid Identity**. It cross-references, not duplicates.
- It does **not** decide business/security policy — which MFA methods are mandated, which users are
  "privileged," and every production enforcement decision are the customer's determinations; the kit
  provides the skill and the labs.
- It does **not** invent licensing or preview facts — where availability may differ by tenant/cloud
  (P1/P2, passkeys, CBA, preview features) it says **verify in your tenant**.

## How it is delivered

This kit is delivered as a **Complete Solution Package (PDF + Word + scripts)** — the documentation as
a formatted Word document and PDF, plus the KQL lab pack and all five lab helpers, in a single ZIP
(`EKMFACA-Complete-Solution.zip`) — yours to keep and re-run for every new cohort.

## Outcome

A team that can **design, test, and troubleshoot** MFA and Conditional Access on Microsoft Entra
safely — the right methods, persona-based policies, every policy proven in report-only and What-If
before it can enforce, break-glass protected, and sign-in logs read with confidence — ready to move
into the production enforced-baseline solutions.

Delivered as a Complete Solution Package (PDF + Word + scripts).
