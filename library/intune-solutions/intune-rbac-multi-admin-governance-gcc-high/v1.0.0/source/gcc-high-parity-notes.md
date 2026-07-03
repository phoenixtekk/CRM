# GCC High Parity Notes — Intune Administrative Governance (RBAC & Multi-Admin Approval)

This reference records what is (and isn't) the same in **GCC High / DoD** versus Commercial for this
solution, with sources. Where Microsoft does not state something explicitly, the item is flagged
**[verify for GCC High]** — nothing here is invented.

## 1. Which cloud this edition targets
Microsoft runs Intune as **two** service instances:
- **Commercial service** — used by Commercial customers **and GCC** (state/local government uses the
  same commercial instance; there is no separate GCC instance for Intune).
- **Government cloud** — **GCC High** and **DoD**, a physically separate datacenter built on Microsoft
  Azure Government (Impact Levels IL4/IL5).

So in Microsoft's Intune docs, "GCC" = the commercial service, while "GCC High"/"DoD" = the sovereign
government cloud. **This edition targets GCC High / DoD** (the `*.us` sovereign cloud).
*Source: "Microsoft Intune Government Service overview," Microsoft Learn.*

## 2. Admin portals and endpoints (this is the biggest practical difference)
| Purpose | Commercial | GCC High |
|---|---|---|
| Intune admin center | `intune.microsoft.com` / `endpoint.microsoft.com` | `intune.microsoft.us` / `endpoint.microsoft.us` |
| Entra admin center | `entra.microsoft.com` | `entra.microsoft.us` |
| Microsoft 365 admin | `admin.microsoft.com` | `portal.office365.us/adminportal/` |
| Azure portal | `portal.azure.com` | `portal.azure.us` |
| Sign-in authority | `login.microsoftonline.com` | `login.microsoftonline.us` |
| Microsoft Graph | `graph.microsoft.com` (`-Environment Global`) | `graph.microsoft.us` (`-Environment USGov`) |
| Company Portal (web) | `portal.manage.microsoft.com` | `portal.manage.microsoft.us` |

Notes: SSL/TLS inspection is **not supported** on `*.manage.microsoft.us`; some tasks require
unauthenticated proxy access to `manage.microsoft.us`. The DoD Graph host is
`dod-graph.microsoft.us` (still reached via `-Environment USGovDoD` in Graph PowerShell, or `USGov`
for GCC High).
*Sources: "Network endpoints for US government deployments," Microsoft Learn; "Microsoft Graph
national cloud deployments," Microsoft Learn; Microsoft government-cloud portal URL references.*

## 3. Microsoft Graph PowerShell in GCC High
Add `-Environment USGov` to **every** `Connect-MgGraph` call (or `-Environment USGovDoD` for DoD).
Built-in environments:
- Global — `login.microsoftonline.com` / `graph.microsoft.com`
- **USGov** — `login.microsoftonline.us` / `graph.microsoft.us` (GCC High)
- **USGovDoD** — `login.microsoftonline.us` / `dod-graph.microsoft.us` (DoD)

Without `-Environment USGov`, the module authenticates against the Commercial endpoint and GCC High
credentials fail with what looks like an auth error but is really the wrong cloud. All five scripts in
this solution set `-Environment USGov` by default.
*Source: "Connect-MgGraph (Microsoft.Graph.Authentication)" and "Get-MgEnvironment," Microsoft Learn.*

## 4. RBAC, scope tags, role assignments
RBAC (built-in/custom roles, permissions, scope tags, role assignments) is part of Intune's
**standard MDM feature set**, which Microsoft lists as available in GCC High and DoD ("You can use app
policies, device configuration profiles, compliance policies, and more"). Scope tags and role
assignments are core RBAC and are used the same way in the sovereign portals.
*Status: available in GCC High.* Microsoft does not enumerate scope tags as a separate line item in
the government service description, so confirm behaviour on your tenant — **[verify for GCC High]**.
*Source: "Microsoft Intune Government Service overview," Microsoft Learn (Supported features → Standard
MDM features).*

## 5. Multi-Admin Approval (access policies / `operationApprovalPolicies`)
Multi Admin Approval is documented under Intune **fundamentals / RBAC** (not called out separately in
the government service description). Because Intune's RBAC/fundamentals surface is served from the
shared government instance and the `operationApprovalPolicies` Graph resource is not listed among the
GCC High "not available" or "planned" features, MAA is expected to be present in GCC High.
**Treat as available but [verify for GCC High] on your tenant** before committing a design — Microsoft
has not published a GCC-High-specific MAA statement.
Protected resource types (Commercial, and the target for GCC High verification): Apps, Compliance
policies, Configuration policies (settings catalog), Device actions (wipe/retire/delete), Role-based
access control, Scripts (Windows), Tenant Configuration (device categories). Changes to access
policies themselves are always protected.
*Sources: "Use Multi Admin Approval in Intune," Microsoft Learn; "Microsoft Intune Government Service
overview," Microsoft Learn (features not-available / planned tables — MAA is not listed as excluded).*

## 6. Confirmed gaps that affect this solution
- **Change Review Agent / Security Copilot in MAA — NOT available.** The Commercial MAA experience can
  surface Change Review Agent (Security Copilot) approval suggestions for Windows PowerShell script
  requests. **Microsoft Security Copilot is listed as not-yet-supported in GCC High/DoD**, so this
  Copilot-assisted approval column does not appear — approvals in GCC High are **fully manual**.
  *Source: government service overview (Security Copilot under "planned / not available"); MAA doc
  (Change Review Agent section).*
- **Remote Help — NOT yet available** in GCC High/DoD (planned). Adjacent to admin governance; do not
  design around it in a GCC High tenant.
- **Cloud PKI — NOT yet available (GCC High)**, **Windows Autopilot (classic) — not available** in
  GCC High/DoD. Not required by this solution but commonly assumed from Commercial guidance; do not
  carry those assumptions over.
*Source: "Microsoft Intune Government Service overview," Microsoft Learn (planned / not-available
tables).*

## 7. Behaviour that is the same in both clouds (from the MAA doc)
These MAA behaviours are cloud-independent and apply in GCC High:
- Requires at least two admin accounts; an admin **cannot approve their own** request (including
  Global/Intune Administrators).
- Approver group **must be a security group** and **must be added to an Intune role assignment as a
  member group**, or members are periodically removed. Approvers also need resource-specific Read.
- Intune sends **no notifications**; requests **expire in 3 days** if not completed; status history is
  visible up to 30 days.
- A **Role**-type access policy can deadlock RBAC (it gates the RBAC changes MAA itself needs) —
  configure it last.
- All actions on a protected resource (Create/Edit/Modify/Delete/Assign) are gated; audit logs record
  requests and approvals.
*Source: "Use Multi Admin Approval in Intune," Microsoft Learn.*

## 8. How to verify on your own tenant
Run `RBACGOVG-Discovery.ps1` (it connects with `-Environment USGov`). If
`/beta/deviceManagement/operationApprovalPolicies` returns without error and the **Multi Admin
Approval** node is present under Tenant administration in `intune.microsoft.us`, MAA is available on
your GCC High tenant. If the node or Graph resource is absent, open a Microsoft support case rather
than assuming Commercial parity.

---
### Sources
- Microsoft Learn — *Microsoft Intune Government Service overview*:
  `https://learn.microsoft.com/intune/fundamentals/government-service`
- Microsoft Learn — *Use Multi Admin Approval in Intune*:
  `https://learn.microsoft.com/intune/fundamentals/role-based-access-control/multi-admin-approval`
- Microsoft Learn — *Network endpoints for US government deployments*:
  `https://learn.microsoft.com/intune/intune-service/fundamentals/intune-us-government-endpoints`
- Microsoft Learn — *Microsoft Graph national cloud deployments*:
  `https://learn.microsoft.com/graph/deployments`
- Microsoft Learn — *Connect-MgGraph* / *Get-MgEnvironment* (Microsoft.Graph.Authentication)
- Microsoft government-cloud portal URL references (GCC High `*.us` portal list)

*Last researched: 2026-07 (as of Microsoft Learn government-service page dated 2026-06-04). GCC High
feature availability changes over time — re-verify before each engagement.*
