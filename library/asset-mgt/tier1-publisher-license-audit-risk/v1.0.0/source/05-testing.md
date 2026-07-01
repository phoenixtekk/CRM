# 5. Testing Guide — Tier-1 Publisher License & Audit-Risk Management

Run after the pilot publisher is processed (Implementation Step 7) and again for each publisher and
each re-validation cycle.

## Test 1 — Scope is complete
Do: Compare the publisher-scope group from `TIER1LIC-Set-ScopeTargeting.ps1` against the deployment
inventory from `TIER1LIC-Discovery.ps1`.
Expected: Every in-scope host/user for the publisher appears in the inventory; nothing in scope is
missing.

## Test 2 — Every product has a defined metric
Do: Open the per-publisher position worksheet.
Expected: Each product line has a named metric, a one-line counting rule, and an entitled quantity —
no blanks.

## Test 3 — Deployment maps cleanly to the metric
Do: Run `TIER1LIC-Validation.ps1` for the publisher.
Expected: Zero unresolved flags — no missing metric, missing core count/factor, or sub-capacity
claimed without the prerequisite. Every install maps to a metric quantity.

## Test 4 — Position and exposure are calculated
Do: Run `TIER1LIC-Report.ps1`.
Expected: Each product shows consumption versus entitlement, a position (shortfall or headroom), and
an exposure quantity; the per-publisher exposure register is written.

## Test 5 — Every exposure item has an owner and disposition
Do: Review the exposure register with the owner/approver.
Expected: Each item is assigned remediate, acquire, or accept-and-budget, with a named owner.

## Test 6 — Remediation proposes, does not change
Do: Run `TIER1LIC-Remediation.ps1` (default).
Expected: It runs in `-WhatIf` mode and outputs a proposed work list only; no system is modified.

## Test 7 — Audit evidence pack is assembled
Do: Open the audit evidence pack for the publisher.
Expected: Contracts, position worksheet, deployment-to-metric mapping, exposure register with
dispositions, and sub-capacity proof (where claimed) are all present and current.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| Pilot pass | Tests 1 to 5 pass for the pilot publisher; no unresolved validation flags |
| Publisher pass | Tests 1 to 7 pass for the publisher before its audit/renewal cycle |
