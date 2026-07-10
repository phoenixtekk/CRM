# 6. Troubleshooting — Secure Microsoft 365 Copilot: Oversharing & SharePoint Permissions Remediation

Common failures, their cause, and the fix. Symptoms map to the implementation steps.

## Discovery returns no sites / partial results
- **Symptom:** `CPLTSHARE-Discovery.ps1` writes an empty or short `Oversharing Discovery – Estate – Assess`.
- **Cause:** Missing read scope, wrong sign-in, or site enumeration returning nothing for the account.
- **Fix:** Reconnect with `Connect-MgGraph -Scopes "Sites.Read.All","Directory.Read.All"` and/or
  `Connect-PnPOnline`. Confirm the account can read the sites. Fall back to the SharePoint admin center
  **Active sites** export as the site list and re-run.

## Permission read is unavailable for a site
- **Symptom:** Sites appear with a "permission read unavailable / needs higher scope" note.
- **Cause:** The discovery identity lacks rights to read that site's permissions.
- **Fix:** This is expected in read-only discovery. Use the SharePoint admin **Data Access Governance**
  reports (SAM) as the authoritative view, or elevate the discovery identity's read rights for the
  in-scope sites.

## Data Access Governance / RAC / RCD blades are missing
- **Symptom:** No **Reports → Data access governance**, **Restricted access control**, or **Restricted
  Content Discovery** in the SharePoint admin center.
- **Cause:** **SharePoint Advanced Management (SAM)** is not licensed/enabled, or the feature has moved.
  *(SAM is a paid add-on and its surface evolves — verify.)*
- **Fix:** Acquire/enable SAM, or proceed with **manual sharing cleanup** plus interim **RSS** and note
  the SAM controls as pending. The scripts degrade gracefully when SAM is absent.

## Removed the grant, but Copilot still surfaces the content
- **Symptom:** After remediation, the test user can still get the content via Copilot or search.
- **Cause 1 — indexing latency:** Copilot/search re-indexes on a cadence; the change has not propagated
  yet. **Fix:** Wait the re-index window and re-test; record the test time.
- **Cause 2 — access still exists via another path:** A different broad link, a group membership, or a
  parent-site grant still applies. **Fix:** Re-run `CPLTSHARE-Discovery.ps1` on that site, check **Manage
  access** for every path, and remove the remaining grant/link.
- **Cause 3 — content cached in a prior response/history:** **Fix:** Confirm against a fresh prompt; prior
  chat history is not new access. Apply interim **RCD/RSS** if immediate fencing is required.

## Restricted SharePoint Search broke legitimate search/Copilot
- **Symptom:** After enabling RSS, users can't find sites they should.
- **Cause:** RSS blocks everything **not** on the allow-list (max 100 sites); a needed site was omitted.
- **Fix:** Add the site with `Add-SPOTenantRestrictedSearchAllowedListUrls -Urls "<url>"`, or disable RSS
  with `Set-SPOTenantRestrictedSearchMode -Mode Disabled`. Remember RSS is an **interim** stopgap — remove
  it once real access is fixed.

## Remediation broke legitimate collaboration
- **Symptom:** After `-Commit`, legitimate users lost access to a pilot site.
- **Cause:** A grant that was actually needed was removed (audience mis-scoped with the owner).
- **Fix:** Restore from the before-state (`Oversharing Discovery – Estate – Assess` and the site's version
  history / re-grant), re-scope with the owner, and re-run the `-WhatIf` preview before re-committing.

## `-WhatIf` shows a change you didn't approve
- **Symptom:** The remediation preview would touch a site or grant not on the approved list.
- **Cause:** The reduction list included a site/grant beyond the owner-approved set.
- **Fix:** Correct `Site Access Reduction – Sites – Pilot` to match the recorded owner decisions; never
  `-Commit` a change that wasn't approved.

## SPO Management Shell RSS cmdlets not recognized
- **Symptom:** `Set-SPOTenantRestrictedSearchMode` / `Add-SPOTenantRestrictedSearchAllowedListUrls` error
  as not found.
- **Cause:** Old `Microsoft.Online.SharePoint.PowerShell` module, or the tenant lacks the feature.
- **Fix:** `Update-Module Microsoft.Online.SharePoint.PowerShell`; reconnect with `Connect-SPOService`.
  If still absent, RSS may not be available in your tenant *(verify)* — use per-site RCD instead.

## Validation shows oversharing unchanged after remediation
- **Symptom:** `CPLTSHARE-Validate.ps1` reports the pilot signal at or near baseline.
- **Cause:** The `-Commit` step wasn't run, targeted the wrong sites, or the discovery cache is stale.
- **Fix:** Confirm remediation actually committed to the pilot sites; re-run discovery/validation; verify
  the pilot-site scope matches between the remediation and validation runs.

## Auditing / verification data missing
- **Symptom:** No Copilot interaction or sharing-change events for the verification record.
- **Cause:** Unified audit logging was off or recently enabled (backfill delay).
- **Fix:** Enable auditing (Purview **Audit**), allow time for events to populate, then re-run the
  verification and `CPLTSHARE-Report.ps1`.
