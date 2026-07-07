# Testing & Validation

Each procedure states the exact check and its **expected pass/fail** signal. Reuse the artifact names
from Implementation. Run all read-only validations before any `--apply`.

## Test 1 — Auth least-scope (Gate 3-A)
**Procedure:** Run `gwsdk_auth_scope_validator.py`. It authenticates the service identity
(`Automation SA – AdminSDK – Core`) impersonating `Impersonation Subject – Reports – ReadOnly`, lists
the scopes actually granted on `DWD Grant – AdminSDK – LeastScope`, and compares them to the declared
task→scope inventory.
- **Pass:** authentication succeeds; the granted scopes exactly match the intended read-only set (plus
  the write scope only if provisioning is authorized); no scope is flagged as broader than required.
- **Fail:** authentication fails (`unauthorized_client` / `access_denied`) or an over-broad or missing
  scope is reported. Fix the DWD grant / impersonation subject before continuing.

## Test 2 — Discovery baseline is read-only and complete
**Procedure:** Run the discovery tool to produce `Discovery Report – Tenant – Assess`.
- **Pass:** a dated report is written with user counts, OU distribution, license usage, and suspended
  accounts; the run made **no** write calls (verify no admin activity from the run in the audit report).
- **Fail:** missing sections, an empty report, or any write call observed.

## Test 3 — Reports accurate (Gate 4-A)
**Procedure:** For the pilot scope, generate `Sharing Report – External – Validate` and `Audit Report –
Login – Validate`. Spot-check a sample of rows against the Admin console (same users/files/events).
- **Pass:** sampled rows match the console (external-shared files are genuinely external; login events
  match sign-in activity).
- **Fail:** discrepancies → check scope, impersonation subject, and Reports API event latency before
  trusting the report.

## Test 4 — Automation idempotent, dry-run (Gate 4-B)
**Procedure:** Run `Provisioning Run – Finance-OU – Pilot` in **dry-run** (default) **twice** against the
same desired-state input.
- **Pass:** both runs produce an identical plan; users already in desired state show **no change**.
- **Fail:** the two plans differ, or a no-op user shows a planned change → fix desired-state input or
  matching logic. Do **not** proceed to `--apply`.

## Test 5 — Apply correctness (Gate 4-C)
**Procedure:** After `--apply` on the pilot OU, immediately re-run the provisioning tool in dry-run.
- **Pass:** the plan now shows **no changes** (tenant matches desired state); the audit report shows the
  expected admin actions and nothing more.
- **Fail:** residual planned changes or unexpected admin actions → **roll back** via the change log
  (`--revert <logfile>`), then investigate.

## Test 6 — Rollback works
**Procedure:** In a controlled test, apply a small change on the pilot OU, then run `--revert <logfile>`
(dry-run, then `--apply`).
- **Pass:** the revert plan exactly reverses the applied change and, after apply, the tenant is back to
  the prior state (dry-run shows no diff).
- **Fail:** the revert plan is incomplete → the change log is not capturing prior values correctly; fix
  before relying on any production apply.

## Test 7 — No secrets in code / no key committed
**Procedure:** Scan the repo for private-key material, `*.json` service-account keys, and credentials in
committed files; confirm the scripts obtain credentials only from ADC / a runtime-supplied path.
- **Pass:** no key or secret is present; credentials resolve from ADC / secrets manager only.
- **Fail:** any key or secret found → remove, **rotate** it, and reconfigure to ADC/secrets manager.

## Test 8 — Scheduled evidence (Gate 6-A)
**Procedure:** Deploy `Schedule Definition – Reports – Expand` and let the first scheduled run execute.
- **Pass:** the expected dated artifact appears in the expected location, complete.
- **Fail:** missing/partial artifact → check the scheduler entry, the runtime credential (ADC available
  to the scheduled context), and the tool's exit code/log.
