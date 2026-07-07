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
