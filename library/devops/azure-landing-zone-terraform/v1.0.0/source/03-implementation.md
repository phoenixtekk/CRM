# 3. Implementation Guide — Azure Landing Zone with Terraform

Follow these steps **in order**. Work in your **Git repository** (the Terraform code), the **Azure CLI /
portal** (bootstrap + verification), and the **CI/CD pipeline** (plan → approve → apply). Names in `code`
are the exact objects to create — keep them consistent so the Terraform, pipeline, and helper scripts all
refer to the same objects. Provider/module versions are **pinned and flagged "verify"** — confirm current
supported versions before applying.

**Object naming convention:** `<purpose>-<scope>-<stage>` (Azure resource naming). The objects you build:

| Object | Name |
|--------|------|
| Root management group | `mg-corp-root` |
| Platform MGs | `mg-platform` → `mg-identity`, `mg-management`, `mg-connectivity` |
| Landing-zone MGs | `mg-landingzones` → `mg-corp`, `mg-online` |
| Sandbox / decommissioned | `mg-sandbox`, `mg-decommissioned` |
| State backend RG / storage | `rg-iactf-tfstate` / `stiactftfstate<unique>` (container `tfstate`) |
| Policy assignment (regions) | `IACTF-Policy-AllowedRegions-Root` |
| Policy assignment (tags) | `IACTF-Policy-RequireTags-LandingZones` |
| Log Analytics workspace | `log-iactf-management` |
| Hub network RG / VNet | `rg-iactf-hub` / `vnet-hub-eastus` |
| Spoke network RG / VNet | `rg-iactf-spoke-corp` / `vnet-spoke-corp-eastus` |
| CI/CD service connection | `sc-iactf-oidc` |
| Pipeline | `IACTF-Pipeline-Plan-Apply` |

> **Model:** Assess → Configure → **Pilot against `mg-sandbox` / non-prod first** → Validate the gates →
> Expand to production behind the approval gate. Everything is **`terraform plan` / what-if first**. Every
> production `apply` is approval-gated. Rollback guidance is at the end.

## Step 1 — Assess: baseline the current estate
1. Run **`IACTF-Discovery.ps1`** — inventories the current management-group hierarchy, subscriptions,
   existing policy assignments, and role assignments, and confirms your effective rights at root.
2. Record what already exists so the Terraform imports/avoids it (don't recreate the Tenant Root Group).
3. Confirm the requirements checklist (§2), especially **elevated rights at root** and the **standards**.

## Step 2 — Bootstrap the remote state backend (one-time, outside the pipeline)
1. Create the state backend with the CLI (this must exist before `terraform init`):
   ```
   az group create -n rg-iactf-tfstate -l eastus
   az storage account create -n stiactftfstate<unique> -g rg-iactf-tfstate -l eastus \
       --sku Standard_LRS --min-tls-version TLS1_2 --allow-blob-public-access false
   az storage account blob-service-properties update -n stiactftfstate<unique> \
       -g rg-iactf-tfstate --enable-versioning true
   az storage container create -n tfstate --account-name stiactftfstate<unique> --auth-mode login
   ```
2. Grant the deploy identity **Storage Blob Data Contributor** on the storage account.
3. Run **`IACTF-Validate.ps1 -BackendOnly`** to confirm the backend is reachable.

## Step 3 — Configure: author the Terraform and pin versions
1. In your repo, add the provided **`main.tf`** (management groups, policy assignments, RBAC baseline,
   hub-spoke networking, Log Analytics, and the `backend "azurerm"` block pointing at Step 2).
2. Set your inputs in `variables.tf` / `terraform.tfvars`: allowed regions, required tags, the root
   management-group display name, and network address spaces — from your **standard** (§2.5).
3. **Pin** `required_version` and each provider `version` in the `terraform`/`required_providers` block;
   run `terraform init` and **commit `.terraform.lock.hcl`**. *Verify the pinned provider/module versions
   against the registry first.*

## Step 4 — Pilot: plan and apply against the non-production scope
1. Point the workspace at the **non-prod** target (`mg-sandbox` or a sandbox subscription) via a variable.
2. Run `terraform plan -out tfplan` **locally or in the pipeline's plan stage** and **read the what-if**:
   confirm it will create `mg-corp-root` and children, the **audit-mode** policy assignments, the RBAC
   baseline, `log-iactf-management`, and the hub/spoke VNets — and **nothing unexpected**.
3. Apply to the pilot scope: `terraform apply tfplan`.
4. **Keep policy in audit first:** ensure `IACTF-Policy-AllowedRegions-Root` and
   `IACTF-Policy-RequireTags-LandingZones` deploy with effect **`Audit`/`Disabled`** at this stage — do
   **not** start in `Deny`.

## Step 5 — Wire the CI/CD pipeline (plan → approve → apply)
1. Add the provided **`azure-pipelines.yml`** to the repo; create the pipeline `IACTF-Pipeline-Plan-Apply`.
2. Configure the **federated (OIDC) service connection** `sc-iactf-oidc` scoped to the target management
   group (no stored secret).
3. The pipeline runs **`terraform plan`** on pull requests / the `plan` stage and publishes the plan as an
   artifact; the **`apply`** stage is gated by a **manual approval / environment check**.
4. Add a **scheduled** trigger that runs `plan` (drift detection) and fails/reports if the plan is
   non-empty (out-of-band drift).

## Step 6 — Validate the pilot (the gates)
Run **`IACTF-Validate.ps1`** and **`IACTF-Report.ps1`** and confirm:
- **G1 Plan is clean & reviewed** — `terraform plan` produces the expected what-if and **no** unexpected
  destroys; the plan was reviewed in a PR.
- **G2 State locks** — a second concurrent `apply` is **blocked** by the blob lease (state locking works).
- **G3 Policy inherits (in audit)** — `IACTF-Report.ps1` shows the policy assignments present at the MG
  scope and reporting **compliance** (audit), inherited by child scopes.
- **G4 Pipeline gate** — the `apply` stage **waits for approval**; the scheduled `plan` reports **no
  drift** on an unchanged environment.

**Pass** = all four gates green. **Fail** = fix before promoting to production (see §6).

## Step 7 — Expand: promote to production in waves
1. **Promote guardrails to enforce:** change the policy assignment effects from **`Audit`** to **`Deny`**
   (allowed-regions, required-tags) **one at a time**, re-plan, and apply — after confirming
   `IACTF-Report.ps1` shows no legitimate resources would be blocked.
2. **Vend production subscriptions:** use the subscription-vending pattern to place new subscriptions
   into `mg-corp` / `mg-online` with baseline policy/RBAC/networking inherited.
3. **Add spokes:** peer new `vnet-spoke-*` VNets to `vnet-hub-eastus` for each workload landing zone.
4. Run every change as a **reviewed PR → `plan` → approval → `apply`**; re-run `IACTF-Report.ps1` after
   each wave to capture the governance/compliance state.

> **Rollback (any step):** Terraform is your rollback — **revert the commit** and `apply` the previous
> known-good state, or `terraform plan`/`apply` a targeted change to restore. For a bad **policy `Deny`**,
> set the assignment effect back to **`Audit`** and re-apply. **Never** hand-edit resources in the portal
> to "fix" drift — that widens the gap between state and reality; correct it in code and re-apply. Root
> management-group and subscription-vending changes are **high-impact** — do them under change control.

---
### Order of operations
`Assess (Discovery) → bootstrap state backend → author + pin Terraform → plan/apply to non-prod (policy
in audit) → wire pipeline (plan→approve→apply + scheduled drift) → validate the 4 gates → promote policy
to Deny + vend prod subscriptions in waves`
