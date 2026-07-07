# 3. Implementation Guide — BitTitan MigrationWiz: M365 → Google Migration Execution

Follow these steps in order. This guide executes an **M365 → Google Workspace migration on BitTitan
MigrationWiz** — proving the endpoints, projects, pre-stage/delta passes, throttling, and DNS/MX
cutover on a **named pilot wave**, validating each user across mail, documents, and chat, then
expanding **wave by wave**. Artifact names are fixed — create them with the exact names shown and
reuse them every wave. **MigrationWiz console internals** (the exact screens for creating endpoints,
projects, passes, and the DMA installer, plus licensing) are **deferred to BitTitan's documentation**;
this guide governs the repeatable procedure and sequencing around them and flags version-dependent
behavior **"verify for your version."**

> Model: baseline and design once, prove the full migration and cutover on a pilot wave, validate
> mail/docs/chat per user against the gate, then cut over DNS/MX and expand. The repeatable way:
> **Assess → Design → Configure → Pilot → Validate → Expand.**

## Step 1 — Assess: baseline the source and target
1. Run `btw-readiness-assessment.py` to baseline both sides read-only: the **M365 source** (users,
   licensed mailboxes, shared mailboxes, resource/room mailboxes, OneDrive/SharePoint sites, Teams —
   read over Microsoft Graph) and the **Google target** (users provisioned, licenses, and whether the
   service account's domain-wide delegation is present — read over the Admin SDK). Record it as
   `BTW Discovery – Source & Target – Baseline`.
2. Add the details the APIs cannot read: per-mailbox and per-site **data volumes**, SharePoint site →
   Shared Drive intentions, Team → Chat-space intentions, resource-calendar mappings, and any
   mail-touching integrations (relay connectors, forwarding, shared-mailbox delegation) that affect
   the migration or routing.
3. Record gaps against the Requirements checklist. **Do not proceed** past missing source app
   registration, missing target delegation, under-licensing, or a missing identity source of truth —
   resolve those first.

## Step 2 — Design: fix the endpoints and projects
1. **Endpoint design.** Fix the two reusable endpoints and the identity each uses:
   - `BTW Endpoint – M365 Source – Prod` — the source connection using the Entra **app registration**
     from §2.2 (client ID + the application permissions/admin consent MigrationWiz's source-endpoint
     docs specify; **verify for your version**).
   - `BTW Endpoint – Google Target – Prod` — the target connection using the Google **service account**
     with domain-wide delegation from §2.3 (the scopes MigrationWiz's target-endpoint docs specify;
     **verify for your version**).
2. **Project design.** Fix which projects run, their data-type order, and mappings:
   - `BTW Project – Mailbox – Prod` — mail, calendar, contacts (Exchange Online → Gmail/Calendar/
     Contacts).
   - `BTW Project – Documents – Prod` — OneDrive → user Drive, SharePoint sites → **Shared Drives**
     (record each site→drive mapping).
   - `BTW Project – Teams to Chat – Prod` — Teams → Google Chat/Spaces (record each Team→space mapping;
     **verify for your version** which collaboration data types are in scope).
3. **DMA decision.** Decide explicitly whether any in-scope project path requires the **Device
   Management Agent**. Cloud-to-cloud mail typically does not; some document/desktop-source paths do —
   **verify for your version and project type**. If required, record where the DMA is deployed; if not,
   record "no DMA required" so no one deploys it speculatively.
4. Generate the line-item **mapping CSVs** each project consumes with `btw-project-mapping-builder.py`
   (reads the source directory + target directory, emits `BTW Mapping – User Pairs – Per Project` with
   validated source→target address pairs). **Freeze** the design before the pilot; every wave runs it
   unchanged.

## Step 3 — Configure: build and prove the endpoints, then the projects
1. Create both endpoints in MigrationWiz per the design (console flow deferred to BitTitan). Run
   `btw-config-helper.py --check-delegation` to confirm the Google service account's client ID is
   authorized for the required scopes and the source app registration is reachable, before proceeding.
2. **Prove the endpoints** on **one test line item**: migrate a small set of mail/docs for a single
   test user source→target and confirm no authorization error. Endpoints are a prerequisite, not a
   pilot step.
3. Create the three projects, attaching the source and target endpoints and importing the pilot wave's
   mapping CSV as line items. Set the project options (data-type filters, address mapping, folder/label
   mapping) per the design; **exact option behavior is verify-for-your-version.**

## Step 4 — Configure: author the pre-stage / delta and throttling plan
1. Author the pass plan per project with `btw-wave-planner.py`:
   - **Pre-Stage pass** `BTW Pass – Pre-Stage – Per Wave` — a bulk pre-stage migration bounded by an
     **age filter** (e.g. "items older than N days") run well ahead of cutover, so only a small delta
     remains at the switch.
   - **Delta/cutover pass** `BTW Pass – Delta Cutover – Per Wave` — the pass at cutover that moves only
     what changed since pre-stage, without re-moving migrated items.
   - **Throttling** `BTW Throttle – Project Concurrency – Per Wave` — the concurrency/ item-per-hour
     settings that keep passes within source (M365/Graph) and target (Google API) limits. The planner
     emits throttling **guidance**; the exact MigrationWiz concurrency controls and provider limits are
     **verify-for-your-version.**
2. Fix the pre-stage age filter, the delta timing relative to the DNS/MX cutover, and the concurrency
   ceiling. This plan is applied unchanged every wave.

## Step 5 — Author the DNS/MX cutover runbook and rollback
1. Author `BTW Cutover – DNS/MX – Per Wave` with the fixed sequence:
   1. **Readiness** — the wave's target accounts are provisioned and licensed, both endpoints prove
      one test line item, `btw-config-helper.py` reports delegation/consent healthy, and
      `btw-config-helper.py --check-throttle` shows no active provider throttling.
   2. **Pre-stage** — run `BTW Pass – Pre-Stage – Per Wave` for each project ahead of cutover.
   3. **Coexistence routing** — apply **split/dual delivery** (MX at Google, Gmail routes not-yet-
      migrated users onward to Exchange Online) under change control, with the MX TTL already lowered.
   4. **Delta cutover** — run `BTW Pass – Delta Cutover – Per Wave` to finalize recent mail/docs/chat.
   5. **Validate** — run `btw-postmigration-validation.py` per user (mail **and** documents **and**
      chat) and confirm the wave passes the gate.
   6. **DNS/MX cutover** — apply the staged MX/DNS change for the wave with a documented back-out.
   7. **Rollback** — revert routing/DNS to the prior platform and re-point the wave; used only if the
      gate fails.
2. Define the go/no-go: the wave passes only when readiness held, the pre-stage completed, all data
   types validated per user, the delta pass is clean, and the DNS/MX change is applied and reversible.

## Step 6 — Pilot: run Wave 0 end to end
1. Assemble `BTW Wave – Pilot – Wave 0`: a small, representative set (core IT and early adopters) that
   **includes at least one shared mailbox, one SharePoint site, and one Team** so those paths are
   exercised. Generate its mapping CSV with `btw-project-mapping-builder.py`.
2. Execute the full runbook on the pilot wave: readiness → pre-stage → coexistence routing → delta
   cutover → validate → DNS/MX cutover.
3. Run `btw-postmigration-validation.py` per user for coverage/exceptions. The pilot passes **only**
   when the whole runbook ran end to end and every user validated across every in-scope data type.

## Step 7 — Validate: fix the runbook, not just the wave
1. Complete the Testing Guide for the pilot. Treat every issue as a **runbook/design** defect: fix the
   endpoint identity/scopes, the project mappings, the pre-stage age filter, or the throttling profile
   so later waves inherit the fix.
2. Re-run the affected pass and validation. Where line items failed on transient errors, use
   MigrationWiz's per-item **retry** (verify for your version) and re-validate; regenerate the mapping
   CSV with `btw-project-mapping-builder.py` if source→target pairs changed.

## Step 8 — Expand wave by wave
1. For each subsequent wave `BTW Wave – <Segment> – Per Wave`, re-run the same runbook: generate the
   wave's mapping CSV, pre-stage, apply coexistence routing, delta-cutover, validate per user
   (`btw-postmigration-validation.py`), and cut over DNS/MX — passing the go/no-go before the next
   wave. Check provider throttling with `btw-config-helper.py --check-throttle` before each pre-stage.
2. Keep the coexistence routing rule current as the migrated population grows so every user's mail
   always reaches their current platform; a stale rule silently mis-delivers.

## Step 9 — Decommission coexistence
1. After the **final** wave validates and cuts over, retire the split/dual-delivery routing and the
   onward route to Exchange Online, and finalize the MX so all mail is delivered in Gmail — never
   mid-migration. Confirm no forwarding loop or stale route remains, then release the MigrationWiz
   projects/endpoints per BitTitan's guidance.

---
### Order of operations
`Assess/baseline -> Design (endpoints+projects+DMA) -> Configure/prove endpoints+projects -> Pre-stage/delta+throttle plan -> Cutover runbook+rollback -> Wave 0 pilot -> Validate/fix runbook -> Expand wave by wave -> Decommission coexistence`
