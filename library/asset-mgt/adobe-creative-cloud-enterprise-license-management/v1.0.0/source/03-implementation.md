# 3. Implementation Guide — Adobe Creative Cloud for Enterprise License Management

Follow these steps in order. Work in the Adobe Admin Console and, where available, the Adobe User
Management API; the supplied scripts assist at each read-only step.

Adobe-specific configuration (exact Admin Console menus, identity and SSO setup, API authentication)
is deferred to Adobe's official documentation. The steps below give the correct general procedure and
name every artifact you produce so the same names are reused in Testing, Troubleshooting, and the
recurring review.

> Model: Confirm the foundation, inventory and analyze, reclaim and reassign, then institutionalize a
> recurring review — proven on a pilot scope first. Standard model: Assess to Configure to Pilot to
> Validate to Expand.

Named artifacts produced by this guide (reuse these exact names):
- `Product-Profile Map – All Adobe Products – Configure`
- `Seat Inventory – Pilot Scope – Assess`
- `Right-Sizing Register – Pilot Scope – Validate`
- `Review Cadence – Adobe Estate – Expand`
- `Reclaim-Review Group – Pilot Scope – Validate`

## Step 1 — Confirm identity and product profiles (Assess)
1. In the Admin Console, confirm the identity type and directory are in place and stable (requirement
   2.2). Do not change identity setup here; only confirm it.
2. Under Products, list every purchased Adobe product and its product profiles, and record each
   profile's seat quota and entitled users or groups into `Product-Profile Map – All Adobe Products – Configure`.
3. For each profile note whether it is an all-apps or single-app entitlement and its per-seat cost
   from the entitlement record (requirement 2.4). This map is what makes right-sizing possible.

## Step 2 — Inventory assigned seats for the pilot scope (Assess)
1. Choose the pilot scope (requirement 2.7) — typically the all-apps profile or one department.
2. Run `ADOBELIC-Discovery.ps1` to read assignments. Where the Adobe User Management API is available,
   the script reads users and product assignments via the API; otherwise it reads an Admin Console CSV
   export you provide. Save the output as `Seat Inventory – Pilot Scope – Assess`.
3. Confirm the inventory's seat count per profile reconciles to the Admin Console quota and to the
   purchased count in the entitlement record. Note any variance.

## Step 3 — Identify unused and over-provisioned seats (Validate)
1. Run `ADOBELIC-Validation.ps1` against the seat inventory plus the activity or last-active signal
   (from Adobe reporting where available; otherwise the best available export). The script classifies
   each seat as active, idle (no recent activity beyond your threshold), or over-provisioned (for
   example an all-apps seat used as a single app).
2. Record the candidates in `Right-Sizing Register – Pilot Scope – Validate`, one row per user with:
   current profile, recommended action (keep, downsize, reclaim), evidence (last-active or usage), and
   a confirmation owner.
3. Run `ADOBELIC-Report.ps1` to produce a seat and cost summary — assigned versus active seats per
   profile and the estimated cost of idle and over-provisioned seats. This is the business case for the
   reclamation.

## Step 4 — Build the reclaim-review group (Configure)
1. Run `ADOBELIC-Set-ScopeTargeting.ps1` to assemble the reclaim and downsize candidates from the
   right-sizing register into a review group named `Reclaim-Review Group – Pilot Scope – Validate`.
   The script prepares the list (and, where the API is available, can stage an Adobe user group);
   it does not remove anyone.
2. Route the group to the confirmation owners named in the register. Reclamation only proceeds for
   users a confirmation owner approves — this protects active users from losing access.

## Step 5 — Reclaim and reassign (Validate, pilot gate)
1. For each approved reclaim candidate, remove the user from the product profile in the Admin Console
   (or via the User Management API where you have a tested, authorized write path). Removing the user
   from the profile frees the seat. The exact removal action is deferred to Adobe's documentation.
2. For each approved downsize candidate, remove the user from the all-apps profile and add them to the
   appropriate single-app profile.
3. Reassign freed seats to people on the waiting list before purchasing any new seats.
4. Re-run `ADOBELIC-Discovery.ps1` and `ADOBELIC-Report.ps1` and confirm the freed and reassigned
   seats are reflected. This is the pilot gate — see the Testing Guide for the pass and fail criteria.

## Step 6 — Set the recurring review (Expand)
1. Define `Review Cadence – Adobe Estate – Expand`: the schedule (for example monthly or quarterly),
   the owner, the idle threshold, and the artifacts to refresh each cycle (the seat inventory, the
   right-sizing register, and the seat-and-cost report).
2. Schedule `ADOBELIC-Discovery.ps1`, `ADOBELIC-Validation.ps1`, and `ADOBELIC-Report.ps1` to run each
   cycle so the next review starts from current data.
3. Tie the cadence to the renewal date in the entitlement record so a true-down is prepared before
   renewal, not discovered after.

## Step 7 — Expand beyond the pilot
1. After the pilot gate passes, repeat Steps 2 through 5 for the next scope (the next product profile,
   department, or office), reusing the same named artifacts scoped to the new area.
2. Continue until the whole Adobe estate is covered, then let `Review Cadence – Adobe Estate – Expand`
   keep it aligned.

---
### Order of operations
`Confirm identity and profiles -> Seat inventory -> Identify idle and over-provisioned -> Reclaim-review group -> Reclaim and reassign (pilot gate) -> Recurring review -> Expand`
