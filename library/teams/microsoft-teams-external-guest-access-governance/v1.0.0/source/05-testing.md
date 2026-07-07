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
