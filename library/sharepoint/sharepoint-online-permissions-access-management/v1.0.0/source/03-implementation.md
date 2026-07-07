# 3. Implementation

Follow these steps in order. They implement the house model **Assess → Design → Configure → Pilot →
Validate → Expand**, pilot-first, with explicit **pass/fail gates** and a **rollback**. Every artifact is
named `<Purpose> – <Scope> – <Stage>` and reused verbatim in later steps, testing, troubleshooting, and
the scripts. Examples use `contoso.sharepoint.com` and a `Finance` site — **substitute your tenant and
real site names**; never invent an org.

> **Safety.** Every change is preceded by a read-only audit and runs **`-WhatIf` / dry-run by default**.
> Only an explicit `-Commit` writes. Do the whole cycle on **`Permission Scope – Pilot – Stage1`** before
> touching **`Permission Scope – Broad – Stage2`**.

---

## Stage A — Assess (read-only): baseline the permission posture

### A1. Connect with least privilege
1. Install/confirm the toolchain (Requirements 1–2): SharePoint Online Management Shell, PnP PowerShell,
   Graph PowerShell.
2. Connect read-only to a pilot site:
   ```powershell
   Connect-PnPOnline -Url https://contoso.sharepoint.com/sites/Finance -Interactive
   Get-PnPWeb | Select-Object Title, Url
   ```
3. For tenant-level reporting, also `Connect-SPOService -Url https://contoso-admin.sharepoint.com`
   (Government: `https://contoso-admin.sharepoint.us` — **verify your cloud**).

### A2. Run the discovery audit → `Permission Audit – SPO – Discovery`
1. Run **`SPOPERM-Discovery.ps1`** (read-only) against the pilot site(s). It inventories, per site:
   - **Broken inheritance** — every web/list/library/folder/item with `HasUniqueRoleAssignments = true`.
   - **Unique permissions** — the actual role assignments at each broken-inheritance scope.
   - **Direct user grants** — role assignments whose principal is a **User** (not a SharePoint/Entra
     group).
   - **Limited Access** — principals holding only the system-managed **Limited Access** level.
   - **Over-share signals** — broad principals (e.g. **Everyone**, **Everyone except external users**, the
     built-in **Members** group) granted **Edit/Full Control** at the site root.
   ```powershell
   .\SPOPERM-Discovery.ps1 -Url https://contoso.sharepoint.com/sites/Finance -CsvPath .\finance-audit.csv
   ```
2. Save the export as the baseline **`Permission Audit – SPO – Discovery`**. This is both the
   **before-state for rollback** and the **exception list** the site owner reviews.

**Gate A (pass/fail):** You have a complete audit export for every pilot site, and the site owner has
reviewed it and marked each unique-permission/direct-grant as **keep (documented exception)** or
**remediate**. **Fail** = no baseline or no owner sign-off → do not proceed.

---

## Stage B — Design: define the group + permission-level model

### B1. Author `Access Model – SPO – Design`
Document, for each in-scope site:
1. **The groups that back access** — the three SharePoint groups and what feeds them:
   - `SPO Group – Finance Owners – Prod` → **Full Control** (site owners only; keep tiny).
   - `SPO Group – Finance Members – Prod` → **Edit** (contributors) — membership fed by the Entra/M365
     group `M365 Group – Finance – Prod` where one exists.
   - `SPO Group – Finance Visitors – Prod` → **Read** (read-only consumers).
2. **The permission-level model** — standardize on built-in **Full Control / Edit / Contribute / Read**
   (see Overview). Define a custom level **`Perm Level – Read No Download – Prod`** *only* if a real
   view-only-no-download requirement exists. **Never edit built-in levels in place.**
3. **The unique-permission rule** — the default is **inherit**. A scope may keep unique permissions only
   if it is (a) documented in the design, (b) owner-approved, and (c) still group-based (a *group* granted
   at the scope, never an individual). Everything else is remediated to inherit.
4. **Scopes:** name the pilot **`Permission Scope – Pilot – Stage1`** and the broad rollout
   **`Permission Scope – Broad – Stage2`**.

**Gate B:** `Access Model – SPO – Design` is written and approved by the information owner and security
stakeholder. **Fail** = no approved model → do not configure.

---

## Stage C — Configure: stand up group-based access

### C1. Ensure the site's SharePoint groups exist and carry the standard levels
1. For an **M365-group-connected Team site**, the group already provides Owners/Members; confirm the
   SharePoint group associations and levels. For a **communication/classic site**, ensure the three
   SharePoint groups exist:
   ```powershell
   # Confirm the associated groups and their permission levels (read-only first)
   Get-PnPGroup | Select-Object Title, Id
   Get-PnPGroupPermissions -Identity "Finance Members"
   ```
2. Where a group is missing, create it and assign the standard level (dry-run first with the config
   script, then `-Commit`):
   ```powershell
   .\SPOPERM-Remediate-GroupAccess.ps1 -Url https://contoso.sharepoint.com/sites/Finance -EnsureGroups -WhatIf
   ```
3. If you defined a custom level, create **`Perm Level – Read No Download – Prod`** by copying **Read** and
   removing the download-related permissions in *Site permissions → Permission levels* (or via PnP role
   definition). **Verify the effective behavior in your tenant** before assigning it broadly.

### C2. Feed group membership from the Entra/M365 source of truth
1. Where an Entra/M365 group is authoritative, make it the membership of the SharePoint Members group
   (i.e. add `M365 Group – Finance – Prod` **as a member of** `SPO Group – Finance Members – Prod`, or use
   the M365 group directly for Team sites) so joins/leaves flow automatically.
2. Confirm no *individual users* are granted at the site root outside the three groups — those are the
   direct grants Stage D remediates.

**Gate C:** The three named groups exist with the correct standard levels, and members flow from the
governed group source where one exists. **Fail** = access still granted to individual users at the root →
fix before remediating sub-scopes.

---

## Stage D — Pilot remediation (`-WhatIf` first, then `-Commit`)

Do Stage D **only** on `Permission Scope – Pilot – Stage1`.

### D1. Convert direct user grants → group membership (`Group Access Remediation – <Site> – Remediation`)
1. **Dry-run** the conversion — for each direct user grant flagged in the audit, the script proposes the
   group the user should join (based on the granted level) and the direct grant it will remove:
   ```powershell
   .\SPOPERM-Remediate-GroupAccess.ps1 -Url https://contoso.sharepoint.com/sites/Finance `
       -ConvertDirectGrants -WhatIf
   ```
2. Review the proposal with the site owner. Where a direct grant maps to no legitimate group, the owner
   decides the correct group (or that the access should be removed entirely).
3. **Commit** the approved conversions:
   ```powershell
   .\SPOPERM-Remediate-GroupAccess.ps1 -Url https://contoso.sharepoint.com/sites/Finance `
       -ConvertDirectGrants -Commit
   ```
   This adds each user to the correct SharePoint group and removes the direct role assignment. Record it
   as **`Group Access Remediation – Finance – Remediation`**.

### D2. Reset broken inheritance → inherit (`Inheritance Reset – <Site> – Remediation`)
1. **Dry-run** the reset — the script lists every scope it would reset to inherit, **excluding** the
   documented exceptions from `Access Model – SPO – Design`:
   ```powershell
   .\SPOPERM-Reset-Inheritance.ps1 -Url https://contoso.sharepoint.com/sites/Finance `
       -ExcludeList .\documented-exceptions.csv -WhatIf
   ```
2. Confirm the list matches the audit and the owner's keep/remediate decisions.
3. **Commit** the resets:
   ```powershell
   .\SPOPERM-Reset-Inheritance.ps1 -Url https://contoso.sharepoint.com/sites/Finance `
       -ExcludeList .\documented-exceptions.csv -Commit
   ```
   Each reset calls the scope's `ResetRoleInheritance()`, re-inheriting site permissions and removing the
   unique grant (and any **Limited Access** it created). Record as **`Inheritance Reset – Finance –
   Remediation`**.

> **Rollback.** If a reset removes access someone genuinely needed, re-grant it *as a group* at the
> minimum necessary scope, or (last resort) re-break inheritance and re-add the documented grant, using
> the `Permission Audit – SPO – Discovery` baseline as the record of the prior state.

---

## Stage E — Validate the pilot

Run the validation script and the tests in **05-testing.md** against `Permission Scope – Pilot – Stage1`:
```powershell
.\SPOPERM-AccessReview.ps1 -Url https://contoso.sharepoint.com/sites/Finance -Report -CsvPath .\finance-access.csv
```
**Gate E (pass/fail):**
- Access at the site is **group-based** — no individual users granted directly at the root (system
  accounts excepted).
- **Broken inheritance count is reduced** to only the documented exceptions.
- **Limited Access sprawl is reduced** correspondingly (it disappears when the underlying unique grant is
  reset).
- **No over-share** — no broad principal holds Edit/Full Control at the root unintentionally.
- A **re-run audit** matches the intended end-state; the owner confirms no one lost needed access.

**Fail** any item → remediate or roll back before expanding.

---

## Stage F — Stand up access reviews, then expand

### F1. Wire the recurring review → `Access Review – <Site> – Prod`
- **If Entra ID P2 is licensed:** create a **Microsoft Entra ID Access Review** over the membership of
  `M365 Group – Finance – Prod` (and/or the site owners), recurring (e.g. quarterly), with the site owner
  as reviewer and "remove access if not reviewed" per the org's policy. Name it **`Access Review – Finance
  – Prod`**. *(Entra admin center → Identity Governance → Access reviews — verify the exact path in your
  tenant.)*
- **If SharePoint Advanced Management (SAM) is licensed:** additionally enable **site access review** and
  the **Data Access Governance** reports in the SharePoint admin center to catch over-sharing between
  reviews.
- **If neither add-on is licensed:** schedule the included **`SPOPERM-AccessReview.ps1 -Report`** on a
  recurring basis and route the export to the owner for attestation. Same evidence, no add-on.

### F2. Establish the recurring access report → `Access Report – SPO – Report`
- Schedule **`SPOPERM-AccessReview.ps1 -Report`** across in-scope sites to produce a repeatable
  who-has-access export, and (where SAM is licensed) supplement with the DAG reports. Store exports with
  the review records.

### F3. Expand to `Permission Scope – Broad – Stage2`
- Repeat Stages A–E per site (or in owner-approved batches) across the broad scope, always: fresh audit →
  owner review → `-WhatIf` → `-Commit` → validate. Never expand past a failed gate.

**Gate F:** A recurring review exists for each in-scope site (via P2 Access Reviews, SAM site review, or
the scheduled script), and the recurring `Access Report – SPO – Report` is running. **Fail** = no ongoing
attestation → the model will drift; close before declaring done.
