# 6. Troubleshooting Guide — Container Labeling (Teams, Groups & Sites)

Field issues and how to resolve them, in the order you are likely to hit them. Every check here is safe.

## The container-label scope ("Groups & sites") isn't selectable on a label
**Symptom:** When creating/editing a sensitivity label, the **Groups & sites** scope is greyed out or the
protection settings never apply to containers.
**Cause:** Container labeling isn't enabled for the tenant — the `Group.Unified` directory setting
`EnableMIPLabels` is not `True`, or labels haven't been synced.
**Fix:** Run `IPCONT-Check-Prereqs.ps1` and read the `EnableMIPLabels` line. Enable with
`IPCONT-Set-ContainerLabels.ps1 -EnablePrerequisites -Commit` (Global/Groups Admin) — it sets the setting
and runs `Execute-AzureAdLabelSync`. **Verify the current enablement method against Microsoft guidance for
your tenant** — the directory-settings surface is evolving (legacy AzureADPreview vs Microsoft Graph).

## `Execute-AzureAdLabelSync` isn't recognized / the sync step warns
**Symptom:** The enablement `-Commit` prints a warning on the label-sync step, or the cmdlet is missing.
**Cause:** The **AIPService** module isn't installed, or `Connect-AIPService` didn't complete.
**Fix:** `Install-Module AIPService -Scope CurrentUser -Force`; run `Connect-AIPService` then
`Execute-AzureAdLabelSync`. The setting change (`EnableMIPLabels`) is the gating action; the sync makes
labels available faster. Verify AIPService availability/guidance for your tenant.

## A published container label doesn't appear when creating a Team/site
**Symptom:** A pilot user creates a Team/site but sees no container labels (or not the expected one).
**Cause:** The label policy isn't published to that user, the label lacks the **Groups & sites** scope,
or label sync hasn't propagated yet.
**Fix:** Confirm `Container Labels – Groups & Sites – Policy` includes the user (`Get-LabelPolicy`), that
the label has container scope (`Get-Label`), and allow time for propagation. A non-member correctly sees
nothing — that is the policy gating access, not a bug.

## Applying a label to a group fails with "insufficient privileges" (403)
**Symptom:** `IPCONT-Set-ContainerLabels.ps1 -Commit` errors PATCHing a group's `assignedLabels`.
**Cause:** The delegated Graph write scope wasn't consented — `Group.ReadWrite.All` (and
`Directory.ReadWrite.All` for the enablement step).
**Fix:** Re-run `Connect-MgGraph` with the scopes in the script header and consent; if admin consent is
required, a Global Administrator approves them once in Entra → Enterprise applications. Discovery and
validation need **read** scopes only.

## `[MISSING LABEL]` — the label name isn't found in the catalog
**Symptom:** The apply script reports the target label isn't in the published catalog.
**Cause:** The label isn't published to the running account, or the display name in the targets CSV
doesn't match the label exactly.
**Fix:** Run `Get-Label` / `IPCONT-Check-Prereqs.ps1` to see the exact published label names; correct the
CSV `Label` column. The label must be **published** (in a label policy) to be resolvable.

## A site label applied but external sharing didn't actually tighten
**Symptom:** A `Container – Highly Confidential` site still allows guest sharing.
**Cause:** The **SharePoint tenant** `SharingCapability` ceiling, or the label can only *tighten* sharing
— it can't exceed the tenant, and per-site sharing can be overridden. Or propagation lag.
**Fix:** Confirm the tenant baseline with `IPCONT-Check-Prereqs.ps1`; remember a label **tightens**, so a
tenant already at "Only people in your organization" makes a broader label setting a no-op. Verify the
per-site sharing with `Get-SPOSite -Detailed`. Allow time for the setting to apply.

## Unmanaged-device access isn't limited/blocked as the label says
**Symptom:** A `Container – Confidential` site downloads fine from an unmanaged device.
**Cause:** The unmanaged-device (Conditional Access) control requires **Entra ID P1** and SharePoint
Conditional Access; without P1 the label's device setting has no enforcement. Or the tenant/site
`ConditionalAccessPolicy` isn't set to limited/block.
**Fix:** Run `IPCONT-Check-Prereqs.ps1` — if `AAD_PREMIUM` isn't detected, record the device control as
**deferred (not licensed)** and scope the label to privacy/guest/external-sharing. Where P1 exists, verify
the SharePoint `ConditionalAccessPolicy` and the label's device-access setting. **Verify against your
plan.**

## Guest was still addable to a "no guests" container
**Symptom:** An owner added an external guest to a `Container – Highly Confidential` Group.
**Cause:** The label wasn't actually applied to that container, the guest setting on the label isn't
"not allowed," or the tenant-level B2B/guest policy is overriding. Propagation lag is also possible.
**Fix:** Validate with `IPCONT-Validate-ContainerLabels.ps1` that the container carries the label and
privacy is `Private`; confirm the label's guest setting; check the Entra external-collaboration settings
aren't contradicting. Re-test after propagation.

## `Connect-SPOService` fails or sites aren't enumerated
**Symptom:** The discovery/report/validate scripts skip SharePoint sites.
**Cause:** `-SPOAdminUrl` wasn't supplied, the **Microsoft.Online.SharePoint.PowerShell** module is
missing, or the account lacks SharePoint Administrator.
**Fix:** Install the module, pass `-SPOAdminUrl https://<tenant>-admin.sharepoint.com`, and connect as a
SharePoint Administrator. Group/Team data still comes from Graph without SPO — only site-level sharing
requires the SPO connection.

## Validation reports FAIL "label != expected" right after applying
**Symptom:** `IPCONT-Validate-ContainerLabels.ps1` shows the old/empty label just after `-Commit`.
**Cause:** Label assignment to a container can take time to propagate across Graph/SharePoint.
**Fix:** Wait and re-run validation. If it persists, re-check the apply output for an error and confirm
the label is published and the target identity (group id / site URL) is correct.

---
### When to stop and escalate
- A required control is **not licensed** (e.g. Entra ID P1 for device access) and the plan can't change →
  record it as deferred and scope the labels to what you have; do not assume the control is active.
- A **classification/guest determination** is being asked of you (which data is "Highly Confidential,"
  who may be a guest) → escalate to compliance, data-owner, privacy, or legal. This solution provides the
  technical method and evidence, not the determination.
- A portal path or protection-settings page name **doesn't match your tenant** → the Purview portal is
  actively evolving; verify the current path in your tenant before assuming the guide is wrong about the
  *step*.
