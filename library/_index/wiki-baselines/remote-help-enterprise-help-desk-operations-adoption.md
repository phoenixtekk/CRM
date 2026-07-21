# Remote Help for the Enterprise Help Desk — Operations, Unattended Access & Adoption at Scale

> **Version 1.0.0** · Category: Intune · Solution code: RHELPOPS

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary — Remote Help for the Enterprise Help Desk (Operations, Unattended Access & Adoption)

**White-label · Intune Solutions**

Deploying Remote Help is the easy part; **running it as a help-desk capability** is where the value
is won or lost. Once the app is enabled and installed, an enterprise still needs the operating
model: who can help whom, when unattended access is appropriate and how it is governed, how a
session fits the ticket and escalation workflow, how usage and outcomes are measured, and how end
users learn to trust and request help. This package delivers that operating model.

> **Prerequisite:** this solution **assumes Remote Help is already deployed** — see the separate
> **Remote Help** solution (slug `remote-help`), which covers enable, app deployment, and the base
> security model. This package is the **operations and adoption layer on top** and does **not**
> repeat that setup.

This is a complete, self-guided package written for an administrator who has Remote Help deployed
but has not yet turned it into a governed, measured, widely-used help-desk service.

## What you get
- A **Solution Overview** of the operating model and exactly what it adds vs. the base deployment.
- A **Requirements Guide** with verify / implement-if-missing for every prerequisite (base
  deployment, tier definition, RBAC rights, licensing, unattended governance, ticketing, reporting).
- An **Implementation Guide** of precise, ordered steps: tier agent groups, scope groups, per-tier
  RBAC roles, unattended-access governance, role assignment with scope, the session-to-ticket
  workflow, KPI reporting, a pilot, and an adoption campaign — every object named and reused.
- Five **PowerShell scripts** for discovery, validation, KPI reporting, scope-proofing, and a
  `-WhatIf`-gated role/scope assigner.
- **Testing** (PASS/FAIL) and **Troubleshooting** guides for confident rollout.

## What this delivers
Help-desk **tiers mapped to Remote Help RBAC roles and scope** so agents help exactly the right
users and no more; **governed, guard-railed unattended access** owned by a single tier; a
**session-to-ticket workflow** with tier escalation; **usage/outcome/adoption KPI reporting**; and an
**adoption campaign** that gets end users requesting help and agents using the tool — piloted, then
expanded.

## Verify-with-Microsoft note
Remote Help's role/permission names, portal navigation, and — critically — whether and how
**unattended access** is offered change over time. This guide governs the *practice* and names every
object you create; it flags Microsoft-owned capability specifics to **verify against current
Microsoft documentation** rather than asserting them.

## The standard deployment model
**Assess → Configure → Pilot → Validate → Expand.**

## Outcome
Remote Help operating as a real help-desk capability — right-scoped roles, governed unattended
access, a traceable session-to-ticket workflow, outcome reporting, and genuine adoption.


---


# 1. Solution Overview — Remote Help for the Enterprise Help Desk (Operations, Unattended Access & Adoption)

## What this solution is
This is the **operations and adoption layer** that sits **on top of an existing Remote Help
deployment**. It does **not** install, enable, or re-teach the base Remote Help service or its
security model — that is the job of the separate **Remote Help** solution (slug `remote-help`),
which is the **prerequisite** for this package. This solution assumes Remote Help is already
enabled in the tenant, the Remote Help app is deployed to devices, and the base security model
(Entra authentication, RBAC, compliance visibility, audit) is in place.

> **Prerequisite (read this first):** This solution **assumes Remote Help is deployed per the
> "Remote Help" solution** (`remote-help`). If Remote Help is not yet enabled and the app not yet
> deployed, run that solution first. Everything below builds the *help-desk practice* around a
> working Remote Help deployment; it never repeats install/enable/security-model setup.

Once the app is in place, an enterprise still has to turn "installed" into a **running help-desk
capability**: who can help whom, when unattended access is appropriate and how it is governed, how
a session fits the ticket and escalation workflow, how usage and outcomes are measured, and how end
users learn to trust and request help. That operating model is what this solution delivers.

## What this adds vs. the base Remote Help product
| Base **Remote Help** product (prerequisite) | **This** operations/adoption product |
|---|---|
| Enable Remote Help in the tenant | *(assumed already done)* |
| Deploy the Remote Help app via Intune | *(assumed already done)* |
| The security model (Entra auth, RBAC, compliance, audit) | *(assumed already in place)* |
| — | **Role & scope design** — map help-desk **tiers** to RBAC roles + scope so agents help exactly the right users, and no more |
| — | **Attended vs unattended access** — when unattended is appropriate, how it is governed and consented, and its guardrails |
| — | **Help-desk workflow** — fit a session into ticket intake, verification, escalation tiers, and session logging/handoff |
| — | **Measurement** — usage, session outcomes, and adoption KPIs + reporting |
| — | **Adoption** — end-user comms, how to request help, trust/consent expectations, agent enablement |

## The operating model
1. **Tier the help desk.** Define the support tiers (for example **Tier 1 – Service Desk**,
   **Tier 2 – Desktop Support**, **Tier 3 – Escalation Engineering**) and decide what each tier is
   allowed to do in a Remote Help session (view only, full control, elevation).
2. **Map each tier to an RBAC role + scope.** Each tier gets its own Remote Help RBAC role
   (capability) and its own scope (the users it may help), so an agent can help exactly the right
   population and no more.
3. **Govern unattended access.** Decide where unattended assistance is appropriate (for example
   unattended kiosks, shared devices, or servers with no user present to consent), restrict it to a
   dedicated tier, and put guardrails around it. *(Unattended-access availability and behavior in
   Remote Help — whether it is offered, on which platforms, its exact settings and consent model —
   must be **verified against current Microsoft documentation**; this solution governs the practice,
   it does not assert the capability.)*
4. **Wire the session into the ticket workflow.** Every session starts from a ticket, verifies the
   caller, is escalated across tiers when needed, and is logged back to the ticket on completion.
5. **Measure and report.** Track session volume, outcomes, escalation and consent rates, unattended
   sessions, and adoption; report the KPIs that prove the capability is working.
6. **Drive adoption.** Tell end users how to request help and what to expect (consent, audit), and
   enable agents so the tool is actually used.

## Benefits
- **Right-scoped support** — agents help the users they should, with the capability they should have.
- **Governed unattended access** — a deliberate, guard-railed practice instead of an open door.
- **Faster, traceable resolution** — sessions live inside the ticket and escalation flow.
- **Provable value** — KPIs and reporting show utilization, outcomes, and adoption.
- **Real adoption** — end users trust it and agents use it, so the investment pays off.

## Limitations (be honest with buyers)
- **Requires Remote Help already deployed** (the `remote-help` solution) — this package does not
  install or enable it.
- **Unattended-access specifics are Microsoft-governed** — availability, supported platforms, exact
  settings, and consent behavior change over time and must be verified against current Microsoft
  documentation before you rely on them.
- **RBAC role names, permission names, and portal navigation** in Intune change over time — this
  guide names objects consistently but you must confirm current labels in your tenant.
- **Ticketing integration is process-level** — this solution defines how a session maps to a ticket;
  it does not build a code integration to any specific ITSM product.

## The standard deployment model
> **Design the tiers & role/scope model → configure roles, scope, and unattended governance →
> pilot with one tier and a small user scope → validate scope, unattended, logging, and KPIs →
> expand across tiers and run the adoption campaign.** Repeatable pattern:
> **Assess → Configure → Pilot → Validate → Expand.**


---


# 2. Requirements Guide — Remote Help Operations & Adoption

Verify **every** requirement before configuring. Each entry: **Description · Why · Verify ·
Implement-if-missing.** Category-wide prerequisites are in `global-requirements-intune-solutions.md`.

> This solution is the **operations/adoption layer**. Its single biggest prerequisite is that the
> **base Remote Help deployment already exists** — see 2.1. It does **not** re-teach that setup.

## 2.1 Remote Help already deployed (the base product)
**Description:** Remote Help is already **enabled** tenant-wide, the **Remote Help app is deployed**
to devices via Intune, and the base security model (Entra authentication, RBAC framework,
compliance visibility, audit) is in place.
**Why:** This solution builds the help-desk operating model *around* a working Remote Help
deployment. Without it there is nothing to operate.
**Verify:** Intune → **Tenant administration → Remote Help** shows Remote Help **Enabled**; the
Remote Help app shows as installed on pilot devices. Or run **`RHELPOPS-Discovery.ps1`** (reports
whether Remote Help is enabled and which RBAC role assignments already exist).
**Implement:** If Remote Help is **not** yet deployed, run the separate **"Remote Help"** solution
(slug `remote-help`) first — it covers enable, app deployment, and the security model. Return here
once it is in place.

## 2.2 Help-desk tier definition
**Description:** A defined set of support tiers and, for each, the intended Remote Help capability
(view only, full control, elevation).
**Why:** Roles and scope are assigned per tier; you cannot map roles until the tiers exist.
**Verify:** A written tier model exists (for example **Tier 1 – Service Desk**, **Tier 2 – Desktop
Support**, **Tier 3 – Escalation Engineering**).
**Implement:** Document the tiers and their intended capability before configuring roles (this guide
uses those three tier names throughout).

## 2.3 RBAC role rights to create/assign roles
**Description:** An operator account with rights to create and assign Intune RBAC roles and to read
role assignments.
**Why:** This solution creates custom Remote Help RBAC roles and assigns them with scope.
**Verify:** Intune → **Tenant administration → Roles** is accessible and **Create** / **Assignments**
are available to your account.
**Implement:** Assign **Intune Administrator** (or a role that grants RBAC management) to the
operator. *(The exact built-in role that grants "manage Intune roles" — and whether a custom role
can — must be **verified against current Microsoft documentation**.)*

## 2.4 Remote Help RBAC roles & permissions
**Description:** Remote Help RBAC roles that express each tier's capability (view, full control,
elevation) — either the built-in Remote Help roles or custom roles built from Remote Help
permissions.
**Why:** The role is what limits *what* an agent can do in a session; scope limits *who* they can
help.
**Verify:** Intune → **Tenant administration → Roles**; confirm Remote Help roles/permissions are
available to select.
**Implement:** Create the custom roles in Section 3. *(The exact **names** of the built-in Remote
Help roles, the exact **permission names** for view vs full control vs elevation, and whether
unattended access is expressed as a permission — **verify against current Microsoft documentation**;
do not assume the labels.)*

## 2.5 Licensing for helpers (and any unattended scenario)
**Description:** A Remote Help license assigned to helper (agent) accounts, and any additional
licensing that unattended assistance may require.
**Why:** Remote Help is a licensed add-on; unattended scenarios may have their own licensing or
capability requirements.
**Verify:** M365 admin center → **Billing → Licenses** (Intune Suite / Remote Help add-on) for agent
accounts.
**Implement:** Assign the Remote Help / Intune Suite license to every agent account. *(Whether
unattended access requires any additional license or capability — **verify against current Microsoft
documentation**.)*

## 2.6 Unattended-access governance decision
**Description:** A documented decision on **whether** unattended assistance is allowed, **where** (which
device populations), and **which tier** owns it, plus the guardrails (change/ticket requirement,
logging, review).
**Why:** Unattended access removes the live-consent step, so it must be a deliberate, governed
practice — not a default.
**Verify:** A written unattended-access policy exists and names the owning tier.
**Implement:** Complete the decision in Section 3, Step 4. *(Whether Remote Help offers unattended
access at all, on which platforms, and its exact consent/behavior model — **verify against current
Microsoft documentation** before enabling anything.)*

## 2.7 Ticketing / ITSM integration points
**Description:** A ticketing/ITSM system and a defined point in its workflow where a Remote Help
session is initiated and where the session outcome is logged back.
**Why:** Sessions must be traceable to a ticket for accountability, escalation, and reporting.
**Verify:** Your ITSM system has a ticket state/field where "Remote Help session" can be recorded
(for example a work-note, activity, or custom field).
**Implement:** Define the session-to-ticket steps in Section 3, Step 5. This is a **process**
integration (agents record the session on the ticket); it is not a code integration to any specific
ITSM product.

## 2.8 Reporting / audit read access
**Description:** Access to Remote Help usage/audit data for reporting KPIs.
**Why:** Measurement depends on being able to read session/usage and audit activity.
**Verify:** Intune → **Tenant administration → Remote Help** shows a usage report; or an account with
Graph **AuditLog.Read.All** / **DeviceManagementApps.Read.All** can run **`RHELPOPS-Report.ps1`**.
**Implement:** Grant the reporting account the read access above. *(The exact Remote Help usage
report location and the Graph scopes/endpoints that expose session data — **verify against current
Microsoft documentation**.)*

---
## Checklist
- [ ] Remote Help already deployed (base `remote-help` solution) — `RHELPOPS-Discovery.ps1`
- [ ] Help-desk tiers defined (Tier 1 / Tier 2 / Tier 3) with intended capability
- [ ] Operator has rights to create/assign RBAC roles
- [ ] Remote Help RBAC roles/permissions available (names verified against Microsoft docs)
- [ ] Remote Help license on agent accounts (+ any unattended licensing verified)
- [ ] Unattended-access governance decision documented (owning tier + guardrails)
- [ ] Ticketing/ITSM session-log point defined
- [ ] Reporting/audit read access granted


---


# Global Requirements — Intune Solutions (category-level)

These requirements apply to **every** solution in the **Intune Solutions**
category. They are published once at the category level so individual listings stay small.
Confirm these before deploying *any* Intune solution. Each entry: **Description · Why · Verify · Implement-if-missing.**

## G1. Microsoft Entra ID tenant
**Description:** An active Microsoft Entra ID (Azure AD) tenant.
**Why:** It is the identity backbone for every cloud and Intune-managed resource.
**Verify:** Sign in to `https://entra.microsoft.com` as an administrator.
**Implement:** Create a Microsoft 365/Azure subscription, which provisions a tenant.

## G2. Microsoft Intune subscription
**Description:** An Intune-bearing license plan.
**Why:** Intune delivers all configuration, compliance, and security policies.
**Verify:** `https://intune.microsoft.com` loads; **Tenant administration → Tenant status** shows active.
**Implement:** Assign Microsoft 365 E3/E5, Business Premium, or standalone Intune Plan 1.

## G3. Administrative roles
**Description:** Appropriate Entra/Intune admin roles for the operator.
**Why:** Creating policies and enrollment settings requires elevated rights.
**Verify:** Entra → **Roles and administrators**; confirm **Intune Administrator**.
**Implement:** Assign **Intune Administrator**; reserve Global Administrator for tenant-wide changes.

## G4. Device enrollment in Intune
**Description:** Targeted Windows devices are enrolled and manageable.
**Why:** Policies only reach enrolled devices.
**Verify:** Intune → **Devices → All devices**; the device appears and is **compliant**.
**Implement:** Enable **Automatic Enrollment** and join devices to Entra ID.

## G5. Pilot security group
**Description:** A Microsoft Entra security group for pilot/targeted users or devices.
**Why:** Every solution is piloted before fleet rollout.
**Verify:** Entra → **Groups**; the pilot group exists.
**Implement:** Entra → **Groups → New group** → **Security** → add members.

## G6. Supported Windows baseline
**Description:** Windows 10 21H2+ or Windows 11 with current updates.
**Why:** Modern Intune features assume a patched, supported OS.
**Verify:** `winver`, or Intune → device → **Hardware**.
**Implement:** Deploy **Update rings** or upgrade to Windows 11.

## G7. Network access to Microsoft cloud endpoints
**Description:** Outbound HTTPS to Microsoft 365, Entra, and Intune service URLs.
**Why:** Enrollment, policy sync, and authentication depend on these endpoints.
**Verify:** From a device, reach `https://login.microsoftonline.com` and `https://enrollment.manage.microsoft.com`.
**Implement:** Allow Microsoft's published Office 365/Intune URL & IP ranges through proxy/firewall.

---
**The standard deployment model (all solutions):** **Assess → Configure → Pilot → Validate → Expand.**


---


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


---


# 5. Testing Guide — Remote Help Operations & Adoption

Run after the pilot setup (Implementation Step 7a) and after each expansion wave. Each test has an
explicit **PASS/FAIL**. All object names match Section 3 exactly.

## Test 1 — An agent can help only in-scope users
**Do:** As a **Tier 1** agent (`RHELP-T1-Agents`), start a Remote Help session to a user **in**
`RHELP-Scope-Standard-Users`; then attempt a user **not** in any scope assigned to Tier 1 (for
example a `RHELP-Scope-VIP-Users`-only user). Also run **`RHELPOPS-Test-Scope.ps1`**.
**PASS:** The in-scope session is permitted; the out-of-scope attempt is **not** available/permitted,
and `RHELPOPS-Test-Scope.ps1` reports the Tier 1 scope resolves to the intended users **and no more**.
**FAIL:** A Tier 1 agent can help a user outside `RHELP-Scope-Standard-Users`.

## Test 2 — Capability matches the tier
**Do:** Verify a **Tier 1** session is **view-only** (no control), a **Tier 2** session allows
**full control**, and a **Tier 3** session allows control **and** elevation.
**PASS:** Each tier has exactly its intended capability (`RHELP Role – Tier 1 View` /
`RHELP Role – Tier 2 Control` / `RHELP Role – Tier 3 Elevation`).
**FAIL:** A tier has more (or less) capability than its role defines — for example Tier 1 can take
control.

## Test 3 — Unattended access works only where governed
**Do:** As **Tier 3**, attempt an unattended session to a device **in**
`RHELP-Scope-Unattended-Devices` (with the approving change/ticket); then attempt an unattended
session to a device **not** in that group, and attempt unattended as **Tier 1/Tier 2**.
**PASS:** Unattended succeeds **only** for approved devices **and only** for Tier 3; every
non-approved device and every non-Tier-3 attempt is refused.
**FAIL:** Unattended works on a non-approved device, or a non-Tier-3 tier can run unattended.
*(If Microsoft does not offer unattended for your platform, this test's PASS is: no unattended path
exists anywhere, and the policy records that — **verify against current Microsoft documentation**.)*

## Test 4 — A session is logged to a ticket
**Do:** Run an attended session end-to-end from a ticket, then inspect the ticket.
**PASS:** The ticket records session start/end time, attended vs unattended, actions taken, and
outcome (resolved/escalated), per Step 5b. Unattended sessions also reference the approving change.
**FAIL:** A completed session leaves no ticket record, or is missing the required fields.

## Test 5 — Escalation moves the ticket (and the authorized tier)
**Do:** As Tier 1, hit a case beyond your capability/scope and escalate.
**PASS:** The **ticket** moves to Tier 2/Tier 3, and the higher tier (not the Tier 1 agent) performs
the control/elevation/VIP action. The Tier 1 agent never exceeds `RHELP Role – Tier 1 View`.
**FAIL:** An agent exceeds their tier instead of escalating the ticket.

## Test 6 — KPIs report
**Do:** Run **`RHELPOPS-Report.ps1`** for the reporting window and review the CSV; run
**`RHELPOPS-Validate.ps1`**.
**PASS:** The report produces the defined KPIs (session volume per tier, average handle time,
first-contact resolution, escalation rate, consent/decline rate, unattended session count, adoption
rate) — populated from Remote Help usage plus ITSM ticket data — and `RHELPOPS-Validate.ps1` reports
the role/scope model in place, reporting available, and unattended governed.
**FAIL:** KPIs cannot be produced, or `RHELPOPS-Validate.ps1` reports the model/reporting/unattended
governance is missing.

## Test 7 — Adoption is measurable
**Do:** Confirm the single request path (ticket queue) is the entry point and that the adoption-rate
KPI (share of eligible tickets using Remote Help) is populated for the pilot population.
**PASS:** Adoption rate is being measured from the defined entry point.
**FAIL:** There is no single request path, or adoption cannot be measured.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| **Pilot pass** | Tests 1, 2, 4, 6, 7 pass for the pilot tier/scope (Test 3 if unattended is in scope) |
| **Wave pass** | Tests 1, 2, 4, 6 pass before the next expansion wave |
| **Unattended go-live** | Test 3 passes before `RHELP-Scope-Unattended-Devices` goes live |


---


# 6. Troubleshooting Guide — Remote Help Operations & Adoption

Use **`RHELPOPS-Discovery.ps1`** to see the current role/scope model, **`RHELPOPS-Validate.ps1`** for
a PASS/FAIL check of the whole model, **`RHELPOPS-Test-Scope.ps1`** to prove a tier's reach, and
**`RHELPOPS-Report.ps1`** for KPI data. Object names match the Implementation Guide exactly.

> This layer assumes Remote Help is already deployed (base `remote-help` solution). If the app won't
> enable/install or a session won't connect **at all**, that is a base-deployment issue — see the
> base Remote Help solution's troubleshooting, not this one.

## A. Agent can't help / wrong scope
| Symptom | Cause | Remediation |
|---|---|---|
| Agent can't help a user they should | Agent not in the tier group, or the scope group doesn't contain that user | Add the agent to `RHELP-T1/2/3-Agents`; add the user to the correct `RHELP-Scope-*` group; run `RHELPOPS-Test-Scope.ps1` |
| Agent **can** help a user they should NOT (over-reach) | Role scope too broad, or tier assigned an extra scope group | Run `RHELPOPS-Test-Scope.ps1` (reports over-reach); remove the extra scope group from that tier's assignment (`RHELP Assignment – Tier N`) |
| Agent has more control than intended (e.g. Tier 1 can take control) | Wrong role on the tier | Confirm the tier uses its role — Tier 1 → `RHELP Role – Tier 1 View`, Tier 2 → `…Control`, Tier 3 → `…Elevation`; re-assign with `RHELPOPS-Set-RoleScope.ps1` |
| Scope seems ignored | How Remote Help evaluates scope groups vs. scope tags may differ from expectation | **Verify the current scope-gating behavior against Microsoft documentation**; re-run Testing Test 1 to confirm the actual boundary before trusting it |

## B. Unattended access not available / not among tiers
| Symptom | Cause | Remediation |
|---|---|---|
| Unattended option missing entirely | Remote Help may not offer unattended for your platform/scenario, or it isn't enabled | **Verify availability against current Microsoft documentation**; if unsupported, record it in the policy and route those cases to an alternative governed path — do not work around it |
| Unattended works on a device it shouldn't | Device wrongly in `RHELP-Scope-Unattended-Devices` | Remove the device from the group; keep only approved kiosks/shared/no-consent devices |
| A non-Tier-3 tier can run unattended | Unattended scope attached to a role other than Tier 3 | Detach `RHELP-Scope-Unattended-Devices` from Tier 1/Tier 2 assignments; keep it only on `RHELP Assignment – Tier 3`; re-run `RHELPOPS-Validate.ps1` |
| Unattended session has no approving change | Guardrail skipped | Enforce the change/ticket precondition (Step 4.3); reject sessions without it |

## C. Session not logged to a ticket
| Symptom | Cause | Remediation |
|---|---|---|
| Completed session leaves no ticket record | Agent started ad-hoc, not from a ticket | Enforce "every session starts from a ticket" (Step 5b.1); coach the agent |
| Ticket record missing required fields | Logging step skipped | Require start/end time, attended/unattended, actions, and outcome on close (Step 5b.6); add it to the ticket template |
| Can't tie platform activity to a ticket | No ticket id captured | Record the `TicketId` in the session log so `RHELPOPS-Report.ps1` output can be joined to ITSM data |

## D. KPIs missing / can't report
| Symptom | Cause | Remediation |
|---|---|---|
| `RHELPOPS-Report.ps1` returns nothing | Reporting access missing, or the Graph usage endpoint differs | Grant the reporting account read access; **verify the current Remote Help usage endpoint/scopes against Microsoft documentation**; fall back to Intune → Tenant administration → Remote Help usage report |
| Volume shows but outcome/adoption KPIs blank | Those KPIs need ITSM data | Enrich the CSV with ticket data (attended/unattended, handle time, FCR, escalation, ticket id) per the provided columns |
| Per-tier split missing | Tier isn't derivable from platform data alone | Map the agent to its tier group (from `RHELPOPS-Discovery.ps1`) when enriching the report |
| `RHELPOPS-Validate.ps1` FAILs "reporting reachable" | Audit/usage endpoint didn't respond | Confirm scopes/permissions and endpoint; retry |

## E. Low adoption
| Symptom | Cause | Remediation |
|---|---|---|
| Users don't request help / low adoption rate | No single request path or unclear comms | Publish the "How to get remote help" note (Step 7b.1); make the ticket queue the one entry point |
| Users decline sessions | Trust/consent not set | State plainly that agents are Entra-authenticated, sessions need **consent**, and are **audited** |
| Agents don't use the tool | Enablement gap | Train each tier on capability, scope, escalation, and logging (Step 7b.3) |
| Adoption can't be measured | No defined entry point/KPI | Define the adoption-rate KPI (eligible tickets using Remote Help) and measure from the ticket queue |

## F. Scripts
Run from a workstation with the **Microsoft Graph PowerShell SDK** installed
(`Install-Module Microsoft.Graph -Scope CurrentUser`). All are read-only **except**
`RHELPOPS-Set-RoleScope.ps1`, which **defaults to `-WhatIf`** (dry run) and changes nothing until you
pass `-WhatIf:$false`.

| Script | Use it when |
|---|---|
| `RHELPOPS-Discovery.ps1` | You need to see the current role assignments, scope groups, and who-can-help-whom |
| `RHELPOPS-Validate.ps1` | You want a PASS/FAIL on role/scope model, reporting, and unattended governance |
| `RHELPOPS-Test-Scope.ps1` | You must prove a tier is scoped to the intended users and no more (over-reach/gap) |
| `RHELPOPS-Report.ps1` | You need the usage/outcome/adoption KPI export (CSV) |
| `RHELPOPS-Set-RoleScope.ps1` | You want to apply/adjust one tier's role+scope binding (dry-run first) |

```powershell
# See the current model
powershell -ExecutionPolicy Bypass -File .\RHELPOPS-Discovery.ps1

# Validate the whole operating model (exit code = number of failed checks)
powershell -ExecutionPolicy Bypass -File .\RHELPOPS-Validate.ps1

# Prove Tier 1 is scoped to standard users and no more
powershell -ExecutionPolicy Bypass -File .\RHELPOPS-Test-Scope.ps1 -TierAgentGroup RHELP-T1-Agents -ExpectedScopeGroup RHELP-Scope-Standard-Users

# Export KPIs
powershell -ExecutionPolicy Bypass -File .\RHELPOPS-Report.ps1 -Days 30 -CsvPath C:\Temp\rhelpops-kpis.csv

# Assign a role+scope to a tier (DRY RUN by default; add -WhatIf:$false to commit)
powershell -ExecutionPolicy Bypass -File .\RHELPOPS-Set-RoleScope.ps1 -RoleName 'RHELP Role – Tier 1 View' -AgentGroup RHELP-T1-Agents -ScopeGroup RHELP-Scope-Standard-Users -AssignmentName 'RHELP Assignment – Tier 1'
```

## G. When to escalate
If the role/scope model validates (`RHELPOPS-Validate.ps1` PASS), scope proves correct
(`RHELPOPS-Test-Scope.ps1` PASS), unattended is governed to Tier 3 only, and sessions still behave
unexpectedly (scope not honored, unattended behaving differently than documented), capture the
behavior and **verify the current Remote Help capability against Microsoft documentation**; if it
still conflicts, open a Microsoft Intune support case with the role/assignment details.


---


# 7. Best Practices — Remote Help Operations & Adoption

## Role & scope design
- **One role per tier, one capability per tier.** Keep `RHELP Role – Tier 1 View` view-only, reserve
  full control for `RHELP Role – Tier 2 Control`, and elevation for `RHELP Role – Tier 3 Elevation`.
  Never blur capabilities across tiers.
- **Scope is the "who," role is the "what."** Use scope groups (`RHELP-Scope-Standard-Users`,
  `RHELP-Scope-VIP-Users`) to limit who each tier can help; use the role to limit what they can do.
- **Keep scope groups Assigned, not Dynamic.** An agent's reach should widen only by a deliberate,
  auditable change — never automatically.
- **Route VIP/executive support to a dedicated tier.** Handle `RHELP-Scope-VIP-Users` at Tier 3 so
  sensitive users get consistent, senior handling.

## Unattended access
- **Treat unattended as an exception, not a default.** Grant it to **Tier 3 only** and only for
  devices in `RHELP-Scope-Unattended-Devices`.
- **Require a change/ticket for every unattended session** and flag it as unattended in reporting.
- **Review the unattended device scope on a cadence** (for example monthly) and remove devices that
  no longer need it.
- **Verify the capability before you rely on it.** Whether Remote Help offers unattended access, on
  which platforms, and how consent behaves must be confirmed against current Microsoft documentation.

## Workflow & escalation
- **Every session starts from a ticket** — no ad-hoc help. It is the record, the scope, and the KPI
  source.
- **Verify the caller before connecting**, every time.
- **Escalate the ticket, never exceed the role.** When a case is beyond a tier, the ticket moves to
  the tier that is authorized — the agent does not.
- **Log the session on the ticket on completion** (time, attended/unattended, actions, outcome).

## Measurement & adoption
- **Define KPIs up front** and report them on a fixed cadence with `RHELPOPS-Report.ps1`.
- **Combine platform usage with ITSM data** — outcome and adoption KPIs need both.
- **Give end users one request path** and set consent/audit expectations plainly so they trust it.
- **Enable agents on scope, capability, escalation, and logging** — adoption fails when agents are
  unsure what they may do.
- **Iterate the comms where uptake is low** — a downward escalation rate and a rising adoption rate
  mean the model is working.

## Hygiene
- **Document the role/scope model** (which tier, which role, which scope) for audits.
- **Re-validate each wave** with `RHELPOPS-Validate.ps1` and `RHELPOPS-Test-Scope.ps1`.
- **Confirm current portal labels and role/permission names** against Microsoft documentation before
  each major change — they drift.


---


# 8. Deliverables Summary — Remote Help Operations & Adoption

> **Prerequisite:** the base **Remote Help** solution (slug `remote-help`) — this package is the
> operations/adoption layer on top of it and does not repeat install/enable/security-model setup.

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case: turning a Remote Help deployment into a running help-desk capability |
| 1. Solution Overview | The operating model, what this adds vs. the base product, benefits, limitations |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing (base deployment, tiers, RBAC, licensing, ticketing, reporting) |
| Global Requirements (Intune Solutions) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Ordered steps: tier groups, scope groups, per-tier RBAC roles, unattended governance, role assignment + session-to-ticket workflow, reporting, pilot + adoption, expand |
| 5. Testing Guide | PASS/FAIL validation (in-scope only, capability per tier, governed unattended, ticket logging, escalation, KPIs, adoption) |
| 6. Troubleshooting Guide | Field issues and remediation (wrong scope, unattended not available, session not logged, KPIs missing, low adoption) |
| 7. Best Practices | Field-proven recommendations for role/scope, unattended, workflow, and adoption |

## PowerShell scripts
| Script | What it does |
|---|---|
| `RHELPOPS-Discovery.ps1` | Read-only: reports existing Remote Help RBAC role assignments, scope groups, and who-can-help-whom |
| `RHELPOPS-Validate.ps1` | PASS/FAIL: role/scope model in place, reporting available, unattended governed |
| `RHELPOPS-Report.ps1` | Exports usage/outcome/adoption KPIs to CSV |
| `RHELPOPS-Test-Scope.ps1` | Read-only: proves an agent tier is scoped to the intended users and no more |
| `RHELPOPS-Set-RoleScope.ps1` | The only state-changer: assigns a Remote Help RBAC role + scope group to a help-desk tier. **Defaults to `-WhatIf`.** |

## What the buyer receives
- This operations/adoption guide as a **Word** document and **PDF**.
- All five **PowerShell scripts** in a single ZIP.
- A repeatable process following the standard model: **Assess → Configure → Pilot → Validate → Expand.**

## Outcome
Remote Help running as a real help-desk capability — right-scoped tier roles, governed unattended
access, a session-to-ticket workflow with escalation, outcome/adoption reporting, and end-user
adoption — not just an installed app.
