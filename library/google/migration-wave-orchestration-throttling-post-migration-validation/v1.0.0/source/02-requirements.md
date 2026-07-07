# 2. Requirements

These are the **solution-specific** prerequisites for running migration cutover operations. They build
**on top of** the shared category prerequisites in `global-requirements-google.md` (Workspace/Cloud
Identity tenant with super-admin; source Microsoft 365 / Entra access; DNS control for routed domains;
identity source of truth and provisioning; a pilot OU/group with change control; security/compliance
stakeholders). Do not re-satisfy those here — verify them first, then confirm the additions below.

> This solution assumes the **program-level plan already exists** (the migration program solution
> owns discovery baseline, tooling strategy, and coexistence design). It also assumes a **migration
> engine has been chosen and stood up** (its own solution/docs own the engine). What this solution
> adds is the operational scaffolding to *run* the waves: the user set to batch, the limits to budget
> against, the validation criteria, and the hypercare team.

---

## 2.1 A chosen, connected migration engine
- **Description:** One migration engine is selected and its source/target connections are established:
  **Google Workspace Migrate**, **GWMME**, **BitTitan MigrationWiz**, **CloudM Migrate**, or another.
  The engine can authenticate to the **Microsoft 365 source** (Exchange Online / OneDrive / SharePoint)
  and the **Google Workspace target** at the scope it will migrate.
- **Why required:** This solution orchestrates *around* an engine; it does not move data. Wave
  scheduling, throttle budgeting, and validation all assume the engine exists and can run.
- **How to verify:** Confirm the engine is installed/subscribed, its source and target endpoints
  authenticate successfully, and a single test user can be migrated end to end. (Engine console
  details are in that vendor's own documentation — **verify for your version**.)
- **How to implement if missing:** Stand up the engine per its vendor solution/documentation and
  validate one test user before batching waves.

## 2.2 A discovery user set (the population to batch)
- **Description:** A machine-readable export of the users in scope, with the attributes needed to
  batch waves: user principal name / primary SMTP, display name, department/OU, manager, **mailbox
  delegates**, **shared-mailbox membership**, distribution-list/group membership, and (where known)
  mailbox and Drive/OneDrive data volume.
- **Why required:** Waves must keep **dependency clusters** together (a manager and their delegates, a
  shared mailbox and its members) and be sized by data volume; without these attributes the batcher
  can only split alphabetically, which breaks delegate and shared-mailbox access at cutover.
- **How to verify:** Open the export (CSV/JSON) and confirm each user row carries UPN, department,
  manager, and delegate/shared-mailbox references. The assessment tool (`discovery-profile.py`)
  reports which attributes are missing.
- **How to implement if missing:** Produce the export from Microsoft Entra ID / Exchange Online (the
  program solution's discovery step) — or use the assessment tool to read the Google directory for
  the target-side view — before batching.

## 2.3 Documented throttling / API-limit model for both vendors
- **Description:** The **current** throttling/quota posture on both sides: the **Microsoft Graph**
  throttling model for the read APIs the engine uses (per-app and per-tenant limits, 429 + `Retry-After`
  behavior), and the **Google Workspace** API quotas relevant to the target and to your automation
  (Admin SDK Directory, Reports, Drive, Gmail), plus the engine's own documented throughput/concurrency
  guidance.
- **Why required:** The throttle budget (concurrency + pacing per wave) is computed from these. Guessing
  causes either wasted windows (too conservative) or 429/`RESOURCE_EXHAUSTED` storms that stall a
  cutover (too aggressive).
- **How to verify:** In **Google Cloud console → APIs & Services → Quotas** confirm the quotas for the
  APIs your automation and engine use; review Microsoft Graph throttling guidance for the resources
  the engine reads; review the engine's concurrency guidance. **These change over time and vary by
  tenant/licensing — confirm current numbers.**
- **How to implement if missing:** Gather the current limits (the throttle planner reads Google quota
  where the API exposes it and applies documented Microsoft Graph guidance); request quota increases
  from the respective vendor where a wave needs more than the default.

## 2.4 Service identity for the automation (read-only / least privilege)
- **Description:** A credential for the Python tools to read both directories and (optionally) validate
  the target: a **Google Cloud service account with domain-wide delegation** (or an OAuth client) scoped
  to the **read-only** Admin SDK Directory / Reports / Drive / Gmail scopes needed for validation, and —
  where the Microsoft side must be read — a **Microsoft Entra app registration** with least-privilege
  Graph read scopes.
- **Why required:** The tools discover users, budget throttling, check readiness, and validate results;
  they need directory/report read access. Least privilege keeps the automation safe.
- **How to verify:** Confirm the Google service account is authorized in **Admin console → Security →
  API controls → Domain-wide delegation** with only the read scopes listed in each tool's `--help`; if
  reading Microsoft, confirm the Entra app has only the read Graph scopes.
- **How to implement if missing:** Create the service account / app registration, grant the minimal
  **read-only** scopes, and provide credentials to the tools via **OAuth / Application Default
  Credentials (ADC)** — **never** hardcode keys or commit exported key files.

## 2.5 Defined validation criteria (the pass/fail definition of "done")
- **Description:** An agreed, written definition of what "successfully migrated" means for a user and a
  wave: acceptable item-count variance (some engines legitimately deduplicate or skip system items),
  which permission/sharing states must match, mail-flow tests to pass, delegate access to confirm, and
  calendar/free-busy checks.
- **Why required:** Validation is only meaningful against a criterion. Without it, "counts differ by 3"
  is either a pass or a failure depending on nobody's opinion.
- **How to verify:** Confirm a validation-criteria document exists and names the tolerances; the
  validation tool takes these as parameters/config.
- **How to implement if missing:** Agree the criteria with the migration lead and the business owners
  before the pilot wave; record them so every wave is judged the same way.

## 2.6 A hypercare team, SLA, and issue intake
- **Description:** A named **hypercare team** for the post-cutover window, an agreed **SLA** per issue
  severity, and an intake channel (ticket queue / form) that feeds the triage tracker.
- **Why required:** Cutovers generate a tail of user issues (a missing delegate, a broken mail rule, a
  not-yet-shared Drive). Managing that tail against an SLA is what keeps a wave from being declared
  "done" while users are still blocked.
- **How to verify:** Confirm the team roster, the severity/SLA matrix, and the intake channel exist.
- **How to implement if missing:** Stand up the hypercare rota and SLA and connect the intake channel
  before the pilot wave cuts over.

## 2.7 A change window and rollback authority for cutover
- **Description:** An approved **change window** for each cutover (final delta + mail-routing/DNS
  switch) and a named approver who can authorize the **rollback** if a gate fails.
- **Why required:** Cutover changes mail flow and DNS — high-impact, production-affecting changes that
  must be made under change control with a way back.
- **How to verify:** Confirm the change window is booked and the rollback approver is named for each
  wave (especially the pilot).
- **How to implement if missing:** Book the window and confirm the rollback approver as part of the
  per-wave go/no-go, per the shared change-control requirement.
