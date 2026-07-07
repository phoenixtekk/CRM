# 3. Implementation — SharePoint Online External Sharing & Access Governance

Follow the house model: **Assess → Design → Configure → Pilot → Validate → Expand**, with explicit
pass/fail gates and a documented rollback. Tenant-wide sharing is **high-impact** — do not skip the
pilot/change-window discipline.

> **Naming:** every artifact you create is named `<Purpose> – <Scope> – <Stage>` per the Overview's
> reference model and reused verbatim in the admin centers, scripts, testing, and reports.
>
> **Connections used throughout:**
> - SPO Management Shell: `Connect-SPOService -Url https://<tenant>-admin.sharepoint.com`
>   (Government: your `.us` admin host — verify your cloud).
> - PnP: `Connect-PnPOnline -Url https://<tenant>.sharepoint.com/sites/<site> -Interactive`.
> - Graph: `Connect-MgGraph -Scopes "Sites.Read.All","User.Read.All"` (add
>   `AccessReview.ReadWrite.All` for reviews; `-Environment USGov`/`USGovDoD` on Gov clouds).
> - `contoso.com` / `fabrikam.com` are placeholder domains — substitute your real tenant and partner
>   domains.

---

## Stage 0 — Assess (read-only, changes nothing)

**Goal:** capture the current posture as `External Exposure – SPO – Discovery` and hand it to the
policy owner as the evidence for the sharing-policy decision.

1. **Connect and capture the tenant sharing posture.** In the SharePoint admin center go to
   **Policies → Sharing** to read the current external-sharing slider, default link settings, and
   expiration; then capture the same values in PowerShell for the record:
   ```powershell
   Connect-SPOService -Url https://contoso-admin.sharepoint.com
   Get-SPOTenant | Select-Object SharingCapability, OneDriveSharingCapability,
       DefaultSharingLinkType, DefaultLinkPermission,
       RequireAnonymousLinksExpireInDays, ExternalUserExpirationRequired, ExternalUserExpireInDays,
       SharingDomainRestrictionMode, SharingAllowedDomainList, SharingBlockedDomainList,
       PreventExternalUsersFromResharing, RequireAcceptingAccountMatchInvitedAccount
   ```
2. **Capture per-site sharing** for the sites in scope and the **external-user population**:
   ```powershell
   Get-SPOSite -Limit All -Detailed |
       Select-Object Url, SharingCapability, Title | Sort-Object Url
   Get-SPOExternalUser -PageSize 50   # external users who accepted invitations
   ```
3. **Run the discovery script** to produce the baseline CSV in one pass:
   `.\SPOEXT-Discovery.ps1 -CsvPath .\External-Exposure-Discovery.csv` (read-only). Save the output as
   **`External Exposure – SPO – Discovery`**.
4. **Review the SharePoint Data Access Governance (DAG) reports** in the admin center →
   **Reports → Data access governance** (e.g. **Sharing links**, **Everyone Except External Users
   (EEEU)**) for oversharing signals. *(DAG report availability is plan-dependent — verify in your
   tenant.)*

**Gate 0 (pass to proceed):** you have a saved discovery baseline (tenant + OneDrive + per-site
capability, link defaults, expiration, domain mode, guest population) and have reviewed the DAG signals.
**Fail:** if you cannot read `Get-SPOTenant`/`Get-SPOExternalUser`, fix Requirements 2.1–2.2 first.

---

## Stage 1 — Design (with the policy owner; no changes yet)

**Goal:** agree the values that the settings will encode. Record them in the policy document
(Requirement 2.5). Decide, with the security/compliance owner:

- **Tenant `SharingCapability`** — the approved level. The four values are:
  - `Disabled` — no external sharing.
  - `ExistingExternalUserSharingOnly` — only guests already in the directory.
  - `ExternalUserSharingOnly` — **New and existing guests** (sign-in / verification-code required).
  - `ExternalUserAndGuestSharing` — **Anyone** links allowed (unauthenticated) **plus** guests.
  A common governed target is **`ExternalUserSharingOnly`** (new + existing guests, no Anyone links).
- **`OneDriveSharingCapability`** — equal to or tighter than the tenant value.
- **`DefaultSharingLinkType`** = `Direct` (**Specific people**) and **`DefaultLinkPermission`** = `View`.
- **Anyone-link expiration** (`RequireAnonymousLinksExpireInDays`, e.g. `30`) — only relevant if Anyone
  is permitted; name it `Anyone Link Expiration – 30d – Prod`.
- **Guest-access expiration** (`ExternalUserExpireInDays`, e.g. `60`) — `Guest Expiration – 60d – Prod`.
- **Domain restriction** — `SharingDomainRestrictionMode` = `AllowList` with a partner allow-list
  (`Domain Allowlist – Partners – Prod`) **or** `BlockList` (`Domain Blocklist – Restricted – Prod`).
- **Confidential site tiers** — which sites get a tighter per-site `SharingCapability` and/or a
  sensitivity-label container control, named `Site Sharing – <SiteName> – Prod` /
  `Container Label – <Level> – Prod`.
- **Guest-review cadence** — quarterly is typical: `Access Review – Guests – Quarterly`.

**Gate 1:** a signed-off policy document with every value above and the approver named, plus the
`Sharing Scope – Pilot – Stage1` site/user list and a change window for the tenant-wide portions.

---

## Stage 2 — Configure & Pilot

> **Sequencing note.** Tenant `SharingCapability`, default link type, expiration, and domain mode are
> **tenant-wide** — they cannot be scoped to a pilot site. Therefore: **first** prove the *tighter
> site-level* and *link/expiration behavior* on the pilot sites (which you can scope), **then** apply
> the tenant-wide baseline in the agreed change window with the rollback ready. Do all writes with the
> config script's dry-run first.

### 2a. Pilot the per-site tightening (scoped, reversible)
1. **Record each pilot site's current `SharingCapability`** (for rollback) from Stage 0.
2. **Tighten a confidential pilot site** below the tenant default and set its link defaults:
   ```powershell
   $site = 'https://contoso.sharepoint.com/sites/Confidential-Pilot'
   Set-SPOSite -Identity $site -SharingCapability ExistingExternalUserSharingOnly
   Set-SPOSite -Identity $site -DefaultSharingLinkType Direct -DefaultLinkPermission View
   # Per-site Anyone-link expiration override (only if Anyone is allowed at that site):
   Set-SPOSite -Identity $site -OverrideTenantAnonymousLinkExpirationPolicy $true `
       -AnonymousLinkExpirationInDays 30
   ```
   Name this `Site Sharing – Confidential-Pilot – Prod`.
3. **Apply a per-site domain restriction** on the pilot site if the design calls for it:
   ```powershell
   Set-SPOSite -Identity $site -SharingDomainRestrictionMode AllowList `
       -SharingAllowedDomainList "fabrikam.com contoso-partner.com"
   ```
4. **Apply the sensitivity-label container control** (if in scope; label must be **published** —
   Requirement 2.6). Get the label GUID from the compliance owner / `Get-Label` (Purview PowerShell) and
   apply it:
   ```powershell
   Set-SPOSite -Identity $site -SensitivityLabel "<published-label-GUID>"
   ```
   Name this `Container Label – Confidential – Prod`. *(Container-label enforcement of external sharing
   is defined in the label by the compliance owner — you are applying it, not authoring it.)*
5. **Use the config script for the batch/dry-run path** so every write is previewed first:
   ```powershell
   .\SPOEXT-Set-Sharing.ps1 -SiteScope (Get-Content .\pilot-sites.txt) `
       -SiteSharingCapability ExistingExternalUserSharingOnly -WhatIf   # dry run
   .\SPOEXT-Set-Sharing.ps1 -SiteScope (Get-Content .\pilot-sites.txt) `
       -SiteSharingCapability ExistingExternalUserSharingOnly -Commit    # apply
   ```

**Gate 2a:** on the pilot site, a **new share** offers *Specific people / View* by default, an **Anyone
link** (if permitted) shows an expiration, an attempt to share to a **non-allowed domain is blocked**,
and the site's `SharingCapability` reads the tightened value. Rollback: `Set-SPOSite -Identity $site
-SharingCapability <original>` (and restore the original link defaults / domain mode).

### 2b. Apply the tenant baseline (change window)
Preview, then apply, `Tenant Sharing Baseline – SPO – Prod`. Do the dry run first:
```powershell
.\SPOEXT-Set-Sharing.ps1 -TenantBaseline -SharingCapability ExternalUserSharingOnly `
    -DefaultLinkType Direct -DefaultLinkPermission View `
    -AnonymousLinkExpireDays 30 -GuestExpireDays 60 `
    -DomainMode AllowList -DomainList "fabrikam.com contoso-partner.com" -WhatIf
```
The equivalent direct cmdlets (what the script runs on `-Commit`):
```powershell
Set-SPOTenant -SharingCapability ExternalUserSharingOnly
Set-SPOTenant -OneDriveSharingCapability ExistingExternalUserSharingOnly   # <= tenant
Set-SPOTenant -DefaultSharingLinkType Direct -DefaultLinkPermission View
Set-SPOTenant -RequireAnonymousLinksExpireInDays 30        # if Anyone permitted
Set-SPOTenant -ExternalUserExpirationRequired $true -ExternalUserExpireInDays 60
Set-SPOTenant -SharingDomainRestrictionMode AllowList `
    -SharingAllowedDomainList "fabrikam.com contoso-partner.com"
Set-SPOTenant -PreventExternalUsersFromResharing $true `
    -RequireAcceptingAccountMatchInvitedAccount $true
```
> **Order matters:** if you are **tightening** the tenant (e.g. removing Anyone), announce it — existing
> Anyone links of the now-disallowed type are **disabled**. Apply in the change window with the rollback
> (`Set-SPOTenant -SharingCapability <original>` plus the original link/expiration/domain values, all
> captured in Stage 0) staged and ready.

**Gate 2b:** `Get-SPOTenant` reflects every baseline value; a tenant-wide new-share defaults to
*Specific people / View*; sharing to a non-allowed domain is blocked tenant-wide; a newly invited guest
receives an expiration. **Fail → rollback** to the Stage 0 values and reconvene with the policy owner.

### 2c. Stand up guest access reviews
1. **In the Entra admin center → Identity Governance → Access reviews**, create a recurring review
   `Access Review – Guests – Quarterly` scoped to **Guest users** (and/or the membership of
   externally-shared M365 groups), with reviewers = group owners or the sponsoring managers, a
   **recurrence** of quarterly, and **auto-apply** of results (remove access if not approved / not
   responded per policy). *(Access Reviews require Entra ID P2 / ID Governance — Requirement 2.7.)*
2. **If Access Reviews are not licensed**, run the fallback: `.\SPOEXT-ExposureReport.ps1
   -IncludeGuests -CsvPath .\Guest-Review.csv` and route the CSV to owners for manual attestation. Flag
   the licensing gap to the policy owner.

**Gate 2c:** the recurring review exists (or the fallback CSV is produced and routed) and a first cycle
has an owner and a due date.

---

## Stage 3 — Validate

Run the validation script against the pilot and the tenant baseline:
```powershell
.\SPOEXT-Validation.ps1 -SiteScope (Get-Content .\pilot-sites.txt) `
    -ExpectSharingCapability ExternalUserSharingOnly `
    -ExpectDefaultLinkType Direct -ExpectDefaultLinkPermission View `
    -ExpectDomainMode AllowList
```
It returns PASS/FAIL per check. Then run `.\SPOEXT-ExposureReport.ps1 -SiteScope (Get-Content
.\pilot-sites.txt) -CsvPath .\External-Exposure-Report.csv` to produce `External Exposure – SPO –
Report` and confirm the exposure inventory matches expectations (no unexpected Anyone-links, external
principals only on trusted domains). Full procedures are in **05-testing.md**.

**Gate 3:** every validation check PASSes and the exposure report shows no out-of-policy sharing. Any
FAIL is remediated (or rolled back) before Expand.

---

## Stage 4 — Expand

1. **Widen the site-level tightening** from `Sharing Scope – Pilot – Stage1` to `Sharing Scope – Broad
   – Stage2` in tranches, running the config script in **dry-run then commit** per tranche and
   re-validating after each:
   ```powershell
   .\SPOEXT-Set-Sharing.ps1 -SiteScope (Get-Content .\wave2-sites.txt) `
       -SiteSharingCapability ExistingExternalUserSharingOnly -WhatIf
   ```
2. **Schedule the recurring exposure report** (`External Exposure – SPO – Report`) and confirm the
   **`Access Review – Guests – Quarterly`** recurrence is active.
3. **Hand over** the policy document, the discovery baseline, the validation output, and the report
   cadence to operations. Keep the Stage 0 values retained as the standing rollback reference.

**Gate 4 (done):** the tenant baseline and all in-scope site tiers match policy, guest reviews recur,
the exposure report runs on a cadence, and the rollback values are archived.

---

## Rollback summary (keep ready at every stage)
| Change | Rollback |
|---|---|
| Tenant `SharingCapability` tightened | `Set-SPOTenant -SharingCapability <Stage-0 value>` (existing links of a re-allowed type do **not** auto-restore) |
| Default link type/permission | `Set-SPOTenant -DefaultSharingLinkType <orig> -DefaultLinkPermission <orig>` |
| Anyone/guest expiration | Restore original `RequireAnonymousLinksExpireInDays` / `ExternalUserExpireInDays` (or `ExternalUserExpirationRequired $false`) |
| Domain mode/list | `Set-SPOTenant -SharingDomainRestrictionMode None` (or restore original mode + lists) |
| Per-site tightening | `Set-SPOSite -Identity <url> -SharingCapability <orig>` + original link/domain values |
| Sensitivity label applied | Re-apply the prior label or clear per the compliance owner's guidance |
