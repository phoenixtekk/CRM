# 1. Solution Overview — Microsoft 365 License Optimization & Reharvesting

## What this solution is
Microsoft 365 licenses are assigned per user (directly or via group-based licensing) and billed per
seat every month whether or not the seat is used. Over time the assigned count drifts above the
*needed* count: people leave but keep their seats, users are placed on a high tier (E5) when a lower
tier (E3) covers what they actually do, and duplicate or overlapping plans accumulate. This solution
is a repeatable way to measure real usage, identify the waste, reclaim it safely, and keep it
reclaimed — using only the Microsoft 365 admin center and Microsoft Graph, no third-party tooling.

## Why this matters
- License waste is invisible by default. The admin center shows *assigned* counts, not *used* counts; the gap is where the money leaks.
- A single E5 → E3 right-size or a single reclaimed leaver seat recovers real, recurring dollars every month, and the savings compound across a fleet.
- Reclamation done carelessly breaks people — a shared mailbox, a service account, or a seasonal user can look "inactive" and must never be stripped blindly. The discipline below makes reclamation safe.
- A one-time cleanup regresses within months as new leavers and new over-tier assignments appear. The value is in the *recurring campaign*, not a single sweep.

## How it works
1. Microsoft 365 subscriptions are read as `subscribedSku` objects via Microsoft Graph: each SKU has a `prepaidUnits` (purchased) and `consumedUnits` (assigned) count — the first gap to close is purchased-but-unassigned seats.
2. Each user's assigned plans are read from the Graph user `assignedLicenses` / `licenseDetails`, giving an authoritative assigned inventory per person and per SKU.
3. Real usage is measured from the Microsoft 365 usage reports (Graph `reports` endpoints and the admin center Usage area): last activity date for Exchange, Teams, SharePoint, OneDrive, and overall last sign-in. A seat with no activity across the window is a candidate.
4. Candidates are classified into three levers — **unused** (assigned but no activity / leaver), **duplicate** (overlapping plans on one user), and **over-tier** (on a higher SKU than usage justifies, e.g. E5 features never touched).
5. Candidates are validated for safety (inactivity confirmed across the full window; shared mailboxes, resource/room accounts, and service accounts excluded) before any change.
6. Reclamation removes the unused/duplicate license or right-sizes the tier; freed seats either reduce the next true-up or are reassigned, and the savings are reported.
7. The whole cycle is wrapped in a recurring **savings campaign** so the tenant stays right-sized as the population changes.

## The three optimization levers
- **Reclaim (unused / leavers):** remove a license from a user with no activity across the measurement window — the largest and safest win when validated.
- **De-duplicate:** remove an overlapping plan when a user carries two SKUs that grant the same service (e.g. a standalone plan plus a suite that already includes it).
- **Right-size (downgrade tier):** move a user from a higher SKU to a lower one when the high-tier-only features show no usage (e.g. E5 → E3 when advanced security/analytics features are unused).

## What you can control
- Which SKUs are in scope for optimization (start with the highest unit cost).
- The inactivity window that defines "unused" (e.g. 90 days of no sign-in and no service activity).
- The exclusion rules that protect shared mailboxes, room/resource accounts, and service accounts.
- The pilot candidate set reclaimed first, before any broad sweep.
- The cadence of the recurring savings campaign (e.g. monthly).

## Limitations (be honest with buyers)
- Microsoft 365 usage reports can be **de-identified** (names replaced with anonymized IDs) by a tenant privacy setting; with it on, per-user matching is impossible until it is turned off (see Requirements).
- Usage data has latency (reports reflect activity up to a few days old) and a fixed maximum window (up to 180 days), so set the inactivity window inside the available range.
- Downgrading a tier can remove features a user *will* need later; right-size on evidence, communicate, and keep an easy re-grant path.
- Removing a license can affect data retention for some services (e.g. mailbox/OneDrive grace periods) — confirm retention before reclaiming a leaver's last license.

## Naming convention (used in every doc and script)
Every artifact this solution creates is named `<Purpose> – <Scope> – <Stage>` and reused verbatim
across the docs, scripts, and admin center. The standard set:

| Artifact | Name |
|---|---|
| Saved discovery export | `License Inventory – M365 – Discovery` |
| Saved usage export | `Usage Activity – M365 – Discovery` |
| Reclaim-candidate list | `Reclaim Candidates – M365 – Validation` |
| Savings report | `Savings Report – M365 – Report` |
| Pilot reclaim target group | `Reclaim Targets – Pilot – Stage1` |
| Broad reclaim target group | `Reclaim Targets – Broad – Stage2` |
| Exclusion (protected) group | `Reclaim Exclusions – Shared+Service – AllStages` |
| Savings campaign tag | `Savings Campaign – M365 – Recurring` |

## The standard deployment model
> Build the baseline → classify candidates → reclaim a safe **pilot** set first → validate the savings
> and that nobody broke → expand to the broad set and stand up the recurring campaign.
> Pattern: **Assess → Configure → Pilot → Validate → Expand.**
