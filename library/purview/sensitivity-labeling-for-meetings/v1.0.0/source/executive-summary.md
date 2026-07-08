# Executive Summary — Sensitivity Labeling for Meetings: Microsoft Purview

Organizations protect the document and forget the meeting. Board reviews, M&A calls, HR investigations,
security-incident bridges, and privileged legal discussions happen live in Microsoft Teams — in meetings
created with whatever defaults the organizer clicked: an open lobby that lets anyone with the link walk
in, recording anyone can start, a chat that persists and can be copied out, and an invite that travels
unprotected. You cannot claim a confidential meeting is protected when its controls are accidental. This
solution closes that gap: it uses **sensitivity labels scoped to Meetings in Microsoft Purview** to make
lobby, recording, chat, copy, and content protection a **named property of the meeting** — configured,
piloted, validated, and defensible.

This is a complete, do-it-today package written for an administrator applying meeting protection for the
first time. It delivers a three-tier meeting label taxonomy end-to-end — from reading the current label
and Teams-meeting baseline, through authoring and publishing the labels, to piloting them on real
meetings and expanding — with every label, policy, and pilot ring named once and reused everywhere, and
every change proven on a pilot ring before the estate is touched. Because the meeting-label surface and
the Teams-Premium licensing that gates its protections are **evolving**, the guide cites the method and
flags every capability "verify your licensing/tenant" rather than asserting a setting or an entitlement
as permanent.

## What you get
- A plain-language Solution Overview of meeting labels — lobby, recording, chat, copy, watermark,
  end-to-end encryption, and invite protection — how they govern the meeting (not the files in it), and
  how they complement file/email sensitivity labels.
- A Requirements Guide with verify / implement-if-missing for every prerequisite: sensitivity-label
  licensing plus **Teams Premium** for the meeting-option protections, least-privilege Purview and Teams
  roles, the S&C PowerShell + MicrosoftTeams toolchain, the Meetings-scope capability, a compatible Teams
  meeting baseline, the authored/published labels, in-scope meeting types with stakeholders, and a pilot
  ring with change control.
- An Implementation Guide of precise, ordered steps: assess labels and the Teams baseline, design the
  taxonomy and map, author the meeting labels with their portal protection settings, publish to a pilot
  ring, **pilot on real meetings**, validate against the gate, then expand with optional default and
  mandatory labeling.
- Five PowerShell tools — Discovery, a prerequisite/health helper, a safe Configuration/Remediation tool
  (`-WhatIf` by default), Validation, and Reporting — built on Security & Compliance PowerShell and the
  MicrosoftTeams module, **read-only or `-WhatIf` by default with no credentials in code**.
- Testing and Troubleshooting guides with explicit pass/fail gates, plus field-proven Best Practices.

## What this delivers
Sensitive meetings protected from Purview: lobby, recording, chat, copy, and content protection driven
by a named sensitivity label and the invite encrypted — validated on a pilot before you scale.

## The deployment model
Assess → Design → Configure → **Pilot (real meetings)** → Validate → Expand — with a pilot gate before
the estate, and optional default/mandatory labeling turned on only after validation.

## Outcome
The meeting blind spot closed — confidential meetings carry a label that holds the wrong people in the
lobby, controls recording, keeps chat in the room, and protects the invite — with the determination of
which meeting is sensitive, and any records/legal-hold obligation on a recording, left to the owners who
make it.
