# 3. Implementation Guide — SaaS Application Discovery & License Right-Sizing

Follow these steps in order. Discovery and reporting use the Microsoft Entra admin center
(`entra.microsoft.com`) and the Microsoft Graph PowerShell scripts; right-sizing actions happen in each
SaaS app's own admin console.

> Model: discover the inventory, map owners and spend, build a right-sizing register on a pilot scope,
> validate the actions, then expand. A pilot gate sits between Validate and Expand.

## Step 1 — Create the review-scope group
1. Go to `entra.microsoft.com` then Identity then Groups then All groups then New group.
2. Group type Security; Name `Review Scope – SaaS – Pilot`. Add a representative set of users (one
   department or team whose SaaS use you understand). Create.
3. You can build or refresh this group later with `SAASLIC-Set-ScopeTargeting.ps1`.

## Step 2 — Discover the SaaS app inventory
1. Go to `entra.microsoft.com` then Identity then Applications then Enterprise applications. This list
   is your raw SaaS inventory (apps integrated for sign-in).
2. Run `SAASLIC-Discovery.ps1` to export the enterprise apps plus per-app sign-in activity to a CSV.
3. Record the result as `App Inventory – SaaS – Discovered`. Add any apps bought outside SSO (from
   expense/procurement data) manually — sign-in logs cannot see those.

## Step 3 — Read usage and insights
1. Go to `entra.microsoft.com` then Identity then Applications then Enterprise applications then Usage
   and insights. Review sign-in counts per app over the last 7/30 days.
2. Cross-check against `SAASLIC-Discovery.ps1` output. Flag apps with few or zero sign-ins as
   consolidation/retirement candidates.

## Step 4 — Map owners and spend
1. For each app in `App Inventory – SaaS – Discovered`, add the business owner (Requirement 2.5) and
   the annual cost plus entitled seats (Requirement 2.7).
2. Save this as `Owner Map – SaaS – Mapped`. Sort by annual cost so the highest-spend apps are reviewed first.

## Step 5 — Build the right-sizing register (pilot scope)
1. Run `SAASLIC-Report.ps1` to produce, per app, the entitled seats versus actively-signing-in users
   over your dormancy window, with a wasted-seat and estimated-savings figure.
2. For each app, choose a right-sizing lever and record it in `Right-Sizing Register – SaaS – Pilot`:
   - Reclaim — users with no sign-in across the window; remove their seat.
   - Consolidate — two or more apps doing the same job; pick one, migrate users off the others.
   - Downgrade — users who sign in but do not need the premium plan; move them to a cheaper tier.
3. Get each app owner's approval against the register before any seat is changed.

## Step 6 — Flag reclaim candidates safely
1. Run `SAASLIC-Remediation.ps1` (default `-WhatIf`). It lists the dormant-seat reclaim candidates and
   writes a candidate file — it changes nothing by default.
2. Review the candidate list with the owner. The actual seat removal/downgrade is performed in each
   SaaS app's own admin console (or its automation); this solution flags, it does not delete vendor seats.

## Step 7 — Validate the pilot (pilot gate)
1. Confirm reclaimed users in the pilot were genuinely dormant and have not lost needed access — check
   for any access request or complaint after the change.
2. Re-run `SAASLIC-Report.ps1` and confirm the seat counts and spend for the pilot apps dropped as
   expected. Complete the Testing Guide.
3. Pilot gate: only proceed to Step 8 when the pilot apps pass the Testing Guide and no wrongful
   reclaim occurred.

## Step 8 — Expand to the full estate
1. Build `Review Scope – SaaS – Expanded` (the rest of the organization) with
   `SAASLIC-Set-ScopeTargeting.ps1`.
2. Repeat Steps 2 to 6 across the full inventory; promote the register to
   `Right-Sizing Register – SaaS – Expanded`.

## Step 9 — Set the recurring review
1. Document the cadence (e.g. monthly for high-spend apps, quarterly for the rest) as
   `Review Cadence – SaaS – Recurring`: who runs the scripts, who approves, and the dormancy threshold.
2. Schedule it; each cycle re-runs Discovery and Report, refreshes the register, and reclaims newly
   dormant seats — so sprawl does not creep back.

---
### Order of operations
`Scope group -> Discover inventory -> Usage and insights -> Owner & spend map -> Right-sizing register
-> Flag reclaim (WhatIf) -> Validate (pilot gate) -> Expand -> Recurring review`
