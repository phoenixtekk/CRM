# Sales Content — Windows Delivery Optimization (Bandwidth Savings & Peer Content Distribution)

## Hook
**Download once, share everywhere.** Stop every managed device pulling the same updates and apps over
your internet link. Configure Windows Delivery Optimization in Intune so Microsoft content crosses the
WAN **once per network** — peer-shared and cached — and prove the saving with real numbers.

## The problem
Every Windows device independently downloads monthly updates, feature updates, Microsoft Store and
Microsoft 365 Apps updates, Intune Win32 apps, and Autopilot/ESP content. Across a fleet — especially
branch offices on modest circuits — that duplicate traffic saturates the WAN, slows provisioning, and
inflates bandwidth cost.

## The value — run it yourself
- **Simpler** — exact Intune Settings Catalog steps in the right order: Download Mode, peer group
  scoping (GroupIDSource), bandwidth caps (absolute/percentage, business-hours), cache sizing.
- **Cheaper** — one fixed price vs. an open consulting meter ($1,500–$3,000/day); it pays for itself in
  reclaimed WAN bandwidth. Buy once, unlimited devices.
- **Tested** — pilot-first (Assess → Configure → Pilot → Validate → Expand) with validation scripts and
  pass/fail gates. You *prove* peering works and *measure* the saving before you expand.

## What's inside
- 8 source documents: Executive Summary, Solution Overview, Requirements (+ category global
  requirements), Implementation, Testing, Troubleshooting, Best Practices, Deliverables Summary.
- 5 PowerShell scripts: `DELOPT-Preflight`, `DELOPT-Get-Status`, `DELOPT-Report-Savings`,
  `DELOPT-Get-Policy`, `DELOPT-Remediation`.
- Compiled PDF + Word guide and the scripts, delivered as one Complete Solution ZIP.

## Scope boundary (honest positioning)
This is the **content-delivery / bandwidth** layer. It optimizes *how* content reaches devices — it
does **not** decide *what* patches deploy or *when* (Windows Update for Business), patch third-party
apps (Third-Party App Patching), or package Win32 apps (Win32 App Packaging & Deployment). Microsoft
Connected Cache is covered at **decision level**; standing up an MCC node is a separate future product.

## Pricing
| Tier | SKU | Price |
|---|---|---|
| Commercial | `PTK-DELOPT-COMM-001` | $2,295.00 |
| Non-Profit (−40%) | `PTK-DELOPT-NPO-001` | $1,377.00 |
| Government (−15%) | `PTK-DELOPT-GOV-001` | $1,950.75 |

Discounted tiers require eligibility verification (non-profit status; public-sector status).

## The bottom line
The same updates and apps cross the internet once per network instead of once per device — lower
bandwidth, faster provisioning, and peer-vs-HTTP-vs-cache numbers that prove it. Deployable by a
single administrator, validated on a pilot before you expand.
