# Requirements

Confirm every requirement below **before** you begin Section 3. Each entry follows the same shape:
**Description** (what it is), **Why required** (what breaks without it), **How to verify** (exactly
where to look), and **How to implement if missing**. Category-wide Copilot prerequisites (tenant,
Copilot licensing, Entra identity/MFA, network/client readiness, baseline data governance) live once
in `global-requirements-copilot.md` — confirm those first; the requirements here are specific to
governing **declarative business-process agents**.

> **Roles named below are exact.** Where a Microsoft role or Graph scope is required, it is written
> verbatim so you can search for it. Reserve **Global Administrator** for emergencies; every routine
> task in this model has a least-privilege role.

---

## R1. Accountable executive sponsor

**Description.** A single named senior leader who owns the outcome of the agent governance programme
and will back the Agent Review Board's decisions.

**Why required.** Decision rights are only real if someone senior will support the ARB when a
director's favourite agent is rejected, or when a popular org-wide share is refused. Without a
sponsor, the model becomes advisory and is ignored the first time it says "no".

**How to verify.** A named individual has agreed in writing to sponsor the programme and to receive
the monthly `AGBGOV – Agent Governance Scorecard`.

**How to implement if missing.** Present the Section 1 problem statement and the Step 1 baseline
(ownerless and broadly-shared agent counts) to your IT or data-governance leadership and secure a
named sponsor before Step 1. Do not proceed without one.

---

## R2. Microsoft 365 Copilot licensing (and awareness of the agent billing models)

**Description.** Microsoft 365 Copilot licences for the users who build and use agents, or a
pay-as-you-go Copilot Studio subscription for metered agent consumption.

**Why required.** **Agent Builder** — the tool that creates the declarative agents this model governs
— is available only to users with a Microsoft 365 Copilot licence **or** in tenants with
pay-as-you-go enabled for Copilot Studio. Agents that reach shared tenant data (SharePoint, Graph
connectors) are billed on metered consumption and are **off by default** in Copilot Chat. You must
know which model you are in before you can govern who builds what.

**How to verify.** Microsoft 365 admin center → **Billing → Licenses → Subscriptions**; confirm
Microsoft 365 Copilot seats and/or a Copilot Studio pay-as-you-go / capacity plan.

**How to implement if missing.** Assign Microsoft 365 Copilot licences (via group where possible) to
the pilot cohort, or enable pay-as-you-go for Copilot Studio. Confirm current base-plan prerequisites
in your tenant.

---

## R3. The AI Administrator role (least-privilege agent governance)

**Description.** At least one administrator holding the **AI Administrator** Entra role to configure
agent settings, manage the Agent Registry, and approve/publish/block agents.

**Why required.** Every enforcement action in this model — setting agent access and sharing controls,
approving an org-catalog submission, blocking an unsafe agent, reassigning an ownerless agent, and
calling the `copilotPackages` Graph API — is available to **AI Administrator**. Using it instead of
Global Administrator is the least-privilege posture Microsoft recommends and this model requires.

**How to verify.** Entra admin center → **Roles & admins → Roles & admins** → search **AI
Administrator** → **Assignments**; confirm at least one member. Also confirm in Microsoft 365 admin
center → **Users → Active users →** *your account* → **Roles**.

**How to implement if missing.** Assign the **AI Administrator** role to the person(s) who will hold
the **Agent Admin** accountability. Assign **Global Reader** to auditors who need view-only access.
Do not assign Global Administrator for routine agent work.

---

## R4. Entra group-management rights

**Description.** Rights to create and own Microsoft Entra security groups (Groups Administrator, or a
delegated group owner with creation rights).

**Why required.** The model's accountabilities and its two central controls — *who may build agents*
and *who may share org-wide* — are bound to Entra security groups (`AGBGOV – Agent Builders`,
`AGBGOV – Agent Sharing – Org-Wide Approved`, and the four accountability groups). Without
group-management rights you cannot create the objects the controls point at.

**How to verify.** Entra admin center → **Identity → Groups → All groups → + New group**; if you can
open and complete the form, you have the right.

**How to implement if missing.** Have a Global Administrator assign **Groups Administrator**, or make
your operator an owner of the relevant groups with tenant group-creation enabled.

---

## R5. A system of record for the governance artefacts

**Description.** A place to hold the register, decision records, standards, and logs — typically
SharePoint Online lists, or an ITSM CI class if you have one.

**Why required.** The governance *system of record* is distinct from the technical inventory. The
Agent Registry in the admin center tells you what exists in the tenant; the `AGBGOV – Agent Register`
tells you who is accountable, what was decided, and when it is next reviewed. One cannot substitute
for the other.

**How to verify.** You can create a SharePoint list on your IT team's site (or a CI class in your
ITSM tool) and set item-level permissions and version history.

**How to implement if missing.** Provision a SharePoint Online site for IT governance, or identify
the ITSM class you will use. Step 3 builds the lists.

---

## R6. Known Copilot data-governance and oversharing posture (prerequisite solutions)

**Description.** A known state of (a) SharePoint/OneDrive sharing and oversharing, and (b) Copilot
data governance — sensitivity labels and DLP for Microsoft 365 Copilot.

**Why required.** An agent's data reach is exactly its user's existing access; a Finance agent shared
org-wide over an overshared site is an exposure this model must *flag for review* but cannot *fix* —
fixing it is the oversharing-remediation solution's job, and constraining what Copilot may process is
the Copilot data-governance / DLP solution's job. This model defines *when* a data review is required
and *who* owns it; it depends on those two solutions for the actual controls.

**How to verify.** Confirm whether the oversharing-remediation and Copilot data-governance/DLP
programmes have run, or are in place, for the scope you intend to enable agents in.

**How to implement if missing.** Sequence those solutions ahead of, or alongside, broad agent
enablement. You can still run the governance model in pilot scope, but record the oversharing/DLP
posture as a known risk in each affected agent's register entry.

---

## R7. Change-management interface (CAB), if one exists

**Description.** Knowledge of whether your organisation runs a formal Change Advisory Board (CAB) and,
if so, its cadence and submission deadlines.

**Why required.** Higher-risk agent changes (an agent handling regulated data, or one being shared
tenant-wide) should be represented in enterprise change control without every minor instruction tweak
consuming a CAB slot. The model defines the CAB interface in Step 8; you need to know whether a CAB
exists to complete it.

**How to verify.** Ask your service-management function whether a CAB operates and obtain its cadence.

**How to implement if missing.** If no CAB exists, the ARB holds change authority for all tiers —
record that explicitly so an auditor is not left inferring it.

---

## R8. Nominated role-holders

**Description.** Named individuals (or a documented way to nominate them per agent) for the four
accountabilities: **Agent Owner**, **Business Sponsor**, **Data & Security Reviewer**, **Agent
Admin**.

**Why required.** The RACI in Step 2 is only enforceable if the groups behind it have members. An
empty `AGBGOV – Agent Data-Security Reviewers` group means no agent handling sensitive data can ever
be approved.

**How to verify.** You have at least one nominee for Business Sponsor, Data & Security Reviewer, and
Agent Admin, and a rule for who becomes Agent Owner (default: the maker who built the agent).

**How to implement if missing.** Work with Information Security and the sponsoring business functions
to nominate role-holders before Step 4.

---

## R9. Microsoft Graph PowerShell (for the governance scripts)

**Description.** The **Microsoft Graph PowerShell SDK** installed on the operator workstation, able
to sign in to the correct cloud (`Global` / `USGov` / `USGovDoD`).

**Why required.** The five `AGBGOV-*.ps1` scripts use Microsoft Graph PowerShell (read-only by
default) to baseline agents, validate governance gates, produce the scorecard, package approval
evidence, and flag broadly-shared agents.

**How to verify.** In PowerShell run `Get-Module Microsoft.Graph -ListAvailable`. Confirm the SDK is
present and the account can `Connect-MgGraph`.

**How to implement if missing.** Install with `Install-Module Microsoft.Graph -Scope CurrentUser
-Force`. For the `copilotPackages` discovery path, the signed-in account needs the delegated scope
**`CopilotPackages.Read.All`** and a **Microsoft Agent 365** licence; where that is unavailable
(including all Government tenants), the discovery script degrades to the Agent Registry CSV export —
see Section 3, Step 1. *This API is preview/licence-gated — verify current availability in your
tenant.*

---

## R10. Understanding of the agent build surfaces in scope

**Description.** Clarity on which build surfaces this model governs: **Agent Builder** declarative
agents (primary), **SharePoint** agents, and **Copilot Studio** "Copilot agents" (declarative).
Full custom-engine agents and pro-code agents built with the Microsoft 365 Agents Toolkit are
**out of scope** here (they follow the code app-lifecycle and already require admin publication).

**Why required.** Scoping the model to business-user declarative agents keeps it proportionate. The
gap it closes is specifically the Agent Builder agent that can be shared org-wide with no approval;
custom-engine agents already require admin approval to publish.

**How to verify.** Confirm with your makers which surfaces are in use. `AGBGOV-Discovery.ps1` reports
each agent's **platform** (`Microsoft 365 Copilot Agent Builder` vs `Copilot Studio`) and
**elementType** (`DeclarativeAgent` vs `CustomEngineAgent`) so you can see the mix.

**How to implement if missing.** If custom-engine agents are prevalent, run this model for the
declarative agents and handle custom-engine agents through your existing application-change process;
the RACI and ARB still apply.
