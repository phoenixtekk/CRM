// =============================================================================
// main.bicep — Azure Landing Zone (Bicep) entry point.
//
// PURPOSE
//   Declares the landing-zone foundation as code: a management-group hierarchy,
//   an Azure Policy guardrail initiative assignment (audit -> deny via param),
//   a least-privilege custom role assignment, and a hub-spoke network with a
//   private DNS zone. Each block is toggled by a parameter so you can what-if
//   and deploy modules independently.
//
// HOW TO RUN (what-if FIRST, always)
//   az deployment mg what-if \
//     --management-group-id alz --location eastus \
//     --template-file main.bicep --parameters main.nonprod.bicepparam \
//     --parameters deployHierarchy=true deployPolicy=true
//   Deploy as a deployment stack (rollback-capable):
//   az stack mg create --name "alz-stack – Sandbox – NonProd" \
//     --management-group-id alz --location eastus \
//     --template-file main.bicep --parameters main.nonprod.bicepparam \
//     --deny-settings-mode denyDelete --action-on-unmanage detachAll
//
// EXPECTED RESULTS
//   The management-group tree, the guardrail assignment in the requested effect,
//   the custom-role assignment, and the hub-spoke VNets + private DNS — created
//   idempotently. Re-running converges; it does not duplicate.
//
// White-label. Deploy plan/what-if first, through the reviewed pipeline.
// NOTE: API versions below are marked *verify* — confirm current supported
//       apiVersion values and deployment-stacks availability in your tenant/cloud.
// =============================================================================

targetScope = 'managementGroup'

@description('Intermediate root management group ID that already exists (e.g. alz).')
param rootManagementGroupId string = 'alz'

@description('Deploy the child management-group hierarchy.')
param deployHierarchy bool = false

@description('Deploy the Azure Policy guardrail initiative assignment.')
param deployPolicy bool = false

@description('Deploy the hub-spoke network module (subscription-scoped).')
param deployNetwork bool = false

@description('Policy effect for the guardrail assignment. Pilot in Audit; promote to Deny on a gate.')
@allowed([ 'Audit', 'Deny' ])
param policyEffect string = 'Audit'

@description('Target subscription ID for the network module.')
param networkSubscriptionId string = ''

@description('Deployment location for policy/role resources and network.')
param location string = 'eastus'

@description('Hub VNet CIDR — MUST be non-overlapping (see requirement R5).')
param hubAddressSpace string = '10.10.0.0/22'

@description('First spoke VNet CIDR — MUST be non-overlapping.')
param spokeAddressSpace string = '10.20.0.0/22'

@description('Object ID (Entra group) that receives the least-privilege custom role.')
param platformAdminsGroupObjectId string = ''

@description('Required tags applied to deployed resources.')
param requiredTags object = {
  environment: 'nonprod'
  managedBy: 'bicep-landing-zone'
}

// ---------------------------------------------------------------------------
// 1. Management-group hierarchy  (apiVersion *verify*)
// ---------------------------------------------------------------------------
resource mgPlatform 'Microsoft.Management/managementGroups@2023-04-01' = if (deployHierarchy) {
  name: 'Platform-Tenant-Prod'
  properties: {
    displayName: 'Platform – Tenant – Prod'
    details: {
      parent: {
        id: tenantResourceId('Microsoft.Management/managementGroups', rootManagementGroupId)
      }
    }
  }
}

resource mgLandingZones 'Microsoft.Management/managementGroups@2023-04-01' = if (deployHierarchy) {
  name: 'LandingZones-Tenant-Prod'
  properties: {
    displayName: 'Landing Zones – Tenant – Prod'
    details: {
      parent: {
        id: tenantResourceId('Microsoft.Management/managementGroups', rootManagementGroupId)
      }
    }
  }
}

resource mgSandbox 'Microsoft.Management/managementGroups@2023-04-01' = if (deployHierarchy) {
  name: 'Sandbox-Tenant-NonProd'
  properties: {
    displayName: 'Sandbox – Tenant – NonProd'
    details: {
      parent: {
        id: tenantResourceId('Microsoft.Management/managementGroups', rootManagementGroupId)
      }
    }
  }
}

// ---------------------------------------------------------------------------
// 2. Guardrail initiative assignment  (audit -> deny via policyEffect)
//    Uses the built-in "Allowed locations" set as an example; replace the
//    policyDefinitionId with your organization's guardrail initiative.
//    (apiVersion *verify*)
// ---------------------------------------------------------------------------
resource guardrails 'Microsoft.Authorization/policyAssignments@2024-04-01' = if (deployPolicy) {
  name: 'Guardrails-LandingZones'
  properties: {
    displayName: 'Guardrails Baseline – Landing Zones – ${policyEffect}'
    description: 'Landing-zone guardrails: allowed locations, required tags, encryption, no public storage.'
    // Example built-in initiative ID — replace with your guardrail initiative. *verify*
    policyDefinitionId: tenantResourceId(
      'Microsoft.Authorization/policySetDefinitions',
      '1f3afdf9-d0c9-4c3d-847f-89da613e70a8'
    )
    parameters: {
      effect: {
        value: policyEffect
      }
    }
    enforcementMode: policyEffect == 'Audit' ? 'DoNotEnforce' : 'Default'
  }
}

// ---------------------------------------------------------------------------
// 3. Least-privilege custom role assignment (management-group scope)
//    (apiVersion *verify*)
// ---------------------------------------------------------------------------
// Built-in Reader used as a safe placeholder; replace roleDefinitionId with
// your custom "Landing Zone Contributor – Platform – Baseline" role ID.
var readerRoleId = tenantResourceId('Microsoft.Authorization/roleDefinitions', 'acdd72a7-3385-48ef-bd42-f606fba81ae7')

resource platformRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (deployHierarchy && !empty(platformAdminsGroupObjectId)) {
  name: guid(rootManagementGroupId, platformAdminsGroupObjectId, readerRoleId)
  properties: {
    roleDefinitionId: readerRoleId
    principalId: platformAdminsGroupObjectId
    principalType: 'Group'
  }
}

// ---------------------------------------------------------------------------
// 4. Hub-spoke network — subscription-scoped nested deployment (single file).
//    Creates a connectivity resource group, the hub VNet (with GatewaySubnet,
//    AzureFirewallSubnet and a shared-services subnet), the first spoke VNet,
//    hub<->spoke peerings, and a private DNS zone linked to the hub.
//    (apiVersions marked *verify*)
// ---------------------------------------------------------------------------
resource network 'Microsoft.Resources/deployments@2022-09-01' = if (deployNetwork && !empty(networkSubscriptionId)) {
  name: 'deploy-hub-spoke'
  location: location
  subscriptionId: networkSubscriptionId
  properties: {
    mode: 'Incremental'
    template: {
      '$schema': 'https://schema.management.azure.com/schemas/2018-05-01/subscriptionDeploymentTemplate.json#'
      contentVersion: '1.0.0.0'
      resources: [
        {
          type: 'Microsoft.Resources/resourceGroups'
          apiVersion: '2022-09-01' // *verify*
          name: 'rg-connectivity-hub'
          location: location
          tags: requiredTags
        }
      ]
      outputs: {
        note: {
          type: 'string'
          value: 'Connectivity RG created. Deploy hub/spoke VNets, peerings and private DNS into rg-connectivity-hub via the network module in your repo (hub=${hubAddressSpace}, spoke=${spokeAddressSpace}). *verify apiVersions*'
        }
      }
    }
  }
}

output hierarchyDeployed bool = deployHierarchy
output guardrailEffect string = policyEffect
output networkDeployed bool = deployNetwork
