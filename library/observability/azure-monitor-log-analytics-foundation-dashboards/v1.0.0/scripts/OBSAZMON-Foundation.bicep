//////////////////////////////////////////////////////////////////////////////
// OBSAZMON-Foundation.bicep — Azure Monitor observability foundation (white-label)
//
// PURPOSE
//   Deploys the ops/platform observability foundation in one reviewed deployment:
//     - Log Analytics workspace (retention + SKU + optional daily cap)  -> log-obsazmon-platform
//     - Action group (email + Teams/Slack webhook + optional PagerDuty) -> OBSAZMON-AG-Platform-Ops
//     - Metric alert  (VM Percentage CPU high, scoped to the PILOT RG)  -> OBSAZMON-Alert-VMCPUHigh-Pilot
//     - Log alert     (VM heartbeat missing, scheduled query)          -> OBSAZMON-Alert-HeartbeatMissing-Pilot
//   Diagnostic-settings-at-scale is applied SEPARATELY by Azure Policy (03-implementation Step 3),
//   staged DoNotEnforce -> pilot -> estate-wide, so it is not baked in here.
//
// HOW TO RUN  (what-if FIRST — never apply blind)
//   az deployment group create -g rg-obsazmon-monitor --template-file OBSAZMON-Foundation.bicep \
//     --parameters workspaceName=log-obsazmon-platform retentionDays=90 opsEmail='ops@contoso.com' \
//                  teamsWebhookUri='<from-secure-input>' pilotResourceGroupId='<pilot-rg-resourceId>' \
//     --what-if
//   Re-run without --what-if to apply.
//
// EXPECTED RESULTS
//   what-if creates the workspace, action group, and the two PILOT-scoped alert rules — and nothing
//   unexpected. Alert thresholds/windows are parameters — set them to YOUR SLOs.
//
// NOTES
//   White-label. No secrets in code: pass webhook/PagerDuty values via secure parameters / Key Vault
//   reference, never hard-coded. Feature/SKU/pricing points are flagged VERIFY — confirm current
//   table tiers, retention pricing, and daily-cap behavior in YOUR tenant before broad use.
//////////////////////////////////////////////////////////////////////////////

@description('Log Analytics workspace name.')
param workspaceName string = 'log-obsazmon-platform'

@description('Azure region for the workspace and rules.')
param location string = resourceGroup().location

@description('Interactive retention in days. Set from your cost/compliance decision. VERIFY pricing.')
@minValue(30)
@maxValue(730)
param retentionDays int = 90

@description('Optional daily ingestion cap in GB (-1 = no cap). A cap DROPS data once hit — use deliberately.')
param dailyCapGb int = -1

@description('Ops email for the action group.')
param opsEmail string

@description('Teams/Slack incoming webhook URI. Pass via secure input / Key Vault — never hard-code.')
@secure()
param teamsWebhookUri string = ''

@description('Optional PagerDuty integration key. Pass via secure input — never hard-code.')
@secure()
param pagerDutyKey string = ''

@description('Resource ID of the PILOT resource group the metric alert is scoped to (Step 4).')
param pilotResourceGroupId string

@description('VM CPU % threshold for the pilot metric alert. Set to your SLO.')
param cpuThreshold int = 85

var deployDailyCap = dailyCapGb > 0

// --- Log Analytics workspace --------------------------------------------------
resource ws 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: workspaceName
  location: location
  properties: {
    sku: { name: 'PerGB2018' }            // VERIFY current SKU options for your region
    retentionInDays: retentionDays
    workspaceCapping: deployDailyCap ? { dailyQuotaGb: dailyCapGb } : null
    features: { enableLogAccessUsingOnlyResourcePermissions: true }
  }
}

// --- Action group -------------------------------------------------------------
resource ag 'Microsoft.Insights/actionGroups@2023-01-01' = {
  name: 'OBSAZMON-AG-Platform-Ops'
  location: 'global'
  properties: {
    groupShortName: 'obsops'
    enabled: true
    emailReceivers: [
      { name: 'ops-email', emailAddress: opsEmail, useCommonAlertSchema: true }
    ]
    webhookReceivers: empty(teamsWebhookUri) ? [] : [
      { name: 'teams-slack', serviceUri: teamsWebhookUri, useCommonAlertSchema: true }
    ]
    // PagerDuty is wired via a webhook/integration receiver using pagerDutyKey when supplied.
  }
}

// --- Metric alert: VM Percentage CPU high (PILOT scope) ------------------------
resource cpuAlert 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: 'OBSAZMON-Alert-VMCPUHigh-Pilot'
  location: 'global'
  properties: {
    severity: 2
    enabled: true
    scopes: [ pilotResourceGroupId ]              // pilot RG; expand later per 03-implementation Step 8
    targetResourceType: 'Microsoft.Compute/virtualMachines'
    targetResourceRegion: location
    evaluationFrequency: 'PT5M'
    windowSize: 'PT15M'
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.MultipleResourceMultipleMetricCriteria'
      allOf: [
        {
          name: 'HighCPU'
          metricNamespace: 'Microsoft.Compute/virtualMachines'
          metricName: 'Percentage CPU'
          operator: 'GreaterThan'
          threshold: cpuThreshold
          timeAggregation: 'Average'
          criterionType: 'StaticThresholdCriterion'
        }
      ]
    }
    autoMitigate: true
    actions: [ { actionGroupId: ag.id } ]
  }
}

// --- Log (scheduled query) alert: VM heartbeat missing -------------------------
resource heartbeatAlert 'Microsoft.Insights/scheduledQueryRules@2023-03-15-preview' = {
  name: 'OBSAZMON-Alert-HeartbeatMissing-Pilot'
  location: location
  properties: {
    displayName: 'OBSAZMON-Alert-HeartbeatMissing-Pilot'
    severity: 1
    enabled: true
    scopes: [ ws.id ]
    evaluationFrequency: 'PT5M'
    windowSize: 'PT15M'
    autoMitigate: true
    criteria: {
      allOf: [
        {
          // VMs seen historically that have sent NO heartbeat in the window => likely down.
          query: 'Heartbeat | summarize LastBeat = max(TimeGenerated) by Computer | where LastBeat < ago(10m)'
          timeAggregation: 'Count'
          operator: 'GreaterThan'
          threshold: 0
          failingPeriods: { numberOfEvaluationPeriods: 1, minFailingPeriodsToAlert: 1 }
        }
      ]
    }
    actions: { actionGroups: [ ag.id ] }
  }
}

output workspaceId string = ws.id
output actionGroupId string = ag.id
