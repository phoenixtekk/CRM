# 6. Troubleshooting Guide — Sensitivity & Retention Labels

Common failure modes, likely causes, and resolutions. Portal paths are current at authoring — the
Purview portal is evolving, so **verify paths in your tenant**. Where a symptom is caused by
licensing, the fix is a plan check, not a config change — **verify your licensing/tenant.**

## A cmdlet is "not recognized" (Get-Label / New-AutoSensitivityLabelPolicy / Get-AdaptiveScope)
- **Cause:** not connected to Security & Compliance PowerShell, or the feature is not licensed in the tenant.
- **Resolve:** run `Connect-IPPSSession` (from the ExchangeOnlineManagement module) first. If the cmdlet still fails after connecting, the capability may require **E5 / E5 Compliance** (service-side auto-labeling, adaptive scopes) — verify the subscription. The provided scripts auto-connect but cannot grant licensing.

## Access denied creating labels or policies
- **Cause:** the admin lacks **Information Protection Admin** (sensitivity) or **Records Management / Compliance Administrator** (retention/adaptive scope) role, or the role has not propagated.
- **Resolve:** add the account to the least-privilege role group (§2.2), sign out/in, allow propagation time, retry.

## Pilot users don't see the sensitivity labels in Office
- **Cause:** label policy not scoped to the user, client not yet synced, or an older Office build.
- **Resolve:** confirm the user is in the group backing `SL Policy – Pilot – Ring1`; verify with `Get-LabelPolicy`. Allow client sync time (can take up to a few hours); confirm a current Microsoft 365 Apps build. Labels only appear once the **policy** is published, not when the label is created.

## An encrypting label doesn't actually protect the file
- **Cause:** the protection (Rights Management) service isn't activated, the rights definition points at a non-existent/empty group, or the label isn't published.
- **Resolve:** confirm the protection service is **activated** (§2.6); confirm the mail-enabled security group in `EncryptionRightsDefinitions` exists and has members; confirm the label is published via a policy. Re-run Test 3 (unauthorized open must be denied).

## Co-authoring or third-party tools break after applying an encrypting label
- **Cause:** encryption + rights that block the collaboration/automation path.
- **Resolve:** this is expected behavior for strong protection — that's why encryption is piloted. Reserve encrypting labels for content that truly needs it; use marking-only labels for lower tiers. Review the rights model with the data owner; ensure required co-authors are in the rights group.

## Service-side auto-labeling "isn't labeling anything"
- **Cause (usually correct behavior):** the policy is in **simulation** (`TestWithoutNotifications`) — it scans and reports but **does not label**. This is by design until precision is signed off.
- **Resolve:** confirm mode with `PURVLABEL-SimulationReport.ps1`. Once precision is accepted (Test 6), enforce with `PURVLABEL-SensitivityConfig.ps1 -AutoLabel -EnforceFromSimulation -Commit`.

## Simulation shows too many matches (false positives)
- **Cause:** the auto-labeling rule conditions are too broad (loose sensitive info types, low instance counts).
- **Resolve:** tighten the rule — higher minimum instance counts, more specific sensitive info types, add supporting keywords, or use a trainable classifier. Let simulation re-run and re-review with the data owner. Do **not** enforce until precision is acceptable.

## Simulation seems "stuck" / no results yet
- **Cause:** service-side scanning processes large volumes over time and is subject to throughput/item limits; results are not instant.
- **Resolve:** allow the scan to progress; re-run `PURVLABEL-SimulationReport.ps1` later. Confirm the in-scope locations actually contain matching content. **Verify current scan limits for your tenant.**

## Adaptive scope resolves 0 objects (or the whole tenant)
- **Cause:** the query attribute is unpopulated (0 objects) or the query is too broad (everyone).
- **Resolve:** preview with `PURVLABEL-Validation.ps1 -ScopeName "<scope>"`. If empty, backfill the query attribute (e.g. `Department`) per §2.7. If too broad, tighten the query. Never bind a retention policy to an unvalidated scope.

## Retention label not offered to users
- **Cause:** the retention label policy isn't scoped to the user/site, or publishing latency.
- **Resolve:** confirm the label is published via `RL Publish – Pilot – Ring1` (pilot) or the adaptive policy; check `Get-RetentionCompliancePolicy` and its rule (`New-RetentionComplianceRule -PublishComplianceTag`). Allow publishing latency before concluding it failed.

## A retention "delete" label deleted content unexpectedly (or didn't dispose)
- **Cause:** wrong action/trigger, or the disposition behavior wasn't tested on disposable content first.
- **Resolve:** **halt broad reliance immediately.** Review the label's `RetentionAction`, `RetentionDuration`, and `RetentionType` (creation vs modification trigger) with records/legal. Only re-enable after Test 10 passes on throwaway items. Remember: retention periods/actions are records/legal determinations, not technical defaults.

## Changes to a label aren't reflected for users
- **Cause:** label/policy edits take time to propagate; existing content keeps the label it was stamped with.
- **Resolve:** allow propagation; re-publish if needed. Note that renaming/reordering labels after publish is disruptive — existing content retains the prior label. Design the taxonomy up front (Best Practices).

## Rolling back a policy safely
- **Sensitivity policy:** `Remove-LabelPolicy "<name>"` unpublishes without deleting the labels.
- **Auto-labeling:** `PURVLABEL-SensitivityConfig.ps1 -AutoLabel -AutoLabelName "<name>" -DisableAutoLabel -Commit` returns it to simulation.
- **Retention policy:** `Remove-RetentionCompliancePolicy "<name>"` unpublishes without deleting the retention labels.
- Removing a **policy** never deletes the underlying **labels** — so rollback is low-risk and reversible.
