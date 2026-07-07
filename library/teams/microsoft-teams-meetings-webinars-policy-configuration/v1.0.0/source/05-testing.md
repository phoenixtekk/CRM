# 5. Testing & Validation

Run these after each pilot/expand wave. Each test has an explicit **pass/fail**. Most are read-only via
`TEAMSMTG-Validation.ps1`; the live-meeting tests require actually scheduling and joining a meeting,
which is the only way to prove the runtime experience. Reuse the reference-model names throughout.

> Reconnect if needed: `Connect-MicrosoftTeams` (Government: add `-TeamsEnvironmentName`) and
> `Connect-MgGraph -Scopes 'Group.Read.All','User.Read.All'`.

---

## Test 1 — Named policies exist and match design
- **How:** `Get-CsTeamsMeetingPolicy | Format-Table Identity, AutoAdmittedUsers, AllowAnonymousUsersToJoinMeeting, AllowCloudRecording, AllowTranscription, DesignatedPresenterRoleMode, NewMeetingRecordingExpirationDays`
- **Pass:** `Meeting Policy – Standard – Prod`, `– Exec – Prod`, `– Restricted – Prod`, and the pilot
  policy exist, each with the values from the §3.1 design table.
- **Fail:** a policy is missing or a value differs → re-run `TEAMSMTG-Set-MeetingPolicy.ps1 -Commit`.

## Test 2 — Org anonymous-join stance applied
- **How:** `Get-CsTeamsMeetingConfiguration -Identity Global | Select-Object DisableAnonymousJoin`
- **Pass:** `DisableAnonymousJoin` matches the org decision (`Meeting Config – Org – Prod`).
- **Fail:** value differs → re-apply `Set-CsTeamsMeetingConfiguration` (§3.2).

## Test 3 — Group assignments present and ranked
- **How:** `Get-CsGroupPolicyAssignment -PolicyType TeamsMeetingPolicy | Format-Table GroupId, PolicyName, Rank`
  (resolve GroupId to name via `Get-MgGroup`).
- **Pass:** each cohort group is assigned its intended policy at the intended **Rank** (lower = higher
  precedence); the pilot assignment exists during pilot.
- **Fail:** missing/duplicate assignment or wrong rank → fix with the assignment helper (§3.6/§3.8).

## Test 4 — Effective policy per user is correct
- **How:** `Get-CsUserPolicyAssignment -Identity <pilotUser> -PolicyType TeamsMeetingPolicy` (or
  `TEAMSMTG-Validation.ps1 -SampleGroup 'Meeting Scope – Pilot – Group'`).
- **Pass:** each sampled user's **effective** meeting policy is the one their highest-ranked group
  assignment grants (or Global if unassigned by design).
- **Fail:** a user resolves to the wrong policy → check group membership and assignment ranks (a
  higher-ranked group can win unexpectedly).

## Test 5 — Lobby behaves as configured (live)
- **How:** As a pilot organizer, schedule a meeting; have an **external/anonymous** person and an
  **internal** person try to join early.
- **Pass:** admission matches `-AutoAdmittedUsers` (e.g. Exec = organizer-only → external waits in
  lobby; internal per policy). Anonymous join follows the org + policy stance.
- **Fail:** someone bypasses the lobby who shouldn't → recheck the effective policy (Test 4) and the org
  anonymous switch (Test 2), allow propagation time, retest.

## Test 6 — Recording & transcription follow policy (live)
- **How:** In a meeting held under each cohort's policy, attempt **Record** and **Transcribe**.
- **Pass:** recording/transcription are available only where `-AllowCloudRecording` /
  `-AllowTranscription` are `$true`; unavailable where `$false`.
- **Fail:** a control is available/unavailable against policy → confirm the meeting was held under the
  expected effective policy and propagation completed.

## Test 7 — Presenter role enforced (live)
- **How:** In a meeting, have an **attendee** attempt to share screen / manage participants.
- **Pass:** presenter capability matches `-DesignatedPresenterRoleMode` (e.g. organizer-only mode blocks
  attendee sharing until promoted).
- **Fail:** attendees can present against policy → recheck effective policy and retest after propagation.

## Test 8 — Webinars & town halls governed
- **How:** As a **Standard** cohort user, attempt to create a **webinar** and a **town hall**; repeat as
  a **Restricted** cohort user.
- **Pass:** creation matches `Events Policy – Standard – Prod` (allowed) vs `Events Policy – Restricted –
  Prod` (blocked). `Get-CsTeamsEventsPolicy` shows the intended stance.
- **Fail:** creation allowed/blocked against policy → verify the events-policy assignment for that
  cohort and propagation.

## Test 9 — Meeting template + sensitivity (Teams Premium only)
- **How:** As a **Premium** pilot organizer, schedule using `Meeting Template – Confidential – Prod`;
  confirm the template appears and its locked options + the `Sensitivity Label – Confidential – Meeting`
  protections apply. As a **non-Premium** user, confirm the template does not appear.
- **Pass:** Premium organizer sees and can apply the template with its label; non-Premium does not
  (expected licensing behavior).
- **Fail:** template missing for a Premium user → recheck the template policy publication and Premium
  licensing (§2.1); do **not** assume it should appear without Premium.

## Test 10 — Recording lands in the right place with expiration
- **How:** Record a test meeting under a recording-enabled policy (non-channel and channel).
- **Pass:** non-channel recording is in the organizer's **OneDrive**, channel recording in the team's
  **SharePoint** site; the file's expiration reflects `-NewMeetingRecordingExpirationDays`.
- **Fail:** recording missing or in the wrong location / no expiration → confirm the organizer's
  OneDrive is provisioned (§2.5) and the policy's expiration value; coordinate conflicting retention
  with compliance.

## Test 11 — No unintended blast radius
- **How:** Sample **unassigned** users: `Get-CsUserPolicyAssignment -Identity <user> -PolicyType
  TeamsMeetingPolicy`.
- **Pass:** users not in any assigned cohort resolve to the **Global** baseline you tuned — no surprise
  policy from a stray assignment.
- **Fail:** an unassigned user has an unexpected policy → find and remove the stray group/user
  assignment.

---

### Validation report
`TEAMSMTG-Validation.ps1` emits the `Meeting Validation – Teams – Report` (CSV) with a row per check and
a PASS/FAIL column. **All rows PASS + the live tests (5–10) confirmed** is the gate to expand to the
next wave.
