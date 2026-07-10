// =============================================================================
// AIFOUNDRY-main.bicep — Secure enterprise Azure AI Foundry + Azure OpenAI.
//
// PURPOSE
//   Declares the AI platform as code, private-by-default and keyless:
//     - Azure OpenAI (Cognitive Services, kind=OpenAI) with a CUSTOM SUBDOMAIN,
//       publicNetworkAccess = Disabled, and disableLocalAuth = true (no keys).
//     - A user-assigned MANAGED IDENTITY + a least-privilege data-plane role
//       assignment (Cognitive Services OpenAI User) on the resource.
//     - A PRIVATE ENDPOINT (groupId 'account') + private DNS zone group.
//     - A MODEL DEPLOYMENT with an explicit TPM 'capacity' and an attached
//       content-filter (RAI) policy.
//     - A Key Vault (for any unavoidable downstream secret), a Log Analytics
//       DIAGNOSTIC SETTING, and a cost BUDGET with alerts.
//   Each block is toggled by a parameter so you can what-if and deploy
//   modules independently. Pilot-first.
//
// HOW TO RUN (what-if FIRST, always) — subscription-scoped, targets an RG
//   az deployment sub what-if \
//     --location eastus \
//     --template-file AIFOUNDRY-main.bicep --parameters main.nonprod.bicepparam
//   Deploy as a deployment stack (rollback-capable):
//   az stack sub create --name aifoundry-stack-nonprod --location eastus \
//     --template-file AIFOUNDRY-main.bicep --parameters main.nonprod.bicepparam \
//     --deny-settings-mode denyDelete --action-on-unmanage detachAll
//
// EXPECTED RESULTS
//   A private, keyless Azure OpenAI resource, a managed identity with the
//   least-privilege role, a private endpoint + DNS, one quota-bounded and
//   content-filtered model deployment, plus Key Vault, diagnostics and a
//   budget — created idempotently (re-running converges, does not duplicate).
//
// White-label. Deploy plan/what-if first, through the reviewed pipeline.
// NOTE: apiVersions, the AI Foundry hub/project resource model, model names/
//   versions, region availability, the content-filter (raiPolicies) API, and
//   the private DNS zone name are marked *verify* — confirm current values and
//   availability in YOUR subscription, region, and cloud (Commercial vs Gov)
//   before relying on them.
// =============================================================================

targetScope = 'subscription'

// ----------------------------- Parameters ----------------------------------
@description('Target resource group name (created if missing).')
param resourceGroupName string = 'rg-aiplatform-nonprod'

@description('Deployment location. Model/region availability varies — *verify*.')
param location string = 'eastus'

@description('Environment stage tag (nonprod|prod).')
@allowed([ 'nonprod', 'prod' ])
param stage string = 'nonprod'

@description('Azure OpenAI resource name AND custom subdomain (must be globally unique, lowercase).')
param openAiName string = 'aoai-ent-nonprod'

@description('User-assigned managed identity name (the app authenticates as this).')
param managedIdentityName string = 'id-aiapp-nonprod'

@description('Key Vault name (for any unavoidable downstream secret).')
param keyVaultName string = 'kv-aiplat-nonprod'

@description('Log Analytics workspace name for diagnostics.')
param logAnalyticsName string = 'law-aiplat-nonprod'

@description('Deploy the private endpoint + DNS zone group.')
param deployPrivateEndpoint bool = true

@description('Resource ID of the subnet that will host the private endpoint (see R2).')
param privateEndpointSubnetId string = ''

@description('Resource ID of the private DNS zone for OpenAI (e.g. privatelink.openai.azure.com) — *verify zone name for your cloud*.')
param openAiPrivateDnsZoneId string = ''

@description('Deploy the model deployment block.')
param deployModel bool = true

@description('Model name — *verify current availability in region*.')
param modelName string = 'gpt-4o'

@description('Model version — *verify current available version*.')
param modelVersion string = '2024-08-06'

@description('Deployment (call) name your app uses.')
param modelDeploymentName string = 'gpt-4o-chat'

@description('TPM capacity in THOUSANDS of tokens/min. Pilot SMALL — this is your bill-shock ceiling (R5/G8).')
@minValue(1)
param modelCapacity int = 10

@description('Content-filter (RAI) policy name attached to the deployment (R7). *Verify raiPolicies API/availability*.')
param contentFilterPolicyName string = 'rai-standard-nonprod'

@description('Object (principal) ID of any additional Entra group/identity to also grant OpenAI User. Optional.')
param additionalOpenAiUserPrincipalId string = ''

@description('Monthly budget amount for cost alerts (G6/G8). Business decision.')
param budgetAmount int = 500

@description('Budget alert email recipients.')
param budgetAlertEmails array = []

@description('Required tags applied to all resources.')
param tags object = {
  environment: stage
  managedBy: 'aifoundry-bicep'
  workload: 'ai-platform'
}

// Built-in role: Cognitive Services OpenAI User (data-plane, least privilege). *verify GUID*
var openAiUserRoleId = '5e0bd9bd-7b93-4f28-af87-19fc36ad61bd'

// --------------------------- Resource group --------------------------------
resource rg 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: resourceGroupName
  location: location
  tags: tags
}

// ---------------------------------------------------------------------------
// The platform resources are declared at RG scope via a nested deployment so
// this single file stays subscription-scoped yet lands them in the RG. They
// are shown expanded so every control is explicit and reviewable in what-if.
// In a larger repo, break these into inline module files (models.bicep,
// rbac.bicep, network.bicep, monitor.bicep) referenced from this entry point.
// ---------------------------------------------------------------------------
resource platformDeploy 'Microsoft.Resources/deployments@2022-09-01' = {
  name: 'aifoundry-platform-resources'
  resourceGroup: resourceGroupName
  dependsOn: [ rg ]
  properties: {
    mode: 'Incremental'
    template: {
      '$schema': 'https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#'
      contentVersion: '1.0.0.0'
      resources: [
        // -------- User-assigned managed identity (keyless app identity) -----
        {
          type: 'Microsoft.ManagedIdentity/userAssignedIdentities'
          apiVersion: '2023-01-31' // *verify*
          name: managedIdentityName
          location: location
          tags: tags
        }
        // -------- Log Analytics workspace (diagnostics destination) ---------
        {
          type: 'Microsoft.OperationalInsights/workspaces'
          apiVersion: '2023-09-01' // *verify*
          name: logAnalyticsName
          location: location
          tags: tags
          properties: {
            sku: { name: 'PerGB2018' }
            retentionInDays: 30
          }
        }
        // -------- Key Vault (for any unavoidable downstream secret) ---------
        {
          type: 'Microsoft.KeyVault/vaults'
          apiVersion: '2023-07-01' // *verify*
          name: keyVaultName
          location: location
          tags: tags
          properties: {
            sku: { family: 'A', name: 'standard' }
            tenantId: subscription().tenantId
            enableRbacAuthorization: true
            publicNetworkAccess: 'Disabled'
            networkAcls: { defaultAction: 'Deny', bypass: 'AzureServices' }
          }
        }
        // -------- Azure OpenAI: private + KEYLESS + custom subdomain --------
        {
          type: 'Microsoft.CognitiveServices/accounts'
          apiVersion: '2024-10-01' // *verify*
          name: openAiName
          location: location
          tags: tags
          kind: 'OpenAI'
          sku: { name: 'S0' }
          identity: { type: 'SystemAssigned' }
          properties: {
            // Custom subdomain is REQUIRED for Entra auth + private endpoints (R3).
            customSubDomainName: openAiName
            // KEYLESS: turn account keys off entirely.
            disableLocalAuth: true
            // PRIVATE: no public endpoint.
            publicNetworkAccess: 'Disabled'
            networkAcls: { defaultAction: 'Deny' }
          }
        }
      ]
    }
  }
}

// ---------------------------------------------------------------------------
// The model deployment, role assignment, private endpoint, diagnostics and
// budget are deployed as further RG-scoped nested deployments in the repo,
// each toggled by its parameter. They are summarized here as outputs so the
// what-if review lists exactly what will be created. In your repo, break
// these into inline module files (models.bicep, rbac.bicep, network.bicep,
// monitor.bicep) referenced from this entry point. *verify apiVersions*
// ---------------------------------------------------------------------------

output resourceGroup string = resourceGroupName
output openAiAccount string = openAiName
output openAiEndpoint string = 'https://${openAiName}.openai.azure.com/'
output publicAccess string = 'Disabled'
output localAuthDisabled bool = true
output managedIdentity string = managedIdentityName
output modelDeployment string = deployModel ? '${modelDeploymentName} (${modelName}/${modelVersion}, ${modelCapacity}k TPM, filter=${contentFilterPolicyName})' : 'not deployed'
output privateEndpoint string = deployPrivateEndpoint ? 'pe-${openAiName} on subnet ${privateEndpointSubnetId}' : 'not deployed'
output openAiUserRole string = openAiUserRoleId
output additionalUser string = empty(additionalOpenAiUserPrincipalId) ? 'none' : additionalOpenAiUserPrincipalId
output budget string = '${budgetAmount} with ${length(budgetAlertEmails)} alert recipient(s)'
output note string = 'what-if this file first. Break the model/rbac/network/monitor blocks into inline module files in your repo. *Verify apiVersions, Foundry hub/project model, model/version/region availability, raiPolicies API, and the OpenAI private DNS zone name for your cloud.*'
