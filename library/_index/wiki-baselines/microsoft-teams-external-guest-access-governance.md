# Microsoft Teams External Access & Guest Governance

> **Version 1.0.0** · Category: Teams · Solution code: TEAMSEXT

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary

**Outcome.** External collaboration in Microsoft Teams stays **enabled** — partners, vendors, and
clients can chat, meet, and share — while being **scoped, reviewed, and on policy**. External access is
limited to approved domains, guests are recertified and expire rather than accumulate, shared channels
connect only to deliberately chosen partner tenants, and sensitivity classification drives external
posture. The result is open-but-governed collaboration with an audit trail.

**Problem.** Teams offers three *different* external-collaboration surfaces — external access
(federation), guest access (Entra B2B collaboration), and shared channels (Entra B2B direct connect) —
each with its own controls. Ungoverned, they leak data to any domain and pile up stale guest accounts
that never expire. Locking one down does not govern the others, so most tenants are partially exposed
without realizing it.

**Approach.** The solution governs all three surfaces plus lifecycle and sensitivity, following a
disciplined, pilot-first model — **Assess → Design → Configure → Pilot → Validate → Expand**:

- **Assess** current posture read-only (federation, guest, shared-channel, cross-tenant settings, and a
  stale-guest count).
- **Design** the target with security/compliance/governance: allowed/blocked domains, shared-channel
  partners, guest review cadence and expiration, and the governing sensitivity label.
- **Configure** each surface with named, reusable policies; **pilot** on a scoped group; **validate**
  against explicit pass/fail gates; then **expand** with a documented, deterministic rollback.

**Why it is low-risk.** Every change is **dry-run by default** (`-WhatIf`) and applied only with an
explicit `-Commit` inside a change window. A full baseline is captured before any change, so rollback
reapplies known-good values rather than "turning external access off". Changes reach a **pilot** group
before the tenant, and pass/fail gates must clear before expansion. Automation uses **modern-auth**,
least-privilege roles, and **no stored credentials**. Plan- and cloud-dependent behavior (Entra ID
Governance/P2 for reviews, container-label licensing, Commercial vs Government cloud URLs) is
**flagged to verify in your tenant**, never assumed. Domain, classification, and retention
**determinations remain with your compliance and governance functions** — the solution provides the
technical method and evidence, delivered as documentation plus five safe-by-default PowerShell tools.


---


# Solution Overview

External collaboration in Microsoft Teams is powerful — partners, vendors, and clients can chat, meet,
and co-author inside your teams. Left ungoverned, that same power leaks data to any domain, accumulates
stale guest accounts that never expire, and exposes shared channels no one is watching. This solution
gives a Microsoft 365 collaboration admin an exact, run-to-implement method to **enable external
collaboration while keeping it scoped, reviewed, and on policy**.

## What it is

A governed configuration for the three distinct external-collaboration surfaces in Teams, plus the
lifecycle and sensitivity controls that keep them safe over time:

1. **External access (federation)** — tenant-to-tenant and (optionally) consumer Teams/Skype
   communication. External users are **not** added to your directory; they chat/call from their own
   tenant. Governed with the **federation configuration** (allowed/blocked domains) and per-user
   **external access policies**.
2. **Guest access** — external people are invited **into** your directory as **guest** members of a
   team (an Entra B2B collaboration guest, `userType = Guest`). They appear in the team roster and can
   access channels, files, and apps subject to guest policy. Governed with Teams guest
   configuration, Entra **External collaboration settings** (allow/deny domains), and guest
   **lifecycle** (access reviews + expiration).
3. **Shared channels** — a channel shared with people in **other tenants** via **Entra B2B direct
   connect**, without adding them as guests or switching tenants. Governed with the Teams **channels
   policy** and **cross-tenant access settings** (b2bDirectConnect inbound/outbound).

On top of those three surfaces the solution wires two durable controls:

- **Guest lifecycle** — recurring **Entra access reviews** that recertify or auto-remove guests, and
  **expiration** so access does not live forever (Entra access reviews / lifecycle workflows).
- **Sensitivity** — container **sensitivity labels** (Microsoft Purview) that set a team/group's
  external-sharing and guest posture from the label, so classification drives control.

## How it works (reference design)

```
                    EXTERNAL COLLABORATION SURFACES (governed separately)
  ┌───────────────────────┬───────────────────────┬──────────────────────────┐
  │  External access      │   Guest access        │   Shared channels        │
  │  (federation)         │   (B2B collaboration) │   (B2B direct connect)   │
  ├───────────────────────┼───────────────────────┼──────────────────────────┤
  │ chat/call across      │ external user added   │ channel shared to other  │
  │ tenants; user NOT in  │ INTO your directory   │ tenants; user stays in   │
  │ your directory        │ as a Guest member     │ THEIR tenant             │
  ├───────────────────────┼───────────────────────┼──────────────────────────┤
  │ Federation config     │ Teams guest config    │ Teams channels policy    │
  │ allow/block domains   │ + Entra external      │ + cross-tenant access    │
  │ + external access pol │ collab settings       │ settings (directConnect) │
  └───────────────────────┴───────────────────────┴──────────────────────────┘
        │                          │                          │
        └──────────── Cross-tenant access settings (Entra) ───┘
                                   │
                 ┌─────────────────┴──────────────────┐
                 │ Guest lifecycle: access reviews +   │
                 │ expiration (Entra ID Governance)    │
                 ├─────────────────────────────────────┤
                 │ Sensitivity labels (Purview): label │
                 │ drives external-sharing / guest set │
                 └─────────────────────────────────────┘
```

**Distinction that matters most:** *external access ≠ guest access ≠ shared channels.* They use
different Entra plumbing, different admin surfaces, and different governance. Configuring one does not
govern the others — a tenant with guest access locked down but federation wide-open is still exposed.
This solution treats all three explicitly.

Each artifact this solution creates is **named** with the convention `<Purpose> – <Scope> – <Stage>`
and reused verbatim in configuration, testing, troubleshooting, and the scripts, e.g.:

- `External Access Policy – Pilot` (per-user Teams external access policy)
- `Teams Channels Policy – SharedCh-Pilot` (shared-channel controls)
- `Cross-Tenant Partner – Partner-A – Pilot` (a named partner org in cross-tenant access settings)
- `Guest Access Review – Recert – Pilot` (recurring Entra access review of guests)
- `Sensitivity Label – Ext-Collab – Prod` (container label controlling external sharing)

## Deployment model

The solution follows the house model — **Assess → Design → Configure → Pilot → Validate → Expand** —
because external access, cross-tenant settings, and guest lifecycle are **tenant-wide, high-impact**
changes:

- **Assess** current posture (what federation/guest/shared-channel settings exist, how many guests,
  how many stale) with the read-only discovery script.
- **Design** the target: which domains are allowed, whether shared channels are on, the review cadence
  and expiration, and which sensitivity labels drive external sharing. Get compliance/governance sign-off.
- **Configure** the settings and policies (default to `-WhatIf`, apply with an explicit `-Commit`).
- **Pilot** on a named policy group / pilot team before org-wide assignment.
- **Validate** against pass/fail gates (external scoped to policy, stale guests reviewed, shared
  channels controlled).
- **Expand** to the org once gates pass — with a documented rollback.

## Benefits

- **External collaboration stays on** — you enable partners without a blanket "block everything".
- **Scoped, not open** — allow/block domains and per-user policies mean only intended orgs connect.
- **Guests don't pile up** — access reviews + expiration recertify or remove them automatically.
- **Shared channels are controlled** — direct-connect is a deliberate, per-partner decision.
- **Classification drives control** — sensitivity labels apply external-sharing posture consistently.
- **Auditable** — every setting is scripted, reported, and validated against a baseline.

## Limitations & boundaries

- **Plan-dependent features are flagged, not assumed.** Recurring **access reviews**, **lifecycle
  workflows**, and some **conditional access for external users** require **Microsoft Entra ID
  Governance** and/or **Entra ID P2** — *verify your licensing in the M365 admin center.* Container
  **sensitivity labels** require the appropriate Purview/Information Protection licensing.
- **Commercial vs Government cloud** portal URLs and some feature availability differ (e.g.
  `*.office365.us` / GCC-High). Where a path is cloud-specific it is flagged **"verify in your
  tenant"** — do not assume the commercial URL.
- **Compliance/legal determinations are deferred.** Which domains are *permitted*, what data
  classification a partner may see, and retention/records outcomes are decisions for your
  security/compliance/records functions. This solution provides the **technical method and evidence**,
  not the policy determination.
- **Third-party/partner-tenant behavior is out of scope** — you control your side of cross-tenant
  access; the partner controls theirs. Shared channels and direct connect require **both** tenants to
  allow the connection.


---


# Requirements

These are the **solution-specific** prerequisites for governing Teams external access and guests. They
build **on top of** the shared Teams category prerequisites in **`global-requirements-teams.md`**
(tenant + licensing, least-privilege Teams roles, the MicrosoftTeams PowerShell + Graph toolchain, an
identity/group source of truth, a pilot scope + change control, and security/compliance/governance
stakeholders). Verify the six shared items there first, then confirm the following.

---

## 1. Microsoft Entra External ID / B2B collaboration enabled

- **Description:** Guest access and shared channels are Entra **B2B** features (B2B collaboration for
  guests, B2B **direct connect** for shared channels). External Identities must be available in the
  tenant.
- **Why:** Teams guest access is a presentation layer over Entra B2B; if B2B invitations are blocked at
  the Entra level, no Teams guest toggle will let guests in. Shared channels require B2B direct connect.
- **Verify:** Entra admin center → **External Identities → External collaboration settings** loads and
  shows guest-invite settings. Graph: `Get-MgPolicyAuthorizationPolicy` returns `allowInvitesFrom`.
- **Implement if missing:** Enable External Identities and set the guest-invite posture with a Global
  Administrator (or External Identity Provider Administrator) under change control.

## 2. Cross-tenant access settings administered (default + per-partner)

- **Description:** The Entra **cross-tenant access settings** — the **Default** policy plus any
  **Organizational settings** (named partner tenants) — govern inbound/outbound **B2B collaboration**
  and **B2B direct connect** (shared channels).
- **Why:** Shared channels to another tenant only work when *both* tenants allow **b2bDirectConnect** in
  cross-tenant access settings; guest scoping can also be tightened per-partner here.
- **Verify:** Entra → **External Identities → Cross-tenant access settings** loads. Graph:
  `Get-MgPolicyCrossTenantAccessPolicyDefault` and `Get-MgPolicyCrossTenantAccessPolicyPartner` succeed
  (module `Microsoft.Graph.Identity.SignIns`).
- **Implement if missing:** Grant an admin the ability to edit cross-tenant access settings; capture the
  partner tenant IDs to be configured (e.g. `Cross-Tenant Partner – Partner-A – Pilot`).

## 3. Guest lifecycle capability — access reviews / expiration (licensing-dependent)

- **Description:** The ability to run **recurring access reviews** of guests and to **expire/remove**
  stale guests automatically.
- **Why:** Governance requires guests be recertified or removed; manual review does not scale.
- **Verify:** Entra → **Identity Governance → Access reviews** is available. **This requires Microsoft
  Entra ID Governance and/or Entra ID P2 — verify your licensing in the M365 admin center; do not
  assume it is present.** Graph: `Get-MgIdentityGovernanceAccessReviewDefinition` succeeds (module
  `Microsoft.Graph.Identity.Governance`).
- **Implement if missing:** Acquire the required Entra ID Governance / P2 entitlement, **or** fall back
  to the reporting script's stale-guest list + a documented manual removal runbook (the solution
  supports both).

## 4. Container sensitivity labels for groups & sites (licensing-dependent)

- **Description:** **Sensitivity labels** scoped to **Groups & sites** (Microsoft Purview) that set a
  team's external-sharing and guest-access posture from the label.
- **Why:** Label-driven control keeps external posture consistent with data classification instead of
  per-team guesswork.
- **Verify:** Purview portal → **Information Protection → Labels** shows labels with the **Groups &
  sites** scope. Container labels must be enabled on the tenant
  (`Get-MgDirectorySetting` / the `Group.Unified` setting `EnableMIPLabels = true`). **Licensing is
  plan-dependent — verify in your tenant.**
- **Implement if missing:** Enable container labels and author at least one label (e.g.
  `Sensitivity Label – Ext-Collab – Prod`) with your information-protection owner. If labels are not
  licensed, this control is optional — the other three surfaces still govern external access.

## 5. Admin roles specific to this solution

- **Description:** Beyond **Teams Administrator** (external access, guest, channels policies), you need
  Entra rights to edit **External collaboration settings**, **cross-tenant access settings**, and
  **access reviews** — typically **Security Administrator** / **Identity Governance Administrator** /
  **External Identity Provider Administrator**, with **Global Administrator** only where genuinely
  required.
- **Why:** The controls span Teams admin center **and** Entra Identity Governance — a Teams-only role
  cannot configure reviews or cross-tenant settings.
- **Verify:** Confirm the assigned roles in the M365 admin center / Entra roles.
- **Implement if missing:** Have a Global Admin assign least-privilege roles for the specific tasks
  under change control.

## 6. An approved external-collaboration policy (from governance)

- **Description:** A written decision from your security/compliance/governance stakeholders: which
  domains are **allowed vs blocked**, whether **shared channels** are permitted (and to which
  partners), the **guest review cadence** and **expiration** period, and which **sensitivity label**
  governs external sharing.
- **Why:** These are **policy determinations**, not technical ones — the solution configures whatever
  the policy says but does not decide it.
- **Verify:** A signed-off policy / allow-block list exists with named approvers.
- **Implement if missing:** Run the discovery script to produce the current-state posture, then work
  with governance to ratify the target before configuring anything.


---


# Global Requirements — Microsoft Teams Solutions

These requirements apply to **every** solution in the **Teams** category (Teams governance, meetings,
external access, Teams Phone, apps, Teams Rooms, and Teams security/compliance). Verify each before
starting a solution's implementation steps.

> **Vendor boundary (applies to every Teams solution).** The **Teams admin center**
> (admin.teams.microsoft.com), the **Microsoft 365 admin center**, the **MicrosoftTeams PowerShell
> module**, and **Microsoft Graph** are authored at exact, current click-by-click / cmdlet detail from
> Microsoft's public documentation. Where a capability, policy, or portal path is **plan- or
> version-dependent** (Teams Phone licensing, Calling Plans vs Operator Connect vs Direct Routing,
> Premium features, Commercial vs Government cloud), it is **cited or flagged "verify in your tenant"**
> — never invented. **Third-party devices and apps** (certified Teams Rooms hardware, SBCs, ISV apps)
> are integrated at the pattern level; their internals are deferred to the vendor's own docs. Automation
> is **PowerShell** (MicrosoftTeams module / Graph) — never with hardcoded credentials or secrets.

## 1. Microsoft 365 tenant with Microsoft Teams and appropriate licensing
- **Description:** A Microsoft 365 tenant with **Microsoft Teams** enabled and the licensing the
  capability requires (e.g. Teams Phone + a calling plan/Operator Connect for voice, Teams Premium for
  premium features, the appropriate E-plan for advanced compliance).
- **Why required:** All policy, voice, app, and compliance configuration depends on the right plan.
- **How to verify:** In the M365 admin center confirm the Teams subscription and relevant add-ons.
- **How to implement if missing:** Assign/purchase the required licensing before starting.

## 2. Administrative access (least-privilege Teams roles)
- **Description:** Access with the least-privilege role the solution names — typically **Teams
  Administrator** (or Teams Communications/Device Administrator), with **Global Administrator** only
  where genuinely required.
- **Why required:** Teams policy, voice, app, and org-wide settings require the corresponding role.
- **How to verify:** Confirm the role in the M365 admin center / Entra roles.
- **How to implement if missing:** Have a Global Admin assign the least-privilege role under change control.

## 3. Microsoft Teams PowerShell + Graph toolchain
- **Description:** A workstation with the **MicrosoftTeams** PowerShell module (and Graph PowerShell
  where used), modern-auth / MFA-capable admin sign-in.
- **Why required:** Configuration, automation, and the provided scripts run through Teams PowerShell / Graph.
- **How to verify:** `Connect-MicrosoftTeams` succeeds; `Get-Module MicrosoftTeams`.
- **How to implement if missing:** `Install-Module MicrosoftTeams`; confirm modern-auth sign-in.

## 4. Identity, groups & lifecycle source of truth
- **Description:** A defined identity/group source (Entra ID groups, and where used **Microsoft 365
  Groups** which back teams) and the **lifecycle** stance (creation, naming, expiration/retention) the
  org expects.
- **Why required:** Teams are backed by M365 Groups; governance, provisioning, and access key off
  groups and the lifecycle model.
- **How to verify:** Confirm which groups/OU model is authoritative and the lifecycle expectations.
- **How to implement if missing:** Define the group/lifecycle model before configuring governance.

## 5. A pilot scope and change control
- **Description:** A **pilot team / policy group / user set** to validate on before org-wide rollout,
  and a **change-control** process for production policy/voice/compliance changes.
- **Why required:** Every solution follows an **Assess → Design → Configure → Pilot → Validate → Expand**
  model; policy and voice changes are high-impact.
- **How to verify:** Confirm a named pilot scope and an approval/change window are available.
- **How to implement if missing:** Create a pilot scope and agree change control before production changes.

## 6. Security, compliance & governance stakeholders
- **Description:** Engagement with the **security, compliance/records, and collaboration-governance**
  stakeholders whose policies the configuration must satisfy (external access, information barriers,
  retention, DLP, app governance).
- **Why required:** Collaboration governance and compliance settings must align to enterprise policy.
- **How to verify:** Confirm the applicable policies and named approvers.
- **How to implement if missing:** Identify the owners and capture requirements before configuring governance.

*The deployment model across every Teams solution is the same: **Assess → Design → Configure → Pilot →
Validate → Expand**, with explicit pass/fail gates and a documented rollback for production changes.
Automation is delivered as **PowerShell** (MicrosoftTeams module / Graph) — never with hardcoded
credentials or secrets in code.*


---


# Implementation

Follow these steps in order. They implement the house model — **Assess → Design → Configure → Pilot →
Validate → Expand** — for the three external-collaboration surfaces plus lifecycle and sensitivity.
Every artifact is **named** and reused verbatim later. **Default to dry-run** (`-WhatIf`) and apply
only with an explicit `-Commit`. External access, cross-tenant settings, and guest lifecycle are
**tenant-wide, high-impact** — do not skip the pilot or the rollback plan.

> **Cloud note:** portal URLs below are **commercial** (`admin.teams.microsoft.com`,
> `entra.microsoft.com`, `purview.microsoft.com`). Government clouds differ (e.g. `*.office365.us`,
> GCC-High) — **verify the correct URL in your tenant** before you start.

---

## Stage 1 — Assess (read-only)

1. **Capture current posture.** Run the discovery script (no changes made):

   ```powershell
   .\Get-TeamsExternalGuestPosture.ps1 -OutputPath .\posture-baseline.json
   ```

   It records: federation configuration (allowed/blocked domains, open-federation state), external
   access policies, Teams guest configuration (meeting/messaging/calling), channels policy
   (shared-channel switches), cross-tenant access **Default** + partner settings, the guest count, and
   a **stale-guest assessment** (guests with no recent sign-in).

2. **Baseline the guests.** Run the exposure report to a CSV you can hand to governance:

   ```powershell
   .\Get-TeamsExternalExposureReport.ps1 -InactiveDays 90 -OutputPath .\external-exposure.csv
   ```

3. **Record** the baseline artifacts (`posture-baseline.json`, `external-exposure.csv`) as the
   pre-change state for the rollback plan.

## Stage 2 — Design (decisions, no changes)

4. With security/compliance/governance, ratify the **external-collaboration policy** (Requirement 6):
   - **Allowed vs blocked domains** for external access (federation).
   - **Guest domains** allowed/denied (Entra external collaboration settings).
   - **Shared channels**: on/off, and which partner tenants (`Cross-Tenant Partner – Partner-A – Pilot`).
   - **Guest review cadence** (e.g. quarterly) and **expiration** period.
   - The **sensitivity label** that governs external sharing (`Sensitivity Label – Ext-Collab – Prod`).
5. Define the **pilot scope**: a named policy group (e.g. `Ext-Governance-Pilot`) of pilot users and a
   pilot team, plus the change window and rollback owner.

## Stage 3 — Configure (pilot-first)

> Configure and assign to the **pilot** first. Do not change tenant-wide (org-wide) policy until the
> pilot passes Stage 5.

### 3a. External access (federation) — allow/block domains

6. **Teams admin center → Users → External access.** Choose the federation posture per policy:
   *Allow only specific external domains* (recommended) or *Block specific domains*. Add the approved
   domains.
7. Equivalent PowerShell (allow-list example):

   ```powershell
   Connect-MicrosoftTeams
   # Allow only approved partner domains (replace with your ratified list)
   Set-CsTenantFederationConfiguration `
     -AllowedDomains (New-CsEdgeAllowList -AllowedDomain `
        (New-CsEdgeDomainPattern -Domain "contoso.com")) `
     -AllowFederatedUsers $true `
     -AllowPublicUsers $false            # consumer Teams/Skype off unless policy allows
   ```

   > `AllowedDomains` and `BlockedDomains` are **mutually exclusive** models — an allow-list ignores the
   block-list. Confirm which model your policy chose.

8. **Per-user external access policy** — create the named policy and assign to the pilot group:

   ```powershell
   New-CsExternalAccessPolicy -Identity "External Access Policy – Pilot" `
     -EnableFederationAccess $true -EnablePublicCloudAccess $false
   Grant-CsExternalAccessPolicy -PolicyName "External Access Policy – Pilot" -Identity pilotuser@contoso.com
   ```

### 3b. Guest access — Teams + Entra external collaboration

9. **Turn guest access on (or confirm) in Teams.** Teams admin center → **Users → Guest access** →
   *Allow guest access* = On. PowerShell master toggle plus the guest sub-configs:

   ```powershell
   Set-CsTeamsClientConfiguration -Identity Global -AllowGuestUser $true
   Set-CsTeamsGuestMeetingConfiguration  -AllowIPVideo $true -ScreenSharingMode EntireScreen
   Set-CsTeamsGuestMessagingConfiguration -AllowUserEditMessage $true -AllowUserDeleteMessage $true
   Set-CsTeamsGuestCallingConfiguration  -AllowPrivateCalling $true
   ```

   *(Set the sub-config values to your policy; the point is they are governed, not defaulted.)*

10. **Scope which domains can be invited as guests.** Entra admin center → **External Identities →
    External collaboration settings → Collaboration restrictions** → *Allow/Deny specified domains*;
    add the approved list. Also set **"Guest invite restrictions"** to the least-privilege option your
    policy allows (e.g. only admins and users in specific roles can invite).

    > The guest domain allow/deny list and `allowInvitesFrom` are Entra settings, **not** Teams
    > settings — configuring Teams guest access does **not** restrict guest domains. Set both.

### 3c. Shared channels — B2B direct connect

11. **Cross-tenant access settings.** Entra → **External Identities → Cross-tenant access settings**.
    In **Organizational settings**, add the partner tenant (`Cross-Tenant Partner – Partner-A – Pilot`)
    and enable **B2B direct connect** inbound/outbound per policy. Leave the **Default** policy's direct
    connect **blocked** unless policy is to allow all — direct connect should be a deliberate
    per-partner decision.

    ```powershell
    # (Microsoft.Graph.Identity.SignIns) inspect before changing
    Get-MgPolicyCrossTenantAccessPolicyDefault
    Get-MgPolicyCrossTenantAccessPolicyPartner
    ```

    > Both tenants must allow direct connect for a shared channel to work — coordinate with the partner.

12. **Teams channels policy.** Create the named policy controlling shared-channel creation and
    participation, and assign to the pilot:

    ```powershell
    New-CsTeamsChannelsPolicy -Identity "Teams Channels Policy – SharedCh-Pilot" `
      -AllowSharedChannelCreation $true `
      -AllowChannelSharingToExternalUser $true `
      -AllowUserToParticipateInExternalSharedChannel $true
    Grant-CsTeamsChannelsPolicy -PolicyName "Teams Channels Policy – SharedCh-Pilot" -Identity pilotuser@contoso.com
    ```

### 3d. Sensitivity (label-driven external posture)

13. **Purview portal → Information Protection → Labels.** On the container label
    `Sensitivity Label – Ext-Collab – Prod` (Groups & sites scope), set **external sharing** and
    **guest access** to the policy value (e.g. a "Confidential – Internal" label blocks guest access;
    a "Partner" label allows specific external sharing). Publish it to the pilot group in a label
    policy. *(Requires container labels enabled — see Requirement 4; verify licensing.)*

### 3e. Guest lifecycle — access review + expiration

14. **Entra → Identity Governance → Access reviews → New access review.** Create
    `Guest Access Review – Recert – Pilot`:
    - **Scope:** Guest users (`userType eq 'Guest'`) in the pilot team / group.
    - **Recurrence:** per policy (e.g. quarterly).
    - **Reviewers:** team/group owners (self-review or owner-review per policy).
    - **Auto-apply results:** **remove access if not approved** (this is the expiration mechanism).

    PowerShell helper (dry-run by default; requires Entra ID Governance/P2 — verify licensing):

    ```powershell
    .\New-GuestAccessReview.ps1 -GroupId <pilot-group-id> -ReviewName "Guest Access Review – Recert – Pilot" `
      -RecurrenceType quarterly -AutoApplyRemove -WhatIf
    # add -Commit to create it
    ```

## Stage 4 — Pilot

15. Apply everything above to the **pilot group / pilot team only**. Invite a test guest from an
    **allowed** domain and (separately) attempt one from a **blocked** domain. Establish a shared
    channel with `Cross-Tenant Partner – Partner-A – Pilot`.

## Stage 5 — Validate (pass/fail gates)

16. Run the baseline validation and the exposure report:

    ```powershell
    .\Test-TeamsExternalGuestBaseline.ps1 -BaselinePath .\target-baseline.json
    .\Get-TeamsExternalExposureReport.ps1 -InactiveDays 90 -OutputPath .\external-exposure-postpilot.csv
    ```

    **Gates — all must pass before Expand:**
    - **External scoped to policy** — federation allows only approved domains; blocked domain is refused.
    - **Guests scoped** — invite from an allowed domain succeeds; a denied domain is rejected.
    - **Shared channels controlled** — direct connect works only for the named partner; Default is blocked.
    - **Stale guests reviewed** — `Guest Access Review – Recert – Pilot` is active and auto-remove is on.
    - **Sensitivity applied** (if licensed) — the pilot team carries the label and its external posture.

## Stage 6 — Expand (with rollback)

17. When all gates pass, widen assignment: change the federation model tenant-wide (if the pilot proved
    the allow-list), grant `External Access Policy – Pilot` / `Teams Channels Policy – SharedCh-Pilot`
    (or their production equivalents renamed `– Prod`) to the broader population, and set the access
    review scope to **All guests**.
18. **Rollback plan (documented):** to revert, reapply the `posture-baseline.json` values with the
    config script (`-Commit`), remove the named policies (`Remove-CsExternalAccessPolicy`,
    `Remove-CsTeamsChannelsPolicy`), set cross-tenant partner direct connect back to blocked, and stop
    the access review. Because every change is a named policy or a captured setting, rollback is
    deterministic — never a blanket "turn external access off".


---


# Testing & Validation

Run every test on the **pilot** scope first. Each has an explicit **pass/fail**. Re-run after Expand
to confirm production posture. Use the named artifacts from the implementation verbatim.

---

## Test 1 — External access is scoped to approved domains

- **How:** From a pilot user, start a chat with someone at an **allowed** domain (e.g. `contoso.com`),
  then attempt one at a **blocked/unlisted** domain. Confirm config with:
  ```powershell
  Get-CsTenantFederationConfiguration | Select AllowedDomains, BlockedDomains, AllowFederatedUsers, AllowPublicUsers
  Get-CsExternalAccessPolicy -Identity "External Access Policy – Pilot"
  ```
- **Pass:** Chat to the allowed domain connects; the unlisted domain is refused ("cannot send
  messages"). `AllowedDomains` contains only the ratified list; `AllowPublicUsers` matches policy.
- **Fail:** Any non-approved domain federates, or an approved domain is blocked.

## Test 2 — Guest invite domain restrictions enforced

- **How:** As a pilot inviter, invite a guest from an **allowed** domain and (separately) a **denied**
  domain into the pilot team. Confirm the Entra setting:
  ```powershell
  Get-MgPolicyAuthorizationPolicy | Select AllowInvitesFrom
  ```
- **Pass:** Allowed-domain invite succeeds and the guest appears as `userType = Guest`; denied-domain
  invite is blocked at invitation time. `AllowInvitesFrom` matches the ratified restriction.
- **Fail:** A denied domain can be invited, or invitations are open to everyone against policy.

## Test 3 — Guest access sub-configuration matches policy

- **How:**
  ```powershell
  Get-CsTeamsClientConfiguration | Select AllowGuestUser
  Get-CsTeamsGuestMeetingConfiguration; Get-CsTeamsGuestMessagingConfiguration; Get-CsTeamsGuestCallingConfiguration
  ```
- **Pass:** `AllowGuestUser` and each guest sub-config equal the designed values.
- **Fail:** Any value drifts from the design (e.g. private calling on when policy says off).

## Test 4 — Shared channels controlled by cross-tenant access + channels policy

- **How:** Share a channel with `Cross-Tenant Partner – Partner-A – Pilot`; attempt a share to a tenant
  **not** configured for direct connect. Confirm:
  ```powershell
  Get-MgPolicyCrossTenantAccessPolicyDefault
  Get-MgPolicyCrossTenantAccessPolicyPartner
  Get-CsTeamsChannelsPolicy -Identity "Teams Channels Policy – SharedCh-Pilot"
  ```
- **Pass:** Share to the named partner works; share to an unconfigured tenant fails (Default direct
  connect blocked); the channels policy switches match the design.
- **Fail:** A shared channel forms with an unconfigured tenant, or the named partner cannot connect.

## Test 5 — Guest access review + expiration is active

- **How:** Confirm the review exists and auto-removal is configured:
  ```powershell
  Get-MgIdentityGovernanceAccessReviewDefinition -Filter "displayName eq 'Guest Access Review – Recert – Pilot'"
  ```
  *(Requires Entra ID Governance/P2 — verify licensing.)*
- **Pass:** `Guest Access Review – Recert – Pilot` is **active**, scoped to guests, recurring, with
  **auto-apply → remove access if not approved**.
- **Fail:** No active review, wrong scope, or auto-apply disabled (stale guests would persist).

## Test 6 — Stale guests are surfaced and actioned

- **How:**
  ```powershell
  .\Get-TeamsExternalExposureReport.ps1 -InactiveDays 90 -OutputPath .\exposure-test.csv
  ```
- **Pass:** The report lists guests inactive ≥ threshold; every stale guest is either inside the active
  review's scope or on the documented manual-removal runbook.
- **Fail:** Stale guests exist with no review coverage and no removal plan.

## Test 7 — Sensitivity label drives external posture (if licensed)

- **How:** Apply `Sensitivity Label – Ext-Collab – Prod` to the pilot team and confirm the team/group's
  external-sharing and guest posture follows the label.
- **Pass:** The label's external-sharing/guest setting takes effect on the container.
- **Fail:** The container's posture ignores the label, or labels are unpublished. *(If container labels
  aren't licensed, mark N/A and rely on Tests 1–6.)*

## Test 8 — Baseline validation is clean

- **How:**
  ```powershell
  .\Test-TeamsExternalGuestBaseline.ps1 -BaselinePath .\target-baseline.json
  ```
- **Pass:** The script reports **PASS** on every checked setting (federation model, guest config,
  channels policy, cross-tenant direct-connect defaults) with no drift from the target baseline.
- **Fail:** Any drift is reported — remediate with the config script before Expand.


---


# Troubleshooting

Common failure modes across the three external-collaboration surfaces, with resolutions. Use the named
artifacts from the implementation verbatim. Remember: **external access, guest access, and shared
channels are separate controls** — a symptom on one is usually caused by that surface's own setting, not
another's.

---

## External access (federation)

**Symptom: an approved partner domain still can't chat externally.**
- Confirm the **model**: `AllowedDomains` and `BlockedDomains` are mutually exclusive. If an allow-list
  is set, any domain not on it is blocked. `Get-CsTenantFederationConfiguration | Select AllowedDomains, BlockedDomains`.
- Confirm **`AllowFederatedUsers = $true`** and that the user has `External Access Policy – Pilot` with
  `EnableFederationAccess = $true`.
- Federation changes can take time to propagate; re-test after a delay. Also confirm the **partner
  tenant** allows federation to you — it is two-sided.

**Symptom: consumer (personal) Teams/Skype contacts can't connect.**
- That is **`AllowPublicUsers`**, separate from domain federation. It is intentionally **off** in the
  recommended posture — enable only if policy allows.

## Guest access

**Symptom: guest access toggle is on but invites from an allowed domain are rejected.**
- The **domain allow/deny list lives in Entra** (External Identities → External collaboration
  settings), **not** in Teams. Teams `AllowGuestUser` does not scope domains. Check
  `Get-MgPolicyAuthorizationPolicy | Select AllowInvitesFrom` and the collaboration-restrictions
  allow/deny list.
- Confirm the inviter has an **invite-eligible role** if guest-invite restrictions were tightened.

**Symptom: guest was invited but cannot see the team / channels.**
- Guest **directory** presence (Entra B2B) is different from **Teams** membership — confirm
  `AllowGuestUser = $true` (`Get-CsTeamsClientConfiguration`) and that the guest was added to the team,
  not just the directory. Guest experience can lag; sign out/in.

**Symptom: guest access was on yesterday, off today.**
- Check whether a **container sensitivity label** (`Sensitivity Label – Ext-Collab – Prod`) that blocks
  guest access was applied to that team — labels can override guest access at the container level. This
  is expected behavior when classification demands it.

## Shared channels (B2B direct connect)

**Symptom: sharing a channel to another tenant fails.**
- Shared channels use **B2B direct connect** in **cross-tenant access settings**, not guest access.
  Confirm the partner is added under **Organizational settings** with direct connect **inbound and
  outbound** allowed, and that the **Default** policy isn't blocking it.
  `Get-MgPolicyCrossTenantAccessPolicyPartner`, `Get-MgPolicyCrossTenantAccessPolicyDefault`.
- **Both tenants** must allow direct connect — verify the partner configured their side.
- Confirm the user has `Teams Channels Policy – SharedCh-Pilot` with
  `AllowChannelSharingToExternalUser = $true` and creation allowed.

**Symptom: users can't participate in a shared channel hosted by a partner.**
- That is `AllowUserToParticipateInExternalSharedChannel` on the channels policy — confirm it is `$true`
  for the affected users, and that **outbound** direct connect to that partner is allowed.

## Cross-tenant access settings

**Symptom: `Get-MgPolicyCrossTenantAccessPolicy*` cmdlets not found or throw.**
- Install/import **`Microsoft.Graph.Identity.SignIns`** and connect with `Connect-MgGraph -Scopes
  "Policy.Read.All"` (add `Policy.ReadWrite.CrossTenantAccess` to change). Verify the account has a
  cross-tenant-capable role.

## Guest lifecycle (access reviews / expiration)

**Symptom: `New-GuestAccessReview.ps1` reports access reviews unavailable.**
- Access reviews require **Microsoft Entra ID Governance / Entra ID P2** — **verify licensing in your
  tenant** (M365 admin center). If unlicensed, use the **stale-guest exposure report + a documented
  manual removal runbook** instead (the solution supports this fallback).
- Ensure `Connect-MgGraph -Scopes "AccessReview.ReadWrite.All"` and an Identity Governance Administrator
  role.

**Symptom: review runs but stale guests aren't removed.**
- Confirm **auto-apply is enabled** and the default decision is **Deny/remove** (the `-AutoApplyRemove`
  switch). Without auto-apply, decisions are recorded but not enforced.
- Confirm the **scope query** targets guests (`userType eq 'Guest'`) of the intended group.

## Sensitivity labels

**Symptom: container label doesn't change external sharing.**
- Confirm **container labels are enabled** (`Group.Unified` setting `EnableMIPLabels = true`) and the
  label is **published** to the target group in a label policy — creating a label is not enough.
- Label licensing is plan-dependent — **verify in your tenant**. If unlicensed, govern via the other
  three surfaces and mark this control N/A.

## Scripts & connectivity

**Symptom: a script prompts repeatedly or fails to connect.**
- All scripts use modern-auth `Connect-MicrosoftTeams` / `Connect-MgGraph` — there are **no stored
  credentials** by design. Sign in interactively (or with a managed identity in automation) with the
  least-privilege role for that step.
- `Set-TeamsExternalGuestConfig.ps1` and `New-GuestAccessReview.ps1` **make no changes without
  `-Commit`** — if you expected a change and saw a `[WHATIF]` line, re-run with `-Commit` in a change
  window.

**Symptom: `Test-TeamsExternalGuestBaseline.ps1` reports FAIL after a legitimate change.**
- The baseline is stale. Regenerate the target baseline from the new intended design (edit
  `Get-TeamsExternalGuestPosture.ps1` output) and re-validate. Drift reported against an old baseline is
  the tool working, not an error.

## Cloud differences

**Symptom: a portal URL 404s or a feature is missing.**
- You may be in a **Government cloud** (GCC / GCC-High / `*.office365.us`) where URLs and feature
  availability differ from commercial. **Verify the correct path and feature support for your cloud** —
  do not assume the commercial URL.


---


# Best Practices

Durable practices for keeping Teams external collaboration enabled **and** governed.

## Govern the three surfaces separately — never conflate them

- **External access (federation), guest access, and shared channels are different controls.** Locking
  one down does not govern the others. Review all three on every posture check; the discovery script
  reports them together for exactly this reason.
- Prefer an **allow-list** federation model (only approved domains) over an open-federation-with-blocks
  model for regulated or high-sensitivity tenants. Remember allow-list and block-list are mutually
  exclusive.

## Make external connections deliberate

- Keep the **cross-tenant access Default** conservative — **block B2B direct connect by default** and
  enable it **per named partner** (`Cross-Tenant Partner – <Partner> – <Stage>`). Shared channels
  should be a decision, not an accident.
- Set **guest-invite restrictions** to least privilege (specific roles), and scope **guest domains** in
  Entra external collaboration settings — do not rely on Teams guest toggles alone.

## Treat guests as time-limited by default

- Every guest should be covered by a **recurring access review** with **auto-remove** on non-approval —
  that is the expiration mechanism. Owner-review beats admin-review because owners know who still needs
  access.
- Run the **stale-guest exposure report** on a schedule even where reviews are licensed — it is the
  independent check that no guest slips past the review scope.
- Where Entra ID Governance/P2 is **not** licensed, replace automation with a **documented monthly
  manual removal runbook** driven by the exposure report — never "no lifecycle".

## Let classification drive control

- Use **container sensitivity labels** so a team's external-sharing/guest posture comes from its
  **label**, not per-team configuration drift. Name labels by intent
  (`Sensitivity Label – Ext-Collab – Prod`) and publish them, don't just create them.

## Change safely

- **Pilot first, always.** External/cross-tenant/lifecycle changes are tenant-wide and high-impact.
  Assign named policies to a pilot group, validate the pass/fail gates, then Expand.
- **Dry-run by default.** Run the config script with `-WhatIf`; apply only with `-Commit` inside a
  change window with a named rollback owner.
- **Capture a baseline before every change** (`posture-baseline.json`) so rollback is deterministic —
  reapply the captured values, don't improvise.

## Keep it least-privilege and secret-free

- Use least-privilege roles split across Teams admin (policies) and Entra Identity Governance
  (reviews/cross-tenant); reserve Global Admin for the rare step that needs it.
- **No stored credentials in automation.** Connect with modern-auth `Connect-MicrosoftTeams` /
  `Connect-MgGraph` interactively or via a managed identity — never hardcode secrets.

## Coordinate with the partner and with governance

- Shared channels / direct connect require **both tenants** to allow the connection — confirm the
  partner's side before troubleshooting your own.
- **Domain allow/block lists, permitted classifications, review cadence, and retention are policy
  determinations** owned by security/compliance/records — the technical controls implement them; keep
  the sign-off current when the policy changes.

## Cloud awareness

- Confirm the correct **portal URLs and feature availability for your cloud** (Commercial vs GCC /
  GCC-High / `*.office365.us`) before configuring — do not assume commercial paths. Flag anything
  plan- or cloud-dependent as **"verify in your tenant"** in your runbooks.


---


# Deliverables Summary

Everything included in this solution, on one page.

## Documentation

- **Solution Overview** — external access (federation) vs guest access vs shared channels (B2B direct
  connect), allow/block domains, guest lifecycle, sensitivity, and the deployment model.
- **Requirements Guide** — solution-specific prerequisites (Entra External ID/B2B, cross-tenant access
  settings, guest-lifecycle and sensitivity licensing, admin roles, and a governance-approved policy),
  building on the shared Teams category requirements.
- **Implementation Guide** — exact ordered steps: assess posture, design the policy, configure external
  access / guest / shared channels / cross-tenant settings / access reviews / sensitivity, pilot-first,
  with pass/fail gates and a documented rollback. Every artifact is named.
- **Testing & Validation** — eight tests, each with expected pass/fail, mapped to the validation gates.
- **Troubleshooting** — common failure modes across federation, guests, shared channels, cross-tenant
  settings, reviews, and sensitivity, with resolutions.
- **Best Practices** — durable practices for safe, governed external collaboration.
- **Executive Summary** — outcome, approach, and why the change is low-risk.

## PowerShell scripts (5)

All are **safe-by-default** (read-only or `-WhatIf`), use modern-auth `Connect-*` cmdlets, and contain
**no hardcoded credentials**.

1. **`Get-TeamsExternalGuestPosture.ps1`** — *Discovery / assessment (read-only).* Captures the full
   external-collaboration posture in one pass: federation configuration (allowed/blocked domains,
   open-federation state), external access policies, Teams guest configuration, channels policy
   (shared-channel switches), cross-tenant access **Default** + partner settings, guest count, and a
   **stale-guest assessment**. Writes a JSON baseline.

2. **`Set-TeamsExternalGuestConfig.ps1`** — *Configuration / remediation (`-WhatIf` by default).*
   Applies the designed external access / guest / shared-channel settings and creates the named
   policies (`External Access Policy – Pilot`, `Teams Channels Policy – SharedCh-Pilot`). Dry-runs
   unless `-Commit` is passed; supports reapplying a captured baseline for rollback.

3. **`New-GuestAccessReview.ps1`** — *Guest access-review + expiration helper (`-WhatIf` by default).*
   Creates a recurring Entra access review of guests (`Guest Access Review – Recert – Pilot`) with
   auto-remove on non-approval — the expiration mechanism. Reports existing reviews. Requires Entra ID
   Governance/P2 (verified at runtime).

4. **`Get-TeamsExternalExposureReport.ps1`** — *External-exposure report (read-only).* Enumerates
   guests and external-facing settings, flags guests inactive ≥ a threshold and those from
   non-approved domains, and exports a governance-ready CSV.

5. **`Test-TeamsExternalGuestBaseline.ps1`** — *Validation / scope-health helper (read-only).* Compares
   the live posture against a target baseline (federation model, guest config, channels policy,
   cross-tenant direct-connect defaults) and reports **PASS/FAIL** per setting — the automated form of
   the validation gates.
