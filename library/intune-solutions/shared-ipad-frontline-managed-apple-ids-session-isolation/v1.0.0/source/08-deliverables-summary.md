# 8. Deliverables Summary — Shared iPad for Frontline Teams

Everything included in this solution package, and what each piece is for.

## Documentation (this guide)

- **Executive Summary** — the business case in one page: the leak, the root cause, the A-vs-B decision,
  the Managed Apple ID blocker, and the outcome.
- **Solution Overview** — the root cause stated plainly (why a shared single-user iPad *cannot* isolate
  sessions), the two supported architectures with a side-by-side comparison and honest trade-offs, how
  this solution works, the Managed Apple ID reclamation workstream, benefits, limitations, the standard
  deployment model, and what the existing catalog already covers.
- **Requirements Guide** — 18 prerequisites, each with **Description · Why required · How to verify ·
  How to implement if missing**: Intune and Microsoft 365 licensing, Entra ID, Apple Business Manager,
  verified domains, **devices present in ABM** (the constraint that decides feasibility on an existing
  fleet), the Apple MDM push certificate, the ADE token, supervision, iPadOS version, **storage sizing
  for per-user data**, Managed Apple IDs, ABM↔Entra federation, **the personal Apple ID conflict as a
  gate**, admin roles on both sides, network, Wi-Fi at the handover points, and executive sponsorship.
  Plus the category-level **Global Requirements — Intune Solutions**.
- **Implementation Guide** — exact, ordered, click-by-click steps across five phases: assess and prepare
  identity (groups, the enrollment-time grouping owner, **the Apple ID conflict-resolution gate**,
  federation); configure the Apple connection (APNs, ADE token, **the enrollment profile with Shared
  iPad enabled** — the step that delivers isolation, device assignment); configure the device
  (field lockdown restrictions, compliance, the app allowlist with exact publisher/bundle IDs); pilot
  (wipe and re-enroll, validation gate); and expand (fleet eligibility, staged waves).
- **Testing & Validation** — nine tests with explicit PASS/FAIL gates, built around **the
  session-isolation A/B test**: eight discrete checks (mailbox, cached mail, chat, photos, autofill,
  signed-in state, files, browser state) run with two real users on one device, in both directions,
  plus a diagnostic table mapping each failure back to the architecture step that caused it. Includes
  the **shift-handover runbook** for the field team.
- **Troubleshooting** — symptom → cause → fix, led by the #1 failure ("the next user still sees the
  prior user's mail"), plus Managed Apple ID sign-in, ABM conflicts, federation loops, ADE enrollment,
  storage, app behaviour under Shared iPad, restrictions, and the scripts.
- **Best Practices** — architecture discipline, running the reclamation campaign without causing an
  incident, procurement and sizing, configuration choices, naming hygiene, and operations.

## PowerShell scripts (Microsoft Graph) — `SHAREDIPAD-Scripts.zip`

All scripts are tenant-side (run from an admin workstation with the Microsoft Graph PowerShell SDK).
Each header states **Purpose · How to run · Required Graph scopes · Expected results**.
**Four of the five make no changes of any kind. The fifth defaults to `-WhatIf`.**

1. **`SHAREDIPAD-Discovery.ps1`** *(read-only)* — readiness discovery: the ADE/ABM token and its expiry,
   the Apple MDM push certificate and its expiry, every ADE enrollment profile **and whether Shared iPad
   is enabled on it**, the iPad inventory (model, storage, iPadOS, supervised, ADE state, ownership),
   and which of this solution's named objects exist.
2. **`SHAREDIPAD-Validate.ps1`** *(read-only)* — PASS/FAIL scoring against the success criteria: ADE
   token valid, a **Shared-iPad-enabled** profile exists and is assigned, the device group is Assigned
   and owned by the Intune Provisioning Client, pilot devices supervised and ADE-enrolled, restrictions
   and compliance assigned, app allowlist assigned. Prints a clear PASS/FAIL summary — and says plainly
   that a PASS proves the *architecture*, not the isolation.
3. **`SHAREDIPAD-Report.ps1`** *(read-only)* — fleet report: per-device Shared iPad readiness with the
   blocking reason, assigned ADE profile, supervision, storage, compliance, and last check-in, with CSV
   export. Use it to size the project and track waves.
4. **`SHAREDIPAD-AppleIDConflict.ps1`** *(read-only)* — builds the **Entra-side candidate worklist** of
   users who need a Managed Apple ID and may therefore collide with a personal Apple ID, as a CSV with
   tracking columns for the reclamation campaign. **It states clearly that it cannot query Apple — the
   authoritative conflict list comes from Apple Business Manager; this is the candidate/tracking list
   only.**
5. **`SHAREDIPAD-Set-Restrictions.ps1`** *(the only state-changing script)* — assigns and verifies the
   `SHARED IPAD – Restrictions – Field Lockdown` profile assignment, with a read-only pre-flight that
   checks the group is Assigned and owned by the Provisioning Client. **Defaults to `-WhatIf` and says
   so** — it changes nothing unless you pass `-WhatIf:$false` explicitly. It never removes an existing
   assignment.

## Objects this solution creates

| Object | Type |
|---|---|
| `PILOT – Shared iPad Users` | Entra security group (Assigned, users) |
| `SHARED IPAD – FMD – Pilot` | Entra security group (Assigned, devices) |
| `SHARED IPAD – FMD – Production` | Entra security group (Assigned, devices) |
| `SHARED IPAD – ADE Profile – Shared` | Intune ADE enrollment profile (Shared iPad enabled) |
| `SHARED IPAD – Restrictions – Field Lockdown` | Intune device configuration profile |
| `SHARED IPAD – Compliance – iPadOS` | Intune compliance policy |
| `SHARED IPAD – Apps – Field Allowlist` | Intune device configuration profile + the app assignments |

## Hero image

- **`SHAREDIPAD-hero.png`** — the product image (1200×1200) used on the listing.

## How it's delivered

A **Word** document and **PDF** (cover, table of contents, page numbers, and a scripts appendix), plus
all five PowerShell scripts in a single **ZIP** — yours to keep and reuse across **unlimited devices**.

## A note on vendor specifics

This guide deliberately **flags rather than asserts** anything that Apple or Microsoft controls and
changes: current Shared iPad prerequisites (iPadOS version, storage minimums, maximum resident users),
Apple Business Manager portal navigation and flow names, the domain-verification and Apple ID
conflict-resolution mechanics, ABM↔Entra federation specifics, and the Microsoft 365 Shared Device Mode
iOS supported-app list. Each carries an explicit **verify against current Apple/Microsoft documentation**
flag. The concepts, decision points, and sequencing are given confidently; the vendor-controlled
specifics are pointed at the vendor's live documentation — because you are following this click-by-click,
and a confidently-stated wrong number costs more than a flag.
