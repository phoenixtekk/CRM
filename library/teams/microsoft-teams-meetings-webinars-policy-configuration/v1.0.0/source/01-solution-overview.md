# 1. Solution Overview — Microsoft Teams Meetings, Webinars & Policy Configuration

## What this solution is
Out of the box, Teams meetings behave the same for everyone, and the defaults are permissive: anyone
can bypass the lobby, external and anonymous people can join and even start meetings, everyone is a
presenter, cloud recording and transcription are on, and there is no way to tell an exec's board
meeting apart from a casual team sync. This solution **configures Microsoft Teams meetings, webinars,
and town halls by policy** so meetings are secure, consistent, and fit-for-purpose. Specifically it:

- designs and applies **Teams meeting policies** that control the **lobby** (who bypasses / who waits),
  **anonymous and PSTN join**, **cloud recording and transcription**, **presenter roles**, meeting
  chat, and **recording expiration / storage**;
- configures **webinars and town halls** through the **Teams events policy** (who can create webinars,
  who can run town halls, attendee access), and notes where legacy **Teams live events** still apply;
- builds **meeting templates** and attaches **sensitivity labels** to meetings where **Teams Premium**
  is licensed (watermark, prevent copy, forced lobby/recording) — flagging the licensing gate;
- confirms **recording storage** lands correctly in **OneDrive / SharePoint** and sets recording
  **expiration**; and
- **assigns policies by group** (Entra ID / Microsoft 365 group) with `New-CsGroupPolicyAssignment`, so
  the right cohort gets the right meeting experience without per-user churn.

The work is done in the **Teams admin center** (admin.teams.microsoft.com), the **Microsoft 365 admin
center**, the **Microsoft Purview** portal (for sensitivity labels), and the **MicrosoftTeams
PowerShell module** (with **Microsoft Graph** for group membership). Every change is **pilot-first**.

## Scope — what this is, and what it deliberately is NOT
**In scope:** Teams **meeting policies**, org-wide **meeting settings** (anonymous join, storage),
**events policy** (webinars + town halls), **meeting templates** and their **sensitivity label**
attachment (Teams Premium), **recording expiration/storage** behavior, and **group-based policy
assignment**.

**Not in scope (separate products / owners):**
- **Teams Phone / calling plans / Operator Connect / audio conferencing dial-in** — voice is a
  different solution. This solution touches PSTN only as a *meeting lobby/bypass* control, not as call
  routing or number provisioning.
- **The definition of sensitivity labels and retention** — a meeting template can *apply* a
  sensitivity label, but **what the label means, and any retention/records schedule, is a Microsoft
  Purview / compliance determination** made by the compliance/records/legal owners. This solution
  attaches the label the compliance owner names; it does not author label policy.
- **Broad Teams governance / lifecycle** (team creation, naming, expiration), **external & guest
  access** governance, and **Teams apps** governance are their own solutions.
- **Teams Rooms** device configuration — a Rooms meeting experience keys off these same meeting
  policies, but device deployment is a separate solution.

## Why this matters
- **The default lobby is a security gap.** With permissive defaults, uninvited external or anonymous
  participants can land directly in a meeting, and anyone can start it before the organizer arrives.
  A lobby policy closes that gap consistently instead of meeting-by-meeting.
- **"Everyone is a presenter" is how meetings get hijacked.** Setting the **presenter role** by policy
  stops attendees from sharing their screen or removing others uninvited.
- **Recording and transcription are compliance-sensitive.** Whether a meeting can be recorded or
  transcribed, where the recording is stored, and how long it lives are decisions that should be set by
  policy for a cohort — not left to each user.
- **Webinars and town halls are external-facing.** Uncontrolled, anyone can spin up an external
  webinar. The events policy decides who can, and how attendees join.
- **One size does not fit all.** Execs, standard staff, and frontline/external-facing users need
  different meeting experiences. Group-based assignment delivers that without manual per-user work.

## How it works
1. **Licensing gates the premium pieces (verify first).** Core meeting policies, events policy, and
   group assignment work on standard Teams licensing. **Meeting templates, sensitivity labels on
   meetings, watermark, and "prevent copy" are Teams Premium features** — they require a **Teams
   Premium** license on the organizer. Confirm entitlement before designing templates. *(Verify in your
   tenant/plan.)*
2. **Assess the current posture.** Export today's meeting policies, events policy, org meeting
   configuration, recording/storage settings, and existing group assignments — the
   `Meeting Posture – Teams – Discovery` snapshot — so you design against reality, not assumptions.
3. **Design the policy set.** Rather than editing the built-in **Global (Org-wide default)** policy
   destructively, design a small set of **named custom policies** for the cohorts that need them, and
   tune the Global policy to a safe baseline for everyone else.
4. **Configure org-wide meeting settings.** Set the org-level **`Set-CsTeamsMeetingConfiguration`**
   controls — notably **`-DisableAnonymousJoin`** — which sit *above* the per-policy anonymous toggle.
5. **Build the meeting policies.** Create/tune each policy's lobby (`-AutoAdmittedUsers`), anonymous
   join (`-AllowAnonymousUsersToJoinMeeting`), PSTN lobby bypass (`-AllowPSTNUsersToBypassLobby`),
   recording (`-AllowCloudRecording`), transcription (`-AllowTranscription`), presenter role
   (`-DesignatedPresenterRoleMode`), chat, and recording expiration (`-NewMeetingRecordingExpirationDays`).
6. **Configure webinars & town halls.** Create/tune the **events policy**
   (`Set-CsTeamsEventsPolicy`): `-AllowWebinars`, `-AllowTownhalls`, attendee access, and event
   integrations. Note the legacy **Teams live events** policy (`Set-CsTeamsMeetingBroadcastPolicy`)
   where an org still uses live events; Microsoft is steering live events toward **town halls**.
7. **Build templates + sensitivity (Teams Premium).** In the Teams admin center, create the meeting
   **template** and attach the **sensitivity label** the compliance owner specifies, then publish it
   with a template policy so the right cohort sees it.
8. **Assign by group.** Assign each policy to its cohort's group with
   **`New-CsGroupPolicyAssignment`** (ranked), so membership drives the meeting experience — pilot
   group first.

## The reference model (artifacts this solution creates)
Every artifact is named `<Purpose> – <Scope> – <Stage>` and reused verbatim across the docs, scripts,
the Teams admin center, and the Purview portal.

| Artifact | Name |
|---|---|
| Read-only posture assessment export | `Meeting Posture – Teams – Discovery` |
| Org-wide meeting settings (anonymous join, storage) | `Meeting Config – Org – Prod` |
| Baseline meeting policy for most staff | `Meeting Policy – Standard – Prod` |
| Executive / sensitive-meeting policy | `Meeting Policy – Exec – Prod` |
| Restricted (frontline / external-facing) policy | `Meeting Policy – Restricted – Prod` |
| Pilot copy of the standard policy | `Meeting Policy – Standard – Pilot` |
| Webinars + town halls events policy | `Events Policy – Standard – Prod` |
| Restricted events policy (no external webinars) | `Events Policy – Restricted – Prod` |
| Meeting template (Teams Premium) | `Meeting Template – Confidential – Prod` |
| Sensitivity label attached to the template | `Sensitivity Label – Confidential – Meeting` *(defined by compliance)* |
| Pilot scope group | `Meeting Scope – Pilot – Group` |
| Executive scope group | `Meeting Scope – Exec – Group` |
| Group policy assignment (exec cohort) | `Meeting Assignment – Exec – Group` |
| Validation pass/fail report | `Meeting Validation – Teams – Report` |

> The **sensitivity label** name above is illustrative — use the exact label the **compliance/records**
> owner has defined in Purview. Never invent a label or decide what it protects.

## Benefits
- Lobby, recording, transcription, and presenter behavior are **set by policy**, not left to defaults —
  consistently, per cohort.
- Anonymous and PSTN join are controlled at **both** the org level and the policy level, closing the
  most common meeting-security gaps.
- Webinars and town halls are **governed** — only the intended creators can run external events.
- Sensitive meetings get a **template + sensitivity label** (watermark, prevent copy, forced lobby)
  where Teams Premium is licensed.
- Assignment is **group-driven**, so onboarding a new exec or team gets the right experience
  automatically, and every change is **pilot-first with pass/fail gates and a rollback**.

## Limitations (be honest with buyers)
- **Templates, sensitivity labels on meetings, watermark, and prevent-copy are Teams Premium.** Without
  Premium on the organizer, those steps do not apply — **verify entitlement in your tenant/plan**; this
  solution flags it but cannot grant it.
- **Policy changes are not instant.** New or changed meeting/events policies and group assignments can
  take time to propagate to clients (commonly minutes, occasionally longer); validate after propagation.
- **Group assignment is ranked, not additive.** A user in multiple assigned groups gets the policy from
  the **highest-ranked** assignment for that policy type — plan ranks deliberately (covered in
  Implementation).
- **The Global policy still applies to everyone unassigned.** Tuning custom policies does nothing for
  users who fall back to Global — the baseline must be set too.
- **Sensitivity-label meaning and retention are compliance decisions.** This solution attaches the
  label the compliance owner specifies; **what it protects and how long meeting data is retained is
  their determination**, not the implementer's.
- **Commercial vs Government clouds differ.** Portal URLs and some capability availability differ on
  **GCC / GCC High / DoD** (`*.office365.us`, `*.microsoft.us`); noted where it matters — verify on
  your cloud.

## The standard deployment model
> Assess the current meeting/events posture and licensing → design the policy set (Global baseline +
> Standard/Exec/Restricted, events policy, templates) → configure org settings and policies → assign to
> a **pilot** group first → validate (lobby, recording, roles, webinars, template) against explicit
> pass/fail gates → expand to the broad cohorts in waves.
> Pattern: **Assess → Design → Configure → Pilot → Validate → Expand**, with explicit pass/fail gates
> and a documented rollback.
