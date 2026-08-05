# Implementation

This section stands up the operating model end to end. Work through the steps **in order** — later
steps depend on objects created by earlier ones. Every object you create is given an **exact name**;
use that name verbatim, because Section 5 (Testing), Section 6 (Troubleshooting), and all five
PowerShell scripts refer to these names directly.

**Naming convention used throughout:** `AGBGOV – <Purpose> – <Scope>`, using an en dash (`–`)
surrounded by single spaces. Keep it consistent; the validation script matches on it.

> **Government tenants (GCC / GCC High / DoD):** substitute `https://admin.microsoft.us` for
> `https://admin.microsoft.com` and `https://portal.azure.us` for `https://entra.microsoft.com` in
> every navigation path below. Blade, tab, and field names are the same. Two behaviours differ and
> are called out in the relevant steps: the `copilotPackages` Graph API is **not** available in
> Government (use the CSV export), and some agent features roll out later — **verify current GCC High
> agent feature availability**.

**Total elapsed time:** expect 3–5 working days of effort for Steps 1–11, then two full board cycles
(typically 4 weeks at a fortnightly cadence) for the pilot in Step 12.

---

## Step 1 — Baseline the current agent estate and its sharing posture

You cannot govern what you have not counted. Produce the "before" picture first; the ownerless and
broadly-shared counts are also what will hold the executive sponsor's attention.

1. On your admin workstation, open **PowerShell** as your normal (non-elevated) user.
2. Install the Graph SDK if it is not present:
   ```
   Install-Module Microsoft.Graph -Scope CurrentUser -Force
   ```
3. Change to the folder containing this package's scripts.
4. Run the discovery script, exporting to CSV:
   ```
   powershell -ExecutionPolicy Bypass -File .\AGBGOV-Discovery.ps1 -CsvPath .\AgentEstate-Baseline.csv
   ```
   For a Government tenant add `-Environment USGov` (or `-Environment USGovDoD`).
5. At the `Connect-MgGraph` prompt, sign in with an account holding **AI Administrator** (R3) and
   **Accept** the consent prompt for the read-only scopes.
6. **If the Graph path is unavailable** (you see *"copilotPackages API not available / not
   licensed"* — this is expected in Government tenants and in tenants without a Microsoft Agent 365
   licence), the script tells you to export the inventory manually instead. Do that now:
   - Navigate to `https://admin.microsoft.com` → **Agents → All agents → Registry**.
   - Click **Export** to download the agent list as CSV (it includes name, status, channel, date
     created, last modified, publisher, publisher type, version, owner, description, platform, and
     instructions — 30+ fields).
   - Re-run the script pointing at that file:
     `powershell -ExecutionPolicy Bypass -File .\AGBGOV-Discovery.ps1 -RegistryCsv .\ExportedAgents.csv -CsvPath .\AgentEstate-Baseline.csv`
7. Open `AgentEstate-Baseline.csv` in Excel. Record these five numbers — they are your baseline
   scorecard, and Step 12 will measure against them:

   | Metric | Where it comes from |
   |---|---|
   | Total declarative agents | Rows where `ElementType` = `DeclarativeAgent` |
   | Agents **shared org-wide** (`AvailableTo` = `all`) | The broad-sharing exposure |
   | Agents with **no owner** recorded | `Owner` is blank |
   | Agents built in **Agent Builder** (the gap surface) | `Platform` = `Microsoft 365 Copilot Agent Builder` |
   | **Unmanaged / shadow** agents | Flagged by the Agent Registry as unmanaged or lacking a registry entry |

8. In the Microsoft 365 admin center, open **Agents → All agents** and note the **Agents without
   owners**, **Unmanaged agents**, and **Agents at risk** tiles. Record those three numbers — they
   are usually the most uncomfortable and most useful figures in the baseline.
9. Save all files to your system of record (R5) in a folder named `AGBGOV – Baseline – <YYYY-MM>`.
   Do not skip this; Step 12 compares against it.

---

## Step 2 — Define the four accountabilities (the RACI)

1. Create a document in your system of record named exactly
   `AGBGOV – Agent Governance RACI – Enterprise – v1.0`.
2. Populate it with the following matrix. This is the model's authority definition; adapt names, not
   structure.

   | Activity | Agent Owner | Business Sponsor | Data & Security Reviewer | Agent Admin | ARB |
   |---|---|---|---|---|---|
   | Raise intake request for a new business agent | **A/R** | C | I | I | I |
   | Provide business justification & value | C | **A/R** | I | I | C |
   | Declare knowledge sources & data reached | **A/R** | I | C | I | C |
   | Perform data-access & sharing review | C | I | **A/R** | I | C |
   | Approve for business use | C | C | C | I | **A/R** |
   | Publish the agent to "Built by your org" | I | I | I | **A/R** | I |
   | Set / restrict org-wide sharing scope | C | I | C | **A/R** | I |
   | Classify a change's risk tier | **A/R** | I | C | I | C |
   | Block an unsafe / non-compliant agent | I | I | C | **A/R** | I |
   | Own the agent runbook & keep it correct | **A/R** | I | I | I | I |
   | Reassign an ownerless agent | I | C | I | **A/R** | I |
   | Approve retirement / decommission | C | **A/R** | C | I | **A** |
   | Sign off the periodic review | **A/R** | C | **C** | I | **A** |

   *A = Accountable (one only), R = Responsible, C = Consulted, I = Informed.*

3. Immediately below the matrix, record **the four escalation rules** verbatim:
   - An agent used in a business process with no named **Agent Owner** is blocked, not tolerated.
   - An agent handling `Confidential` or `Restricted` data with no completed **Data & Security
     Reviewer** sign-off cannot reach `Approved – business use`.
   - Sharing an agent with **"Anyone in your organization"** requires an ARB approval *and* a
     completed data-access review; an unreviewed org-wide share is a finding.
   - **Blocking an agent never requires a meeting.** Any **Agent Admin** may block any agent
     immediately on a credible safety or compliance concern; it is always a safe, reversible action.
4. Have the executive sponsor from R1 approve the document, and record the approval date in it.

---

## Step 3 — Create the Agent Register, Decision Record, and Retirement Log

The register is the governance system of record. The Agent Registry in the admin center is the
*technical* record of what exists; the `AGBGOV – Agent Register` is the *governance* record of who is
accountable, what was decided, and when it is next reviewed.

1. Open your system of record from R5. These instructions use SharePoint Online; adapt the field
   types if you are using an ITSM CI class.
2. Navigate to your IT team's SharePoint site → **New → List → Blank list**.
3. In **Name**, enter exactly `AGBGOV – Agent Register`. In **Description**, enter
   `Authoritative record of every business-process agent, its accountabilities, approval status, sharing scope, and lifecycle state.`
   Leave **Show in site navigation** ticked. Click **Create**.
4. Add the following columns. For each, click **+ Add column**, choose the type shown, enter the name
   exactly as written, then click **Save**.

   | Column name | Type | Notes |
   |---|---|---|
   | `Agent Name` | Single line of text | Rename the default `Title` column to this. Match the Agent Registry display name. |
   | `Agent Id` | Single line of text | The package/agent id from the Agent Registry; the join key to the scripts. |
   | `Build Surface` | Choice | `Agent Builder`, `SharePoint`, `Copilot Studio`. |
   | `Agent Owner` | Person | The maker accountable for the agent. Required. |
   | `Business Sponsor` | Person | Business accountability for the need. Required. |
   | `Data & Security Reviewer` | Person | Who signed the data/sharing review. |
   | `Agent Admin` | Person | Who enforces in the admin center. |
   | `Knowledge Sources` | Multiple lines of text | The SharePoint sites / sources the agent reads. |
   | `Data Classification` | Choice | `Public`, `Internal`, `Confidential`, `Restricted`. |
   | `Sharing Scope` | Choice | `Only owner`, `Specific users/groups`, `Anyone in org`. |
   | `Business Justification` | Multiple lines of text | Copied from the intake request. |
   | `Lifecycle State` | Choice | `Requested`, `In review`, `Approved – pilot`, `Approved – business use`, `Deprecated`, `Retired`. |
   | `ARB Decision Reference` | Single line of text | Format `AGBARB-<YYYY>-<NNN>`. |
   | `Approval Date` | Date and time | Date only. |
   | `Next Review Date` | Date and time | Approval date + review interval (Step 6). |
   | `Risk Tier` | Choice | `Tier 1 – Low`, `Tier 2 – Moderate`, `Tier 3 – High`, `Tier 4 – Critical`. |
   | `Runbook Link` | Hyperlink | Points at the agent runbook. |
   | `Published To Store` | Choice | `Not published`, `Built by your org`. |

5. Enable version history: **gear icon → List settings → Versioning settings** → set **Create a
   version each time you edit an item in this list** to **Yes** → **OK**.
6. Set permissions: **gear icon → List settings → Permissions for this list → Stop Inheriting
   Permissions → OK**. Grant the register custodian **Edit**; grant all Agent Owners **Read**.
   Approval fields must not be editable by requesters.
7. Seed the register from your Step 1 baseline. For each declarative agent create a register item
   populating `Agent Name`, `Agent Id`, `Build Surface`, and `Sharing Scope`. Leave the
   accountability and approval fields blank — the gaps are the point, and Step 11 fills them.
8. Create a second list named exactly `AGBGOV – Agent Decision Record` with columns: `Decision
   Reference` (single line of text, format `AGBARB-<YYYY>-<NNN>`), `Agent Name` (single line of
   text), `Decision Date` (date), `Decision` (choice: `Approved`, `Approved with conditions`,
   `Deferred – evidence required`, `Rejected`), `Conditions` (multiple lines of text), `Members
   Present` (multiple lines of text), `Data Review Outcome` (multiple lines of text), `Evidence Pack
   Link` (hyperlink), `Decision Rationale` (multiple lines of text). Enable version history as in
   step 5.
9. Create a third list named exactly `AGBGOV – Agent Retirement Log` with columns: `Agent Name`
   (single line of text), `Agent Id` (single line of text), `Retirement Reason` (choice: `Owner
   left / ownerless`, `Superseded`, `No longer used`, `Failed review`, `Security/compliance`),
   `Decision Reference` (single line of text), `Blocked Date` (date), `Deleted Date` (date),
   `Retired By` (person), `Evidence Link` (hyperlink). Enable version history.

---

## Step 4 — Create the governance security groups in Entra ID

These groups make the RACI enforceable, and they are what the two Copilot Control System controls in
Step 5 are bound to.

1. Navigate to `https://entra.microsoft.com` and sign in with an account holding the rights from R4.
2. In the left navigation, expand **Identity**, then click **Groups → All groups**.
3. Click **+ New group**.
4. Complete the **New Group** form for the first group:
   - **Group type:** `Security`
   - **Group name:** `AGBGOV – Agent Builders`
   - **Group description:** `Users sanctioned to build declarative agents (Agent Builder / Copilot Studio). Bound to the Copilot agent access control.`
   - **Microsoft Entra roles can be assigned to the group:** `No`
   - **Membership type:** `Assigned`
   - **Owners:** add the register custodian.
   - **Members:** add the sanctioned makers nominated in R8.
5. Click **Create**.
6. Repeat steps 3–5 exactly to create each of the following. **Use `Assigned` for all** — these are
   deliberate governance decisions, and a dynamic rule would let an HR attribute change silently
   grant or remove build/share rights.

   | Group name | Description |
   |---|---|
   | `AGBGOV – Agent Sharing – Org-Wide Approved` | `Users permitted to create org-wide ("Anyone in your organization") agent sharing links. Bound to the Copilot agent sharing control.` |
   | `AGBGOV – Agent Owners` | `Makers accountable for individual agents, their instructions, knowledge sources, and runbooks.` |
   | `AGBGOV – Agent Business Sponsors` | `Business leads accountable for the need and value of agents.` |
   | `AGBGOV – Agent Data-Security Reviewers` | `Information Security / data governance staff who review agent data access and sharing.` |
   | `AGBGOV – Agent Admins` | `Administrators (AI Administrator role) who approve, publish, block, reassign, and retire agents.` |

7. Verify: still in **Identity → Groups → All groups**, type `AGBGOV` in the search box. Exactly six
   groups must be listed. Record each group's **Object Id** (open the group → **Overview** → copy
   **Object Id**) into the RACI document from Step 2.

---

## Step 5 — Set the enforcement controls in the Copilot Control System

This is the step that converts "only sanctioned people may build, and only approved people may share
org-wide" from a sentence into an enforced control. *Agent admin surfaces evolve quickly — the exact
blade labels below were verified against Microsoft Learn on 2026-07-24; if a toggle has moved, find
its current location and apply the same intent. Verify against current Microsoft documentation.*

### 5a — Restrict who can build / access agents

1. Sign in to the **Microsoft 365 admin center** (`https://admin.microsoft.com`) with **AI
   Administrator** (R3).
2. Open the **Copilot Control System**, then navigate to **Copilot → Settings → Data access →
   Agents**.
3. Under who can access agents, select **Specific users/groups** and choose
   `AGBGOV – Agent Builders`. (Choose **All users** only if your policy is open build with post-hoc
   governance; choose **No users** to pause agent access entirely.)
4. Under which types of apps and agents are available, choose the publishers your policy allows —
   agents created by **Microsoft**, **external publishers**, and **your organization** — and
   **uncheck** any you do not sanction. Review the third-party data-handling warning before allowing
   external publishers.
5. Click **Save**.

### 5b — Restrict who can share agents org-wide

1. Still in the Microsoft 365 admin center, open the **agent sharing** control (in the Copilot
   Control System agent settings; *verify the current blade path*).
2. Set org-wide sharing to **Specific users or groups** and choose
   `AGBGOV – Agent Sharing – Org-Wide Approved`. This is the control that closes the core gap: an
   Agent Builder agent can no longer be shared with **"Anyone in your organization"** by an
   unapproved user.
   - Choose **No users** if your policy is that *no* agent may be shared org-wide without going
     through the org-catalog publish flow (the strictest posture).
   - **All users** is the default and the posture this model exists to replace.
3. Click **Save**. Note the documented behaviour: **the change applies only to new sharing actions**
   — agents already shared org-wide keep that access until their owner updates them. Step 9 handles
   the existing broadly-shared agents.

### 5c — Confirm the org-catalog approval path is on

1. Confirm that submissions to the org catalog route to admin review: Microsoft 365 admin center →
   **Agents → All agents → Registry**, and confirm you (as Agent Admin) receive and can act on
   **agent requests** (review → **publish** to *Built by your org*, or **reject**). This is the gate
   every business agent passes in Step 8.
2. *Government note:* publishing agents to the organization **is** supported in GCC High and GCC
   Moderate — confirm the request queue is visible in your Government admin center.

---

## Step 6 — Publish the Agent Standards document

This is the document that makes "approved for business use" a test rather than an opinion.

1. Create a document in your system of record named exactly `AGBGOV – Agent Standards – Enterprise –
   v1.0`.
2. Include the following six sections. Each must be written so a reviewer can answer *yes* or *no* —
   avoid "should be considered".

   **Section 1 — Definition of approved for business use.** An agent is `Approved – business use`
   only when all of the following are true: a named Agent Owner and Business Sponsor exist in the
   register; the data-access & sharing review is complete and signed; the sharing scope is set no
   broader than the review permits; a runbook exists and is linked; the agent's name conforms to the
   naming standard; and an `AGBGOV – Agent Decision Record` exists with a decision of `Approved` or
   `Approved with conditions` (all conditions met).

   **Section 2 — Data-access & sharing review criteria.** The Data & Security Reviewer must record a
   determination against each of: the data classification the agent handles; the specific knowledge
   sources (SharePoint sites/files, connectors, websites) it reads; whether any source is known to be
   overshared (cross-reference the oversharing-remediation posture, R6); whether a **DLP for
   Microsoft 365 Copilot** policy or sensitivity-label boundary applies (cross-reference the Copilot
   data-governance solution — do not re-specify it here); the requested sharing scope and whether it
   is justified; and whether the agent should be published to the org catalog or kept to specific
   users.

   **Section 3 — Sharing standard.** Default sharing is **Only owner** during build and **Specific
   users/groups** for team use. **"Anyone in your organization"** is permitted only with ARB approval
   and a completed data review, and only for agents whose knowledge sources are all `Public` or
   `Internal`. Publishing to **Built by your org** is the sanctioned route for broad availability
   because it passes admin review.

   **Section 4 — Naming standard.** Every business-process agent must be named:
   ```
   AGBGOV – <Function> – <Purpose> – <Audience>
   ```
   For example: `AGBGOV – Finance – Expense Policy Q&A – Finance Team`,
   `AGBGOV – HR – Benefits Assistant – All Staff`, `AGBGOV – Sales – Proposal Helper – Sales EMEA`.
   Use the en dash with single spaces. `AGBGOV-Validation.ps1` tests conformance to exactly this
   pattern for agents in scope.

   **Section 5 — Supportability bar.** Before business-use approval an agent must have: a documented
   purpose and the instructions it runs on; a named Agent Owner who will keep it correct; a runbook
   covering how to update it, how to reassign it if the owner leaves, and how to retire it; and a
   statement of the data it reaches.

   **Section 6 — Review interval.** Set `Next Review Date` by risk tier: `Tier 4 – Critical` every 6
   months; `Tier 3 – High` every 12 months; `Tier 1 – Low` and `Tier 2 – Moderate` every 12 months
   (agents drift faster than packaged apps — do not exceed 12 months for any tier). A review that
   lapses moves the agent to `Deprecated` until it is re-reviewed.

3. Have the executive sponsor and the Head of Information Security approve the document. Record both
   approval dates.
4. Publish it where every maker can read it **before** they build. A standards document nobody can
   find generates the same rework as no standards document.

---

## Step 7 — Stand up the intake workflow

1. Create the intake form. Using Microsoft Forms: navigate to `https://forms.office.com` → **New
   Form** → name it exactly `AGBGOV – Agent Intake Request Form`. Add these questions, all
   **Required** unless stated:

   | # | Question | Type |
   |---|---|---|
   | 1 | Proposed agent name (per the naming standard) | Text |
   | 2 | Named Agent Owner (the maker) and Business Sponsor | Text |
   | 3 | What business process will this agent support, and what happens if we do not build it? | Long text |
   | 4 | Which knowledge sources will it read? (SharePoint sites/files, Teams, connectors, websites) | Long text |
   | 5 | Highest data classification among those sources | Choice: Public / Internal / Confidential / Restricted |
   | 6 | Who needs to use it? | Choice: Only me / Specific team or group / Anyone in the organisation |
   | 7 | Build surface | Choice: Agent Builder / SharePoint / Copilot Studio |
   | 8 | Does any knowledge source contain personal, financial, health, or regulated data? | Choice: Yes / No / Unknown |
   | 9 | Required-by date and the driver for it | Text |
   | 10 | Has an existing approved agent been evaluated for this need? Which, and why insufficient? | Long text |

2. Route the responses into a SharePoint list named `AGBGOV – Agent Intake Queue` (via the form's
   **Responses → ⋯ → Create a Flow**), or export responses to Excel weekly if you have no Power
   Automate licence. The discipline matters more than the mechanism.
3. Publish the **intake SLA**: the register custodian triages every request within **3 business
   days** and returns it, tables it for the next ARB, or fast-tracks it under the Tier 1 pre-approval
   rule (Step 8).
4. Publish the **return criteria** explicitly. A request is returned to the requester — not queued —
   when it lacks a named Agent Owner and Business Sponsor, a description of knowledge sources, or a
   data classification. Publish these so returns are not perceived as arbitrary.

---

## Step 8 — Stand up the Agent Review Board and change classification

1. Create a recurring Outlook meeting named exactly
   `AGBGOV – Agent Review Board – Enterprise – Fortnightly`.
2. Set the cadence and duration:
   - **Cadence:** every two weeks. Weekly is unsustainable; monthly makes IT the bottleneck and
     drives users to share agents around the gate.
   - **Duration:** 45 minutes. If you consistently overrun, the intake gate in Step 7 is too loose.
3. Define **membership**. Invite as **required**: the register custodian (chair), one member of
   `AGBGOV – Agent Data-Security Reviewers`, and one `AGBGOV – Agent Admins` member. Invite as
   **optional**: the requesting Agent Owner and Business Sponsor for their item only.
4. Define **quorum** and record it in the standards document: the chair plus one Data & Security
   Reviewer. **Without a Data & Security Reviewer present, no agent handling `Confidential` or
   `Restricted` data and no request to share org-wide may be approved** — such items are deferred, not
   waved through.
5. Define the four permitted **decisions**. The board selects exactly one per item:
   - `Approved` — proceeds to `Approved – pilot`, then business use.
   - `Approved with conditions` — proceeds, with each condition recorded with a named owner and due
     date (e.g. "narrow sharing to the Finance group", "remove the HR site as a knowledge source").
   - `Deferred – evidence required` — the specific missing evidence is named, with who supplies it
     and by when (commonly a completed data-access review).
   - `Rejected` — with a written rationale that states what would change the answer.
6. Define the **evidence pack** required before an item may be tabled. The chair refuses to table
   items lacking any of: the completed intake request; the data-access & sharing review determination
   against all criteria in Standards Section 2; the proposed sharing scope; a proposed risk tier; and
   a named Agent Owner who has confirmed they will keep the runbook.
7. Define the **Tier 1 pre-approval (standard change) rule** so the board is not consumed by routine
   work: a minor instruction or wording change to an already-approved agent, with **no** change to
   knowledge sources, data classification, or sharing scope, is **pre-approved** and does not require
   an ARB slot. It is recorded retrospectively in the `AGBGOV – Agent Decision Record` with the
   reference `AGBARB-<YYYY>-STD-<NNN>`.
8. Create the change classification document named exactly `AGBGOV – Agent Change Classification –
   Enterprise – v1.0`, with the four risk tiers:

   | Risk tier | Definition | Approval required | Sharing/publish policy | Rollback |
   |---|---|---|---|---|
   | `Tier 1 – Low` | Wording/instruction tweak; no change to sources, data, or sharing. | Pre-approved (standard). Owner confirms classification. | No change to sharing. | Owner reverts instructions. |
   | `Tier 2 – Moderate` | New agent over `Public`/`Internal` sources; or a new knowledge source at the same classification. | ARB approval. | Specific users/groups; org-wide only with review. | Owner unshares / reverts. |
   | `Tier 3 – High` | Agent over `Confidential` data; or any request to share **Anyone in your organization**; or publish to **Built by your org**. | ARB approval **and** Data & Security Reviewer sign-off. | Org-wide/publish only after review; CAB notified. | Agent Admin **blocks** in the Agent Registry. |
   | `Tier 4 – Critical` | Agent over `Restricted`/regulated data; or a business-critical or clinical/regulated process. | ARB approval, Data & Security sign-off, **and** CAB approval. | Publish only via org catalog with a written go/no-go. | Agent Admin **blocks** immediately; Sponsor + CAB notified. |

9. Define the **CAB interface** (R7): if a CAB exists, Tier 1–2 are standard/pre-approved and consume
   no CAB time, Tier 3 is **notified** to CAB, and Tier 4 is **submitted** to CAB with the ARB
   Decision Reference as the technical approval evidence. If no CAB exists, the ARB holds change
   authority for all tiers — record that explicitly.
10. State the **blocking principle** prominently: *blocking an agent never requires approval.* Any
    Agent Admin may block any agent at any time on a credible safety or compliance concern; blocking
    is reversible (unblock) and is the cheapest possible containment. Requiring approval to block
    converts a two-minute containment into a data-exposure window.
11. Record every decision in the `AGBGOV – Agent Decision Record` within **1 business day** of the
    meeting. Decisions not recorded within that window are treated as not made.

---

## Step 9 — Set the sharing policy and stand up the shared-agent access review

This is the component that turns broad sharing from an unreviewed default into a governed, reviewed
decision — and cleans up the existing broadly-shared agents that Step 5b's control did not
retroactively change.

1. Publish the sharing-scope rules from Standards Section 3 to all makers.
2. Run the shared-agent review to find every agent currently shared broadly:
   ```
   powershell -ExecutionPolicy Bypass -File .\AGBGOV-Review-SharedAgents.ps1 -CsvPath .\SharedAgents-Review.csv
   ```
   For a Government tenant add `-Environment USGov` and, if the Graph path is unavailable, pass the
   Agent Registry CSV export with `-RegistryCsv .\ExportedAgents.csv`. The script flags agents whose
   `AvailableTo` = `all` (shared org-wide), agents shared to large groups, and agents lacking an
   owner.
3. For each flagged agent, the register custodian opens a review item and routes it to the Data &
   Security Reviewer. The outcome is one of: **keep** (owner + sponsor named, sharing justified,
   recorded in the register); **narrow** (owner reduces the sharing scope to the reviewed set); or
   **retire** (no owner or no justification — go to Step 10).
4. Record every outcome in a list named exactly `AGBGOV – Shared-Agent Access Review` with columns:
   `Agent Name`, `Agent Id`, `Current Sharing Scope`, `Reviewer`, `Review Date`, `Outcome`
   (`Keep` / `Narrow` / `Retire`), `Action Taken`, `Decision Reference`.
5. Set the **review cadence**: broadly-shared and org-published agents are re-reviewed **every 6
   months**; the sweep in step 2 runs **monthly** so newly broad-shared agents surface quickly.

---

## Step 10 — Define the lifecycle and retirement process

Agents outlive their makers. Retirement is the step that actually shrinks risk, and it must be
explicit and evidenced.

1. Adopt the lifecycle states already in the register: `Requested → In review → Approved – pilot →
   Approved – business use → Deprecated → Retired`.
2. Define the **retirement triggers**: the Agent Owner has left and the agent is ownerless; the agent
   is superseded by another; the agent is no longer used; a review lapsed and was not renewed; or a
   security/compliance concern requires it.
3. Define the **retirement procedure**, and follow it for every retirement:
   - The Business Sponsor (or, for ownerless agents, the register custodian) confirms retirement and
     records an `AGBGOV – Agent Decision Record` entry.
   - The Agent Admin **blocks** the agent first (Microsoft 365 admin center → **Agents → All agents →
     Registry** → open the agent → flyout → **Block**). Blocking is reversible and is the safe pause.
   - Communicate a **notice period** to known users where the agent is in active use (default 30
     days); ownerless or unused agents may be blocked immediately.
   - After the notice period with no valid objection, **delete** the agent. For an agent the maker
     built, only the maker can delete it in Agent Builder; for ownerless agents the Agent Admin
     deletes it from the Agent Registry. *Deletion is permanent and irreversible* — the block-then-
     wait sequence exists precisely so deletion is never the first action.
   - Record the block date, delete date, and evidence link in the `AGBGOV – Agent Retirement Log`.
4. For **ownerless agents specifically**, use the admin center's built-in handling: the **Agents
   without owners** card filters the Agent Registry to ownerless agents in one click; from there the
   Agent Admin either **reassigns** a new owner (if the agent should live on) or blocks/deletes it (if
   not). Reassign rather than orphan whenever a business use still exists.

---

## Step 11 — Stamp governance onto the existing estate

Now bring the agents that already exist under the model.

1. Open `AgentEstate-Baseline.csv` from Step 1. For every declarative agent, decide its disposition:
   **ratify** (a real business use with an owner you can name), **narrow/keep** (per the Step 9
   review), or **retire** (Step 10).
2. For each agent to ratify, create or complete its `AGBGOV – Agent Register` item: name the Agent
   Owner, Business Sponsor, and (if sensitive) Data & Security Reviewer; set `Lifecycle State` to
   `Approved – business use`; and record a bulk-ratification reference `AGBARB-<YYYY>-LEGACY-<NNN>`
   in the `AGBGOV – Agent Decision Record`.
3. Rename any agent that does not conform to the Step 6 naming standard. The Agent Owner edits the
   name in Agent Builder (**All agents → …** → **Edit** → update name → **Update**), or the admin
   updates it via the Agent Registry. Renaming does not change who the agent is shared with.
4. For each agent to retire, run the Step 10 procedure.
5. Re-run the validation script to confirm the estate now largely conforms:
   ```
   powershell -ExecutionPolicy Bypass -File .\AGBGOV-Validation.ps1 -RegisterCsv .\AGBGOV-Register-Export.csv -CsvPath .\Validation-Baseline.csv
   ```
   (Export the `AGBGOV – Agent Register` list to CSV first, or point the script at the Agent Registry
   export — it accepts either.)

---

## Step 12 — Pilot the model for two full board cycles

Do not roll the model across the whole tenant immediately. Run it narrow and prove it.

1. Choose the pilot scope: **one business function** (for example, Finance) **or one agent family**
   (for example, all HR-facing agents). Record the choice.
2. Run the model exactly as documented for **two complete ARB cycles** — at a fortnightly cadence,
   four weeks.
3. During the pilot, route **every** new or changed agent in scope through the intake form. No
   exceptions, including urgent ones — an urgent request is a Tier 3/Tier 4 change, not a bypass.
4. At the end of each cycle, run the validation and reporting scripts:
   ```
   powershell -ExecutionPolicy Bypass -File .\AGBGOV-Validation.ps1 -RegisterCsv .\AGBGOV-Register-Export.csv -CsvPath .\Validation-Cycle1.csv
   powershell -ExecutionPolicy Bypass -File .\AGBGOV-Report.ps1 -RegisterCsv .\AGBGOV-Register-Export.csv -CsvPath .\Scorecard-Cycle1.csv
   ```
5. Hold a 30-minute retrospective after cycle 2 with the board. Ask: which gate produced the most
   rework, which evidence requirement was hardest to supply, and where did someone attempt to share
   an agent around the gate? Amend the standards document and increment its version.
6. Only when Section 5's gates pass, proceed to Step 13.

---

## Step 13 — Expand to the whole tenant and enter steady state

1. Make the intake form the **only** sanctioned route for a new business agent tenant-wide. Announce
   the date, and have the executive sponsor from R1 send the announcement — not IT.
2. Tighten the Step 5b sharing control from `AGBGOV – Agent Sharing – Org-Wide Approved` to the final
   posture your pilot proved sustainable (specific approved group, or no org-wide sharing at all).
3. Bulk-ratify or retire the remaining legacy agents: ratify those with a nameable owner and business
   use; move the rest to `Deprecated`, give the 30-day notice, and retire. This is the step that
   shrinks the estate.
4. Establish the steady-state cadence:

   | Activity | Frequency | Owner |
   |---|---|---|
   | Agent Review Board | Fortnightly | Register custodian (chair) |
   | Governance scorecard published (`AGBGOV-Report.ps1`) | Monthly | Register custodian |
   | Conformance validation (`AGBGOV-Validation.ps1`) | Monthly | Agent Admin |
   | Shared-agent sweep (`AGBGOV-Review-SharedAgents.ps1`) | Monthly | Data & Security Reviewer |
   | "Agents at risk" / ownerless review in the admin center | Monthly | Agent Admin |
   | Broadly-shared / published-agent access review | Every 6 months | Data & Security Reviewer |
   | Standards & change-classification review | Annually | Executive sponsor + Security |

5. Add the scorecard to an existing governance forum's standing agenda (an IT operations review, a
   data-governance board, or an AI council). Metrics reported nowhere change nothing.
6. Archive the Step 1 baseline alongside the first steady-state scorecard. The delta — fewer
   ownerless agents, fewer unreviewed org-wide shares, more agents with named owners — is the
   business case for having done this, and it is what you present at the annual review.
