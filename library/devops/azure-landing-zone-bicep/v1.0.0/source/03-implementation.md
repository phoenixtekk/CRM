# 3. Implementation — Azure Landing Zone with Bicep

Follow these steps in order. Everything is **pilot-first**: you deploy against a **non-production** management group with policy in **audit**, validate, then expand to production behind pipeline approval and promote guardrails to **deny**. Every object you create is named with the convention **`<Purpose> – <Scope> – <Stage>`** and that exact name is reused in later steps, testing, and the scripts. Placeholder tenant is `contoso.com` / `contoso.onmicrosoft.com`.

> Run every apply with **`what-if` first**. Never run an unreviewed apply against production. All examples use the Azure CLI; the pipeline runs the same commands.

## Naming you will create (reuse these exact names)
| Object | Name |
|---|---|
| Intermediate root management group | `alz` (display: `Landing Zone – Tenant – Root`) |
| Platform management group | `Platform – Tenant – Prod` |
| Landing-zones management group | `Landing Zones – Tenant – Prod` |
| Sandbox / non-prod management group | `Sandbox – Tenant – NonProd` |
| Guardrail initiative assignment | `Guardrails Baseline – Landing Zones – Audit` (later `…– Deny`) |
| Custom RBAC role | `Landing Zone Contributor – Platform – Baseline` |
| Hub virtual network | `Hub Network – Connectivity – Prod` |
| First spoke virtual network | `Spoke Network – Workload01 – NonProd` |
| Deployment stack (non-prod) | `alz-stack – Sandbox – NonProd` |
| Deployment stack (prod) | `alz-stack – Platform – Prod` |
| Pipeline | `Landing Zone Pipeline – Platform – CICD` |

## Step 1 — Assess: inventory the current estate (read-only)
1. Sign in: `az login` (add `--tenant contoso.onmicrosoft.com` if you have several).
2. Set the working subscription: `az account set --subscription "<non-prod sub id>"`.
3. Run the discovery script from the `scripts/` folder:
   `powershell -ExecutionPolicy Bypass -File .\IACBICEP-Discovery.ps1`
   It reports existing management groups, policy assignments, custom roles, standing **Owner** assignments, and existing VNet address ranges. Save the output — it is your baseline and your address-overlap check for **R5**.
4. Confirm your identity has the rights from **R1** at the intermediate group.

## Step 2 — Configure: scaffold the Bicep repo
1. Clone the empty repo created in Global Requirements G3 and add the provided files at the root:
   - `main.bicep` — the landing-zone template (entry point).
   - `azure-pipelines.yml` — the CI/CD pipeline.
   - `IACBICEP-Discovery.ps1`, `IACBICEP-Validate.ps1`, `IACBICEP-Report.ps1` under `scripts/`.
2. Create a `bicepconfig.json` and pin the Bicep version (**R2**), and a parameters file (`main.nonprod.bicepparam` and `main.prod.bicepparam`) holding your naming prefixes, tag set, address ranges (**R5/R6**), and the target management-group IDs.
3. Commit to a **feature branch** and open a pull request — infrastructure changes are reviewed, never pushed straight to `main` (Global Requirements G3 branch protection).

## Step 3 — Configure: deploy the management-group hierarchy (non-prod first)
1. Preview with what-if at tenant/management-group scope:
   `az deployment mg what-if --management-group-id alz --location eastus --template-file main.bicep --parameters main.nonprod.bicepparam --parameters deployHierarchy=true`
2. Read the preview. It should show the creation of `Platform – Tenant – Prod`, `Landing Zones – Tenant – Prod`, and `Sandbox – Tenant – NonProd` under `alz`.
3. Deploy the hierarchy as a deployment stack (non-prod scope):
   `az stack mg create --name "alz-stack – Sandbox – NonProd" --management-group-id alz --location eastus --template-file main.bicep --parameters main.nonprod.bicepparam --parameters deployHierarchy=true --deny-settings-mode denyDelete --action-on-unmanage detachAll`
4. Verify in the portal: **Management groups** now shows the tree.

## Step 4 — Configure: assign policy guardrails in AUDIT
1. What-if the policy assignment scoped to `Landing Zones – Tenant – Prod`:
   `az deployment mg what-if --management-group-id alz --location eastus --template-file main.bicep --parameters main.nonprod.bicepparam --parameters deployPolicy=true policyEffect=Audit`
2. Deploy it (updates the same stack). This creates the initiative assignment **`Guardrails Baseline – Landing Zones – Audit`** — require encryption, block public storage, allowed locations, allowed SKUs, require tags — all in **audit** effect.
3. Confirm under **Policy → Assignments** at the management-group scope that the assignment exists and its effect is **Audit**. Do **not** move to deny yet.

## Step 5 — Configure: apply the identity / RBAC baseline
1. What-if the RBAC module, then deploy it. It creates the custom role **`Landing Zone Contributor – Platform – Baseline`** (narrow actions, no `Microsoft.Authorization/*/write`) and assigns it at `Platform – Tenant – Prod`.
2. Review existing standing **Owner** assignments from the Step 1 discovery output. Plan their removal (do this in a controlled change — removing your own Owner mid-deploy can lock you out).
3. Where **Entra ID P2** is licensed, configure the eligible (PIM) assignments the Bicep references. *Verify current PIM availability and licensing in your tenant.*

## Step 6 — Configure: deploy hub-spoke networking and DNS (non-prod)
1. What-if the network module with your **R5** address ranges:
   `az deployment sub what-if --subscription "<non-prod sub id>" --location eastus --template-file main.bicep --parameters main.nonprod.bicepparam --parameters deployNetwork=true`
2. Deploy it. This creates **`Hub Network – Connectivity – Prod`** (with `GatewaySubnet`, `AzureFirewallSubnet`, and a shared-services subnet), the first spoke **`Spoke Network – Workload01 – NonProd`**, the hub↔spoke **peerings**, and the **private DNS zones** (e.g. `privatelink.blob.core.windows.net`) linked to the hub.
3. Confirm peering status is **Connected** in the portal (**Virtual networks → Peerings**).

## Step 7 — Pilot: validate the non-prod landing zone
1. Run the validation script (what-if / read-only):
   `powershell -ExecutionPolicy Bypass -File .\IACBICEP-Validate.ps1 -ManagementGroupId alz -Environment NonProd`
   It confirms the hierarchy exists, the guardrail assignment is present in **Audit**, the custom role is assigned, and peerings are Connected — see the **Testing** guide for pass/fail gates.
2. Run a policy compliance scan and review audit findings (`az policy state trigger-scan`). Exempt any legitimate false positives before you ever consider deny.
3. Generate the posture report: `powershell -ExecutionPolicy Bypass -File .\IACBICEP-Report.ps1 -ManagementGroupId alz`.

## Step 8 — Wire the CI/CD pipeline (what-if → approval → deploy)
1. In Azure DevOps (or GitHub), create the pipeline **`Landing Zone Pipeline – Platform – CICD`** from `azure-pipelines.yml`.
2. Confirm the **service connection** uses workload identity federation (Global Requirements G4) and the **`Prod` environment** has the approval gate and reviewer group from **R7**.
3. The pipeline stages are: **Validate** (lint/build Bicep) → **What-If** (posts the preview to the PR) → **Approval** (manual gate) → **Deploy** (deployment stack). Merging to `main` triggers Validate + What-If; the Deploy stage only runs after approval.

## Step 9 — Expand: deploy to production, then promote guardrails to DENY
1. With `main.prod.bicepparam`, let the pipeline run **Validate → What-If** against production. Review the what-if output in the PR.
2. Approve the gate. The pipeline deploys the production stack **`alz-stack – Platform – Prod`**.
3. Only after production has run cleanly in **audit** for your agreed soak period, change the policy effect to deny: re-run with `policyEffect=Deny`, review the what-if, and approve. The assignment becomes **`Guardrails Baseline – Landing Zones – Deny`**.
4. **Rollback** at any point: `az stack mg delete/update` on the named stack removes or reverts exactly what it deployed (use `--action-on-unmanage detachAll` to leave resources in place while detaching stack management).

> Onboard each new subscription by moving it under `Landing Zones – Tenant – Prod` and adding a spoke to the parameters — it inherits policy, RBAC, and connectivity automatically. That is the repeatable payoff of the landing zone.
