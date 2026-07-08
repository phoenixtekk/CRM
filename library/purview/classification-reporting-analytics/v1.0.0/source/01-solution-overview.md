# 1. Solution Overview — Classification Reporting & Analytics (Microsoft Purview)

## What this solution is
This solution stands up **classification reporting and analytics** in **Microsoft Purview** using the
two native explorers: **Content Explorer** (where classified content lives right now) and **Activity
Explorer** (what has happened to labeled/sensitive content over time). The outcome is a defensible,
repeatable answer to the questions leadership keeps asking: *"What is classified, where is it, and how
much of our estate is covered?"* and *"What are people doing with our sensitive and labeled content?"*

It covers the whole path: confirming the **licensing and least-privilege roles** that gate the
explorers, **enabling** the reporting surfaces (audit ingestion + the Content Explorer viewer role
groups scoped to a named reporting group), **piloting** the reporting on a limited scope, **validating**
that both explorers return data, and **operating** it with repeatable PowerShell exports and dashboards.
It is written for an administrator with no prior Purview-reporting experience.

It is **read-and-report by design.** This solution does **not** decide your classification scheme,
create sensitivity/retention labels, or author DLP policy — those are separate Purview solutions and,
where they carry regulatory or records weight, their **determinations are deferred to compliance,
records, privacy, and legal**. Here you make the *existing* classification signal **visible, measurable,
and dashboard-ready**.

## Content Explorer vs Activity Explorer in one paragraph each
- **Content Explorer** is a **current-state snapshot** of your estate. It shows, per location (Exchange
  mailboxes, SharePoint sites, OneDrive accounts, and — where supported — Teams), the items where
  Purview has detected a **sensitive information type (SIT)**, a **sensitivity label**, a **retention
  label**, or a **trainable classifier**. You drill from an aggregate count down to the individual file
  or message. It answers **"what is classified and where, right now."**
- **Activity Explorer** is a **time-series of activity** (a rolling window, typically up to ~30 days —
  **verify your tenant**). It shows events on labeled/sensitive content: **label applied, changed,
  downgraded, or removed**; **DLP rule matches**; **files copied to removable media / network share /
  cloud**; and more, filterable by location, user, label, and activity type. It answers **"what is
  happening to our classified content over time."**

Together they give the **coverage** view (Content Explorer) and the **behavior/trend** view (Activity
Explorer) that a classification program needs to prove it is working.

## How the reporting signal is produced
- **Content Explorer** is populated by Purview's classification engine as it scans and labels content —
  you don't feed it; you **grant sight of it** (the viewer role groups) and **read** it. In PowerShell
  the same data is exportable with **`Export-ContentExplorerData`** (Security & Compliance PowerShell),
  which returns items by tag type (SIT / Label / RetentionLabel / TrainableClassifier) — used here for
  repeatable coverage exports. *(Availability is licensing-gated — verify your tenant.)*
- **Activity Explorer** is populated from the **unified audit pipeline**. The portal surface is Activity
  Explorer; the same activity is queryable in PowerShell with **`Search-UnifiedAuditLog`** filtered to
  the sensitivity-label, DLP, and endpoint record types — used here for repeatable activity exports and
  trend dashboards. **Audit ingestion must be enabled** for either surface to be complete.

## What this delivers
- **Coverage reporting** — counts and locations of content carrying each **sensitivity label**,
  **retention label**, **sensitive information type**, and **trainable classifier**, exportable to CSV
  and chartable — the "how much of the estate is classified, and where" answer.
- **Activity reporting** — label lifecycle (apply/change/downgrade/remove), DLP matches, and egress
  activities over a rolling window — the "what are people doing with it" answer.
- **Dashboards** — the exports feed a repeatable dashboard (Excel/Power BI at the buyer's choice) so the
  numbers are shown, not just queried. *(Power BI/Fabric modeling is referenced at the pattern level;
  its licensing and build are the buyer's — this solution delivers the data and the shape.)*
- **Operational hygiene** — least-privilege viewer roles scoped to a named analyst group, audit-lag and
  role-drift health checks, and a pilot-first rollout.

## What is authored exactly vs deferred / flagged
- **Exact navigation and cmdlets** are given for the **Microsoft Purview portal**
  (`purview.microsoft.com`), the **classic compliance portal** (`compliance.microsoft.com`) where a
  surface still lives there, **Security & Compliance PowerShell** (`Connect-IPPSSession`), and where
  useful **Microsoft Graph**.
- **Licensing is plan-gated and flagged.** Content Explorer content viewing, Activity Explorer, and
  trainable classifiers generally require **Microsoft 365 E5 / E5 Compliance** — availability is
  **"verify your licensing/tenant"**, never assumed.
- **The portal is evolving.** Content Explorer and Activity Explorer are moving between the classic
  compliance portal and the new Purview portal, and card/menu names shift. Where a path is version-
  dependent this solution gives both known locations and flags **"verify against your current portal."**
- **Determinations are deferred.** What the classification scheme *should* be, what retention a record
  *must* have, whether an activity is a *policy violation* — those belong to compliance, records,
  privacy, and legal. This solution reports the signal and provides the evidence; it does not rule.

## The standard deployment model
> **Assess** licensing + roles + what is already classified → **Design** the reporting scope, the
> analyst role group, and the dashboard shape → **Configure** audit ingestion + the Content Explorer
> viewer role groups (scoped) → **Pilot** the reporting on a limited scope → **Validate** both explorers
> return data against pass/fail gates → **Expand** to the full analyst audience and scheduled exports.
> Pattern: **Assess → Design → Configure → Pilot → Validate → Expand**, with explicit pass/fail gates
> and a documented rollback. Role and audit changes are handled under change control and piloted before
> broad grant.
