# 3. Implementation — Intune-as-Code (Graph & Terraform, CI/CD)

Follow these steps in order. Everything is **pilot-first**: you export the current tenant, model a scoped set of policies as code, plan and apply against a **dev tenant or a pilot group** with a backup taken first, validate, then promote to production behind approval and widen assignments. Every object you create is named with the convention **`<Purpose> – <Scope> – <Stage>`** and that exact name is reused in later steps, testing, and the scripts. Placeholder tenant is `contoso.onmicrosoft.com`.

> Run every change with **`terraform plan` first**. Never `apply` to production without an approved plan. Take a **backup** before any apply that changes production.

## Naming you will create (reuse these exact names)
| Object | Name |
|---|---|
| Automation app registration (SPN) | `Intune-as-Code – Automation – SPN` |
| Pilot assignment group | `Intune-Pilot – Devices – Ring0` |
| Windows config profile (code) | `Windows Baseline – Corporate – Config` |
| Compliance policy (code) | `Compliance Minimum – Corporate – Compliance` |
| App-protection policy (code) | `App Protection – Mobile – MAM` |
| Terraform workspace — dev | `intune – Dev – Workspace` |
| Terraform workspace — prod | `intune – Prod – Workspace` |
| State container | `tfstate-intune` |
| Pipeline | `Intune-as-Code Pipeline – Endpoint – CICD` |
| Backup export folder | `backups/<yyyy-MM-dd>/` |

## Step 1 — Assess: export the current tenant to code (read-only baseline)
1. Sign in the automation identity for reading: `Connect-MgGraph` (or use the app credential from **R2**).
2. Run the export/discovery script from `scripts/`:
   `powershell -ExecutionPolicy Bypass -File .\IACINTUNE-Discovery.ps1 -OutputPath .\baseline`
   It reads existing **device configuration**, **compliance**, and **app-protection** policies to JSON under `.\baseline` and prints a summary count. This is your baseline and your first backup.
3. Review the exported JSON. Pick a **scoped starter set** to codify first — e.g. one Windows config profile, one compliance policy, one app-protection policy — rather than the whole tenant on day one.

## Step 2 — Configure: register the automation identity
1. Confirm the app registration **`Intune-as-Code – Automation – SPN`** exists with the Graph application permissions and admin consent (**R2**).
2. Store its credential in Key Vault / the pipeline secret store (never in code). For local runs, set the standard `ARM_CLIENT_ID` / `ARM_TENANT_ID` (and the client secret or OIDC) environment variables the Terraform provider reads.
3. Confirm the `Microsoft.Graph` PowerShell module (**R4**) and Terraform CLI + pinned Graph provider (**R3**) are installed.

## Step 3 — Configure: scaffold the Terraform repo
1. In the repo, add the provided files: `main.tf` (policy definitions), `versions.tf` (pinned provider + backend), and `azure-pipelines.yml`; put `IACINTUNE-Discovery.ps1`, `IACINTUNE-Validate.ps1`, and `IACINTUNE-Report.ps1` under `scripts/`.
2. Configure the **remote state backend** (`tfstate-intune` container, **R5**) in `versions.tf` and run `terraform init`.
3. Create two workspaces: `terraform workspace new "intune – Dev – Workspace"` and `terraform workspace new "intune – Prod – Workspace"` so dev and prod state never mix.
4. Translate your scoped starter set from the baseline JSON into Terraform resources in `main.tf`, using the names above (`Windows Baseline – Corporate – Config`, etc.). Assign them to **`Intune-Pilot – Devices – Ring0`** only.
5. Commit to a **feature branch** and open a pull request — Intune changes are reviewed, never pushed straight to `main`.

## Step 4 — Pilot: plan and apply to dev / pilot group (backup first)
1. Take a backup: `powershell -ExecutionPolicy Bypass -File .\IACINTUNE-Report.ps1 -Backup -OutputPath .\backups`.
2. Select the dev workspace: `terraform workspace select "intune – Dev – Workspace"`.
3. **Plan (the preview):** `terraform plan -out tfplan`. Read it — it must show only the intended creates/changes for your starter set, assigned to the pilot group. **No unexpected destroys.**
4. Apply to dev / pilot: `terraform apply tfplan`.
5. In the Intune admin center (**Devices → Configuration** / **Compliance** / **Apps**) confirm the three named policies exist and are assigned to `Intune-Pilot – Devices – Ring0`.

## Step 5 — Validate: confirm the pilot
1. Run the validation script:
   `powershell -ExecutionPolicy Bypass -File .\IACINTUNE-Validate.ps1 -PilotGroup "Intune-Pilot – Devices – Ring0"`
   It confirms the three policies exist, are assigned to the pilot group only, and that a fresh `terraform plan` shows **no drift** — see the **Testing** guide for pass/fail gates.
2. On a pilot device, confirm the config/compliance/app-protection policies apply as expected (sync from **Company Portal** / **Settings → Accounts → Access work or school**).
3. Resolve any issues and re-plan until clean before promoting.

## Step 6 — Wire the CI/CD pipeline (validate → plan → approval → apply)
1. Create the pipeline **`Intune-as-Code Pipeline – Endpoint – CICD`** from `azure-pipelines.yml`.
2. Confirm the **service connection** uses workload identity federation (or the app credential from the secret store) and the **`intune-prod` environment** has the approval gate and reviewer group from **R7**.
3. The stages are: **Validate** (`terraform fmt`/`validate`) → **Plan** (posts the plan to the PR) → **Approval** (manual gate) → **Apply**. PRs run Validate + Plan; Apply only runs after approval.

## Step 7 — Expand: promote to production, then widen assignments
1. Merge to `main`. The pipeline runs **Validate → Plan** against the **prod** workspace. Review the plan in the PR.
2. **Back up production first** (the pipeline's pre-apply step runs `IACINTUNE-Report.ps1 -Backup`), then approve the gate. The pipeline runs `terraform apply` against `intune – Prod – Workspace`.
3. Widen assignments in stages: after the pilot ring is healthy, add broader groups to the policy assignments **in code**, plan, review, and apply — never by editing the portal.
4. **Rollback** at any point: restore the affected policy from the most recent backup (`IACINTUNE-Report.ps1 -Restore`), or revert the code change and re-apply.

## Step 8 — Operate: schedule drift detection and backup
1. Schedule a periodic pipeline run (or `IACINTUNE-Report.ps1 -DriftCheck`) that runs `terraform plan` with **no code change** — any non-empty plan is **drift** (a portal edit made outside the pipeline).
2. For each drift item, decide: **reconcile** (bring the portal change into code) or **revert** (re-apply code to overwrite it). Do not ignore drift — it is the signal that someone bypassed the pipeline.
3. Keep the scheduled **backup** running so a restore point always exists.

> Onboard each new policy the same way: model it in `main.tf`, assign to the pilot ring, plan, review, apply, then widen. That repeatable loop is the payoff — Intune managed like software.
