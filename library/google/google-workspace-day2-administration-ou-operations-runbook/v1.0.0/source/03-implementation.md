# Implementation

This guide builds the Google Workspace day-2 operations practice in the house order **Assess → Design
→ Configure → Pilot → Validate → Expand**. Work pilot-first: nothing rolls to the whole organization
until the pilot passes the gates in §Validate. Every artifact you create is named with the convention
`<Purpose> – <Scope> – <Stage>` and that exact name is reused in testing, troubleshooting, and the
scripts. Production changes (policy, roles, mail-related settings) carry a documented rollback.

> **Navigation note.** Admin console paths below (admin.google.com) reflect Google's public
> documentation at authoring time. Google occasionally relabels or relocates console sections and adds
> preview features. Where a path or capability may differ by edition or rollout, the step says
> **verify in your tenant**. Never assume; confirm against your current console.

---

## Stage 1 — Assess (read-only baseline)

Establish the current state before changing anything. This is entirely read-only.

1. **Run the discovery/assessment tool.** From a workstation with the R4 credential configured, run:
   ```
   python ou_policy_assessment.py --output ou-policy-baseline-current.json
   ```
   It enumerates the current **OU tree** (Directory API `orgunits.list`), the **users/admins per OU**,
   the **groups**, and a summary of **admin-role assignments**, and writes them to a JSON snapshot. It
   is read-only; it makes no changes.

2. **Run the admin-role/delegation audit.**
   ```
   python admin_role_auditor.py --output admin-role-audit-current.csv
   ```
   It lists every admin-role assignment (`roleAssignments.list`), flags **super-admins**, and flags
   roles assigned at the root vs. scoped to an OU. Save the CSV as the assessment artifact
   `Report – Admin-Role Audit – Assess`.

3. **Capture current monitoring/alert posture.** In **admin.google.com → Security → Alert center →
   Settings**, note which system-defined alerts are enabled and which admin-created alert rules exist.
   Record whether the **Reports API** is enabled (R3/R4).

4. **Record undocumented practice.** Interview the current operators: how are users onboarded/
   offboarded today, who resets passwords, how are incidents handled. This becomes the raw material for
   the runbook library.

**Assess output:** `ou-policy-baseline-current.json`, `Report – Admin-Role Audit – Assess`, an alert
inventory, and notes on current practice.

---

## Stage 2 — Design

Turn the assessment into an intended target design. These are documents/artifacts, not console
changes yet.

### 2.1 Design the OU tree

1. Design a **shallow, purpose-driven OU tree** — populations that need different policy, not a mirror
   of the HR org chart. A common reference shape:
   ```
   Root
   ├── Corp
   │   ├── Standard-Users
   │   ├── Privileged-Users        (admins, finance, legal — stricter policy)
   │   └── Service-Accounts        (no interactive policy; API/service identities)
   └── Contractors                 (restricted sharing, no data export)
   ```
2. Name each OU artifact `OU – <path> – Baseline`, e.g. `OU – Corp/Privileged-Users – Baseline`.
3. Decide **inheritance intent** for each: which settings inherit from parent and which are overridden
   at the child. Prefer inheritance; override only where a population genuinely needs different policy.
4. Where a policy must follow **membership** rather than OU placement, note it for a **configuration
   group** (access-group-based policy targeting) instead of an OU override — **verify group-based
   policy availability for that specific service in your tenant.**

### 2.2 Design the settings baseline

For each OU, document the intended value of the **governance-critical settings** — the ones that carry
security/compliance weight and are the highest-value drift targets:

- **Per-service on/off** (Gmail, Drive, Meet, Chat, Marketplace apps allow-listing).
- **Drive external sharing** (off / allow-listed domains / on) and **link-sharing defaults**.
- **2-Step Verification enforcement** and **login challenges**.
- **Less-secure/legacy access, session length, and context-aware access** where in scope.
- **Gmail routing/compliance/attachment settings** where governed.

Record these in a **baseline file** — `ou-policy-baseline.json` — that the drift detector will compare
live configuration against. Curate it from the Assess snapshot (edit the current-state export into the
intended state). Name it `Baseline – OU Settings – Design`.

### 2.3 Design the admin-role delegation matrix

Map each operations team to the **least-privilege** role and scope:

| Team | Role artifact | Base role | Scope |
|---|---|---|---|
| Tier-1 help desk | `Admin Role – Help Desk – Corp` | Help Desk Admin (custom, reset password + read user) | `OU – Corp` |
| Identity/groups | `Admin Role – Groups – Corp` | Groups Admin | `OU – Corp` |
| Service config | `Admin Role – Services – Root` | Services Admin (scoped services only) | Root or per-service |
| Security ops | `Admin Role – Security-Read – Root` | Custom (security/report read, alert center) | Root |
| Break-glass | (super-admin, kept minimal) | Super Admin | Root |

Custom roles let you grant a **specific privilege set** and, for user-management privileges, **scope
them to an OU** — verify which privileges are OU-scopable in your tenant. The design principle: no
day-to-day task requires super-admin.

### 2.4 Design monitoring/alerting and health checks

1. Define the **monitored events** — the security- and operations-relevant ones the health-check tool
   will report from the **Reports API** (login failures/suspicious logins, admin activity, external
   sharing, OAuth token grants, mobile/device events).
2. Define the **alerts** to enable/create in the alert center, each named `Alert – <condition> –
   Enforce`, e.g. `Alert – Suspicious-Login – Enforce`, `Alert – Admin-Privilege-Change – Enforce`,
   `Alert – External-Sharing-Spike – Enforce`. Use system-defined alerts where they exist; create
   admin rules for the rest — **verify available alert types in your tenant.**
3. Define the **health-check cadence** (e.g. daily automated report, weekly review) the report
   generator produces.

### 2.5 Design the runbook library (table of contents)

List every runbook, each named `Runbook – <task> – Production`:

- `Runbook – User Onboarding – Production`
- `Runbook – User Offboarding – Production`
- `Runbook – Group Lifecycle – Production`
- `Runbook – Shared Drive Lifecycle – Production`
- `Runbook – Device Action – Production` (wipe/block/approve)
- `Runbook – Access Request Handling – Production`
- `Runbook – Incident: Account Compromise – Production`
- `Runbook – Incident: Data Exposure / Oversharing – Production`
- `Runbook – Incident: Mail-Flow Issue – Production`
- `Runbook – Change Control – Production`
- `Runbook – Config-Drift Review – Production`

**Design gate:** the OU tree, baseline file, role matrix, alert list, and runbook TOC are documented
and approved by the change-control and security stakeholders (GR-5/GR-6) before any Configure step.

---

## Stage 3 — Configure (pilot scope first)

Build the design. Apply every change to the **pilot OU** (`OU – Corp/Standard-Users – Pilot`) and the
pilot help-desk team **before** the rest of the organization. Each production change below has a
rollback.

### 3.1 Build the OU tree

1. In **admin.google.com → Directory → Organizational units**, create the OUs from the Design tree.
   Create parents before children.
2. Move a **small pilot set of test/volunteer users** into `OU – Corp/Standard-Users – Pilot`.
   Leave everyone else where they are.
   - **Rollback:** OUs can be deleted only when empty; moving users back to their prior OU reverts
     inherited policy. Record each user's original OU before moving.

### 3.2 Apply the settings baseline to the pilot OU

1. For each governed service, set the intended value from `Baseline – OU Settings – Design` **on the
   pilot OU only** (e.g. **Apps → Google Workspace → Drive and Docs → Sharing settings**, scoped to
   the pilot OU; **Security → Authentication → 2-Step Verification**, scoped to the pilot OU). Leave
   parent/root values unchanged so inheritance elsewhere is untouched.
2. After applying, run the drift detector against the pilot OU to confirm live == baseline:
   ```
   python config_drift_detector.py --baseline ou-policy-baseline.json --scope Corp/Standard-Users/Pilot
   ```
   Expect **0 drift** for the pilot OU.
   - **Rollback:** set the pilot OU settings back to **Inherit from parent**, which restores the
     pre-change behavior.

### 3.3 Create the delegated admin roles

1. In **Account → Admin roles**, create each **custom role** from the delegation matrix with only its
   intended privileges; assign it to the **pilot help-desk member**, scoped to the pilot OU where
   supported.
2. Verify with the auditor:
   ```
   python admin_role_auditor.py --output admin-role-audit-pilot.csv
   ```
   Confirm the pilot help-desk member has exactly the intended role and **no super-admin**.
   - **Rollback:** remove the role assignment; the account reverts to no admin privileges.

### 3.4 Configure monitoring, alerting, and health checks

1. In **Security → Alert center → Settings**, enable the system-defined alerts from the Design list and
   create the admin alert rules (`Alert – … – Enforce`). Set notification recipients to the security-ops
   group. **Verify available alert types in your tenant.**
2. Confirm the Reports API is enabled and the R4 credential can read it. Generate the first health
   report:
   ```
   python health_check_report.py --days 7 --output health-check-pilot.html
   ```
   - **Rollback:** disabling an admin-created alert rule reverts to the prior (no-alert) state; the
     health report is read-only and needs no rollback.

### 3.5 Author the runbook library

1. Write each `Runbook – <task> – Production` from the Design TOC. Every runbook states: **trigger,
   pre-checks, exact Admin console / Admin SDK steps, the artifact names touched, verification, and
   escalation.** Use the ops/config helper to standardize inputs and dry-run destructive lifecycle
   steps:
   ```
   python ops_config_helper.py offboard --user pilot.user@example.com --dry-run
   ```
   (`--dry-run` is the default; it prints the offboarding checklist and the API calls it *would* make
   without changing anything.)
2. Store runbooks in the operations knowledge base alongside the evidence store (R6).

---

## Stage 4 — Pilot

Operate the pilot as if it were production, for a defined window (e.g. one to two weeks):

- Run `Runbook – User Onboarding – Production` and `Runbook – User Offboarding – Production` against
  pilot users, using the pilot help-desk role (not super-admin).
- Fire a **test event** for each configured alert (e.g. a controlled external-share of a pilot
  document) and confirm the alert appears in the alert center and notifies the recipients.
- Run the daily `health_check_report.py` and the weekly `config_drift_detector.py` for the pilot OU.

---

## Stage 5 — Validate (pass/fail gates)

Do not expand until **all** gates pass. See `05-testing.md` for the full procedures.

- **Gate G1 — OU/policy applied:** `config_drift_detector.py --scope Corp/Standard-Users/Pilot`
  reports **0 drift** against `ou-policy-baseline.json`. **Fail →** reconcile the setting or the
  baseline and re-run.
- **Gate G2 — Least-privilege confirmed:** `admin_role_auditor.py` shows the pilot help-desk member
  with **only** the intended role and **no unexpected super-admins**. **Fail →** remove excess
  privilege.
- **Gate G3 — Monitoring live:** every `Alert – … – Enforce` fired on its test event and notified the
  security-ops group; the health report generated with real Reports API data. **Fail →** fix the alert
  rule / API access.
- **Gate G4 — Runbooks exercised:** onboarding, offboarding, a request, and one incident runbook were
  executed successfully by the delegated (non-super-admin) role, with correct verification. **Fail →**
  fix the runbook or the role scope.

---

## Stage 6 — Expand

1. Roll the OU tree and settings baseline to the remaining populations **OU by OU**, running
   `config_drift_detector.py` after each to confirm 0 drift. Move users into their target OUs in
   controlled batches (record original OU for rollback).
2. Assign the delegated admin roles to the full operations teams; re-run `admin_role_auditor.py` and
   confirm the super-admin count is still minimal.
3. Enable the full alert set organization-wide; schedule the health report (daily) and the drift
   detector (weekly) as recurring jobs against the R4 read-only credential.
4. Publish the full runbook library and hand operations to the BAU team as **owned** — every routine
   task has a named runbook, every population a governed policy, and monitoring is live.

**Expansion rollback:** because expansion is OU-by-OU, any batch can be reverted by moving its users
back to their original OU and setting the OU's settings to **Inherit**, restoring pre-change behavior
for that population without affecting others.
