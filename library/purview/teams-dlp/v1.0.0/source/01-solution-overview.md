# Solution Overview — Teams Chat & Channel DLP in Microsoft Purview

## What this solution delivers

Microsoft Teams is where a great deal of an organization's real-time work now happens — and a great
deal of its sensitive data. A credit-card number pasted into a **1:1 chat**, a client's health
record dropped into a **channel post**, a confidential contract **shared as a file** in a team: these
are everyday Teams actions, and without a control they flow to whoever is in the conversation —
including **external guests and federated users**. Left unaddressed, that is both a **compliance
gap** and a direct **data-risk exposure**.

This solution delivers **Teams chat & channel Data Loss Prevention** end to end in Microsoft Purview,
covering the two ways sensitive data moves through Teams:

1. **Teams messages (chat + channel).** A DLP policy on the **Teams chat and channel messages**
   location can **detect and act on** sensitive content in **1:1 and group chats**, **standard and
   private channel messages** — blocking the message, showing a **policy tip**, and (critically)
   applying differently to **internal** versus **external / everyone** recipients.
2. **Files shared in Teams.** Files shared in a Teams **chat** live in the sender's **OneDrive**, and
   files shared in a **channel** live in the team's **SharePoint** site — so **SharePoint Online** and
   **OneDrive** DLP is what governs Teams-shared files. This solution configures those locations in
   the same policy so a "Teams DLP" control actually covers the files too, not just the message text.

The result is *stop sensitive data in Teams messages and files* — configured, **piloted in
simulation/test** first, validated, and defensible.

This solution walks a competent-but-novice administrator through the complete, repeatable
deployment:

1. **Confirm licensing, roles, and in-scope sensitive content** — Teams message DLP is
   licensing-dependent; the content to protect (labels / sensitive info types) must exist.
2. **Author the policy in simulation/test mode first** — the Teams-message rule(s) and the
   SharePoint/OneDrive file rule(s), each keyed to your sensitive content, with the internal-vs-
   external recipient logic — **nothing blocked** yet.
3. **Validate on a pilot ring** — prove, on a small pilot user group, that the message and file
   activity is *seen* and *would* act; then move rules from simulation to **enforce** deliberately,
   with an explicit pass/fail gate and a documented rollback at every step.

## The two coverage areas (how Teams DLP actually maps)

| Area | Where the data lives | DLP location that governs it |
|---|---|---|
| **Teams messages** — 1:1 chat, group chat, standard & private channel posts | The Teams messaging service | **Teams chat and channel messages** location (a DLP location in its own right). |
| **Files shared in a Teams chat** | The **sender's OneDrive** | **OneDrive** location. |
| **Files shared in a Teams channel** | The **team's SharePoint site** | **SharePoint** location. |

> **This is the key insight most "Teams DLP" projects miss:** the **message** location and the
> **file** locations are **different**. A policy that only enables the Teams-messages location leaves
> **shared files uncovered**. This solution enables **all three** so the control is complete. **Verify
> the exact location names and Teams message-scope (chat vs channel vs private/shared channel)
> coverage against your licensing/tenant** — Teams DLP scope and the portal evolve.

## What Teams message DLP is (and is not)

- **It is** the extension of Purview Data Loss Prevention to the **Teams chat and channel messages**
  location — detecting sensitive content in messages and applying an action (block the message with a
  policy tip, differentiated for internal vs external recipients).
- **It is not** a retention, eDiscovery, or communication-compliance control. Those are separate
  Purview capabilities; this solution is **DLP** (preventing sensitive-data leakage), not records or
  conduct monitoring.
- **It is licensing-dependent.** Teams DLP (especially chat/channel-message DLP) is a premium
  capability — **verify the exact licensing required for message-level DLP against the Microsoft
  Purview service description for your tenant** (it typically requires E5-tier or equivalent
  compliance licensing, and message-level DLP has specific requirements). Some scope (e.g. private/
  shared channels) and portal paths evolve — **verify against your licensing/tenant** rather than
  assuming (see `global-requirements-purview.md` §1).

## Simulate first — these are high-impact controls

A **block** on a Teams message stops a real conversation at the moment someone hits send; a block on a
shared file interrupts collaboration. A mis-scoped rule can block legitimate work. Therefore:

- The policy is deployed in **simulation/test mode first** (the DLP policy modes *Test with
  notifications* / *Test without notifications*; in the portal, *"Run the policy in simulation
  mode"*) — it **evaluates and records what it *would* do without blocking anyone** — validated on a
  small pilot user group, and only then moved to **enforce**.

**Verify the exact simulation/test terminology in your tenant** (the wording evolves).

> **Determinations are not yours to make.** *Which* data is sensitive, *whether* a given message or
> shared file is a policy violation, and *what* action a channel warrants are **compliance / records /
> security / HR-legal** determinations — this solution delivers the technical configuration and the
> evidence, not the determination (see `global-requirements-purview.md` §5).

## The standard deployment model

Every step follows the same repeatable model, with an explicit **pass/fail gate** between phases:

**Assess → Design → Configure → Pilot (simulation) → Validate → Expand (enforce).**

- **Assess** — confirm licensing, least-privilege roles, the in-scope sensitive content, the pilot
  user group, and compliance/security stakeholder sign-off.
- **Design** — decide the message action (block / policy tip) and the internal-vs-external logic, the
  file action, name every object, and set the pilot scope.
- **Configure** — build the DLP policy across the **Teams messages + SharePoint + OneDrive** locations
  in **simulation**, with the message and file rules.
- **Pilot** — run in simulation on the pilot users; confirm the message and file activity is seen and
  *would* act without blocking anyone.
- **Validate** — run the pass/fail gates in `05-testing.md`.
- **Expand** — move rules to enforce and widen scope **only** after the gate passes; roll back per
  `03-implementation.md` if a gate fails.

## What's in the box

- This overview, a **Requirements** guide, an ordered **Implementation** guide, **Testing**
  (pass/fail gates), **Troubleshooting**, **Best Practices**, and a **Deliverables Summary** +
  **Executive Summary**.
- **Five PowerShell tools** (Security & Compliance PowerShell / Microsoft Graph): a **Discovery**
  inventory of existing DLP policies, the Teams/SharePoint/OneDrive coverage, labels, and SITs; a
  **Configure/Remediation** helper that builds the Teams-message + file DLP policy in **simulation
  (`-WhatIf` first)**; a **Validation** checker; a **Reporting** rollup of policy modes and DLP
  activity; and a **scope/health** helper — **read-only or `-WhatIf` by default; no credentials in
  code.**

> **Sources.** Microsoft Learn — *Learn about the default data loss prevention policy in Microsoft
> Teams*, *Data loss prevention and Microsoft Teams*, *Create and deploy data loss prevention
> policies* (locations, conditions, actions, simulation mode), and the *Microsoft Purview service
> description* (licensing for Teams message DLP). These capabilities are **licensing-dependent** and
> the Purview portal is **evolving** — **verify capability availability, the Teams message scope,
> portal paths, and cmdlet parameters against your licensing/tenant** rather than assuming.
