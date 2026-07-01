<#
.SYNOPSIS
    SCCMTS-Set-ScopeTargeting.ps1 — collection/scope targeting helper for piloting the runbook.
.DESCRIPTION
    PURPOSE
        Prepare a small, controlled scope to pilot the troubleshooting runbook on real failures
        without touching production breadth:
          - Ensure a pilot device collection exists (create it if missing).
          - Add the specific failing device(s) to that pilot collection.
        Use it so re-runs and remediation stay confined to the piloted devices (runbook Steps 9-10).
        SAFE BY DEFAULT: -WhatIf is on unless you pass -WhatIf:$false.
    HOW TO RUN
        From a ConfigurationManager PowerShell session (site drive PS XYZ:\>):
          Preview:  .\SCCMTS-Set-ScopeTargeting.ps1 -SiteCode ABC -SmsProvider cm01.contoso.com `
                        -CollectionName "OSD - Runbook - Pilot" -DeviceName PC123
          Execute:  add -WhatIf:$false
        Requires the ConfigurationManager module and RBAC rights to create/modify collections.
    EXPECTED RESULTS
        With -WhatIf: the collection and membership changes it would make. Without: the pilot
        collection exists and the named device(s) are direct members, ready to pilot the runbook.
.NOTES
    Phoenixtekk Workplace Marketplace — Infrastructure Solutions. Changes are gated behind -WhatIf.
#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
param(
    [Parameter(Mandatory)][string]$SiteCode,
    [Parameter(Mandatory)][string]$SmsProvider,
    [Parameter(Mandatory)][string]$CollectionName,
    [string[]]$DeviceName,
    [string]$LimitingCollectionName = 'All Systems'
)

if (-not $PSBoundParameters.ContainsKey('WhatIf')) { $WhatIfPreference = $true }

if (-not (Get-Module ConfigurationManager)) {
    Import-Module "$($env:SMS_ADMIN_UI_PATH)\..\ConfigurationManager.psd1" -ErrorAction Stop
}
if (-not (Get-PSDrive -Name $SiteCode -PSProvider CMSite -ErrorAction SilentlyContinue)) {
    New-PSDrive -Name $SiteCode -PSProvider CMSite -Root $SmsProvider -ErrorAction Stop | Out-Null
}
Push-Location "$($SiteCode):"
try {
    Write-Host "=== SCCMTS scope targeting (WhatIf=$WhatIfPreference) ===" -ForegroundColor Cyan

    # 1. Ensure the pilot collection exists.
    $coll = Get-CMDeviceCollection -Name $CollectionName -ErrorAction SilentlyContinue
    if (-not $coll) {
        if ($PSCmdlet.ShouldProcess($CollectionName, "Create device collection (limited to $LimitingCollectionName)")) {
            $coll = New-CMDeviceCollection -Name $CollectionName -LimitingCollectionName $LimitingCollectionName -ErrorAction Stop
            Write-Host "  Created collection '$CollectionName'." -ForegroundColor Green
        } else {
            Write-Host "  Would create collection '$CollectionName'." -ForegroundColor Yellow
        }
    } else {
        Write-Host "  Collection '$CollectionName' already exists (ID $($coll.CollectionID))." -ForegroundColor Green
    }

    # 2. Add each named device as a direct member.
    foreach ($d in $DeviceName) {
        $res = Get-CMDevice -Name $d -ErrorAction SilentlyContinue
        if (-not $res) { Write-Host "  Device '$d' not found in the site — skipped." -ForegroundColor Yellow; continue }
        if ($PSCmdlet.ShouldProcess($d, "Add as direct member of '$CollectionName'")) {
            Add-CMDeviceCollectionDirectMembershipRule -CollectionName $CollectionName -ResourceId $res.ResourceID -ErrorAction SilentlyContinue
            Write-Host "  Added '$d' to '$CollectionName'." -ForegroundColor Green
        } else {
            Write-Host "  Would add '$d' to '$CollectionName'." -ForegroundColor Yellow
        }
    }

    Write-Host "`nPilot the runbook against '$CollectionName'; keep re-runs/remediation scoped here." -ForegroundColor Green
}
finally {
    Pop-Location
}
