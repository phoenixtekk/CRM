# Deliverables Summary

Everything included in the **Google Workspace Day-2 Administration & Operations Runbook**, on one page.

## Documentation

- **Solution Overview** — the operating model plus the OU/policy-governance architecture (OU tree,
  policy inheritance, settings baseline, change control) and the Assess → Design → Configure → Pilot →
  Validate → Expand deployment model.
- **Requirements Guide** — the solution-specific prerequisites (steady-state go-live, super-admin +
  admin-team structure, Reports API access/retention, a read-only control-plane identity for the
  tooling, a target-state design/baseline, and change-control/evidence), each with how to verify and
  how to implement if missing — layered on the shared Google-category requirements.
- **Implementation Guide** — exact, ordered steps to design and build the OU tree and settings
  baseline, establish least-privilege admin-role delegation, stand up monitoring/alerting and health
  checks, and author the runbook library — pilot-first, every artifact named, with pass/fail gates and
  rollbacks.
- **Testing & Validation** — eight validation procedures (T1–T8) mapped to the four gates (OU/policy
  applied, least-privilege, monitoring live, runbooks exercised), each with an expected pass/fail
  signal.
- **Troubleshooting** — common failure modes and resolutions (API scope/auth `403`s, drift false
  positives, inheritance confusion, alert-simulation limits, retention gaps).
- **Best Practices** — durable practices for OU/policy governance, least-privilege administration,
  monitoring, runbooks/change control, tooling/credentials, and compliance posture.
- **Runbook Library table of contents** — the named runbooks (onboarding, offboarding, group/Shared
  Drive lifecycle, device action, request handling, three incident runbooks, change control, drift
  review).

## The 5 Python tools

All tools are **read-only or dry-run by default**, contain **no credentials/keys**, authenticate via
OAuth/ADC or a domain-wide-delegated service account with **read-only** Admin SDK scopes, and expose
`--help`. They require `pip install google-api-python-client google-auth` for live API calls and fall
back to a documented **offline/sample mode** so they can be inspected without a tenant.

1. **`ou_policy_assessment.py`** — *Assessment / discovery (read-only).* Enumerates the OU tree
   (Directory `orgunits.list`), users/admins per OU, groups, and an admin-role-assignment summary, and
   writes a JSON baseline snapshot. This is the Assess-stage artifact and the seed for the intended
   settings baseline.

2. **`config_drift_detector.py`** — *Validation / drift detection (read-only).* Compares the live
   configuration for a given OU scope against a curated **baseline JSON** (`ou-policy-baseline.json`)
   and reports each `DRIFT: <setting> expected=<x> actual=<y>`, exiting non-zero when drift exists so
   it can gate CI/scheduled checks.

3. **`admin_role_auditor.py`** — *Delegation / control check (read-only).* Lists every admin-role
   assignment (`roleAssignments.list` + `roles.list`), flags **super-admins** and root-scoped roles,
   and exports a CSV audit for least-privilege review (Gate G2).

4. **`health_check_report.py`** — *Health / monitoring report generator (read-only, Reports API).*
   Pulls recent activity from the Admin SDK **Reports API** (login, admin, drive/token events) for the
   last N days and renders an HTML health report — login summary, admin-activity summary,
   external-sharing summary, and a top-risk section — for the daily/weekly health cadence (Gate G3).

5. **`ops_config_helper.py`** — *Operations / config helper (dry-run default, `--apply` gated).*
   Standardizes routine runbook inputs (e.g. offboarding checklist, group/Shared-Drive lifecycle
   scaffolding) and, by default, **prints the exact API calls it would make** without changing
   anything; write actions require an explicit `--apply` and confirmation. Backs the lifecycle
   runbooks with a safe, repeatable helper.
