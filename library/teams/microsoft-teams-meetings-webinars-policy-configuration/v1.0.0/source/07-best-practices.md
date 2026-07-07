# 7. Best Practices

Durable practices for configuring Teams meetings, webinars, and policy assignment. These outlast any
single tenant and keep the meeting estate secure and consistent.

## Policy design
- **Don't butcher the Global policy — layer custom policies.** Tune **Global (Org-wide default)** to a
  safe baseline for everyone unassigned, and express cohort differences in a **small** set of named
  custom policies (`Standard`, `Exec`, `Restricted`). A sprawl of near-identical policies is
  unmaintainable.
- **Name every policy `<Purpose> – <Scope> – <Stage>` and reuse the name everywhere** — admin center,
  scripts, assignments, runbook. Consistent names make audits and troubleshooting fast.
- **Decide the baseline with the business, not in the tool.** Lobby, recording, transcription, and
  presenter defaults are security/collaboration decisions (§2.4). The tool applies them; the
  stakeholders own them.

## Security defaults that pay off
- **Close the lobby by default.** Prefer `EveryoneInCompanyExcludingGuests` (or tighter) over
  `Everyone`; reserve organizer-only lobby for sensitive cohorts. Never leave external/anonymous
  bypass on by default.
- **Control anonymous at both layers.** Set the org master switch (`DisableAnonymousJoin`) deliberately;
  the per-policy toggle only refines what the org allows.
- **Default presenter to a restrictive mode** for most cohorts so attendees can't hijack sharing;
  organizers can still promote presenters per meeting.
- **Keep PSTN lobby-bypass off** unless a specific cohort needs it — dial-in participants are the
  hardest to identify.

## Recording, transcription & storage
- **Treat recording as data.** Set `-NewMeetingRecordingExpirationDays` deliberately and coordinate with
  the compliance owner's OneDrive/SharePoint retention — the two interact and the stricter one governs.
- **Confirm OneDrive provisioning before enabling recording** for a cohort; a recording with nowhere to
  land fails silently for the organizer.
- **Don't enable transcription org-wide by reflex** — some jurisdictions and meeting types have consent
  implications; make it a cohort decision.

## Webinars & town halls
- **Govern who can create external events.** Restrict webinar/town-hall creation to the cohorts that
  need it via the events policy; don't leave it open to the whole org.
- **Prefer town halls over legacy live events** for new large-broadcast needs — Microsoft is steering
  live events toward town halls; verify the retirement timeline for your cloud before building new live
  events.

## Teams Premium (templates & sensitivity)
- **Verify Premium entitlement before designing templates.** If the cohort has no Teams Premium,
  templates/sensitivity/watermark silently do nothing — scope them to Premium users or defer.
- **Attach labels, don't author them.** The sensitivity label and its protections are the **compliance
  owner's** determination in Purview; the template only attaches an existing published label.
- **Use templates to lock the sensitive experience** (forced lobby, no recording, restricted
  presenting) so organizers can't accidentally loosen it.

## Assignment & change discipline
- **Assign by group, not per user.** Group assignment keeps the experience aligned to identity/HR
  reality and survives joiners/movers/leavers. Reserve per-user grants for exceptions.
- **Rank assignments deliberately.** A user in multiple assigned groups gets the **lowest-Rank** (highest
  precedence) assignment per policy type — document the rank scheme and test effective policy (Test 4).
- **Always pilot first.** Assign to `Meeting Scope – Pilot – Group`, validate against §5, and only then
  expand in waves. Meeting changes touch everyone's daily experience.
- **Keep the rollback ready.** Roll back **assignments first** (fastest restore), then policies; never
  delete a policy that still has assignments (§3.11).
- **Re-run discovery periodically.** `TEAMSMTG-Discovery.ps1` on a schedule catches drift — new policies,
  stray assignments, or a Global baseline that changed under you.

## Cloud & versioning
- **Confirm Commercial vs Government early** and use the matching URLs/endpoints and PowerShell
  environment throughout; some events/Premium features differ by cloud.
- **Treat version-dependent parameters as "verify in your tenant."** Events-policy and template cmdlet
  parameters evolve; check the accepted values for your module version before scripting them broadly.
- **Automate safe-by-default.** Keep the scripts read-only / `-WhatIf` unless `-Commit` is explicit, and
  never store credentials — always modern-auth `Connect-*`.
