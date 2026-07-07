# Troubleshooting

Common failure modes and how to resolve them. Reuse the named artifacts from the implementation
guide when checking. All checks are read-only unless a fix is explicitly a change.

---

## Connect / authentication

### `Connect-PnPOnline` fails with "AADSTS… application not found" or a consent error
- **Cause:** since September 2024 PnP PowerShell has no default multi-tenant app; you must supply
  your own registered app’s **client ID**, and it must be admin-consented.
- **Resolve:** register `PnP – Provisioning – Prod`
  (`Register-PnPEntraIDAppForInteractiveLogin -ApplicationName "PnP – Provisioning – Prod" -Tenant <tenant>.onmicrosoft.com`),
  admin-consent the required delegated permissions, and pass `-ClientId <app-client-id>` on every
  `Connect-PnPOnline`. See Requirement 1.

### `Connect-SPOService` cannot reach the admin center
- **Cause:** wrong admin host, or a **Government/sovereign cloud** where the URL and endpoint
  differ from Commercial.
- **Resolve:** use your tenant’s admin URL (`https://<tenant>-admin.sharepoint.com` for Commercial;
  the GCC High / DoD host differs) and pass the correct `-Region`/environment. **Verify in your
  tenant** — do not assume the Commercial URL.

### Unattended provisioning flow fails at sign-in
- **Cause:** interactive/delegated auth cannot run unattended.
- **Resolve:** use **certificate-based app-only** auth for the flow’s app registration; store the
  certificate in a secure store; never hardcode a secret in the script.

---

## Provisioning

### The provisioning script "did nothing"
- **Cause:** it ran in the **default `-WhatIf` dry-run**; that is by design.
- **Resolve:** review the planned name/template/hub the dry run printed, then re-run with `-Commit`.

### Computed site URL is wrong or rejected
- **Cause:** the department/purpose contained characters stripped by the naming policy, or the URL
  already exists.
- **Resolve:** the policy upper-cases and strips non-alphanumerics (`TEAM-<Dept>-<Purpose>`); pick a
  distinct purpose/code, or delete/rename the colliding site. Confirm the department is a valid
  value from `Term Set – Department – Prod`.

### `Invoke-PnPSiteTemplate` errors or applies partially
- **Cause:** the `.pnp` template references site columns/content types not yet present (e.g. the
  governed content type has not syndicated), or a handler failed mid-apply.
- **Resolve:** confirm `Content Type – Governed Document – Prod` is **published** and has syndicated
  to the site collection (publishing is asynchronous — allow time), then re-run
  `Invoke-PnPSiteTemplate`. PnP template application is idempotent; re-applying completes missing
  handlers.

### `New-PnPSite` for a group Team site fails on alias
- **Cause:** the M365 group **alias** collides, or group creation is restricted to an approved group
  (Requirement 2) that the running identity is not in.
- **Resolve:** choose a unique alias, or run as an identity permitted to create groups. This is
  expected once self-service group creation is constrained — provision through the approved app.

---

## Hubs

### `Add-PnPHubSiteAssociation` fails: hub not found
- **Cause:** the hub is not registered, or the title does not match exactly.
- **Resolve:** `Get-PnPHubSite` and confirm the exact title (`Hub – Pilot – Pilot`,
  `Hub – Corp – Prod`, `Hub – Divisions – Prod`). Register it with `Register-PnPHubSite` if missing.

### Site associated to the wrong hub
- **Resolve:** re-run `Set-SPOHubAndMetadata.ps1 -Commit` with the correct `-Hub`; it removes the
  existing association and adds the correct one. Association is reversible
  (`Remove-PnPHubSiteAssociation`).

### Hub navigation / theme not showing on an associated site
- **Cause:** hub settings propagate asynchronously, or the site overrides navigation.
- **Resolve:** allow propagation time; confirm the site is not using a custom nav that overrides the
  hub. Re-check with `Get-PnPHubSite`.

---

## Taxonomy & content types

### Managed-metadata columns show as free text or are missing
- **Cause:** the governed content type / site columns did not publish or syndicate.
- **Resolve:** confirm `Content Type – Governed Document – Prod` and the columns
  (`Site Column – Department – Prod`, etc.) exist in the **content type gallery** and are
  **published**; wait for syndication; re-apply the template. See Requirement 4.

### Term set exists but has no values / users cannot pick a term
- **Cause:** the structure was created but the **business term values** were not added (they are the
  org’s vocabulary, supplied by the taxonomy owner — Requirement 3).
- **Resolve:** have the Term Store Administrator / taxonomy owner add the terms
  (`New-PnPTerm -TermSet "Term Set – Department – Prod" …`). The solution builds structure, not the
  determination of which terms are valid.

### Content type gallery not available
- **Cause:** older tenant surfacing the classic Content Type Hub instead.
- **Resolve:** use `/sites/contentTypeHub` publishing on that tenant. **Verify in your tenant** which
  surface is present.

---

## Governance pipeline & lifecycle

### Sites are still being created outside the pipeline
- **Cause:** self-service site and/or M365 **group creation** is not yet constrained (this is only
  done at Expand, Step 6.2).
- **Resolve:** restrict group creation to the approved group and set site creation to route through
  the request process under change control. **Rollback is a settings reversal** — no data is lost.
  Verify with Test 8. **Verify the exact setting/behavior in your tenant.**

### The approval flow does not trigger provisioning
- **Cause:** the flow’s connection to the provisioning helper/app failed, or the approver was not
  set.
- **Resolve:** confirm `Provisioning Flow – Approve → Provision – Prod` has a valid connection and
  the governance approver (Requirement 5) is configured; test with a single request end-to-end
  (Test 7).

### Owner-less or inactive sites are not being caught
- **Cause:** `Lifecycle Policy – Inactive Site – Prod` signals (M365 group expiration, owner check)
  are not configured.
- **Resolve:** enable group expiration for group-connected sites and ensure the provisioning gate
  refuses requests without a business owner and two site owners; run
  `Get-SPOGovernanceComplianceReport.ps1` to surface owner-less sites.

---

## Reporting

### Compliance report shows a site inspectable in the browser as "non-compliant" for content type
- **Cause:** the report connects per-site and may hit a transient permission/throttling error while
  reading fields/content types.
- **Resolve:** re-run scoped to the affected site; confirm the running identity has access; if the
  tenant is throttling, run the report in smaller scopes (per hub) rather than tenant-wide at once.

### Assessment or report is slow / times out on a large tenant
- **Cause:** enumerating thousands of site collections and inspecting each is expensive.
- **Resolve:** run `Invoke-SPOArchitectureAssessment.ps1` off-peak; scope
  `Get-SPOGovernanceComplianceReport.ps1` with `-Scope Hub` rather than `Tenant`; expect
  Microsoft 365 throttling on very large estates and retry.
