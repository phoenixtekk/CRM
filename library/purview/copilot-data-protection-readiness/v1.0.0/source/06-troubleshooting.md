# 6. Troubleshooting — Microsoft 365 Copilot Data-Protection Readiness (Microsoft Purview)

Common failure modes and resolutions, grouped by phase. Most issues are **licensing/availability**,
**permissions/scope**, or **propagation timing** — the controls here are evolving and licensing-gated,
so "verify in your tenant" is the recurring theme. Scripts are read-only or `-WhatIf`/simulation until
`-Commit`, so diagnosis is safe.

## Connections & authentication
- **`Connect-IPPSSession` fails or cmdlets missing (`Get-Label` not found).** Install the current
  **ExchangeOnlineManagement** module and connect with a modern-auth/MFA compliance admin.
  `AICOPILOT-ReadinessScope.ps1` reports the session state.
- **`Connect-MgGraph` connected but site/permission reads fail.** The Graph session lacks scope. Reconnect
  requesting at least `Sites.Read.All` (and `InformationProtectionPolicy.Read.All` where used); confirm
  an admin consented to the scopes. `Get-MgSitePermission` also requires sufficient rights — if it is
  denied, fall back to the **SharePoint DAG report** for the authoritative view.
- **"Access denied" opening a Purview/SharePoint blade.** Missing the least-privilege role (Requirement
  2.2). Assign Information Protection Admin / the DLP role / SharePoint Administrator as appropriate; don't
  work around it with Global Admin as standing practice.

## Licensing & availability (the most common blocker)
- **The DLP "Microsoft 365 Copilot" location is not present.** It is evolving and licensing-gated —
  **verify**. If absent, do not fake it: keep "keep out of Copilot" content controlled with sensitivity
  **label encryption/usage rights** (which Copilot honors) plus **site access reduction** (Step 6), and
  record DLP-for-Copilot as pending. `AICOPILOT-Remediation.ps1 -Action DlpForCopilot` parameterizes the
  location and warns rather than assuming it.
- **SAM reports/controls (DAG, RCD, RSS, RAC, site access reviews) missing.** SharePoint Advanced
  Management is not licensed/enabled (Requirement 2.6). Remediate access via native SharePoint site/
  sharing settings and Graph permission review instead, and note the interim containment as unavailable.
- **Container labeling / mandatory labeling options not shown.** Both are licensing-dependent — verify.
  Proceed with a **default label** (no mandatory enforcement) if mandatory labeling is unavailable.
- **DSPM for AI blade absent.** It is optional here — this solution remediates with or without it. Use the
  discovery scripts and SharePoint DAG reports for the oversharing picture.

## Discovery
- **`Get-MgSite -Search "*"` returns few or no sites.** The Graph module version or scope limits the
  search; the endpoint/behavior can vary — **verify** the `Microsoft.Graph.Sites` module. Supply the
  in-scope site list from the SharePoint admin DAG export and pass targeted site IDs instead of a wildcard.
- **Every site shows `OversharingSignal = review`.** Permission reads were unavailable (scope). Use the
  **SharePoint DAG "Everyone Except External Users" / sharing-links reports** as the authoritative source
  and reconcile.
- **Discovery and DAG report disagree.** The DAG report is the authoritative tenant view; the script is a
  portable snapshot and may lag or lack permission depth. Trust the DAG report for the decision.

## Labeling
- **Auto-labeling policy created but nothing appears labeled.** Correct — in **simulation** it labels
  nothing; it only shows what it *would* label. Review the **simulation results** in the portal before
  enabling. If simulation shows nothing at all, the policy has no rules/conditions yet — add the sensitive
  info type → label conditions.
- **Simulation over-matches (false positives).** Tighten the conditions (more specific info types,
  confidence/count thresholds) and re-simulate. Never enable an over-matching policy.
- **Copilot still summarizes content that carries a "protected" label.** The label likely classifies
  without **encryption/usage rights** — Copilot only withholds content whose label denies the user usage
  rights. Add encryption with the appropriate usage rights to the label, and allow for propagation.
- **Cited Copilot responses carry an unexpected label.** Copilot inherits the **highest-priority** label
  of the cited sources — check the label **priority order** in the taxonomy.

## DLP for Copilot
- **Policy created but no test matches.** In **test** mode matches are simulated only; confirm the rule
  scopes the **Copilot location** and the correct **label** condition. Allow processing time.
- **Cannot add the Copilot-location rule (`New-DlpComplianceRule`).** The Copilot DLP location may not be
  available via PowerShell in your tenant — configure the rule in the **Purview DLP portal**, or use the
  label-encryption + access-reduction equivalent. Verify availability.

## SharePoint access reduction & interim containment
- **Removing a broad grant broke legitimate access.** Restore the prior sharing on that site immediately
  (rollback), then re-scope the reduction to a least-privilege **group** (RAC where licensed) so intended
  users keep access. Pilot access changes on the ring first.
- **RSS/RCD applied but Copilot/search still returns fenced content.** Allow for propagation; confirm RSS
  mode (`Get-SPOTenantRestrictedSearchMode`) and that the site is on the correct RCD/allow list. RSS is an
  **interim allow-list (up to 100 sites)** — content outside the allow list is excluded, not the reverse;
  confirm the list semantics for your intent.
- **Treating RSS/RCD as the fix.** They are **stopgaps** — they hide, not reduce, access. Track fenced
  sites as remediation debt and remove containment once the underlying access is actually corrected.

## Enforcement & go/no-go
- **`AICOPILOT-Remediation.ps1 -Action Enforce` did nothing.** By design it previews without `-Commit`,
  and the enforce mode-changes are commented until you match your exact policy names — set the specific
  policy identities to the enable mode and confirm the mode value in your tenant.
- **Go/no-go report shows a control "MISSING".** The policy name doesn't match, or it wasn't created.
  Re-run the relevant remediation step with the exact artifact name, then re-report. Do not sign a
  go/no-go with missing evidence.
- **Oversharing signal did not drop after remediation.** Re-run discovery on the **same site set**;
  confirm the access changes actually applied (propagation), and that new broad shares didn't appear.
  Persisting signal means more sites to remediate before broad Copilot rollout.
