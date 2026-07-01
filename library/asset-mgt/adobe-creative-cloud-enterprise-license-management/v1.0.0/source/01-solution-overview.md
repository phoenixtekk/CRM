# 1. Solution Overview — Adobe Creative Cloud for Enterprise License Management

## What this solution is
This is the repeatable way to manage Adobe Creative Cloud for Enterprise licensing in the Adobe
Admin Console. It treats Adobe seats as a Software Asset Management (SAM) problem: every paid seat
should be deliberately assigned to a person who needs it, sized to the right product, reclaimed when
it falls idle, and reviewed on a recurring cadence. The goal is to keep Adobe spend matched to real
need without disrupting the people who genuinely use the tools.

Adobe Admin Console internals, identity and single sign-on (SSO) configuration, and the exact API
authentication flow change over time and are owned by Adobe. This solution defers those specifics to
Adobe's official documentation and focuses on the correct general procedure and the SAM process that
wraps around it.

## The Adobe Creative Cloud for Enterprise licensing model
Creative Cloud for Enterprise uses named-user licensing. A paid entitlement (a seat) is consumed
when a product is made available to a specific user, not when software is installed on a device. The
key building blocks are:

- Named-user licensing — a seat is tied to an individual identity. Assigning or removing a user from
  an entitlement is what consumes or frees a seat.
- Product profiles — within a purchased product (for example an all-apps plan or a single-app plan),
  a product profile defines which services and how many seats are made available, and which users or
  user groups are entitled. Assignment to a product profile is the act that consumes a seat.
- User groups — collections of users that can be attached to product profiles so assignment scales
  by role rather than one person at a time.
- Identity types — Adobe supports more than one identity type for accounts (for example federated
  identity backed by an organization's identity provider, enterprise-managed identities, and Adobe
  IDs). The identity type affects how users are created, authenticated, and governed. The exact setup
  is deferred to Adobe's documentation; for SAM purposes the relevant fact is that each named user
  occupies a seat regardless of identity type.

## How seat management works
1. Confirm the identity foundation (how users sign in) and the product profiles that exist for each
   purchased Adobe product.
2. Build a product-profile map so it is clear which profile grants which product and how many seats
   each profile is sized for.
3. Inventory the assigned seats — which named users are entitled through which profiles — and gather
   usage data so idle and over-provisioned seats become visible.
4. Right-size: match each user to the cheapest product that meets their real usage (for example move a
   single-app user off an all-apps profile), and flag seats with no recent activity for reclamation.
5. Reclaim idle seats by removing the user from the product profile, freeing the seat for reuse or for
   a true-down at renewal.
6. Reassign freed seats to people on a waiting list instead of buying new ones.
7. Run a recurring review so the estate does not drift back out of alignment.

## Where usage data comes from
Adobe exposes administrative data through the Adobe User Management API (a REST API). Where that API
is available to you, assignment and group data can be read programmatically. Adobe activity and usage
detail is also available through the Admin Console as reports and CSV exports. This solution reads
Adobe data through the User Management API where available and otherwise operates on an Admin Console
CSV export — both paths are supported, and the scripts comment clearly where Adobe-specific endpoints
or export columns are required.

## What you can control
- Which named users are assigned to which product profiles (and therefore which seats are consumed).
- Right-sizing — moving users between an all-apps profile and a single-app profile to fit real usage.
- Reclamation — removing idle users from profiles to free seats.
- Review cadence — the recurring schedule on which the estate is re-inventoried and re-checked.

## Why this matters
- Cost control — all-apps seats are expensive; an unused or over-provisioned seat is pure waste.
- Compliance — assignments stay reconciled against the purchased entitlement count, so you are neither
  over- nor under-licensed at true-up or renewal.
- Predictability — a recurring review means reclamation is routine, not a fire drill triggered by a
  surprise renewal quote.
- Reuse over rebuy — freed seats go to the next requester, deferring or avoiding new purchases.

## Limitations (be honest with buyers)
- This solution manages Adobe Creative Cloud for Enterprise seat assignment and right-sizing. It does
  not negotiate Adobe contracts or perform the purchase or true-up transaction itself.
- The exact Admin Console menus, identity and SSO setup, and API authentication flow are owned by
  Adobe and are deferred to Adobe's official documentation; they may change.
- Usage and activity detail depends on what the Adobe User Management API and Admin Console exports
  expose to your organization; some signals require the appropriate Admin Console report.
- Removing a user from a product profile revokes their access to that product — reclamation must follow
  the review and confirmation steps so active users are never cut off.

## The standard deployment model
> Confirm identity and product profiles, build the product-profile map and seat inventory, identify
> unused and over-provisioned seats, reclaim and reassign, set a recurring review, then prove it on a
> pilot scope before expanding. Standard model: Assess to Configure to Pilot to Validate to Expand.
