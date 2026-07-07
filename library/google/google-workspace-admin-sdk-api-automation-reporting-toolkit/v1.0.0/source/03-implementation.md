# Implementation

Follow these steps in order. The model is **Assess → Design → Configure → Pilot → Validate → Expand**,
pilot-first. Every artifact is named `<Purpose> – <Scope> – <Stage>` and the same name is reused later
in Testing, Troubleshooting, and the scripts. **No secrets are written into code** at any step; write
operations are **dry-run first** and require an explicit `--apply`.

> High-impact changes in this solution are the **provisioning writes** (`Provisioning Run – Finance-OU –
> Pilot` and later). Each such step names its **pass/fail gate** and its **rollback**.

---

## Stage 1 — Assess

### 1.1 Inventory what you will automate and report on
Confirm the scope: which OUs/groups you provision, which reports you must produce (user/license,
external Drive sharing, login/admin audit, group membership), and the required cadence. Record the
**scope inventory** from Requirements §6 — the task→scope→subject mapping.

### 1.2 Establish the read-only baseline
Nothing here changes the tenant. You will stand up read-only access first and only add write scopes for
the pilot provisioning step.

---

## Stage 2 — Design

### 2.1 Define the naming and artifact conventions
Adopt the reference-model names (Overview). The service identity is `Automation SA – AdminSDK – Core`;
its delegation grant is `DWD Grant – AdminSDK – LeastScope`; its impersonation subject is
`Impersonation Subject – Reports – ReadOnly`.

### 2.2 Design the scope model (least scope)
Assign the **narrowest** scope per task:

| Task | Scope | Access |
|---|---|---|
| Discovery / user & license report | `admin.directory.user.readonly` | read |
| Group membership report | `admin.directory.group.readonly` | read |
| Login / admin audit report | `admin.reports.audit.readonly` | read |
| Drive external-sharing report | `drive.readonly` (or `drive.metadata.readonly`) | read |
| User/OU/license provisioning (`--apply`) | `admin.directory.user` | write |

Read scopes are the default set on the DWD grant. The **write** scope is added only when the pilot
provisioning step is authorized.

---

## Stage 3 — Configure

### 3.1 Create the automation project and enable APIs
As a super-admin, in the Google Cloud console create the project `Automation Project – Workspace – Core`.
Under **APIs & Services → Library**, enable: **Admin SDK API**, **Google Drive API**, and **Cloud
Identity API**. (Directory and Reports are served by the Admin SDK API.)

### 3.2 Create the service identity
In **IAM & Admin → Service Accounts**, create `Automation SA – AdminSDK – Core`. **Do not create or
download a JSON key.** Record its **OAuth client ID** (the numeric unique ID) for the delegation grant.

### 3.3 Authorize domain-wide delegation with least scope
In the **Admin console** → **Security → Access and data control → API controls → Domain-wide
delegation**, add a new grant `DWD Grant – AdminSDK – LeastScope`:
- **Client ID:** the service account's OAuth client ID from 3.2.
- **OAuth scopes:** the **read-only** scopes from 2.2, comma-separated. Add
  `admin.directory.user` (write) **only** when you authorize the pilot provisioning step (3.6).

### 3.4 Choose the impersonation subject
Create or designate a **least-privilege admin** account `Impersonation Subject – Reports – ReadOnly`
(with only the admin privileges the reports require) as the subject the service account impersonates.
Do **not** impersonate a super-admin for routine runs.

### 3.5 Configure runtime credentials (no keys in code)
Provide credentials via **ADC** (`gcloud auth application-default login` for local dev, or an attached
identity in cloud), or reference a secured credential from a **secrets manager** at runtime. Confirm the
scripts read credentials only from ADC / a path passed at runtime — never a committed file.

**Gate 3-A (auth least-scope):** run the auth validator
(`gwsdk_auth_scope_validator.py`). **Pass** = it authenticates, lists exactly the intended scopes, and
flags none as broader than required. **Fail** = fix the DWD grant / impersonation subject before
proceeding. **Rollback:** none needed (read-only); remove any over-broad scope from the grant.

### 3.6 (Deferred) authorize the write scope for provisioning
Only when you reach the pilot provisioning step, add `admin.directory.user` to `DWD Grant – AdminSDK –
LeastScope`. This is a **change-controlled** action.

---

## Stage 4 — Pilot

### 4.1 Run discovery (read-only)
Run the discovery tool to produce `Discovery Report – Tenant – Assess` (user counts, OU distribution,
license usage, suspended accounts). This is read-only and establishes the baseline.

### 4.2 Produce the read-only reports on the pilot scope
Generate, scoped to the pilot OU/group:
- `Sharing Report – External – Validate` (Drive external-sharing exposure), and
- `Audit Report – Login – Validate` (login / admin activity from the Reports API).

Confirm each writes a dated CSV/JSON artifact and the row counts are plausible.

**Gate 4-A (reports accurate):** spot-check a sample of rows against the Admin console for the same
pilot users/files. **Pass** = sampled rows match the console. **Fail** = investigate scope /
impersonation / API before trusting the report.

### 4.3 Dry-run the provisioning automation
Run the provisioning tool against the pilot OU `Provisioning Run – Finance-OU – Pilot` **without**
`--apply` (dry-run is the default). It reads the desired-state input (CSV) and prints, per user, the
exact create/update/move/license action it *would* take — **making no change**.

**Gate 4-B (automation idempotent, dry-run):** run the dry-run **twice**. **Pass** = the planned
actions are identical and, for users already in the desired state, the plan shows **no change**
(idempotent). **Fail** = fix the desired-state input or matching logic before applying.

### 4.4 Apply the provisioning on the pilot (change-controlled)
After Gate 4-B passes and the write scope is granted (3.6), re-run with `--apply` for the pilot OU only.
The tool prints each change as it makes it and writes a result log.

**Gate 4-C (apply correctness):** re-run the tool in dry-run immediately after apply. **Pass** = the
plan now shows **no changes** (the tenant matches desired state) and the audit report shows the expected
admin actions. **Fail** → **rollback**.

> **Rollback for provisioning (`Provisioning Run – Finance-OU – Pilot`):** the apply run writes a
> reversible **change log** (prior value per field per user). To roll back, feed that change log to the
> tool's `--revert <logfile>` mode (dry-run first, then `--apply`) to restore prior OU / license /
> attribute values, or suspend newly created accounts. Because writes are least-scope
> (`admin.directory.user`) and per-user, blast radius is contained to the pilot OU.

---

## Stage 5 — Validate

### 5.1 Confirm all gates green
Auth least-scope (3-A), reports accurate (4-A), automation idempotent (4-B), apply correctness (4-C).
Re-run the full read-only report set and confirm artifacts are dated and complete. See
`05-testing.md` for the detailed validation procedures.

---

## Stage 6 — Expand

### 6.1 Broaden scope
Once the pilot is validated, expand the provisioning desired-state input and the report scope from the
pilot OU/group to the next waves, one controlled step at a time — re-running Gate 4-B (dry-run
idempotency) before each `--apply`.

### 6.2 Schedule the recurring reports
Run the scheduling helper to emit `Schedule Definition – Reports – Expand`: the exact command lines and
cron / Cloud Scheduler / Task Scheduler entries for each recurring report, plus the least-scope
service-identity requirements. Deploy those to your scheduler so evidence is produced automatically.

**Gate 6-A (scheduled evidence):** confirm the first scheduled run produces the expected dated artifact
in the expected location. **Pass** = artifact present and complete. **Fail** = fix the schedule /
credentials (see Troubleshooting).
