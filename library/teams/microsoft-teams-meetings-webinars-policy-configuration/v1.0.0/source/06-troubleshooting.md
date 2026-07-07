# 6. Troubleshooting

Common failure modes when configuring Teams meetings, webinars, and policy assignment — each with the
likely root cause and the fix. Reuse the reference-model names. Reconnect if needed
(`Connect-MicrosoftTeams`; `Connect-MgGraph -Scopes 'Group.Read.All','User.Read.All'`).

---

## A policy change "isn't taking effect" for users
- **Most likely: propagation delay.** New/changed meeting or events policies and group assignments can
  take minutes (occasionally longer) to reach clients. **Wait and retest**, and have the user fully
  restart Teams.
- **Or: the user isn't actually assigned the policy you think.** Check the **effective** policy, not the
  policy definition: `Get-CsUserPolicyAssignment -Identity <user> -PolicyType TeamsMeetingPolicy` (or
  `TEAMSMTG-Validation.ps1 -SampleGroup ...`). If it resolves to Global, the group assignment didn't
  apply to them.
- **Or: you edited the wrong policy.** Confirm you changed the policy the user is assigned, not a
  similarly named one. Names matter — use the exact reference-model names.

## A user gets the wrong policy (multiple groups)
- **Root cause:** the user is in **more than one** assigned group, and group assignments resolve by
  **Rank** — the **lowest-Rank** (highest-precedence) assignment for that policy type wins.
- **Fix:** review ranks with `Get-CsGroupPolicyAssignment -PolicyType TeamsMeetingPolicy` (or
  `TEAMSMTG-AssignmentReport.ps1`), and set ranks so the intended policy wins. If a user needs an
  explicit exception, use a direct `Grant-CsTeamsMeetingPolicy -Identity <user>` (per-user overrides
  group assignment).

## Anonymous users still join when you disabled it (or can't when you allowed it)
- **Root cause:** anonymous join is a **two-layer** control. `Set-CsTeamsMeetingConfiguration -Identity
  Global -DisableAnonymousJoin` is the **org master switch**; the per-policy
  `-AllowAnonymousUsersToJoinMeeting` only refines what the org permits.
- **Fix:** confirm the org switch first (`Get-CsTeamsMeetingConfiguration -Identity Global | Select
  DisableAnonymousJoin`), then the policy. If the org switch disables anonymous join, no policy can
  re-enable it. Allow propagation after changing either.

## Lobby lets in people it shouldn't (or holds everyone)
- **Root cause:** the effective policy's `-AutoAdmittedUsers` doesn't match intent, or the meeting was
  created **before** the policy change and kept its old settings.
- **Fix:** verify the organizer's effective policy value, and test with a **newly scheduled** meeting.
  Remember the organizer can also change lobby options **per meeting** (unless a Teams Premium template
  locks them) — a locked template is the way to enforce it.

## Presenter role isn't enforced — attendees can still share
- **Root cause:** `-DesignatedPresenterRoleMode` on the effective policy isn't the restrictive mode you
  expect, or the meeting predates the change, or the organizer promoted the attendee to presenter.
- **Fix:** confirm the effective policy mode; test with a fresh meeting; check the meeting's participant
  roles. For guaranteed enforcement on sensitive meetings, lock it via a Teams Premium template.

## Recording or transcription button is missing (or unexpectedly present)
- **Root cause:** the effective policy's `-AllowCloudRecording` / `-AllowTranscription` value, or a
  meeting created before the change.
- **Fix:** verify the effective policy; test with a new meeting. Note both organizer and the recording
  initiator's policy can matter — verify the person trying to record has the expected policy.

## Recording succeeds but the file is missing / in the wrong place
- **Root cause:** recordings go to **OneDrive** (non-channel meetings, organizer's OneDrive) or
  **SharePoint** (channel meetings, team site) — **not** a separate service. If the organizer has **no
  OneDrive provisioned** or is **out of quota**, recording can fail or have nowhere to land.
- **Fix:** confirm the organizer has OneDrive licensed/provisioned with quota (§2.5). For channel
  meetings, check the team's SharePoint site. Check `-NewMeetingRecordingExpirationDays` and any
  OneDrive/SharePoint **retention** — the stricter of expiration vs retention governs; coordinate with
  compliance.

## Webinar or town hall creation is blocked (or wrongly allowed)
- **Root cause:** the effective **events policy** (`Events Policy – Standard/Restricted – Prod`) stance
  (`-AllowWebinars` / `-AllowTownhalls`) for that user, or the assignment didn't propagate.
- **Fix:** `Get-CsTeamsEventsPolicy` for the definition and `Get-CsUserPolicyAssignment -PolicyType
  TeamsEventsPolicy -Identity <user>` for the effective assignment. Confirm the cohort's events-policy
  group assignment exists and has propagated.

## `Set-CsTeamsEventsPolicy` / template cmdlet fails on a parameter
- **Root cause:** events-policy and meeting-template cmdlet **parameters and accepted values are
  version-dependent** — a parameter valid in one module/tenant version may not exist in another.
- **Fix:** run `Get-Help Set-CsTeamsEventsPolicy -Full` (and update the **MicrosoftTeams** module),
  confirm the exact parameters/values for your version, and adjust. Do **not** guess parameter names —
  verify in your tenant. For templates, prefer the **Teams admin center** and verify the current
  PowerShell template cmdlet names.

## Meeting template doesn't appear for a user
- **Root cause (most common): no Teams Premium.** Templates, sensitivity labels on meetings, watermark,
  and prevent-copy require **Teams Premium** on the **organizer** — without it the template silently
  does not appear. Or: the template policy isn't published to that user.
- **Fix:** verify Teams Premium licensing (§2.1); verify the template policy is published to the user's
  cohort. A **non-Premium** user not seeing the template is **expected**, not a bug.

## Sensitivity label can't be attached to the template
- **Root cause:** the label isn't **published** to the relevant users in **Microsoft Purview**, or the
  operator lacks the Purview label role.
- **Fix:** confirm with the **compliance owner** that `Sensitivity Label – Confidential – Meeting` (use
  the real name) is created and published. **Do not create or redefine the label** — its meaning and
  protections are the compliance owner's determination.

## `Connect-MicrosoftTeams` or Graph fails / wrong cloud
- **Root cause:** wrong cloud environment, missing module, or insufficient role.
- **Fix:** for **Government** clouds connect with the correct environment
  (`Connect-MicrosoftTeams -TeamsEnvironmentName TeamsGCCH` / `TeamsDOD` — **verify the value for your
  cloud**); ensure the **MicrosoftTeams** module is installed/updated (`Install-Module MicrosoftTeams`)
  and the operator holds **Teams Administrator**. For Graph, connect with
  `-Scopes 'Group.Read.All','User.Read.All'`.

## Rolling back safely
- **Un-assign the group first** — fastest restore of the prior experience:
  `Remove-CsGroupPolicyAssignment -GroupId <id> -PolicyType TeamsMeetingPolicy`. Users fall back to
  their next-ranked assignment or **Global**.
- **Revert a per-user grant:** `Grant-CsTeamsMeetingPolicy -Identity <user> -PolicyName $null`.
- **A custom policy left unassigned affects no one** — you can leave it in place. Only
  `Remove-CsTeamsMeetingPolicy` once no assignment references it.
- **Never delete a policy that still has assignments**, and coordinate any label/template change with
  the compliance owner.
