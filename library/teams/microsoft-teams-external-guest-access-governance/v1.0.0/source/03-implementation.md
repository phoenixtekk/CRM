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
