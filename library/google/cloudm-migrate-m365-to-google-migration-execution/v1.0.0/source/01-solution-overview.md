# Solution Overview

## What this solution is

This solution is the **execution playbook for migrating Microsoft 365 to Google Workspace using
CloudM Migrate** at enterprise scale. It covers the end-to-end procedure — standing up the CloudM
platform (hosted or self-hosted), building the M365 and Google connections, designing the migration
profile and user list, and running the scan / pre-stage / full / delta sequence with throttling and
validation — so that mail, files, and collaboration data move reliably with minimal user disruption.

CloudM Migrate is a **third-party migration engine**. This document treats it at the **procedural
playbook level**: architecture, prerequisites, connection/endpoint setup, profile and mapping design,
wave and pre-stage/delta sequencing, throttling, and validation. **Deep CloudM console internals,
exact screen labels, licensing tiers, and product support are deferred to CloudM's own
documentation** — where a step depends on a specific CloudM version or a preview behavior, it is
flagged **"verify for your version."** The Google Admin console / Cloud Identity side and the
Microsoft 365 / Entra side are authored at exact detail because they are stable, publicly documented
platforms.

## How it works

CloudM Migrate reads from a **source** (Microsoft 365 — Exchange Online mailboxes, OneDrive, and
SharePoint) and writes to a **destination** (Google Workspace — Gmail, Google Drive, Shared Drives)
over each vendor's APIs. The migration is driven by four moving parts:

1. **Platform** — the CloudM Migrate engine, either **hosted** (CloudM-run SaaS) or **self-hosted**
   (installed on your own Windows migration server[s], scaled out for throughput). The engine holds
   the migration configuration and executes the passes.
2. **Connections** — authenticated links to each ecosystem: a **Microsoft 365 / Entra app
   registration** (source read) and a **Google Workspace service account / OAuth** with
   domain-wide delegation (destination write). These are the security identities the engine acts as.
3. **Migration profile** — the reusable configuration object that says *what* to migrate (mail,
   calendar, contacts, Drive/OneDrive, SharePoint), *how* to map source users to destination users,
   filtering (date ranges, folder exclusions), and throttling limits.
4. **User list** — the CSV of source→destination mappings that scopes each run to a set of users
   (and, for files, sites/paths → Shared Drives).

The engine runs in **passes**: a **Scan** (read-only discovery of item counts and sizes), an
optional **Pre-stage** (bulk-copy the historical bulk of data ahead of cutover while users still
work in M365), a **Full** pass, and repeated **Delta** passes (copy only what changed since the last
pass) leading up to **cutover** (MX/mail-routing switch to Google). A final delta after cutover
sweeps any last items.

## Reference model — naming convention

Every artifact this solution creates is named with the convention **`<Purpose> – <Scope> – <Stage>`**
and that exact name is reused in later steps, testing, troubleshooting, and the scripts:

| Artifact | Example name | What it is |
|---|---|---|
| CloudM platform instance | `Migration Platform – Enterprise – Prod` | The hosted/self-hosted engine |
| M365 source connection | `Source Connection – M365 – Prod` | Entra app registration used as source |
| Google destination connection | `Destination Connection – Google – Prod` | GCP service account w/ DWD |
| Migration profile | `Migration Profile – Mail+Drive – Standard` | Reusable what/how config |
| Pilot wave | `Migration Wave – Pilot – Wave0` | First validated cohort (25–50 users) |
| Production wave | `Migration Wave – Finance – Wave3` | A departmental cohort |
| Pre-stage run | `Pre-stage Run – Finance – Wave3` | Bulk historical copy pre-cutover |
| Delta run | `Delta Run – Finance – Wave3` | Incremental changed-items copy |
| Validation report | `Validation Report – Finance – Wave3` | Post-migration item/permission check |

## Where CloudM Migrate fits vs. native and other tools

- **Native / Google-first:** Google's own **Data Migration Service** (mail only, small scale) and
  **GWMME / Google Workspace Migrate** handle certain M365→Google moves. CloudM Migrate is chosen for
  **breadth** (mail + Drive + SharePoint + collaboration in one engine), **scale** (parallelism,
  self-hosted throughput), and **operational tooling** (per-user reporting, retriable deltas).
- **Other third-party engines:** BitTitan MigrationWiz and Google Workspace Migrate solve overlapping
  problems; the engine choice is an architecture decision made before this playbook runs. This
  solution assumes CloudM Migrate has been selected.

## The wave approach

Migration is executed **wave by wave**, never fleet-wide in one shot. Each wave is a cohort of users
(typically aligned to a department or site) that flows through **pre-stage → delta → cutover →
post-cutover delta → validate**. The **pilot wave** (`Migration Wave – Pilot – Wave0`) proves the
profile and connections end-to-end before any production wave runs.

## Benefits

- **Reliable, repeatable cutovers** — pre-staging historical data moves the bulk of bytes off the
  cutover critical path; deltas keep the final switch small and fast.
- **Minimal disruption** — users keep working in M365 until their wave cuts over; only the small
  final delta happens during the change window.
- **Auditable** — every wave produces a validation report (item counts, permissions, mail-flow) with
  explicit pass/fail gates.
- **Scoped risk** — pilot-first with documented rollback; a bad wave is contained to its cohort.

## Limitations & boundaries

- **Fidelity is engine- and API-bound.** Some item types migrate with reduced fidelity (e.g. certain
  Exchange rules, SharePoint web parts, complex OneNote); confirm the current fidelity matrix in
  CloudM's documentation for your version.
- **This is not a CloudM console manual.** Screen-by-screen console navigation, licensing, and
  entitlement are CloudM's to document; **verify for your version**.
- **Throttling is provider-imposed.** Microsoft Graph / Exchange and Google API quotas cap
  throughput; this solution gives sequencing and throttling *guidance*, not guaranteed rates.
- **Coexistence (free/busy, mail routing during migration)** is adjacent and may need its own design;
  this solution focuses on data movement and cutover.

## Deployment model

This solution follows the house model: **Assess → Design → Configure → Pilot → Validate → Expand**,
pilot-first, with explicit pass/fail gates and a documented rollback for every high-impact production
change (mail flow, DNS/MX, sharing, cutover). No production wave proceeds until the pilot wave passes
its validation gate.
