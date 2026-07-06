# 1. Solution Overview — Microsoft 365 → Google Workspace Migration Program & Wave Plan

## What this program is
Moving an enterprise of 150k+ users from Microsoft 365 to Google Workspace is a **program**, not a
project. It is a governed operating model — a discovery baseline, a wave plan, a tooling strategy, a
coexistence design, per-wave cutover runbooks, and a hypercare period — run over months, across mail,
Drive, and collaboration, with every wave gated before the next begins. This solution is that
program. It orchestrates the individual data-movement workstreams (mail, Drive/OneDrive, Chat/Teams)
rather than duplicating them: the per-service migration mechanics live in their own solutions
(Exchange Online → Gmail, SharePoint/OneDrive → Google Drive, Teams → Google Chat/Meet); this program
sequences them, segments the users, governs the cutovers, and holds the gates.

## Why this matters
Enterprise migrations fail for predictable, non-technical reasons. There is no wave plan, so the
organization attempts a big-bang cutover and discovers architectural problems at 150k scale that a
pilot would have caught at 500. Coexistence is an afterthought, so mail is lost or double-delivered
while half the estate is on each platform and free/busy lookups fail across the divide. Cutovers are
ungoverned, so a wave is declared "done" while its DNS, mail-flow, and data-move validation is still
outstanding, and the failure surfaces days later with no rollback. And because nothing is proven on a
pilot first, every wave re-learns the same lessons and re-does the same work. A disciplined program
fixes the cause: it segments the population deliberately, designs coexistence up front, governs each
cutover with an explicit go/no-go gate, and proves the whole pattern on a pilot wave so later waves
execute the same runbook without rework. Public enterprise-migration guidance is consistent on this —
large moves are run in phases/waves for iterative testing, focused support, and continuous
improvement, with core IT and early adopters first, then department-by-department rollout
([Google Workspace Migrate — plan your phases](https://support.google.com/workspacemigrate/answer/9275515),
[Google enterprise migration & change management](https://workspace.google.com/solutions/migration/enterprise-migration/)).

## The migration operating model
The program runs through six sequential stages. Each has an owner, an entry condition, and an exit
gate (see the Implementation Guide). The stages are named and reused across every wave.

1. **Discovery** — baseline the source estate: user and mailbox counts, mailbox/Drive data volumes,
   shared mailboxes and resource calendars, distribution lists and groups, and the integrations
   (relay/apps/service accounts) that touch mail and files. This is what the wave plan is built from.
2. **Design** — decide the target Workspace architecture, the identity/provisioning model, the
   tooling strategy per service, and the coexistence design (how mail routes and free/busy works
   while the estate is split). Produced once, reused every wave.
3. **Coexistence** — stand up the transition state so migrated and not-yet-migrated users interoperate:
   directory sync, mail routing (dual/split delivery), and calendar interop. Coexistence is a
   **transitional** phase, deliberately time-boxed — never a permanent end state.
4. **Waves** — segment 150k users into sized, bounded waves and schedule them. Wave 0 is the pilot;
   subsequent waves expand by business unit/geography/data-weight until the estate is covered.
5. **Cutover** — execute each wave against its runbook: readiness → mail-flow/DNS → data move →
   validation → (rollback if the gate fails). Each wave passes a go/no-go gate before the next starts.
6. **Hypercare** — a heightened-support window after each wave (and after the final wave) where
   issues are triaged fast, coexistence is decommissioned in step, and the wave is formally closed.

## The named program artifacts
The program is built from a fixed set of named artifacts you author once and reuse every wave. Using
the exact names keeps the program legible across owners, waves, and months.

| Artifact | Name |
|---|---|
| Source estate baseline | `GWMIGPROG Discovery - Source Estate - Baseline` |
| Target & tooling design | `GWMIGPROG Design - Target & Tooling - Program` |
| Coexistence design | `GWMIGPROG Coexistence - Mail & Calendar - Transition` |
| Wave plan | `GWMIGPROG Wave Plan - Segmentation - 150k` |
| Per-wave cutover runbook | `GWMIGPROG Runbook - Cutover - Per Wave` |
| Go/no-go gate | `GWMIGPROG Gate - Go/No-Go - Per Wave` |
| Program cadence & RACI | `GWMIGPROG Cadence & RACI - Program - All Stages` |

## Workstream sequencing
The program runs several workstreams in parallel, but they are ordered by dependency, not by
convenience:

- **Identity & provisioning first.** Users and groups must exist in Google (via directory sync — e.g.
  Google Cloud Directory Sync or SCIM) before any of their data can land or any coexistence routing
  can address them. Nothing migrates until identity is in place for that wave's population.
- **Coexistence before the first data wave.** Mail routing and calendar interop must be live before
  any user is cut over, so a migrated user and a not-yet-migrated user can still mail and schedule
  each other. Coexistence is stood up once and governs the whole transition.
- **Mail, Drive, and collaboration per wave.** Within a wave, data services migrate on a defined
  order (typically mail and calendar aligned to the mail cutover, Drive data staged ahead and
  finalized at cutover, chat/collaboration aligned to the user's move). Each service's mechanics are
  deferred to its own solution; the program schedules and gates them together per wave.
- **Decommission last.** Coexistence routing and the source tenant footprint are retired only after
  the final wave clears hypercare — never mid-program.

## Wave planning in brief
Waves are sized from the discovery baseline. Wave count is driven by the number of users, the data
volume, and the mix of data types being moved
([Google — plan your phases](https://support.google.com/workspacemigrate/answer/9275515)). The
program spreads the most data-heavy users across waves so no single wave overwhelms the migration
throughput, keeps each wave a coherent business unit/geography so support and comms are focused, and
never moves a user between waves once the wave is confirmed (that risks duplicate data). Wave 0 is a
50–150-user pilot of core IT and early adopters that proves the full runbook end to end before any
production business unit moves. The Implementation Guide gives the sizing method; `GWMIGPROG-Set-ScopeTargeting.ps1`
builds each wave's target group.

## What this is not
This program governs sequencing, segmentation, coexistence, and cutover — the orchestration layer. It
does **not** re-document the internal steps of each per-service migration tool; those are deferred to
the vendor's own docs and to the individual mail/Drive/Chat migration solutions. Where the program
reads the source estate to plan and gate waves, the included scripts read **Microsoft 365 / Microsoft
Entra** through Microsoft Graph, read-only; they move no data and change no mail flow.

## The deployment model
> Baseline the estate and design once, stand up coexistence, prove the full cutover runbook on a pilot
> wave, validate against the go/no-go gate, then expand wave by wave until the estate is covered — the
> repeatable way: Assess, then Configure, then Pilot, then Validate, then Expand.
