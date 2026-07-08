# Solution Overview — Exchange Online DLP in Microsoft Purview

## What this solution delivers

Email is the single most common channel through which sensitive data leaves an organization. A
credit-card list pasted into a message, a spreadsheet of national IDs attached and sent to a personal
address, a *Confidential*-labeled contract forwarded to an outside party — every one of those is an
outbound email that today may leave with **nothing watching it**. **Microsoft Purview Data Loss
Prevention (DLP) for Exchange Online** closes that gap: it inspects messages in the transport
pipeline against your **sensitive content** and can **notify**, **warn (with override)**, **encrypt**,
or **block** the message before it leaves — and it can show the sender a **policy tip** explaining
why, at the moment they hit *Send*.

This solution walks a competent-but-novice administrator through a **complete, repeatable Exchange
Online DLP deployment**:

1. **Discover what already exists** — inventory any DLP policies already scoped to Exchange, how they
   interact with **Exchange mail-flow (transport) rules**, which sensitive information types (SITs) and
   sensitivity labels are available to key on, and the current policy **modes**.
2. **Design the policy** — decide, with your compliance/security stakeholders, *which* sensitive
   content matters (SITs, sensitivity labels), *which* recipient scope is risky (external vs internal,
   trusted-partner domains), and *which* action each scenario takes (**notify / warn / encrypt /
   block**).
3. **Author one Exchange Online DLP policy** with a small set of rules covering the core scenarios —
   sensitive content to **external** recipients, sensitivity-labeled mail to external recipients,
   internal visibility — **piloted in simulation/test mode first** so nothing is blocked until you have
   validated it, and with **policy tips** configured for user guidance.
4. **Validate, then enforce and expand** — prove in simulation that each rule *sees* the right mail and
   *would* act on the right content, then move the rules from simulation to **enforce**, one scenario
   at a time, with an explicit pass/fail gate and a documented rollback at every step.

The result turns **unmonitored outbound email** into a **monitored, then enforced** control set on
Exchange Online — configured, piloted, validated, and defensible in Microsoft Purview.

## What Exchange Online DLP is (and is not)

- **It is** the application of Purview Data Loss Prevention to the **Exchange** location — inspecting
  message content, attachments, and properties in the transport pipeline and taking a rule action
  (notify, policy tip, allow-with-override, encrypt, block, incident report) when a message matches
  your conditions.
- **It is not** the same thing as an **Exchange mail-flow (transport) rule**. Both act on mail in
  transport and *both can coexist*, but Purview DLP is authored in the **Purview compliance** surface
  (policies + rules over the whole M365 estate), evaluates alongside transport rules, and is the
  strategic home for content-based data-loss control. This solution uses **Purview DLP**; it flags
  where transport-rule interaction matters (see `06-troubleshooting.md`).
- **It is not** a substitute for your SharePoint/OneDrive/Teams/Endpoint DLP — Exchange is **one
  location**. A single DLP policy *can* span multiple locations; this solution focuses on the
  **Exchange** location.
- **It is licensing-dependent.** Baseline DLP for Exchange is broadly available, but **advanced**
  capabilities (some conditions/classifiers, simulation reporting depth, certain encryption actions)
  can require **Microsoft 365 E5** or the **E5 Compliance** add-on, and the portal is **evolving** —
  **verify capability availability and exact portal paths/cmdlet parameters against your
  licensing/tenant** rather than assuming (see `global-requirements-purview.md` §1).

## The scenarios this solution controls

Each is an email condition the DLP policy can detect and, in a rule, **Notify (policy tip)**, **Warn
with override**, **Encrypt**, or **Block**:

| Scenario | What the rule keys on |
|---|---|
| **Sensitive info → external (high volume)** | A message containing a sensitive information type (e.g. credit card, national ID) above a chosen instance count, sent to recipients **outside** the organization. |
| **Sensitive info → external (low volume)** | The same, at a lower instance count — usually **warn with policy tip / allow override** rather than hard block. |
| **Labeled mail → external** | A message (or attachment) carrying a **sensitivity label** such as *Confidential*, sent externally — often **encrypt** or **block**. |
| **Sensitive info → internal** | Sensitive content sent to **internal** recipients — usually **audit / notify** for visibility, not block. |
| **Trusted-partner exception** | Recipient domains you explicitly trust are treated as an **exception** so sanctioned business flows are not blocked. |

> **Policy tips.** When a rule is configured to notify the sender, Exchange can display a **policy
> tip** in Outlook (desktop/web) at compose time — explaining the issue and, where configured,
> offering **override with business justification** or **report false positive**. Policy tips are a
> user-education control, not just an enforcement control. **Verify tip behavior per Outlook client in
> your tenant.**

## Simulate first — this is a high-impact control

A DLP **block** action stops a real message from being delivered. A mis-scoped rule can block
legitimate business email mid-flow. Therefore **every** policy in this solution is deployed in
**simulation/test mode first**. Exchange Online DLP policies support four modes —
**`Enable`** (enforce), **`Disable`** (off), **`TestWithNotifications`** (simulate *and* show policy
tips), and **`TestWithoutNotifications`** (simulate silently). In a Test mode the policy **evaluates
and records what it *would* do without blocking or encrypting anyone** — validated on a pilot sender
scope, and only then moved to **`Enable`**. **Verify the exact mode names/behavior in your tenant**
(the portal wording evolves).

> **Determinations are not yours to make.** *Which* data is sensitive, *which* scenarios must be
> **blocked** versus merely **audited**, *whether* a given message is a policy violation, and *whether*
> a recipient domain is "trusted" are **compliance / security / privacy / legal** determinations —
> this solution delivers the technical configuration and the evidence, not the determination (see
> `global-requirements-purview.md` §5).

## The standard deployment model

Every step follows the same repeatable model, with an explicit **pass/fail gate** between phases:

**Assess → Design → Configure → Pilot (simulation/test) → Validate → Expand (enforce).**

- **Assess** — confirm licensing, least-privilege roles, in-scope sensitive content (SITs/labels), the
  recipient-scope decisions, the pilot sender scope, and compliance/security stakeholder sign-off.
- **Design** — decide which scenarios **notify** vs **warn** vs **encrypt** vs **block**, name every
  policy/rule/object, define the trusted-partner exception, and set the pilot scope.
- **Configure** — build the policy and its rules **in simulation/test mode**, with policy tips.
- **Pilot** — run in simulation on the pilot senders; confirm each scenario is seen and *would* act.
- **Validate** — run the pass/fail gates in `05-testing.md`.
- **Expand** — move rules from simulation to enforce and widen scope **only** after the gate passes;
  roll back per `03-implementation.md` if a gate fails.

## What's in the box

- This overview, a **Requirements** guide, an ordered **Implementation** guide, **Testing**
  (pass/fail gates), **Troubleshooting**, **Best Practices**, and a **Deliverables Summary** +
  **Executive Summary**.
- **Five PowerShell tools** (Security & Compliance PowerShell via `Connect-IPPSSession`): a
  **Discovery** inventory of existing Exchange-scoped DLP config, transport-rule interaction, SITs and
  labels, and current modes; a **Configure/Remediation** helper that builds the policy + rules in
  **simulation (`-WhatIf` first, writes gated by `-Commit`)**; a **Validation** checker; a
  **Reporting** rollup of DLP rule matches / policy-tip / block events; and a **scope/health** helper —
  **read-only or `-WhatIf` by default; no credentials in code.**

> **Sources.** Microsoft Learn — *Learn about data loss prevention*, *Create and deploy data loss
> prevention policies* (conditions, actions, simulation mode), *Data loss prevention policy tips
> reference*, *DLP policy conditions and actions for Exchange*, and the Security & Compliance
> PowerShell reference for `*-DlpCompliancePolicy` / `*-DlpComplianceRule` /
> `Get-DlpSensitiveInformationType`. DLP capability is **licensing-dependent** and the Purview portal
> is **evolving** — **verify capability availability, portal paths, and cmdlet parameters against your
> licensing/tenant** rather than assuming.
