# Authoring Lessons — learned from validation edits

> **Append-only knowledge base that the `/generate-solution` factory MUST consult before authoring**
> (see generate-solution SKILL §1). Each lesson is a generalizable correction harvested from a human
> validation edit to a published solution doc on Wiki.js (the Documentation Validation Learning Loop,
> CLAUDE.md §6). The goal: every new Microsoft-technology implementation doc the factory builds applies
> the accumulated, real-world corrections — so accuracy compounds as the catalog grows.
>
> **How entries get here:** the daily learning run diffs each published wiki page against the factory
> render; for each human correction it (a) syncs the fix into that solution's source and (b) — when the
> correction generalizes — adds a lesson below. Recurring/high-impact lessons are promoted into the
> SKILL house-style (with human approval).
>
> **Format per lesson:** `- [YYYY-MM-DD] (category · tag) Lesson. — from <slug> / <source-file> · Step N`
> Keep each lesson atomic, imperative, and reusable across solutions. Don't delete; supersede with a
> newer dated line if a lesson changes.

## Intune Solutions

### Navigation paths
- [2026-06-23] (intune-solutions · ade-enrollment) When a step creates an **iOS/iPadOS ADE enrollment
  program profile**, give the **full navigation path**, not just "open Profiles → Create": *Devices >
  Enrollment > Apple > Enrollment program tokens > (open the ADE token) > Profiles > Create profile >
  iOS/iPadOS*, then "enter a name and description." Novice admins can't find the Profiles tab without
  the token-drill-down. — from `cod-byod-iphone-dual-device-sso` / `03-implementation.md` · Step 6

### Prerequisites & requirements
<!-- (none yet) -->

### Naming & objects
- [2026-06-25] (intune-solutions · store-app) When a step adds an app from the **iOS/iPadOS (or
  managed Google Play) store**, identify it by its **exact store publisher name and bundle/package
  ID**, and disambiguate it from similarly-named apps. Don't write just "search **Webex** (publisher
  **Cisco**)" — write "publisher **Cisco Systems, Inc.** — bundle ID `com.cisco.squared`, *not*
  'Webex Meetings'". Store search returns multiple near-identical results; the exact publisher string
  + bundle ID is what guarantees the admin selects (and kiosk-locks to) the right app. — from
  `ios-iphone-shared-device-mode` / `03-implementation.md` · Step 9

### Wording & clarity
<!-- (none yet) -->

## Entra ID Solutions
<!-- (none yet) -->

## Defender Solutions
<!-- (none yet) -->

## Cross-cutting (all categories)
- [2026-07-02] (cross-cutting · commercial-vs-government) **Commercial M365 and Government (GCC / GCC High / DoD) tenants often differ in actual setup — not just price.** Different admin portal URLs (e.g. `portal.azure.us`, `portal.office365.us`, `endpoint.microsoft.us`, `login.microsoftonline.us`), feature/endpoint availability and parity gaps, service rollout timing, and compliance constraints mean a step-by-step guide that is correct for Commercial can be wrong for Government. **When authoring any solution, research whether the configuration differs for Government** and, where it materially does, produce a **distinct Government deliverable** (its own guide/scripts) rather than reusing the Commercial deliverable at the Government price. The 3-tier pricing (Commercial/NPO/Gov) is a pricing model; it does NOT imply the Gov content is identical. Where Gov differs, treat it as a separate product/deliverable (own slug/SKU/guide), not price-level-3 of the same service. — from owner directive (Dolibarr catalog review)
- [2026-07-07] (cross-cutting · dedupe-gap-only-and-effort-pricing) **When a proposed solution OVERLAPS an existing product, do not rebuild the overlap — identify the specific GAP the existing product does NOT cover, and scope the new product to ONLY that gap.** (E.g. "Exchange Online Archiving" vs the existing `PURVIEW` retention product → scope the new one to email archiving specifically — archive mailboxes / EOA / auto-expanding archive / litigation & in-place hold — not Purview's DLP/labels/retention.) When deduping a JD/request against the catalog, always state what's already covered and propose only net-new gap scope. **Corollary — effort-based pricing:** if scoping to the gap (or adding genuinely new features/details to an EXISTING solution) materially increases the delivery effort, raise the price a tier to match the effort per `pricing.md` — but ONLY when the added effort is real; do not inflate price for cosmetic additions. This gap-only + effort-priced discipline is how the factory and catalog improve over time (less duplication, right-sized products/prices). — from owner directive (Messaging-wave dedupe)
