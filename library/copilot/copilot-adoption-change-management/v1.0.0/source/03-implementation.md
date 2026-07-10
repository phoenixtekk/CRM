# 3. Implementation Guide — Microsoft 365 Copilot Adoption & Change-Management Program

Follow these steps in order. This is a program, so most steps are organizational — recruiting people,
building the catalog, launching comms — with the admin-center and script steps used to assign, measure,
and validate. Portal work is in the Microsoft 365 admin center (`https://admin.microsoft.com`) and
Microsoft Entra admin center (`https://entra.microsoft.com`).

> Model: assess readiness and capture the baseline, stand up sponsorship and champions, build the
> role-based use-case catalog and training/comms, pilot with a cohort, measure adoption against the
> baseline, then expand org-wide on a 30-60-90 plan. Every object you create is named and reused.

## Step 1 — Assess readiness and capture the baseline
1. Confirm the global-requirements gate: data readiness (oversharing + labels) and governance policy
   are in place (`global-requirements-copilot.md`). Do not launch broad adoption before this.
2. Run `CPLTADOPT-Discovery.ps1` to list assigned Copilot licenses vs. users who have actually used
   Copilot — this is your **adoption baseline**. Save the output and the date.
3. Run `CPLTADOPT-LicenseOptimization.ps1` to spot assigned-but-unused seats you can reclaim and
   reassign to the pilot cohort.

## Step 2 — Name the executive sponsor and stakeholders
1. Confirm the sponsor (Requirement 2.2). Brief them on the 30-60-90 plan and their two commitments: a
   launch message and periodic visible use.
2. Identify a stakeholder per target role (sales, finance, IT, HR, exec) who will help source champions
   and tailor use cases.

## Step 3 — Build the champions network
1. Entra -> `Identity -> Groups -> All groups -> New group` -> Security ->
   `Copilot Champions Network - Tenant - Steady`. Add at least one champion per major department.
2. Run `CPLTADOPT-ChampionsRoster.ps1` to confirm role/department coverage and flag gaps.
3. Set the champions' cadence: a recurring champions sync, a shared channel for peer questions, and a
   simple way to submit wins and friction back to the program.

## Step 4 — Create the pilot cohort
1. Entra -> `Groups -> New group` -> `Copilot Adoption Pilot - Pilot - Pilot`; add licensed
   representatives of each target role.
2. Run `CPLTADOPT-Discovery.ps1` scoped to the pilot group to confirm every member is licensed (assign
   or reclaim seats as needed).

## Step 5 — Build the role-based use-case catalog
1. For each role, write 4–6 concrete use cases as "task you already do -> the Copilot prompt/action ->
   time saved" (see Solution Overview for the starter set: sales, finance, IT, HR, exec).
2. Validate each use case with that role's champion and stakeholder so it reflects real work.
3. Publish the catalog where the cohort will find it (a Teams tab or SharePoint page), and give
   champions the catalog as their coaching script.

## Step 6 — Stand up the training curriculum
1. Schedule the launch training for the pilot cohort (a short, role-relevant session, not a single
   generic webinar).
2. Add the recurring elements: a weekly prompt clinic, per-role lunch-and-learns run by champions, and
   self-serve quick guides drawn from the use-case catalog.
3. Record sessions and link them from the catalog page so new users can self-onboard.

## Step 7 — Launch the communications cadence
1. Sponsor sends the launch message (Day 0).
2. Run the 90-day comms calendar: weekly Copilot tips tied to a role use case, champion-sourced win
   stories, and gentle nudges to under-active users. Keep it steady — the habit forms in the first 90
   days.
3. Route questions to the champions channel so the network, not the help desk, carries adoption.

## Step 8 — Measure the pilot against the baseline
1. After ~2–4 weeks, run `CPLTADOPT-Report.ps1` to measure active usage, usage by app, and trend for
   the pilot cohort, and compare to the Step 1 baseline.
2. Run `CPLTADOPT-Validate.ps1` to confirm the program is fully stood up (sponsor named, champions
   group populated with coverage, pilot licensed, catalog/comms in place, measurement working).
3. Use the report to target the weak spots — an under-used app gets a focused clinic; a lagging
   department gets more champion attention. Complete the Testing Guide.

## Step 9 — Expand org-wide on a 30-60-90 plan
1. **Days 0–30 (Launch):** sponsor message; pilot cohort trained; champions active; baseline captured;
   weekly tips running. Milestone: pilot cohort activated and measured.
2. **Days 31–60 (Scale):** roll the program to the next wave of roles/departments using the same
   catalog, training, and comms; champions onboard their teams. Milestone: active usage growing
   week-over-week across waves (`CPLTADOPT-Report.ps1`).
3. **Days 61–90 (Embed):** make it business-as-usual — recurring champion syncs, monthly adoption
   report to the sponsor, and a quarterly review of unused licenses (`CPLTADOPT-LicenseOptimization.ps1`)
   to reclaim and reallocate. Milestone: adoption sustained past launch, return reported to leadership.

---
### Order of operations
`Assess + baseline -> sponsor + stakeholders -> champions network -> pilot cohort -> use-case catalog
-> training curriculum -> comms cadence -> measure vs. baseline -> expand on 30-60-90`

### Rollback / adjust
- This is a program, not a tenant configuration — there is nothing destructive to roll back. If
  adoption lags, adjust the levers: re-energize sponsorship, add champions to weak departments, sharpen
  the role use cases, or increase training/comms frequency, then re-measure with `CPLTADOPT-Report.ps1`.
- Reclaiming an unused license (`CPLTADOPT-LicenseOptimization.ps1`) is a report only — reassignment is
  done deliberately in the admin center, never automatically.
