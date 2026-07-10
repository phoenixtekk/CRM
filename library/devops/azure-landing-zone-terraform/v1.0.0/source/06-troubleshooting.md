# 6. Troubleshooting — Azure Landing Zone with Terraform

Symptom → likely root cause → fix. Start with **`IACTF-Discovery.ps1`** (what exists + your rights) and
**`IACTF-Validate.ps1`** (backend + plan/drift) — most failures are a state-backend problem, insufficient
rights at the management-group scope, a version drift, or a policy `Deny` blocking a legitimate resource.

## `terraform init` fails on the backend
- **Root cause:** the state storage account/container doesn't exist yet, the deploy identity lacks
  **Storage Blob Data Contributor**, or the `backend "azurerm"` block points at the wrong
  account/container.
- **Fix:** confirm Step 2 bootstrap ran (RG `rg-iactf-tfstate`, storage `stiactftfstate<unique>`,
  container `tfstate`); grant the identity blob-data access; verify the backend block values. Run
  **`IACTF-Validate.ps1 -BackendOnly`**.

## "Error acquiring the state lock" / apply hangs on lock
- **Root cause:** another `apply` holds the blob lease, or a previous run crashed and left a stale lock.
- **Fix:** wait for the other run to finish (locking is working as intended). Only if you're certain no
  run is active, break the lease on the state blob (or `terraform force-unlock <ID>`) — **never** during a
  live apply.

## `plan`/`apply` fails with authorization / "does not have permission" at MG scope
- **Root cause:** the identity lacks **Owner / User Access Administrator + Management Group Contributor**
  at the target management group (subscription-only rights aren't enough to create MGs or assign
  inherited policy/RBAC).
- **Fix:** assign the needed roles at the target MG (or elevate at root via **Access management for Azure
  resources** for the one-time hierarchy creation, then remove). `IACTF-Discovery.ps1` reports effective
  rights.

## Provider/plugin version errors or an unexpected plan after `init -upgrade`
- **Root cause:** provider or module versions **floated** (not pinned / lock file not committed), changing
  plan behavior mid-rollout.
- **Fix:** pin `required_version` and each provider `version`, commit **`.terraform.lock.hcl`**, and run
  `terraform init` without `-upgrade` in CI. Upgrade versions deliberately in their own reviewed PR.
  *Verify supported versions against the registry.*

## Policy assignment is blocking a legitimate deployment (`RequestDisallowedByPolicy`)
- **Root cause:** a guardrail was promoted to **`Deny`** too early, or its parameters (allowed regions /
  required tags) are stricter than intended.
- **Fix:** set the assignment effect back to **`Audit`**, re-apply, and confirm with `IACTF-Report.ps1`
  what would be blocked; correct the parameters, then re-promote to `Deny` once clean. Audit-before-Deny
  is the rule.

## Policy shows "not started" / no compliance results
- **Root cause:** compliance evaluation hasn't run yet (it's periodic), or the assignment scope doesn't
  cover the resources.
- **Fix:** trigger an on-demand scan (`az policy state trigger-scan`) or wait for the evaluation cycle;
  confirm the assignment scope (`IACTF-Report.ps1`). Newly-assigned policy can take time to report.

## Management group changes don't appear / hierarchy looks wrong
- **Root cause:** management-group operations are eventually consistent and can lag; or the Terraform
  created a parallel structure instead of using the existing root.
- **Fix:** re-run `IACTF-Discovery.ps1` after a short wait; ensure the code references the **existing**
  Tenant Root Group as parent rather than recreating it. Don't duplicate the root.

## Pipeline can't authenticate to Azure (OIDC)
- **Root cause:** the federated **service connection** `sc-iactf-oidc` isn't configured for workload
  identity federation, the federated credential subject/issuer doesn't match the pipeline, or the
  connection lacks a role at the target scope.
- **Fix:** confirm the service connection uses **workload identity federation** (not a secret), the
  federated credential matches the pipeline's subject, and the identity has the needed role at the target
  MG. Re-run the `plan` stage.

## The `apply` stage ran without approval
- **Root cause:** the pipeline environment/stage has **no approval check**, or the approval was applied to
  the wrong environment.
- **Fix:** add a **manual approval / environment check** to the `apply` stage's environment in
  `azure-pipelines.yml`; verify the `plan` and `apply` stages are separated with the gate between them.

## VNet peering fails
- **Root cause:** **overlapping address spaces** between hub and spoke, or the peering was created only on
  one side.
- **Fix:** ensure hub/spoke address ranges don't overlap; create peering **both directions** (the module
  does this — confirm both `hub→spoke` and `spoke→hub` resources applied). Re-plan.

## Scheduled `plan` reports drift you didn't make
- **Root cause:** someone changed a resource **in the portal** (out-of-band), or a provider default
  changed after a version bump.
- **Fix:** reconcile by **re-applying the code** (restores desired state) — don't "fix" it in the portal.
  If a provider default changed, review the diff and update the code intentionally. This is drift
  detection doing its job.

---
### First moves for any landing-zone issue
1. `IACTF-Discovery.ps1` — what exists, and do you have rights at the target MG scope?
2. `IACTF-Validate.ps1` — is the backend reachable/locked, and does `plan` show unexpected changes/drift?
3. `IACTF-Report.ps1` — are policy assignments present and in the expected effect (Audit vs Deny)?
4. Only then change configuration — **`plan` first**, review the what-if, and keep the prior commit as
   your rollback (revert + apply).
