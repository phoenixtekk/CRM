# Requirements

These are the **solution-specific** prerequisites for standing up a Google Workspace day-2
administration and operations practice. They build **on top of** the shared Google-category
prerequisites in `global-requirements-google.md` — the provisioned Workspace/Cloud Identity tenant
with super-admin (GR-1), a pilot OU/group and change control (GR-5), and engagement with security,
compliance, and governance stakeholders (GR-6). Verify those first; the items below are what this
operations solution additionally needs. Each is stated as **Description / Why required / How to verify
/ How to implement if missing**.

---

## R1. A completed go-live (steady-state, not mid-migration)

- **Description:** Google Workspace is already in production — users are on Gmail/Drive/Docs/Meet/Chat
  and the cutover is complete. This solution operates a live tenant, it does not migrate one.
- **Why required:** The operating model (OU baseline, drift detection, runbooks) assumes a stable
  target configuration to govern *against*. Running it mid-migration produces false drift and unstable
  baselines.
- **How to verify:** Confirm mail flow (MX) points at Google, users sign in daily, and there is no
  active migration wave in flight.
- **How to implement if missing:** Complete migration cutover first (that is the separate
  migration-cutover-operations solution). Return here once BAU begins.

## R2. Super-admin plus a defined admin-team structure

- **Description:** At least one **super-admin** account (used only for break-glass and for building
  the delegation model), **plus** the list of teams/individuals who will operate the tenant day-to-day
  and what each must be able to do (help desk, identity/groups, service configuration, security).
- **Why required:** The least-privilege delegation model (`Admin Role – <team> – <scope>`) is built
  from this. Without a defined team-to-capability mapping, roles cannot be scoped.
- **How to verify:** In **admin.google.com → Account → Admin roles**, confirm current super-admins
  (there should be a small, known number) and current role assignments. Confirm the operations org
  chart / responsibilities off-console.
- **How to implement if missing:** Reduce super-admins to the minimum, establish break-glass
  accounts, and document the operations team responsibilities before designing roles.

## R3. Reports API / audit-log access and retention posture

- **Description:** Access to the **Admin SDK Reports API** (activity and usage reports) and a decision
  on **audit-log retention** appropriate to your edition and compliance obligations. Google Workspace
  retains audit-log data for defined windows by service; longer retention typically requires export
  (e.g. to BigQuery) — verify the current retention windows and export options for your edition.
- **Why required:** Monitoring, health checks, and evidence (R6) read from the Reports API; incident
  investigation depends on logs still being retained when you look.
- **How to verify:** In the Admin console, confirm the **Reporting / Audit and investigation** tools
  are available for your edition; confirm the Reports API is enabled in the associated Google Cloud
  project (see R4).
- **How to implement if missing:** Enable the Reports API in the service-account/OAuth project;
  if long-term retention is required, stand up a log export (e.g. BigQuery export) — verify the
  current export mechanism and windows for your edition.

## R4. A control-plane identity for the Python tooling (OAuth or domain-wide delegated service account)

- **Description:** An authentication method for the five Python tools: either an **OAuth user
  credential** for an admin, or a **service account with domain-wide delegation** authorized for the
  read-only Admin SDK scopes the tools use (Directory read-only, Reports read-only, Groups settings
  read-only). No keys are ever stored in the tools.
- **Why required:** The tools call the Admin SDK Directory and Reports APIs to assess, validate, and
  detect drift. They must authenticate with least-privilege, credential-free code.
- **How to verify:** Confirm a Google Cloud project exists with the **Admin SDK API** enabled and
  either an OAuth client or a domain-wide-delegated service account authorized for the read-only
  scopes (in **Admin console → Security → API controls → Domain-wide delegation** the client ID is
  listed with only the read-only scopes).
- **How to implement if missing:** Create the Cloud project, enable the Admin SDK API, create the
  service account (or OAuth client), and authorize **only the read-only scopes** the tools name in
  their `--help`. Supply the credential to the tools via ADC / an environment path — never hardcoded.

## R5. A documented target-state design (or the intent to produce one)

- **Description:** The **target OU tree**, the **per-OU settings baseline**, the **admin-role
  delegation matrix**, the **monitored events/alerts list**, and the **runbook library table of
  contents** — either already documented, or acknowledged as the first deliverable of the Design
  stage. The drift detector compares live configuration against a **baseline file** you own.
- **Why required:** "Drift" and "correct policy" are only meaningful relative to an intended design.
  The config-drift tool needs a baseline artifact to compare against.
- **How to verify:** Confirm a baseline document/JSON exists (or is scheduled) that names each OU and
  its intended key settings.
- **How to implement if missing:** Produce it in the Design stage (Implementation §Design) — the
  assessment tool exports the *current* state as a starting point you curate into the intended
  baseline.

## R6. Change-control and evidence process (extends GR-5)

- **Description:** A **change-control** path for tenant configuration changes (who approves, the
  change window, the rollback plan) and a place to **retain evidence** (health-check reports, drift
  reports, role-audit exports) for audit.
- **Why required:** Governance requires that configuration changes are approved and reversible and
  that the operating state is provable after the fact. Config-drift detection is only useful if
  unplanned changes are actually caught by a process.
- **How to verify:** Confirm an approval path and change window exist (GR-5) and that generated
  reports are stored in a durable, access-controlled location.
- **How to implement if missing:** Define the approval/rollback process with the tenant owners and
  designate an evidence store before making production configuration changes.
