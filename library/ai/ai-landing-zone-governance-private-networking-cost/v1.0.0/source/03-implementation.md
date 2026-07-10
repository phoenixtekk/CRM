# Implementation — AI Landing Zone & Governance (Private Networking, Content Safety, Cost)

This is the exact, ordered build. Every object you create is **named** with the convention
`<purpose>-ailz-<scope/service>-<stage>` (resources) or `Policy-<Control>-AILZ` (policy assignments),
and the **same name is reused** in later steps, testing, and the IaC. Everything is
**plan/what-if-first**: `terraform plan` (or ARM `what-if`) precedes every apply, and you apply to a
**non-production scope before production**, with the **policy guardrails in audit (DoNotEnforce) mode**
until validated.

> **Before you start:** confirm the elevated deploy role (R1), the address plan (R2), the private-DNS
> strategy (R3), the allowed regions/models/tags (R4), provider registration (R5), the encrypted
> **remote state** backend (R6), the pinned OIDC toolchain (R7), and a non-prod scope (R8). Sign in
> with a **workload-identity-federated** pipeline identity — **never a client secret on a laptop**
> (category G2, G5).

**Named objects created in this guide (verbatim — reused everywhere):**

| Object | Name | What it is |
| --- | --- | --- |
| Resource group (hub) | `rg-ailz-hub-platform` | Hub network + private DNS + platform services |
| Resource group (AI spoke, pilot) | `rg-ailz-spoke-nonprod` | Pilot AI workload spoke |
| Hub VNet | `vnet-ailz-hub-platform` | Central connectivity + DNS |
| Spoke VNet | `vnet-ailz-spoke-nonprod` | AI workload network (pilot) |
| Subnet (private endpoints) | `snet-ailz-privateendpoints` | Holds the AI-service private endpoints |
| Subnet (AI workload) | `snet-ailz-aiworkload` | Compute/app that calls the AI services |
| VNet peering | `peer-ailz-hub-to-spoke` / `peer-ailz-spoke-to-hub` | Hub ⇄ spoke peering |
| Private DNS zone (OpenAI) | `privatelink.openai.azure.com` | Resolves Azure OpenAI to private IP |
| Private DNS zone (Cognitive/Content-Safety) | `privatelink.cognitiveservices.azure.com` | Resolves Cognitive Services / Content Safety |
| Private DNS zone (AI Search) | `privatelink.search.windows.net` | Resolves Azure AI Search |
| Private DNS zone (Key Vault) | `privatelink.vaultcore.azure.net` | Resolves Key Vault |
| Private DNS zone (blob) | `privatelink.blob.core.windows.net` | Resolves blob storage |
| Private endpoint (OpenAI) | `pep-ailz-openai-nonprod` | Private endpoint for the AI service |
| Private endpoint (Key Vault) | `pep-ailz-keyvault-nonprod` | Private endpoint for Key Vault |
| Key Vault | `kv-ailz-nonprod-<suffix>` | Secrets store (private, RBAC — globally unique name) |
| Log Analytics workspace | `log-ailz-platform` | Diagnostics + usage/workbook backing store |
| Managed identity (workload) | `id-ailz-aiworkload-nonprod` | Keyless identity for the AI workload |
| Policy initiative | `AILZ-AI-Guardrails-Initiative` | The grouped guardrail set |
| Policy assignment (regions) | `Policy-AllowedRegions-AILZ` | Restrict resource locations to the allow-list |
| Policy assignment (models) | `Policy-AllowedModels-AILZ` | Restrict Azure OpenAI model deployments |
| Policy assignment (private-only) | `Policy-PrivateOnly-AILZ` | Deny public network access on AI services |
| Policy assignment (content-safety) | `Policy-ContentSafetyOn-AILZ` | Audit/enforce content-safety posture |
| Policy assignment (tagging) | `Policy-RequireTags-AILZ` | Require the mandatory tags |
| Budget | `Budget-AILZ-Platform` | Cost budget + alert thresholds |
| Cost action group | `ag-ailz-cost-alerts` | Notifies owners on budget thresholds |
| Usage workbook | `Workbook-AILZ-AIUsage` | Token/resource usage dashboard |
| RBAC role assignment | `Cognitive Services OpenAI User` → `id-ailz-aiworkload-nonprod` | Keyless data-plane access |

---

## Phase 0 — Assess (read-only, changes nothing)

### Step 0.1 — Confirm identity, scope, and providers

1. Sign in and confirm you are at the **pilot subscription** with the elevated role (R1):

   ```powershell
   Connect-AzAccount
   Set-AzContext -Subscription "<pilot-subscription-id>"
   ```

2. Run the discovery helper:

   ```powershell
   ./AILZ-Discovery.ps1 -SubscriptionId "<pilot-subscription-id>"
   ```

   It reports: your **effective role** at the scope (expect Owner/UAA — R1), **registered vs missing
   resource providers** (R5), existing **VNets and address spaces** (to check overlap — R2), existing
   **private DNS zones** (R3), current **policy assignments**, any **Key Vault**, and — importantly —
   **any existing AI (Cognitive Services) resources with public network access ON**. **Read-only** —
   it calls only `Get`/`List` cmdlets.

### Step 0.2 — Confirm remote state and toolchain

1. `terraform version`, `az version` (or `Get-Module Az -ListAvailable`), and `git --version` return
   the pinned/supported builds (R7).
2. `terraform init` succeeds against the **remote state** backend (R6) — the Azure Storage account +
   container, encrypted and versioned. Confirm the pipeline's Azure service connection uses **OIDC /
   workload identity federation**, not a stored secret.

---

## Phase 1 — Configure (author the landing zone as code; nothing applied yet)

### Step 1.1 — Set the variables

1. Open `main.tf` (and its `variables`/`terraform.tfvars`) and set:
   - `location` and `allowed_regions` — your agreed region allow-list (R4).
   - `allowed_models` — your agreed Azure OpenAI model/version allow-list (R4).
   - `required_tags` — your mandatory tag keys (R4).
   - `hub_address_space`, `spoke_address_space`, and the two subnet prefixes for
     `snet-ailz-privateendpoints` and `snet-ailz-aiworkload` (R2) — non-overlapping.
   - `create_private_dns_zones` — `true` to create the zones in the hub, or `false` to link to your
     existing central zones (R3).
2. Confirm the object names match the table above (or your agreed convention).

### Step 1.2 — Review the plan (no apply)

1. Generate and **read** the plan — this is the single most important review gate. In the pipeline
   this is the `terraform plan` stage in `azure-pipelines.yml`; locally:

   ```
   terraform plan -out ailz.plan
   ```

   Confirm the plan will **create**: `rg-ailz-hub-platform` + `rg-ailz-spoke-nonprod`, the two VNets +
   subnets + `peer-ailz-*` peerings, the five `privatelink.*` DNS zones (if enabled) linked to the
   VNets, `pep-ailz-openai-nonprod` + `pep-ailz-keyvault-nonprod`, `kv-ailz-nonprod-<suffix>` (with
   **public access disabled**), `log-ailz-platform`, `id-ailz-aiworkload-nonprod` + its RBAC
   assignment, the `AILZ-AI-Guardrails-Initiative` and its five `Policy-*-AILZ` assignments **in
   `DoNotEnforce` (audit) mode**, and `Budget-AILZ-Platform` + `ag-ailz-cost-alerts` — and **nothing
   unexpected** (no deletions of existing infrastructure).
2. Commit the code and the plan output for review/approval (category G5, G8).

---

## Phase 2 — Pilot (apply to a non-production scope first, policies in audit)

### Step 2.1 — Apply the network, private endpoints, identity, and Key Vault

1. In the pipeline, run the **plan → approval → apply** flow (`azure-pipelines.yml`). The `apply`
   stage runs **only after** the Environment approval gate is satisfied; it re-plans and applies
   `ailz.plan`. It targets the **pilot** scope (`rg-ailz-spoke-nonprod` / the pilot subscription).
2. Confirm `kv-ailz-nonprod-<suffix>` has **public network access = Disabled** and is reached via
   `pep-ailz-keyvault-nonprod`; confirm `id-ailz-aiworkload-nonprod` holds the **Cognitive Services
   OpenAI User** role (keyless).

### Step 2.2 — Assign the policy initiative in AUDIT (DoNotEnforce) mode

1. The `AILZ-AI-Guardrails-Initiative` and its five assignments (`Policy-AllowedRegions-AILZ`,
   `Policy-AllowedModels-AILZ`, `Policy-PrivateOnly-AILZ`, `Policy-ContentSafetyOn-AILZ`,
   `Policy-RequireTags-AILZ`) are created with **`enforcement_mode = "DoNotEnforce"`** — they
   **report** non-compliance but do **not** block anything yet. This is deliberate: observe impact
   before enforcing.
2. Wait for the first compliance evaluation (it is not instant — *verify current evaluation timing*),
   then review results with `AILZ-Report.ps1`. *Some built-in AI policy definitions may be preview or
   absent in your cloud — the initiative flags any that could not be assigned; verify availability.*

### Step 2.3 — Place a test AI service and set content-safety + budget

1. Deploy **one pilot AI service** (e.g. an Azure OpenAI / Cognitive Services account) into
   `rg-ailz-spoke-nonprod`, **public access disabled**, reached via `pep-ailz-openai-nonprod`, with
   the content-safety default in place. (Deploying and hardening the AI service in depth is the
   companion *Secure AI Foundry / OpenAI Deployment* solution — here you place one to prove the zone.)
2. Confirm `Budget-AILZ-Platform` is set with alert thresholds (e.g. 50/80/100%) wired to
   `ag-ailz-cost-alerts`, and that `Workbook-AILZ-AIUsage` shows the pilot resource.

---

## Phase 3 — Validate

1. Run the validation helper:

   ```powershell
   ./AILZ-Validate.ps1 -SubscriptionId "<pilot-subscription-id>"
   ```

   It checks the pass/fail gates in `05-testing.md`: VNets/peering/subnets exist, the private DNS
   zones are linked, the AI service and Key Vault have **public access disabled** and resolve to
   **private IPs**, the workload uses **managed identity (no keys)**, the `AILZ-AI-Guardrails-
   Initiative` is **assigned and reporting** (audit), the content-safety default is present, and
   `Budget-AILZ-Platform` exists with thresholds. It also runs a **private-resolution probe**
   (read-only) confirming the AI hostname resolves to a private IP.
2. Run the posture + cost report and review with governance:

   ```powershell
   ./AILZ-Report.ps1 -SubscriptionId "<pilot-subscription-id>"
   ```

   It summarizes private-endpoint coverage, policy compliance (what would be denied once enforced),
   budget status, and current AI spend. **Do not enforce or expand until the gates pass.**

---

## Phase 4 — Expand

1. **Flip the guardrails from audit to enforce.** Once the compliance report shows the estate is clean
   (or the exceptions are understood and excepted), change the assignments' `enforcement_mode` from
   `DoNotEnforce` to **`Default` (enforced)** — `Policy-PrivateOnly-AILZ`, `Policy-AllowedRegions-AILZ`,
   `Policy-AllowedModels-AILZ`, and `Policy-RequireTags-AILZ` now **Deny** non-compliant
   creates/updates. Plan → review → apply as always.
2. **Extend the scope.** Move the initiative assignment from the pilot subscription up to the target
   **management group** so all AI workloads inherit the guardrails. Peer additional AI spokes to
   `vnet-ailz-hub-platform`.
3. **Institutionalize plan → review → apply.** Every future change to the network, policy, RBAC, or
   cost controls goes through `terraform plan` / `what-if`, review, and approval — never portal
   click-ops.
4. **Set the stage for the next layers.** With the zone governed, deploy the companion *Secure Azure
   OpenAI / AI Foundry*, *Enterprise RAG*, *MLOps*, and *Content Safety & Responsible-AI* solutions
   **into** it.

---

## Rollback / safe-off

- **Because everything was plan/what-if-first and non-prod-first**, most missteps are caught in `plan`
  before they apply. Keep every apply small and reviewed.
- **A policy is denying something it shouldn't:** the guardrails ship in **audit mode** for exactly
  this reason. If you already enforced, set the assignment's `enforcement_mode` back to
  `DoNotEnforce` (or scope an **exemption** via an Azure Policy exemption for the specific resource),
  re-apply, and investigate. Never enforce a broad `Deny` estate-wide before validating in audit.
- **Terraform-managed objects:** `terraform destroy` (scoped, plan-first) removes what Terraform
  created — but **do not destroy the network, private DNS, or Key Vault casually**; other workloads
  may already depend on them. Treat destroy as a deliberate, reviewed action, and remember Key Vault
  soft-delete/purge-protection may retain the vault.
- **Break-glass:** keep an owner-level break-glass identity **exempt** from any deny policy that could
  lock out administration, and validate you can still manage the scope after enforcing.
- **Remote state** is your source of truth and rollback point — protect and version it (R6).
