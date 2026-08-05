<#
.SYNOPSIS
    IOSSDMFL-Remediation.ps1 — safely fix the shared-iPhone foundation (Assigned group + Provisioning Client owner).
.DESCRIPTION
    PURPOSE
        Remediates the most common blockers for iPhone Shared Device Mode enrollment-time grouping:
        creates the ASSIGNED device group if missing and ensures the Intune Provisioning Client
        (AppId f1346770-5b25-470b-88bd-d5744ab7952c) is an OWNER of it (without the owner, no-affinity
        devices never populate the group and nothing deploys). Defaults to -WhatIf, so it previews
        every change and modifies nothing until re-run to apply. It does NOT create the ADE profile or
        register devices into shared mode (an on-device Authenticator action) — those are called out.
    HOW TO RUN
        Preview (default, no changes):
          powershell -ExecutionPolicy Bypass -File .\IOSSDMFL-Remediation.ps1 -GroupName "iPhone SDM - Devices"
        Apply the change:
          powershell -ExecutionPolicy Bypass -File .\IOSSDMFL-Remediation.ps1 -GroupName "iPhone SDM - Devices" -WhatIf:$false
        (Install once: Install-Module Microsoft.Graph -Scope CurrentUser)
        Required Graph scopes: Group.ReadWrite.All, Application.Read.All
    EXPECTED RESULTS
        In preview: what is missing and exactly what WOULD be created/assigned.
        When applied: an Assigned security group exists with the Intune Provisioning Client as owner.
        Re-run IOSSDMFL-Discovery.ps1 to confirm READY, then finish the ADE profile + shared-mode
        registration per the Implementation Guide.
.NOTES
    White-label — the repeatable way. Defaults to -WhatIf; changes require -WhatIf:$false.
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$GroupName = 'iPhone SDM - Devices'
)

# Default to preview unless the caller explicitly passes -WhatIf.
if (-not $PSBoundParameters.ContainsKey('WhatIf')) { $WhatIfPreference = $true }

$ErrorActionPreference = 'Stop'
Connect-MgGraph -Scopes 'Group.ReadWrite.All','Application.Read.All' | Out-Null

$ProvClientAppId = 'f1346770-5b25-470b-88bd-d5744ab7952c'  # Intune Provisioning Client

# Resolve the Provisioning Client service principal (needed as the owner directory object)
$spId = $null
try {
    $sp = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/servicePrincipals?`$filter=appId eq '$ProvClientAppId'"
    $spId = @($sp.value)[0].id
} catch {}
if (-not $spId) {
    Write-Host "Could not find the Intune Provisioning Client service principal (AppId $ProvClientAppId)." -ForegroundColor Yellow
    Write-Host "Open the Intune portal once as Global Administrator to provision it, then re-run." -ForegroundColor Yellow
    return
}

# Find or create the Assigned group
$grp = $null
try { $g = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/groups?`$filter=displayName eq '$GroupName'"; $grp = @($g.value)[0] } catch {}

if (-not $grp) {
    $mailNick = ($GroupName -replace '[^a-zA-Z0-9]', '')
    $body = @{ displayName=$GroupName; description='Shared iPhones (no user affinity) for Entra Shared Device Mode. Created by IOSSDMFL-Remediation.ps1.'; mailEnabled=$false; mailNickname=$mailNick; securityEnabled=$true; groupTypes=@() }
    if ($PSCmdlet.ShouldProcess($GroupName, 'Create Assigned security group')) {
        $grp = Invoke-MgGraphRequest -Method POST -Uri 'https://graph.microsoft.com/v1.0/groups' -Body ($body | ConvertTo-Json) -ContentType 'application/json'
        Write-Host "Created Assigned group '$GroupName' (id $($grp.id))." -ForegroundColor Green
    } else {
        Write-Host "WhatIf: would create Assigned security group '$GroupName'." -ForegroundColor Yellow
    }
} else {
    Write-Host "Group '$GroupName' already exists (id $($grp.id))." -ForegroundColor Green
    if ($grp.groupTypes -contains 'DynamicMembership') {
        Write-Host "WARNING: group is DYNAMIC — shared/no-affinity grouping needs an ASSIGNED group. Recreate it as Assigned." -ForegroundColor Yellow
    }
}

# Ensure the Provisioning Client is an owner
if ($grp -and $grp.id) {
    $already = $false
    try { $owners = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/groups/$($grp.id)/owners"; $already = @($owners.value | Where-Object { $_.appId -eq $ProvClientAppId }).Count -gt 0 } catch {}
    if ($already) {
        Write-Host 'Intune Provisioning Client is already an owner.' -ForegroundColor Green
    } elseif ($PSCmdlet.ShouldProcess($GroupName, 'Add Intune Provisioning Client as owner')) {
        $ref = @{ '@odata.id' = "https://graph.microsoft.com/v1.0/directoryObjects/$spId" }
        Invoke-MgGraphRequest -Method POST -Uri "https://graph.microsoft.com/v1.0/groups/$($grp.id)/owners/`$ref" -Body ($ref | ConvertTo-Json) -ContentType 'application/json' | Out-Null
        Write-Host 'Added Intune Provisioning Client as an owner.' -ForegroundColor Green
    } else {
        Write-Host "WhatIf: would add the Intune Provisioning Client (sp $spId) as an owner of '$GroupName'." -ForegroundColor Yellow
    }
}

Write-Host ''
Write-Host 'Note: this script does NOT create the no-affinity ADE profile or register devices into shared mode.' -ForegroundColor DarkGray
Write-Host '      Finish those per the Implementation Guide (Steps 2 and 7).' -ForegroundColor DarkGray
Write-Host ''
if ($WhatIfPreference) { Write-Host 'Preview only (-WhatIf). Re-run with -WhatIf:$false to apply.' -ForegroundColor Yellow }
else { Write-Host 'Remediation complete. Re-run IOSSDMFL-Discovery.ps1 to confirm READY.' -ForegroundColor Green }
