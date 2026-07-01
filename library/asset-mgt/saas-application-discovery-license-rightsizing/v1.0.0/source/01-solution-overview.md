# 1. Solution Overview — SaaS Application Discovery & License Right-Sizing

## What this solution is
SaaS sprawl is the new shadow IT: teams buy apps directly, seats are bought and forgotten, and
nobody holds a full picture of SaaS spend. This solution is the repeatable way to discover the SaaS
applications your people actually sign in to, map each app to an owner and a cost, and right-size
licenses by reclaiming unused seats, consolidating overlapping tools, and downgrading over-provisioned
plans. The discovery signal comes from Microsoft Entra ID — every federated/SSO SaaS app shows up as
an enterprise application, and sign-in plus usage telemetry tells you who is really using it.

## How it works
1. Entra ID enterprise applications are the inventory of SaaS apps integrated for sign-in. Each one
   is a candidate for review.
2. Sign-in logs and the Usage and insights reports show which users authenticate to which app, and
   how recently — the basis for an active-versus-dormant judgement.
3. Each app is mapped to a named owner and an annual cost, producing a spend picture you can rank.
4. Seat utilization (entitled seats versus actively-signing-in users) exposes the three right-sizing
   levers: reclaim dormant seats, consolidate overlapping tools onto one, and downgrade plans nobody
   uses the premium features of.
5. A recurring review keeps the picture current as new apps appear and usage shifts, so sprawl does
   not creep back.

## The named artifacts (use these names everywhere)
This solution produces a small set of artifacts. Name each one with the pattern
`<Purpose> – <Scope> – <Stage>` and reuse the names verbatim across every document, script, and group:

- `App Inventory – SaaS – Discovered` — the list of SaaS enterprise apps found in Entra ID.
- `Owner Map – SaaS – Mapped` — each app mapped to a business owner and annual cost.
- `Right-Sizing Register – SaaS – Pilot` — the working register of reclaim/consolidate/downgrade
  candidates for the pilot scope, promoted to `Right-Sizing Register – SaaS – Expanded` for the fleet.
- `Review Cadence – SaaS – Recurring` — the documented schedule and checklist for the ongoing review.
- `Review Scope – SaaS – Pilot` and `Review Scope – SaaS – Expanded` — the Entra ID groups that bound
  each review pass.

## What you can control
- Which apps are in scope (the inventory and the review-scope groups).
- The dormancy threshold (how many days without a sign-in marks a seat as a reclaim candidate).
- The right-sizing action per app: reclaim, consolidate, or downgrade.
- The review cadence (monthly, quarterly) and who owns each app's decision.

## Benefits
- Spend control — you see total SaaS spend and the slice that is wasted on dormant or duplicate seats.
- Faster reviews — usage telemetry replaces guesswork and email chains about "who still needs this".
- Less sprawl — a recurring review catches new apps and forgotten seats before they accumulate.
- Auditability — a named inventory, owner map, and register make every decision traceable.

## Limitations (be honest with buyers)
- Entra ID sees SaaS apps integrated for sign-in (SSO/federated/gallery). Apps bought outside SSO
  (personal-card purchases, non-federated tools) are not visible from sign-in logs alone — surface
  those from expense/procurement data and add them to the inventory manually.
- Sign-in telemetry shows authentication, not feature-level usage. A user who signs in but never uses
  premium features is a downgrade candidate, which sign-in data alone cannot prove — confirm with the
  app's own admin console where available.
- Sign-in log retention depends on your Entra ID plan; richer history needs a P1/P2 plan or a Log
  Analytics export. This is noted in the Requirements Guide.
- Reclaiming a seat is a SaaS-admin action in each vendor's console. This solution finds and flags the
  candidates; the actual seat removal happens in the app (or via its own automation).

## The standard deployment model
> Discover the inventory, map owners and spend, build the right-sizing register on a pilot scope,
> validate the reclaim/consolidate/downgrade actions, then expand to the full estate.
> The repeatable way: Assess to Configure to Pilot to Validate to Expand.
