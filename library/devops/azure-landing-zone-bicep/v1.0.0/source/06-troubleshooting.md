# 6. Troubleshooting — Azure Landing Zone with Bicep

Common failures during a Bicep landing-zone rollout, as **symptom → cause → fix**. Re-run `IACBICEP-Validate.ps1` after any fix to re-check the gates.

## Deployment authorization / scope
**Symptom:** `AuthorizationFailed` or `does not have permission to perform action 'Microsoft.Management/managementGroups/write'` on the hierarchy deploy.
**Cause:** The identity lacks Owner (or Contributor + User Access Administrator) at the intermediate management group (**R1**).
**Fix:** Have a Global Administrator grant the role at `alz`; confirm with `az account management-group list` and re-run Step 3's what-if.

**Symptom:** `MissingSubscriptionRegistration` for `Microsoft.Network` / `Microsoft.Authorization`.
**Cause:** The resource provider is not registered on the target subscription (**R4**).
**Fix:** `az provider register --namespace Microsoft.Network`; registration is async — wait for `Registered`, then redeploy.

## Bicep build / what-if
**Symptom:** `az bicep build` fails or `az stack` is "not a recognized command".
**Cause:** Bicep / Azure CLI too old, or the version is not pinned (**R2/R3**).
**Fix:** `az bicep upgrade` and update the CLI; pin versions in `bicepconfig.json`. *Verify current supported versions.*

**Symptom:** `what-if` shows unexpected **Delete** or **Modify** on resources you did not intend to change.
**Cause:** A parameter changed a name (so ARM sees a replace), or someone edited a stack-managed resource in the portal (drift).
**Fix:** **Stop — do not approve.** Diff the parameter files, run `IACBICEP-Report.ps1` for drift, reconcile, then re-what-if until the preview is clean.

## Deployment stacks / rollback
**Symptom:** Stack update fails with `denyAssignment` blocking a change.
**Cause:** The stack's `denyDelete`/deny-settings are protecting managed resources from out-of-band change — working as intended.
**Fix:** Make the change **through the stack** (update the Bicep + redeploy the stack), not directly on the resource.

**Symptom:** `az stack mg show` reports the stack is missing after you deployed.
**Cause:** You deployed with `az deployment mg create` instead of `az stack mg create`, so there is no stack (and no rollback unit) — Test 7 fail.
**Fix:** Redeploy via `az stack mg create` with the named stack so the resources are tracked and rollback is available.

## Policy
**Symptom:** A brand-new guardrail shows every resource as **NonCompliant** immediately, alarming stakeholders.
**Cause:** The assignment is in **Audit** (correct) but the compliance scan surfaced the true current state — this is the point of audit-before-deny.
**Fix:** Triage findings, fix real issues, and **exempt** legitimate cases before promoting to deny. Never move to deny with an un-triaged audit picture.

**Symptom:** Compliance state stays `NotStarted` / `Unknown` after assignment.
**Cause:** Policy evaluation is not instantaneous.
**Fix:** `az policy state trigger-scan --management-group alz`, wait, then re-run `IACBICEP-Report.ps1`.

**Symptom:** A legitimate production deployment starts failing after you promoted guardrails to **Deny**.
**Cause:** A deny policy is now blocking a real, allowed pattern that was only visible as an audit finding before.
**Fix:** Revert the effect to Audit (re-run with `policyEffect=Audit`), fix or exempt the pattern, then re-promote. This is why the model soaks in audit first.

## RBAC / identity
**Symptom:** You lose access mid-deployment after the RBAC step.
**Cause:** Removing standing **Owner** included your own account.
**Fix:** Restore access via the documented break-glass account; always exclude break-glass from Owner-removal and stage RBAC changes carefully (Step 5).

**Symptom:** PIM-eligible assignment in the Bicep fails to create.
**Cause:** **Entra ID P2** not licensed, or PIM not enabled in the tenant.
**Fix:** *Verify PIM availability and licensing in your tenant.* Fall back to a scoped standing assignment of the least-privilege custom role until P2 is in place.

## Networking
**Symptom:** Hub↔spoke peering shows **Disconnected** / one-sided.
**Cause:** Overlapping address spaces or only one direction of the peering was created (**R5**).
**Fix:** Confirm non-overlapping CIDRs from the discovery output, ensure both peering directions exist, and redeploy the network module.

**Symptom:** Private-endpoint DNS does not resolve from a spoke.
**Cause:** The private DNS zone is linked to the hub but not reachable from the spoke, or the zone name is wrong.
**Fix:** Verify the private DNS zone name (e.g. `privatelink.blob.core.windows.net`), confirm the VNet link and that spoke traffic routes through the hub, then re-test resolution.

## Pipeline
**Symptom:** The Deploy stage runs without pausing for approval.
**Cause:** The Environment approval check (required reviewers) is not attached to the production stage (**R7**).
**Fix:** Add required reviewers to the `landing-zone-prod` Environment and confirm the deploy job references `environment:` — re-run the pipeline (Test 8).

**Symptom:** Pipeline auth fails with a token/credential error.
**Cause:** The service connection is not configured for workload identity federation, or the federated credential subject/scope is wrong (**G4**).
**Fix:** Reconfigure the service connection for OIDC/workload identity federation and scope it to the deployment target; never fall back to a stored secret.
