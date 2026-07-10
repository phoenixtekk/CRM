# 5. Testing — Intune-as-Code (Graph & Terraform, CI/CD)

Validate against a **dev tenant or the pilot group** before you promote to production. Each test has an explicit **pass/fail gate**. Reference the scripts by name; they are read-only / plan-only except the explicit backup/apply steps.

## Test 1 — Baseline export is complete
- **How:** `powershell -ExecutionPolicy Bypass -File .\IACINTUNE-Discovery.ps1 -OutputPath .\baseline`, then inspect `.\baseline`.
- **Pass:** JSON files exist for device configuration, compliance, and app-protection policies; the printed counts match what you see in the Intune admin center.
- **Fail:** Counts mismatch or empty → check the app's Graph permissions/admin consent (**R2**) and that `Connect-MgGraph` used the right identity.

## Test 2 — Terraform initializes and validates
- **How:** `terraform init` then `terraform validate` and `terraform fmt -check`.
- **Pass:** `init` downloads the **pinned** Graph provider from `versions.tf`; `validate` returns success; formatting is clean.
- **Fail:** Provider not found → check the pinned provider name/version (**R3**). Backend error → check the `tfstate-intune` backend config (**R5**).

## Test 3 — Plan shows only intended changes (no surprise destroys)
- **How:** `terraform workspace select "intune – Dev – Workspace"` then `terraform plan -out tfplan`.
- **Pass:** The plan shows only the creates/changes for your starter set (`Windows Baseline – Corporate – Config`, `Compliance Minimum – Corporate – Compliance`, `App Protection – Mobile – MAM`), assigned to the pilot group. **Zero unexpected `destroy` lines.**
- **Fail:** A `destroy` you did not intend → **stop**; usually a renamed resource or missing/incorrect state. Reconcile before applying.

## Test 4 — Policies exist and are pilot-scoped
- **How:** `powershell -ExecutionPolicy Bypass -File .\IACINTUNE-Validate.ps1 -PilotGroup "Intune-Pilot – Devices – Ring0"`, or the Intune admin center.
- **Pass:** The three named policies exist and are assigned **only** to `Intune-Pilot – Devices – Ring0` (not All Devices / All Users).
- **Fail:** Assigned to a broad group during pilot → fix the assignment in code, plan, and re-apply. Missing policy → re-run Step 4's apply.

## Test 5 — Policy applies on a pilot device
- **How:** On an enrolled pilot device, sync (Company Portal / Access work or school) and check the config/compliance/app-protection result.
- **Pass:** The device receives the profiles; compliance evaluates; app-protection applies to the targeted app.
- **Fail:** Not applied → confirm the device is a member of the pilot group and licensed; allow time for Intune to deliver policy.

## Test 6 — Drift detection works
- **How:** Make a small **portal** edit to one managed policy, then run `IACINTUNE-Report.ps1 -DriftCheck` (or `terraform plan`).
- **Pass:** The plan is **non-empty** and shows the portal edit as a pending change back to the coded value — drift is detected.
- **Fail:** Plan stays empty after a real portal change → state is stale or the resource is not actually managed; check the backend (**R5**) and that the policy is in `main.tf`.

## Test 7 — Backup and restore round-trip
- **How:** `IACINTUNE-Report.ps1 -Backup -OutputPath .\backups`, then verify a `-Restore` dry run reads it back.
- **Pass:** A timestamped backup folder contains the policy JSON; the restore dry run reports it would recreate the exported policies.
- **Fail:** Backup empty or restore cannot parse → check the output path permissions and that the export completed (**R7**).

## Test 8 — Pipeline enforces plan and approval
- **How:** Push a trivial change on a branch; open a PR; watch the pipeline.
- **Pass:** **Validate** and **Plan** run automatically and post the plan; the **Apply** stage **pauses at the approval gate** (**R7**) and the pre-apply **backup** runs before any apply.
- **Fail:** Apply runs without pausing → the environment approval check is not attached to the apply stage; fix the `intune-prod` environment configuration.

## Exit criteria
All eight tests pass against dev / the pilot group, the plan is clean, drift is detected, backup/restore works, and the pipeline pauses for approval — **only then** promote to production and widen assignments.
