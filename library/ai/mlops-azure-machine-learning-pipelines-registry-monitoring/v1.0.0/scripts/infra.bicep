// =============================================================================
// infra.bicep — Azure Machine Learning workspace + compute as code (MLOps foundation).
//
// PURPOSE
//   Declares the MLOps platform as infrastructure-as-code: the Azure ML workspace
//   and its required linked resources (Storage, Key Vault, Application Insights,
//   Container Registry), a scale-to-zero training compute cluster, and the
//   least-privilege managed-identity role assignment the workspace needs on its
//   storage. Deploy the non-prod parameters first, validate, then prod.
//
// HOW TO RUN (what-if FIRST, always)
//   az deployment group what-if -g <rg> \
//     --template-file infra.bicep \
//     --parameters env=nonprod workspaceName=mlw-platform-nonprod
//   Then deploy:
//   az deployment group create -g <rg> \
//     --template-file infra.bicep \
//     --parameters env=nonprod workspaceName=mlw-platform-nonprod
//
// EXPECTED RESULTS
//   The workspace 'ML Workspace – Platform – <Stage>' with linked Storage/KeyVault/
//   AppInsights/ACR, the training cluster 'Training Cluster – Platform – NonProd'
//   (min 0 nodes = scale to zero), and a Storage Blob Data Contributor assignment
//   to the workspace identity — created idempotently. Re-running converges.
//
// White-label. Deploy plan/what-if first, through the reviewed pipeline.
// NOTE: API versions below are marked *verify* — confirm current supported
//       apiVersion values and feature availability in your tenant/cloud.
// =============================================================================

targetScope = 'resourceGroup'

@description('Environment stage — drives naming and defaults. Pilot nonprod first.')
@allowed([ 'nonprod', 'prod' ])
param env string = 'nonprod'

@description('Azure ML workspace name, e.g. mlw-platform-nonprod / mlw-platform-prod.')
param workspaceName string = 'mlw-platform-${env}'

@description('Deployment location.')
param location string = resourceGroup().location

@description('Training compute cluster VM size.')
param trainingVmSize string = 'Standard_DS3_v2'

@description('Max nodes for the training cluster. Min is 0 (scale to zero when idle).')
param trainingMaxNodes int = 4

@description('Idle seconds before the training cluster scales down (cost control, G8).')
param idleSecondsBeforeScaleDown int = 300

@description('Required tags applied to every resource.')
param requiredTags object = {
  environment: env
  managedBy: 'azureml-mlops'
  workload: 'churn-classifier'
}

var suffix = uniqueString(resourceGroup().id, workspaceName)
var storageName = toLower('st${take(replace(workspaceName, '-', ''), 14)}${take(suffix, 6)}')
var kvName      = toLower('kv-${take(workspaceName, 12)}-${take(suffix, 5)}')
var acrName     = toLower('acr${take(replace(workspaceName, '-', ''), 14)}${take(suffix, 6)}')
var aiName      = 'appi-${workspaceName}'

// ---------------------------------------------------------------------------
// Linked resources required by an Azure ML workspace  (apiVersions *verify*)
// ---------------------------------------------------------------------------
resource storage 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageName
  location: location
  tags: requiredTags
  sku: { name: 'Standard_LRS' }
  kind: 'StorageV2'
  properties: {
    allowBlobPublicAccess: false
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
  }
}

resource keyvault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: kvName
  location: location
  tags: requiredTags
  properties: {
    tenantId: subscription().tenantId
    sku: { family: 'A', name: 'standard' }
    enableRbacAuthorization: true
    enableSoftDelete: true
    publicNetworkAccess: 'Disabled' // private-by-default (G3). Add a private endpoint per the landing-zone solution.
  }
}

resource appinsights 'Microsoft.Insights/components@2020-02-02' = {
  name: aiName
  location: location
  tags: requiredTags
  kind: 'web'
  properties: {
    Application_Type: 'web'
  }
}

resource acr 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  name: acrName
  location: location
  tags: requiredTags
  sku: { name: 'Standard' }
  properties: {
    adminUserEnabled: false // keyless — use managed identity (G2/R5)
  }
}

// ---------------------------------------------------------------------------
// Azure ML workspace — system-assigned managed identity (keyless auth, R5)
// (apiVersion *verify* — the workspace resource type evolves)
// ---------------------------------------------------------------------------
resource workspace 'Microsoft.MachineLearningServices/workspaces@2024-04-01' = {
  name: workspaceName
  location: location
  tags: requiredTags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    friendlyName: 'ML Workspace – Platform – ${env == 'prod' ? 'Prod' : 'NonProd'}'
    storageAccount: storage.id
    keyVault: keyvault.id
    applicationInsights: appinsights.id
    containerRegistry: acr.id
    publicNetworkAccess: 'Disabled' // no public endpoint — add private endpoints separately
  }
}

// ---------------------------------------------------------------------------
// Training compute cluster — 'Training Cluster – Platform – NonProd'
//   min 0 nodes = SCALE TO ZERO when idle (cost control, G8).
// (apiVersion *verify*)
// ---------------------------------------------------------------------------
resource trainingCluster 'Microsoft.MachineLearningServices/workspaces/computes@2024-04-01' = {
  parent: workspace
  name: 'cpu-train-${env}'
  location: location
  properties: {
    computeType: 'AmlCompute'
    properties: {
      vmSize: trainingVmSize
      vmPriority: 'Dedicated'
      scaleSettings: {
        minNodeCount: 0
        maxNodeCount: trainingMaxNodes
        nodeIdleTimeBeforeScaleDown: 'PT${idleSecondsBeforeScaleDown}S'
      }
    }
  }
}

// ---------------------------------------------------------------------------
// Least-privilege data-plane role — workspace identity -> Storage Blob Data
//   Contributor on the linked storage (R5). Built-in role GUID *verify*.
// ---------------------------------------------------------------------------
var storageBlobDataContributor = subscriptionResourceId(
  'Microsoft.Authorization/roleDefinitions',
  'ba92f5b4-2d11-453d-a403-e96b0029c9fe' // Storage Blob Data Contributor — *verify*
)

resource wsStorageRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(storage.id, workspace.id, storageBlobDataContributor)
  scope: storage
  properties: {
    roleDefinitionId: storageBlobDataContributor
    principalId: workspace.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

output workspaceId string = workspace.id
output workspaceName string = workspace.name
output trainingClusterName string = trainingCluster.name
output stage string = env
