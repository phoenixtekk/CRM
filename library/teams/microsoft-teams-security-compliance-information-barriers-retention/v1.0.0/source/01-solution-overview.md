# 1. Solution Overview — Microsoft Teams Security & Compliance: Information Barriers, Retention & DLP

## What this solution is
Microsoft Teams carries chats, channel messages, and files that fall under the same compliance
obligations as email and documents — but the **Teams-specific** controls are easy to miss when an
organization stands up a broad Microsoft Purview program. This solution applies the compliance
controls that are **specific to Teams**:

1. **Information barriers (IB)** — policies that stop two defined groups of people from communicating
   in Teams (chat, calls, meeting invites, and being added to the same team). Used where regulation
   or policy requires an "ethical wall" (for example a group that must not talk to another group).
2. **Teams retention** — retention policies scoped to **Teams chat messages** and **Teams channel
   messages** (and, where used, **private-channel** and **shared-channel** messages), so Teams
   conversations are kept for a required period and then deleted, or blocked from deletion.
3. **Teams DLP** — Data Loss Prevention policies scoped to the **Teams** location, which detect
   sensitive content in Teams chats and channel messages and audit, warn on, or block it.

This solution deliberately covers **only the Teams-specific slice**. The broad Purview program —
the sensitivity-label taxonomy, org-wide DLP across Exchange/SharePoint/OneDrive/endpoint, retention
labels and records management — is referenced, not rebuilt. If your organization already runs a
Purview program, this solution extends it into Teams; if it does not, the Requirements Guide points
to that broader work.

## How it works
1. **Information barriers** are built from **segments** (groups of users defined by a directory
   attribute — Department, `MemberOf`, and so on) and **IB policies** that either *block* or *allow*
   communication between segments. You define the segments, define the policies, then run a tenant
   **application** step that evaluates every user against the segments and enforces the barriers.
   Barriers show up in Teams as blocked chats/searches and prevention from joining the same team.
2. **Teams retention** uses a retention policy whose **locations are the Teams locations only**
   (Teams chat, Teams channel messages). A retention **rule** on that policy sets the duration and the
   end-of-life action (retain, retain-then-delete, or delete-only). Teams retention writes to the
   hidden `SubstrateHolds` / mailbox folders that back Teams messages.
3. **Teams DLP** uses a DLP policy scoped to the **Teams** location with a rule that matches
   sensitive-information types or sensitivity labels. As with all DLP, you deploy it first in a
   **test / audit** mode, review the matches (the **DLP audit gate**), tune out false positives, then
   switch to enforce (notify or block).
4. Every artifact is created with a **consistent name** and validated on a **pilot scope** before it
   is expanded, with a documented rollback at each gate.

## The reference design (named artifacts)
The implementation creates and reuses these exact names (yours will differ by content, but the
naming convention `<Purpose> – <Scope> – <Stage>` is the point):

- Segments: `IB Segment – GroupA – Prod`, `IB Segment – GroupB – Prod`
- IB policy: `IB Policy – GroupA-blocks-GroupB – Pilot`
- Retention: policy `Retention Policy – Teams Chat+Channel – Pilot`, rule `Retention Rule – Teams 7yr – Pilot`
- Teams DLP: policy `DLP Policy – Teams Sensitive – Pilot`, rule `DLP Rule – Teams PII – Pilot`

## What you can control
- **Information barriers:** which segments exist (by attribute), which segments are blocked from or
  allowed to communicate, and when the barriers are applied tenant-wide.
- **Teams retention:** the duration, the trigger (when content was created / last modified), and the
  end-of-life action for Teams chat and channel messages — including private and shared channels.
- **Teams DLP:** which sensitive-information types or labels a Teams policy matches, whether it runs
  in test or enforce mode, and the action (audit, notify with a policy tip, or block the message).

## Benefits
- **Ethical walls that actually hold** — IB blocks Teams chat, calls, and team membership between
  groups that must stay separated, enforced by the platform rather than by policy on paper.
- **Defensible Teams retention** — Teams conversations are kept and deleted on a defined schedule,
  closing the gap most Purview rollouts leave open (email and files retained, Teams chat not).
- **Sensitive content controlled in chat** — Teams DLP catches PII and other sensitive content in
  chats/channels, tuned in audit before it ever blocks a real conversation.
- **Aligned, not duplicated** — the Teams controls plug into the org's existing Purview program using
  the same sensitive-information types, labels, and audit surface.

## Limitations (be honest with buyers)
- **Information barriers, Teams DLP, and org-wide retention are plan-gated.** IB and Teams DLP
  typically require the higher Microsoft 365 / Purview compliance plans (E5 / E5 Compliance or the
  standalone add-on); adaptive-scope retention likewise. The Requirements Guide names the licensing —
  **verify the exact entitlement in your tenant.**
- **IB application is tenant-wide, not per-pilot.** Once you start IB policy application it evaluates
  every user. You "pilot" IB by defining the segment attribute so that **only pilot users carry it**,
  validating, then expanding the attribute's coverage — not by scoping the application run.
- **Teams retention deletion is irreversible** once the period elapses; validate the schedule on a
  pilot scope first.
- **Records schedules, legal-hold determinations, and the IB policy definitions themselves are
  compliance/legal decisions, not technical ones.** This solution provides the technical method and
  the evidence; **the determination of who-must-not-talk-to-whom, and how long to keep what, is
  deferred to your compliance, records, and legal functions.**
- Teams retention and IB interact with other holds (eDiscovery holds, Litigation Hold); content under
  a hold is preserved regardless of a delete action. Coordinate with the eDiscovery/legal owners.

## The standard deployment model
> **Assess → Design → Configure → Pilot → Validate → Expand**, pilot-first, with explicit pass/fail
> gates and a documented rollback. Information barriers, retention deletion, and DLP enforcement are
> **high-impact** — each is deployed to a named pilot scope, validated against a gate, and only then
> expanded. Automation is delivered as **PowerShell** (Security & Compliance PowerShell / the
> MicrosoftTeams module / Microsoft Graph), read-only or `-WhatIf` by default, with no credentials in
> code.
