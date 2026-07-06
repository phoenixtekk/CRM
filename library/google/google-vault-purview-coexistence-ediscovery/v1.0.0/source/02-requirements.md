# 2. Requirements Guide — Vault ↔ Purview Coexistence: eDiscovery, Legal Hold & Retention

Verify **every** requirement before configuring. Each entry: **Description · Why · Verify ·
Implement-if-missing.** Category-wide prerequisites are in `global-requirements-google.md`.

> **Vendor boundary.** Google Vault and Google Admin console paths, and the Microsoft **Purview
> portal** paths, are authored from each vendor's current public documentation. Vault's **Gemini-app**
> hold/retention support and the evolving Purview eDiscovery experience are flagged **"verify in your
> tenant."** Retention *periods* and hold *triggers* are **legal/records-counsel determinations** —
> this guide covers the technical prerequisites, not the legal ones.

## 2.1 Vault-capable Google Workspace edition + Vault privileges
**Description:** A Google Workspace edition that includes **Google Vault**, with an admin account holding **Vault privileges** (Manage Matters, Manage Holds, Manage Searches/Exports, Manage Retention as needed).
**Why:** All Google-side retention, holds, search, and export are performed in Vault; without a Vault-capable edition and Vault privileges there is no Google-side governance surface.
**Verify:** Sign in to `vault.google.com` — if Vault loads and **Matters** / **Retention** are visible, the edition and privileges are present. In the Admin console, confirm Vault is on for the relevant OUs (**Apps → Google Workspace → Vault**) and privileges under **Account → Admin roles** (Vault privileges) / **Security → Access and data controls → Vault**.
**Implement:** Acquire a Vault-capable Workspace edition through Google or an authorized reseller; turn Vault on for the relevant OUs and assign an admin role with the required Vault privileges (reserve super-admin for tenant-wide changes).

## 2.2 Microsoft Purview eDiscovery access + eligible licensing
**Description:** Access to the **Microsoft Purview portal** (`purview.microsoft.com`) with **eDiscovery** permissions, and — critically — an **eligible license on every user whose content will be held**.
**Why:** The Microsoft-side estate (Exchange, SharePoint, OneDrive, Teams) is held and discovered in Purview. eDiscovery holds require an eligible license on each **held** user; frontline tiers (Office 365 F1/F3) **cannot be the target** of an eDiscovery hold, and query-based / custodian-scoped holds require higher tiers (M365 E5/A5/G5 or the E5 Compliance / E5 eDiscovery & Audit add-ons). (Source: Microsoft Learn.)
**Verify:** Sign in to `purview.microsoft.com`; the **eDiscovery** solution card and **Cases** are available. Confirm each in-scope custodian's assigned subscription includes eDiscovery-hold rights.
**Implement:** Assign eDiscovery permissions/roles; **before** placing a user on hold, assign the required subscription/add-on to any custodian whose tier lacks hold rights (placing an unlicensed user on hold is not supported).

## 2.3 Estate inventory — what's governed where
**Description:** A documented map of which custodians and record classes live in **Vault** (Workspace), in **Purview** (M365), or — during migration — in **both**.
**Why:** Every hold and search works from this coverage map; a custodian with data on both sides must be held on both. Without the inventory, coexistence gaps are invisible.
**Verify:** Run `GWVAULT-Discovery.ps1` (enumerates Vault matters/holds/retention and flags Purview-side coverage to confirm) and review `GWVAULT-Report.ps1`. Cross-check Vault **Matters/Retention** and Purview **Cases/Hold policies**.
**Implement:** Complete the inventory in Implementation Step 1 before configuring holds.

## 2.4 Retention policy (records schedule) — legally approved
**Description:** An organization **retention/records schedule** — approved by legal/records counsel — defining how long each record class must be kept (and when it may be deleted).
**Why:** Vault retention rules and Purview retention policies must both be configured to this schedule; where a class exists on both sides, both are aligned to the **longer** of the two so nothing is purged out from under a hold. The *periods themselves* are a legal determination, not a technical default.
**Verify:** A written, counsel-approved retention schedule exists and names the record classes in scope on each platform.
**Implement:** Obtain the approved schedule from legal/records before configuring any retention rule; do not invent retention periods.

## 2.5 Matter / case naming convention (identical across both)
**Description:** A naming convention so a legal matter is named **identically** in Vault (a **matter**) and Purview (an eDiscovery **case**), in the form `<Purpose> – <Scope> – <Stage>` — e.g. `Litigation – Acme v. Example – Hold`.
**Why:** Parallel holds are only defensible if a custodian's Vault matter and Purview case are unmistakably the same legal matter; matched names make coverage auditable and reconciliation reliable.
**Verify:** The convention is agreed with legal/eDiscovery; matched names are reserved. Or run `GWVAULT-Set-ScopeTargeting.ps1` (default `-WhatIf`) to preview a matched matter scope.
**Implement:** Agree the convention with legal; reserve the matched matter/case names before creating holds (Implementation Step 2).

## 2.6 Legal / eDiscovery stakeholders + change control
**Description:** Engagement with **legal, records management, and eDiscovery** stakeholders (the hold owners and approvers), and a documented change/rollback process for hold, retention, and discovery changes.
**Why:** Holds, retention periods, and discovery scope are legal decisions with legal consequences (spoliation risk if under-preserved; cost/over-collection risk if over-preserved). Legal owns the *what*; this solution operationalizes the *how*. A pilot gate and rollback are mandatory (global requirement 6).
**Verify:** Named legal/eDiscovery owners and approvers are confirmed; a change ticket exists with an approver, a window, and a rollback step (e.g. release a hold, revert a retention rule).
**Implement:** Identify the legal/eDiscovery owners and obtain the hold list and retention schedule; record the change and rollback before touching production.

## 2.7 Pilot custodian scope
**Description:** A small **pilot scope of custodians** (an OU/group on the Google side and the matching users on the Microsoft side) to validate the whole hold → retention → discovery loop before extending to all custodians.
**Why:** The coexistence loop (parallel holds effective, retention applied, discovery returns on both) must be proven small before the full population depends on it (pilot gate + rollback).
**Verify:** A named pilot custodian scope exists on both platforms. Or run `GWVAULT-Set-ScopeTargeting.ps1` to preview/create the Google-side scope group.
**Implement:** Create the pilot scope group with `GWVAULT-Set-ScopeTargeting.ps1` (or Admin console → **Directory → Groups**), and identify the matching Purview custodians.

## 2.8 Search/export readiness (both platforms)
**Description:** The ability to run and **export** searches on both sides — Vault **search + export** (by matter) and Purview **search + export** (by case) — and a place to reconcile the two export sets.
**Why:** Defensible discovery collects from both ecosystems and reconciles into one production; if either side cannot export, the coexistence discovery is incomplete.
**Verify:** In Vault, a matter can run a search and export; in Purview, a case search can export. Confirm the operator holds the export privileges on both.
**Implement:** Grant Vault search/export privileges and Purview eDiscovery export roles; define where reconciled productions are assembled and stored under counsel's direction.

---
## Checklist
- [ ] Vault-capable Workspace edition + Vault privileges (Matters/Holds/Retention/Search-Export)
- [ ] Purview portal eDiscovery access **and eligible license on every held custodian**
- [ ] Estate inventory — what's governed where (`GWVAULT-Discovery.ps1` / `GWVAULT-Report.ps1`)
- [ ] Counsel-approved retention/records schedule (periods are a legal determination)
- [ ] Matched matter/case naming convention reserved on both platforms
- [ ] Legal/eDiscovery stakeholders named; change control / rollback documented
- [ ] Pilot custodian scope created on both platforms
- [ ] Search/export readiness confirmed on Vault and Purview
