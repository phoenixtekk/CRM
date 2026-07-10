# 3. Implementation — Azure AI Foundry & Azure OpenAI: Secure Enterprise Deployment

Follow these steps in order. Everything is **pilot-first**: you deploy a **non-production** Foundry project and Azure OpenAI resource with a **low TPM quota**, validate isolation and keyless access, then expand to production behind pipeline approval. Every object you create is named with the convention **`<Purpose> – <Scope> – <Stage>`** and that exact name is reused in later steps, testing, and the scripts. Placeholder tenant is `contoso.com` / `contoso.onmicrosoft.com`.

> Run every deployment with **`what-if` first**. Never run an unreviewed apply against production. Examples use the Azure CLI; the CI/CD pipeline runs the same commands behind an approval gate.

## Naming you will create (reuse these exact names)
| Object | Name (display) | Resource name (example) |
|---|---|---|
| Resource group (non-prod) | `AI Platform RG – Enterprise – NonProd` | `rg-aiplatform-nonprod` |
| AI Foundry hub | `AI Foundry Hub – Enterprise – NonProd` | `hub-ai-ent-nonprod` |
| AI Foundry project | `AI Foundry Project – TeamA – NonProd` | `proj-teama-nonprod` |
| Azure OpenAI resource | `Azure OpenAI – Enterprise – NonProd` | `aoai-ent-nonprod` (subdomain `aoai-ent-nonprod`) |
| Model deployment | `gpt-4o Deployment – Chat – NonProd` | `gpt-4o-chat` |
| Content-filter (RAI) policy | `Content Filter – Standard – NonProd` | `rai-standard-nonprod` |
| Private endpoint (OpenAI) | `Private Endpoint – OpenAI – NonProd` | `pe-aoai-nonprod` |
| User-assigned managed identity | `Managed Identity – AI App – NonProd` | `id-aiapp-nonprod` |
| Key Vault | `Key Vault – AI Platform – NonProd` | `kv-aiplat-nonprod` |
| Log Analytics workspace | `Log Analytics – AI Platform – NonProd` | `law-aiplat-nonprod` |
| Diagnostic setting | `Diagnostics – OpenAI – NonProd` | `diag-aoai-nonprod` |
| Budget | `Budget – AI Platform – NonProd` | `budget-aiplat-nonprod` |
| Data-plane role assignment | `OpenAI User – AI App – NonProd` | (role: Cognitive Services OpenAI User) |
| Deployment stack (non-prod) | `aifoundry-stack – Enterprise – NonProd` | `aifoundry-stack-nonprod` |
| Deployment stack (prod) | `aifoundry-stack – Enterprise – Prod` | `aifoundry-stack-prod` |
| CI/CD pipeline | `AI Platform Pipeline – Enterprise – CICD` | (Azure DevOps / GitHub) |

## Step 1 — Assess: inventory the current AI estate (read-only)
1. Sign in: `az login` (add `--tenant contoso.onmicrosoft.com` if you have several) and `Connect-AzAccount` for the Az modules.
2. Set the working subscription: `az account set --subscription "<non-prod sub id>"`.
3. Run the discovery script from the `scripts/` folder:
   `powershell -ExecutionPolicy Bypass -File .\AIFOUNDRY-Discovery.ps1 -SubscriptionId "<non-prod sub id>"`
   It reports existing **Cognitive Services / OpenAI** resources and, for each: whether **public network access is Enabled** (a risk), whether **local auth (keys) is enabled**, whether a **custom subdomain** is set (**R3**), model deployments and their TPM, private endpoints, diagnostic settings, and it lists VNets/subnets and existing **private DNS zones** (**R2**). Save the output — it is your baseline and your "what's insecure today" list.
4. Confirm the rights, VNet/subnet, and quota from **R1–R5**.

## Step 2 — Configure: scaffold the Bicep repo
1. Clone the empty repo (Global Requirements G4) and add the provided files:
   - `AIFOUNDRY-main.bicep` — the platform template (entry point).
   - `AIFOUNDRY-Discovery.ps1`, `AIFOUNDRY-Report.ps1` under `scripts/`.
   - `AIFOUNDRY-Validate.py`, `AIFOUNDRY-ModelSmokeTest.py` under `scripts/`, plus a pinned `requirements.txt` (**R8**).
2. Create a parameters file per environment (`main.nonprod.bicepparam`, `main.prod.bicepparam`) holding: the **subdomain**, target **VNet/subnet** IDs, **private DNS zone** ID(s), the model + version + **TPM** for the deployment, the **content-filter policy** name/thresholds, the Log Analytics workspace, and the **budget** amount/thresholds (**R2/R5/R6/R7**). Never hard-code these in the template.
3. Commit to a **feature branch** and open a pull request — infrastructure is reviewed, never pushed straight to `main`.

## Step 3 — Configure: deploy the private, keyless Azure OpenAI resource (non-prod)
1. Preview with `what-if` at resource-group scope (the Bicep creates the RG-scoped resources; run against the subscription with the RG target):
   `az deployment sub what-if --location eastus --template-file AIFOUNDRY-main.bicep --parameters main.nonprod.bicepparam`
2. **Read the preview.** Confirm it creates **`Azure OpenAI – Enterprise – NonProd`** with **`publicNetworkAccess: Disabled`**, **`disableLocalAuth: true`**, and **`customSubDomainName`** set (**R3**), plus the **`Managed Identity – AI App – NonProd`**, **`Key Vault – AI Platform – NonProd`**, and **`Log Analytics – AI Platform – NonProd`**.
3. Deploy as a deployment stack (rollback-capable):
   `az stack sub create --name "aifoundry-stack-nonprod" --location eastus --template-file AIFOUNDRY-main.bicep --parameters main.nonprod.bicepparam --deny-settings-mode denyDelete --action-on-unmanage detachAll`
   *Verify deployment-stacks availability in your cloud (R-note); if unavailable, fall back to `az deployment sub create` and note that rollback is manual.*
4. Verify in the portal: the resource exists and **Networking** shows **Public network access: Disabled**.

## Step 4 — Configure: wire the private endpoint and DNS
1. `what-if` then deploy the private-endpoint block (it is part of `AIFOUNDRY-main.bicep`, toggled by the `deployPrivateEndpoint` parameter): it creates **`Private Endpoint – OpenAI – NonProd`** on your **R2** subnet with `groupId` **`account`**, and the **private DNS zone group** linking it to `privatelink.openai.azure.com` (*verify the exact zone name for your cloud*).
2. Confirm the endpoint's connection state is **Approved** and a private DNS **A record** now exists for `aoai-ent-nonprod.openai.azure.com` pointing to the private IP (**Private endpoint → DNS configuration**).
3. From a VM/host **inside the VNet**, `nslookup aoai-ent-nonprod.openai.azure.com` must resolve to the **private** IP. From outside the VNet it should not resolve to a usable public endpoint — that is the isolation working.

## Step 5 — Configure: assign least-privilege data-plane RBAC to the managed identity
1. The Bicep creates **`OpenAI User – AI App – NonProd`** — an assignment of the **Cognitive Services OpenAI User** role to **`Managed Identity – AI App – NonProd`** at the Azure OpenAI resource scope (**R4**). Confirm it appears under the resource's **Access control (IAM) → Role assignments**.
2. Do **not** grant Contributor to app identities; use **Contributor** only for the identity/pipeline that manages deployments, and **User** for identities that only call models. Least privilege by default.
3. Because keys are disabled (`disableLocalAuth`), this assignment is the *only* way to authenticate — there is no key fallback, by design.

## Step 6 — Configure: deploy the model with an explicit quota and content filter
1. `what-if` then deploy the model block: it creates the deployment **`gpt-4o Deployment – Chat – NonProd`** (deployment name `gpt-4o-chat`) of a specific model **version**, with an explicit **`capacity`** (TPM, in thousands) from your **R5** quota, and attaches the content-filter policy **`Content Filter – Standard – NonProd`** (**R7**). *Model name/version, region availability, and the exact content-filter API are subject to change — verify current availability.*
2. Keep the pilot **TPM small** (e.g. the minimum that lets you test). It is both your load and your bill-shock ceiling — raise it deliberately later.
3. Confirm the deployment and its attached content filter in the portal (**Azure AI Foundry / OpenAI → Deployments**).

## Step 7 — Configure: turn on diagnostics and the budget
1. The Bicep creates the diagnostic setting **`Diagnostics – OpenAI – NonProd`** sending audit/request/response metadata and metrics to **`Log Analytics – AI Platform – NonProd`**, and the **`Budget – AI Platform – NonProd`** with the alert thresholds from your parameters (**R6**).
2. Confirm logs are arriving: after a test call (Step 8), run a `AzureDiagnostics`/resource-log query in Log Analytics and see the request appear.
3. Confirm the budget exists with recipients under **Cost Management → Budgets**.

## Step 8 — Pilot: validate keyless access and isolation end to end
1. Run the Python posture validation (keyless, read-only):
   `python AIFOUNDRY-Validate.py --subscription <non-prod sub id> --resource-group rg-aiplatform-nonprod --account aoai-ent-nonprod`
   It confirms **public access Disabled**, **local auth Disabled**, **custom subdomain set**, the **private endpoint** present, the **role assignment** present, the **deployment + content filter** present, and a **diagnostic setting** configured — the Testing guide's gates. It authenticates via `DefaultAzureCredential` with **no key**.
2. Run the keyless smoke test — it proves an app can actually call the model with a token and **no key**:
   `python AIFOUNDRY-ModelSmokeTest.py --endpoint https://aoai-ent-nonprod.openai.azure.com/ --deployment gpt-4o-chat`
   Run it **from inside the VNet** (a jump host / the CI agent on the VNet). A single, low-token completion returns → keyless + private path work end to end. From outside the VNet the network call should fail — that is isolation confirmed.
3. Generate the posture/usage report: `powershell -ExecutionPolicy Bypass -File .\AIFOUNDRY-Report.ps1 -SubscriptionId "<non-prod sub id>" -ResourceGroup rg-aiplatform-nonprod`.

## Step 9 — Wire the CI/CD pipeline (what-if → approval → deploy)
1. Create the pipeline **`AI Platform Pipeline – Enterprise – CICD`** in Azure DevOps or GitHub Actions from your repo. Its stages are **Validate** (build Bicep, run `AIFOUNDRY-Validate.py` against non-prod) → **What-If** (posts the preview to the PR) → **Approval** (manual gate) → **Deploy** (deployment stack).
2. Confirm the **service connection** uses **workload identity federation (OIDC)** — no stored secret (Global Requirement G5) — and the **production environment** has the approval gate and reviewer group.
3. Merging to `main` triggers Validate + What-If; the Deploy stage runs only after approval.

## Step 10 — Expand: deploy to production, then onboard more projects/models
1. With `main.prod.bicepparam` (production subdomain, VNet, a **higher, deliberate TPM**, stricter content filter if agreed), let the pipeline run **Validate → What-If** against production. Review the what-if in the PR.
2. Approve the gate. The pipeline deploys **`aifoundry-stack-prod`**. Re-run `AIFOUNDRY-Validate.py` against production — all gates must pass before any app points at it.
3. **Onboard a new team** by adding a Foundry **project** under the hub and (if needed) a new **model deployment** with its own TPM and the agreed content filter — parameters only, same template. Each new app gets its **own managed identity** with the **User** role. That is the repeatable payoff.
4. **Rollback** at any point: `az stack sub delete/update` on the named stack removes or reverts exactly what it deployed (use `--action-on-unmanage detachAll` to leave resources in place while detaching stack management).

> Raising a deployment's TPM, swapping a model version, or tightening the content filter are all **parameter changes** through the same `what-if` → approval → deploy path — never a portal click on production.
