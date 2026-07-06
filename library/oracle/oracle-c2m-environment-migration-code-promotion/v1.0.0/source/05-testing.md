# 5. Testing Guide — Oracle C2M Environment Migration & Code Promotion (Dev → QA → Prod)

Run after each promotion (Implementation Steps 5–8), for QA first and then again for Production. Each test
confirms one part of the promotion landed and that source and target are at parity. The scripts that touch
live systems are read-only; the remediation helper is dry-run by default.

## Test 1 — Source and target are at compatible levels
Do: Run `OC2MMIG-Discovery.sh` against source and target.
Expected: Both report the same C2M/OUAF release and patch level (or an intended, understood gap); no
unplanned version mismatch.

## Test 2 — The bundle imported and applied
Do: On the target, review the CMA import result for the Migration Request, then run `OC2MMIG-Validation.sh`.
Expected: The import shows applied with no errors; validation reports the CMA-import signal present for the
promoted scope.

## Test 3 — Configuration objects match (no drift)
Do: Run `OC2MMIG-Report.sh` to compare the promoted configuration objects between source and target.
Expected: Every object in the Migration Request is present in the target and matches the source; the
compare report shows no missing or mismatched objects for the scope.

## Test 4 — Code build / patch level is identical
Do: Run `OC2MMIG-Discovery.sh` on source and target and compare the build/patch level.
Expected: The target's code build/patch level equals the source's; configuration and code are in lockstep.

## Test 5 — Inbound Web Services are deployed and current
Do: On the target, check the *Deployment Status* zone for the in-scope services; run
`OC2MMIG-Validation.sh`.
Expected: Each in-scope IWS shows **current** (service revision matches the deployed value); validation
reports the IWS signal present. On QA/Prod, deployment was done with `iwsdeploy`, not the portal.

## Test 6 — Review caught nothing unexpected
Do: Confirm the import review (Step 5.3) showed only the intended objects, and that no target-only object
was unexpectedly replaced or left stale.
Expected: The applied change set equals the intended scope; nothing outside the Migration Request changed.

## Test 7 — Rollback point is verified (Production)
Do: For Production, confirm the pre-import backup restores and the prior bundle level is recorded.
Expected: A verified restore path exists; the promotion is recoverable inside the change window.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| QA gate | Tests 1–6 pass; configuration parity confirmed, code build matched, IWS current — and QA functional testing passed — before promoting to Production |
| Production gate | Tests 1–6 pass for Production against QA, and Test 7 (verified rollback point) is satisfied inside the change window |
