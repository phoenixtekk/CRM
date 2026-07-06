# 3. Implementation Guide — Microsoft Teams → Google Chat & Meet Migration & Coexistence

Follow these steps in order. This guide runs the migration end to end: baseline the Teams estate, map
channels to spaces and design the meetings transition, stand up meeting coexistence, prove the full
cutover on a named pilot wave, then expand wave by wave until the estate is on Chat and Meet. Artifact
names are fixed — create them with the exact names shown and reuse them for every wave. The internal
console steps of any specific migration tool, and the movement of the underlying files, are deferred to
that tool's docs and to the Drive migration solution; this guide governs the mapping, sequencing,
coexistence, and adoption.

> Model: baseline and map once, stand up meeting coexistence, prove the cutover on a pilot wave,
> validate against the gate, then expand. The repeatable way: Assess, then Configure, then Pilot, then
> Validate, then Expand.

## Step 1 — Assess: baseline the Teams estate and stand up governance and adoption
1. Run `GWCHAT-Discovery.ps1` to capture the source baseline: teams, standard channels per team, channel
   membership counts, and the meeting/calendar signals visible through Microsoft Graph. Record it as
   `GWCHAT Discovery - Teams Estate - Baseline`, then add what the API cannot read (per-channel file
   volumes, recurring-meeting counts, third-party integrations) by hand.
2. Stand up the program governance: named Responsible/Accountable owners for each cutover stage, a
   recurring go/no-go forum, and the change-control process from the global requirements.
3. Start the adoption plan `GWCHAT Adoption - Change & Comms - Program` now — comms and role-based
   training are built alongside the technical plan, not added at cutover.
4. Record gaps against the Requirements checklist. Do not proceed past a missing baseline, missing
   identity source of truth, or an unresolved legal-hold decision for the Teams source.

## Step 2 — Configure: map channels to spaces and decide the migration path
1. Build `GWCHAT Mapping - Channels to Spaces - Program`. For **each in-scope team/standard channel**,
   record:
   - the **Google Chat space** name (name spaces consistently — e.g. one space per channel, prefixed by
     the team, so the mapping is legible and reusable),
   - the **member source** (the team/channel roster that seeds the space),
   - the **Drive location** that holds the channel's files (the Drive workstream moves the content; the
     mapping records which space points at which Drive/shared-drive location),
   - the **history decision** — conversations imported, or fresh start — recorded per space.
2. Decide the **migration path** and write it into the mapping, with the limits acknowledged in writing:
   - **Native channel-message migration** (channels → spaces) — supports channel *conversations* into
     spaces but **does not** carry 1:1/private chats, drops some formats/features (underlining, message
     cards, nested lists, Streams, praise, approvals), imports into hidden **import-mode** spaces on a
     **90-day** clock, and caps at **1,000 teams per import**
     ([Google Workspace Help — run a chat migration](https://knowledge.workspace.google.com/admin/migrate/run-a-chat-migration),
     [Google for Developers — import data to Google Chat](https://developers.google.com/workspace/chat/import-data)).
   - **Third-party tool** — where it covers more (e.g. DMs) — internals deferred to the vendor's docs
     ([Google Workspace Updates — migrate with CloudM](https://workspaceupdates.googleblog.com/2025/02/migrate-data-from-microsoft-teams-to-google-chat.html)).
   - **Fresh start** — create spaces and members, migrate no history; the fastest, lowest-risk path when
     history has little going-forward value.
   Author this **tool-agnostically** — the mapping governs *what maps to what and how much history*, not
   a specific vendor's console steps.
3. Record the **Teams source retention** decision (keep read-only / eDiscovery export) — the migration is
   a productivity move, **not** a compliance archive
   ([Google Workspace Help — set up a chat migration](https://knowledge.workspace.google.com/admin/migrate/set-up-a-chat-migration)).
4. Freeze the mapping before Wave 0. Every wave creates spaces the same way.

## Step 3 — Design and stand up meeting coexistence
1. Design `GWCHAT Meetings - Teams to Meet - Transition`:
   - **Meetings → Meet.** Define how scheduled and recurring **Teams meetings** are re-issued as
     **Google Meet** events for a wave's migrated users (new meetings created on Google Calendar/Meet;
     recurring Teams series re-issued as Meet series for the wave).
   - **Interop during the split.** Define how cross-platform meetings work while the estate is split:
     **calendar sync** between Google Workspace and Teams so events/RSVPs stay consistent, and
     **Meet↔Teams join** so each side can join the other's meetings
     ([Microsoft Learn — calendar syncing with Google Workspace](https://learn.microsoft.com/en-us/microsoftteams/setup-calendar-syncing-with-google-workspace),
     [Google Workspace Updates — Meet–Teams interoperability](https://workspaceupdates.googleblog.com/2026/02/meet-hardware-microsoft-teams-intero.html)).
2. Stand up interop on a test population and prove it: a migrated user and a not-yet-migrated user can
   see each other's availability and join a single cross-platform meeting.
3. Set the interop's intended **end** — it is transitional, decommissioned as waves complete.

## Step 4 — Build the wave plan
1. Segment the population into `GWCHAT Wave Plan - Segmentation - Teams` from the discovery baseline.
2. Apply the sizing rules:
   - **Wave 0 = pilot** — 50–150 users of core IT and early adopters that exercises the full runbook
     (spaces created, sample history imported, meetings on Meet, interop proven) before any production
     business unit moves.
   - **Keep teams intact.** Put a whole team (and its channels' members) in the same wave so a team is
     not split across Chat and Teams mid-conversation — live chat does **not** bridge 1:1 across the two
     platforms during coexistence.
   - **Coherent business units.** Keep each wave a single business unit/geography so comms, training, and
     support are focused.
   - **One wave per user, fixed.** Assign every user to exactly one wave and do not move users between
     waves once confirmed.
3. Build each wave's target group with `GWCHAT-Set-ScopeTargeting.ps1` (runs with `-WhatIf` by default).

## Step 5 — Author the per-wave cutover runbook and go/no-go gate
1. Author `GWCHAT Runbook - Cutover - Per Wave` with the fixed five-stage sequence:
   1. **Readiness** — the wave's users/groups are provisioned in Google, Chat/Meet enabled and licensed,
      the wave's spaces are mapped, the Drive pre-stage for the wave's channels is complete, and comms/
      training are delivered; `GWCHAT-Validation.ps1` reports the wave ready.
   2. **Spaces & history** — create the wave's Chat spaces from the mapping (or run the migration tool
      into **import-mode** spaces, then finalize within the 90-day window), seed membership, and confirm
      the accepted history scope. Finalizing an import-mode space is one-way — do it only when the
      space's history is complete for the wave.
   3. **Meetings / interop** — re-issue the wave's recurring meetings as Meet; confirm calendar sync and
      Meet↔Teams interop are live for the wave so cross-platform meetings still work.
   4. **Validation** — run the per-wave validation gates (Testing Guide) and `GWCHAT-Report.ps1` to
      confirm coverage (spaces created, members present, meetings working, users active).
   5. **Rollback** — the documented back-out (users continue on Teams for chat/meetings; unfinalized
      import-mode spaces are discarded; interop keeps them working) used only if the gate fails.
2. Define `GWCHAT Gate - Go/No-Go - Per Wave`: the wave passes only when readiness held, spaces exist
   with correct membership, the accepted history scope imported, meetings work on Meet with interop live,
   validation passed, and hypercare owners are ready. The next wave does not start until this gate
   passes.

## Step 6 — Run Wave 0 (the pilot) end to end
1. Build the Wave 0 group with `GWCHAT-Set-ScopeTargeting.ps1 -WhatIf:$false`.
2. Execute the full runbook on Wave 0: readiness → spaces & history → meetings/interop → validation.
3. Run `GWCHAT-Validation.ps1` for the wave and `GWCHAT-Report.ps1` for coverage/adoption.
4. Hold the Wave 0 `GWCHAT Gate - Go/No-Go - Per Wave` at the program cadence. The pilot passes only when
   the whole runbook ran end to end, the accepted history scope imported cleanly, meetings work on Meet,
   and interop is proven.

## Step 7 — Validate the pilot and fix the runbook, not just the wave
1. Complete the Testing Guide for Wave 0. Treat every issue as a **runbook** defect — fix the runbook,
   the mapping, the meetings design, or the tooling choice so later waves inherit the fix.
2. Remediate any space/membership/data-quality gaps with `GWCHAT-Remediation.ps1` (runs with `-WhatIf`
   by default) before re-running validation.

## Step 8 — Expand wave by wave
1. For each subsequent wave, re-run the same runbook: build the wave group
   (`GWCHAT-Set-ScopeTargeting.ps1`), execute readiness → spaces & history → meetings/interop →
   validation, run `GWCHAT-Validation.ps1` and `GWCHAT-Report.ps1`, and pass the go/no-go gate before
   the next wave.
2. Keep interop current as the migrated population grows; each user's meetings must work on their current
   platform through the split.
3. Keep adoption running per wave — usage of spaces and Meet is the real measure that a wave landed.

## Step 9 — Hypercare and decommission
1. After each wave, run a heightened-support hypercare window: triage issues fast, confirm the wave's
   users are active in Chat and Meet, and formally close the wave at the cadence.
2. After the **final** wave clears hypercare, decommission the meeting interop and stand down the Teams
   source footprint per the design's end-state — **retaining** the Teams source (or its eDiscovery
   export) for as long as legal-hold/retention policy requires, never before.

---
### Order of operations
`Assess/baseline -> Map channels->spaces + decide path -> Meeting coexistence -> Wave plan -> Runbook+gate -> Wave 0 pilot -> Validate/fix runbook -> Expand wave by wave -> Hypercare + decommission (source retained for legal hold)`
