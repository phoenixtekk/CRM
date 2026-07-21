# 3. Implementation Guide — Remote Help Operations & Adoption

Follow these steps **in order**. Most steps are in the **Microsoft Intune admin center**
(`https://intune.microsoft.com`) and **Microsoft Entra admin center** (`https://entra.microsoft.com`).

> **This guide does NOT install or enable Remote Help.** That is the base **Remote Help** solution
> (slug `remote-help`) and is a **prerequisite** (Requirement 2.1). Everything below assumes Remote
> Help is already enabled and its app already deployed. Start here only once that is true.

> **Model:** Design tiers & role/scope → configure roles, scope & unattended governance → pilot one
> tier + small scope → validate → expand across tiers + adoption campaign.

> **Naming convention (used verbatim throughout, and in Testing, Troubleshooting, and the scripts):**
> `<Purpose> – <Scope/Tier> – <Stage>`. Every object below is named; reuse each name exactly.

> **Verify-with-Microsoft note:** the exact Intune blade labels, the built-in Remote Help role
> names, the permission names for view vs full control vs elevation, and whether unattended access
> is offered/how it behaves all change over time. Where this guide names a portal path or a
> capability, **confirm the current label and availability in your tenant against current Microsoft
> documentation** before relying on it. The object names *you* create (groups, roles, assignments)
> are yours and are used verbatim.

## Step 1 — Create the help-desk tier agent groups (Entra)
Create one **Assigned** security group per tier, holding the agents in that tier.

1. Entra → **Groups → New group**.
2. **Group type:** Security. **Membership type:** **Assigned**. **Name:** `RHELP-T1-Agents`.
   **Description:** *Tier 1 – Service Desk agents (Remote Help view-only)*. Add the Tier 1 agents as
   members. **Create**.
3. Repeat to create `RHELP-T2-Agents` — *Tier 2 – Desktop Support agents (full control)* — add Tier 2
   agents. **Create**.
4. Repeat to create `RHELP-T3-Agents` — *Tier 3 – Escalation Engineering agents (full control +
   elevation + governed unattended)* — add Tier 3 agents. **Create**.

## Step 2 — Create the scope groups (the users each tier may help) (Entra)
These groups define **who** each tier is allowed to help. Create them as **Assigned** security
groups containing the target **users** (or their devices, per your model).

1. Entra → **Groups → New group** → Security → **Assigned** → **Name:** `RHELP-Scope-Standard-Users`.
   **Description:** *Standard corporate users eligible for Tier 1/Tier 2 assistance*. Add the standard
   user population. **Create**.
2. Create `RHELP-Scope-VIP-Users` — *VIP/executive users; Tier 3 handling* — add the VIP/executive
   users. **Create**.
3. *(Optional, for unattended scope — see Step 4)* Create `RHELP-Scope-Unattended-Devices` —
   *Devices approved for unattended assistance (kiosks/shared/no-consent-user)* — add only the
   approved devices. **Create**.

> **Assigned, not Dynamic:** keep these **Assigned** so membership is deliberate and auditable — an
> agent's reach should never widen automatically. If you later choose dynamic membership, review the
> rule as a security control.

## Step 3 — Create the per-tier Remote Help RBAC roles (Intune)
Create one custom RBAC role per tier expressing that tier's **capability**. *(If your tenant's
built-in Remote Help roles already match a tier's capability exactly, you may assign the built-in
role instead in Step 4 — **verify the built-in role names and their permissions against current
Microsoft documentation**.)*

1. Intune → **Tenant administration → Roles → Create** (create a custom role).
2. **Name:** `RHELP Role – Tier 1 View`. **Description:** *Remote Help view-only for Tier 1*.
   Under permissions, enable the **Remote Help** permission(s) that grant **view/observe only** (no
   control). *(Exact permission names — **verify against current Microsoft documentation**.)* **Next
   → Create**.
3. Create `RHELP Role – Tier 2 Control` — *Remote Help full control for Tier 2* — enable the Remote
   Help permission(s) for **full control** (view + take control). **Create**.
4. Create `RHELP Role – Tier 3 Elevation` — *Remote Help full control + elevation (+ governed
   unattended) for Tier 3* — enable full control **and** the permission(s) that allow **elevation**
   (and unattended, if it is expressed as a permission). *(Whether elevation and unattended are
   separate permissions — **verify against current Microsoft documentation**.)* **Create**.

## Step 4 — Configure and govern unattended access
Decide and document unattended access **before** assigning it. *(Whether Remote Help offers
unattended assistance, on which platforms, and its exact enablement/consent behavior — **verify
against current Microsoft documentation**; do not enable a capability this guide asserts.)*

1. **Decide scope.** Unattended assistance is appropriate only where **no user is present to
   consent** and the business need is clear — for example approved kiosks, shared devices, or
   unattended endpoints. Put **only** those devices in `RHELP-Scope-Unattended-Devices` (Step 2.3).
2. **Assign one owning tier.** Grant unattended handling to **Tier 3 only** (`RHELP-T3-Agents` via
   `RHELP Role – Tier 3 Elevation`). No other tier gets unattended.
3. **Set guardrails (documented policy):**
   - Every unattended session **requires an approved change/ticket** referencing the device.
   - Unattended sessions are **logged to the ticket** (Step 5) and **flagged as unattended** in
     reporting (Step 6).
   - Unattended scope membership is **reviewed** on a fixed cadence (for example monthly).
4. **Enable the capability** (if and where Microsoft offers it) for the unattended scope only, per
   current Microsoft documentation. **Do not** enable it tenant-wide or for attended scopes.

> If Microsoft does **not** offer unattended assistance for your platform/scenario, record that in
> the policy and route those cases to an alternative governed path — do not work around it.

## Step 5 — Assign the roles with scope, and wire the session-to-ticket workflow
### 5a — Assign each role to its tier group with its scope (Intune)
1. Intune → **Tenant administration → Roles →** open **`RHELP Role – Tier 1 View`** → **Assignments →
   Assign**. **Assignment name:** `RHELP Assignment – Tier 1`. **Members (groups):** `RHELP-T1-Agents`.
   **Scope (Groups):** `RHELP-Scope-Standard-Users`. **Save**.
2. Open **`RHELP Role – Tier 2 Control`** → **Assignments → Assign**. **Assignment name:**
   `RHELP Assignment – Tier 2`. **Members:** `RHELP-T2-Agents`. **Scope (Groups):**
   `RHELP-Scope-Standard-Users`. **Save**.
3. Open **`RHELP Role – Tier 3 Elevation`** → **Assignments → Assign**. **Assignment name:**
   `RHELP Assignment – Tier 3`. **Members:** `RHELP-T3-Agents`. **Scope (Groups):**
   `RHELP-Scope-Standard-Users`, `RHELP-Scope-VIP-Users`, and (for unattended)
   `RHELP-Scope-Unattended-Devices`. **Save**.

> **How scope limits "who can help whom":** the role **scope** is what restricts an agent tier to
> its intended user population. *(Exactly how Remote Help evaluates scope groups vs. scope tags to
> gate a session — **verify against current Microsoft documentation**; this guide assigns scope by
> group as the intended control.)* Validate it in Testing (Section 5) before you trust it.

### 5b — Define the session-to-ticket workflow (process)
Document this as the standard agent procedure (no portal change — this is the operating process):

1. **Intake.** A ticket is created in your ITSM system. The agent works from the ticket, never
   ad-hoc.
2. **Verify the caller.** The agent confirms the user's identity per your verification policy
   before starting any session.
3. **Right tier / right scope.** Tier 1 handles standard requests within `RHELP-Scope-Standard-Users`;
   Tier 2 takes control cases; Tier 3 takes VIP (`RHELP-Scope-VIP-Users`) and unattended cases.
4. **Start the session** from the ticket context (attended: user consents in Remote Help;
   unattended: only per Step 4 governance).
5. **Escalate when needed.** If out of tier capability or scope, the agent escalates the **ticket**
   to the next tier — they do **not** exceed their role. Escalation moves the ticket, which moves the
   authorized tier.
6. **Log & hand off.** On completion the agent records on the ticket: session start/end time,
   attended vs unattended, actions taken, and outcome (resolved / escalated). Unattended sessions
   additionally reference the approving change/ticket.

## Step 6 — Stand up usage & outcome reporting
1. Define the KPIs you will report (see Section 7 for the recommended set): session volume per tier,
   average handle time, first-contact resolution, escalation rate, consent/decline rate, unattended
   session count, and adoption rate.
2. Run **`RHELPOPS-Report.ps1`** to export usage/outcome/adoption KPIs to CSV on your cadence
   (for example weekly). *(The exact Remote Help usage data available via the portal vs. Graph —
   **verify against current Microsoft documentation**; the script exports what is available and
   marks gaps.)*
3. Cross-reference the export with your ITSM ticket data (from Step 5b logging) to complete outcome
   and adoption KPIs the platform alone cannot show.

## Step 7 — Pilot, then run the adoption campaign
### 7a — Pilot (one tier, small scope)
1. Start with **Tier 1** (`RHELP-T1-Agents`) and a small subset of `RHELP-Scope-Standard-Users`.
2. Run **`RHELPOPS-Validate.ps1`** → confirms the role/scope model is in place and reporting is
   available.
3. Run **`RHELPOPS-Test-Scope.ps1`** → proves a Tier 1 agent is scoped to the intended users **and
   no more**.
4. Complete the **Testing Guide** (Section 5) for the pilot before expanding.

### 7b — Adoption campaign
1. **End-user comms.** Publish a short "How to get remote help" note: how to request help (raise a
   ticket), what to expect (an Entra-authenticated agent, a **consent prompt**, and that sessions are
   **audited**), and — where applicable — that some approved devices may receive **governed unattended
   assistance**. Set trust/consent expectations plainly.
2. **Self-service entry point.** Point users to the single request path (the ticket queue) so demand
   is captured and measurable.
3. **Agent enablement.** Train each tier on its capability, its scope, the escalation rule, and the
   session-to-ticket logging. Make clear an agent never exceeds their tier — they escalate the
   ticket.
4. **Measure adoption.** Track the adoption rate KPI (share of eligible tickets using Remote Help)
   from Step 6 and iterate the comms where uptake is low.

## Step 8 — Expand across tiers
1. Add **Tier 2** and **Tier 3** to live handling; extend `RHELP-Scope-Standard-Users` /
   `RHELP-Scope-VIP-Users` to the full populations in waves.
2. Bring **`RHELP-Scope-Unattended-Devices`** online only after the Step 4 governance and a
   successful unattended validation (Section 5).
3. Re-run **`RHELPOPS-Validate.ps1`** and **`RHELPOPS-Test-Scope.ps1`** each wave; keep reporting on
   the weekly cadence.

---
### Order of operations
`Tier agent groups → Scope groups → Per-tier RBAC roles → Unattended governance → Role assignments
(with scope) + session-to-ticket workflow → Reporting → Pilot + adoption campaign → Expand`
