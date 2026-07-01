# 5. Testing Guide — Netskope Client Troubleshooting & Diagnostics Toolkit

Run during the help-desk pilot (Implementation Step 7) and after any Netskope client/console change.
These tests validate the toolkit itself — that diagnostics collect correctly and each runbook
resolves or cleanly escalates its failure class.

## Test 1 — Discovery collects client state
**Do:** On a target endpoint run `NSDIAG-Discovery.ps1`.
**Expected:** Reports client installed state, service status, processes, and certificate presence; no access-denied errors (elevated).

## Test 2 — Validation checks connectivity
**Do:** Run `NSDIAG-Validation.ps1`.
**Expected:** DNS resolves, TCP reachability checks return a clear pass/fail, and a steering/auth state summary prints.

## Test 3 — Report returns device context
**Do:** Run `NSDIAG-Report.ps1` and connect to Microsoft Graph.
**Expected:** Per-device context (OS, last sync, compliance) prints; the vendor-deferred client-log reminder is shown.

## Test 4 — Remediation is safe by default
**Do:** Run `NSDIAG-Remediation.ps1` with no switches.
**Expected:** It runs in `-WhatIf` mode and only *describes* the restart/repair/re-enroll actions — it changes nothing until explicitly confirmed.

## Test 5 — Scope group builds
**Do:** Run `NSDIAG-Set-ScopeTargeting.ps1` (with `-WhatIf` first).
**Expected:** It previews, then on confirmation creates/confirms `Diagnostics Scope – Help Desk – Pilot` and reports membership.

## Test 6 — Steering runbook resolves its class
**Do:** On a device with the client service stopped, run `Client Triage – Steering – Diagnose`, then the resolve path.
**Expected:** Discovery shows the service down; the safe restart remediation brings steering back, confirmed by re-running Validation.

## Test 7 — Authentication runbook classifies correctly
**Do:** On a device with an enrollment/auth issue, run `Client Triage – Authentication – Diagnose`.
**Expected:** The bundle and device context point to enrollment/identity/clock skew; the runbook selects re-enroll (not a blind reinstall).

## Test 8 — Clean escalation
**Do:** Simulate an unresolved case (e.g. a suspected cloud-side fault).
**Expected:** The runbook produces the complete `Diagnostic Bundle – Endpoint – Collect` plus the vendor-log handoff note, ready for Netskope support.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| **Pilot pass** | Tests 1–5 pass, and Tests 6–8 show at least one class resolved and one clean escalation |
| **Expand pass** | All eight tests pass and the help desk completed one live ticket cycle through the runbooks |
