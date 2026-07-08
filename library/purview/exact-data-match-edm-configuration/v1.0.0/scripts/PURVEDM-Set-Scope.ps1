<#
.SYNOPSIS
    PURVEDM-Set-Scope.ps1 — Report/adjust the EDM DLP pilot policy's scope (-WhatIf by default).
.DESCRIPTION
    PURPOSE
        Reports a DLP policy's current mode and included/excluded scope, and — only with -Commit — adds
        or removes a pilot group (e.g. SG-EDM-Pilot) from the policy's scope for the chosen workload.
        Safe by default: without -Commit it prints the intended Set-DlpCompliancePolicy change but
        applies nothing, and it NEVER moves a policy into enforce (Enable) mode — enforcement is a
        deliberate, separate portal/change-control step. Also surfaces data-refresh guidance.
    HOW TO RUN
        # Show the policy's current mode + scope (no changes):
        powershell -File .\PURVEDM-Set-Scope.ps1 -PolicyName 'DLP-EDM-CustomerRecords-Sim'
        # Preview adding the pilot group to the Exchange scope:
        powershell -File .\PURVEDM-Set-Scope.ps1 -PolicyName 'DLP-EDM-CustomerRecords-Sim' `
            -Workload Exchange -AddGroup 'SG-EDM-Pilot' -WhatIf
        # Apply it:
        powershell -File .\PURVEDM-Set-Scope.ps1 -PolicyName 'DLP-EDM-CustomerRecords-Sim' `
            -Workload Exchange -AddGroup 'SG-EDM-Pilot' -Commit
        Requires Security & Compliance PowerShell (Connect-IPPSSession).
    EXPECTED RESULTS
        Prints the policy Mode + current scope. -WhatIf: prints the Set-DlpCompliancePolicy call it WOULD
        run. -Commit: applies the scope change and re-reads it. Refuses to modify an ENFORCING policy.
.NOTES
    Purview — Exact Data Match. Writes gated behind -Commit; never enables enforcement. No secrets in code.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$PolicyName,
    [ValidateSet('Exchange','SharePoint','OneDrive','Teams','Endpoint')][string]$Workload = 'Exchange',
    [string]$AddGroup,
    [string]$RemoveGroup,
    [string]$UserPrincipalName,
    [switch]$Commit
)

if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) { Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force -AllowClobber }
Import-Module ExchangeOnlineManagement -ErrorAction Stop
if (-not (Get-Command Get-DlpCompliancePolicy -ErrorAction SilentlyContinue)) {
    if ($UserPrincipalName) { Connect-IPPSSession -UserPrincipalName $UserPrincipalName } else { Connect-IPPSSession }
}

$pol = Get-DlpCompliancePolicy -Identity $PolicyName -ErrorAction SilentlyContinue
if (-not $pol) { Write-Host ("Policy '{0}' not found. Create it (in simulation) per the Implementation Guide." -f $PolicyName) -ForegroundColor Red; return }

# Map workload -> the include/exclude scope property names
$map = @{
    Exchange   = @{ Inc = 'ExchangeSenderMemberOf';       Exc = 'ExchangeSenderMemberOfException' }
    SharePoint = @{ Inc = 'SharePointLocation';           Exc = 'SharePointLocationException' }
    OneDrive   = @{ Inc = 'OneDriveSharedBy';             Exc = 'OneDriveSharedByMemberOfException' }
    Teams      = @{ Inc = 'TeamsLocation';                Exc = 'TeamsLocationException' }
    Endpoint   = @{ Inc = 'EndpointDlpLocation';          Exc = 'EndpointDlpLocationException' }
}
$incProp = $map[$Workload].Inc

Write-Host ("=== DLP policy '{0}' ===" -f $PolicyName) -ForegroundColor Cyan
Write-Host ("Mode     : {0}" -f $pol.Mode)
$curInc = $pol.$incProp
Write-Host ("Workload : {0}  (scope property: {1})" -f $Workload, $incProp)
Write-Host ("Current included scope: {0}" -f ($(if ($curInc) { ($curInc -join ', ') } else { '(none / all)' })))

if ($pol.Mode -eq 'Enable' -and ($AddGroup -or $RemoveGroup)) {
    Write-Host 'SAFETY: this policy is ENFORCING (Mode=Enable). This helper will not modify an enforcing policy — adjust scope in the portal under change control.' -ForegroundColor Red
    return
}

if (-not $AddGroup -and -not $RemoveGroup) {
    Write-Host "`n(Report only — pass -AddGroup / -RemoveGroup to stage a scope change.)" -ForegroundColor DarkGray
    Write-Host 'Refresh reminder: schedule EdmUploadAgent.exe /UploadData on the secure host so the data store never goes stale (Best Practices / R8).' -ForegroundColor DarkGray
    return
}

# Compute the intended new membership list
$new = New-Object System.Collections.Generic.List[string]
foreach ($m in @($curInc)) { if ($m) { [void]$new.Add([string]$m) } }
if ($AddGroup    -and ($new -notcontains $AddGroup))    { [void]$new.Add($AddGroup) }
if ($RemoveGroup) { $new = New-Object System.Collections.Generic.List[string]; foreach ($m in @($curInc)) { if ($m -and ([string]$m) -ne $RemoveGroup) { [void]$new.Add([string]$m) } } }

Write-Host ("Intended included scope: {0}" -f ($(if ($new.Count) { ($new -join ', ') } else { '(none)' })))

if (-not $Commit) {
    Write-Host '-- WhatIf: no changes made. Would run: --' -ForegroundColor Yellow
    Write-Host ("   Set-DlpCompliancePolicy -Identity '{0}' -{1} @({2})" -f $PolicyName, $incProp, (($new | ForEach-Object { "'$_'" }) -join ', '))
    Write-Host 'Re-run with -Commit to apply (policy stays in its current non-enforce mode).' -ForegroundColor Yellow
    return
}

# --- Commit path ---
$splat = @{ Identity = $PolicyName; $incProp = @($new.ToArray()) }
Set-DlpCompliancePolicy @splat -ErrorAction Stop
$after = Get-DlpCompliancePolicy -Identity $PolicyName
Write-Host ("PASS: scope updated. Included scope now: {0} (Mode still {1})." -f (($after.$incProp -join ', ')), $after.Mode) -ForegroundColor Green
Write-Host 'Re-run the testing gates after any scope change; keep the policy in simulation until the gates pass and sign-off is in writing.' -ForegroundColor DarkGray
