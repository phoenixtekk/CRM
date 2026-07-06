# 6. Troubleshooting Guide — Microsoft Teams → Google Chat & Meet Migration & Coexistence

Use `GWCHAT-Discovery.ps1` for the Teams source baseline, `GWCHAT-Validation.ps1` for per-wave/per-team
readiness, `GWCHAT-Report.ps1` for coverage/adoption, and `GWCHAT-Remediation.ps1` (runs with `-WhatIf`
by default) for safe fixes to wave/space readiness data gaps. The internal errors of a specific
migration tool (a single message, attachment, or space import failure) are diagnosed in that tool's own
docs; this guide covers the **migration**: mapping, spaces, meetings, coexistence, and gates.

## A. Users expected migrated chat history that isn't there
| Symptom | Cause | Remediation |
|---|---|---|
| "My 1:1 chats are gone" | The native channel migration does **not** carry 1:1/private chats | Set the expectation in the adoption comms; if DMs are truly required, choose a third-party tool in the mapping — but the native path never covers them ([Google — import data to Google Chat](https://developers.google.com/workspace/chat/import-data)) |
| "Formatting/links look wrong" | Underlining, message cards, nested lists, Streams/praise/approvals aren't migrated | Expected — not a defect. Confirm it's on the accepted-limits list in `GWCHAT Mapping - Channels to Spaces - Program` ([Google — run a chat migration](https://knowledge.workspace.google.com/admin/migrate/run-a-chat-migration)) |
| "Old messages needed for a legal case are missing" | The migration is a productivity feature, not a compliance archive | Retrieve from the retained Teams source / eDiscovery export; never treat the migrated copy as the archive of record ([Google — set up a chat migration](https://knowledge.workspace.google.com/admin/migrate/set-up-a-chat-migration)) |

## B. A space is stuck in import mode or was deleted
- An import-mode space is hidden from users and must be **finalized within 90 days** or it is deleted and
  unrecoverable. If a space vanished, it likely passed the 90-day window unfinalized — re-run the import
  for that channel and finalize promptly. Never open an import you can't finish; finalizing is one-way
  ([Google — import data to Google Chat](https://developers.google.com/workspace/chat/import-data)).

## C. The import fails partway or won't take all teams
| Symptom | Cause | Remediation |
|---|---|---|
| Import rejects teams beyond a limit | The native tool imports up to **1,000 teams per import** | Split into additional imports; plan the batches in the wave plan rather than discovering the cap mid-cutover ([Google — run a chat migration](https://knowledge.workspace.google.com/admin/migrate/run-a-chat-migration)) |
| Messages won't import for some users | Target users aren't licensed or Chat-enabled | Enable Chat and assign licenses for the wave's users; re-run `GWCHAT-Validation.ps1` (Test 2) |

## D. A space has the wrong or missing members
- The space's roster doesn't match the channel. The mapping's member source is stale or the users weren't
  provisioned. Re-provision the wave's users (GCDS/SCIM), reconcile the roster against
  `GWCHAT Mapping - Channels to Spaces - Program`, and run `GWCHAT-Remediation.ps1` (preview) then
  `GWCHAT-Validation.ps1`.

## E. Cross-platform meetings fail during coexistence
| Symptom | Cause | Remediation |
|---|---|---|
| Migrated and Teams users can't see each other's availability | Calendar sync not live for both directions | Confirm `GWCHAT Meetings - Teams to Meet - Transition` calendar sync is active both ways; re-run Testing Guide Test 7 ([Microsoft Learn — calendar syncing with Google Workspace](https://learn.microsoft.com/en-us/microsoftteams/setup-calendar-syncing-with-google-workspace)) |
| A user can't join the other platform's meeting | Meet↔Teams interop not enabled for the wave | Confirm interop is on for the wave's users ([Google Workspace Updates — Meet–Teams interoperability](https://workspaceupdates.googleblog.com/2026/02/meet-hardware-microsoft-teams-intero.html)) |
| A recurring meeting disappeared at cutover | Recurring Teams series was not re-issued as a Meet series | Re-issue the series on Meet per the meetings-transition design; add recurring-series re-issue to the runbook's readiness so later waves don't repeat it |

## F. A team is split across Chat and Teams mid-conversation
- Users report chat "stops working" between colleagues. The team was split across two waves, and live
  chat does not bridge 1:1 across the platforms during coexistence. Keep teams intact in one wave; if
  already split, accelerate the trailing members' wave to reunite the team, and confirm with
  `GWCHAT-Set-ScopeTargeting.ps1` (preview).

## G. A wave fails its go/no-go gate
| Symptom | Cause | Remediation |
|---|---|---|
| Readiness fails | Users not provisioned/licensed or Chat/Meet not enabled | Fix identity/provisioning and enable Chat/Meet for the wave; re-run `GWCHAT-Validation.ps1` |
| Validation incomplete | Spaces/history/meetings not finished for the wave | Do not pass the gate; complete the outstanding step, then re-run `GWCHAT-Report.ps1` |
| Gate ambiguous | Criteria not defined/owned | Complete `GWCHAT Gate - Go/No-Go - Per Wave` criteria and name the Accountable owner before deciding |

## H. The same problem recurs every wave
- A defect fixed only for one wave will reappear. Fix the **runbook**, the mapping, or the meetings design
  — not just the wave — so later waves inherit the fix (Implementation Step 7). Recurring issues are
  almost always an un-fixed runbook, not bad luck.

## I. A cutover needs to be reversed
- The wave failed validation. Invoke the runbook's rollback: the wave's users continue on Teams for chat
  and meetings, unfinalized import-mode spaces are discarded, and interop keeps them working. Rollback is
  only used when the gate fails — confirm it was tested (Testing Guide Test 8).

## J. Graph scripts fail to connect
- `GWCHAT-Discovery.ps1`, `GWCHAT-Validation.ps1`, `GWCHAT-Report.ps1`, and
  `GWCHAT-Set-ScopeTargeting.ps1` use Microsoft Graph against the source Microsoft Teams / Microsoft 365
  tenant. If connection fails, confirm the Microsoft Graph PowerShell SDK is installed and the signed-in
  account holds the read scopes the script requests (consent on first run). Re-run after consent.

## K. Diagnostics quick reference
```powershell
.\GWCHAT-Discovery.ps1                                        # Teams estate baseline for mapping/waves
.\GWCHAT-Set-ScopeTargeting.ps1 -GroupName "..." -MembersCsv .\wave.csv     # -WhatIf by default
.\GWCHAT-Validation.ps1 -Wave "Wave 1" -MembersCsv .\wave.csv               # per-wave readiness
.\GWCHAT-Report.ps1 -MappingCsv .\gwchat-mapping.csv                        # coverage/adoption
.\GWCHAT-Remediation.ps1 -MembersCsv .\wave.csv                             # -WhatIf by default
```

## L. When to escalate
If a wave's users are provisioned, licensed, and Chat/Meet-enabled, the mapping is correct, and
validation still reports gaps after remediation, capture the `GWCHAT-Validation.ps1` and
`GWCHAT-Report.ps1` output and review the wave with the identity, migration-tooling, and meetings owners
at the program cadence before passing the go/no-go gate.
