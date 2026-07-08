# 3. Implementation Guide — Implementing Microsoft Purview: Foundation, Roles & Onboarding

Follow these steps **in order**. Assessment and baseline come from the **Microsoft Purview portal**
(purview.microsoft.com), the **Microsoft 365 admin center**, **Security & Compliance PowerShell**
(`Connect-IPPSSession`), **Exchange Online PowerShell** (`Connect-ExchangeOnline`, for the audit
cmdlets), and **Microsoft Graph**. Role changes are previewed with `-WhatIf` before `-Commit`. Artifact
names follow the `<Purpose> – Purview – <Stage>` convention from the Overview and are reused verbatim.

> **Model:** Assess the tenant, design the least-privilege role/RBAC model, configure roles + core
> services + workload connections, validate on a **pilot ring**, confirm every gate, then hand off to
> the capability solutions. Pattern: **Assess → Design → Configure → Pilot → Validate → Expand.**
>
> **Portal paths are cited as of authoring and the Purview portal is evolving — verify each path in your
> own tenant.** Capability availability is licensing-dependent — verify against your plan (Requirement
> 2.1). This foundation enables plumbing only; DLP/label/retention/insider-risk *policies* are piloted
> in simulation/test in their own solutions.

## Step 1 — Assess the tenant (Assess)
1. Open the **Microsoft Purview portal** (`https://purview.microsoft.com`) and orient: the left rail
   lists the capabilities (Information Protection, Data Loss Prevention, Data Lifecycle Management,
   Records Management, Insider Risk Management, Communication Compliance, Audit, eDiscovery, Data Map /
   Unified Catalog, DSPM). Confirm which appear — visibility tracks your licensing.
2. Run `PURVIMP-Assess-Readiness.ps1 -CsvPath .\PurviewReadiness.csv`. Read-only, it captures:
   compliance SKUs present (E3/E5/E5 Compliance), the existing role groups and their members, the
   unified-audit-log status, and connectivity to S&C PowerShell + Graph. It writes
   `Purview Readiness – Foundation – Assess`.
3. Record which capabilities your licensing unlocks and which are out-of-scope for now. **Pass/fail:**
   you can state, per capability, "available on this plan" or "not licensed — deferred."

## Step 2 — Design the least-privilege role matrix (Design)
1. Using the readiness output and the role model in the Overview, build the **role assignment matrix**
   `Purview Role Matrix – Design`: for each function (compliance admin, classification data,
   information protection, records, insider risk, eDiscovery, audit, classification visibility,
   communication compliance) list the built-in role group and the **named** members (individuals or
   security groups).
2. Apply separation of duties: **Insider Risk Management**, **Communication Compliance**, and
   **eDiscovery Manager** membership is minimal, named, and kept **separate** from general compliance
   administration. Membership determinations for these sensitive roles are **confirmed with HR, privacy,
   and legal** — you implement the assignment, they make the call.
3. Reserve **Global Administrator** for only the two one-time setup actions (enabling the unified audit
   log, consenting Graph scopes). **Pass/fail:** every function maps to a least-privilege role group and
   named members; no capability relies on blanket Global Admin.

## Step 3 — Preview and apply role groups (Configure, pilot-first)
1. Dry-run first: `PURVIMP-Set-RoleGroups.ps1 -MatrixPath .\Purview-Role-Matrix.csv -WhatIf`. With
   `-WhatIf` (the default) it makes **no changes** — it prints exactly which member would be added to
   which role group and flags any built-in group that does not yet exist in your tenant.
2. Read every line against `Purview Role Matrix – Design`. Confirm no unintended broad grant and that
   the sensitive-role rows match the HR/legal-approved list.
3. Apply to the **pilot ring first**: run with `-Commit` scoped to the `Purview Pilot Ring – Stage1`
   admins, using `Add-RoleGroupMember` under the hood. Only create a **custom** role group
   (`New-RoleGroup`) where you need tighter scoping than a built-in group provides.
4. **Pass/fail + rollback:** `Get-RoleGroupMember` returns exactly the intended pilot members. Rollback
   is `Remove-RoleGroupMember` for any member added in error (the script prints the exact reverse
   command for each add).

## Step 4 — Enable the core data services (Configure)
1. Check status read-only: `PURVIMP-Enable-CoreServices.ps1`. It reports
   `UnifiedAuditLogIngestionEnabled`, audit retention posture, and whether the **Content Explorer
   Content Viewer** / **Content Explorer List Viewer** role groups exist and have members.
2. If the unified audit log is off, enable it (one-time, Global Admin):
   `PURVIMP-Enable-CoreServices.ps1 -Commit` → wraps
   `Set-AdminAuditLogConfig -UnifiedAuditLogIngestionEnabled $true`. Ingestion can take up to ~24 hours
   to begin surfacing results — enable it **early**.
3. Assign the Content/Activity Explorer viewer roles (Step 3 covers the mechanism) to the reviewers in
   the matrix, so `Data classification → Content explorer` and `→ Activity explorer` render for them
   (verify path). Writes/updates `Purview Core Services – Enablement`.
4. **Pass/fail:** audit ingestion reports `True`; the Explorer viewer role groups have the intended
   members; Content/Activity Explorer load for a viewer.

## Step 5 — Connect and confirm the in-scope workloads (Configure)
1. Run `PURVIMP-Scope-Config.ps1 -CsvPath .\PurviewScope.csv`. Read-only, it confirms the M365 workloads
   (Exchange, SharePoint, OneDrive, Teams) are present and reports **endpoint device onboarding**
   readiness from the Purview device-onboarding surface. It writes `Purview Workload Scope – Map`.
2. For endpoints, record onboarding **readiness** (whether devices are onboarded to Purview for future
   endpoint DLP) — actual tenant-wide device onboarding is executed in the endpoint-DLP solution, not
   here. Confirm the in-scope workload list with stakeholders.
3. **Pass/fail:** the scope map lists every in-scope workload with a connected/onboarded/ready status;
   any gap (e.g. endpoints not yet onboarded) is recorded as a hand-off item.

## Step 6 — Baseline Compliance Manager (Configure)
1. Open Purview portal → **Compliance Manager**. Note the current **compliance score** and the default
   **data protection baseline** assessment (verify the assessment name/availability against your
   licensing). Export the assessment: `Assessments → Export`.
2. Run `PURVIMP-Report-ComplianceBaseline.ps1 -CsvPath .\PurviewBaseline.csv -ComplianceScore <score>`
   to capture the supporting compliance signals — **Secure Score** (Graph `security/secureScores`),
   unified-audit status, and the role-group posture — alongside the portal score you supply. It writes
   `Purview Compliance Baseline – Report`.
3. Store the exported assessment plus the snapshot as your baseline. **Determinations about which
   regulations/assessments apply are the compliance team's** — you capture the baseline, they own the
   target. **Pass/fail:** a dated baseline (score + assessment export + signal snapshot) is stored.

## Step 7 — Validate the foundation on the pilot ring (Pilot → Validate)
1. Re-run `PURVIMP-Assess-Readiness.ps1` and confirm the role groups now resolve to the intended pilot
   members and the audit log reports enabled.
2. Have each pilot admin confirm they can perform exactly their function and **not** more (e.g. an
   eDiscovery manager cannot administer insider risk) — separation of duties holds.
3. Confirm Content/Activity Explorer render, audit search returns recent activity, and Compliance
   Manager shows the captured baseline. Complete the **Testing Guide** before expanding. **Pass/fail:**
   all Testing-Guide gates pass on the ring.

## Step 8 — Expand to the capability solutions (Expand)
1. With the foundation validated, broaden role-group membership from the pilot ring to the full named
   set (dry-run `-WhatIf`, then `-Commit`), and confirm audit/Explorer/baseline remain healthy.
2. Hand off to the dedicated Purview capability solutions — **sensitivity & retention labels, DLP,
   data lifecycle & records management, insider risk, communication compliance, audit
   standard/premium investigations, DSPM, and data governance (data map / catalog)** — each of which
   configures its capability on this foundation and pilots high-impact policies in
   simulation/test/disabled mode first. This solution deliberately **does not** duplicate that work.

---
### Order of operations
`Assess tenant → Design role matrix → Dry-run (-WhatIf) roles → Apply roles to pilot ring → Enable core
services (audit + Explorer roles) → Confirm workload scope → Baseline Compliance Manager → Validate on
ring → Expand membership + hand off to capability solutions`
