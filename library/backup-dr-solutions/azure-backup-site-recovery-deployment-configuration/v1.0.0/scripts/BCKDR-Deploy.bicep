/*
=============================================================================
  BCKDR-Deploy.bicep - Deploy hardened Azure Backup vaults + backup policies.

  PURPOSE
      Declarative deployment for the "Azure Backup & Site Recovery -
      Deployment & Configuration" solution (Stage 2 - Configure). Creates:
        - Recovery Services Vault - Core - Configure   (rsv-backup-core-prod)
            with SOFT DELETE enabled and IMMUTABILITY per parameter.
        - Backup Vault - Object - Configure            (bvault-backup-object-prod)
            with its own soft delete + immutability, for blob backup.
        - VM Backup Policy - Daily-30d - Configure     (bkpol-vm-daily-30d)
        - Files Backup Policy - Daily-30d - Configure  (bkpol-files-daily-30d)
      (SQL-in-VM and vaulted-blob policies are created in-console/CLI after the
       SQL workload and blob datasource are registered - see 03-implementation.md.)

  HOW TO RUN  (ALWAYS what-if FIRST - never apply blind)
      az deployment group what-if -g rg-backup-core-prod \
        --template-file BCKDR-Deploy.bicep --parameters immutabilityState=Unlocked
      az deployment group create -g rg-backup-core-prod \
        --template-file BCKDR-Deploy.bicep --parameters immutabilityState=Unlocked

  EXPECTED RESULTS
      Two hardened vaults and two backup policies in the target resource group.
      Leave immutabilityState=Unlocked until Stage 4 (Validate) proves the config;
      set to Locked deliberately in Stage 5 - LOCKING IS IRREVERSIBLE.

  NOTE
      White-label. Verify current API versions / immutability + soft-delete
      property support in your tenant; property paths drift between API versions.
=============================================================================
*/

@description('Azure region for the vaults.')
param location string = resourceGroup().location

@description('Recovery Services vault name.')
param recoveryServicesVaultName string = 'rsv-backup-core-prod'

@description('Backup vault (Data Protection) name for blob/disk backup.')
param backupVaultName string = 'bvault-backup-object-prod'

@description('Soft-delete retention in days (14-180).')
@minValue(14)
@maxValue(180)
param softDeleteRetentionDays int = 14

@description('Immutability state for both vaults. Keep Unlocked until validated; Locked is IRREVERSIBLE.')
@allowed([ 'Disabled', 'Unlocked', 'Locked' ])
param immutabilityState string = 'Unlocked'

@description('Daily backup time (UTC, HH:mm) for VM/Files policies.')
param backupTimeUtc string = '2026-01-01T23:00:00Z'

// --------------------------------------------------------------------------
// Recovery Services vault (VM / Files / SQL-in-VM / ASR) with hardening
// --------------------------------------------------------------------------
resource rsv 'Microsoft.RecoveryServices/vaults@2024-04-01' = {
  name: recoveryServicesVaultName
  location: location
  sku: {
    name: 'RS0'
    tier: 'Standard'
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    securitySettings: {
      immutabilitySettings: {
        state: immutabilityState
      }
      softDeleteSettings: {
        softDeleteState: 'Enabled'
        softDeleteRetentionPeriodInDays: softDeleteRetentionDays
      }
    }
    publicNetworkAccess: 'Enabled'
  }
}

// Cross-region restore + storage redundancy config for the RS vault
resource rsvBackupConfig 'Microsoft.RecoveryServices/vaults/backupconfig@2024-04-01' = {
  parent: rsv
  name: 'vaultconfig'
  properties: {
    enhancedSecurityState: 'Enabled'
    softDeleteFeatureState: 'Enabled'
    storageModelType: 'GeoRedundant'
    crossRegionRestoreFlag: true
  }
}

// VM Backup Policy - Daily-30d - Configure
resource vmPolicy 'Microsoft.RecoveryServices/vaults/backupPolicies@2024-04-01' = {
  parent: rsv
  name: 'bkpol-vm-daily-30d'
  properties: {
    backupManagementType: 'AzureIaasVM'
    policyType: 'V2'
    schedulePolicy: {
      schedulePolicyType: 'SimpleSchedulePolicyV2'
      scheduleRunFrequency: 'Daily'
      dailySchedule: {
        scheduleRunTimes: [ backupTimeUtc ]
      }
    }
    retentionPolicy: {
      retentionPolicyType: 'LongTermRetentionPolicy'
      dailySchedule: {
        retentionTimes: [ backupTimeUtc ]
        retentionDuration: {
          count: 30
          durationType: 'Days'
        }
      }
    }
    timeZone: 'UTC'
  }
}

// Files Backup Policy - Daily-30d - Configure
resource filesPolicy 'Microsoft.RecoveryServices/vaults/backupPolicies@2024-04-01' = {
  parent: rsv
  name: 'bkpol-files-daily-30d'
  properties: {
    backupManagementType: 'AzureStorage'
    workLoadType: 'AzureFileShare'
    schedulePolicy: {
      schedulePolicyType: 'SimpleSchedulePolicy'
      scheduleRunFrequency: 'Daily'
      scheduleRunTimes: [ backupTimeUtc ]
    }
    retentionPolicy: {
      retentionPolicyType: 'LongTermRetentionPolicy'
      dailySchedule: {
        retentionTimes: [ backupTimeUtc ]
        retentionDuration: {
          count: 30
          durationType: 'Days'
        }
      }
    }
    timeZone: 'UTC'
  }
}

// --------------------------------------------------------------------------
// Backup vault (Data Protection) for blob backup, with hardening
// --------------------------------------------------------------------------
resource backupVault 'Microsoft.DataProtection/backupVaults@2024-04-01' = {
  name: backupVaultName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    storageSettings: [
      {
        type: 'GeoRedundant'
        datastoreType: 'VaultStore'
      }
    ]
    securitySettings: {
      immutabilitySettings: {
        state: immutabilityState
      }
      softDeleteSettings: {
        state: 'On'
        retentionDurationInDays: softDeleteRetentionDays
      }
    }
  }
}

output recoveryServicesVaultId string = rsv.id
output backupVaultId string = backupVault.id
output vmPolicyName string = vmPolicy.name
output filesPolicyName string = filesPolicy.name
output immutabilityApplied string = immutabilityState
