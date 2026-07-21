# 5. Testing Guide — Remote Help Operations & Adoption

Run after the pilot setup (Implementation Step 7a) and after each expansion wave. Each test has an
explicit **PASS/FAIL**. All object names match Section 3 exactly.

## Test 1 — An agent can help only in-scope users
**Do:** As a **Tier 1** agent (`RHELP-T1-Agents`), start a Remote Help session to a user **in**
`RHELP-Scope-Standard-Users`; then attempt a user **not** in any scope assigned to Tier 1 (for
example a `RHELP-Scope-VIP-Users`-only user). Also run **`RHELPOPS-Test-Scope.ps1`**.
**PASS:** The in-scope session is permitted; the out-of-scope attempt is **not** available/permitted,
and `RHELPOPS-Test-Scope.ps1` reports the Tier 1 scope resolves to the intended users **and no more**.
**FAIL:** A Tier 1 agent can help a user outside `RHELP-Scope-Standard-Users`.

## Test 2 — Capability matches the tier
**Do:** Verify a **Tier 1** session is **view-only** (no control), a **Tier 2** session allows
**full control**, and a **Tier 3** session allows control **and** elevation.
**PASS:** Each tier has exactly its intended capability (`RHELP Role – Tier 1 View` /
`RHELP Role – Tier 2 Control` / `RHELP Role – Tier 3 Elevation`).
**FAIL:** A tier has more (or less) capability than its role defines — for example Tier 1 can take
control.

## Test 3 — Unattended access works only where governed
**Do:** As **Tier 3**, attempt an unattended session to a device **in**
`RHELP-Scope-Unattended-Devices` (with the approving change/ticket); then attempt an unattended
session to a device **not** in that group, and attempt unattended as **Tier 1/Tier 2**.
**PASS:** Unattended succeeds **only** for approved devices **and only** for Tier 3; every
non-approved device and every non-Tier-3 attempt is refused.
**FAIL:** Unattended works on a non-approved device, or a non-Tier-3 tier can run unattended.
*(If Microsoft does not offer unattended for your platform, this test's PASS is: no unattended path
exists anywhere, and the policy records that — **verify against current Microsoft documentation**.)*

## Test 4 — A session is logged to a ticket
**Do:** Run an attended session end-to-end from a ticket, then inspect the ticket.
**PASS:** The ticket records session start/end time, attended vs unattended, actions taken, and
outcome (resolved/escalated), per Step 5b. Unattended sessions also reference the approving change.
**FAIL:** A completed session leaves no ticket record, or is missing the required fields.

## Test 5 — Escalation moves the ticket (and the authorized tier)
**Do:** As Tier 1, hit a case beyond your capability/scope and escalate.
**PASS:** The **ticket** moves to Tier 2/Tier 3, and the higher tier (not the Tier 1 agent) performs
the control/elevation/VIP action. The Tier 1 agent never exceeds `RHELP Role – Tier 1 View`.
**FAIL:** An agent exceeds their tier instead of escalating the ticket.

## Test 6 — KPIs report
**Do:** Run **`RHELPOPS-Report.ps1`** for the reporting window and review the CSV; run
**`RHELPOPS-Validate.ps1`**.
**PASS:** The report produces the defined KPIs (session volume per tier, average handle time,
first-contact resolution, escalation rate, consent/decline rate, unattended session count, adoption
rate) — populated from Remote Help usage plus ITSM ticket data — and `RHELPOPS-Validate.ps1` reports
the role/scope model in place, reporting available, and unattended governed.
**FAIL:** KPIs cannot be produced, or `RHELPOPS-Validate.ps1` reports the model/reporting/unattended
governance is missing.

## Test 7 — Adoption is measurable
**Do:** Confirm the single request path (ticket queue) is the entry point and that the adoption-rate
KPI (share of eligible tickets using Remote Help) is populated for the pilot population.
**PASS:** Adoption rate is being measured from the defined entry point.
**FAIL:** There is no single request path, or adoption cannot be measured.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| **Pilot pass** | Tests 1, 2, 4, 6, 7 pass for the pilot tier/scope (Test 3 if unattended is in scope) |
| **Wave pass** | Tests 1, 2, 4, 6 pass before the next expansion wave |
| **Unattended go-live** | Test 3 passes before `RHELP-Scope-Unattended-Devices` goes live |
