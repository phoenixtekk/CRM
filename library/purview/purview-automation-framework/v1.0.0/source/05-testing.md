# 5. Testing & Validation — Microsoft Purview Automation Framework

Work through every gate. Each has a **method**, an **expected result (pass)**, and a **fail action**.
Tests are read-only or use the framework's own `-WhatIf`/safe-first modes — no policy enforces during
testing. Do not enforce/publish (Implementation Step 7) until every pilot gate passes; then re-confirm on
expand.

> **Remember:** deploying into test/simulation/unpublished mode is *not* enforcement. These gates prove the
> framework deploys, validates, and reports correctly and that policies land in the intended safe-first
> state — enforcement is a separate, deliberate step with its own gate.

## Gate 1 — Toolchain, roles, and licensing are ready
- **Method:** `OPSAUTO-Health.ps1`.
- **Pass:** modules present and current; `Connect-IPPSSession`/`Connect-MgGraph` succeed; the policy-object types your config targets are readable; the required E5/E5-Compliance plan is present where the config needs it.
- **Fail:** install/update the module (Requirement 2.3), assign the missing role (2.2) or license (2.1), and retest.

## Gate 2 — Current-state snapshot is produced
- **Method:** `OPSAUTO-Discovery.ps1` → `Automation Snapshot – Tenant State – Current`.
- **Pass:** the snapshot enumerates existing DLP policies (with mode), sensitivity labels + label policies, and retention policies + rules.
- **Fail:** resolve the connection/permission error the script reports; confirm the view-only role can read each object type.

## Gate 3 — Config validates structurally
- **Method:** `OPSAUTO-Deploy.ps1 -ConfigPath .\baseline.json -ValidateConfigOnly` (no tenant calls).
- **Pass:** the config parses; required fields present; entries needing E5 are flagged; no structural errors.
- **Fail:** correct the config shape/fields the script names; re-validate before any deploy.

## Gate 4 — Dry-run (`-WhatIf`) shows the intended actions only
- **Method:** `OPSAUTO-Deploy.ps1 -ConfigPath .\baseline.json -Scope Pilot -WhatIf`.
- **Pass:** the printed `New-/Set-*` actions match the config; scope is the **pilot** (not tenant-wide); DLP targets **test/simulation mode**, labels **unpublished**, retention **unenforced/pilot-scoped**; **no** enforce/publish action appears.
- **Fail:** the plan shows the wrong scope, mode, or an unexpected enforce — fix the config/scope and re-dry-run. Do **not** `-Commit` until the plan is correct.

## Gate 5 — Safe-first deploy lands objects in the intended mode
- **Method:** `OPSAUTO-Deploy.ps1 ... -Scope Pilot -Commit`, then `OPSAUTO-Discovery.ps1`.
- **Pass:** the pilot DLP policies exist in **test/simulation mode**, labels exist **unpublished**, retention exists **pilot-scoped/unpublished** — nothing is enforcing.
- **Fail:** re-run discovery to confirm mode; if an object enforced, it means `-Enforce` was passed — return it (Step 7 rollback) and re-deploy safe-first.

## Gate 6 — Validation reports no unexpected drift
- **Method:** `OPSAUTO-Validate.ps1 -ConfigPath .\baseline.json -Scope Pilot` → `Automation Validate – Desired State – Drift`.
- **Pass:** every config entry has a matching deployed object in the expected mode; no missing/extra/altered/mode-mismatched items beyond what's intended.
- **Fail:** reconcile — re-deploy the missing/changed object (`-Commit`) or fix the config; investigate any **extra** object (a portal-created policy the config doesn't know about) with its owner.

## Gate 7 — DLP test/simulation results are reviewed
- **Method:** in the Purview DLP portal, open the simulation/test results for the deployed DLP policies (what *would* have matched) and review with the policy owners. **Verify the simulation view exists/behaves as expected in your tenant** (Requirement 2.1).
- **Pass:** the simulated matches are as intended — no obviously over-broad or mis-scoped rule — and the owners accept them.
- **Fail:** adjust the rule conditions/scope in the config, re-deploy safe-first, and re-review before enforcing.

## Gate 8 — Reports/scorecard reflect reality
- **Method:** `OPSAUTO-Report.ps1 -ConfigPath .\baseline.json -Scope Pilot` → inventory + coverage scorecard.
- **Pass:** the inventory matches the deployed objects and the config; the scorecard is green for the pilot (present, correct mode, in scope).
- **Fail:** address the specific red scorecard item (missing policy, wrong mode, out-of-scope) and re-run.

## Gate 9 — Enforcement is deliberate and reversible (only when enforcing)
- **Method:** `OPSAUTO-Deploy.ps1 ... -Scope Pilot -Enforce -WhatIf` → review → `-Enforce -Commit`; then confirm the intended enforce/publish state and confirm rollback works (`-Commit` without `-Enforce` returns to safe-first).
- **Pass:** the enforce step affects only the reviewed pilot objects; rollback cleanly returns DLP to test mode / unpublishes labels+retention.
- **Fail:** if enforce touched more than intended, roll back immediately and re-scope; never expand enforcement until the pilot enforce gate is clean.

## Gate 10 — Cadence catches injected drift
- **Method:** as a test, change one deployed policy in the portal (e.g. disable it), then run the read-only chain (`Discovery → Validate → Report`).
- **Pass:** validation flags the change as drift and the scorecard reflects it; restore the policy via `-Commit`.
- **Fail:** confirm the scheduled chain runs under a role that can read the object and that the config entry matches; fix and retest.

## Evidence to retain
- `OPSAUTO-Health.ps1` and `OPSAUTO-Discovery.ps1` outputs (before/after).
- Every `-WhatIf` transcript for deploy and enforce.
- The drift report and coverage scorecard for the pilot and the expanded scope.
- The DLP test/simulation review notes and the change approvals (Requirement 2.6/2.7).

> The framework proves policies are **deployed, validated, and evidenced** as configured. Whether the
> policy *content* (info types, durations, taxonomy) is correct or legally adequate is a **compliance/
> records/legal determination** — these gates test the automation, not the determination.
