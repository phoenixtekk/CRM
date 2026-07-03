# 1. Solution Overview — Entra ID Governance (PIM, Access Reviews & Entitlement Management) — Government (GCC High)

> This is the **Government (GCC High)** edition. It deploys the same Entra ID Governance model as the
> Commercial edition, but on the **US sovereign cloud**: the admin portals, sign-in endpoints, and
> Microsoft Graph endpoints are the `*.us` sovereign URLs, and a few capabilities lag or differ from
> Commercial. Configure a GCC High tenant with these steps — not with Commercial steps that silently
> authenticate against the wrong cloud.

## What Entra ID Governance is
Microsoft Entra ID Governance is the set of Entra identity-governance capabilities that make access
least, time-bound, and provable. Three services do the work: Privileged Identity Management (PIM)
turns admin roles into just-in-time, approval-gated grants; access reviews recertify who should keep
roles, group membership, and application access; and entitlement management packages access into
catalogs and access packages that are granted by policy and expire. Together they replace always-on
admin and never-reviewed access with a governed, auditable model.

This is Entra directory-level governance across the whole tenant. It is distinct from Intune
role-based access control, which governs only who can administer Intune; the two are complementary
and do not overlap.

## How it works
1. Privileged Identity Management makes a directory role (for example `Global Administrator`) eligible rather than active. A person holds no standing power; they activate the role for a limited window when they need it.
2. Activation can require approval, multi-factor authentication, a justification, and a ticket number, and it raises alerts on risky activity. Activation is time-bound and expires automatically.
3. Access reviews ask a reviewer (the resource owner, a manager, or the users themselves) to recertify access on a schedule; anything not approved is removed, so stale access decays automatically.
4. Entitlement management groups related resources (groups, apps, SharePoint sites) into a catalog, then publishes access packages with a policy that governs who may request them, who approves, and when access expires.
5. Break-glass emergency accounts are deliberately excluded from PIM so a PIM misconfiguration can never lock every administrator out of the tenant.
6. Every activation, review decision, and access-package grant is logged, giving an auditor a provable trail of who had access to what, and why.

## Commercial vs GCC High — what's different
The governance model is identical; the **cloud plane it runs on is not**. In GCC High:

- **You sign in and administer at sovereign `*.us` portals**, not the Commercial `*.com` portals. The Commercial portals will not recognize a GCC High account. (See the Requirements Guide for the full endpoint table.)
  - Microsoft Entra admin center: **`https://entra.microsoft.us`** (Commercial: `entra.microsoft.com`).
  - Azure portal: **`https://portal.azure.us`** (Commercial: `portal.azure.com`).
  - Sign-in / authentication: **`https://login.microsoftonline.us`** (Commercial: `login.microsoftonline.com`).
  - Microsoft Graph: **`https://graph.microsoft.us`** for GCC High, **`https://dod-graph.microsoft.us`** for DoD (Commercial: `graph.microsoft.com`). Source: Microsoft Learn, *Microsoft Graph national cloud deployments*.
- **Scripts must target US Gov Graph.** Every `Connect-MgGraph` call in this solution uses **`-Environment USGov`**; without it the SDK authenticates against the Commercial endpoint and fails against a GCC High tenant. All five scripts in this package default to `-Environment USGov`.
- **Licensing uses the Government SKUs.** PIM, access reviews, and entitlement management require **Microsoft Entra ID P2** or **Microsoft Entra ID Governance**. In the US Government clouds the governance capability ships as **"Microsoft Entra ID Governance for Government"** and **"Microsoft Entra ID Governance Add-on for Microsoft Entra ID P2 for Government,"** which Microsoft documents as available in GCC, GCC High, and DoD. Source: Microsoft Learn, *Microsoft Entra ID Governance licensing fundamentals*.
- **Core governance is GA in US Gov.** Microsoft's *Entra feature availability in Azure for US Government* lists **Access reviews, Entitlement management, Privileged Identity Management (PIM), and Lifecycle workflows (in Entra ID Governance)** as available. The core deployment in this solution is fully supported.
- **Some adjacent capabilities lag, are partial, or differ** — call these out and verify against the current sovereign docs before relying on them:
  - **HR-driven provisioning** is listed as **Partial** for US Gov.
  - **My Staff** (delegated user management portal) is listed as **not available** (❌) for US Gov.
  - **Graph Explorer** (the browser tool at `developer.microsoft.com/graph`) is **not supported** for the `graph.microsoft.us`/DoD endpoints — use PowerShell (`-Environment USGov`) rather than Graph Explorer.
  - **Cross-tenant / cross-cloud collaboration** (connected organizations spanning Commercial ↔ US Gov, cross-cloud synchronization) behaves differently across clouds and parts remain **preview**; Microsoft notes cross-cloud sync in GCC High is delivered under the *Entra ID Governance for Government* SKU. **Verify for GCC High** before designing external-guest access packages that cross a cloud boundary.
  - **Preview / ML-assisted features** (for example machine-learning access-review recommendations, catalog access reviews, and other capabilities marked Preview in the licensing table) may reach the sovereign clouds later than Commercial — **verify for GCC High** at the time you deploy rather than assuming Commercial parity.

> Where this document says **"verify for GCC High,"** treat the capability as unconfirmed for the
> sovereign cloud: check the current Microsoft US Gov documentation (or the Microsoft 365 US
> Government service descriptions) before you depend on it. Never assume Commercial parity for a
> preview or external-collaboration feature.

## What you can control
- PIM role assignment as eligible vs active, activation maximum duration, and permanent-vs-time-bound assignment expiry.
- Activation requirements: approval, approver list, multi-factor authentication, justification, and ticket information.
- Access reviews for directory roles (via PIM), for groups and application assignments, and for access-package assignments — with a recurrence, reviewer, and auto-apply of results.
- Entitlement-management catalogs, access packages, request/approval policies, and access expiry or periodic review.
- PIM alerts (for example, too many Global Administrators, or admins with standing assignments) and their thresholds.

## Benefits
- Least privilege — admins hold roles eligibly and activate only when needed, shrinking standing attack surface.
- Time-bound — activations and access-package grants expire automatically, so access does not accumulate.
- Provable — activations, approvals, and review decisions are logged for audit and compliance (supports CMMC / NIST 800-171 least-privilege and review objectives common to GCC High tenants).
- Self-service with control — users request access packages; policy decides who approves and when it expires.
- Automatic decay of stale access — access reviews remove what is no longer approved without manual cleanup.
- Sovereign-correct — configured on the `*.us` plane so a government tenant is governed in-cloud, not against Commercial endpoints.

## Limitations (be honest with buyers)
- Entra ID Governance / P2 (Government SKUs) licensing is required for PIM, access reviews, and entitlement management; confirm licensing before you begin (see requirements).
- PIM governs Entra directory roles, PIM-enabled groups, and Azure resource roles — not Intune RBAC and not on-premises Active Directory admin rights.
- Over-tight approval or too few approvers can delay legitimate activations; approver coverage must be planned.
- Break-glass accounts are intentionally outside PIM and must instead be protected by strong stored credentials, exclusion documentation, and sign-in monitoring.
- GCC High parity gaps apply to adjacent/preview/external-collaboration features (see *Commercial vs GCC High* above and `gcc-high-parity-notes.md`) — verify before relying on them.

## The standard deployment model
> Onboard privileged roles to PIM as eligible with approval and alerts -> stand up access reviews for
> roles and app access -> build entitlement-management access packages with policy and expiry ->
> validate activation and recertification on a pilot scope -> expand to the tenant.
> pattern: Assess -> Configure -> Pilot -> Validate -> Expand.
