// =============================================================================
// AIRAG-infra.bicep — Enterprise RAG Platform on Azure (infrastructure as code)
//
// PURPOSE
//   Deploy the RAG platform's Azure infrastructure as code, private-by-default:
//     - Azure AI Search   (Semantic ranker enabled; hosts the permission-trimmed index)
//     - Azure OpenAI      + an embedding deployment (rag-embeddings) and a chat
//                           deployment (rag-chat)
//     - Storage account   for source documents (RAG Storage - Source - NonProd)
//     - User-assigned managed identity (keyless service-to-service auth)
//     - Public network access DISABLED on Search + OpenAI (reach them via private
//       endpoints created in your networking stack / the AI landing zone)
//
// HOW TO RUN  (ALWAYS what-if first — never blind-apply; non-prod resource group first)
//   az login
//   az group create -n rg-rag-platform-nonprod -l <region>
//   az deployment group what-if -g rg-rag-platform-nonprod \
//       -f AIRAG-infra.bicep -p AIRAG-infra.bicepparam        // <-- review (the gate)
//   az deployment group create  -g rg-rag-platform-nonprod \
//       -f AIRAG-infra.bicep -p AIRAG-infra.bicepparam        // only after review+approval
//   Rollback: az group delete -n rg-rag-platform-nonprod      // destroys THIS non-prod stack
//
//   After deploy, assign the managed identity LEAST-PRIVILEGE data-plane roles:
//     - Search Index Data Contributor + Search Index Data Reader (on the Search service)
//     - Cognitive Services OpenAI User                          (on the OpenAI resource)
//   (role assignments are intentionally kept OUT of this template — grant at the
//    narrowest scope with your governance process.)
//
// EXPECTED RESULTS
//   A private, keyless RAG foundation — Search (semantic) + OpenAI (embeddings + chat) +
//   source storage + managed identity, public access disabled — ready for the Python
//   ingestion pipeline (AIRAG-Ingest.py) to build the permission-trimmed index.
//
// NOTES
//   White-label. What-if first. Non-prod first. Model names/versions, Search tier
//   feature/pricing, and semantic-ranker availability move between GA and preview and
//   vary by region — values here are placeholders you MUST verify for your subscription.
// =============================================================================

targetScope = 'resourceGroup'

@description('Deployment location.')
param location string = resourceGroup().location

@description('Short name stem used to build resource names, e.g. "ragnonprod".')
@minLength(3)
@maxLength(11)
param namePrefix string = 'ragnonprod'

@description('Azure AI Search SKU. Must support vector + semantic ranking. Verify current tiers.')
@allowed([ 'basic', 'standard', 'standard2', 'standard3' ])
param searchSku string = 'standard'

@description('Azure OpenAI embedding model. Verify current model/version/dimensions in your region.')
param embeddingModel string = 'text-embedding-3-large'
param embeddingModelVersion string = '1'

@description('Azure OpenAI chat model. Verify current model/version/region.')
param chatModel string = 'gpt-4o'
param chatModelVersion string = '2024-08-06'

@description('Capacity (TPM in thousands) for each model deployment. Size embeddings for ingestion; verify quota.')
param embeddingCapacity int = 50
param chatCapacity int = 20

// Names follow the solution's <Purpose> - <Scope> - <Stage> convention.
var searchName   = 'srch-${namePrefix}'            // RAG Search  - Platform - NonProd
var openAiName   = 'oai-${namePrefix}'             // RAG OpenAI  - Platform - NonProd
var storageName  = toLower('strag${namePrefix}')   // RAG Storage - Source   - NonProd
var identityName = 'id-${namePrefix}-platform'     // RAG Identity- Platform - NonProd

var commonTags = {
  solution: 'Enterprise RAG on Azure'
  stage: 'NonProd'
}

// ---------------------------------------------------------------------------
// User-assigned managed identity — keyless auth for the pipeline + orchestration.
// Grant data-plane roles (Search Data Contributor/Reader, OpenAI User) AFTER deploy.
// ---------------------------------------------------------------------------
resource identity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: identityName
  location: location
  tags: commonTags
}

// ---------------------------------------------------------------------------
// Azure AI Search — private, semantic ranking enabled.
// ---------------------------------------------------------------------------
resource search 'Microsoft.Search/searchServices@2024-06-01-preview' = {
  name: searchName
  location: location
  tags: commonTags
  sku: {
    name: searchSku
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    replicaCount: 1
    partitionCount: 1
    // Semantic ranker (billable add-on). 'standard' enables it; verify current options.
    semanticSearch: 'standard'
    // Private-by-default: no public endpoint. Reach via private endpoint.
    publicNetworkAccess: 'disabled'
    // Prefer Entra (RBAC) data-plane auth over keys.
    authOptions: null
    disableLocalAuth: true
  }
}

// ---------------------------------------------------------------------------
// Azure OpenAI — private, custom subdomain (required for Entra data-plane auth).
// ---------------------------------------------------------------------------
resource openai 'Microsoft.CognitiveServices/accounts@2024-10-01' = {
  name: openAiName
  location: location
  tags: commonTags
  kind: 'OpenAI'
  sku: {
    name: 'S0'
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    customSubDomainName: openAiName
    publicNetworkAccess: 'Disabled'
    disableLocalAuth: true
  }
}

// Embedding deployment — rag-embeddings (RAG Embeddings - Model - NonProd).
// Dimensions of this model MUST match the index `contentVector` field.
resource embeddingDeployment 'Microsoft.CognitiveServices/accounts/deployments@2024-10-01' = {
  parent: openai
  name: 'rag-embeddings'
  sku: {
    name: 'Standard'
    capacity: embeddingCapacity
  }
  properties: {
    model: {
      format: 'OpenAI'
      name: embeddingModel
      version: embeddingModelVersion
    }
  }
}

// Chat deployment — rag-chat (RAG Chat - Model - NonProd). Deploy AFTER embeddings.
resource chatDeployment 'Microsoft.CognitiveServices/accounts/deployments@2024-10-01' = {
  parent: openai
  name: 'rag-chat'
  dependsOn: [ embeddingDeployment ]
  sku: {
    name: 'Standard'
    capacity: chatCapacity
  }
  properties: {
    model: {
      format: 'OpenAI'
      name: chatModel
      version: chatModelVersion
    }
  }
}

// ---------------------------------------------------------------------------
// Source-document storage — private, no public blob access, TLS 1.2+.
// ---------------------------------------------------------------------------
resource storage 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: storageName
  location: location
  tags: commonTags
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    allowBlobPublicAccess: false
    allowSharedKeyAccess: false
    minimumTlsVersion: 'TLS1_2'
    publicNetworkAccess: 'Disabled'
    networkAcls: {
      defaultAction: 'Deny'
    }
  }
}

// ---------------------------------------------------------------------------
// Outputs — consumed by AIRAG-Ingest.py / AIRAG-Validate.py.
// (No keys are emitted — auth is keyless via the managed identity + RBAC.)
// ---------------------------------------------------------------------------
output searchEndpoint string = 'https://${search.name}.search.windows.net'
output openAiEndpoint string = openai.properties.endpoint
output embeddingDeploymentName string = embeddingDeployment.name
output chatDeploymentName string = chatDeployment.name
output storageAccountName string = storage.name
output managedIdentityClientId string = identity.properties.clientId
output managedIdentityPrincipalId string = identity.properties.principalId
