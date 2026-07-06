# 5. Testing Guide — Microsoft Teams → Google Chat & Meet Migration & Coexistence

Run these per-wave validation gates for **every** wave — first for Wave 0 (the pilot), then for each
expansion wave — before that wave's go/no-go decision. Each test confirms one part of the cutover
runbook worked for the wave's population. A wave does not pass until its gate criteria are met.

## Test 1 — Baseline and wave assignment are complete
Do: Confirm every user in the wave is assigned to exactly one wave in
`GWCHAT Wave Plan - Segmentation - Teams` and appears in the wave's target group, and that the wave keeps
its teams intact; run `GWCHAT-Set-ScopeTargeting.ps1` (preview) to confirm membership.
Expected: The wave's members match the plan, no user is in two waves or unassigned, and no team is split
across two waves.

## Test 2 — Readiness: identity, licensing, and Chat/Meet enabled
Do: Run `GWCHAT-Validation.ps1` for the wave.
Expected: The wave's users/groups are provisioned into Google, licensed, and **Chat and Meet are
enabled**; readiness signals report present with no gaps.

## Test 3 — Spaces created with correct membership
Do: For a sample of the wave's channels, confirm the mapped **Google Chat space** exists with the name
from `GWCHAT Mapping - Channels to Spaces - Program` and the correct member roster.
Expected: Each sampled channel has its space, correctly named, with membership matching the mapping.

## Test 4 — History scope imported as designed (and limits honored)
Do: For spaces where history was in scope, confirm channel conversations imported and the import-mode
space was **finalized** within the window; confirm the accepted limits held (no 1:1/private chats
expected; some formats not carried).
Expected: The imported history matches the agreed scope; no space is stuck in import mode past the
**90-day** deadline; unsupported content is absent as expected, not treated as a defect
([Google for Developers — import data to Google Chat](https://developers.google.com/workspace/chat/import-data),
[Google Workspace Help — run a chat migration](https://knowledge.workspace.google.com/admin/migrate/run-a-chat-migration)).

## Test 5 — Files reachable from the space
Do: For a sample space, confirm the channel's files are in the mapped **Google Drive / shared-drive**
location and reachable by the space's members.
Expected: Members can open the channel's content in Drive; the space points at the correct Drive location
per the mapping (file movement itself is the Drive workstream).

## Test 6 — Meetings work on Google Meet
Do: For a sample of the wave's recurring and new meetings, confirm they exist as **Google Meet** events
and join successfully.
Expected: Meetings resolve on Meet for migrated users; re-issued recurring series appear correctly per
`GWCHAT Meetings - Teams to Meet - Transition`.

## Test 7 — Coexistence: cross-platform meetings interop
Do: Create a cross-platform meeting between a migrated user (Meet) and a not-yet-migrated user (Teams);
confirm calendar sync and Meet↔Teams join.
Expected: Both users see the event and can join a single meeting across platforms; free/busy stays
consistent
([Microsoft Learn — calendar syncing with Google Workspace](https://learn.microsoft.com/en-us/microsoftteams/setup-calendar-syncing-with-google-workspace),
[Google Workspace Updates — Meet–Teams interoperability](https://workspaceupdates.googleblog.com/2026/02/meet-hardware-microsoft-teams-intero.html)).

## Test 8 — Rollback is proven available
Do: Review the wave's rollback step and confirm the back-out (users continue on Teams; unfinalized
import-mode spaces discarded; interop keeps them working) is documented and executable.
Expected: A clear rollback exists for the wave; it is invoked only if the gate fails.

## Test 9 — Adoption and coverage reported
Do: Run `GWCHAT-Report.ps1` for the wave/program.
Expected: The report shows spaces created vs mapped, members present, meetings working, and users active
in Chat/Meet — coverage renders without gaps for the wave.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| Wave 0 (pilot) pass | Tests 1-9 pass; the full runbook ran end to end and every runbook defect is fixed in the runbook/mapping/design before expanding |
| Expansion wave pass | Tests 1-9 pass for the wave; the go/no-go gate `GWCHAT Gate - Go/No-Go - Per Wave` is cleared before the next wave starts |
| Program decommission | All waves passed and cleared hypercare, and the Teams source is retained per legal-hold policy, before interop and the source footprint are retired |
