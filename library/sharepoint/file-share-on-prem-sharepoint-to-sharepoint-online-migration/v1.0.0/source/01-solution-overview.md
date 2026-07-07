# 1. Solution Overview — File-Share & On-Prem SharePoint → SharePoint Online Migration

## What this solution is
Legacy file servers and on-premises SharePoint Server farms are expensive to run, hard to secure,
and increasingly a liability — but the naive fix (copy everything up with a drag-and-drop tool)
simply recreates the mess in the cloud: broken permissions, orphaned folders nested twenty levels
deep, filenames the platform rejects, and no owner for anything. This solution is a **repeatable,
pilot-first method to migrate file shares and on-prem SharePoint content into SharePoint Online
(SPO) and OneDrive cleanly** — assess and remediate the source, map it to a governed target
information architecture (IA), execute with Microsoft's supported migration tooling (**Migration
Manager** and the **SharePoint Migration Tool / SPMT**) using a pre-stage + delta pattern, map
permissions, and validate that content and access actually landed.

It uses only supported Microsoft tooling and PowerShell (SharePoint Online Management Shell, **PnP
PowerShell**, the **SPMT PowerShell** module, and Microsoft Graph). The migration-tool *console
internals* (the Migration Manager agent UI, the SPMT desktop wizard screens) are deferred to
Microsoft's product documentation — this solution gives you the **procedure, sequencing, and
automation** around them, which is where migrations actually succeed or fail.

> **Scope boundary.** This is an **on-prem / file-share → SharePoint Online** migration. It is
> distinct from any **SPO → other-platform** migration (e.g. SPO → Google Drive), which moves in the
> opposite direction with different tooling. Source here = Windows/NAS file shares (SMB/UNC) and
> **on-premises SharePoint Server** (2013/2016/2019/Subscription Edition) document libraries. Target
> = SharePoint Online team/communication sites and OneDrive for Business.

## Why this matters
- **A bad migration is worse than no migration.** Lift-and-shift with no remediation carries every
  legacy problem — nested-permission sprawl, dead content, unresolvable names — into a platform where
  they are harder to fix and now cost you per-GB.
- **The platform will silently reject content you didn't remediate.** Path/URL length over the SPO
  limit, blocked file types, invalid characters, and oversized files fail *during* the migration —
  discovering that on cutover night, at scale, is how migrations slip weeks.
- **Permissions are the hardest part and the part tools do worst.** NTFS ACLs and on-prem SharePoint
  groups do not map one-to-one to SPO/M365 groups. Getting this wrong either over-shares (a
  compliance incident) or locks people out (a flood of tickets) on day one.
- **Without a target IA, you pave the cow paths.** Deciding *where* content lands — which site, which
  library, which hub — before you move it is what turns a migration into a cleanup.
- **Delta migration is what makes cutover safe.** Pre-staging the bulk while the source stays live,
  then moving only the changes at cutover, shrinks the freeze window from days to hours.

## How it works
1. **Assess the source.** Scan file shares (and inventory on-prem SharePoint libraries) for the things
   that break SPO migrations: **path/URL length** approaching the limit, **invalid characters** and
   reserved names, **blocked file types**, **oversized files**, very large libraries/folders, and the
   **permission model** (NTFS ACLs, share permissions, on-prem SP groups). The output is a factual
   inventory and a remediation punch-list.
2. **Remediate the source (or plan around it).** Fix or flag each blocker: shorten paths, rename
   invalid items, remove or archive blocked/dead content, split oversized structures. Remediation is
   staged and reversible; nothing is changed in production without a report and an approval.
3. **Design the target IA.** Map each source share/library to a target **site → library → folder**
   and to a hub, applying a naming convention and a governance model (owners, sharing, retention
   intent — with the compliance *determination* deferred to the records/legal function). This is a
   *mapping*, not a copy of the source tree.
4. **Map permissions.** Translate each source principal (NTFS group, on-prem SP group, individual
   ACE) to a target **SPO group / M365 group / Entra security group** and a permission level. Where a
   clean mapping doesn't exist, it is flagged for a decision rather than guessed.
5. **Configure the migration tool.** Choose **Migration Manager** (agent-based, best for many file
   shares and on-prem SP at scale, tasks defined in the SharePoint admin center) or **SPMT** (desktop
   / PowerShell, best for smaller or scripted runs); register the target, define tasks from the
   mapping (bulk CSV/JSON), and set the settings (permissions, versions, filters).
6. **Pre-stage, then delta.** Run a full **pre-stage** pass while the source stays read/write, then —
   at the agreed cutover window — set the source read-only and run an **incremental (delta)** pass
   that moves only what changed. This is the pattern both Microsoft tools support for a low-downtime
   cutover.
7. **Validate.** Compare source vs. target **item counts**, spot-check **permissions**, confirm
   metadata/versions per the settings chosen, and confirm the delta is clean (nothing left behind).
   Only then is the source decommissioned per the org's retention rules.

## Reference design (what "good" looks like)
- A **pilot wave** (one representative share or on-prem site collection) proves the whole
  assess → remediate → map → migrate → validate chain end-to-end before any broad wave.
- Bulk migration runs from a **migration workstation/agent** with line-of-sight to the source (SMB /
  on-prem SP) and to SPO, using **Migration Manager agents** (scaled out for throughput) or **SPMT**.
- Content lands in a **governed target IA** — communication/team sites under hubs, with owners,
  sharing settings, and retention intent applied — not a mirror of the old drive letters.
- Every wave uses **pre-stage + delta** so the business keeps working on the source until a short,
  scheduled cutover.
- A **validation gate** (counts + permissions + delta-clean) must pass before a wave is called done
  and the source is retired.

## Naming convention (used in every doc and script)
Every artifact this solution creates is named `<Purpose> – <Scope> – <Stage>` and reused verbatim
across the docs, scripts, the SharePoint admin center, and the migration tool. The standard set:

| Artifact | Name |
|---|---|
| Source assessment export | `Source Assessment – FileShare+SP – Discovery` |
| Remediation punch-list | `Remediation Plan – Source – PreMigration` |
| Target IA / destination map | `Target IA Map – SPO – Design` |
| Permission mapping table | `Permission Map – Source→SPO – Design` |
| Pilot migration task | `Migration Task – Pilot – Wave0` |
| First broad wave task | `Migration Task – Finance – Wave1` |
| Cutover runbook (per wave) | `Cutover Plan – <Scope> – <WaveN>` |
| Post-migration validation report | `Post-Migration Validation – <Scope> – Validate` |
| Target site (pilot) | `SPO Site – Pilot – Prod` |

## Benefits
- **Content lands organized and governed**, not a cloud copy of the legacy mess.
- **No cutover-night surprises** — blockers are found and fixed in assessment, not discovered at scale.
- **Permissions arrive intact and intentional**, mapped to modern SPO/M365 groups.
- **Low-downtime cutover** via pre-stage + delta.
- **Evidence of success** — counts and permission validation prove the migration, per wave.

## Limitations (be honest with buyers)
- **Migration-tool console internals are deferred to Microsoft docs.** This solution gives the method,
  sequencing, task definitions, and PowerShell — not a screen-by-screen tour of the Migration Manager
  or SPMT UI, which Microsoft documents and changes.
- **SPO service limits are Microsoft's, not ours, and change.** Path/URL length, file-size, blocked
  file types, and list-view limits are enforced by the service; the exact current values must be
  **verified against Microsoft's documentation for your tenant/cloud** (see Requirements/Testing).
- **Government and sovereign clouds differ.** GCC High / DoD (`*.sharepoint.us` / `*.office365.us`)
  and other sovereign clouds can differ in tool support, endpoints, and limits — **verify in your
  tenant**; do not assume Commercial behavior.
- **Not every source is tool-supported.** Encrypted, in-use, or exotic sources (e.g. some NAS
  permission models, IRM/RMS-protected files, third-party ECM) may need vendor tooling or manual
  handling; those are integrated at the pattern level and deferred to the vendor's docs.
- **Compliance/legal determinations are out of scope.** What to retain, what is under legal hold, and
  which records schedule applies are **decided by the org's compliance/records/legal functions** —
  this solution provides the technical method and evidence, not the determination.

## The standard deployment model
> Assess and remediate the source → design the target IA and permission map → configure the tool →
> run a **pilot** wave (pre-stage + delta) and validate → expand wave by wave, retiring each source
> only after its validation gate passes.
> Pattern: **Assess → Design → Configure → Pilot → Validate → Expand**, with explicit pass/fail gates
> and a documented rollback (the source stays authoritative until validation passes).
