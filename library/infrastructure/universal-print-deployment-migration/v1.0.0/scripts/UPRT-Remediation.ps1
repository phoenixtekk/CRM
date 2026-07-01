<#
.SYNOPSIS
    UPRT-Remediation.ps1 - safely fix failed Universal Print printer deployments.
.DESCRIPTION
    PURPOSE
        Reconciles printer-share deployment so a printer that should reach a group actually does:
        ensures the target Entra ID group is granted access to the printer share, and (on a device)
        forces an MDM/Intune sync so the deployed printer re-applies. Defaults to -WhatIf: it reports
        what it WOULD change and makes no modifications until you pass -WhatIf:$false.
    HOW TO RUN
        Preview (default, no changes):
          powershell -ExecutionPolicy Bypass -File .\UPRT-Remediation.ps1 `
            -ShareName "UniversalPrint - HQ-Floor2-MFP - Shared" -GroupId <entra-group-guid>
        Apply changes:
          ... -ShareName "..." -GroupId <guid> -WhatIf:$false
    EXPECTED RESULTS
        With -WhatIf (default): a plan of the access grant + sync that would occur.
        With -WhatIf:$false: the group is granted to the share via Graph and a device MDM sync is triggered.
    SCOPES
        Requires PrinterShare.ReadWrite.All (delegated) for the access grant.
.NOTES
    Infrastructure solution - the repeatable way. Default -WhatIf; makes changes only when disabled.
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory = $true)][string]$ShareName,
    [Parameter(Mandatory = $true)][string]$GroupId,
    [switch]$SyncDevice
)

# Default to -WhatIf unless the caller explicitly turned it off.
if (-not $PSBoundParameters.ContainsKey('WhatIf')) { $WhatIfPreference = $true }

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'PrinterShare.ReadWrite.All' -NoWelcome

Write-Host "`n=== Universal Print deployment remediation ===" -ForegroundColor Cyan

# Find the printer share by display name.
$share = (Invoke-MgGraphRequest -Method GET -Uri '/v1.0/print/shares').value |
         Where-Object { $_.displayName -eq $ShareName } | Select-Object -First 1

if (-not $share) {
    Write-Host "  Share not found: '$ShareName'. Confirm it is shared in the Universal Print portal." -ForegroundColor Yellow
    Disconnect-MgGraph | Out-Null
    return
}

# Grant the group access to the share (this is what makes the printer deployable to the group).
$target = "share '$ShareName' -> grant access to group $GroupId"
if ($PSCmdlet.ShouldProcess($target, "Grant group to printer share")) {
    $body = @{ '@odata.id' = "https://graph.microsoft.com/v1.0/groups/$GroupId" } | ConvertTo-Json
    # POST to allowedGroups/`$ref adds the group to the share's allowed groups.
    Invoke-MgGraphRequest -Method POST -Uri "/v1.0/print/shares/$($share.id)/allowedGroups/`$ref" -Body $body -ContentType 'application/json'
    Write-Host "  Granted group $GroupId to share '$ShareName'." -ForegroundColor Green
} else {
    Write-Host "  [WhatIf] Would grant group $GroupId to share '$ShareName'." -ForegroundColor DarkGray
}

# Optionally force a local device MDM sync so the deployed printer re-applies.
if ($SyncDevice) {
    if ($PSCmdlet.ShouldProcess($env:COMPUTERNAME, "Trigger MDM/Intune sync")) {
        Start-Process -FilePath "$env:WINDIR\System32\deviceenroller.exe" -ArgumentList "/c /AutoEnrollMDM" -WindowStyle Hidden
        Write-Host "  MDM sync requested on $env:COMPUTERNAME." -ForegroundColor Green
    } else {
        Write-Host "  [WhatIf] Would trigger an MDM/Intune sync on $env:COMPUTERNAME." -ForegroundColor DarkGray
    }
}

Disconnect-MgGraph | Out-Null
Write-Host "`nRe-run UPRT-Report.ps1 after a policy cycle to confirm coverage." -ForegroundColor Green
