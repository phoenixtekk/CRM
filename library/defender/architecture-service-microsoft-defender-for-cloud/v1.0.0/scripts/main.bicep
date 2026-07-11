//  main.bicep — REFERENCE ARCHITECTURE SKELETON for "Architecture Service — Microsoft Defender
//  for Cloud". Enables Defender for Cloud plans at MANAGEMENT-GROUP scope so subscriptions inherit
//  protection. Adapt to your naming/policy standards. DEPLOY WHAT-IF FIRST (see ARCMDC-Deploy.ps1).
//
//  PURPOSE
//      A parameterized, wave-driven skeleton that turns the design record
//      ('MDC Architecture Decision Record - Platform - Prod') into infrastructure-as-code:
//      it sets the CSPM plan and the selected workload plans to Standard, at the target
//      management group, via a policy assignment of the built-in Defender-for-Cloud initiative so
//      new + existing subscriptions inherit the configuration. This is a REFERENCE skeleton to
//      review and adapt — not a blind apply.
//  HOW TO DEPLOY (what-if first)
//      # Preview at the pilot management group (changes nothing):
//      az deployment mg what-if --management-group-id <pilotMgId> --location <region> \
//        --template-file main.bicep --parameters wave=1 enableDefenderCspm=true
//      # Apply only after the what-if is reviewed and approved:
//      az deployment mg create   --management-group-id <pilotMgId> --location <region> \
//        --template-file main.bicep --parameters wave=1 enableDefenderCspm=true
//      (ARCMDC-Deploy.ps1 wraps this with a -WhatIf default.)
//  EXPECTED RESULTS
//      A management-group policy assignment that drives Defender-for-Cloud plan enablement across
//      descendant subscriptions, consistent with the wave. Verify with ARCMDC-Validate.ps1.
//  NOTES
//      White-label. Deploy what-if first; paid plans incur cost. Verify current plan availability
//      and the built-in policy/initiative definition ids in your tenant before applying.

targetScope = 'managementGroup'

@description('Rollout wave (1 = CSPM + foundational; later waves add workload plans). Sequences cost.')
@allowed([ 1, 2, 3 ])
param wave int = 1

@description('Enable the paid Defender CSPM (CloudPosture) plan. Verify current pricing/availability.')
param enableDefenderCspm bool = true

@description('Which workload plans to enable in this wave (added in waves 2/3 per the design).')
param workloadPlans array = [
  // e.g. 'VirtualMachines', 'StorageAccounts', 'Containers', 'KeyVaults', 'SqlServers', 'AppServices'
]

@description('Resource ID of the central Log Analytics workspace used for continuous export.')
param logAnalyticsWorkspaceId string = ''

@description('Deployment location for the management-group deployment metadata.')
param location string = 'eastus'

// --- Enforce Defender-for-Cloud plan enablement across the MG via the built-in initiative. ---
// The built-in policy initiative 'Configure Microsoft Defender for Cloud plans' (a.k.a. the
// Defender-for-Cloud auto-provisioning / plan-configuration initiative) is the supported way to
// enable plans at scale so subscriptions INHERIT them. Replace the definitionId below with the
// current built-in initiative id in your tenant (verify — ids are versioned).
@description('Built-in Defender-for-Cloud plan-configuration policy initiative definition id. VERIFY current id in your tenant.')
param defenderInitiativeDefinitionId string = '/providers/Microsoft.Authorization/policySetDefinitions/<VERIFY-defender-for-cloud-initiative-id>'

resource defenderPlansAssignment 'Microsoft.Authorization/policyAssignments@2022-06-01' = {
  name: 'mdc-plans-wave${wave}'
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    displayName: 'MDC Plans - Platform MG - Wave ${wave}'
    description: 'Reference: enable Defender for Cloud plans at MG scope so subscriptions inherit them. Wave ${wave}.'
    policyDefinitionId: defenderInitiativeDefinitionId
    enforcementMode: 'Default' // set to 'DoNotEnforce' to model impact before enforcing
    parameters: {
      // Map the initiative's plan parameters here per wave. CSPM in wave 1; workload plans in later waves.
      // Example shape (parameter names depend on the initiative version — VERIFY):
      // cloudPostureEffect: { value: enableDefenderCspm ? 'DeployIfNotExists' : 'Disabled' }
    }
  }
}

// Optional: continuous-export config is typically deployed per-subscription; the design points
// every subscription's export at this central workspace. Passed through for reference/wiring.
output workspaceForExport string = logAnalyticsWorkspaceId
output assignedInitiative string = defenderInitiativeDefinitionId
output waveDeployed int = wave
output workloadPlansRequested array = workloadPlans
