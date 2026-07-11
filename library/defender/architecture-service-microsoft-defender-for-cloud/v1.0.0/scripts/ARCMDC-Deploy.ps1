<#
.SYNOPSIS
    ARCMDC-Deploy.ps1 — deploy the reference main.bicep at management-group scope.
    SAFE PREVIEW by default (what-if); applies only when explicitly confirmed.
.DESCRIPTION
    PURPOSE
        Deployment helper for the "Architecture Service — Microsoft Defender for Cloud" solution.
        Wraps the reference main.bicep as a management-group deployment. It DEFAULTS TO A WHAT-IF
        (New-AzManagementGroupDeployment -WhatIf) so you see exactly which plan enablements would
        happen before anything changes; -Apply performs the deployment. This is the only script
        that can change configuration.
    HOW TO RUN
        # Preview (default — what-if, changes nothing):
        powershell -ExecutionPolicy Bypass -File .\ARCMDC-Deploy.ps1 -ManagementGroupId '<pilotMgId>' -Wave 1
        # Apply (explicit — required to deploy):
        powershell -ExecutionPolicy Bypass -File .\ARCMDC-Deploy.ps1 -ManagementGroupId '<pilotMgId>' -Wave 1 -Apply
        Requires Az.Accounts, Az.Resources and Owner/Contributor at the management-group scope.
    EXPECTED RESULTS
        Preview: prints the what-if of the MG deployment (which plan config would change).
        Apply: deploys the Bicep at the MG scope for the wave. Validate with ARCMDC-Validate.ps1.
        Rollback: redeploy with the plan set to Free / enforcementMode DoNotEnforce, or delete the
        policy assignment created by the template.
.NOTES
    White-label. DEFAULTS TO what-if/preview. Paid plans incur cost on Apply — verify pricing and
    the built-in initiative id in your tenant. Pilot MG first; expand in waves.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string]$ManagementGroupId,
    [int]$Wave = 1,
    [string]$Location = 'eastus',
    [string]$TemplateFile = ".\main.bicep",
    [switch]$Apply
)

foreach ($m in 'Az.Accounts','Az.Resources') {
    if (-not (Get-Module -ListAvailable -Name $m)) { Install-Module Az -Scope CurrentUser -Force -AllowClobber; break }
}
Import-Module Az.Accounts -ErrorAction Stop
Import-Module Az.Resources -ErrorAction Stop
if (-not (Get-AzContext)) { Connect-AzAccount | Out-Null }

if (-not (Test-Path $TemplateFile)) { Write-Host ("Template not found: {0}" -f $TemplateFile) -ForegroundColor Red; return }

$whatIf = -not $Apply
Write-Host "`n=== ARCMDC deploy reference Bicep (management-group scope) ===" -ForegroundColor Cyan
Write-Host ("Management group: {0}   Wave: {1}" -f $ManagementGroupId, $Wave)
Write-Host ("Mode: {0}" -f ($(if ($whatIf) { 'PREVIEW (what-if) — no changes' } else { 'APPLY — deploys; PAID plans may bill' }))) -ForegroundColor $(if ($whatIf) { 'Yellow' } else { 'Red' })

$deployParams = @{
    ManagementGroupId       = $ManagementGroupId
    Location                = $Location
    TemplateFile            = $TemplateFile
    TemplateParameterObject = @{ wave = $Wave }
    Name                    = ("arcmdc-wave{0}-{1}" -f $Wave, (Get-Date -Format 'yyyyMMddHHmm'))
}

try {
    if ($whatIf) {
        Write-Host "`nRunning what-if (this changes nothing)..." -ForegroundColor Yellow
        New-AzManagementGroupDeployment @deployParams -WhatIf
        Write-Host "`nReview the predicted changes above. When approved, re-run with -Apply." -ForegroundColor Yellow
    } else {
        Write-Host "`nDeploying..." -ForegroundColor Red
        $d = New-AzManagementGroupDeployment @deployParams
        Write-Host ("`nAPPLIED — provisioning state: {0}. Validate with ARCMDC-Validate.ps1." -f $d.ProvisioningState) -ForegroundColor Green
        Write-Host "Rollback: redeploy with plans=Free / enforcementMode=DoNotEnforce, or remove the policy assignment." -ForegroundColor DarkGray
    }
} catch {
    Write-Host ("Deployment call failed: {0}" -f $_.Exception.Message) -ForegroundColor Red
    Write-Host "Confirm MG-scope rights, the built-in initiative id in main.bicep, and current plan availability." -ForegroundColor Yellow
}
