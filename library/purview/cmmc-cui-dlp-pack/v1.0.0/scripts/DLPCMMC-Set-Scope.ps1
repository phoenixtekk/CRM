<#
.SYNOPSIS
    DLPCMMC-Set-Scope.ps1 — scope/health helper that reports and (with -Commit) narrows a CUI DLP policy to the enclave / pilot ring (-WhatIf by default).
.DESCRIPTION
    PURPOSE
        Reports a CUI DLP policy's current location scope and, with -Commit, sets the INCLUDED /
        EXCLUDED users, groups, or sites so enforcement targets only the CUI enclave or the pilot ring
        (e.g. 'CUI DLP Pilot Ring - Stage1') rather than the whole tenant ("All"). Safe by default: with
        -WhatIf it only reports the intended scope change; it applies nothing unless -Commit is passed,
        and it will NOT flip a policy's mode (it never enforces — mode changes stay a portal/change-control
        step). Also prints a quick health check (mode + current scope).
    HOW TO RUN
        # Report current scope only:
        powershell -File .\DLPCMMC-Set-Scope.ps1 -PolicyName 'DLP - CUI Email - Simulation' -WhatIf
        # Narrow the Exchange scope to the pilot ring group (still simulation — mode untouched):
        powershell -File .\DLPCMMC-Set-Scope.ps1 -PolicyName 'DLP - CUI Email - Simulation' `
            -Location Exchange -IncludeGroup 'CUI DLP Pilot Ring - Stage1' -Commit
        Requires Security & Compliance PowerShell (Connect-IPPSSession).
    EXPECTED RESULTS
        -WhatIf: prints the current mode/scope and the Set-DlpCompliancePolicy call it WOULD run.
        -Commit: applies the include/exclude scope and re-prints the resulting scope. Mode is never
        changed by this script. Verify with DLPCMMC-Validate.ps1 -ExpectScoped.
.NOTES
    Purview — CMMC / CUI DLP Pack. Writes gated behind -Commit; never changes policy mode/enforcement. No credentials in code.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$PolicyName,
    [ValidateSet('Exchange','SharePoint','OneDrive','Teams','Endpoint')]
    [string]$Location = 'Exchange',
    [string[]]$IncludeGroup,
    [string[]]$ExcludeGroup,
    [string]$UserPrincipalName,
    [switch]$Commit
)

if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force -AllowClobber
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop
if (-not (Get-Command Get-DlpCompliancePolicy -ErrorAction SilentlyContinue)) {
    if ($UserPrincipalName) { Connect-IPPSSession -UserPrincipalName $UserPrincipalName } else { Connect-IPPSSession }
}

$p = Get-DlpCompliancePolicy -Identity $PolicyName -ErrorAction SilentlyContinue
if (-not $p) { Write-Host ("Policy '{0}' not found." -f $PolicyName) -ForegroundColor Red; return }

Write-Host ("=== CUI DLP scope/health — '{0}' ===" -f $PolicyName) -ForegroundColor Cyan
Write-Host ("Mode (unchanged by this script): {0}" -f $p.Mode)
Write-Host '--- Current location scope ---' -ForegroundColor Cyan
foreach ($loc in 'ExchangeLocation','SharePointLocation','OneDriveLocation','TeamsLocation','EndpointDlpLocation') {
    $val = $p.$loc
    if ($val -and $val.Count -gt 0) { Write-Host ("  {0}: {1}" -f $loc, ($val -join ', ')) }
}

# Map the friendly location to the include/exclude parameter names.
$paramMap = @{
    'Exchange'   = @{ Inc = 'ExchangeSenderMemberOf';    Exc = 'ExchangeSenderMemberOfException' }
    'SharePoint' = @{ Inc = 'SharePointLocation';        Exc = 'SharePointLocationException' }
    'OneDrive'   = @{ Inc = 'OneDriveSharedBy';          Exc = 'OneDriveSharedByMemberOfException' }
    'Teams'      = @{ Inc = 'TeamsLocation';             Exc = 'TeamsLocationException' }
    'Endpoint'   = @{ Inc = 'EndpointDlpLocation';       Exc = 'EndpointDlpLocationException' }
}
$names = $paramMap[$Location]

if (-not $IncludeGroup -and -not $ExcludeGroup) {
    Write-Host 'No -IncludeGroup/-ExcludeGroup supplied — reported current scope only (health check).' -ForegroundColor Yellow
    return
}

$set = @{ Identity = $PolicyName }
if ($IncludeGroup) { $set[$names.Inc] = $IncludeGroup }
if ($ExcludeGroup) { $set[$names.Exc] = $ExcludeGroup }

if (-not $Commit) {
    Write-Host '-- WhatIf: no changes made. Would run: --' -ForegroundColor Yellow
    $argStr = ($set.GetEnumerator() | Where-Object { $_.Key -ne 'Identity' } | ForEach-Object { "-$($_.Key) '$([string]::Join(",", $_.Value))'" }) -join ' '
    Write-Host ("Set-DlpCompliancePolicy -Identity '{0}' {1}" -f $PolicyName, $argStr)
    Write-Host 'Re-run with -Commit to apply. Mode/enforcement is never changed by this script.' -ForegroundColor Yellow
    return
}

Set-DlpCompliancePolicy @set -ErrorAction Stop
Write-Host 'Scope updated (mode untouched).' -ForegroundColor Green

$after = Get-DlpCompliancePolicy -Identity $PolicyName
Write-Host '--- Resulting scope ---' -ForegroundColor Cyan
foreach ($k in $names.Values) {
    $val = $after.$k
    if ($val -and $val.Count -gt 0) { Write-Host ("  {0}: {1}" -f $k, ($val -join ', ')) }
}
Write-Host 'Done. Validate with DLPCMMC-Validate.ps1 -ExpectScoped.' -ForegroundColor Cyan
