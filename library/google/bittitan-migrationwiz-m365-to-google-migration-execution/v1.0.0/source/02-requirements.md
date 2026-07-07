# 2. Requirements Guide — BitTitan MigrationWiz: M365 → Google Migration Execution

Verify every requirement before running the migration. Each entry gives **Description**, **Why
required**, **How to verify**, and **How to implement if missing**. Category-wide prerequisites — the
Google Workspace target tenant and super-admin, the source M365 / Entra environment, DNS control, the
identity source of truth, a pilot scope, and governance stakeholders — are in
`global-requirements-google.md`; do not repeat them here. This guide adds what a **MigrationWiz**
execution specifically needs. **MigrationWiz account setup, licensing, and console configuration are
deferred to BitTitan's own documentation** ("verify for your version"); this guide states what must
be true for the tool to run, not how to click through its console.

## 2.1 A MigrationWiz account with the required licensing
Description: An active **BitTitan / MigrationWiz (MSPComplete)** account for the migration, with
migration **licensing** sufficient for the in-scope users and data types — for example a **User
Migration Bundle** per user (covering mailbox + document + collaboration for that user) or the
per-migration licenses the project types require. The exact license SKUs, quantities, and
entitlements are **BitTitan's to define — verify for your version**.
Why required: MigrationWiz will not run a paid pass without applied licenses; under-licensing stalls a
wave mid-cutover.
How to verify: Sign in to the MigrationWiz/MSPComplete workspace and confirm the account is active and
that license count ≥ the wave's user count for each data type in scope. Confirm which license type
each project (Mailbox / Document / Teams-to-Chat) consumes per BitTitan's documentation.
How to implement if missing: Purchase/apply the appropriate MigrationWiz licenses through BitTitan or
an authorized reseller before scheduling the pilot. (Licensing detail deferred to BitTitan.)

## 2.2 Source M365 / Entra access and a source app registration
Description: Administrative access to the source **Microsoft 365** tenant and **Microsoft Entra ID**
sufficient to (a) create/authorize the **app registration** MigrationWiz uses for the source endpoint,
and (b) grant the mailbox/OneDrive/SharePoint/Teams access the chosen project types require. For
mail, this is typically an app registration with the Graph/Exchange application permissions
MigrationWiz's documentation specifies (application access to mailboxes), consented tenant-wide.
Why required: The source endpoint reads each mailbox, drive, and collaboration space from M365;
without an authorized source identity every line item fails to authenticate.
How to verify: Confirm Global Administrator (or the least-privilege roles BitTitan names) in the Entra
admin center; confirm you can register an app and grant admin consent. Run
`btw-readiness-assessment.py` against the source to confirm you can read the estate over Microsoft
Graph.
How to implement if missing: Obtain the Entra role, create the source app registration and grant the
application permissions/admin consent MigrationWiz's source-endpoint documentation lists (deferred —
verify for your version), and record the app (client) ID in the endpoint design.

## 2.3 Google Workspace target: super-admin, service account, and domain-wide delegation
Description: A provisioned **Google Workspace** target with a **super admin**, target accounts
provisioned for the wave (per the identity source of truth in the global requirements), and a
**Google Cloud service account** (or OAuth app) with **domain-wide delegation** authorized in the
Admin console for the API scopes MigrationWiz's target endpoint requires (Gmail / Drive / Calendar /
Directory as applicable). The automation tools in this solution also use a service account or ADC with
**read-only** Admin SDK / Directory / Reports scopes.
Why required: The target endpoint writes mail/Drive/Chat into licensed Google accounts using the
delegated service identity; a mailbox cannot migrate into an account that does not exist or without
delegated API access.
How to verify: In **admin.google.com → Security → API controls → Domain-wide delegation**, confirm the
service account's **client ID** is authorized for the required scopes; confirm Gmail/Drive licenses
for a sample wave; confirm the target accounts are provisioned.
How to implement if missing: Provision licenses and target accounts (GCDS/SCIM per the global
requirements), create the service account in Google Cloud, and authorize its client ID for the exact
scopes MigrationWiz's target-endpoint documentation specifies (deferred — verify for your version)
before scheduling the pilot.

## 2.4 An endpoint design — source and target, proven
Description: A decision record — the endpoint design — fixing the **M365 source endpoint**
(`BTW Endpoint – M365 Source – Prod`) and the **Google Workspace target endpoint**
(`BTW Endpoint – Google Target – Prod`): connection type, the app-registration / service-account
identity each uses, and the scopes/permissions consented. Each endpoint is **proven** by migrating one
test line item end to end before any bulk pass.
Why required: Endpoints are reused by every project and wave; a misconfigured endpoint fails every line
item. Deciding and proving them once prevents authorization failures discovered at scale.
How to verify: The design names both endpoints, their identities, and their scopes; one test user
migrates a small set of items source→target without an authorization error.
How to implement if missing: Create both endpoints in MigrationWiz (console flow deferred to BitTitan),
record their identities/scopes in the design, and prove one test line item before the pilot wave.

## 2.5 A project design — data types, mappings, and the DMA decision
Description: A project design fixing the **projects** to run — `BTW Project – Mailbox – Prod`,
`BTW Project – Documents – Prod`, `BTW Project – Teams to Chat – Prod` — the **data types** each moves
and in what order, the **mappings** each needs (SharePoint site → Shared Drive, Team → Chat space,
resource/room calendars, address rewriting), and an explicit **Device Management Agent (DMA)
decision**: whether any in-scope project path requires the DMA and, if so, where it is deployed.
(**Verify for your version** which project types need the DMA; cloud-to-cloud mail typically does not.)
Why required: Every wave must run the *same* projects, data-type order, and mappings; deciding per wave
guarantees rework and inconsistent outcomes. An unplanned DMA requirement discovered mid-wave stalls
document migration.
How to verify: The design names each project, its data types and order, the required mappings, and the
DMA decision, and is agreed by the migration's technical owners. `btw-project-mapping-builder.py`
produces the line-item CSV each project consumes.
How to implement if missing: Hold Implementation Step 2 and freeze the project design before the pilot;
generate the mapping CSVs with the builder tool.

## 2.6 A pre-stage / delta and throttling plan
Description: A pass plan fixing, per project: the **Pre-Stage Migration** (bulk-move historical data
ahead of cutover, bounded by an age filter such as "older than N days"), the **Delta/Full pass** at
cutover, and a **throttling** profile (`BTW Throttle – Project Concurrency – Per Wave`) that keeps
concurrency within source (M365/Graph) and target (Google API) limits so passes neither crawl nor trip
protective limits. Provider-side throttling behavior and MigrationWiz's own concurrency controls are
**verify-for-your-version**.
Why required: Without a pre-stage, the full corpus is attempted in the cutover window and the cutover
overruns; without deliberate throttling, passes stall on provider limits. The delta pass is what lets
a re-run move only what changed since pre-stage without re-moving migrated items.
How to verify: The plan states the pre-stage age filter, the delta timing, and the concurrency/
throttle settings; `btw-wave-planner.py` produces the wave/pass schedule and throttling guidance.
How to implement if missing: Author the pass plan in Implementation Step 4; run a pre-stage on the
pilot wave and confirm only a small delta remains at cutover.

## 2.7 A pilot wave, per-user validation, and a DNS/MX cutover runbook with rollback
Description: A named pilot wave — `BTW Wave – Pilot – Wave 0` — of a small, representative user set
(core IT and early adopters, plus at least one shared mailbox, one SharePoint site, and one Team so
those paths are exercised); a per-user validation record `BTW Validation – Mail/Docs/Chat – Per User`
confirming **every** in-scope data type landed; and a repeatable **DNS/MX cutover runbook**
(`BTW Cutover – DNS/MX – Per Wave`) applied under **change control** with a documented, tested
back-out.
Why required: The full migration and cutover must be proven on a pilot before any production wave; each
migrated user must be validated across all data types, not declared done on mail alone; and a DNS/MX
change is high-impact and must be reversible.
How to verify: The pilot wave and validation record exist and cover every data type; the runbook has
all stages and a rollback; the change-control path and lowered MX TTL are in place. Build the wave with
`btw-project-mapping-builder.py` and validate with `btw-postmigration-validation.py`.
How to implement if missing: Define the pilot wave, author the cutover runbook (Step 5), run it end to
end (Step 6), and validate per user before expanding.

---
## Checklist
- [ ] MigrationWiz account active + licensing ≥ wave (verify for your version) — §2.1
- [ ] Source M365/Entra access + source app registration consented — §2.2 · `btw-readiness-assessment.py`
- [ ] Google target super-admin + service account with domain-wide delegation — §2.3 · `btw-config-helper.py`
- [ ] Endpoint design proven (source + target, one test line item) — `BTW Endpoint – M365 Source – Prod` / `BTW Endpoint – Google Target – Prod`
- [ ] Project design frozen (data types, mappings, DMA decision) — `btw-project-mapping-builder.py`
- [ ] Pre-stage/delta + throttling plan — `btw-wave-planner.py`
- [ ] Pilot wave + per-user validation + DNS/MX cutover runbook w/ rollback — `btw-postmigration-validation.py`
