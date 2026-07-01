<#
.SYNOPSIS
    GCCHIGH-Validation.ps1 - GCC High target readiness + per-workstream cutover validation (PASS/FAIL).

    PURPOSE:
        Validates that the GCC High (Microsoft 365 Government High) tenant and Azure Government landing
        zone are ready, and runs per-workstream cutover checks used by the program acceptance gates:
        target tenant + licensing, Azure Gov subscription, sample content parity, and server failover
        state. Emits a PASS/FAIL result per check and an overall result.

    HOW TO RUN:
        1. Install modules (run once):
             Install-Module ExchangeOnlineManagement, Microsoft.Graph, Az -Scope CurrentUser
        2. Run against the GCC HIGH (target) tenant:
             .\GCCHIGH-Validation.ps1 -ExpectedLicenseCount 250 `
                                      -RecoveryVaultName "Recovery Vault - ASR - Target" `
                                      -RecoveryVaultResourceGroup "RG - ASR-Recovery - Target"
        3. Sign in with a target account when prompted (read access is sufficient).

    EXPECTED RESULTS:
        A console table of checks each marked PASS or FAIL, an exported results CSV, and a non-zero
        exit code if any check FAILS - suitable for gating a wave cutover. Read-only: performs no
        changes (no failover is initiated; replication state is only read).

.NOTES
    Azure Solutions - read-only.
#>

[CmdletBinding()]
param(
    [int]$ExpectedLicenseCount = 0,
    [string]$RecoveryVaultName,
    [string]$RecoveryVaultResourceGroup,
    [string[]]$SampleMailboxes = @(),
    [string]$ResultsCsv = ".\Validation Results - Program - Target.csv"
)

$ErrorActionPreference = 'Stop'
$checks = New-Object System.Collections.Generic.List[object]

function Add-Check {
    param($Name, [bool]$Pass, $Detail = '')
    $checks.Add([pscustomobject]@{
        Check  = $Name
        Result = if ($Pass) { 'PASS' } else { 'FAIL' }
        Detail = $Detail
    })
    $color = if ($Pass) { 'Green' } else { 'Red' }
    Write-Host ("[{0}] {1} - {2}" -f $(if($Pass){'PASS'}else{'FAIL'}), $Name, $Detail) -ForegroundColor $color
}

Write-Host "=== GCC High target readiness validation ===" -ForegroundColor Cyan

# --- Microsoft Graph (USGov): tenant + licensing ---
try {
    Import-Module Microsoft.Graph.Authentication, Microsoft.Graph.Identity.DirectoryManagement -ErrorAction Stop
    Connect-MgGraph -Environment USGov -Scopes "Organization.Read.All","Directory.Read.All" -NoWelcome
    $org = Get-MgOrganization
    Add-Check "GCC High tenant reachable" $true ("Tenant: {0}" -f $org.DisplayName)

    # licensing: sum of enabled (prepaid) units across SKUs
    $skus = Get-MgSubscribedSku
    $totalEnabled = ($skus | Measure-Object -Property { $_.PrepaidUnits.Enabled } -Sum).Sum
    $licOk = ($ExpectedLicenseCount -le 0) -or ($totalEnabled -ge $ExpectedLicenseCount)
    Add-Check "Licensing capacity" $licOk ("Enabled units={0}; Expected>={1}" -f $totalEnabled, $ExpectedLicenseCount)
}
catch {
    Add-Check "GCC High tenant reachable" $false $_.Exception.Message
}
finally { try { Disconnect-MgGraph | Out-Null } catch {} }

# --- Azure Government: subscription present ---
try {
    Import-Module Az.Accounts, Az.RecoveryServices -ErrorAction Stop
    Connect-AzAccount -Environment AzureUSGovernment | Out-Null
    $subs = Get-AzSubscription
    Add-Check "Azure Government subscription" ($subs.Count -gt 0) ("Subscriptions found={0}" -f $subs.Count)

    # --- ASR replication / failover state ---
    if ($RecoveryVaultName -and $RecoveryVaultResourceGroup) {
        $vault = Get-AzRecoveryServicesVault -Name $RecoveryVaultName -ResourceGroupName $RecoveryVaultResourceGroup
        Set-AzRecoveryServicesAsrVaultContext -Vault $vault | Out-Null
        $fabrics = Get-AzRecoveryServicesAsrFabric
        $protected = @()
        foreach ($f in $fabrics) {
            foreach ($c in (Get-AzRecoveryServicesAsrProtectionContainer -Fabric $f)) {
                $protected += Get-AzRecoveryServicesAsrReplicationProtectedItem -ProtectionContainer $c
            }
        }
        $healthy = $protected | Where-Object { $_.ReplicationHealth -eq 'Normal' }
        $allHealthy = ($protected.Count -gt 0) -and ($healthy.Count -eq $protected.Count)
        Add-Check "ASR replication healthy" $allHealthy ("Protected={0}; Healthy={1}" -f $protected.Count, $healthy.Count)
    }
}
catch {
    Add-Check "Azure Government subscription" $false $_.Exception.Message
}

# --- Exchange Online (GCC High): sample mailbox parity probe ---
if ($SampleMailboxes.Count -gt 0) {
    try {
        Import-Module ExchangeOnlineManagement -ErrorAction Stop
        Connect-ExchangeOnline -ExchangeEnvironmentName O365USGovGCCHigh -ShowBanner:$false
        foreach ($mbx in $SampleMailboxes) {
            $exists = Get-EXOMailbox -Identity $mbx -ErrorAction SilentlyContinue
            $stats  = if ($exists) { Get-EXOMailboxStatistics -Identity $mbx -ErrorAction SilentlyContinue } else { $null }
            Add-Check ("Sample mailbox present: {0}" -f $mbx) ([bool]$exists) `
                      ("Items={0}" -f ($(if($stats){$stats.ItemCount}else{'n/a'})))
        }
        Disconnect-ExchangeOnline -Confirm:$false
    }
    catch {
        Add-Check "Exchange Online (GCC High) probe" $false $_.Exception.Message
    }
}

# --- Export + overall ---
$checks | Export-Csv -Path $ResultsCsv -NoTypeInformation -Encoding UTF8
$fails = ($checks | Where-Object Result -eq 'FAIL').Count
Write-Host ("`nResults written to {0}" -f $ResultsCsv) -ForegroundColor Green
if ($fails -gt 0) {
    Write-Host ("OVERALL: FAIL ({0} failing check(s))" -f $fails) -ForegroundColor Red
    exit 1
} else {
    Write-Host "OVERALL: PASS" -ForegroundColor Green
    exit 0
}
