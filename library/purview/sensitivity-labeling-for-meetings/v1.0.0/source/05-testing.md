# 5. Testing Guide — Sensitivity Labeling for Meetings (Microsoft Purview)

Run after each configuration step. Every test is safe (read-only or a `-WhatIf` preview) except where it
asks you to observe real behavior on a labeled meeting. Validate on the `Meeting Labels – Pilot Ring –
Stage1` before treating the tenant as production-ready.

## Test 1 — Prerequisites and enablement are in place
**Do:** Run `IPMEET-Check-Prereqs.ps1`.
**Expected:** ExchangeOnlineManagement + MicrosoftTeams modules present and connected; Information
Protection Admin / Teams Admin roles reported; the Teams-Premium and **Meetings-scope** signals reported;
any Meetings-scoped labels that already exist are listed. Every gap (e.g. Teams Premium missing →
Premium-only controls deferred) is **recorded, not guessed**.

## Test 2 — Discovery inventory and Teams baseline are complete
**Do:** Run `IPMEET-Discover.ps1`; spot-check the Teams meeting policy in the Teams admin center.
**Expected:** Every sensitivity label is listed with whether it is **scoped to Meetings**; the label
policies publishing them are listed; the Teams meeting-policy baseline (lobby / `AutoAdmittedUsers`,
recording / `AllowCloudRecording`, chat / `MeetingChatEnabledType`) is reported and matches the admin
center.

## Test 3 — Label create dry-run makes no changes
**Do:** Run `IPMEET-Set-MeetingLabel.ps1 -Action CreateLabels -WhatIf`.
**Expected:** It states which labels it *would* create and changes nothing; `Get-Label` afterward shows
no new labels until `-Commit`.

## Test 4 — Meeting labels exist with the Meetings scope and are published
**Do:** Run `Get-Label | Format-Table DisplayName, Name, ContentType` and `Get-LabelPolicy`; as a pilot
user, start scheduling a new Teams meeting.
**Expected:** The three meeting labels exist and carry the **Meetings** scope; `Meeting Labels – Policy`
is published to the pilot users; the labels appear in the meeting-scheduling UI for a policy member and
**not** for a non-member.

## Test 5 — Publish dry-run makes no changes and is reversible
**Do:** Run `IPMEET-Set-MeetingLabel.ps1 -Action PublishPolicy -PolicyMembers "MeetingLabels-Pilot@contoso.com" -WhatIf`.
**Expected:** The dry-run states the policy/label/membership it *would* set plus the reverse action; a
follow-up `Get-LabelPolicy` shows the policy unchanged — `-WhatIf` truly changed nothing.

## Test 6 — Validation gate passes on the pilot ring
**Do:** Run `IPMEET-Validate.ps1`.
**Expected:** PASS for each gate — every intended label exists with the Meetings scope, is published in
`Meeting Labels – Policy` to the pilot users, and the Teams baseline is compatible with the taxonomy. Any
FAIL names the specific missing object.

## Test 7 — Lobby is governed by the label
**Do:** As a pilot organizer, schedule a `Meeting – Highly Confidential` meeting and have an **external**
attendee attempt to join.
**Expected:** The external attendee is **held in the lobby** (only organizers & co-organizers bypass);
on a `Meeting – General` meeting the same attendee is admitted per the tenant default. (Verify the exact
lobby behavior against your Teams configuration.)

## Test 8 — Recording is governed by the label
**Do:** Join a `Meeting – Highly Confidential` meeting and attempt to start recording; repeat on a
`Meeting – Confidential` meeting as a non-organizer.
**Expected:** Recording is **prevented** on the Highly Confidential tier; on the Confidential tier a
non-organizer cannot start recording (organizers & co-organizers only). Requires Teams Premium — record
as deferred if Premium is not licensed.

## Test 9 — Chat and copy are governed by the label
**Do:** In a `Meeting – Highly Confidential` meeting, check the chat; in a `Meeting – Confidential`
meeting, attempt to copy chat content.
**Expected:** Chat is **off** (or in-meeting only) on the Highly Confidential tier; copying chat content
is **prevented** on the Confidential and Highly Confidential tiers.

## Test 10 — Invite protection and content protection
**Do:** Inspect the calendar invite of a `Meeting – Confidential` meeting; share content in a
`Meeting – Highly Confidential` meeting.
**Expected:** The invite is **encrypted/protected** per the tier; a **watermark** appears on shared
content/video and (where configured) **end-to-end encryption** is active on the Highly Confidential tier
(Teams Premium). Record as deferred where Premium is unavailable.

## Test 11 — Reporting evidence is produced
**Do:** Run `IPMEET-Report.ps1 -CsvPath .\MeetingLabelsReport.csv`.
**Expected:** `Meeting Labels – Coverage Report` lists each meeting label, its scope, and its
publication/target coverage — usable as the management evidence artifact and re-runnable on a schedule.

---
### Pass/fail summary
All gates green on `Meeting Labels – Pilot Ring – Stage1` — labels exist with the Meetings scope, are
published to the pilot, lobby/recording/chat/copy/invite behavior matches each tier on a real meeting,
and the coverage report is produced — before expanding to the estate. Any deferred (Premium-gated)
control is recorded explicitly, not silently skipped.
