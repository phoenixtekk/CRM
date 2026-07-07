# 2. Requirements Guide — Microsoft 365 Purview eDiscovery Administration

Verify **every** requirement before running a matter. Each entry: **Description · Why · Verify ·
Implement-if-missing.** This solution has no shared category-requirements file — all prerequisites
are below.

## 2.1 Microsoft 365 + eDiscovery licensing
**Description:** Licensing that covers the tier you will use. **Content Search** and **eDiscovery
(Standard)** cases and holds are available in most enterprise plans (for example Microsoft 365 E3);
**eDiscovery (Premium)** — custodians, review sets, analytics/de-duplication, and structured export —
requires **Microsoft 365 E5** (or the **E5 eDiscovery and Audit** add-on), and custodians placed on
Premium hold each need an eligible license.
**Why:** Premium features simply do not appear without the plan; running a matter that needs review
sets/analytics on E3 licensing will fail at collection.
**Verify:** Microsoft 365 admin center → **Billing → Licenses**; and open
`https://purview.microsoft.com` → **eDiscovery** — if you cannot create custodians/review sets, you
are on Standard only. Run `MSEDISC-Discovery.ps1` (reports which case types/holds exist). **Plan
names and gating change — verify in your tenant.**
**Implement:** Assign E5 / E5 eDiscovery and Audit to the eDiscovery operators and to custodians who
will be placed on a Premium custodian hold.

## 2.2 eDiscovery roles (least privilege)
**Description:** Operators hold the **eDiscovery Manager** role group (run searches, manage their own
cases); a small number hold **eDiscovery Administrator** (see all cases, manage holds, act on any
matter). Within eDiscovery Manager, distinguish **Manager** members (own cases only) from
**Administrator** members.
**Why:** eDiscovery is powerful — it can read anyone's mail and files. Grant it narrowly through the
role groups, **not** through Global Administrator.
**Verify:** `https://purview.microsoft.com` → **Settings → Roles & scopes → Permissions →
Microsoft Purview solutions → eDiscovery Manager**; or PowerShell `Get-RoleGroupMember "eDiscovery
Manager"` / `Get-RoleGroupMember "eDiscovery Administrator"`. Run `MSEDISC-Discovery.ps1`.
**Implement:** Add operators to **eDiscovery Manager**; add the lead(s) as **eDiscovery
Administrator**. Remove any standing Global Admin use for matters.

## 2.3 Audit logging enabled
**Description:** The Microsoft Purview **unified audit log** is turned on so case, search, hold, and
export activity is recorded.
**Why:** The audit trail is the *evidence of defensibility* — it proves the hold was placed, the
search run, and the export completed. Legal will ask for it.
**Verify:** Purview → **Audit** — a search returns results. Run `MSEDISC-Report.ps1` (surfaces
eDiscovery-related audit activity).
**Implement:** Turn on auditing in the **Audit** solution; allow time for events to populate.

## 2.4 In-scope workloads identified
**Description:** A written list of which workloads the matter must cover — Exchange mailboxes,
SharePoint sites, OneDrive accounts, and Teams (chats/channels/files) — and any that are explicitly
out of scope.
**Why:** Search locations and hold locations are chosen from these; missing a workload (e.g.
forgetting that Teams chat lives in mailboxes) makes the collection incomplete.
**Verify:** A scope note exists naming custodians and their mailboxes/sites/OneDrive/Teams.
**Implement:** Work with legal to enumerate custodians and map each to their Exchange mailbox,
OneDrive URL, SharePoint sites, and Teams membership.

## 2.5 Legal/records stakeholder and scope determination
**Description:** A named legal, compliance, or records owner who **decides** the matter scope —
custodians, date range, keywords, what must be held, and what is produced.
**Why:** Scope, hold, and production are **legal determinations**, not IT defaults. IT executes and
evidences them; IT does not decide them.
**Verify:** A matter intake record exists with a named legal owner, scope, and a hold instruction.
**Implement:** Establish a matter-intake step: legal signs off scope and hold before configuration
begins.

## 2.6 PowerShell modules and connectivity
**Description:** The **ExchangeOnlineManagement** module (provides Security & Compliance PowerShell,
`Connect-IPPSSession`) for Content Search/Standard automation, and — for Premium automation — the
**Microsoft.Graph.Security** module (Microsoft Graph eDiscovery API).
**Why:** The scripts in this solution use Security & Compliance PowerShell for Content Search, cases,
and holds; Premium custodian/review-set/export automation is via Microsoft Graph. Exact Graph cmdlet
parameters are version-dependent — **verify in your tenant**.
**Verify:** `Get-Module -ListAvailable ExchangeOnlineManagement, Microsoft.Graph.Security`;
`Connect-IPPSSession` succeeds with modern auth (MFA).
**Implement:** `Install-Module ExchangeOnlineManagement -Scope CurrentUser` and
`Install-Module Microsoft.Graph.Security -Scope CurrentUser`. Use modern auth only — **no stored
credentials or app secrets in scripts.**

## 2.7 Pilot matter (non-sensitive)
**Description:** A safe, non-sensitive **pilot matter** and a willing pilot custodian (for example an
IT test account) used to walk the full case → search → hold → review → export flow before touching a
real matter.
**Why:** Holds and exports are high-impact; the pattern is proven on `eDiscovery Case – Matter-A –
Pilot` first, then applied to live matters.
**Verify:** A pilot custodian account and a scratch matter name exist.
**Implement:** Nominate a pilot custodian (seed some test mail/files/Teams messages) and reserve the
name `Matter-A`.

## 2.8 Compliance boundary decision (if required)
**Description:** A decision on whether eDiscovery must be **scoped** so a given eDiscovery team can
only search a subset of the org (for example by region or agency), enforced with a **compliance
security filter**.
**Why:** In multi-region/multi-agency tenants, allowing every eDiscovery Manager to search everyone
may violate policy; the boundary must be defined *before* matters run.
**Verify:** A written boundary policy exists (which team may search which population). PowerShell
`Get-ComplianceSecurityFilter` shows configured filters.
**Implement:** With legal/HR, define the boundary; create filters with `MSEDISC-Scope.ps1`
(`New-ComplianceSecurityFilter`). The *policy* is a legal/HR determination; the script only
implements it.

## 2.9 Change control + rollback for holds and exports
**Description:** A documented change-control and rollback process for placing/removing a hold and for
running an export.
**Why:** A broad hold affects preservation across many mailboxes/sites and an export moves potentially
sensitive content; both need an approver, a pilot gate, and a defined rollback.
**Verify:** A change ticket exists with approver, pilot scope, and rollback (remove the case-hold
rule/policy; delete the review set/export). 
**Implement:** Record the change, name the pilot matter, define the rollback, and get legal approval
before placing a live hold or running a live export.

---
## Checklist
- [ ] eDiscovery licensing confirmed (Standard vs **Premium/E5**) — `MSEDISC-Discovery.ps1` — *verify in tenant*
- [ ] Roles assigned: **eDiscovery Manager** (+ **eDiscovery Administrator** lead), no Global Admin for matters
- [ ] Unified audit log enabled — `MSEDISC-Report.ps1`
- [ ] In-scope workloads mapped per custodian (Exchange / SharePoint / OneDrive / Teams)
- [ ] Named legal/records owner + scope & hold determination on record
- [ ] Modules installed (`ExchangeOnlineManagement`, `Microsoft.Graph.Security`); modern auth works
- [ ] Pilot matter `Matter-A` + pilot custodian ready
- [ ] Compliance-boundary decision made (filters via `MSEDISC-Scope.ps1` if required)
- [ ] Change control + rollback for holds and exports
