<#
.SYNOPSIS
    POCMDC-TestSignal.ps1 — generate BENIGN, simulated cloud-security test signal for the MDC PoC. Safe only.
.DESCRIPTION
    PURPOSE
        Produces harmless posture + threat signal so Defender for Cloud has something to surface. It:
          1. Guides creation of Defender for Cloud's built-in SAMPLE SECURITY ALERTS (portal), a
             Microsoft-provided benign way to populate the alert pipeline.
          2. Optionally deploys a benign, DELIBERATELY-MISCONFIGURED test storage account (public
             blob access) in the pilot resource group so CSPM raises a recommendation. It holds NO
             real data and is deleted at teardown.
          3. Prints the steps to drop the EICAR test file on a pilot VM (Defender for Servers) for a
             benign workload alert.
        NO real attack, real malware, or real data exposure is ever performed. -WhatIf previews.
    HOW TO RUN
        # Preview:
        powershell -ExecutionPolicy Bypass -File .\POCMDC-TestSignal.ps1 -WhatIf
        # Deploy the benign misconfig test resource:
        powershell -ExecutionPolicy Bypass -File .\POCMDC-TestSignal.ps1 -ResourceGroup "MDC PoC - Pilot RG - Pilot" -Location eastus -DeployTestResource
        Requires Az.Accounts + Az.Storage and Contributor on the pilot subscription.
    EXPECTED RESULTS
        Sample alerts populate, a recommendation is raised for the benign misconfig, and (optionally)
        an EICAR alert fires — for the PoC to validate.
.NOTES
    White-label. BENIGN signal only (sample alerts + benign misconfig test resource + EICAR). Never real attacks.
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [string]$ResourceGroup = 'MDC PoC - Pilot RG - Pilot',
    [string]$Location = 'eastus',
    [switch]$DeployTestResource,
    [string]$Tag = 'MDC-PoC-TESTSIGNAL'
)

Write-Host "`n=== POCMDC — benign test signal ($Tag) ===" -ForegroundColor Cyan
Write-Host "SAFE ONLY: sample alerts + a benign misconfigured test resource (no real data) + EICAR. No real attacks." -ForegroundColor Yellow

# 1) Sample security alerts (portal-driven, safe).
Write-Host "`n[1] Create built-in SAMPLE security alerts:" -ForegroundColor Cyan
Write-Host "  portal.azure.com -> Microsoft Defender for Cloud -> Security alerts -> Sample alerts ->" -ForegroundColor Gray
Write-Host "  select the PILOT subscription and the enabled plan(s) -> Create sample alerts. (Microsoft-provided, benign.)" -ForegroundColor Green

# 2) Benign misconfigured test resource (CSPM).
Write-Host "`n[2] Deploy the benign misconfigured test resource (CSPM recommendation):" -ForegroundColor Cyan
if ($DeployTestResource) {
    foreach ($m in 'Az.Accounts','Az.Storage') { if (-not (Get-Module -ListAvailable -Name $m)) { Install-Module $m -Scope CurrentUser -Force -AllowClobber } }
    Import-Module Az.Accounts -ErrorAction Stop; Import-Module Az.Storage -ErrorAction Stop
    if (-not (Get-AzContext)) { Connect-AzAccount | Out-Null }
    $rgName = ($ResourceGroup -replace '[^A-Za-z0-9-]','-')
    $saName = ('mdcpoc' + -join ((48..57)+(97..122) | Get-Random -Count 8 | ForEach-Object {[char]$_}))
    if ($PSCmdlet.ShouldProcess("$saName in $rgName", "Deploy benign misconfigured test storage account (public access)")) {
        try {
            if (-not (Get-AzResourceGroup -Name $rgName -ErrorAction SilentlyContinue)) { New-AzResourceGroup -Name $rgName -Location $Location | Out-Null }
            New-AzStorageAccount -ResourceGroupName $rgName -Name $saName -Location $Location -SkuName Standard_LRS -Kind StorageV2 -AllowBlobPublicAccess $true -Tag @{ purpose = $Tag } -ErrorAction Stop | Out-Null
            Write-Host "  Deployed benign test storage '$saName' (public blob access ON) so CSPM raises a recommendation." -ForegroundColor Green
            Write-Host "  It holds NO real data and is deleted at teardown." -ForegroundColor Gray
        } catch { Write-Host ("  Deploy failed: {0}" -f $_.Exception.Message) -ForegroundColor Yellow }
    } else {
        Write-Host "  [WhatIf] Would deploy a benign misconfigured test storage account in '$rgName'." -ForegroundColor Yellow
    }
} else {
    Write-Host "  Pass -DeployTestResource to deploy the benign misconfigured storage account, or create one in the portal." -ForegroundColor Gray
}

# 3) EICAR on a pilot VM (optional workload alert).
Write-Host "`n[3] (Optional) Trigger a benign workload alert on a pilot VM (Defender for Servers):" -ForegroundColor Cyan
Write-Host "  On a pilot VM covered by Defender for Servers, write the EICAR anti-malware TEST file (benign, not malware):" -ForegroundColor Gray
Write-Host "    \$e='X5O!P%@AP[4\PZX54(P^)7CC)7}\$'+'EICAR-STANDARD-ANTIVIRUS-TEST-FILE!\$H+H*'; Set-Content C:\Temp\eicar-poc.com \$e -Encoding ascii -NoNewline" -ForegroundColor Gray
Write-Host "  This raises a benign Defender-for-Servers alert. Delete the file afterwards." -ForegroundColor Green

Write-Host ("`nSignal generated at: {0}  (record this for scorecard latency)." -f (Get-Date).ToString('u')) -ForegroundColor Cyan
Write-Host "Next: POCMDC-Validate.ps1" -ForegroundColor Cyan
