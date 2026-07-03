# Executive Summary — Exchange Online Tenant-to-Tenant Migration (Government / GCC High)

## The situation

Your organization needs to consolidate Exchange Online mailboxes and a primary email domain from one Microsoft 365 tenant into another **within the US sovereign cloud (GCC High)** — a 1:1-domain move. GCC High is **not** the Commercial service with a different sign-in: it uses different admin portals, different service endpoints, a different licensing channel, and — critically — **different migration support**. Runbooks copied from the Commercial cloud can connect to the wrong cloud or fail silently.

## The one decision that shapes the whole project

**Native (Microsoft-built) cross-tenant mailbox migration cannot cross cloud boundaries.** Microsoft states: *"Cross cloud tenant to tenant migration isn't supported."*

- **Commercial ↔ GCC High** — native migration is **not available**; you must use a **third-party migration tool** (Quest, BitTitan, CloudM, Cloudiway, etc.) or **PST** for the mail data.
- **GCC High → GCC High** (same cloud) — native migration exists but reaches government clouds via **Public Preview**; confirm eligibility with Microsoft before relying on it. A third-party tool is a fully supported alternative.

This solution is authored **tool-agnostic**: it prepares both tenants correctly so whichever engine you use will succeed.

## What this solution provides

A tested, novice-admin-friendly, click-to-implement runbook — plus **five PowerShell scripts** — that:

- Uses the correct **`*.us` GCC High portals and endpoints** throughout (`portal.office365.us`, `admin.exchange.office365.us`, `graph.microsoft.us`, `outlook.office365.us`, `login.microsoftonline.us`).
- Calls out every **Commercial-vs-GCC-High difference** at the step where it matters, with a fully **cited** parity reference.
- Follows a gated **Assess → Configure → Pilot → Validate → Expand** method, so nothing scales until a small pilot is proven.
- Ships **read-only** discovery/validation/reporting scripts and **safe (`-WhatIf`-by-default)** remediation and targeting scripts, all connecting to **US Gov** endpoints.

## Business outcome

The migration is executed **correctly for the sovereign cloud** — right portals, right endpoints, licensing sequence respected, cross-cloud constraint handled up front — and **proven on a pilot before you scale**, protecting mail continuity for a government/DIB organization where a botched cutover is not an option.

## Effort and prerequisites

Self-guided, at a fraction of typical consulting cost. Requires: both tenants in GCC High, appropriate US Gov licensing (G3/G5 GCC High) plus the Cross-Tenant User Data Migration add-on for a native move, Global Administrator / Organization Administrator / Move Mailboxes roles, DNS control for the migrating domain, and reachable `*.us` endpoints. Full detail in the Requirements Guide.

> All GCC High specifics are cited to Microsoft US Government documentation or explicitly flagged "verify for GCC High." Nothing is invented.
