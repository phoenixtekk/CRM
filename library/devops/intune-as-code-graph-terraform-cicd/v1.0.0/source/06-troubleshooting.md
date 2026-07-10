# 6. Troubleshooting — Intune-as-Code (Graph & Terraform, CI/CD)

Common failures during an Intune-as-code rollout, as **symptom → cause → fix**. Re-run `IACINTUNE-Validate.ps1` after any fix to re-check the gates.

## Authentication / permissions
**Symptom:** `Connect-MgGraph` or Terraform fails with `Authorization_RequestDenied` / `Insufficient privileges`.
**Cause:** The automation app is missing a required Graph **application** permission or admin consent (**R2**).
**Fix:** Add the required Graph application permissions (e.g. `DeviceManagementConfiguration.ReadWrite.All`, `DeviceManagementApps.ReadWrite.All`) and have an admin grant consent; re-run. *Verify the current minimum permission set.*

**Symptom:** Interactive auth works locally but the pipeline fails to authenticate.
**Cause:** CI/CD needs a non-interactive identity; delegated auth does not work headless (**R2/G4**).
**Fix:** Use workload identity federation (OIDC) or the app's client credential from the pipeline secret store — never a user login, never a secret in code.

## Terraform init / provider
**Symptom:** `terraform init` cannot find the Microsoft Graph provider, or the resource types in `main.tf` are unknown.
**Cause:** Wrong provider name/version, or the provider version does not model that Intune resource (**R3**).
**Fix:** *Verify the current provider source, version, and Intune resource coverage;* pin the validated version in the `terraform{}` block. For unsupported policy types, manage them via the PowerShell/Graph path instead of forcing an unsupported resource.

**Symptom:** `Error acquiring the state lock` / backend errors on init.
**Cause:** The remote state backend (`tfstate-intune`) is misconfigured or a previous run left a lock (**R5**).
**Fix:** Confirm the storage account/container and access; if a stale lock remains from a crashed run, release it deliberately (`terraform force-unlock <id>`) only after confirming no run is active.

## Plan / apply
**Symptom:** `terraform plan` shows unexpected **destroy** lines for policies you did not intend to remove.
**Cause:** A resource was renamed (Terraform sees delete+create), or state is out of sync with the tenant.
**Fix:** **Stop — do not apply.** For a rename, use `terraform state mv` / an import to reconcile; for stale state, import the existing policy. Re-plan until only intended changes remain.

**Symptom:** `apply` fails partway, leaving some policies created and others not.
**Cause:** A mid-apply Graph error (throttling, a bad value, a beta endpoint change).
**Fix:** Read the error, fix the offending resource, and re-`apply` — Terraform is idempotent and will converge. Check `/beta` endpoints for schema changes. *Verify whether the endpoint is beta.*

**Symptom:** Terraform reports "no changes" but the portal clearly differs.
**Cause:** The differing policy is **not actually managed** by Terraform (not in `main.tf`), or state is stale.
**Fix:** Add the policy to code and import it, or refresh state; unmanaged policies are invisible to plan by design.

## Drift
**Symptom:** Drift detection constantly flags changes nobody deliberately made.
**Cause:** Admins are still editing managed policies in the **portal**.
**Fix:** Enforce the operating-model change — managed policies are edited only through Git/the pipeline. Reconcile the current drift (into code or revert) and communicate the new process.

**Symptom:** A legitimate portal change needs to stay.
**Cause:** Someone made a valid change in the portal that should become the new baseline.
**Fix:** **Reconcile** it into `main.tf` (update the code to match), plan, review, and apply — so code and tenant agree again and the plan goes empty.

## Backup / restore
**Symptom:** `IACINTUNE-Report.ps1 -Backup` produces empty JSON files.
**Cause:** Read permissions missing, or the endpoint is `/beta` and unavailable (**R7**).
**Fix:** Confirm read scopes/consent and endpoint availability; *verify current beta endpoint paths.*

**Symptom:** You need to undo a bad production change fast.
**Cause:** A change reached production and is causing device impact.
**Fix:** Restore the affected policy from the most recent backup **or** revert the code change and re-apply through the pipeline (reviewed path). The pre-apply backup guarantees a restore point existed. Do not hand-edit in the portal — that creates drift.

## Assignments / devices
**Symptom:** A new policy applied to far more devices than intended.
**Cause:** It was assigned to All Devices/All Users instead of the pilot ring (Test 4 fail).
**Fix:** Change the assignment in code to `Intune-Pilot – Devices – Ring0`, plan, and re-apply; widen assignments only after the pilot is healthy.

**Symptom:** A pilot device does not receive a policy.
**Cause:** Device not in the pilot group, not licensed, or Intune has not yet delivered policy.
**Fix:** Confirm group membership and licensing (**R1/R6**), force a sync, and allow time for delivery.

## Pipeline
**Symptom:** The Apply stage runs without pausing for approval, or without a backup.
**Cause:** The `intune-prod` environment approval check is missing, or the pre-apply backup step was removed (**R7**).
**Fix:** Attach required reviewers to the `intune-prod` environment and confirm the deployment job runs the backup step before apply (Test 8).
