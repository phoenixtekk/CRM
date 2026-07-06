# 1. Solution Overview — Microsoft Teams → Google Chat & Meet Migration & Coexistence

## What this solution is
Teams isn't just chat. It is **channels, meetings, and shared files**, and users are mid-conversation
when you move them. This solution moves collaboration from **Microsoft Teams to Google Chat and Google
Meet** as a governed migration: a mapping of Teams **channels to Google Chat spaces**, a transition of
**meetings to Google Meet**, a plan for the **shared files** that live inside Teams, a **coexistence**
design so a Teams user and a Chat user can still work together during the cutover, and **adoption**
guidance so people actually land on the new tools. It runs pilot-first and rollback-ready, using the
category deployment model: Assess, then Configure, then Pilot, then Validate, then Expand.

It is **tool-agnostic**. Google offers a native channel-message migration and there are third-party
tools; this solution governs *what maps to what, in what order, and how you prove it* — the specific
console steps of any one migration tool are deferred to that tool's own docs. Where the included
scripts read the source, they read **Microsoft Teams / Microsoft 365** through Microsoft Graph,
read-only.

## The Teams → Chat/Meet model
Teams bundles several capabilities behind one app. The migration treats each as its own workstream with
its own target and its own honest scope.

| Teams object | Google target | How it moves |
|---|---|---|
| A **team** and its **standard channels** | A set of **Google Chat spaces** (one space per channel) | Channel *conversations* can be migrated into spaces; membership is re-created from the team/channel roster |
| **Channel messages / conversation history** | **Messages inside a space** | Migrated via an import path (native or third-party) with real limits — see "Honest scope" below |
| **1:1 chats and group (private) messages** | Google Chat DMs / group DMs | **Not carried by the native channel migration** — treated as a fresh start unless a third-party tool covers them; message history limits apply |
| **Teams meetings** (scheduled + recurring) | **Google Meet** | Meeting *links* are re-created in Google Calendar/Meet; existing invites are re-issued or interop-bridged during coexistence |
| **Files inside channels** (the SharePoint/OneDrive behind Teams) | **Google Drive / shared drives** | Moved by the Drive migration workstream (deferred to the SharePoint/OneDrive → Google Drive solution); this solution maps *which* space points at *which* Drive location |
| **The people** | Google Chat + Meet users | Provisioned into Google first (identity workstream); adoption drives real usage |

## Honest scope — what a Teams → Chat migration can and can't carry
Message-history migration has real, documented limits. Overpromising here is how these projects lose
trust, so this solution states the limits up front and plans around them:

- **Channels map to spaces; conversations can be migrated, but not everything in them.** Google's
  native path migrates **channel conversations from Teams into Chat spaces**
  ([Google Workspace Updates — migrate Teams messages to Chat](https://workspaceupdates.googleblog.com/2024/12/open-beta-migrate-microsoft-teams-messages-to-google-chat.html),
  [Google Workspace Updates — migrate with CloudM](https://workspaceupdates.googleblog.com/2025/02/migrate-data-from-microsoft-teams-to-google-chat.html)).
- **Some message content does not survive.** Rich-text formatting such as underlining, information in
  **message cards**, **nested lists**, and Teams-specific features like **Streams, praise, and
  approvals** are **not** migrated by the native tool
  ([Google Workspace Help — run a chat migration](https://knowledge.workspace.google.com/admin/migrate/run-a-chat-migration)).
- **1:1 and private/group chats are out of scope for the channel migration.** The native path targets
  **named spaces**; **direct messages and unnamed group messages are not supported** by import mode
  ([Google for Developers — import data to Google Chat](https://developers.google.com/workspace/chat/import-data)).
- **Import happens into hidden "import-mode" spaces on a 90-day clock.** Data is imported into spaces
  in **import mode** that end users can't see; the import (including finalizing/rolling out the spaces)
  must complete within **90 days** or the space is deleted and unrecoverable
  ([Google for Developers — import data to Google Chat](https://developers.google.com/workspace/chat/import-data)).
  Once a space is **finalized**, you can't add more historical messages to it.
- **Scale is bounded per import.** The native tool imports up to **1,000 teams per import**; more teams
  means additional imports
  ([Google Workspace Help — run a chat migration](https://knowledge.workspace.google.com/admin/migrate/run-a-chat-migration)).
- **This is a productivity move, not a compliance archive.** Google is explicit that the chat migration
  is a productivity feature and **not intended for legal/retention purposes** — keep the Teams source
  (or an eDiscovery export) for anything under legal hold
  ([Google Workspace Help — set up a chat migration](https://knowledge.workspace.google.com/admin/migrate/set-up-a-chat-migration)).

The practical consequence: **plan for a "history-lite" cutover.** Migrate active channel conversations
where it adds value, set the expectation that not every message/format carries, keep the Teams source
read-only for reference and legal hold, and put the design effort into **going-forward collaboration**
(the right spaces, the right members, meetings on Meet, and adoption) rather than a perfect history copy.

## Meetings → Google Meet
Teams meetings become **Google Meet** meetings. Two things make this safe during the cutover:

- **Re-issue meeting links.** New and recurring meetings are created as Google Meet events on Google
  Calendar for migrated users; existing recurring Teams invites are re-issued as Meet invites for the
  wave.
- **Interop during coexistence.** While the estate is split, cross-platform meetings still work:
  calendar sync keeps events/RSVPs consistent across Google and Teams, and Meet↔Teams interop lets each
  side join the other's meetings so no one is stranded on the wrong client
  ([Microsoft Learn — calendar syncing between Google Workspace and Teams](https://learn.microsoft.com/en-us/microsoftteams/setup-calendar-syncing-with-google-workspace),
  [Google Workspace Updates — Meet–Teams interoperability](https://workspaceupdates.googleblog.com/2026/02/meet-hardware-microsoft-teams-intero.html)).
  Interop is transitional — it keeps the split estate working, not a permanent end state.

## Coexistence during the cutover
Because users move in waves, a migrated user and a not-yet-migrated user must still collaborate. The
coexistence design defines: which users are on Chat/Meet vs Teams at any point, how meetings interop
across the two (calendar sync + Meet↔Teams join), and the expectation that **live chat does not bridge
1:1 across the two platforms** — so waves are kept to coherent teams/business units to minimize
cross-platform chat during the split. Coexistence is **time-boxed** and decommissioned as waves
complete.

## The named artifacts
Author these once and reuse them for every wave. Fixed names keep the migration legible across owners
and waves.

| Artifact | Name |
|---|---|
| Source Teams estate baseline | `GWCHAT Discovery - Teams Estate - Baseline` |
| Channel → space mapping | `GWCHAT Mapping - Channels to Spaces - Program` |
| Meetings transition design | `GWCHAT Meetings - Teams to Meet - Transition` |
| Coexistence design | `GWCHAT Coexistence - Chat & Meet - Transition` |
| Wave plan | `GWCHAT Wave Plan - Segmentation - Teams` |
| Per-wave cutover runbook | `GWCHAT Runbook - Cutover - Per Wave` |
| Go/no-go gate | `GWCHAT Gate - Go/No-Go - Per Wave` |
| Adoption & comms plan | `GWCHAT Adoption - Change & Comms - Program` |

## Workstream sequencing
Ordered by dependency, not convenience:

- **Identity first.** Users and groups must exist in Google (via directory sync — GCDS or SCIM) before
  any space, meeting, or file lands, and before coexistence can address them.
- **Files and identity underpin spaces.** A channel's files move via the Drive workstream; the
  channel→space mapping records which Drive location each space points at, so a space isn't created
  without its content home.
- **Coexistence before the first wave.** Meeting interop (calendar sync + Meet↔Teams) must be live
  before anyone cuts over, so a migrated and a not-yet-migrated user can still meet.
- **Chat, meetings, files per wave.** Within a wave, spaces are created and (optionally) history
  imported, meetings are re-issued on Meet, and the wave's Drive content is finalized.
- **Decommission last.** Interop and the Teams source footprint are retired only after the final wave
  clears hypercare — with the Teams source retained for legal hold as long as policy requires.

## What this is not
This solution governs the mapping, sequencing, coexistence, and adoption — the orchestration. It does
**not** re-document the internal console steps of any specific migration tool, and it does **not** move
the underlying files (that's the Drive migration solution). Its scripts read **Microsoft Teams /
Microsoft 365** through Microsoft Graph, read-only; they move no messages, create no meetings, and
change nothing on either platform.

## The deployment model
> Baseline the Teams estate and design the mapping once, stand up meeting coexistence, prove the full
> cutover on a named pilot wave, validate against the go/no-go gate, then expand wave by wave until the
> estate is on Chat and Meet — the repeatable way: Assess, then Configure, then Pilot, then Validate,
> then Expand.
