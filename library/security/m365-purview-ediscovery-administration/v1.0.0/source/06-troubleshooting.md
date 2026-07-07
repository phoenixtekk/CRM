# 6. Troubleshooting — Microsoft 365 Purview eDiscovery Administration

Common failure modes and how to resolve them. Object names use the pilot convention (`eDiscovery Case
– Matter-A – Pilot`, `Content Search – Matter-A-Keywords – Pilot`, `Hold Policy – Matter-A – Pilot`);
substitute your matter. Start most diagnostics with `MSEDISC-Discovery.ps1` and `MSEDISC-Report.ps1`.

## Access & roles

### "You don't have permission" / can't see a case
**Cause:** The operator is not in an eDiscovery role group, or is an **eDiscovery Manager** (who sees
only their **own** cases) trying to open someone else's case.
**Resolve:** Confirm membership with `MSEDISC-Discovery.ps1` or Purview → **Settings → Roles &
scopes**. Add the operator to **eDiscovery Manager**; for cross-case visibility add to **eDiscovery
Administrator** (Requirement 2.2). Do **not** work around this with Global Admin.

### `Connect-IPPSSession` fails or hangs
**Cause:** Module missing/old, or modern-auth/MFA prompt blocked.
**Resolve:** `Install-Module ExchangeOnlineManagement -Scope CurrentUser`; run interactively so the
MFA prompt appears. In Government clouds pass the correct environment/host — **verify in your
tenant**. Never store credentials to bypass the prompt.

## Licensing / tier

### Custodians, review sets, or analytics are missing from the portal
**Cause:** The tenant/operator has **eDiscovery (Standard)** only — custodians, review sets,
analytics/de-dup, and structured export are **Premium (E5 / E5 eDiscovery and Audit)** features.
**Resolve:** Confirm licensing (Requirement 2.1) in the admin center and with `MSEDISC-Discovery.ps1`;
assign E5/add-on to operators and to custodians who will be placed on a Premium custodian hold.
Menu names differ since the eDiscovery experience was modernized — **verify in your tenant**.

## Search & query

### Search returns zero hits (but content exists)
**Cause:** Query too narrow, wrong locations, or content not yet indexed.
**Resolve:** Re-check the KQL and date range (Implementation Step 4); confirm the in-scope
`-ExchangeLocation`/`-SharePointLocation`; preview with `New-ComplianceSearchAction -Preview`. Widen
one condition at a time and re-run `MSEDISC-Search.ps1 -Apply` — the search **name stays the same**.
Newly created/seeded content can take time to index.

### Search returns far too much
**Cause:** Over-broad free-text query or `All` locations left on after the estimate.
**Resolve:** Add explicit conditions (date range, participants, `kind:`/`filetype:`), scope locations
to the actual custodians, and re-run. Read the statistics with `MSEDISC-Report.ps1` to confirm the
count drops to a plausible range (Testing Test 4).

### Teams messages or Teams files are missing from results
**Cause:** Teams **1:1/channel messages** are stored in the participants' **mailboxes** (Exchange);
Teams **files** live in **SharePoint/OneDrive**. Searching only SharePoint (or only Exchange) misses
half of Teams.
**Resolve:** Include both the custodian **mailbox** (for messages) and the relevant **SharePoint/
OneDrive** locations (for files). Confirm both workloads show hits in `MSEDISC-Report.ps1`.

### Some items are flagged unindexed / partially indexed
**Cause:** Items Microsoft could not fully index (unsupported/corrupt/encrypted content).
**Resolve:** In Premium collections, deliberately **include** unindexed items and record the count;
do not silently drop them. Investigate high unindexed counts (a bad file type, encryption) before
producing.

## Holds & preservation

### Hold shows an error or "not applied"
**Cause:** Invalid location (mailbox/site not resolvable), a custodian without an eligible license, or
propagation still in progress.
**Resolve:** Verify each location is valid and the custodian is licensed; check
`Get-CaseHoldPolicy`/`Get-CaseHoldRule` via `MSEDISC-Report.ps1`. Hold application can take time to
propagate — re-check after propagation.

### A held item was permanently deleted
**Cause:** The hold was placed **after** the deletion, or the hold scope missed that location.
**Resolve:** Preservation only protects content **from the moment the hold is effective** — place the
hold **before** collection/notification (Best Practices). Confirm the deleted item's location was in
`Hold Policy – Matter-A – Pilot`. This is why the pilot **Hold effective** gate (Testing Test 5)
tests deletion→recoverability before any live matter.

### Need to remove a hold
**Cause:** Matter closed or scope changed.
**Resolve:** Remove the **rule** then the **policy** (`Remove-CaseHoldRule` → `Remove-CaseHoldPolicy`;
or portal case → Holds → remove). **On a live matter, get legal approval first** — releasing a hold
can destroy preservation (Implementation rollback).

## Export

### Export fails, is partial, or counts don't reconcile
**Cause:** Interrupted job, throttling on a very large export, or a transient service error.
**Resolve:** Re-run the export; for large matters export in batches. Confirm final status
**Completed** and that item counts match the review-set/search estimate in `MSEDISC-Report.ps1`. Do
**not** treat a partial export as a defensible production (Testing Test 7).

### Export downloaded but no load file / report
**Cause:** Export options omitted the metadata load file or results report.
**Resolve:** Re-export selecting the **load file** and **report** options; keep both as the matter's
evidence (Best Practices — defensible export).

## Boundaries & scope

### A scoped operator can search outside their region/agency
**Cause:** Compliance security filter missing or its membership predicate is wrong.
**Resolve:** Review filters with `MSEDISC-Scope.ps1`; correct the `-RecipientFilter` predicate and
re-create (`New-ComplianceSecurityFilter`). Filter syntax is version-dependent — **verify in your
tenant**. Remember the boundary **policy** is a legal/HR decision; only its implementation is fixed
here.

## Audit / evidence

### No audit activity for the matter
**Cause:** Unified audit log disabled, or too little time has passed.
**Resolve:** Enable auditing (Requirement 2.3); allow events to populate; re-run `MSEDISC-Report.ps1`.
The audit trail is the defensibility evidence — a matter without it is not fully defensible.
