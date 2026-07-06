# 1. Solution Overview — SharePoint Online & OneDrive → Google Drive / Shared Drives Migration

## What this solution is
This solution migrates **SharePoint Online (SPO) and OneDrive for Business** content to **Google
Drive and Shared Drives** — with the content, folder structure, **permissions, and sharing**
mapped deliberately rather than dumped file-for-file. The hard part of a Drive migration is never
the bytes; it is that a SharePoint site and a OneDrive do **not** map one-to-one onto Google Drive,
and that permissions and sharing are where these migrations quietly go wrong. This solution supplies
the **mapping model** (what becomes a Shared Drive, what becomes a folder, whose OneDrive becomes
whose My Drive), the **permission/sharing translation** (SharePoint permission levels → Google roles,
SharePoint sharing → Google sharing), the **tooling pattern** (tool-agnostic — the migration engine
is chosen and its internals deferred to the vendor), and the **per-item validation** that proves each
item landed in the right place with the right access. It is executed **pilot-first** and
**rollback-ready**.

## Why this matters
Drive migrations fail on access, not volume. A team's SharePoint site is copied into a personal My
Drive and now has one owner who can lock everyone out. Permission levels are flattened — a
SharePoint "Contribute" that should have become a Google **Contributor** lands as **Viewer**, and the
team can no longer edit. Sharing links break: an "anyone with the link" SharePoint share does not
carry across, or worse, carries across too broadly. Identities are not mapped, so permissions granted
to `jsmith@source` never resolve on the Google side and are silently dropped — the file arrives with
no access at all ([CloudM — Drive permission changes](https://support.cloudm.io/hc/en-us/articles/25031144447644-Google-Drive-Permission-Changes-Microsoft-365-to-Google-Workspace)).
And because nothing was validated per item, none of this is discovered until a user reports they
cannot open their own files — weeks after the tool declared success. This solution fixes the cause:
it decides the content and permission mapping **up front**, proves it on a **named pilot**, validates
files, permissions, and sharing **per item**, and only then migrates the rest **by wave** — each wave
validated before the next.

## The SPO/OneDrive → Drive/Shared Drives mapping model
The migration is driven by an explicit mapping. Author it once, name it, and reuse it for every wave.

| Source (Microsoft 365) | Target (Google) | Rationale |
|---|---|---|
| **SharePoint team site / document library** (team-owned content) | **Shared Drive** | Team content must be team-owned. A Shared Drive has no single personal owner, so access survives when a person leaves — the correct home for site/library content. |
| **SharePoint site with several libraries** | **One Shared Drive per library**, or one Shared Drive with a folder per library | Keeps Shared Drives within item/member limits and gives each library a clean access boundary. |
| **OneDrive for Business** (personal content) | The same user's **My Drive** | Personal content stays personal, owned by the same identity. |
| **SharePoint folder** | **Folder inside the target Shared Drive** | Structure is preserved beneath the Shared Drive root. |
| **SharePoint permission level** | **Google Drive role** (see translation below) | Access intent is preserved, not flattened. |
| **SharePoint / OneDrive share** (direct grant or link) | **Google sharing** (member/permission or link) | Sharing intent is translated deliberately, not lost or over-broadened. |

The named mapping artifacts:

| Artifact | Name |
|---|---|
| Content + structure mapping | `GWDRIVE Mapping - Content & Structure - Source to Target` |
| Permission/role translation table | `GWDRIVE Mapping - Permissions - Level to Role` |
| Identity mapping table | `GWDRIVE Mapping - Identity - Source to Google` |
| Sharing translation rules | `GWDRIVE Mapping - Sharing - Link & Grant Rules` |
| Pilot scope | `GWDRIVE Pilot - Scope - Wave 0` |
| Per-wave migration + validation runbook | `GWDRIVE Runbook - Migrate & Validate - Per Wave` |

## Permission translation — SharePoint level → Google role
Google Shared Drives have five member access levels; the migration maps each source permission level
to the closest Google role so **access intent is preserved** rather than flattened
([Google — shared drive roles](https://developers.google.com/workspace/drive/api/guides/ref-roles)).

| SharePoint permission level (typical) | Google Drive role | What the role grants |
|---|---|---|
| Full Control / site owner | **Manager** (`organizer`) | Manage files, folders, members, and settings; delete; move out of the drive |
| Design / Edit (manage content) | **Content manager** (`fileOrganizer`) | Add, edit, move, and organize content; share items; cannot manage members |
| Contribute | **Contributor** (`writer`) | View, comment, edit, and create files; cannot manage members or settings |
| Read + comment | **Commenter** | View and comment only |
| Read | **Viewer** (`reader`) | View only |

Exact source permission-level names vary per SharePoint tenant; the translation table is authored
against the source tenant's **actual** levels, not assumed defaults, and reviewed with the content
owners before the pilot.

## Sharing translation
SharePoint sharing (direct grants and sharing links) is translated by rule into Google sharing:
- **Direct grants** to named users/groups → Google **permissions** on the item or membership on the
  Shared Drive, via the **identity mapping table** so each source principal resolves to a Google
  identity. **Any principal missing from the identity map is dropped** by the tool and its permission
  is lost — so the identity map must be complete before migrating
  ([CloudM — Drive permission changes](https://support.cloudm.io/hc/en-us/articles/25031144447644-Google-Drive-Permission-Changes-Microsoft-365-to-Google-Workspace)).
- **Organization sharing links** ("people in your organization") → Google **domain** sharing at the
  matching role.
- **Anyone-with-the-link** shares → translated **only where policy allows**; otherwise down-scoped to
  domain or named access and flagged for owner review, so a migration does not silently widen access.
- **Note on visibility:** as of early 2026, folders a user could not see in SharePoint may appear
  **greyed out** (visible but inaccessible) in Google Drive — visibility changed, not access — so
  users are told to expect this and restricted content is best placed in separate top-level folders
  before migrating.

## The deployment model
> Define the content, permission, identity, and sharing mapping and confirm access; prove the whole
> mapping on a **named pilot**; validate files, permissions, and sharing **per item**; then migrate
> **by wave** and validate each wave before the next — the repeatable way: Assess, then Configure,
> then Pilot, then Validate, then Expand.

## What this is not
This solution governs the **mapping, translation, and per-item validation** of an SPO/OneDrive →
Drive migration. It does **not** re-document the internal console steps of any specific migration
engine — the tool is chosen in the design and its mechanics are deferred to the vendor's own docs
(tool-agnostic). Where the included scripts read the source, they read **SharePoint Online and
OneDrive through Microsoft Graph, read-only**; they move no content and change no permissions (the
one write script and the scope-targeting script default to `-WhatIf`).
