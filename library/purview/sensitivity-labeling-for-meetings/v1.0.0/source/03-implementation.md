# 3. Implementation Guide — Sensitivity Labeling for Meetings (Microsoft Purview)

Follow these steps in order. The model is **Assess → Design → Configure → Pilot → Validate → Expand**.
Every write is **piloted on the `Meeting Labels – Pilot Ring – Stage1` first**, previewed with `-WhatIf`,
and reversible. Named objects are introduced once and reused everywhere:

| Object | Name |
|---|---|
| Meeting labels | `Meeting – General`, `Meeting – Confidential`, `Meeting – Highly Confidential` |
| Label policy | `Meeting Labels – Policy` |
| Pilot ring (users) | `Meeting Labels – Pilot Ring – Stage1` |
| Scope/design map | `Meeting Scope – Map` |
| Coverage report | `Meeting Labels – Coverage Report` |

> **Complete the meeting-protection settings in the portal.** The label/policy **lifecycle** (create,
> publish, add-to-policy) is scriptable and is what the provided tools automate safely. The
> **meeting-option protection settings themselves** — who bypasses the lobby, presenter, recording,
> chat mode, copy-prevention, watermark, end-to-end encryption — are configured on the label in the
> **Purview portal** (they require Teams Premium and depend on the evolving meeting-label surface).
> Author the label's meeting settings in the portal as described in Step 3; use the scripts for the
> safe, repeatable lifecycle and for validation/reporting. **Verify each setting's availability against
> your licensing/tenant.**

## Step 0 — Connect (all steps)
Open PowerShell 5.1+ or 7+ and connect with a modern-auth/MFA admin:
```powershell
Connect-IPPSSession                 # Security & Compliance PowerShell (labels + policies)
Connect-MicrosoftTeams              # Teams meeting-policy baseline (read-only here)
```
Keep credentials out of scripts — sign in interactively. **Pass/fail:** both connections succeed and
`Get-Label` / `Get-CsTeamsMeetingPolicy` return without error.

## Step 1 — Assess current state (Assess)
1. Run `IPMEET-Discover.ps1`. Read-only, it reports: every sensitivity label and **whether any is
   scoped to Meetings**, the label policies that publish them, and the **Teams meeting-policy baseline**
   (lobby / `AutoAdmittedUsers`, recording / `AllowCloudRecording`, chat / `MeetingChatEnabledType`).
2. Run `IPMEET-Check-Prereqs.ps1`. It confirms modules/connections, the roles, the Teams-Premium and
   Meetings-scope signals, and whether meeting labels already exist — PASS/GAP per signal.
3. Record every GAP against the Requirements checklist and remediate before configuring.
   **Pass/fail:** the discovery inventory and prereq report complete; the Teams baseline is captured in
   `Meeting Scope – Map`.

## Step 2 — Design the meeting label taxonomy (Design)
1. With your compliance/security/HR/legal stakeholders, confirm the three-tier taxonomy from the Solution
   Overview and the concrete settings per tier (lobby, chat, copy, recording, content protection).
2. Map your in-scope **meeting types** to tiers (e.g. board & M&A → `Meeting – Highly Confidential`;
   internal-confidential project calls → `Meeting – Confidential`; everyday meetings → `Meeting –
   General`). Record the mapping and the Teams baseline in `Meeting Scope – Map`.
3. Confirm which controls your licensing supports (Teams Premium for recording-control / watermark /
   E2EE); mark any unsupported control **deferred** rather than designing around an unavailable feature.
   **Pass/fail:** `Meeting Scope – Map` is agreed and signed off; the determination of which meeting is
   which tier is owned by stakeholders, not by IT.

## Step 3 — Author and publish the meeting labels (Configure)
Do this **for the pilot first** — publish only to `Meeting Labels – Pilot Ring – Stage1`.

1. **Create the labels (portal).** Purview portal → **Information Protection → Sensitivity labels →
   Create a label**. For each tier, set the name/tooltip and choose the scope **Meetings and calendar
   events** (verify the exact scope wording for your tenant). On the meeting-settings page configure:
   - **Lobby** — who can bypass the lobby (`Meeting – Confidential` = people in my organization;
     `Meeting – Highly Confidential` = only organizers & co-organizers).
   - **Meeting chat** — on / in-meeting only / off, per tier; **prevent copying chat content** for the
     Confidential and Highly Confidential tiers.
   - **Recording** — allow / limit to organizers / prevent, per tier.
   - **Content protection (Teams Premium)** — **watermark** and **end-to-end encryption** for
     `Meeting – Highly Confidential`; **encrypt the meeting invite** where the tier calls for it.

   You can scaffold the **label object and policy** safely with the script:
   ```powershell
   .\IPMEET-Set-MeetingLabel.ps1 -Action CreateLabels -WhatIf     # preview
   .\IPMEET-Set-MeetingLabel.ps1 -Action CreateLabels -Commit     # create the label objects
   ```
   Then complete each label's **meeting-protection settings in the portal** (they are not asserted by the
   script). Re-read with `Get-Label`.

2. **Publish to the pilot (policy).** Create/point the `Meeting Labels – Policy` at the pilot users:
   ```powershell
   .\IPMEET-Set-MeetingLabel.ps1 -Action PublishPolicy -PolicyMembers "MeetingLabels-Pilot@contoso.com" -WhatIf
   .\IPMEET-Set-MeetingLabel.ps1 -Action PublishPolicy -PolicyMembers "MeetingLabels-Pilot@contoso.com" -Commit
   ```
   In the portal, confirm the policy lists the three meeting labels and (optionally, for later) a default
   label and mandatory labeling — **leave default/mandatory off during the pilot**.
   **Pass/fail:** `Get-Label` shows the three labels; `Get-LabelPolicy` shows `Meeting Labels – Policy`
   scoped to the pilot users; the labels appear when a pilot user schedules a Teams meeting and **not**
   for a non-member.

## Step 4 — Pilot on real meetings (Pilot)
1. Have pilot users apply each tier to real (or representative) Teams meetings — a `Meeting – Highly
   Confidential` meeting for a mock board call, a `Meeting – Confidential` for a project call.
2. Observe the enforced behavior: an external attendee is held in the lobby; the recording control
   reflects the tier; chat is off / in-meeting only and cannot be copied; the invite is encrypted; the
   watermark appears when sharing (Premium).
   **Pass/fail:** each piloted meeting behaves as its tier defines; discrepancies are recorded for
   troubleshooting, not worked around.

## Step 5 — Validate the pilot ring (Pilot → Validate)
1. Run `IPMEET-Validate.ps1`. Read-only, it confirms each intended meeting label exists **with the
   Meetings scope**, is **published** in `Meeting Labels – Policy` to the pilot users, and that the Teams
   baseline is compatible — PASS/FAIL per gate.
2. Have a pilot organizer confirm real behavior end-to-end on a labeled meeting (lobby holds an external
   attendee; recording unavailable on the Highly Confidential tier; chat off / no copy).
3. Complete the **Testing Guide** on the ring. **Pass/fail:** all Testing-Guide gates pass on
   `Meeting Labels – Pilot Ring – Stage1`.

## Step 6 — Expand to the estate (Expand)
1. Broaden `Meeting Labels – Policy` from the pilot user group to all intended users (portal or
   `IPMEET-Set-MeetingLabel.ps1 -Action PublishPolicy -PolicyMembers <all-intended> -Commit`). Confirm
   the labels surface at meeting-creation for the wider audience.
2. Optionally set a **default meeting label** and **mandatory labeling** in the policy — only after the
   pilot validates and stakeholders approve; communicate the change to users first.
3. Run `IPMEET-Report.ps1 -CsvPath .\MeetingLabelsReport.csv` to produce `Meeting Labels – Coverage
   Report` — the labels, their scope, and their publication/target coverage — as the management evidence
   artifact, and re-run it on a schedule to keep coverage healthy.
   **Pass/fail:** the labels are published to all intended users; the report shows the taxonomy present,
   scoped to Meetings, and targeted as designed.

---
### Rollback
- **Un-publish** by removing a label from the policy (portal, or `Set-LabelPolicy ... -RemoveLabel`) or
  narrowing the policy back to the pilot users — labels stop surfacing to users immediately.
- **Retire a label** with `Remove-Label` only after confirming it is applied to no in-flight meetings you
  depend on; prefer un-publishing over deletion.
- Meeting-protection settings changed on a label take effect on **new** meetings; existing recurring
  meetings may need re-labeling. Keep `Meeting Scope – Map` as the record of the intended state.

### Order of operations
`Assess labels + Teams baseline → design taxonomy + map → author meeting labels (Meetings scope, portal
settings) → publish policy to pilot users → pilot on real meetings → validate ring → expand policy
(+ optional default/mandatory) → report coverage`
