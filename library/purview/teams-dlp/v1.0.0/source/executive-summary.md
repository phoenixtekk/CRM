# Executive Summary — Teams Chat & Channel DLP in Microsoft Purview

## The problem

Microsoft Teams is where a large share of real-time work — and sensitive data — now moves. A payment
card number pasted into a **chat**, a client's health record dropped into a **channel post**, a
confidential contract **shared as a file** in a team: these are everyday Teams actions, and without a
control they flow to whoever is in the conversation, **including external guests and federated
users**. Left unaddressed, that is both a **compliance gap** and a direct **data-risk exposure**.

## The solution

This solution delivers **Microsoft Purview Data Loss Prevention for Teams** end to end, covering the
two ways sensitive data moves through Teams:

- **Teams messages (chat + channel):** a DLP rule detects sensitive content in 1:1/group chats and
  channel posts, blocks the message with a **policy tip**, and applies differently to **internal**
  versus **external** recipients.
- **Files shared in Teams:** files shared in a **chat** live in the sender's **OneDrive** and files
  shared in a **channel** live in the team's **SharePoint** site — so the policy also spans
  **SharePoint** and **OneDrive** to govern those files. Enabling only the message location would
  leave shared files uncovered; this solution closes that common gap.

Crucially, every rule is **piloted in simulation/test mode first** — it records what it *would* do
without blocking anyone — validated on a small user ring, and only then moved to **enforce**.

## How it works — the model

The delivery follows a disciplined, repeatable model with an explicit pass/fail gate at each step:

**Assess → Design → Configure → Pilot (simulation) → Validate → Expand (enforce).**

Because a block on a Teams message or shared file interrupts real collaboration, nothing is enforced
until it has been proven, in simulation, to see the right content and act only where intended — with a
one-command rollback available at all times.

## What you get

- A complete document set: Overview, Requirements, an ordered Implementation guide, Testing
  (pass/fail gates), Troubleshooting, Best Practices, and this summary.
- **Five PowerShell tools** (Security & Compliance PowerShell / Microsoft Graph) — discovery,
  configuration (simulation, `-WhatIf` first), validation, reporting, and scope/health — all
  **read-only or preview by default, with no credentials in code.**
- A **defensibility evidence pack**: proof of what was configured across messages **and** files, that
  each path was validated in simulation before enforcement, and that enforcement (including
  internal-vs-external) behaves as designed.

## Scope and boundaries

- Teams **message-level** DLP is **licensing-dependent** (a premium capability — verified against the
  Microsoft Purview service description for your tenant) and the Purview portal and Teams DLP scope
  (e.g. private/shared channels) **evolve** — capability availability and exact paths are **verified
  against your licensing/tenant**, never assumed.
- **Regulatory, records, and legal determinations** — which data is sensitive, which paths must be
  blocked versus audited, and whether a message or share is a violation — remain with your
  **compliance, security, records, privacy, and legal** functions. This solution provides the
  **technical method and the evidence**, not the determination.

## The bottom line

Sensitive data moving through **Teams chats, channels, and shared files** becomes a **monitored, then
enforced** control in Microsoft Purview — messages and files, internal and external — **configured,
piloted in simulation, validated, and defensible.**
