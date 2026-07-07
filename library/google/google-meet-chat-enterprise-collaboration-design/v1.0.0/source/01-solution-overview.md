# Solution Overview

## What this is

This solution designs and configures the **steady-state collaboration model for Google Meet and
Google Chat** across an enterprise Google Workspace tenant. It is deliberately distinct from a
Teams-to-Workspace *migration*: here Meet and Chat are already available, but they were rolled out
on defaults. That leaves gaps — meetings anyone can join or take over, recordings landing in
uncontrolled Drive locations, external participants and external chat wide open, ad-hoc Chat spaces
with no naming or ownership discipline, no message history/retention posture, and third-party Chat
apps and bots installable by anyone.

The engagement produces a **named, OU/group-scoped policy design** for both services and configures
it pilot-first:

- **Meet safety & host controls** — host management, who can join, quick access, moderation
  (mute/remove, present locks), safety defaults for the organization and per OU/group.
- **Recording, transcription & storage policy** — who can record, where recordings/transcripts/notes
  land (a governed Shared Drive), and how they are retained.
- **External-participant rules for Meet** — whether and how people outside the organization can
  join, and warning/trust banners for external attendees.
- **Chat spaces architecture** — a spaces taxonomy (team, project, cross-functional, external),
  naming and ownership conventions, and who can create spaces.
- **External chat & file-sharing policy** — external chat allow/block, allowlisted domains, and
  file-sharing controls inside Chat.
- **History & retention** — Chat history default (on/off, per space), Meet artifact retention, and
  the Vault retention/hold rules that back eDiscovery.
- **App & bot governance** — which Chat apps/bots are allowed, and restriction of third-party app
  installation.

## How it works

All policy is expressed in the **Google Admin console** (admin.google.com) under **Apps → Google
Workspace → Google Meet** and **→ Google Chat**, scoped by **organizational unit (OU)** and, for
Chat, by **configuration group** where per-group targeting is needed. Retention and holds are set in
**Google Vault** (vault.google.com). Recordings, transcripts, and Gemini-generated meeting notes are
directed to a governed **Shared Drive** so their access and retention are controlled centrally rather
than scattered across users' My Drive.

Every artifact this solution creates — a policy scope, a Shared Drive, a retention rule, a Chat app
allowlist entry, a validation report — is **named** with the convention `<Purpose> – <Scope> –
<Stage>` and that exact name is reused in configuration, testing, troubleshooting, and the Python
tools. Examples used throughout:

- `Meet Safety Policy – Pilot OU – Configure`
- `Meet Host Management – All Staff – Enforce`
- `Recording Storage – Meet Recordings Shared Drive – Configure`
- `Meet External Access – Partners Group – Scoped`
- `Chat Spaces Taxonomy – Enterprise – Design`
- `Chat External Policy – Allowlisted Domains – Enforce`
- `Chat History – Default On – Enforce`
- `Vault Retention – Chat 3yr – Enforce`
- `Chat App Allowlist – Approved Bots – Enforce`

## Reference model

```
                     Google Admin console (admin.google.com)
                                     │
   ┌─────────────────────────────────┼─────────────────────────────────┐
   │                                 │                                 │
 Google Meet                     Google Chat                        Google Vault
 (Apps → Meet)                   (Apps → Chat)                      (retention/holds)
   │                                 │                                 │
 • Safety & host mgmt            • Space creation scope            • Chat retention rules
 • Who can join / quick access   • External chat + allowlist       • Chat holds (legal)
 • Recording / transcription     • History default (on/off)        • Meet-artifact retention
   → Shared Drive (governed)     • File sharing in Chat              (via Drive rules)
 • External participants         • App/bot allowlist
   scoped per OU / group           per OU / group
   │                                 │
   └──────────── scoped by OU (+ configuration group for Chat) ────────┘
                                     │
                       Pilot OU/group → validate → expand
```

**Scoping model.** Meet and Chat settings apply **top-down by OU**, with child OUs inheriting unless
overridden. Chat additionally supports **configuration groups** for targeting a policy at a group of
users who may span OUs (for example, an "External Collaboration – Partners" group that is allowed
external chat while the rest of the organization is not). The design assigns each control to the
narrowest scope that satisfies policy.

## Benefits

- **Meetings are safe by default** — hosts are in control, uninvited join is prevented, and external
  attendees are visibly flagged.
- **Recordings and transcripts are governed** — they land in one controlled Shared Drive with known
  access and retention, not scattered in personal drives.
- **External collaboration is deliberate, not accidental** — external Meet join and external Chat are
  allowed only where the business needs them, to named domains.
- **Chat is organized and accountable** — a spaces taxonomy with owners and naming, not sprawl.
- **Compliance is satisfiable** — history and Vault retention/holds make Chat eDiscovery-ready.
- **Third-party risk is contained** — only approved Chat apps/bots can be installed.

## Limitations & boundaries

- This solution covers **Meet and Chat configuration and governance only**. It is not the Teams→Chat/
  Meet *migration* (that is a separate solution) and does not migrate historical Teams messages.
- **Admin-console labels and the availability of individual settings vary by Workspace edition and
  change over time** — treat exact toggle names as current-at-authoring and *verify in your tenant*.
  Vault, DLP, and some safety controls require the appropriate edition (e.g. Enterprise/Education
  Plus); confirm licensing (global requirement #1).
- **Gemini-in-Meet features** (automatic note-taking / "take notes for me", transcription behaviors)
  are edition- and rollout-dependent — *verify in your tenant* before relying on them.
- The Python tools use the **Google Workspace Admin SDK and Reports API**. Some Meet/Chat policy
  surfaces are managed only in the Admin console UI and are **not** exposed as writable API settings;
  where that is so, the tools **assess and report** (read-only) and the console remains the change
  surface. No tool invents an API that does not exist.

## Deployment model

The engagement follows the house model **Assess → Design → Configure → Pilot → Validate → Expand**,
pilot-first, with explicit pass/fail gates and a documented rollback for every production change:

1. **Assess** — inventory current Meet/Chat settings, external exposure, spaces, retention, and
   installed apps (read-only tools + Admin console).
2. **Design** — decide the target policy per OU/group: Meet safety/host, recording storage, external
   rules, Chat spaces taxonomy, external/file policy, history/retention, app allowlist.
3. **Configure** — apply the design to the **Pilot OU/group** first, naming every artifact.
4. **Pilot** — a small representative user set runs Meet/Chat under the new policy.
5. **Validate** — run the test procedures and gates; confirm controls enforce, external is scoped,
   recordings land in the Shared Drive, retention applies.
6. **Expand** — roll the validated policy outward OU by OU, re-validating at each wave, with rollback
   ready.

High-impact changes (external access, history/retention, recording storage) are staged under change
control; each has a named rollback in the Implementation guide.
