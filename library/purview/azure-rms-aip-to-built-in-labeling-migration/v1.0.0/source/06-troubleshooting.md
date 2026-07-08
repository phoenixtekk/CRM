# 6. Troubleshooting Guide — Azure RMS / AIP → Built-in Unified Labeling Migration

Field issues and how to resolve them, in the order you are likely to hit them. Every check here is safe
(read-only, a `-WhatIf` preview, or a controlled action on the pilot ring).

## After cutover, a label the add-in showed is missing from the Office ribbon
**Symptom:** A user on built-in labeling no longer sees a label the AIP add-in used to show.
**Cause:** The label exists only in a legacy/classic location, or it isn't published to the user in the
label policy that applies to them (built-in labeling reads only the **unified store**).
**Fix:** Run `IPRMSMIG-Test-Parity.ps1 -UserUpn <user> -ExpectedLabelsPath .\expected-labels.txt` — it
flags `MISSING` labels. Publish the label in the Purview portal, add it to the user's label policy, then
run `IPRMSMIG-Scope-Health.ps1 -Commit` to sync. Confirm with `Get-LabelPolicy`.

## `Connect-AipService` fails or `Get-AipServiceConfiguration` errors
**Symptom:** The AIPService cmdlets won't connect or return errors.
**Cause:** The AIPService module is missing/old, or the account lacks the Azure RMS admin role.
**Fix:** `Install-Module AIPService -Scope CurrentUser -Force`; sign in with a modern-auth admin that
holds the rights to manage the protection service. Re-run `IPRMSMIG-Scope-Health.ps1`.

## Azure RMS `FunctionalState` is `Disabled`
**Symptom:** `IPRMSMIG-Scope-Health.ps1` reports RMS not `Enabled`; label encryption won't apply.
**Cause:** The Azure Rights Management protection service was never activated (or was deactivated).
**Fix:** Activate it as a one-time, reserved Global-Admin action (`Enable-AipService`) under change
control — this is deliberately **not** done by the scripts. Then confirm super-users are configured (2.8)
before changing protection behaviour. Re-run the health check.

## Encryption/custom permissions behave differently than under the add-in
**Symptom:** A label encrypts differently, or a custom-permissions/protected-PDF scenario doesn't work.
**Cause:** The parity mapping missed an encryption setting, **or** the user's Office build is too old for
that built-in-labeling feature (encryption, co-authoring, custom permissions have minimum builds).
**Fix:** Compare the label's encryption settings against the source in `Built-in Labeling Parity –
Design`; recreate the missing setting on the label. Run `IPRMSMIG-Test-Parity.ps1 -OfficeBuild '<build>'`
— if it flags **NEEDS NEWER BUILD**, update Office. Build thresholds are indicative — **verify against
Microsoft's current capabilities table.**

## A departmental RMS template's protection didn't carry over
**Symptom:** Content that used an Azure RMS departmental template is no longer protected as expected.
**Cause:** Departmental/protection templates are **not auto-converted** to labels — the mapped label
wasn't created with matching encryption, or wasn't published.
**Fix:** For each template in the inventory (`Get-AipServiceTemplate`), create/confirm a sensitivity
label reproducing its permissions, offline access, and expiry; publish it to the affected users; run
`Execute-AzureADLabelSync` (`IPRMSMIG-Scope-Health.ps1 -Commit`). Whether the template still applies is a
records/compliance determination — confirm with the owner.

## The AIP add-in is still loading after you applied the client policy
**Symptom:** Users still see the **Azure Information Protection** add-in in the ribbon post-cutover.
**Cause:** The client policy (disable the add-in / enable built-in labeling) didn't reach the device, or
the wrong setting/registry value was used — the Office ADMX names and any registry values evolve.
**Fix:** Confirm the GPO / Cloud Policy targets the user's device and Office restarted. **Verify the exact
setting names and any registry value against the current Office ADMX** (the built-in-labeling switch is
commonly `UseOfficeForLabelling`, plus a managed-add-in setting to disable the add-in) — do not assume a
value from an old screenshot.

## `Set-LabelPolicy -AdvancedSettings` rejects a key or has no effect
**Symptom:** `IPRMSMIG-Set-LabelPolicy.ps1 -Commit` errors on a key, or the behaviour doesn't change.
**Cause:** The advanced-setting **key name** is wrong or deprecated — these vary and evolve; or the
setting applies to a different scope (Outlook vs client) than expected.
**Fix:** Verify the key name against Microsoft's **current** label-policy advanced-settings documentation
and correct the `parity.json`. Re-run with `-WhatIf` first. The script never invents keys — it applies
only what you supply.

## Old protected content won't open on a migrated device
**Symptom:** Documents/emails protected before the migration are denied on a cutover device.
**Cause:** A protection mapping is wrong, or the user genuinely lacks rights.
**Fix:** Use **RMS super-user** recovery (confirmed in 2.8) to open and re-protect the content while you
correct the label/template mapping; then re-validate with the Testing Guide before expanding. This is
exactly why super-users must exist before the first cutover.

## `Execute-AzureADLabelSync` runs but protection still lags
**Symptom:** You synced but the user still sees the pre-change behaviour.
**Cause:** Label/protection changes take time to propagate after a sync, and Office caches label policy.
**Fix:** Allow propagation time, have the user restart Office (which refreshes the label policy), and
re-test. If it persists, re-check the label is published to that user and RMS is `Enabled`.

---
### When to stop and escalate
- **Azure RMS won't activate** or a plan doesn't include the required encryption feature → this is a
  licensing/tenant action; record it and do not force protection changes until it's resolved.
- A **records/retention or legal determination** about whether a legacy departmental template still
  applies is being asked of you → escalate to compliance, records, privacy, or legal. This solution
  provides the technical mapping and evidence, never the determination.
- A **client-policy setting name or registry value in this guide doesn't match your environment** → the
  Office ADMX and the AIP add-in retirement state are evolving; verify the current value against
  Microsoft's guidance and your Office channel rather than assuming the step is wrong.
