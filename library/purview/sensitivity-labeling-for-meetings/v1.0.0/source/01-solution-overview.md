# 1. Solution Overview — Sensitivity Labeling for Meetings (Microsoft Purview)

## What this solution is
Most organizations protect the **document** and forget the **meeting**. A confidential deal, a board
review, an HR investigation, or a security-incident bridge is discussed live in a Microsoft Teams
meeting — and that meeting was created with whatever defaults the organizer clicked: an open lobby that
lets anyone with the link walk in, recording anyone can start, a chat that persists and can be copied
out, and an invite that travels unprotected. That is the gap this solution closes. It uses
**sensitivity labels scoped to Meetings** in Microsoft Purview to govern the meeting itself:

- **Lobby** — who bypasses the lobby and who must wait to be admitted (e.g. only people in your
  organization, or only the organizer and co-organizers) — so the wrong people cannot simply join.
- **Recording** — whether the meeting may be recorded and by whom (e.g. recording prevented, or limited
  to organizers) — so a sensitive conversation is not captured and re-shared.
- **Chat** — whether meeting chat is on, off, or in-meeting only, and whether chat content may be
  **copied** to the clipboard — so discussion does not leak out of the room.
- **Copy / content protection** — a **watermark** on shared content and video and **end-to-end
  encryption** for the highest tier (Teams Premium), plus **encryption of the meeting invite** so the
  calendar item itself is protected.

Everything is done with the **Microsoft Purview portal** (purview.microsoft.com), the **Microsoft 365 /
Teams admin centers**, **Security & Compliance PowerShell** (`Connect-IPPSSession`), and the
**MicrosoftTeams** PowerShell module — no third-party tooling. Meeting labels are configured, **piloted
on a small ring first**, validated against pass/fail gates, and then expanded.

> **A meeting label governs the meeting, not the files shared in it.** A meeting-scoped label sets lobby,
> recording, chat, copy, and content-protection behavior for the Teams meeting and encrypts its invite.
> It does **not** classify or encrypt the documents opened during the call — that is the job of
> **file/email sensitivity labels** (a separate Purview solution). The two are complementary and are
> commonly deployed together; this solution delivers the meeting half.

## Why this matters
- **The lobby is the perimeter of a live conversation.** If anyone with the link bypasses the lobby, the
  meeting is only as private as the least careful forward of its invite. A label makes "only my org
  bypasses the lobby" a property of the meeting, enforced automatically.
- **Recording is forever.** An ad-hoc recording of a confidential meeting becomes a durable, shareable
  asset that outlives the conversation. A label can prevent recording — or limit it to organizers — for
  the meetings that warrant it.
- **Chat leaks after the meeting ends.** Meeting chat persists, and copied chat content travels. Turning
  chat off (or in-meeting only) and preventing copy for the sensitive tiers keeps the discussion in the
  room.
- **It is defensible and auditable.** "Every board and incident meeting is labeled Highly Confidential —
  organizer-only lobby, recording prevented, chat off, invite encrypted" is a statement you can evidence
  with a report, not a hope.

## How it works
1. **Assess.** Read the tenant's current state — which sensitivity labels exist and whether any are
   scoped to **Meetings**, which label policies publish them, and the **Teams meeting policy baseline**
   (lobby default, recording allowed, chat mode) that meeting labels operate on top of — all read-only.
2. **Design.** Define a **meeting label taxonomy** (below) mapping each tier to concrete lobby,
   recording, chat, copy, and content-protection settings, aligned to the classification intent your
   stakeholders set.
3. **Configure.** Author the meeting labels in the Purview portal with the **Meetings** scope and their
   protection settings, and publish them to users via a label policy. (The label/policy lifecycle is
   scriptable; the meeting-protection settings are completed in the portal — see the note below.)
4. **Pilot.** Publish the label policy to a **pilot user group** and have them label real meetings first
   — never tenant-wide on day one. Lobby, recording, and chat changes are **high-impact** for the
   attendee experience; prove them on the ring.
5. **Validate.** Confirm each intended meeting label exists with the Meetings scope, is published, and
   that a labeled meeting actually behaves as the tier defines (external attendee held in lobby,
   recording button unavailable, chat off). Run the pass/fail gates.
6. **Expand.** Broaden the label policy to all intended users, optionally set a **default** meeting label
   and **mandatory labeling**, and hand ongoing coverage and reporting to operations.

## The meeting label taxonomy (design used throughout)
Three tiers are used consistently across the docs, scripts, and portal. Adjust names and settings to your
classification scheme — the **determination** of which meeting warrants which tier belongs to your
compliance, security, HR, and legal stakeholders; this solution provides the technical mapping.

| Label | Lobby (who bypasses) | Meeting chat | Copy chat | Recording | Content protection (Teams Premium) |
|---|---|---|---|---|---|
| `Meeting – General` | Tenant default (people in org & guests) | On | Allowed | Allowed | Encrypt invite (optional) |
| `Meeting – Confidential` | People in my organization (external wait in lobby) | In-meeting only | Prevented | Organizers & co-organizers only | Encrypt invite |
| `Meeting – Highly Confidential` | Only organizers & co-organizers | Off (or in-meeting only) | Prevented | Prevented | Watermark + end-to-end encryption + encrypt invite |

> **Licensing / plan note — verify against your own tenant.** Applying and encrypting the **meeting
> invite** builds on standard sensitivity labeling (Microsoft 365 E3/E5). The **meeting-option
> protections** driven by the label — lobby, presenter, recording, chat, copy-prevention, **watermark**,
> and **end-to-end encryption** — depend on **Microsoft Teams Premium** and on the meeting-scope
> capability being available and enabled in your tenant. Teams Premium and the Purview meeting-label
> surface are **evolving** — confirm current availability, the exact settings offered, and their
> licensing in the Purview portal and Microsoft's documentation for *your* tenant before you design.
> Where Teams Premium is unavailable, scope the labels to the invite-encryption and lobby/chat controls
> that your plan supports and record the Premium-only controls as deferred.

## What you get
- This **Solution Overview**, a **Requirements Guide** (every prerequisite with verify /
  implement-if-missing), a precise **Implementation Guide**, a **Testing Guide** with pass/fail gates, a
  **Troubleshooting Guide**, and field-proven **Best Practices**.
- **Five PowerShell tools** — Discovery, a prerequisite/health helper, a safe Configuration/Remediation
  tool (`-WhatIf` by default), Validation, and Reporting — built on Security & Compliance PowerShell and
  the MicrosoftTeams module, **read-only or `-WhatIf` by default and with no credentials in code**.

> **Boundary.** Which meetings are sensitive, what the retention/records obligations of a recording are,
> and any legal-hold or investigation requirement are **determinations owned by your compliance, HR,
> privacy, and legal functions**. This solution provides the technical configuration and the evidence —
> not the determination.
