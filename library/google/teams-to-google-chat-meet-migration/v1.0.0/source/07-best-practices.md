# 7. Best Practices — Microsoft Teams → Google Chat & Meet Migration & Coexistence

Field-proven practices for moving collaboration from Teams to Chat and Meet **without stranding users** —
and without overpromising a history copy the tools can't deliver.

- **Set the honest scope on day one.** Tell users up front what moves and what doesn't: channel
  conversations can migrate to spaces, but 1:1/private chats don't (native path), some formats/features
  don't carry, and the Teams source stays for reference and legal hold. A migration that promises a
  perfect history copy loses trust the moment a user notices a missing message
  ([Google Workspace Help — run a chat migration](https://knowledge.workspace.google.com/admin/migrate/run-a-chat-migration)).
- **Design going-forward collaboration, not a museum.** Put the effort into the *right* spaces, the
  *right* members, meetings on Meet, and adoption — not into a byte-perfect history copy. History is
  "nice to have"; a working platform people actually use is the goal.
- **Map channels to spaces once, reuse every wave.** Freeze `GWCHAT Mapping - Channels to Spaces - Program`
  with consistent space naming (e.g. team-prefixed, one space per channel), the member source, and the
  Drive location per space. Deciding naming and membership per channel at cutover is the biggest source
  of inconsistent spaces.
- **Keep teams intact within a wave.** Put a whole team in one wave. Live chat does **not** bridge 1:1
  across Chat and Teams during coexistence, so a team split across the two platforms mid-conversation is
  the fastest way to strand people.
- **Identity before spaces, always.** Provision each wave's users/groups into Google (GCDS/SCIM) and
  enable Chat/Meet before any space or meeting is created; a space or invite addressed to a non-existent
  account fails.
- **Respect the import-mode clock.** When you migrate history, spaces sit in **hidden import mode** and
  must be finalized within **90 days** or they're deleted and unrecoverable; finalizing is one-way. Never
  open import until you can finish it, and never finalize until the wave's history is complete
  ([Google for Developers — import data to Google Chat](https://developers.google.com/workspace/chat/import-data)).
- **Batch within the per-import cap.** The native tool imports up to **1,000 teams per import**; plan
  additional imports for larger estates rather than discovering the cap mid-cutover
  ([Google Workspace Help — run a chat migration](https://knowledge.workspace.google.com/admin/migrate/run-a-chat-migration)).
- **Stand up meeting interop before the first wave, and time-box it.** Calendar sync and Meet↔Teams join
  must be live before anyone cuts over so migrated and not-yet-migrated users still meet — and interop is
  transitional, decommissioned as waves complete, never left running indefinitely
  ([Microsoft Learn — calendar syncing with Google Workspace](https://learn.microsoft.com/en-us/microsoftteams/setup-calendar-syncing-with-google-workspace),
  [Google Workspace Updates — Meet–Teams interoperability](https://workspaceupdates.googleblog.com/2026/02/meet-hardware-microsoft-teams-intero.html)).
- **Re-issue recurring meetings, don't hope they survive.** Recurring Teams series break at cutover;
  re-issue them as Meet series per wave so no standing meeting is silently lost.
- **Keep the Teams source for legal hold.** The chat migration is a productivity feature, **not** a
  compliance archive. Preserve the Teams source (or an eDiscovery export) for as long as retention policy
  requires before any decommission
  ([Google Workspace Help — set up a chat migration](https://knowledge.workspace.google.com/admin/migrate/set-up-a-chat-migration)).
- **Prove the whole runbook on a pilot wave.** Wave 0 (core IT + early adopters) exercises spaces,
  history, meetings, and interop end to end. It's cheaper to find a defect in 100 users than in a
  business unit of thousands.
- **Fix the runbook, not just the wave.** Every issue found in a wave is a defect in the runbook,
  mapping, or meetings design — fix it there so all later waves inherit the fix.
- **Adoption runs in tandem with the technical plan.** Comms and role-based training (what moved, where
  files are, how meetings changed) are part of each wave's readiness from the start, not bolted on at
  cutover — usage of spaces and Meet is what tells you a wave actually landed.
- **Gate every cutover.** No wave starts until the previous wave passes `GWCHAT Gate - Go/No-Go - Per Wave`;
  a wave declared done before its validation completes is an incident waiting to surface.
- **Always have a rollback.** Users can stay on Teams for chat/meetings and unfinalized import-mode
  spaces can be discarded — interop keeps the split estate working, so a failed wave is recoverable.
- **Keep the migration tool-agnostic.** This solution governs *what maps to what, how much history, and
  when*; the specific tool's console steps and the file movement live in the tool's docs and the Drive
  migration solution — so a tooling change touches that layer, not the whole program.
