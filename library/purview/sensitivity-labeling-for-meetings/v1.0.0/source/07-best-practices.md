# 7. Best Practices — Sensitivity Labeling for Meetings (Microsoft Purview)

- **Confirm the meeting-label surface before you design anything.** The **Meetings** scope, its exact
  protection settings, and the Teams-Premium licensing that gates them are evolving — read them from the
  Purview label-configuration UI and Microsoft's current docs for *your* tenant rather than assuming a
  setting or a license entitlement that may have moved.
- **Label the meeting *and* the files — they are different jobs.** A meeting label governs lobby,
  recording, chat, copy, and the invite; it does **not** classify or encrypt the documents shared in the
  call. Deploy meeting labels alongside file/email labels so the conversation and its content are both
  protected, and say so to users so they don't assume one covers the other.
- **Keep the taxonomy small and named.** Three tiers (`General`, `Confidential`, `Highly Confidential`)
  that users can choose confidently beat ten they'll guess at. Reuse the exact names across the portal,
  the scripts, and `Meeting Scope – Map`.
- **Pilot on real meetings before you publish widely.** Lobby, recording, and chat changes are felt
  immediately by every attendee. Prove each tier on the `Meeting Labels – Pilot Ring – Stage1` with real
  organizers before broadening the policy — never publish tenant-wide on day one.
- **Turn on default and mandatory labeling last, and communicate first.** A default meeting label and
  mandatory labeling drive coverage, but flipping them without warning surprises organizers mid-schedule.
  Enable them only after the pilot validates and after you've told users what will change.
- **Right-size the lobby, don't just lock it.** "Only organizers & co-organizers bypass" is correct for a
  board or incident call and wrong for an all-hands. Match the lobby setting to the meeting type in the
  taxonomy so protection doesn't become friction users route around.
- **Recording control is a records decision, not just a toggle.** Whether a sensitive meeting may be
  recorded — and how long a recording is kept or held — is owned by compliance/records/legal. Configure
  the technical control the label enforces; leave the retention/hold determination to the owners who make
  it.
- **Mind the interaction with Teams meeting policy.** Meeting labels operate on top of the tenant Teams
  meeting configuration (lobby default, whether cloud recording is allowed, chat mode). Read the baseline
  with `Get-CsTeamsMeetingPolicy`, record it in `Meeting Scope – Map`, and change it only with the Teams
  admin under change control.
- **Treat watermark and end-to-end encryption as Premium-gated and verify per tenant.** These (and
  recording control) depend on Teams Premium. Where Premium is unavailable, scope the labels to the
  invite/lobby/chat controls your plan supports and record the Premium-only controls as **deferred** —
  don't design around a feature the tenant can't enforce.
- **Keep automation safe-by-default and secret-free.** Run discovery, validation, and reporting read-only;
  gate every write behind `-WhatIf` → `-Commit`; sign in interactively with modern auth. No credentials,
  tokens, or secrets belong in a script or a document.
- **Re-report on a schedule.** Coverage drifts as new meeting types and organizers appear. Re-run
  `IPMEET-Report.ps1` periodically so `Meeting Labels – Coverage Report` stays a live evidence artifact,
  not a one-time snapshot.
- **Keep determinations with their owners.** The solution configures and evidences meeting protection;
  which meeting is sensitive, and any records/legal-hold/privacy obligation on a recording or chat, is a
  determination for compliance, security, HR, and legal. Keep that separation explicit so technical
  configuration is never mistaken for a compliance ruling.
