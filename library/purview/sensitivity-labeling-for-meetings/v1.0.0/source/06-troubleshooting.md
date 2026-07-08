# 6. Troubleshooting — Sensitivity Labeling for Meetings (Microsoft Purview)

Symptoms, likely causes, and fixes for the meeting-label lifecycle. Stay in **simulation/pilot** while
diagnosing — reproduce on `Meeting Labels – Pilot Ring – Stage1` before touching the wider estate, and
prefer un-publishing a label over deleting it.

## The meeting labels don't appear when a pilot user schedules a Teams meeting
- **Not published to that user.** Confirm `Meeting Labels – Policy` targets the pilot users
  (`Get-LabelPolicy -Identity "Meeting Labels - Policy"`); add the user with the portal or
  `IPMEET-Set-MeetingLabel.ps1 -Action PublishPolicy -Commit`.
- **Publication lag.** Label-policy changes can take time to reach clients (commonly up to ~24 h). Have
  the user sign out/in of Teams/Outlook and retry before assuming failure.
- **Label not Meetings-scoped.** Run `IPMEET-Validate.ps1`; if a label's `ContentType` doesn't include
  the Meetings scope, re-author the scope in the portal (Information Protection → Sensitivity labels →
  the label → scope **Meetings and calendar events**). Verify the exact scope wording for your tenant.

## The meeting-protection controls (lobby / recording / chat / watermark) don't take effect
- **Teams Premium not licensed.** Recording control, watermark, and end-to-end encryption are
  **Teams Premium** features. `IPMEET-Check-Prereqs.ps1` reports the Premium signal — if it's missing,
  those controls are **deferred**, not broken. Confirm licensing in the M365 admin center.
- **Settings authored on the wrong surface.** The label *lifecycle* is scriptable, but the
  meeting-option protection settings themselves are set **on the label in the portal**. If a control is
  unset there, the script cannot assert it. Re-open the label's meeting-settings page and confirm each
  control (lobby bypass, chat mode, recording, watermark, E2EE).
- **Applies to new meetings only.** Changing a label's settings affects **new** meetings; existing
  recurring meetings may need re-labeling. Re-create or re-label the meeting to test the new setting.
- **Teams meeting policy overrides.** A restrictive/permissive tenant Teams meeting policy can mask the
  label behavior. Compare the label intent against the Teams baseline captured in `Meeting Scope – Map`
  (`Get-CsTeamsMeetingPolicy`); align, don't work around.

## `IPMEET-Set-MeetingLabel.ps1 -Commit` fails or the label isn't created
- **Not connected / wrong session.** Ensure `Connect-IPPSSession` succeeded in this session
  (`Get-Command Get-Label` resolves). The label cmdlets live in Security & Compliance PowerShell, not the
  Teams module.
- **Insufficient role.** Creating/publishing labels needs an Information Protection / Compliance
  Administrator role. Confirm membership in Purview → **Roles & scopes / Permissions**.
- **Duplicate name.** A label or policy with the same name already exists. Run `IPMEET-Discover.ps1` /
  `Get-Label` first; reuse the existing object rather than creating a duplicate.

## `IPMEET-Validate.ps1` reports a label as "not detected on the policy" but the portal shows it
- **Module-version property shape.** Label-to-policy attachment is exposed under different property names
  across module versions; the validator checks the common shapes. Confirm in the portal
  (Information Protection → Label policies → the policy → **Labels**) — if it's listed there, treat the
  validator line as informational and note the module version. Update the ExchangeOnlineManagement module
  if it is significantly out of date.

## External attendees are (or aren't) held in the lobby unexpectedly
- **Lobby is a combined result.** The effective lobby behavior comes from the label's lobby setting **and**
  the tenant/organizer Teams meeting policy (`AutoAdmittedUsers`). Verify both; the label tightens, it
  doesn't override a more permissive test expectation silently. Test with a real external account, not a
  guest already in the tenant.

## Recording still works on a "prevent recording" tier
- **Premium dependency** (see above) — without Teams Premium the recording control is deferred.
- **Cached client.** Have the participant fully restart Teams; policy/label evaluation is cached per
  session. Re-test on a freshly created meeting of that tier.

## The coverage report is empty or missing labels
- **No Meetings-scoped labels yet.** `IPMEET-Report.ps1` only lists meeting-relevant labels; if none are
  authored/scoped, author them (Implementation Step 3) first.
- **CSV not written.** The report is console-only unless you pass `-CsvPath`. Provide a writable path
  (e.g. `-CsvPath .\MeetingLabelsReport.csv`) and confirm you have write permission to that folder.

---
### When to stop and escalate
- A required control is unavailable on your licensing/tenant (e.g. Teams Premium) — record it **deferred**
  and route the licensing decision to the owner; do not design around an unavailable feature.
- **Which meeting belongs to which tier** is a stakeholder determination (compliance/security/HR/legal),
  not a technical fix — capture the mapping in `Meeting Scope – Map` and defer the determination.
- If behavior can't be reconciled with the label and Teams baseline, keep the policy scoped to the pilot
  ring, gather `IPMEET-Validate.ps1` + `IPMEET-Report.ps1` output as evidence, and raise with Microsoft
  support rather than expanding a policy that doesn't behave as designed.
