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
