# 2. Requirements — Azure AI Foundry & Azure OpenAI: Secure Enterprise Deployment

The category-wide prerequisites (an Azure subscription with AI-service access and rights, Entra identity + managed identity + RBAC, private-networking capability, IaC + Python tooling and source control, a CI/CD platform, data source/classification for grounded solutions, content-safety/responsible-AI posture, and cost controls/quotas) are covered once in **Global Requirements — AI** and are **not repeated here**. Confirm those first. Below are the prerequisites **specific to a secure Azure AI Foundry + Azure OpenAI deployment**. Each item: **Description / Why required / How to verify / How to implement if missing.**

## R1. Azure OpenAI (Foundry) resource access approved
**Description:** Your subscription is approved/enabled to create **Azure OpenAI** (and AI Foundry) resources, and the target **region** offers the models you intend to deploy.
**Why required:** Azure OpenAI has historically been an access-managed service and model availability differs by region; you cannot deploy a model that isn't offered where you're deploying.
**How to verify:** In the portal, try **Create a resource → Azure OpenAI** in the target region, or run `az cognitiveservices account list-skus --kind OpenAI --location <region>`. Check the model/region availability list for your intended models. *Access requirements, model list, and regional availability change — verify current availability in your subscription and region.*
**How to implement if missing:** Request access to the AI service if your tenant still requires it; if a model isn't in your region, pick a supported region for that model (you can deploy resources in more than one region).

## R2. An existing VNet, subnet, and Private DNS capability for the AI resources
**Description:** A virtual network with a subnet to hold the **private endpoints**, and the ability to create/link the **private DNS zone(s)** used for private-endpoint resolution (for example `privatelink.openai.azure.com` — *verify the exact zone name(s) for OpenAI / AI Services in your cloud*).
**Why required:** Disabling public access without a working private endpoint + DNS makes the resource unreachable; the private path is how apps still call it.
**How to verify:** The discovery script lists VNets/subnets and existing private DNS zones; confirm the subnet has room and that you can create/link the zone. Confirm `privateEndpointNetworkPolicies` on the subnet won't block the endpoint.
**How to implement if missing:** Provision (or reuse) a subnet for private endpoints and pre-create/link the private DNS zone(s). If your organization uses a central hub for private DNS, plan the zone links there (see the **AI Landing Zone** solution). *Encode ranges/zone names as parameters, never hard-coded literals.*

## R3. Custom subdomain enabled on the Azure OpenAI resource
**Description:** The Azure OpenAI resource is created **with a custom subdomain** (`customSubDomainName`), not the shared regional endpoint.
**Why required:** **Entra ID (keyless/token) authentication and private endpoints require a custom subdomain.** A resource created without one cannot use managed-identity auth and cannot be fronted by a private endpoint the same way.
**How to verify:** The resource's endpoint is `https://<your-subdomain>.openai.azure.com/` (not a shared `*.api.cognitive.microsoft.com` regional URL). The Bicep sets `properties.customSubDomainName`.
**How to implement if missing:** Set `customSubDomainName` at **create time** in the template. It generally **cannot be added after creation** — if an existing resource lacks one, plan to recreate it (the discovery script flags resources without a custom subdomain).

## R4. Data-plane RBAC roles available and assignable to a managed identity
**Description:** The data-plane roles the platform uses — at minimum **Cognitive Services OpenAI User** (call models) and **Cognitive Services OpenAI Contributor** (also manage deployments) — exist and you can assign them to a **user-assigned managed identity**.
**Why required:** With keys disabled (`disableLocalAuth`), these roles are the *only* way an app or script authenticates; without the assignment every call returns 401/403.
**How to verify:** `az role definition list --name "Cognitive Services OpenAI User"` returns the role; confirm you have **User Access Administrator/Owner** to assign it. The validation script checks the assignment.
**How to implement if missing:** Ensure your deploying identity can assign roles at the resource/RG scope; create the user-assigned managed identity ahead of the app that will use it.

## R5. Region quota (TPM) headroom for your intended model deployments
**Description:** Sufficient **tokens-per-minute (TPM) quota** in the target region for the model(s) and deployment size(s) you plan.
**Why required:** A model deployment consumes regional quota; if the region is exhausted the deployment fails, and if quota is too low the app is rate-limited under load.
**How to verify:** Check **Quotas** for Azure OpenAI in the target region (portal, or the management SDK the model script uses). *Quota defaults and limits vary by model, region, and subscription type — verify current availability.*
**How to implement if missing:** Request a quota increase for the model/region before broad rollout; pilot with a **small** TPM and raise it deliberately (this is also your bill-shock control per Global Requirement G8).

## R6. Log Analytics workspace for diagnostics (and a cost budget owner)
**Description:** A **Log Analytics** workspace to receive the AI resource's diagnostic logs/metrics, and an owner/scope for a **cost budget** with alert recipients.
**Why required:** Without a diagnostic destination the platform is unobserved; without a budget an overrun is silent until the invoice (Global Requirement G8).
**How to verify:** The workspace exists (or the Bicep will create one) and you can create a diagnostic setting against it; a budget can be created at the resource-group/subscription scope with an action group / email recipients.
**How to implement if missing:** Create/choose a Log Analytics workspace and define the budget amount and alert thresholds as parameters. *The budget amount and alert thresholds are the customer's business decision.*

## R7. Content-filter (Responsible AI) position for the deployments
**Description:** A decision on the **content-filter severity thresholds** (and any preview protections such as prompt-shield/jailbreak or protected-material detection) to attach to each model deployment.
**Why required:** Generation can emit harmful or ungrounded output; the content filter is the guardrail in front of it, and its strictness is a deliberate choice (Global Requirement G7).
**How to verify:** A RAI/content-filter policy name and thresholds are agreed; the platform attaches it to each deployment. *Some content-safety features are in preview and some require the resource/region to support them — verify current availability.*
**How to implement if missing:** Adopt an acceptable-use/RAI position and set the thresholds; the default filter applies until you configure a stricter custom policy (see the **Azure AI Content Safety** solution). *The acceptable-content determination is the customer's legal / trust-and-safety decision, not this guide's.*

## R8. Python 3 with current Azure AI SDKs, and az/Az for the helpers
**Description:** Python 3.x with the Azure SDKs the scripts use — `azure-identity`, `azure-mgmt-cognitiveservices`, `azure-monitor-query`, and the `openai` package configured for Azure — plus the Azure CLI (`az`, `az bicep`) and Az PowerShell for the helpers.
**Why required:** The validation and smoke-test scripts authenticate **keylessly** via `DefaultAzureCredential` and exercise the platform through the SDK; the infra is Bicep.
**How to verify:** `python --version`, `pip show azure-identity azure-mgmt-cognitiveservices openai`, `az version`, `az bicep version`. *The AI SDKs move fast — verify/pin current versions.*
**How to implement if missing:** `pip install azure-identity azure-mgmt-cognitiveservices azure-monitor-query openai` into a pinned virtual environment; install/upgrade the Azure CLI and `az bicep`; commit the pinned versions to the repo.
