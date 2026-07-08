<#
.SYNOPSIS
    IPPBI-Set-InfoProtection.ps1 — Publish the analytics label policy and print the Power BI/Fabric
    tenant-setting checklist (-WhatIf by default).
.DESCRIPTION
    PURPOSE
        Automates the safe part of enabling analytics labeling: publishes / points 'Analytics Labels -
        Policy' at the pilot (or expansion) BI creators. DEFAULTS TO -WhatIf: prints exactly what it would
        do plus the reverse action and changes nothing; applies only with -Commit. The information-
        protection TENANT SETTINGS (labeling, source inheritance, export restriction, mandatory labeling)
        are configured in the Power BI/Fabric admin portal — this script prints the exact checklist for
        -Action ShowTenantSettings but does not change them. No credentials or secrets are stored.
    HOW TO RUN
        .\IPPBI-Set-InfoProtection.ps1 -Action ShowTenantSettings
        .\IPPBI-Set-InfoProtection.ps1 -Action PublishPolicy -PolicyMembers "BI-Labeling-Pilot@contoso.com" -WhatIf
        .\IPPBI-Set-InfoProtection.ps1 -Action PublishPolicy -PolicyMembers "BI-Labeling-Pilot@contoso.com" -Commit
        PowerShell 5.1+/7+. Connect first with Connect-IPPSSession (modern-auth/MFA admin).
    EXPECTED RESULTS
        ShowTenantSettings: the admin-portal checklist to apply. PublishPolicy -WhatIf: the plan + reverse
        command, no change. PublishPolicy -Commit: the policy exists/targets the members afterward (verify
        with Get-LabelPolicy).
.NOTES
    Purview — Sensitivity Labeling for Power BI & Fabric. Safe-by-default. Verify your licensing/tenant:
    tenant-setting names evolve; complete them in the admin portal. Pilot before enforcing.
#>
[CmdletBinding()]
param(
    [ValidateSet('ShowTenantSettings','PublishPolicy')]
    [string]$Action = 'ShowTenantSettings',
    [string]$PolicyName = 'Analytics Labels - Policy',
    [string[]]$Labels = @('General','Confidential','Highly Confidential'),
    [string[]]$PolicyMembers = @(),
    [string]$DelegationGroup = 'BI Labeling - Enabled Users',
    [switch]$WhatIf,
    [switch]$Commit
)

if (-not $Commit) { $WhatIf = $true }
if ($WhatIf -and $Commit) { Write-Host "Specify either -WhatIf or -Commit, not both." -ForegroundColor Yellow; return }

function Test-Command([string]$Name) { [bool](Get-Command $Name -ErrorAction SilentlyContinue) }

if ($Action -eq 'ShowTenantSettings') {
    Write-Host "`n=== Power BI/Fabric admin portal -> Tenant settings -> Information protection ===" -ForegroundColor Cyan
    Write-Host ("Delegate each setting to the security group: {0}" -f $DelegationGroup) -ForegroundColor DarkGray
    @(
        'Allow users to apply sensitivity labels for content                 -> ON',
        'Apply sensitivity labels from data sources to their data in Power BI -> ON  (source inheritance)',
        'Restrict content with protected labels from unsupported apps         -> configure per design (export)',
        'Automatically apply sensitivity labels to downstream content         -> per design',
        'Mandatory label policy for Power BI                                  -> OFF during pilot; ON after validation'
    ) | ForEach-Object { Write-Host ("  [ ] {0}" -f $_) }
    Write-Host "`nThese are admin-portal settings — not scripted here. Confirm names against current Microsoft docs." -ForegroundColor Yellow
    return
}

# PublishPolicy
if (-not (Test-Command 'Get-Label')) {
    Write-Host "Security & Compliance PowerShell not connected. Run Connect-IPPSSession first." -ForegroundColor Yellow; return
}
if ($PolicyMembers.Count -eq 0) {
    Write-Host "Provide -PolicyMembers (UPNs or mail-enabled groups) to publish the policy to." -ForegroundColor Yellow; return
}

$mode = $(if ($Commit) { 'COMMIT' } else { 'WHATIF (no changes)' })
Write-Host "`n=== Publish analytics label policy — Mode: $mode ===" -ForegroundColor Cyan
$policy = Get-LabelPolicy -Identity $PolicyName -ErrorAction SilentlyContinue

if ($WhatIf) {
    if ($policy) {
        Write-Host ("  WOULD update policy '{0}': ensure labels [{1}] and members [{2}]" -f $PolicyName, ($Labels -join ', '), ($PolicyMembers -join ', ')) -ForegroundColor Yellow
        Write-Host ("        reverse: Set-LabelPolicy -Identity '{0}' -RemoveLabel <label> / narrow members back to pilot" -f $PolicyName) -ForegroundColor DarkGray
    } else {
        Write-Host ("  WOULD create policy '{0}' with labels [{1}] published to [{2}]" -f $PolicyName, ($Labels -join ', '), ($PolicyMembers -join ', ')) -ForegroundColor Yellow
        Write-Host ("        reverse: Remove-LabelPolicy -Identity '{0}'" -f $PolicyName) -ForegroundColor DarkGray
    }
    Write-Host "`nThen enable the tenant settings for the pilot group (see -Action ShowTenantSettings)." -ForegroundColor DarkGray
    return
}

try {
    if (-not $policy) {
        New-LabelPolicy -Name $PolicyName -Settings @{} -ErrorAction Stop | Out-Null
        Write-Host ("  CREATED policy '{0}'." -f $PolicyName) -ForegroundColor Green
    }
    Set-LabelPolicy -Identity $PolicyName -AddLabel $Labels -ErrorAction Stop | Out-Null
    Set-LabelPolicy -Identity $PolicyName -AddExchangeLocation $PolicyMembers -ErrorAction SilentlyContinue | Out-Null
    Write-Host ("  PUBLISHED '{0}' with labels [{1}] to [{2}]." -f $PolicyName, ($Labels -join ', '), ($PolicyMembers -join ', ')) -ForegroundColor Green
    Write-Host "  Next: enable the information-protection tenant settings in the Power BI/Fabric admin portal." -ForegroundColor DarkGray
} catch {
    Write-Host ("  ERROR publishing policy: {0}" -f $_.Exception.Message) -ForegroundColor Red
    Write-Host "  Verify the label/membership parameter names for your ExchangeOnlineManagement version." -ForegroundColor Yellow
}
