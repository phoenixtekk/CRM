<#
.SYNOPSIS
    MDCWP-Validate.ps1 — targeted validation of Defender for Cloud workload-plan enablement
    (plan state, Servers agent/MDE coverage, continuous export, notify-only response workflow).
.DESCRIPTION
    PURPOSE
        Read-only validation for the "Microsoft Defender for Cloud — Workload Protection Plans"
        solution. Confirms the area named by -Plan against the Testing Guide gates on the pilot
        subscription: overall plan state, Servers agent/MDE coverage, continuous export, or the
        response workflow (should be notify-only).
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\MDCWP-Validate.ps1 -SubscriptionId <pilot> -Plan All
        -Plan accepts: Servers | Containers | Databases | Storage | Export | Workflow | All (default All).
        Requires Az.Accounts, Az.Security. Sign in with Connect-AzAccount first. Read-only.
    EXPECTED RESULTS
        PASS/REVIEW lines per check with the object names from the Implementation Guide, so you can
        confirm each Testing Guide gate before expanding to more subscriptions.
.NOTES
    White-label. Read-only. Where a setting is portal-only, the script prints the exact path.
    The response workflow must remain notify-only until the SOC decides otherwise.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string]$SubscriptionId,
    [ValidateSet('Servers','Containers','Databases','Storage','Export','Workflow','All')] [string]$Plan = 'All'
)

Import-Module Az.Accounts -ErrorAction Stop
if (-not (Get-AzContext)) { Connect-AzAccount | Out-Null }
Set-AzContext -SubscriptionId $SubscriptionId | Out-Null
Import-Module Az.Security -ErrorAction Stop
Write-Host "`n=== Defender for Cloud — workload-plan validation ($Plan) on $SubscriptionId ===" -ForegroundColor Cyan

$pricings = @()
try { $pricings = Get-AzSecurityPricing -ErrorAction Stop } catch { Write-Host ("   Could not read pricing: {0}" -f $_.Exception.Message) -ForegroundColor Yellow }

function Show-Plan($name) {
    $p = $pricings | Where-Object { $_.Name -eq $name }
    if ($p) {
        $on = $p.PricingTier -eq 'Standard'
        Write-Host ("   {0,-24} {1}  {2}" -f $name, $p.PricingTier, ($(if ($on) { 'PASS (On)' } else { 'REVIEW (Off)' }))) -ForegroundColor $(if ($on) { 'Green' } else { 'Yellow' })
    } else { Write-Host ("   {0,-24} not found" -f $name) -ForegroundColor Yellow }
}

if ($Plan -in 'Servers','All')    { Show-Plan 'VirtualMachines' }
if ($Plan -in 'Containers','All') { Show-Plan 'Containers' }
if ($Plan -in 'Databases','All')  { Show-Plan 'SqlServers'; Show-Plan 'OpenSourceRelationalDatabases'; Show-Plan 'CosmosDbs' }
if ($Plan -in 'Storage','All')    { Show-Plan 'StorageAccounts'; Show-Plan 'KeyVaults'; Show-Plan 'AppServices'; Show-Plan 'Arm' }

if ($Plan -in 'Servers','All') {
    Write-Host "`n[Servers] MDE + monitoring agent coverage" -ForegroundColor Cyan
    Write-Host "   Confirm: Defender plans > Servers > Settings — MDE integration + agent auto-provisioning On; Arc for non-Azure." -ForegroundColor DarkGray
}
if ($Plan -in 'Export','All') {
    Write-Host "`n[Export] Continuous export 'MDC Continuous Export - Workspace - Prod'" -ForegroundColor Cyan
    Write-Host "   Confirm: Environment settings > Continuous export — Security alerts -> the workspace; data landing in SecurityAlert." -ForegroundColor DarkGray
}
if ($Plan -in 'Workflow','All') {
    Write-Host "`n[Workflow] 'MDC Workload Response - Tenant - Prod' (notify-only)" -ForegroundColor Cyan
    Write-Host "   Confirm: Workflow automation — triggers on high severity, calls a Logic App that NOTIFIES only (no auto-remediation)." -ForegroundColor DarkGray
}
Write-Host "`nValidation complete (read-only). Resolve any REVIEW items before expanding." -ForegroundColor Green
