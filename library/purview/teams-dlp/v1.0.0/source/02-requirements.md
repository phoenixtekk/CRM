# Requirements — Teams Chat & Channel DLP in Microsoft Purview

Confirm every prerequisite below **before** you configure anything. Category-level prerequisites
(tenant, compliance licensing model, least-privilege roles, Security & Compliance PowerShell / Graph
toolchain, in-scope data sources, compliance/privacy/legal stakeholders, pilot scope + change
control) are in `global-requirements-purview.md` — reference them; they are **not** repeated here.
The items below are the ones **specific to Teams DLP**: the **message-level licensing**, the **three
locations** (Teams messages, SharePoint, OneDrive), and the **internal-vs-external** control decision.

Each requirement is written as **Description · Why · Verify · Implement if missing.**

---

## R1. Licensing that includes Teams message DLP, assigned to in-scope users

**Description:** The compliance licensing that includes **DLP for Teams chat and channel messages**,
assigned to the in-scope users. **Verify the exact requirement against the Microsoft Purview service
description for your tenant** — message-level Teams DLP is a premium capability (typically E5-tier /
equivalent compliance licensing) and has its own licensing specifics distinct from file DLP.
**Why:** Message-level Teams DLP is plan-gated; without the right licence the **Teams chat and channel
messages** location and message actions are not available, and message DLP is licensed **per user**.
**Verify:** Microsoft 365 admin center → **Billing → Licenses** confirms the SKU/add-on. In the
Purview portal, **Data Loss Prevention** exposes the **Teams chat and channel messages** location.
Cross-check against the *Microsoft Purview service description* — **verify against your
licensing/tenant.**
**Implement if missing:** Acquire and assign the required SKU/add-on to in-scope users before
authoring the message rule. (File DLP via SharePoint/OneDrive may be available on lower tiers — but
the message rule needs the message-DLP entitlement.)

## R2. Least-privilege roles for DLP authoring

**Description:** The least-privilege roles, mapped to **named** people — **Compliance Administrator**
or **Compliance Data Administrator** (or the **DLP Compliance Management** role group) to author the
DLP policy and rules — with **Global Administrator** only where genuinely required.
**Why:** Purview uses fine-grained role groups; policy authoring requires the matching role and should
not be over-granted.
**Verify:** Purview portal → **Roles & scopes / Permissions** confirms the DLP role membership.
`DLPTEAMS-Discovery.ps1` reports the DLP policy/role signals it can read.
**Implement if missing:** Assign the least-privilege DLP role under change control.

## R3. Teams deployed with the in-scope chat/channel surfaces identified

**Description:** Microsoft Teams in use, with the **message surfaces** in scope identified — **1:1 and
group chats**, **standard channel** messages, and (where covered by your licensing/tenant) **private
channel** and **shared channel** messages. Whether **external / federated** participants are in scope
must be stated.
**Why:** Teams message DLP applies to specific surfaces; the design must state which are covered and
whether external recipients are treated differently. Coverage of private/shared channels varies —
**verify for your tenant.**
**Verify:** Confirm in the Teams admin experience which surfaces are in use and whether external
access/federation is enabled. **Verify the private/shared-channel DLP coverage against current
Microsoft docs for your tenant.**
**Implement if missing:** Document the in-scope surfaces and the external-participant posture with
stakeholders before authoring rules.

## R4. In-scope sensitive content to key the rules on (labels and/or SITs)

**Description:** The **sensitive content** the rules will match — **sensitivity labels** (e.g.
*Confidential*) already published and in use, and/or **sensitive information types** (built-in or
custom) and/or trainable classifiers — that define *what* triggers the message/file rules.
**Why:** A DLP rule acts on **content that matches a condition**; without labels or SITs to match, the
rule has nothing to key on (or would apply to *all* content, which is rarely intended).
**Verify:** Purview → **Information Protection → Labels** shows the labels published; **Data
classification → Sensitive info types** shows the SITs; in-scope content carries labels (Activity/
Content explorer where available). `DLPTEAMS-Discovery.ps1` inventories labels and SITs.
**Implement if missing:** Publish/adopt the needed sensitivity labels or select the SITs first.

## R5. All three DLP locations understood: Teams messages + SharePoint + OneDrive

**Description:** A clear understanding — and the intent to enable — the **three** locations a complete
"Teams DLP" needs: **Teams chat and channel messages** (the message text), **SharePoint** (files
shared in **channels**), and **OneDrive** (files shared in **chats**).
**Why:** Enabling only the Teams-messages location leaves **shared files uncovered**, because
Teams-shared files physically live in SharePoint/OneDrive. A complete control needs all three.
**Verify:** Purview → **Data Loss Prevention** shows all three locations available for a policy.
`DLPTEAMS-Discovery.ps1` reports which locations existing policies cover. **Verify the location names
against your tenant.**
**Implement if missing:** Plan the policy to span all three locations (or explicitly document a
scope decision to cover messages only — but then say so, since files remain uncovered).

## R6. Message action + internal-vs-external decision — agreed with stakeholders

**Description:** A documented decision, agreed with **compliance / security** (and HR/legal where the
action affects users), of:
- The **message action** — block the message with a **policy tip**, notify only, and whether users can
  **override** with business justification.
- The **internal vs external** logic — e.g. audit-only for internal recipients but **block** when the
  content is shared with **external / everyone** (a common Teams DLP posture).
- The **file action** for SharePoint/OneDrive-shared files (block external sharing, notify, etc.).
**Why:** The action is a **policy decision, not a technical default**; blocking a Teams message or an
external share has real operational impact and must reflect enterprise policy.
**Verify:** Confirm the action matrix (internal vs external, message vs file) and the in-scope content
**in writing** before you move any rule from simulation to enforce.
**Implement if missing:** Capture the decision with the relevant owners; until then, deploy **audit /
simulation only.** (See `global-requirements-purview.md` §5.)

## R7. A named pilot user group and change control (simulation/test first)

**Description:** A **named pilot user group** (e.g. `SG-TeamsDLP-Pilot`) and agreement to run the
policy in **simulation/test mode first**, under a **change-control** process, before any enforcing,
broad-scope rollout.
**Why:** Teams-message and file block actions are high-impact; simulation on a small ring proves the
message/file activity is seen and the rules *would* act **without** disrupting real work, and lets you
tune before enforcing.
**Verify:** Confirm the pilot group exists, that **simulation/test mode** is used, and a change
window/approval path. `DLPTEAMS-ScopeHealth.ps1` (`-WhatIf`) previews pilot-scope targeting.
**Implement if missing:** Define the pilot group, deploy in simulation, and agree change control
before enabling enforcement.

## R8. Policy-tip / user-notification content prepared (where used)

**Description:** The **policy-tip text** and any **user notification / email** content that will show
when the message rule fires (e.g. "This message contains sensitive information and was not
delivered"), prepared and approved.
**Why:** A clear, approved policy tip reduces friction and supports the lawful, transparent operation
of the control; a confusing or absent tip generates tickets and workarounds.
**Verify:** Confirm the policy-tip/notification text is drafted and approved by the relevant owners.
**Implement if missing:** Draft the tip/notification content with compliance/communications before
enforcing; simulation can run without it, but enforce should have it.
