# 5. Testing Guide — Oracle C2M DevOps Release Management & CI/CD Automation

Run after each pipeline run (Implementation Steps 4–7), for QA first and then again for Production. Each
test confirms one stage of the pipeline landed and that source and target are at parity and healthy. The
scripts that touch live systems are read-only; the remediation helper is dry-run by default.

## Test 1 — Environments are reachable and at compatible levels
Do: Run `OC2MDEVOPS-Discovery.sh` against source and target.
Expected: Both report reachable, with the same OUAF release/patch level (or an intended, understood gap)
and the pipeline utilities present; no unplanned version mismatch.

## Test 2 — Build stage produced the release artifacts
Do: Confirm the versioned build and the CMA configuration bundle for the release exist in source control;
run `OC2MDEVOPS-ScopeHelper.sh` to confirm the release tuple.
Expected: The build version, bundle, and IWS list are recorded as one release; the scope matches the
intended change.

## Test 3 — Migrate-config stage applied
Do: On the target, review the CMA import result for the release, then run `OC2MDEVOPS-Validation.py`.
Expected: The import shows applied with no errors and the review showed only the intended scope; validation
reports the config-applied signal present for the promoted scope.

## Test 4 — Deploy stage: code build / patch level is identical
Do: Run `OC2MDEVOPS-Discovery.sh` on source and target and compare the build/patch level.
Expected: The target's code build/patch level equals the source's; configuration and code are in lockstep.

## Test 5 — Inbound Web Services are deployed and active
Do: On the target, check the *Deployment Status* zone for the in-scope services and run
`OC2MDEVOPS-Validation.py` (WLST).
Expected: Each in-scope IWS shows current / active (service revision matches the deployed value, module
state active); on QA/Prod deployment was done with `iwsdeploy`, not the portal.

## Test 6 — Routine-admin automation left the environment healthy
Do: After the deploy stage's quiesce/install/resume, run `OC2MDEVOPS-Validation.py`.
Expected: The admin/managed servers are up in the right order, the `threadpoolworker`s / batch are
re-enabled, the schema is reachable, and the health checks pass — no service left stopped or batch left
paused.

## Test 7 — Configuration objects match (no drift)
Do: Run `OC2MDEVOPS-Report.sql` (or the SQL report) to compare the promoted configuration objects between
source and target.
Expected: Every object in the release scope is present in the target and matches the source; the compare
report shows no missing or mismatched objects for the scope.

## Test 8 — Rollback point is verified (Production)
Do: For Production, confirm the pre-deploy backup restores and the prior bundle/build levels are recorded.
Expected: A verified restore path exists; the release is recoverable inside the change window.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| QA gate | Tests 1–7 pass; configuration parity confirmed, code build matched, IWS active, environment healthy — and QA functional testing passed — before promoting to Production |
| Production gate | Tests 1–7 pass for Production against QA, and Test 8 (verified rollback point) is satisfied inside the change window |
