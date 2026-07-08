# 1. Solution Overview — Azure RMS / AIP → Built-in Unified Labeling Migration (Microsoft Purview)

## What this solution is
The **Azure Information Protection (AIP) add-in for Office** is on its way out — Microsoft has
disabled it by default and is retiring it in favour of **built-in labeling**, the sensitivity-labeling
experience baked directly into Word, Excel, PowerPoint, and Outlook with no add-in required. Leaving
users on the AIP add-in past its end of life is both a **compliance gap** (labeling on a dead client)
and a **data-risk exposure** (protection that may stop working). This solution moves you off the AIP
add-in and off legacy **Azure Rights Management (RMS) departmental templates** to **built-in unified
labeling** in Microsoft Purview — **with policy parity**, so the labels, protection, and behaviour your
users see after the cutover match what they had before.

- Inventory the current state: **sensitivity labels** and **label policies** in Microsoft Purview, the
  **Azure RMS / protection templates** in the protection service, and where the **AIP add-in** is still
  in use.
- Confirm the **built-in labeling prerequisites** (supported Office builds, encryption / co-authoring
  requirements) and that the **Azure Rights Management** protection service is activated.
- Build a **parity map**: every AIP add-in feature and every departmental RMS template mapped to its
  built-in-labeling / sensitivity-label equivalent, with gaps flagged.
- Configure Office to **use built-in labeling and disable the AIP add-in**, and tune **label-policy
  advanced settings** so behaviour matches the old client.
- **Pilot on a ring first**, validate parity against pass/fail gates, then **expand** tenant-wide.

Everything is done with the **Microsoft Purview portal** (purview.microsoft.com), **Security &
Compliance PowerShell** (`Connect-IPPSSession`), the **AIPService** PowerShell module (the protection
service), **Microsoft Graph**, and Office client policy (Group Policy / Microsoft 365 Apps admin
center) — no third-party tooling.

> **This is a migration, not a label-taxonomy build.** It moves an *existing* labeling estate from the
> AIP add-in / legacy RMS onto built-in labeling with parity. Designing a label taxonomy from scratch,
> authoring auto-labeling policies, or standing up the Information Protection scanner are separate
> Purview solutions. Where this guide reaches the edge of one of those, it points to it rather than
> duplicating it.

## Why this matters
- **The AIP add-in is retiring — verify the current status for your tenant.** Microsoft has disabled the
  AIP unified labeling add-in for Office by default and is retiring it; built-in labeling is the
  supported path. Users left on the add-in risk a labeling/protection experience that degrades or stops.
  Confirm the exact retirement state against Microsoft's current guidance and your Office channel.
- **Parity is the whole point.** A migration that silently drops a feature (custom permissions, a
  default Outlook label, a mandatory-labeling prompt, a protected-PDF behaviour) is a migration that
  creates help-desk tickets and, worse, unprotected data. This solution treats **feature-and-template
  parity** as the deliverable, not an afterthought.
- **Legacy RMS templates don't move themselves.** Azure RMS departmental/protection templates and
  sensitivity-label encryption are two views of the same protection service, but templates are **not**
  auto-converted into labels. Each must be mapped to a label with matching encryption settings — the
  *technical* method is here; which template still applies is a records/compliance determination.
- **High-impact change deserves a pilot.** Flipping the labeling client for a user changes how every
  document and email is classified and protected. Doing it to a **pilot ring in a controlled window**
  first — and validating parity — is the difference between a clean cutover and a tenant-wide incident.

## How it works
1. **Assess.** Read-only: inventory sensitivity labels, label policies (and their advanced settings),
   Azure RMS activation state, protection/RMS templates, and signals of where the AIP add-in is still
   in use. No changes.
2. **Design.** Build the **parity map** — AIP add-in features → built-in equivalents, and departmental
   RMS templates → sensitivity labels with matching encryption — and record the target **Office client
   policy** (use built-in labeling, disable the AIP add-in) and the **label-policy advanced settings**
   needed for behavioural parity.
3. **Configure.** Apply the label-policy advanced settings (`-WhatIf` preview first), confirm the labels
   and protection exist in the unified store, and stage the Office client policy — all scoped to the
   pilot ring.
4. **Pilot (cutover the ring).** Move the **pilot ring** to built-in labeling / disable the add-in in a
   change window; keep everyone else on the current experience.
5. **Validate.** Confirm on the ring that every label appears, applies, and protects exactly as before,
   that departmental-template protection is reproduced, and that no parity gap is open — against
   explicit pass/fail gates.
6. **Expand (enforce).** Broaden the Office client policy from the ring to the full population, monitor,
   and decommission the AIP add-in.

## Parity dimensions (what "parity" covers)
| Dimension | AIP add-in / legacy RMS | Built-in labeling target |
|---|---|---|
| Label list & order | Labels shown by the add-in | Same labels from the Purview label policy |
| Default / mandatory labeling | Add-in policy settings | Label-policy settings + advanced settings |
| Encryption & permissions | Label encryption / custom permissions | Sensitivity-label encryption (parity; some features need newer Office) |
| Departmental protection | Azure RMS departmental templates | Sensitivity labels with matching encryption |
| Outlook behaviour | Default Outlook label, Do-Not-Forward | Label-policy Outlook settings / advanced settings |
| Recovery | RMS super-users | Azure RMS super-users (unchanged) |

> **Some AIP add-in features require a newer Office build under built-in labeling, and a few have no
> exact equivalent.** Feature availability and minimum builds are **cited or flagged "verify your
> Office version / licensing"**, never invented. Where a gap has no built-in equivalent, it is recorded
> as an explicit decision for the label owner — not silently dropped.

## What you can control
- Which users/devices are in the **pilot ring** vs the broad rollout.
- The **Office client policy** (use built-in labeling; disable/allow the AIP add-in) via Group Policy or
  the Microsoft 365 Apps admin center (Cloud Policy).
- The **label-policy advanced settings** used to reproduce add-in behaviour (default Outlook label,
  mandatory-labeling posture, custom-permissions availability — verify each key against current docs).
- The **parity mapping** of departmental RMS templates to sensitivity labels.
- The change window and rollback for each cutover ring.

## Limitations (be honest with buyers)
- **Licensing- and build-gated.** Sensitivity labeling and its encryption features depend on the tenant's
  licensing (Azure Information Protection P1/P2 / Microsoft 365 E3/E5 — **verify your plan**) and on
  **minimum Office builds** for built-in labeling. Some add-in features (e.g. certain custom-permission
  or protected-PDF behaviours) need newer builds or have no direct equivalent — this solution surfaces
  the gap; it cannot license or upgrade for you.
- **The AIP add-in's retirement state and Office ADMX policy names evolve.** Retirement timing, the exact
  Group Policy / Cloud Policy setting names, and any registry values are **cited as of authoring and
  flagged "verify in your tenant / current ADMX"** — never asserted blind.
- **Departmental RMS templates are not auto-converted.** There is no supported cmdlet that turns a
  protection template into a sensitivity label; each is reproduced as a label with matching encryption.
  Whether a legacy template still applies is a records/compliance determination, deferred.
- **This is not a taxonomy or auto-labeling project.** Building new labels, auto-labeling, DLP, or the
  Information Protection scanner are separate solutions — this migration preserves the existing estate.

## Naming convention (used in every doc and script)
Artifacts this solution creates or captures follow `<Purpose> – Purview – <Stage>` and are reused
verbatim across the docs, scripts, and portal.

| Artifact | Name |
|---|---|
| Label / policy / RMS-template inventory export | `AIP/RMS Inventory – Migration – Assess` |
| AIP-add-in → built-in parity map | `Built-in Labeling Parity – Design` |
| Label-policy advanced-settings configuration | `Label Policy Config – Configure` |
| Migration validation / parity report | `Migration Validation – Report` |
| Migration scope & RMS-health map | `Migration Scope – Map` |
| Migration pilot ring | `AIP Migration Pilot Ring – Stage1` |

## The standard deployment model
> Assess the estate → design the parity map + target client policy → configure label-policy settings and
> stage the client policy → pilot the cutover on a ring → validate parity against pass/fail gates →
> expand tenant-wide and decommission the add-in. Pattern: **Assess → Design → Configure → Pilot →
> Validate → Expand.**
