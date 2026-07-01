<#
.SYNOPSIS
    TEAMSSBC-Report — Export the Microsoft Teams Phone Direct Routing voice
    configuration and per-user assignment report to CSV.

.DESCRIPTION
    Produces an as-built snapshot suitable for change records and audits:
      - voice-config-summary.csv : gateways, usages, routes, policies, dial plans
        flattened into one rows-per-object summary.
      - user-assignments.csv     : per voice-enabled user, the number and policies.

    READ-ONLY. No changes are made to the tenant.

.PARAMETER OutputPath
    Directory to write the CSV reports. Created if it does not exist.
    Default: .\reports

.EXAMPLE
    .\TEAMSSBC-Report.ps1 -OutputPath .\reports

.NOTES
    Solution : Microsoft Teams Phone Direct Routing with SBC (AudioCodes)
    Category : Azure Solutions — read-only.
    Module   : MicrosoftTeams
    Version  : 1.0.0
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = '.\reports'
)

$ErrorActionPreference = 'Stop'

function Connect-IfNeeded {
    if (-not (Get-Module -ListAvailable -Name MicrosoftTeams)) {
        throw "MicrosoftTeams module is not installed. Run: Install-Module MicrosoftTeams -Scope CurrentUser"
    }
    Import-Module MicrosoftTeams -ErrorAction Stop
    try { $null = Get-CsTenant -ErrorAction Stop }
    catch { Connect-MicrosoftTeams | Out-Null }
}

Connect-IfNeeded

if (-not (Test-Path $OutputPath)) {
    New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
}
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'

Write-Host "=== Teams Phone Direct Routing Report ===" -ForegroundColor Green

# ---- Voice config summary (one flattened table) ----
Write-Host "Collecting voice configuration..." -ForegroundColor Yellow
$summary = New-Object System.Collections.Generic.List[object]

foreach ($gw in Get-CsOnlinePSTNGateway) {
    $summary.Add([pscustomobject]@{
        ObjectType = 'PSTN Gateway'
        Name       = $gw.Identity
        Detail1    = "FQDN=$($gw.Fqdn)"
        Detail2    = "Port=$($gw.SipSignalingPort); Enabled=$($gw.Enabled); OPTIONS=$($gw.SendSipOptions)"
        Detail3    = "MediaBypass=$($gw.MediaBypass); MaxSessions=$($gw.MaxConcurrentSessions); ForwardPai=$($gw.ForwardPai)"
    })
}
foreach ($u in (Get-CsOnlinePstnUsage -Identity Global).Usage) {
    $summary.Add([pscustomobject]@{ ObjectType='PSTN Usage'; Name=$u; Detail1=''; Detail2=''; Detail3='' })
}
foreach ($r in Get-CsOnlineVoiceRoute | Sort-Object Priority) {
    $summary.Add([pscustomobject]@{
        ObjectType = 'Voice Route'
        Name       = $r.Identity
        Detail1    = "Priority=$($r.Priority)"
        Detail2    = "Pattern=$($r.NumberPattern)"
        Detail3    = "Gateways=$($r.OnlinePstnGatewayList -join ';'); Usages=$($r.OnlinePstnUsages -join ';')"
    })
}
foreach ($p in Get-CsOnlineVoiceRoutingPolicy) {
    $summary.Add([pscustomobject]@{
        ObjectType = 'Voice Routing Policy'
        Name       = $p.Identity
        Detail1    = "Usages=$($p.OnlinePstnUsages -join ';')"
        Detail2    = ''
        Detail3    = ''
    })
}
foreach ($d in Get-CsTenantDialPlan) {
    $summary.Add([pscustomobject]@{
        ObjectType = 'Tenant Dial Plan'
        Name       = $d.Identity
        Detail1    = "Description=$($d.Description)"
        Detail2    = "NormalizationRules=$($d.NormalizationRules.Count)"
        Detail3    = ''
    })
}

$configFile = Join-Path $OutputPath "voice-config-summary-$stamp.csv"
$summary | Export-Csv -Path $configFile -NoTypeInformation -Encoding UTF8
Write-Host "  -> $configFile" -ForegroundColor DarkGray

# ---- Per-user assignments ----
Write-Host "Collecting user assignments..." -ForegroundColor Yellow
$users = Get-CsOnlineUser -Filter 'EnterpriseVoiceEnabled -eq $true' -ErrorAction SilentlyContinue
if (-not $users) {
    $users = Get-CsOnlineUser | Where-Object { $_.EnterpriseVoiceEnabled }
}
$userReport = $users | Select-Object `
    UserPrincipalName,
    DisplayName,
    LineUri,
    EnterpriseVoiceEnabled,
    @{N='OnlineVoiceRoutingPolicy';E={ "$($_.OnlineVoiceRoutingPolicy)" }},
    @{N='TenantDialPlan';E={ "$($_.TenantDialPlan)" }}

$userFile = Join-Path $OutputPath "user-assignments-$stamp.csv"
$userReport | Export-Csv -Path $userFile -NoTypeInformation -Encoding UTF8
Write-Host "  -> $userFile" -ForegroundColor DarkGray

Write-Host "`nReport complete." -ForegroundColor Green
Write-Host ("  Config objects : {0}" -f $summary.Count)
Write-Host ("  Voice users    : {0}" -f ($userReport | Measure-Object).Count)
