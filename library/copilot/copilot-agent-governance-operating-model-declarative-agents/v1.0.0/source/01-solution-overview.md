# Solution Overview

## The problem this solves

Your users can now build their own AI agents. In the **Agent Builder** experience inside Microsoft
365 Copilot, a business user describes what they want in plain language, points the agent at some
SharePoint sites, Teams chats, or public websites for knowledge, clicks **Create**, and then shares
the result with a colleague, a team, or the entire organisation — all without writing code and, in
most tenants, without anyone in IT ever seeing it.

That is a genuine productivity breakthrough. It is also a governance gap, because these
business-process agents raise exactly the questions that no packaging tool, no DLP policy, and no
label taxonomy answers:

- **Who owns this agent?** Not "who clicked Create" — who is accountable when it gives a wrong
  answer to a customer, when its instructions drift, or when Security asks whether it still needs the
  data access it has.
- **Who said it could go into business use?** Copilot Studio agents can be routed through an
  admin approval gate before publication. A declarative agent built in **Agent Builder** and shared
  directly with "Anyone in your organization" **can reach the whole tenant without any approval at
  all** — that is the specific gap this product closes.
- **Who is it shared with, and should it be?** An agent built over a Finance SharePoint site and
  shared org-wide is a data-exposure decision that was never reviewed.
- **When does it get retired?** The user who built it has left. The agent still runs, still answers,
  still holds its knowledge sources. Nobody decides to switch it off.

When these questions have no answer, the tenant accumulates **ownerless agents** (the creator left,
nobody maintains them), **unreviewed agents** (no data or sharing review, quietly reaching more
people than intended), and **shadow agents** (running with no registry entry and no accountable
owner). Better tooling does not fix this. What fixes it is an **operating model**: named roles, a
defined intake path, a decision forum with authority, published standards, a sharing policy with
review, a lifecycle with real retirement, and metrics that prove it works.

**This solution is that operating model.** It is deliberately a *governance* product, scoped to the
low-code, business-user-built **declarative agents** created in **Agent Builder** (and their
Copilot Studio equivalents) that are used inside business processes.

## What this solution is NOT

This package does **not** teach anyone how to *build* an agent, and it does **not** rebuild the
sibling products it depends on. Specifically, it does **not** cover:

- **How to author a declarative agent** — instructions, knowledge sources, prompt design,
  capabilities. That is the maker's job in Agent Builder / Copilot Studio.
- **The technical inventory and sharing-posture export** — enumerating every agent, its sharing
  links, and the `copilotPackages` Graph diagnostic in depth. That is delivered by the sibling
  product *Copilot Agent Builder — Inventory, Sharing Governance & Export*, which owns the Graph
  endpoint diagnostic. This solution **consumes** that inventory as an input to the register; it does
  not reproduce the export tooling. (A lightweight governance-baseline discovery is included so you
  can start without the sibling, but the deep, repeatable export lives there.)
- **Copilot data governance with Microsoft Purview** — sensitivity labels, DLP for Microsoft 365
  Copilot, auto-labelling, audit/eDiscovery of Copilot interactions. Delivered by the Copilot data
  governance / DLP guardrails solution. This model defines *when* a data review is required and *who*
  is accountable; it does not re-teach how to configure a DLP policy.
- **SharePoint / OneDrive oversharing remediation** — fixing who can reach what. Delivered by the
  Copilot oversharing / SharePoint-permissions solution. Agents inherit that access posture; this
  model references it as a prerequisite, not a deliverable.

What it **does** cover is the layer above all of that: **who may build a business agent, on what
basis it is allowed into business use, who it may be shared with, who is accountable afterwards, and
when it is retired** — plus exactly how each of those decisions is expressed and enforced in the
Microsoft 365 admin center (the **Copilot Control System** and the **Agent Registry**) so the
governance is enforced rather than aspirational.

## The seven components of the operating model

The model has seven components. Each is defined in this package, and each produces a **named,
durable artefact** the organisation keeps.

### 1. Ownership and RACI

Every business-process agent has **four named accountabilities**:

| Role | Accountable for | Typically held by |
|---|---|---|
| **Agent Owner** | The agent itself — its instructions, knowledge sources, behaviour, runbook, and keeping it correct. Usually the maker who built it. | The business user or power user who created the agent. |
| **Business Sponsor** | The business need. Whether the agent should exist at all, the value it delivers, and its retirement. | A business function lead (Finance, HR, Sales, Clinical). |
| **Data & Security Reviewer** | The risk: what data the agent can reach, how widely it is shared, sensitivity/label exposure, and DLP posture. | Information Security / data governance. |
| **Agent Admin** | Enforcing decisions in the Microsoft 365 admin center — approve, publish, block, reassign, retire. | Copilot / M365 administrator holding the **AI Administrator** role. |

The artefact is the **AGBGOV – Agent Register** — the authoritative list of every business-process
agent, its four accountabilities, its review status, and its lifecycle state. Section 3 (Step 3)
builds it, and `AGBGOV-Discovery.ps1` seeds it from your tenant.

### 2. Build eligibility and the intake / approval gate

Two decisions, made explicit:

- **Who may build agents at all.** Not every user needs to. Agent creation is governed centrally in
  the Copilot Control System (agent access settings) and, for org-wide sharing, by an explicit
  policy.
- **The gate before an agent enters business use.** The customer is right that Copilot Studio's own
  publish flow already routes *its* agents through an admin approval before they reach the org
  catalog. The gap is the **Agent Builder** declarative agent shared directly with **"Anyone in your
  organization"**, which bypasses that gate. This model closes the gap by (a) restricting org-wide
  sharing to an approved group and (b) requiring every agent used in a business process — however it
  was built — to pass the **AGBGOV – Agent Review Board** before it is treated as sanctioned.

The artefacts are the **AGBGOV – Agent Intake Request Form** and the **AGBGOV – Agent Intake Queue**.

### 3. The Agent Review Board (ARB)

A standing decision forum with **explicit decision rights**. The ARB can say *approved*, *approved
with conditions*, *deferred pending evidence*, or *rejected*, and its decision is binding. It meets
on a fixed cadence, has defined membership and quorum, and requires a defined **evidence pack** —
including the agent's data-access and sharing posture — before an item is tabled.

The artefact is the **AGBGOV – Agent Decision Record** — one entry per decision, retained for audit.

### 4. Standards and policy

A published definition of what **"approved for business use"** means, so approval is a test rather
than an opinion. Covers the data-and-sharing review criteria, the naming standard applied in the
Agent Registry, the sharing-scope rules, and the supportability bar an agent must clear.

The artefact is the **AGBGOV – Agent Standards – Enterprise – v1.0** and the **naming convention**
applied to agents.

### 5. Sharing policy and access review

The rules for **who an agent may be shared with**, the requirement for a data-access review **before
broad sharing**, and a **periodic access review** of agents that are already shared widely. This is
the component that turns "shared with Anyone in your organization" from an unreviewed default into a
governed decision.

The artefact is the sharing-scope policy inside the standards document and the **AGBGOV –
Shared-Agent Access Review** log, driven by `AGBGOV-Review-SharedAgents.ps1`.

### 6. Lifecycle and change control

An agent is registered, changed, reviewed on a cadence, and — critically — **retired** when it is
stale, ownerless, or risky. The model classifies every change into a **risk tier** with a defined
approval path, and it defines the retirement / decommission process end to end, with evidence.

The artefacts are the **AGBGOV – Agent Change Classification – Enterprise – v1.0** and the **AGBGOV –
Agent Retirement Log**.

### 7. Metrics and evidence

The measures that prove the model works, and the evidence trail that proves it to an auditor.
Coverage (owned, reviewed, ring-appropriate), flow (intake-to-decision time), quality (approval
adherence, retirement completion), and risk (ownerless agents, unmanaged/shadow agents, overdue
reviews, broadly-shared agents).

The artefact is the **AGBGOV – Agent Governance Scorecard**, produced by `AGBGOV-Report.ps1`.

## How declarative agents are built, shared, approved, and managed (verified against Microsoft Learn)

*Verified against Microsoft Learn on 2026-07-24. Agent admin surfaces evolve quickly; where a
control is preview or licence-gated it is flagged. Verify against current Microsoft documentation
before relying on volatile specifics.*

- **Built:** A declarative agent is created in **Agent Builder** inside Microsoft 365 Copilot (or in
  **SharePoint**, or as a "Copilot agent" in **Copilot Studio**) using natural language, with
  knowledge sources from SharePoint, Teams, Outlook, public websites, or Microsoft 365 Copilot
  connectors. Agent Builder requires a Microsoft 365 Copilot licence or a pay-as-you-go Copilot
  Studio tenant.
- **Shared (Agent Builder):** the maker chooses one of three sharing options — **Only you** (default,
  private), **Specific users in your organization** (named users, security groups, security-enabled
  Microsoft 365 groups, or teams), or **Anyone in your organization** (an org-wide sharing link).
  Sharing gives direct access; it does not deploy the agent across channels.
- **Governed sharing:** in the Microsoft 365 admin center an admin sets who may create org-wide
  sharing links — **All users** (default), **Specific users or groups**, or **No users** (org-wide
  sharing disabled). Changes apply only to *new* sharing actions; already-shared agents keep their
  access until the owner updates them.
- **Approved / published:** to become broadly discoverable, an agent is **submitted to the org
  catalog**; an admin **reviews the request** in the admin center and **publishes** it to the **Built
  by your org** section of the **Agent Store**, or **rejects** it. Copilot Studio and custom-engine
  agents publish through the same admin-approval path.
- **Managed:** the **Agent Registry** (Microsoft 365 admin center → **Agents → All agents →
  Registry**) is the central inventory of every agent — Microsoft, external partner, published by
  your org, and shared by creator. From it an admin can **block/unblock**, **delete**, **reassign an
  ownerless agent's owner**, **pin**, **export to CSV** (30+ fields incl. owner, publisher, channel,
  status, instructions), and see **Agents without owners**, **Unmanaged agents**, and **Agents at
  risk** (risk signals aggregated from Microsoft Entra, Purview, and Defender).
- **Roles:** the least-privilege admin role for agent governance is **AI Administrator**; **Global
  Reader** is view-only; **Global Administrator** is highly privileged and reserved for emergencies.

## How this governance plugs into your existing Copilot controls (without re-teaching them)

Governance that lives only in a document is decoration. This model expresses each decision as a
concrete control in the Copilot Control System and connects to the security stack you already own:

| Governance decision | Expressed / enforced as |
|---|---|
| "Only approved people may share agents org-wide." | Copilot Control System **agent sharing** setting → **Specific users or groups** = the `AGBGOV – Agent Sharing – Org-Wide Approved` group. |
| "Only sanctioned people may build agents." | Copilot Control System **agent access** setting → **Specific users/groups** = the `AGBGOV – Agent Builders` group. |
| "This agent is approved for business use." | Admin **publishes** it to **Built by your org** in the Agent Store after ARB approval; the ARB reference is recorded in the register. |
| "This agent is unsafe / non-compliant." | Admin **blocks** it in the **Agent Registry**. |
| "This agent has no owner." | The register names one; the admin **reassigns** the ownerless agent in the Agent Registry. |
| "The change was authorised and by whom." | The `AGBGOV – Agent Decision Record` plus the Agent Registry CSV export, packaged by `AGBGOV-Export-ApprovalEvidence.ps1`. |

The model also defines the **interface** to your existing Copilot data controls without
re-specifying them:

- **Microsoft Purview (DLP for Copilot, sensitivity labels, audit)** — the intake form's data
  answers determine whether a **data review** is required before approval; the model defines the
  trigger and the accountable reviewer, and relies on the Copilot data-governance solution for the
  actual DLP/label configuration. Agents **honour** existing label-based access — an agent cannot
  surface content its user cannot open.
- **SharePoint / OneDrive oversharing** — an agent's data reach is only ever the *user's* existing
  access. Fixing oversharing is the oversharing-remediation solution's job; this model treats a known
  oversharing posture as a prerequisite and flags agents built over sensitive sites for review.
- **Microsoft Entra / Defender "Agents at risk" signals** — the admin center surfaces shadow agents,
  ownerless agents, excessive-permission agents, and sensitive-data-access risks aggregated from
  Entra, Purview, and Defender. The model defines the **cadence** for reviewing those signals and
  **who acts** on them — it does not reconfigure those platforms.

## The standard deployment model

This solution follows the same shape as every other solution in the category:
**Assess → Configure → Pilot → Validate → Expand.**

- **Assess** — baseline the agents already in the tenant and their sharing posture
  (`AGBGOV-Discovery.ps1`); identify ownerless and broadly-shared agents.
- **Configure** — stand up the roles, groups, register, standards, sharing policy, and forum, and set
  the Copilot Control System controls.
- **Pilot** — run the model over a limited scope (one business unit or one agent family) for two full
  ARB cycles.
- **Validate** — measure against the governance gates in Section 5 (`AGBGOV-Validation.ps1`).
- **Expand** — extend across the tenant and move to steady-state operation with the scorecard.

## Limitations and honest scope boundaries

- **This is an operating model, not a purchase of maturity.** It works only if the organisation
  assigns the named roles and holds the forum. A model nobody attends is a document.
- **It requires an accountable executive sponsor** who will back the ARB when a popular agent is
  rejected or an org-wide share is refused. If you cannot identify that sponsor, secure it before
  Step 1.
- **The admin surfaces are moving fast.** Agent Builder, the Agent Registry, Agent 365, and the
  `copilotPackages` Graph API are new and partly in preview; some are licence-gated (the Graph
  Package Management API requires a **Microsoft Agent 365** licence). Every volatile control in this
  guide is flagged "verify against current Microsoft documentation."
- **It does not fix oversharing or configure Purview for you.** Those are prerequisites delivered by
  sibling solutions; this model defines when they must be invoked, not how to configure them.
- **Metrics require the register to be maintained.** The scripts can measure what the tenant exposes;
  they cannot measure business ownership that was never recorded.

## A note for Government tenants (GCC / GCC High / DoD)

The **operating model itself** — the roles, decision rights, intake gate, sharing policy, lifecycle,
and artefacts — is **identical** for Commercial and US Government tenants. What differs is the
**portal URLs** and the **feature availability**:

| Purpose | Commercial | US Government |
|---|---|---|
| Microsoft 365 admin center | `https://admin.microsoft.com` | `https://admin.microsoft.us` |
| Entra / Azure portal | `https://entra.microsoft.com` / `https://portal.azure.com` | `https://portal.azure.us` |
| Sign-in authority | `https://login.microsoftonline.com` | `https://login.microsoftonline.us` |
| Microsoft Graph endpoint | `https://graph.microsoft.com` | `https://graph.microsoft.us` |

Two Government-specific facts, verified against Microsoft Learn on 2026-07-24 and **flagged as
fast-moving — verify against current Microsoft documentation before you rely on them**:

- **Publishing agents to the organization *is* supported in GCC High (GCCH) and GCC Moderate (GCCM)**
  — so the admin approval / org-catalog gate this model depends on exists in Government tenants.
- **The `copilotPackages` Graph Package Management API is NOT available in US Gov L4 (GCC High) or L5
  (DoD)** — only in the global service. In Government tenants, therefore, seed the register from the
  **Agent Registry CSV export** in the admin center rather than from `AGBGOV-Discovery.ps1`'s Graph
  path; the script degrades to this automatically. Government agent feature availability (declarative
  agents with actions, etc.) is rolling out on its own schedule and is narrower than Commercial —
  **verify current GCC High agent feature availability** before promising a capability.

Because the *governance process* is identical and only the portals/feature-availability differ, this
is a **single deliverable** with the Government path documented inline (there is no separate
Government guide). Every script accepts an `-Environment` switch (`Global` / `USGov` / `USGovDoD`) so
it targets the correct sovereign endpoint.
