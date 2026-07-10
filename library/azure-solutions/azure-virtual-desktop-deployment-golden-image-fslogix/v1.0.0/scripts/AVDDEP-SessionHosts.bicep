// =============================================================================
//  AVDDEP-SessionHosts.bicep
//  Azure Virtual Desktop — session-host deployment from a golden image, with a
//  scaling plan. Deploy session hosts reproducibly from a versioned Azure
//  Compute Gallery image instead of hand-building VMs.
//
//  PURPOSE
//    Creates (or updates) a pooled host pool, a workspace + Desktop application
//    group, N session-host VMs built from a specified gallery image version, and
//    a scaling plan bound to the host pool. A fresh host-pool registration token
//    is minted at deploy time so new hosts join automatically.
//
//  HOW TO RUN — ALWAYS what-if FIRST, then create:
//    az deployment group what-if \
//      --resource-group "AVD - Resource Group - Core" \
//      --template-file AVDDEP-SessionHosts.bicep \
//      --parameters @avddep.pilot.parameters.json
//    # review output — must CREATE the pool/VMs/plan, DELETE nothing — then:
//    az deployment group create ... (same args)
//
//  EXPECTED RESULTS
//    A host pool ('AVD - Host Pool - Pilot' by default), workspace, Desktop app
//    group, `sessionHostCount` VMs from image version `galleryImageId`, and an
//    enabled scaling plan. Pilot with sessionHostCount=2; expand by raising it.
//
//  NOTES
//    White-label. Pilot-first and plan/what-if-first by design. Do not embed
//    secrets: pass adminPassword via a secure parameter or Key Vault reference,
//    never hard-coded. Verify VM SKU/image availability in your region.
// =============================================================================

@description('Azure region for all resources.')
param location string = resourceGroup().location

@description('Host pool name (logical: AVD - Host Pool - Pilot). Pilot first.')
param hostPoolName string = 'AVD-Host-Pool-Pilot'

@description('Workspace name (logical: AVD - Workspace - Core).')
param workspaceName string = 'AVD-Workspace-Core'

@description('Desktop application group name (logical: AVD - Desktop App Group - Pilot).')
param appGroupName string = 'AVD-Desktop-App-Group-Pilot'

@description('Scaling plan name (logical: AVD - Scaling Plan - Pilot).')
param scalingPlanName string = 'AVD-Scaling-Plan-Pilot'

@description('Resource ID of the Azure Compute Gallery image VERSION to build hosts from (e.g. .../galleries/avd_compute_gallery_core/images/avd-win11-m365-multisession/versions/1.0.0).')
param galleryImageId string

@description('Number of session hosts. Pilot = 2. Raise to expand.')
@minValue(1)
@maxValue(100)
param sessionHostCount int = 2

@description('Session-host VM size. Right-size to session density.')
param vmSize string = 'Standard_D4as_v5'

@description('Resource ID of the subnet the session hosts attach to.')
param subnetId string

@description('Prefix for session-host VM names (logical: AVD - Session Host - Pilot).')
param vmNamePrefix string = 'avdsh-pilot'

@description('Local admin username for the session hosts.')
param adminUsername string

@description('Local admin password. Pass securely (Key Vault reference / secure param) — never hard-code.')
@secure()
param adminPassword string

@description('Token expiration time (ISO 8601, UTC) for host-pool registration. Keep short; minted at deploy time.')
param tokenExpirationTime string = dateTimeAdd(utcNow('u'), 'PT4H')

// ---------------------------------------------------------------------------
//  Host pool (pooled, breadth-first) with a freshly minted registration token
// ---------------------------------------------------------------------------
resource hostPool 'Microsoft.DesktopVirtualization/hostPools@2023-09-05' = {
  name: hostPoolName
  location: location
  properties: {
    hostPoolType: 'Pooled'
    loadBalancerType: 'BreadthFirst'
    preferredAppGroupType: 'Desktop'
    maxSessionLimit: 8
    startVMOnConnect: true
    registrationInfo: {
      expirationTime: tokenExpirationTime
      registrationTokenOperation: 'Update'
    }
  }
}

// ---------------------------------------------------------------------------
//  Desktop application group + workspace
// ---------------------------------------------------------------------------
resource appGroup 'Microsoft.DesktopVirtualization/applicationGroups@2023-09-05' = {
  name: appGroupName
  location: location
  properties: {
    hostPoolArmPath: hostPool.id
    applicationGroupType: 'Desktop'
  }
}

resource workspace 'Microsoft.DesktopVirtualization/workspaces@2023-09-05' = {
  name: workspaceName
  location: location
  properties: {
    applicationGroupReferences: [
      appGroup.id
    ]
  }
}

// ---------------------------------------------------------------------------
//  Session-host NICs + VMs, built from the gallery image version
// ---------------------------------------------------------------------------
resource nics 'Microsoft.Network/networkInterfaces@2023-09-01' = [for i in range(0, sessionHostCount): {
  name: '${vmNamePrefix}-${i}-nic'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: subnetId
          }
          privateIPAllocationMethod: 'Dynamic'
        }
      }
    ]
  }
}]

resource sessionHosts 'Microsoft.Compute/virtualMachines@2023-09-01' = [for i in range(0, sessionHostCount): {
  name: '${vmNamePrefix}-${i}'
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    storageProfile: {
      imageReference: {
        id: galleryImageId
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Premium_LRS'
        }
      }
    }
    osProfile: {
      computerName: '${vmNamePrefix}-${i}'
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nics[i].id
        }
      ]
    }
    securityProfile: {
      securityType: 'TrustedLaunch'
    }
  }
}]

// NOTE: after VM creation, the AVD agent + registration are applied via a
// DSC/Custom Script extension using hostPool.properties.registrationInfo.token.
// That extension is intentionally left as a documented follow-on so the token
// is never rendered into a stored template output. See 03-implementation Step 6.

// ---------------------------------------------------------------------------
//  Scaling plan bound to the host pool (cost control)
// ---------------------------------------------------------------------------
resource scalingPlan 'Microsoft.DesktopVirtualization/scalingPlans@2023-09-05' = {
  name: scalingPlanName
  location: location
  properties: {
    hostPoolType: 'Pooled'
    timeZone: 'UTC'
    hostPoolReferences: [
      {
        hostPoolArmPath: hostPool.id
        scalingPlanEnabled: true
      }
    ]
    schedules: [
      {
        name: 'Weekdays'
        daysOfWeek: [ 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday' ]
        rampUpStartTime: { hour: 7, minute: 0 }
        rampUpLoadBalancingAlgorithm: 'BreadthFirst'
        rampUpMinimumHostsPct: 20
        rampUpCapacityThresholdPct: 60
        peakStartTime: { hour: 9, minute: 0 }
        peakLoadBalancingAlgorithm: 'BreadthFirst'
        rampDownStartTime: { hour: 18, minute: 0 }
        rampDownLoadBalancingAlgorithm: 'DepthFirst'
        rampDownMinimumHostsPct: 10
        rampDownCapacityThresholdPct: 75
        rampDownForceLogoffUsers: false
        rampDownWaitTimeMinutes: 30
        rampDownNotificationMessage: 'You will be signed off soon. Please save your work.'
        rampDownStopHostsWhen: 'ZeroActiveSessions'
        offPeakStartTime: { hour: 20, minute: 0 }
        offPeakLoadBalancingAlgorithm: 'DepthFirst'
      }
    ]
  }
}

output hostPoolResourceId string = hostPool.id
output workspaceResourceId string = workspace.id
output deployedSessionHostCount int = sessionHostCount
