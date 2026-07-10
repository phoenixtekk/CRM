# 5. Testing Guide — Microsoft Sentinel SOAR: Automation Rules & Playbooks (Logic Apps)

Run after the pilot is configured (Implementation Step 9) and after each expansion. Use a real incident in the pilot scope, or create a controlled test incident.

## Test 1 — Automation rule fires and triages

**Do:** Trigger (or wait for) an incident in the pilot scope. `Microsoft Sentinel` → `Incidents` → open it. Or run `SENTSOAR-Validate.ps1`.
**Expected:** The incident is auto-assigned to the pilot owner and carries the `soar-pilot` and `auto-triaged` tags applied by `Auto-Triage - New Incidents - Pilot`.

## Test 2 — Enrichment playbook ran

**Do:** On the same incident, read the `Comments`/`Activity log`. Or `Logic Apps` → `Enrichment - Incident - Pilot` → `Runs history`.
**Expected:** An enrichment comment is present (IP reputation and/or account status/risk), and the latest run shows `Succeeded`.

## Test 3 — Notification delivered

**Do:** Check the SOC Teams channel and the SOC mailbox. Or `Notify - Teams-Email - Pilot` → `Runs history`.
**Expected:** An Adaptive Card posted to Teams with the incident summary and deep link, and an email arrived; the run shows `Succeeded`.

## Test 4 — Ticket opened and linked

**Do:** Check the ITSM for a new ticket; read the incident comment for the ticket number/URL. Or `Ticketing - Incident - Pilot` → `Runs history`.
**Expected:** A ticket exists with the incident details, and the ticket number is written back onto the incident.

## Test 5 — Response is approval-gated

**Do:** On an incident, `Actions` → `Run playbook` → `Response - Contain - Pilot`. Watch the SOC Approvals channel.
**Expected:** The playbook pauses and posts an approval card; nothing proceeds until an approver clicks `Approve`. If `Reject` is chosen (or it times out), no action is taken.

## Test 6 — Response is simulate-first (no real change)

**Do:** Approve the card from Test 5 while `SimulateMode = true` (pilot default). Then verify the target was **not** changed — the user is still enabled / the device is not isolated / the IP is not blocked.
**Expected:** The incident gets a `SIMULATE: would ...` comment, and there is **no** change on any platform. `Response - Contain - Pilot` → `Runs history` shows it took the simulate branch.

## Test 7 — Managed identity and least privilege

**Do:** Run `SENTSOAR-Set-PlaybookIdentity.ps1`.
**Expected:** Each playbook has a system-assigned identity; each holds Microsoft Sentinel Responder and no more than it needs. The response playbook has no enforced-action platform permission during the pilot.

## Test 8 — Run history is clean

**Do:** Run `SENTSOAR-Report.ps1`.
**Expected:** A per-playbook and automation-rule summary of runs, success/failure counts, and a confirmation that **no enforced (non-simulate) response action** ran during the pilot.

---

## Pass/fail gate

| Gate | Requirement |
|---|---|
| Pilot pass | Tests 1-8 pass: triage, enrichment, notification, and ticketing run cleanly on real incidents; the response playbook is proven approval-gated and simulate-only; identities are least-privilege |
| Expand pass | After change approval, a single enforced response action runs correctly against one controlled case with the approval gate intact, and cost/run-volume is within budget, before wider rollout |
