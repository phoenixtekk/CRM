# 3. Implementation Guide — Secure Microsoft 365 Copilot: Oversharing & SharePoint Permissions Remediation

Follow these steps **in order**. Discovery, validation, and reporting are automated with read-only
PowerShell (Microsoft Graph / PnP PowerShell); remediation is done in the **SharePoint admin center**
(`https://<tenant>-admin.sharepoint.com`) and the **SharePoint Online Management Shell**, and the bundled
remediation script defaults to a **safe preview (`-WhatIf`)** — no sharing changes without `-Commit`.
Every object you create follows the `<Purpose> – <Scope> – <Stage>` convention and is reused verbatim in
Testing, Troubleshooting, and the scripts.

> **Model:** confirm scope → discover the oversharing → agree the remediation with site owners →
> configure and **pilot** on a ring of sites → validate (including from the Copilot side) → expand under
> change control, remove interim controls, and record the evidence.
> Pattern: **Assess → Configure → Pilot → Validate → Expand.**
>
> **Portal-path caveat.** SharePoint admin and SAM blades evolve, and several controls (SAM, RCD, RSS) are
> licensing-gated. The paths below are the current map; if a blade or cmdlet differs in your tenant, use
> the closest documented equivalent and **confirm before acting** — never assume a path that is not
> present.

## Objects you will create (naming reference)
| Object | Name | Where |
|---|---|---|
| Oversharing inventory export | `Oversharing Discovery – Estate – Assess` | `CPLTSHARE-Discovery.ps1` |
| Site access-reduction list | `Site Access Reduction – Sites – Pilot` | `CPLTSHARE-Remediation.ps1` |
| Restricted Access Control lock | `Restricted Access Control – Broad Sites – Pilot` | SharePoint admin / SAM |
| Restricted Content Discovery scope | `Restricted Content Discovery – Sensitive Sites – Pilot` | SharePoint admin / SAM |
| Interim tenant search fence | `Restricted SharePoint Search – Tenant – Interim` | SPO Management Shell |
| Owner-led review | `Site Access Review – Broad Sites – Pilot` | SharePoint admin / SAM |
| Copilot-side verification | `Copilot Permission Verification – Pilot – Validate` | `CPLTSHARE-Validate.ps1` + manual |
| Before/after evidence | `Oversharing Remediation Report – Tenant – Expand` | `CPLTSHARE-Report.ps1` |
| Recurring cadence tag | `Oversharing Review – Tenant – Recurring` | scheduled script chain |

## Step 0 — Confirm scope, licensing, roles, and connections (Assess)
1. On the operator workstation, sign in for read-only work:
   - `Connect-MgGraph -Scopes "Sites.Read.All","Directory.Read.All"` (Microsoft Graph).
   - `Connect-PnPOnline -Url https://<tenant>-admin.sharepoint.com -Interactive` (PnP).
   - For later RSS steps: `Connect-SPOService -Url https://<tenant>-admin.sharepoint.com`.
2. Run `CPLTSHARE-Discovery.ps1 -ScopeOnly` (read-only). It confirms the sign-ins, reports which modules
   and which SAM signals are available, and confirms whether **auditing** is on (Requirements 2.2, 2.3,
   2.8). Note any capability absent so you scope around it.
3. Confirm the **in-scope estate and pilot ring** (Requirement 2.4) and the **change window**
   (Requirement 2.7) before any change.

**Pass/fail:** Sign-ins succeed, modules/SAM availability reported, pilot ring and change window agreed.
**Rollback:** None — read-only.

## Step 1 — Discover the oversharing (Assess)
1. Run `CPLTSHARE-Discovery.ps1` (read-only). It enumerates the in-scope SharePoint sites via Graph/PnP
   and surfaces the **oversharing signals** — **EEEU / org-wide grants**, **"Anyone" (anonymous) links**,
   broad company-wide sharing links, large-membership sites, and stale/guest access — writing
   `Oversharing Discovery – Estate – Assess` (CSV + JSON summary).
2. Where **SAM** is licensed, also open the SharePoint admin center → **Reports → Data access governance**
   and run the **Sharing links**, **Everyone Except External Users (EEEU)**, and **Sensitivity labels
   applied to files** reports. The DAG reports are the **authoritative tenant view**; reconcile them with
   the portable script export.
3. **Rank** the results: broadly-shared sites are the priority, especially those that also hold sensitive
   or unlabeled content (cross-read with the Copilot data-governance discovery if available).

**Pass/fail:** The export lists in-scope sites with their oversharing signal; the top targets can be
named. **Rollback:** None — read-only.

## Step 2 — Agree the remediation with site owners (Configure)
1. Produce the prioritized reduction list: run
   `CPLTSHARE-Remediation.ps1 -Action BuildList -Name "Site Access Reduction – Sites – Pilot"`
   (read-only). It turns `Oversharing Discovery – Estate – Assess` into a ranked, per-site action list
   (remove EEEU, revoke anonymous links, scope to a group, review guests) — it changes **nothing**.
2. Walk the list with the **site owners** (Requirement 2.5). For each pilot site, agree: the correct
   audience, which broad grants/links to remove, whether to lock the site with **RAC**, and whether it
   needs interim **RCD** fencing while cleanup proceeds.
3. **Record the decisions.** *Who should have access and what is "too broad" are the owners' data-owner
   determinations* — you implement and pilot the agreed changes; you do not decide access.

**Pass/fail:** The reduction list is produced and the per-site owner decisions are recorded.
**Rollback:** None — planning only.

## Step 3 — Pilot: reduce access on the ring (Configure → Pilot)
Apply only to the **pilot ring**; nothing tenant-wide is enforced.
1. **Preview first.** Run
   `CPLTSHARE-Remediation.ps1 -Action ReduceAccess -Name "Site Access Reduction – Sites – Pilot" -WhatIf`
   to review exactly which grants/links would be removed. Add `-Commit` only after owner sign-off.
2. **Remove broad grants and links** on each pilot site (under SharePoint Administrator): remove **EEEU**
   and org-wide grants; revoke **"Anyone"/anonymous** and over-broad **company** sharing links; remove
   stale guests/members. Do this via the script (`-Commit`) or the site's **Site permissions** and
   **Manage access** UI.
3. **Lock high-risk sites with RAC (where SAM is licensed).** In the SharePoint admin center → **Active
   sites** → select the site → **Settings** → **Restricted access control**, limit the site to a named
   security group. Name the configuration `Restricted Access Control – Broad Sites – Pilot`.
4. **Interim containment while you clean up.** For not-yet-remediated sensitive sites that must be fenced
   from Copilot immediately:
   - **RCD (per site, SAM):** SharePoint admin center → **Active sites** → site → enable **Restricted
     Content Discovery** (excludes the site's content from Copilot and org-wide search). Name it
     `Restricted Content Discovery – Sensitive Sites – Pilot`.
   - **RSS (tenant, interim):** in the SPO Management Shell,
     `Set-SPOTenantRestrictedSearchMode -Mode Enabled`, then
     `Add-SPOTenantRestrictedSearchAllowedListUrls -Urls "<allowed site URLs>"` to allow only cleaned
     sites. Record as `Restricted SharePoint Search – Tenant – Interim`. Treat RSS/RCD as **temporary
     stopgaps**, not the end state. *(SAM/RSS/RCD availability is tenant-dependent — verify.)*
5. **Kick off owner-led site access reviews (where SAM is licensed).** In the SharePoint admin center,
   start **site access reviews** for the broad sites so owners confirm/clean membership. Name the batch
   `Site Access Review – Broad Sites – Pilot`.

**Pass/fail:** Pilot-site broad grants/links removed (or previewed and owner-approved), RAC/RCD applied
where agreed, interim RSS recorded, access reviews started. **Rollback:** Restore prior sharing on any
site where a change broke legitimate access (the discovery export is the before-state); disable RCD on a
site; `Set-SPOTenantRestrictedSearchMode -Mode Disabled` to turn RSS off.

## Step 4 — Align sensitivity labels & DLP (Configure)
1. Confirm the **sensitivity-label** baseline (Requirement 2.6). Where high-risk pilot sites hold
   sensitive content, ensure the appropriate label (with **encryption/usage rights** where warranted) is
   applied — Copilot honors item-level encryption and will not surface content the user cannot decrypt.
2. Confirm any **DLP-for-Copilot** policy (built in the Copilot data-governance solution) covers the
   "keep out of Copilot" labels for this content. This solution **aligns** with that layer; it does not
   build it. Note label/DLP alignment as pending if that layer is not yet in place.

**Pass/fail:** Labels applied/aligned on high-risk pilot content; DLP-for-Copilot coverage confirmed or
noted pending. **Rollback:** Adjust label scope; no access change here.

## Step 5 — Validate the pilot, including from the Copilot side (Validate)
1. Run `CPLTSHARE-Validate.ps1` (read-only). It re-reads the oversharing signal for the pilot sites and
   confirms it is **lower** than the Step 1 baseline, that RAC/RCD/RSS are in the expected state, and that
   auditing is on. It writes `Copilot Permission Verification – Pilot – Validate`.
2. **Copilot-side check (manual, decisive).** As a **test user who should *not* have access** to a
   remediated site, open Microsoft 365 Copilot and prompt for content that used to be reachable (e.g.
   *"Summarize the <site> budget file"* or search for a known phrase). Copilot must **not** return that
   content. As a **legitimate user**, confirm expected content is **still** reachable (no collaboration
   broken). Record both outcomes against `Copilot Permission Verification – Pilot – Validate`.
   *(Copilot indexes on a cadence; allow time after a permission change before the negative test is
   reliable — see Troubleshooting.)*
3. Confirm with owners that nothing legitimate broke. See Testing (doc 5) for explicit gates.

**Pass/fail:** Oversharing reduced on re-measure; the test user can no longer surface remediated content;
legitimate access intact. **Rollback:** If a legitimate access broke, restore it and re-scope; do not
expand until the gate passes.

## Step 6 — Expand, remove interim controls, and record the evidence (Expand)
1. Only after the pilot gate passes: repeat Steps 3–5 for the **remaining waves** under change control,
   widening RAC and access reviews beyond the pilot ring.
2. **Remove interim controls once the underlying access is fixed:** disable **RSS**
   (`Set-SPOTenantRestrictedSearchMode -Mode Disabled`) and remove **RCD** on sites whose access is now
   correct — the goal is fixed access, not a permanent search fence.
3. Run `CPLTSHARE-Report.ps1` (read-only) to compile `Oversharing Remediation Report – Tenant – Expand` —
   the **before/after oversharing**, the controls applied and their state, and the residual risk — for
   stakeholder sign-off.
4. Stand up the recurring review: tag the cadence `Oversharing Review – Tenant – Recurring` and schedule
   the read-only `Discovery → Validate → Report` chain (e.g. monthly) so oversharing stays measured as
   sites, sharing, and Copilot usage change.

**Pass/fail:** Remediation expanded, interim controls removed, before/after report compiled and signed
off, recurring review scheduled. **Rollback:** Restore prior sharing on any site where broad enforcement
caused an issue; re-apply RSS/RCD containment if a wave must pause. The discovery and report exports are
the before-state to restore toward.
