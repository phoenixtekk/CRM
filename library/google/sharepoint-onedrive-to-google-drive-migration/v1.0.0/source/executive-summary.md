# Executive Summary — SharePoint Online & OneDrive → Google Drive / Shared Drives Migration

Moving files off SharePoint Online and OneDrive to Google Drive is not a copy job — it is a **mapping
job**, and permissions and sharing are where it goes wrong. A SharePoint site does not map one-to-one
onto Google Drive: team content dumped into a personal My Drive gets one owner who can lock everyone
out; permission levels flatten so a team that should still edit lands as view-only; sharing links
break or, worse, widen; and any identity that was not mapped has its access **silently dropped**, so
the file arrives with no permissions at all — none of it discovered until a user reports they cannot
open their own work. This solution removes those failure modes.

This is a complete, self-guided package written for a competent migration admin. It supplies the
**mapping model** (which sites/libraries become which Shared Drives, whose OneDrive becomes whose My
Drive), the **permission and sharing translation** (SharePoint levels → Google roles, SharePoint
sharing → Google sharing, via a complete identity map), the **tooling pattern** (tool-agnostic — the
engine is chosen in the design and its internals deferred to the vendor), and the **per-item
validation** that proves each file landed in the right place with the right access. It is executed
**pilot-first** and **rollback-ready**.

## What you get
- A **Solution Overview** of the SPO/OneDrive → Drive/Shared Drives mapping model — sites/libraries →
  Shared Drives, OneDrive → My Drive, the permission level → role translation, and the sharing
  translation rules.
- A **Requirements Guide** with verify / implement-if-missing for every prerequisite: source
  SPO/OneDrive access, a Google tenant with Shared Drives and storage, a chosen migration tool, a
  complete identity map, the mapping decisions, and a named pilot.
- An **Implementation Guide** of precise, ordered steps: discover the source, define the content /
  permission / identity / sharing mapping, prove it on a named pilot with per-item validation, fix the
  mapping (not just the item), then migrate wave by wave and validate each wave before the next.
- **Five PowerShell scripts** — source content/permission discovery, per-item migration + permission
  validation, a coverage/exception report, safe remediation, and a wave target-group builder — all
  read-only against Microsoft Graph except the two write scripts, which default to `-WhatIf`.
- **Testing and Troubleshooting** guides with explicit per-item gates (files migrated, permissions
  correct, sharing works), plus Best Practices for shared-drive structure — and a migration playbook
  outline the migration runs from.

The solution keeps the migration engine **tool-agnostic**: it owns the mapping, translation, and
validation, so a change of tool touches the engine, not the method.

## What this delivers
A governed, validated Drive migration: SharePoint Online and OneDrive content on Google Drive / Shared
Drives with **permissions and sharing intact**, mapped deliberately and validated per item, proven on
a pilot before any business unit's content moves.

## The deployment model
Assess, then Configure, then Pilot, then Validate, then Expand — with per-item validation of files,
permissions, and sharing before every wave passes, and source content set read-only only after
validation is clean.

## Outcome
Files and shares land on Google Drive / Shared Drives with the **right access** — team content in
Shared Drives, personal content in My Drive, roles preserved, sharing translated, and nothing silently
dropped or widened — proven on a pilot and validated wave by wave.
