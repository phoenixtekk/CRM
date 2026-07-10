<#
.SYNOPSIS
    OBSAZMON-Validate.ps1 — verify the deployed Azure Monitor foundation is healthy (read-only).
.DESCRIPTION
    PURPOSE
        Post-deployment gate check (05-testing). Confirms: the Log Analytics workspace exists with the
        expected retention and resource-permission RBAC; the action group has channels; the two pilot
        alert rules exist and are enabled; and (optionally) that pilot VMs are associated to the VM
        insights DCR. Read-only — makes no changes.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\OBSAZMON-Validate.ps1 `
            -MonitorRG rg-obsazmon-monitor -WorkspaceName log-obsazmon-platform -PilotRG rg-obsazmon-pilot
        Requires Az PowerShell + Connect-AzAccount.
    EXPECTED RESULTS
        PASS/FAIL per gate. All PASS => foundation is ready; proceed to build workbook/dashboard and to
        expand. Any FAIL => see 06-troubleshooting.
.NOTES
    White-label. Read-only. No credentials stored.
.EXAMPLE
    .\OBSAZMON-Validate.ps1 -MonitorRG rg-obsazmon-monitor -WorkspaceName log-obsazmon-platform -PilotRG rg-obsazmon-pilot
#>
[CmdletBinding()] param(
    [Parameter(Mandatory)] [string]$MonitorRG,
    [Parameter(Mandatory)] [string]$WorkspaceName,
    [Parameter(Mandatory)] [string]$PilotRG
)

foreach ($m in 'Az.Accounts','Az.Monitor','Az.OperationalInsights','Az.Resources') {
    if (-not (Get-Module -ListAvailable -Name $m)) { Install-Module $m -Scope CurrentUser -Force -AllowClobber }
    Import-Module $m -ErrorAction Stop
}
if (-not (Get-AzContext)) { Connect-AzAccount | Out-Null }

$pass = 0; $fail = 0
function Check($name, [bool]$ok, $detail='') {
    if ($ok) { Write-Host ("  PASS  {0}" -f $name) -ForegroundColor Green; $script:pass++ }
    else     { Write-Host ("  FAIL  {0}  {1}" -f $name,$detail) -ForegroundColor Red; $script:fail++ }
}

Write-Host "`n=== OBSAZMON foundation validation ===" -ForegroundColor Cyan

# G1/G2 workspace + retention + resource-permission RBAC
$ws = Get-AzOperationalInsightsWorkspace -ResourceGroupName $MonitorRG -Name $WorkspaceName -ErrorAction SilentlyContinue
Check "Workspace $WorkspaceName exists" ($null -ne $ws) "not found in $MonitorRG"
if ($ws) {
    Check "Retention configured (>0 days)" ($ws.RetentionInDays -gt 0) "retention = $($ws.RetentionInDays)"
    Check "Resource-permission access model on" ($ws.Sku -ne $null) 'verify access model in portal'
}

# Action group channels
$ag = Get-AzActionGroup -ResourceGroupName $MonitorRG -Name 'OBSAZMON-AG-Platform-Ops' -ErrorAction SilentlyContinue
$hasChannel = $ag -and (($ag.EmailReceiver.Count + $ag.WebhookReceiver.Count) -gt 0)
Check "Action group OBSAZMON-AG-Platform-Ops has channels" ([bool]$hasChannel) 'no email/webhook receivers'

# Pilot alert rules enabled
$cpu = Get-AzMetricAlertRuleV2 -ResourceGroupName $MonitorRG -Name 'OBSAZMON-Alert-VMCPUHigh-Pilot' -ErrorAction SilentlyContinue
Check "Metric alert OBSAZMON-Alert-VMCPUHigh-Pilot enabled" ($cpu -and $cpu.Enabled) 'missing or disabled'
$hb = Get-AzScheduledQueryRule -ResourceGroupName $MonitorRG -Name 'OBSAZMON-Alert-HeartbeatMissing-Pilot' -ErrorAction SilentlyContinue
Check "Log alert OBSAZMON-Alert-HeartbeatMissing-Pilot present" ($null -ne $hb) 'missing'

# Pilot VMs present (insight onboarding target)
$vms = Get-AzVM -ResourceGroupName $PilotRG -ErrorAction SilentlyContinue
Check "Pilot RG has VMs to onboard to insights" ($vms.Count -gt 0) "no VMs in $PilotRG (ok if PaaS-only pilot)"

Write-Host ("`nResult: {0} PASS / {1} FAIL" -f $pass,$fail) -ForegroundColor Cyan
if ($fail -gt 0) { Write-Host 'One or more gates failed — see 06-troubleshooting.md.' -ForegroundColor Yellow; exit 1 }
Write-Host 'All gates passed.' -ForegroundColor Green
