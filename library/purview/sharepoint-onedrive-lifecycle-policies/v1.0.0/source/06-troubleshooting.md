# 6. Troubleshooting — SharePoint & OneDrive Lifecycle Policies (Microsoft Purview)

Symptoms, likely causes, and fixes for the retention lifecycle. Stay in **retain-only pilot** while
diagnosing — reproduce on `SPO Lifecycle – Pilot Scope – Stage1` before enabling deletion or expanding,
and never enable the delete action to "test" a theory.

## "I deleted a file but it's still there" (Preservation Hold Library)
- **This is retention working.** SharePoint/OneDrive retention keeps a copy of deleted-but-retained
  content in the site's **Preservation Hold Library** until its period elapses. The user's view shows the
  file removed; the hold library retains the copy. Confirm in the site's Preservation Hold Library — this
  is expected, not a defect.

## The policy doesn't seem to apply / takes a long time
- **Propagation delay.** New retention policies can take time (often up to ~1 day, longer for large
  scopes) to fully apply across all locations. Confirm the policy is **Enabled** and wait before
  concluding failure.
- **Location not in scope.** Verify the site/account is actually in the policy's SharePoint/OneDrive
  locations (`DLCSPO-Discover.ps1` / the portal). A static scope only covers the URLs you listed.
- **Adaptive scope query mismatch.** If using an adaptive scope, the site/user may not match the query.
  Re-check the adaptive-scope rule and that the scope has finished evaluating.

## Content is being deleted when I expected retain-only
- **A delete action is enabled.** Run `DLCSPO-Validate.ps1 -ExpectDelete:$false`; if it FAILS the "no
  unintended deletion" gate, the rule is retain-then-delete/delete-only. Return it to retain-only with
  `Set-RetentionComplianceRule -Identity <rule> -RetentionComplianceAction Keep` (or
  `DLCSPO-Set-RetentionPolicy.ps1` was run with `-Action EnableDelete` — reverse it).
- **Reminder:** deletion only happens **after** the period elapses, and it is **irreversible**. Keep the
  action retain-only through the pilot; enable deletion only after validation and approval.

## `DLCSPO-Set-RetentionPolicy.ps1 -Commit` fails
- **Not connected / wrong session.** Ensure `Connect-IPPSSession` succeeded
  (`Get-Command Get-RetentionCompliancePolicy` resolves).
- **Insufficient role.** Creating retention policies needs Records Management / Compliance Administrator.
  Confirm in Purview → Roles & scopes / Permissions.
- **Action/parameter name by module version.** The retain-then-delete action name and rule parameters vary
  across ExchangeOnlineManagement versions (e.g. `KeepAndDelete` vs a `-RetentionComplianceAction` value).
  Verify against your version; update the module if it's far behind.
- **Site URL not resolvable.** A SharePoint URL in `-PilotSites` must be a valid, existing site collection
  URL. Confirm the URL and that you have rights to it.

## Adaptive scope options aren't available
- **Licensing.** Adaptive scopes generally require **E5 / E5 Compliance**. `DLCSPO-Check-Prereqs.ps1`
  reports the `Get-AdaptiveScope` signal. Where unavailable, use a **static scope** and schedule a review
  to catch drift — record adaptive scoping as **deferred**.

## Storage is growing unexpectedly
- **Preservation Hold Library growth.** Retained-then-deleted content accumulates in the hold library
  until its period elapses. This is expected; account for it in capacity planning. It is not a reason to
  disable retention — coordinate storage with the schedule length.

## A location won't release content / conflicts with a hold
- **Overlapping holds win.** A location can be under a retention policy, a retention label, and an
  **eDiscovery hold** simultaneously; the **most restrictive** (longest/hold) wins, so content won't
  delete while any hold applies. Check for eDiscovery holds on the location before expecting deletion, and
  coordinate with the eDiscovery owner.

## `DLCSPO-Validate.ps1` reports a property/action mismatch that looks wrong
- **Module-version property shape.** Location and action properties are exposed under different names
  across module versions. Confirm the intended state in the portal (Data Lifecycle Management → the policy)
  and treat the validator line as informational where the portal disagrees; note the module version.

---
### When to stop and escalate
- A required capability is unavailable on your licensing/tenant (e.g. adaptive scopes) — record it
  **deferred**, fall back to static scoping, and route the licensing decision to the owner.
- **The schedule** — periods, what is a record, what may be deleted and when, and any legal hold — is a
  records/compliance/legal determination, not a technical fix. Capture it in `Lifecycle Schedule – Map`
  and defer the determination.
- If retention/deletion behavior can't be reconciled with the policy, keep the scope on the pilot in
  retain-only, gather `DLCSPO-Validate.ps1` + `DLCSPO-Report.ps1` output as evidence, and raise with
  Microsoft support before enabling deletion or expanding.
