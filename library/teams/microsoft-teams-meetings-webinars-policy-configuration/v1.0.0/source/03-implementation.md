# 3. Implementation

Follow these steps in order. They implement the house model **Assess → Design → Configure → Pilot →
Validate → Expand**. Every artifact is named per the reference model and reused verbatim. Meeting,
events, and assignment changes are **high-impact** (they change every affected user's meeting
experience) — do them under change control, **pilot-first**, with the rollback in §3.11 ready.

> **Connect once, correctly.** All PowerShell below uses modern auth — no stored credentials:
> ```powershell
> Connect-MicrosoftTeams          # Commercial. For Government, add -TeamsEnvironmentName
>                                 # (e.g. TeamsGCCH / TeamsDOD) — verify the value for your cloud.
> Connect-MgGraph -Scopes 'Group.Read.All','User.Read.All'   # for group membership / effective policy
> ```
> Admin center: **admin.teams.microsoft.com** (Government: verify the `*.office365.us` equivalent).

---

## 3.0 Assess — capture the current posture (read-only)
1. Run the discovery script to snapshot today's state into `Meeting Posture – Teams – Discovery`:
   ```powershell
   .\TEAMSMTG-Discovery.ps1 -CsvFolder .\posture
   ```
   It enumerates every **meeting policy** (`Get-CsTeamsMeetingPolicy`), the **events policy**
   (`Get-CsTeamsEventsPolicy`), the org **meeting configuration** (`Get-CsTeamsMeetingConfiguration`),
   recording/storage-relevant settings, and existing **group policy assignments**
   (`Get-CsGroupPolicyAssignment`).
2. **Gate G0 (baseline captured):** you have a CSV of current policies and assignments, and the
   security/collaboration owners have signed off the **target baseline** per §2.4. If not, stop and get
   the baseline first — do not configure against assumptions.

## 3.1 Design — decide the policy set (no changes yet)
Design a **small** set rather than editing Global destructively:

| Cohort | Policy name | Lobby (`-AutoAdmittedUsers`) | Anonymous join | Recording | Presenter role |
|---|---|---|---|---|---|
| Most staff | `Meeting Policy – Standard – Prod` | `EveryoneInCompanyExcludingGuests` | Off | On | `EveryoneUserOverride` |
| Execs / sensitive | `Meeting Policy – Exec – Prod` | `OrganizerOnly` (or `InvitedUsers`) | Off | Off (or On per policy) | `OrganizerOnlyUserOverride` |
| Frontline / external-facing | `Meeting Policy – Restricted – Prod` | `EveryoneInCompany` | Off | Off | `EveryoneInCompanyUserOverride` |
| Everyone unassigned | **Global (Org-wide default)** | `EveryoneInCompanyExcludingGuests` | Off | per org baseline | `EveryoneUserOverride` |

> The exact values are **your** baseline decisions (§2.4) — the table shows a defensible default set.
> `-AutoAdmittedUsers` accepts values including `EveryoneInCompanyExcludingGuests`, `EveryoneInCompany`,
> `Everyone`, `OrganizerOnly`, `InvitedUsers`, and `EveryoneInSameAndFederatedCompany` — **verify the
> exact accepted set for your tenant version**. Presenter-role modes include `EveryoneUserOverride`,
> `EveryoneInCompanyUserOverride`, and `OrganizerOnlyUserOverride`.

Also design the **events policy** (`Events Policy – Standard – Prod` vs `Events Policy – Restricted –
Prod`) and, if Teams Premium is licensed, the **template** (`Meeting Template – Confidential – Prod`)
and its **sensitivity label** (`Sensitivity Label – Confidential – Meeting`, defined by compliance).

## 3.2 Configure — org-wide meeting settings (`Meeting Config – Org – Prod`)
Some controls sit **above** per-policy settings, org-wide:
1. Preview, then set the org meeting configuration — notably anonymous join:
   ```powershell
   # Preview
   Set-CsTeamsMeetingConfiguration -Identity Global -DisableAnonymousJoin $true -WhatIf
   # Apply (this is the org master switch for anonymous join)
   Set-CsTeamsMeetingConfiguration -Identity Global -DisableAnonymousJoin $true
   ```
2. **Layered model to keep straight:** `Set-CsTeamsMeetingConfiguration -DisableAnonymousJoin` is the
   **org master switch**; the per-policy `-AllowAnonymousUsersToJoinMeeting` (§3.3) only takes effect if
   the org switch permits it. Decide the org stance first.
3. **Gate G1 (org settings applied):** `Get-CsTeamsMeetingConfiguration` shows the intended
   `DisableAnonymousJoin`. Anonymous join now behaves per the org decision.

## 3.3 Configure — build the meeting policies (safe, idempotent)
Use the configuration script in preview mode first, then commit. It creates any missing policy and
updates drift on existing ones; it never deletes.
1. **Preview** the full policy set (no changes):
   ```powershell
   .\TEAMSMTG-Set-MeetingPolicy.ps1 -WhatIf
   ```
2. **Commit** the policies:
   ```powershell
   .\TEAMSMTG-Set-MeetingPolicy.ps1 -Commit
   ```
   Under the hood each policy is created/tuned with real parameters, e.g. the Exec policy:
   ```powershell
   New-CsTeamsMeetingPolicy -Identity 'Meeting Policy – Exec – Prod' -ErrorAction SilentlyContinue
   Set-CsTeamsMeetingPolicy  -Identity 'Meeting Policy – Exec – Prod' `
     -AutoAdmittedUsers 'OrganizerOnly' `
     -AllowAnonymousUsersToJoinMeeting $false `
     -AllowPSTNUsersToBypassLobby $false `
     -AllowCloudRecording $false `
     -AllowTranscription $false `
     -DesignatedPresenterRoleMode 'OrganizerOnlyUserOverride' `
     -NewMeetingRecordingExpirationDays 30
   ```
3. Also tune the **Global (Org-wide default)** policy to the safe baseline so unassigned users are
   covered (the script does this when `-IncludeGlobal` is passed).
4. **Gate G2 (policies exist and match design):** `Get-CsTeamsMeetingPolicy | Format-Table Identity,
   AutoAdmittedUsers, AllowCloudRecording, DesignatedPresenterRoleMode` shows each named policy with the
   designed values. No user is assigned yet — safe to proceed.

## 3.4 Configure — webinars & town halls (`Events Policy – Standard – Prod`)
1. Preview then create/tune the events policy:
   ```powershell
   .\TEAMSMTG-Set-EventsAndTemplates.ps1 -WhatIf
   .\TEAMSMTG-Set-EventsAndTemplates.ps1 -Commit
   ```
   Which applies, e.g.:
   ```powershell
   New-CsTeamsEventsPolicy -Identity 'Events Policy – Standard – Prod' -ErrorAction SilentlyContinue
   Set-CsTeamsEventsPolicy -Identity 'Events Policy – Standard – Prod' `
     -AllowWebinars 'Enabled' -AllowTownhalls 'Enabled'
   # Restricted cohort: no external webinars
   Set-CsTeamsEventsPolicy -Identity 'Events Policy – Restricted – Prod' `
     -AllowWebinars 'Disabled' -AllowTownhalls 'Disabled'
   ```
   > Parameter names/values for the events policy are **version-dependent** (e.g. attendee-access and
   > event-integration parameters have evolved) — the script sets the widely-available
   > `-AllowWebinars` / `-AllowTownhalls`; **verify the exact parameters for your tenant version** and
   > extend as needed.
2. **Legacy live events (only if still used):** where an org still runs classic **Teams live events**,
   configure `Set-CsTeamsMeetingBroadcastPolicy`. Microsoft is steering live events toward **town
   halls** — treat live events as legacy and prefer town halls for new work. *(Verify the retirement
   timeline for your cloud.)*
3. **Gate G3 (events policy correct):** `Get-CsTeamsEventsPolicy` shows the intended webinar/town-hall
   stance per cohort.

## 3.5 Configure — meeting templates + sensitivity (Teams Premium — flag & verify)
> **Licensing gate:** this whole step requires **Teams Premium** on the organizer (§2.1). If Premium is
> not licensed, **skip to §3.6** and record templates as deferred.
1. In the **Teams admin center** → **Meetings** → **Meeting templates**, create
   `Meeting Template – Confidential – Prod`. Set the template's locked options (e.g. force lobby to
   `OrganizerOnly`, disable recording, restrict who can present).
2. Attach the **sensitivity label** `Sensitivity Label – Confidential – Meeting` — using the exact label
   the **compliance owner** published in Purview (§2.6). The label's meeting protections (watermark,
   prevent copy, encryption) are **the compliance owner's determination**; you attach, you do not define.
3. Publish the template to the right cohort with a **template policy** (Teams admin center; PowerShell
   exposes template configuration/visibility cmdlets whose exact names are **version-dependent** —
   verify in your tenant, e.g. `Get-CsTeamsMeetingTemplateConfiguration` and the template policy
   cmdlets).
4. **Gate G4 (template visible where intended):** a pilot organizer with Premium sees
   `Meeting Template – Confidential – Prod` when scheduling; a non-Premium user does not (expected).

## 3.6 Pilot — assign policies to the pilot group only
Do **not** assign to production cohorts yet.
1. Create the pilot copy `Meeting Policy – Standard – Pilot` (the config script created it) and assign
   it to `Meeting Scope – Pilot – Group` by **group assignment**:
   ```powershell
   .\TEAMSMTG-AssignmentReport.ps1 -AssignGroup 'Meeting Scope – Pilot – Group' `
     -PolicyType TeamsMeetingPolicy -PolicyName 'Meeting Policy – Standard – Pilot' -Rank 1 -WhatIf
   # then -Commit to apply
   ```
   Which wraps:
   ```powershell
   $g = Get-MgGroup -Filter "displayName eq 'Meeting Scope – Pilot – Group'"
   New-CsGroupPolicyAssignment -GroupId $g.Id -PolicyType TeamsMeetingPolicy `
     -PolicyName 'Meeting Policy – Standard – Pilot' -Rank 1
   ```
2. Assign the pilot **events policy** the same way (`-PolicyType TeamsEventsPolicy`).
3. **Gate G5 (pilot assigned):** `Get-CsGroupPolicyAssignment -GroupId $g.Id` lists the pilot
   assignments. Allow time to propagate (minutes; occasionally longer).

## 3.7 Validate the pilot (see §5 for full procedures)
1. Run validation against the pilot users:
   ```powershell
   .\TEAMSMTG-Validation.ps1 -SampleGroup 'Meeting Scope – Pilot – Group' -CsvPath .\pilot-validation.csv
   ```
2. With pilot users, **schedule and start a real meeting** and confirm the lobby, recording,
   transcription, and presenter behavior match the assigned policy, and (if Premium) that the template
   and sensitivity label appear and enforce.
3. **Gate G6 (pilot passes):** every validation row is **PASS** and the live-meeting behavior matches
   design. If any fail, fix and re-pilot — **do not expand**.

## 3.8 Expand — assign production cohorts in waves
1. Assign each production policy to its group, ranked so multi-group users resolve deterministically
   (**lower Rank = higher precedence**):
   ```powershell
   .\TEAMSMTG-AssignmentReport.ps1 -AssignGroup 'Meeting Scope – Exec – Group' `
     -PolicyType TeamsMeetingPolicy -PolicyName 'Meeting Policy – Exec – Prod' -Rank 1 -Commit
   .\TEAMSMTG-AssignmentReport.ps1 -AssignGroup 'Meeting Scope – Standard – Group' `
     -PolicyType TeamsMeetingPolicy -PolicyName 'Meeting Policy – Standard – Prod' -Rank 2 -Commit
   ```
   This creates the `Meeting Assignment – Exec – Group` (etc.) assignments. Assign the matching **events
   policies** similarly.
2. Expand in **waves** (e.g. exec cohort, then standard, then restricted), validating after each wave.
3. **Gate G7 (production assigned & effective):** `TEAMSMTG-AssignmentReport.ps1` shows the intended
   **effective policy per sampled user**, and each wave passes §5 validation before the next.

## 3.9 Confirm recording storage & expiration
1. With a recording-enabled cohort, record a test meeting and confirm the recording lands in the
   organizer's **OneDrive** (non-channel) or the team's **SharePoint** site (channel meeting), and that
   `-NewMeetingRecordingExpirationDays` is reflected on the file's expiration.
2. **Gate G8 (storage correct):** the recording is in the expected OneDrive/SharePoint location with the
   expected expiration. Coordinate any conflicting OneDrive/SharePoint retention with the compliance
   owner.

## 3.10 Document & hand over
Record the final policy set, events policy, template/label, group assignments and ranks, and the
`Meeting Validation – Teams – Report` in the runbook (`ADMIN_DOCS`). Note the cloud (Commercial vs
Government) and any Premium-gated features that were deferred.

## 3.11 Rollback (have this ready before you start)
Because policy/assignment changes are reversible, rollback is clean:
- **Un-assign a group policy** (revert a cohort to Global/previous):
  ```powershell
  Remove-CsGroupPolicyAssignment -GroupId $g.Id -PolicyType TeamsMeetingPolicy
  ```
  Users fall back to their next-ranked assignment or the **Global** default.
- **Revert a per-user assignment** to Global: `Grant-CsTeamsMeetingPolicy -Identity <user> -PolicyName $null`.
- **Revert org anonymous stance:** `Set-CsTeamsMeetingConfiguration -Identity Global -DisableAnonymousJoin $false`.
- **A custom policy left unassigned affects no one** — you can safely leave it in place or remove it
  with `Remove-CsTeamsMeetingPolicy -Identity '<name>'` once no assignment references it.
- **Templates/labels:** unpublish the template policy to hide the template; the sensitivity label is
  owned by compliance — coordinate any change with them.
> Roll back **assignments first** (fastest way to restore the prior experience), then policies. Never
> delete a policy that still has assignments.
