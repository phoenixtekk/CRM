# 2. Requirements — AI Workload Security Assessment

The category-wide prerequisites (the target tenant/subscription, read-only assessor access, Graph/Az API
access, licensing, scope/baseline, output handling, remediation ownership) are published once in
**Global Requirements — Assessments** — read that first. This page lists only the prerequisites
**specific to assessing Azure AI workloads**. Each item: **Description / Why required / How to verify /
How to implement if missing.**

> Everything here is read-only. If satisfying an item seems to need write/Contributor access, you have
> over-scoped the identity — an AI security review reads configuration, it never changes a resource.

## R1. Azure **Reader** at every subscription / resource group hosting AI workloads
**Description:** The Azure RBAC **Reader** role at each subscription (or resource group) that contains
Azure OpenAI, AI Foundry, AI Search, or Azure ML resources in scope.
**Why required:** Discovery, network-isolation, and content-safety reviews read the AI resources through
Azure Resource Manager; without Reader they return nothing and the workload appears (falsely) absent.
**How to verify:** `portal.azure.com` → the subscription/RG → **Access control (IAM)** → **View my access**
→ confirm **Reader**. `AIWLSEC-Validate.ps1` also confirms `Connect-AzAccount` and lists AI resources found.
**How to implement if missing:** Have an Owner/User Access Administrator assign **Reader** at the highest
common scope covering the AI workloads. Do **not** request Contributor for the assessment.

## R2. Security Reader in Entra (for identity / RBAC review)
**Description:** The **Security Reader** (or Global Reader) directory role, to read managed-identity role
assignments and app registrations tied to the AI workloads.
**Why required:** The keyless-identity review inspects which identities hold data-plane roles on the AI
resources and whether app registrations carry secrets; that needs directory read access.
**How to verify:** Entra admin center → **Roles and administrators** → confirm **Security Reader** /
**Global Reader**. `AIWLSEC-Validate.ps1` confirms the Graph read scopes.
**How to implement if missing:** Have a Privileged Role Administrator assign **Security Reader** (read-only).

## R3. Read scopes / provider access for the AI resource types
**Description:** Reader-level access to the resource providers the scripts query — **Microsoft.CognitiveServices**
(Azure OpenAI / AI Services), **Microsoft.Search** (AI Search), **Microsoft.MachineLearningServices**
(Azure ML), **Microsoft.Network** (private endpoints), and **Microsoft.Insights** (diagnostics). Graph read
scopes such as `Directory.Read.All` for RBAC. *Verify the current provider/API and Graph scope set.*
**Why required:** Each review area calls a specific provider; a missing provider registration or scope makes
that area silently empty.
**How to verify:** `Get-AzResourceProvider -ProviderNamespace Microsoft.CognitiveServices` shows Registered;
`Connect-MgGraph -Scopes "Directory.Read.All"` succeeds. `AIWLSEC-Validate.ps1` reports coverage.
**How to implement if missing:** Ensure the providers are registered on the subscription (they are once the
resources exist) and consent the read-only Graph scopes.

## R4. PowerShell 7+ with Az and Microsoft.Graph modules
**Description:** PowerShell 7+ with **Az.Accounts / Az.Resources / Az.CognitiveServices / Az.Search /
Az.MachineLearningServices / Az.Network / Az.Monitor** and **Microsoft.Graph**. *Verify current versions.*
**Why required:** All five scripts are PowerShell and depend on these modules; version drift is the most
common cause of empty output.
**How to verify:** `$PSVersionTable.PSVersion` ≥ 7; `Get-Module Az.CognitiveServices,Az.Search -ListAvailable`.
**How to implement if missing:** `Install-Module Az -Scope CurrentUser` and
`Install-Module Microsoft.Graph -Scope CurrentUser`. Some ML/Search cmdlets evolve — verify the current
module names for your subscription's resource types.

## R5. A defined, documented AI assessment scope
**Description:** A written scope — which subscriptions/RGs, which AI workloads, and the AI security baseline
you score against — agreed before the run.
**Why required:** Scope keeps the review bounded and the findings comparable run-to-run.
**How to verify:** The scope document exists and names the workloads and baseline; the report records scope
and run date.
**How to implement if missing:** Agree the scope with the AI/security owner. Start with one workload for the
pilot, then expand.

## R6. Diagnostics to Log Analytics for the AI resources (for optional KQL corroboration)
**Description:** Azure OpenAI / AI Search diagnostic settings streaming to a **Log Analytics** workspace (or
Sentinel), if you want to corroborate posture with the supplied read-only KQL.
**Why required:** The KQL corroboration (e.g. key-based auth still in use) needs the logs; without them the
assessment still scores from configuration but loses the live cross-check.
**How to verify:** The AI resource → **Diagnostic settings** shows a workspace destination; you can query
the relevant table. *Verify current table/category names.*
**How to implement if missing:** Note absent diagnostics as a finding (you can't observe what you don't log),
or skip the KQL — it is optional, not required, for the findings.

## R7. A secure destination for the findings report
**Description:** A restricted-access location for the exported findings, which map your AI attack surface.
**Why required:** The report details where an AI workload is exposed; it must be handled as sensitive.
**How to verify:** A restricted SharePoint/Teams site or secured share exists, access limited to the
security/AI owners.
**How to implement if missing:** Provision a restricted destination before running; share on a need-to-know
basis. *Risk-acceptance of any finding remains the customer's decision.*

## R8. Awareness of preview features and the paired build solutions
**Description:** An understanding that several AI safety controls (prompt shields, groundedness detection,
protected-material detection, asynchronous filtering) may be in **preview**, and that the *fixes* for
findings are the paired AI build solutions (AIFOUNDRY / AIRAG / AISAFETY / AILZ).
**Why required:** The assessment must not assert a control is "missing" when it is simply unavailable/preview
in your region; and findings need an owner and a remediation path.
**How to verify:** The report flags preview-dependent findings with "*verify current availability*"; the
remediation column names the paired solution.
**How to implement if missing:** *Verify current availability and preview status* for any safety feature
before treating its absence as a hard finding; assign remediation owners and reference the paired solutions.
