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
- [2026-07-07] (intune-solutions · enrollment-time-grouping) **When a solution targets devices via an
  Entra security group AT ENROLLMENT — Windows Autopilot AND iOS/iPadOS ADE / shared-device (no user
  affinity) — the group must be ASSIGNED (not Dynamic) and the Intune Provisioning Client first-party
  service principal (AppId `f1346770-5b25-470b-88bd-d5744ab7952c`, in many tenants displayed as `Intune
  Autopilot ConfidentialClient`) must be an OWNER of that group.** Enrollment-time device grouping works
  by this principal *owning* the assigned group; without the owner the group stays empty at enrollment
  and nothing (profiles/apps) deploys. Always: name the group, state it is **Assigned**, add the step to
  set the SP as **Owner** (Entra → Groups → <group> → Owners → Add owners → search by **AppId**, not the
  display name which varies), add the matching prerequisite (verify SP is owner) and the troubleshooting
  entry (symptom: "device group empty after enrollment / nothing deploys" → add the SP as owner). Flag it
  tenant-verifiable (name varies; provision the SP by opening the Intune portal once as Global Admin if
  absent). — from owner field validation (shared iOS device enrollment) + `windows-autopilot-gcc-high`
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
- [2026-07-10] (entra-id-solutions · cloud-sync) **Entra Connect *cloud sync* "JoinNotFound / users skipped
  / nothing created" is most often a STALE WATERMARK, not a per-user problem — and *Clear quarantine* is
  NOT the fix.** When a job was quarantined earlier (or the domain verified late, or scope changed), cloud
  sync already "saw" and parked the objects and advanced its watermark; once Healthy again they are no
  longer "newly discovered," so every account re-evaluates to JoinNotFound. The fix is **Restart sync**
  (full — resets Watermarks+Escrows+Quarantine, Graph `…/synchronization/jobs/{id}/restart`), then re-run
  Provision on demand → action=Create. Also: on-demand IGNORES scoping but still respects the watermark,
  so on-demand skipping ≠ a scope problem. For new-tenant domain-move cases, verify the moved domain
  first. — from live validation (cloud sync follow-up) / `entra-cloud-sync-users-not-provisioning-joinnotfound-troubleshooting`

## Defender Solutions
<!-- (none yet) -->

## Cross-cutting (all categories)
- [2026-07-02] (cross-cutting · commercial-vs-government) **Commercial M365 and Government (GCC / GCC High / DoD) tenants often differ in actual setup — not just price.** Different admin portal URLs (e.g. `portal.azure.us`, `portal.office365.us`, `endpoint.microsoft.us`, `login.microsoftonline.us`), feature/endpoint availability and parity gaps, service rollout timing, and compliance constraints mean a step-by-step guide that is correct for Commercial can be wrong for Government. **When authoring any solution, research whether the configuration differs for Government** and, where it materially does, produce a **distinct Government deliverable** (its own guide/scripts) rather than reusing the Commercial deliverable at the Government price. The 3-tier pricing (Commercial/NPO/Gov) is a pricing model; it does NOT imply the Gov content is identical. Where Gov differs, treat it as a separate product/deliverable (own slug/SKU/guide), not price-level-3 of the same service. — from owner directive (Dolibarr catalog review)
- [2026-07-07] (cross-cutting · dedupe-gap-only-and-effort-pricing) **When a proposed solution OVERLAPS an existing product, do not rebuild the overlap — identify the specific GAP the existing product does NOT cover, and scope the new product to ONLY that gap.** (E.g. "Exchange Online Archiving" vs the existing `PURVIEW` retention product → scope the new one to email archiving specifically — archive mailboxes / EOA / auto-expanding archive / litigation & in-place hold — not Purview's DLP/labels/retention.) When deduping a JD/request against the catalog, always state what's already covered and propose only net-new gap scope. **Corollary — effort-based pricing:** if scoping to the gap (or adding genuinely new features/details to an EXISTING solution) materially increases the delivery effort, raise the price a tier to match the effort per `pricing.md` — but ONLY when the added effort is real; do not inflate price for cosmetic additions. This gap-only + effort-priced discipline is how the factory and catalog improve over time (less duplication, right-sized products/prices). — from owner directive (Messaging-wave dedupe)

- [2026-07-14] **Intune iOS App Configuration "Enter XML data" is an Apple property list (plist), not free-form XML.** It must be a lowercase `<dict>` root containing only `<key>`/`<string>`(etc.) pairs. A capitalized `<Dict>` fails ("must begin and end with 'dict' tag"); a pasted vendor profile with `xmlns`/`xsi` namespace attributes fails ("Remove XML headers from property list"). Managed App Configuration is NOT a transport for a vendor's XML profile schema — a full profile, if supported at all, goes in as a CDATA string *value under a key*. When authoring any iOS app-config content, produce valid plist key/value pairs, never a namespaced XML document.
- [2026-07-14] **Intune iOS/mobile VPN "Server address" is a HOSTNAME field, never a URL.** Adding a path/slash (e.g. `host.example.com/Group`) is sent to DNS as a whole string → NXDOMAIN → "Unable to contact/timeout". To select a non-default gateway group on iOS AnyConnect/ASA, select it on the ASA by client-certificate mapping (`crypto ca certificate map`→`tunnel-group-map`) — NOT a URL path, NOT a bare `UserGroup` app-config key (that's a Windows client-profile fragment iOS ignores), NOT the pasted AnyConnect profile. Cert-map is the robust MDM pattern; flag exact vendor CLI/keys as "verify with vendor docs".

## 2026-07-16 — Lockdown is not session isolation (shared multi-user devices)
When a solution involves a device **shared between people** (shift/frontline/kiosk), never present
restriction/lockdown policy or app-level sign-out as the fix for one user seeing another's data. A
single-user-enrolled device has **no per-user session boundary** at the OS level, so cached tokens and
data survive any app sign-out. Authoring rule: state the root cause plainly, then present the actual
**multi-user architecture** decision (on Apple: Shared iPad w/ Managed Apple IDs via ABM+ADE — OS-level
per-user data separation; vs Microsoft 365 Shared Device Mode — app-level global sign-out only, no OS
data separation), including the trade-offs and the fact that converting existing devices requires
re-enrollment. Always close with an explicit **user-A → user-B isolation test** with PASS/FAIL criteria
— the buyer needs proof, not policy.

## 2026-07-16 — Identity prerequisites can be the real blocker; treat them as a first-class workstream
If a solution depends on an identity the org does not yet control (e.g. Managed Apple IDs where staff
tied work email to personal Apple IDs), the reclamation/conflict-resolution campaign is a **gating
workstream**, not a footnote: it needs inventory, sponsorship, comms, a grace period, and it reaches
every personal device those staff own. Author it as its own section, flag the vendor-side flow
specifics as "verify against current documentation", and defer the *whether to mandate* decision to the
customer's HR/legal/identity owners — never make that call in the document.
