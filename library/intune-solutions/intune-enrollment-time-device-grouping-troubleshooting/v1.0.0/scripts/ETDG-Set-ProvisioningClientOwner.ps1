<#
.SYNOPSIS
    ETDG-Set-ProvisioningClientOwner.ps1 — add the Intune Provisioning Client service principal as an Owner of the target group (preview-first, -WhatIf default).
.DESCRIPTION
    Resolves the Intune Provisioning Client service principal by AppId
    (f1346770-5b25-470b-88bd-d5744ab7952c) and adds it as an OWNER of the named target group so
    Intune can write membership at enrollment. Defaults to -WhatIf (preview only); re-run with
    -WhatIf:$false to commit. Then allow 5-10 minutes for Entra propagation before saving the
    enrollment policy. No stored credentials.
.EXAMPLE
    .\ETDG-Set-ProvisioningClientOwner.ps1 -GroupName "Autopilot - Devices - Pilot"            # preview
    .\ETDG-Set-ProvisioningClientOwner.ps1 -GroupName "Autopilot - Devices - Pilot" -WhatIf:$false  # commit
    (PowerShell 5.1+/7+, Microsoft.Graph SDK; connect with Connect-MgGraph)
.NOTES
    Expected results: preview prints the owner add that WOULD occur; commit confirms the owner was
    added. Pass = after propagation, ETDG-Assess-GroupReadiness reports R7 = PASS.
    White-label. Read-only unless -WhatIf:$false is passed.
#>

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory)][string]$GroupName,
    [string]$ProvisioningClientAppId = 'f1346770-5b25-470b-88bd-d5744ab7952c',
    [switch]$WhatIf = $true
)

$ErrorActionPreference = 'Stop'
if ($WhatIf) { $WhatIfPreference = $true }

function Connect-EtdgGraph {
    param([string[]]$Scopes)
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
        throw "Microsoft.Graph PowerShell SDK not found. Install with: Install-Module Microsoft.Graph -Scope CurrentUser"
    }
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    $ctx = Get-MgContext
    if (-not $ctx -or ($Scopes | Where-Object { $ctx.Scopes -notcontains $_ })) {
        Connect-MgGraph -Scopes $Scopes | Out-Null
    }
    Write-Host "Connected to tenant: $((Get-MgContext).TenantId)" -ForegroundColor Green
}

function Invoke-GraphGetAll {
    param([Parameter(Mandatory)][string]$Uri)
    $results = @(); $next = $Uri
    while ($next) {
        $resp = Invoke-MgGraphRequest -Method GET -Uri $next
        if ($null -ne $resp.value) { $results += $resp.value } else { $results += $resp }
        $next = $resp.'@odata.nextLink'
    }
    return $results
}

# Read scope for lookups; write scope only needed to commit.
$scopes = @('Group.Read.All', 'Application.Read.All')
if (-not $WhatIfPreference) { $scopes = @('Group.ReadWrite.All', 'Application.Read.All') }
Connect-EtdgGraph -Scopes $scopes

if ($WhatIfPreference) {
    Write-Host "`n*** PREVIEW MODE (-WhatIf). No changes will be made. Re-run with -WhatIf:`$false to commit. ***`n" -ForegroundColor Yellow
}

# Resolve the target group.
$escaped = $GroupName -replace "'", "''"
$grp = Invoke-GraphGetAll -Uri ("https://graph.microsoft.com/v1.0/groups?`$filter=displayName eq '{0}'" -f $escaped)
if (-not $grp) { throw "Group '$GroupName' not found." }
$g = $grp[0]

# Resolve the Intune Provisioning Client service principal by AppId (name varies by tenant).
$sp = Invoke-GraphGetAll -Uri ("https://graph.microsoft.com/v1.0/servicePrincipals?`$filter=appId eq '{0}'" -f $ProvisioningClientAppId)
if (-not $sp) {
    throw "Intune Provisioning Client service principal (AppId $ProvisioningClientAppId) not found in this tenant. Open https://intune.microsoft.com once as a Global Administrator to provision it, or open a Microsoft support case, then retry."
}
$spObj = $sp[0]
Write-Host ("Found service principal: '{0}' (appId {1}, objectId {2})" -f $spObj.displayName, $spObj.appId, $spObj.id)

# Already an owner?
$owners = Invoke-GraphGetAll -Uri "https://graph.microsoft.com/v1.0/groups/$($g.id)/owners"
if ($owners | Where-Object { $_.appId -eq $ProvisioningClientAppId }) {
    Write-Host "The Intune Provisioning Client is ALREADY an owner of '$GroupName'. Nothing to do." -ForegroundColor Green
    return
}

$target = "group '$GroupName' (id $($g.id))"
$action = "add Intune Provisioning Client (objectId $($spObj.id)) as Owner"
if ($PSCmdlet.ShouldProcess($target, $action)) {
    $body = @{ '@odata.id' = "https://graph.microsoft.com/v1.0/directoryObjects/$($spObj.id)" }
    Invoke-MgGraphRequest -Method POST `
        -Uri "https://graph.microsoft.com/v1.0/groups/$($g.id)/owners/`$ref" `
        -Body ($body | ConvertTo-Json)
    Write-Host "OWNER ADDED. Allow 5-10 minutes for Entra propagation, then re-run ETDG-Assess-GroupReadiness.ps1 and retry the policy Save." -ForegroundColor Green
} else {
    Write-Host "PREVIEW: would $action on $target." -ForegroundColor Yellow
}
