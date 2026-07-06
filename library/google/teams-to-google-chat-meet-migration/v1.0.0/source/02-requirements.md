# 2. Requirements Guide — Microsoft Teams → Google Chat & Meet Migration & Coexistence

Verify every requirement before running the migration. Each entry gives **Description**, **Why**,
**Verify**, and **Implement-if-missing**. Category-wide prerequisites (the Google Workspace tenant, the
source Microsoft 365 / Entra environment, DNS control, the identity source of truth, a pilot scope, and
governance stakeholders) are in `global-requirements-google.md`; this guide adds what the Teams → Chat/Meet
migration specifically needs.

## 2.1 Administrative access to the source Microsoft Teams estate
Description: Administrative read access to the source **Microsoft Teams / Microsoft 365** tenant through
Microsoft Graph — enough to enumerate teams, their standard channels, channel membership, and the
meetings/calendars in scope — captured as `GWCHAT Discovery - Teams Estate - Baseline`.
Why: The channel→space mapping, the wave plan, and the meetings-transition design are all built from an
accurate picture of the Teams estate; without it, spaces are mapped and waves are sized by guesswork.
Verify: You can enumerate teams and channels for a representative sample; run `GWCHAT-Discovery.ps1`.
Implement-if-missing: Obtain the read roles from the Microsoft 365/Teams tenant owner and run
`GWCHAT-Discovery.ps1`, then add the details the API cannot read (per-channel file volumes, meeting
counts, integrations) by hand and declare it the baseline of record.

## 2.2 Google Workspace with Chat and Meet enabled, and licensing
Description: A Google Workspace tenant where **Google Chat and Google Meet are enabled** for the
in-scope users, with the edition/licensing the migration path needs (the native Teams-message migration
requires target users to have **active licenses and Chat enabled**).
Why: Spaces cannot be created for, and messages cannot be imported to, users who are not licensed and
Chat-enabled; meetings cannot be re-issued on Meet for users without Meet.
Verify: In the Google Admin console, confirm Chat and Meet are ON for the pilot OU and the pilot users
are licensed; run `GWCHAT-Validation.ps1` for the wave.
Implement-if-missing: Enable Chat and Meet for the target OUs and assign licenses before scheduling the
pilot wave.

## 2.3 Identity & provisioning into Google
Description: Users and groups flow from the identity source of truth into Google **before** their spaces
or meetings are created — via Google Cloud Directory Sync (GCDS) or SCIM-based provisioning — per the
source of truth defined in the global requirements.
Why: A space's membership and a meeting's invitees resolve to Google accounts; nothing can be created or
addressed until the accounts exist, and coexistence cannot route to them.
Verify: A sample wave's users and groups appear in the Google Admin console before any space is created;
run `GWCHAT-Validation.ps1` for that wave.
Implement-if-missing: Stand up GCDS/SCIM provisioning against the source of truth and confirm a test
population provisions before scheduling Wave 0.

## 2.4 A channel → space mapping
Description: A decision record — `GWCHAT Mapping - Channels to Spaces - Program` — that maps each
in-scope **team/standard channel** to a **Google Chat space** (with the space name, member roster, and
the Drive location that holds the channel's files), and records the **history scope** decided for each
space (conversations imported, or fresh start).
Why: Waves must create spaces the *same* way; deciding naming, membership, and history scope per channel
at cutover time guarantees inconsistent spaces and rework. The mapping is also where the honest
message-history limits are written down so expectations are set once.
Verify: Every in-scope channel maps to exactly one space with a name, a member source, a Drive target,
and a history decision; the mapping is agreed by the migration owners.
Implement-if-missing: Build the mapping in Implementation Step 2 from the discovery baseline; freeze it
before Wave 0.

## 2.5 A meetings-transition design (Teams meetings → Meet + interop)
Description: A design — `GWCHAT Meetings - Teams to Meet - Transition` — for how scheduled/recurring
**Teams meetings become Google Meet** meetings (re-issue links for migrated users) and how **meeting
interop** works while the estate is split (calendar sync between Google and Teams, and Meet↔Teams join).
Why: During the months the estate is split, a migrated user and a not-yet-migrated user must still meet;
without a design, recurring meetings break at cutover and cross-platform meetings fail.
Verify: The design names the re-issue approach for recurring meetings and the interop mechanism, and a
test cross-platform meeting joins successfully in a lab
([Microsoft Learn — calendar syncing with Google Workspace](https://learn.microsoft.com/en-us/microsoftteams/setup-calendar-syncing-with-google-workspace),
[Google Workspace Updates — Meet–Teams interoperability](https://workspaceupdates.googleblog.com/2026/02/meet-hardware-microsoft-teams-intero.html)).
Implement-if-missing: Design the meetings transition in Step 3, stand up interop on a test population,
and prove it before the first production wave. Interop is transitional — set its intended end.

## 2.6 A migration tooling decision (native or third-party), with limits acknowledged
Description: A recorded decision on the **message-migration path** — Google's native channel-message
migration, a third-party tool, or a deliberate **fresh-start** (no history) — with the documented limits
acknowledged in writing: no 1:1/private-chat migration by the native path, unsupported message
formats/features, the 90-day import-mode window, the 1,000-teams-per-import cap, and that the migration
is **not a compliance archive**
([Google for Developers — import data to Google Chat](https://developers.google.com/workspace/chat/import-data),
[Google Workspace Help — run a chat migration](https://knowledge.workspace.google.com/admin/migrate/run-a-chat-migration),
[Google Workspace Help — set up a chat migration](https://knowledge.workspace.google.com/admin/migrate/set-up-a-chat-migration)).
Why: The path drives the runbook and the user comms; deciding it late, or promising a perfect history
copy the tools can't deliver, is the classic way these projects lose trust.
Verify: The tooling decision names the path and lists the accepted limits; the tool's own console steps
are referenced (not re-authored here).
Implement-if-missing: Choose the path in Step 2 and record the accepted limits in the mapping artifact
before Wave 0.

## 2.7 Legal-hold / retention handling for the Teams source
Description: A decision on what happens to the **Teams source** after migration — kept read-only for
reference and any legal hold, or exported via eDiscovery — because the chat migration is a productivity
feature, **not** a retention/compliance archive.
Why: If the source is retired assuming history migrated, data under legal hold can be lost; the migrated
copy is not a defensible archive.
Verify: The retention owner has signed off on how the Teams source is preserved for as long as policy
requires.
Implement-if-missing: Engage the legal/eDiscovery stakeholder from the global requirements and record the
source-retention decision before any Teams decommission.

## 2.8 A wave plan
Description: A segmentation of the in-scope population into sized, bounded, scheduled waves — named
`GWCHAT Wave Plan - Segmentation - Teams` — with Wave 0 as the pilot, kept to **coherent teams/business
units** so cross-platform chat during the split is minimized.
Why: Waves turn the estate into executable, gated units; keeping a team together in one wave avoids a
team being split across Chat and Teams mid-conversation (which live chat does not bridge 1:1).
Verify: Every in-scope user is in exactly one wave, waves keep teams intact where possible, and the pilot
wave is identified.
Implement-if-missing: Build the wave plan from the discovery baseline; build each wave's target group
with `GWCHAT-Set-ScopeTargeting.ps1`.

## 2.9 Per-wave cutover runbook and go/no-go gate
Description: A repeatable per-wave runbook — `GWCHAT Runbook - Cutover - Per Wave` — with the fixed
sequence (readiness → spaces & history → meetings/interop → validation → rollback) and an explicit
`GWCHAT Gate - Go/No-Go - Per Wave` that must pass before the next wave starts.
Why: Every wave executes the same governed cutover; an ungoverned cutover is declared done before
validation, and a failed one with no rollback becomes an incident.
Verify: The runbook exists with all five stages and a documented rollback, and the gate criteria are
defined and owned.
Implement-if-missing: Author the runbook and gate in Step 5, prove them on Wave 0, and reuse them
unchanged for every subsequent wave.

## 2.10 An adoption & change-management plan
Description: A comms/training plan — `GWCHAT Adoption - Change & Comms - Program` — that prepares each
wave's users for Chat and Meet (what moved, what didn't, where to find files, how meetings changed), set
up alongside the technical plan, not bolted on at cutover.
Why: A migration where spaces exist but no one uses them has failed; adoption is what turns a cutover
into a working platform.
Verify: The plan names the comms cadence and role-based training per wave and is part of each wave's
readiness.
Implement-if-missing: Build the adoption plan in Step 1 and make it a readiness gate for every wave.

---
## Checklist
- [ ] Source Teams estate baselined — `GWCHAT-Discovery.ps1` → `GWCHAT Discovery - Teams Estate - Baseline`
- [ ] Google Chat + Meet enabled and licensed for in-scope users
- [ ] Identity/provisioning into Google live — `GWCHAT-Validation.ps1`
- [ ] Channel → space mapping frozen — `GWCHAT Mapping - Channels to Spaces - Program`
- [ ] Meetings-transition + interop design proven — `GWCHAT Meetings - Teams to Meet - Transition`
- [ ] Migration path + accepted limits recorded (native / third-party / fresh-start)
- [ ] Teams source retention / legal-hold decision signed off
- [ ] Wave plan built (teams kept intact, one user per wave) — `GWCHAT Wave Plan - Segmentation - Teams`
- [ ] Per-wave runbook + go/no-go gate authored — `GWCHAT Runbook - Cutover - Per Wave`
- [ ] Adoption & comms plan live — `GWCHAT Adoption - Change & Comms - Program`
