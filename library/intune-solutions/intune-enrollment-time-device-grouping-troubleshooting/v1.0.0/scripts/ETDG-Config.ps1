<#
.SYNOPSIS
    ETDG-Config.ps1 — shared configuration + Graph connection helper for the Enrollment-Time Device Grouping toolkit (read-only).
.DESCRIPTION
    Central place for the fixed Intune Provisioning Client AppId, artifact-name defaults, a
    least-scope Connect-MgGraph helper, and a one-shot health summary that stitches the group
    readiness and prerequisite checks into a single scoped run. Dot-source this file from the
    other ETDG scripts, or run it directly for a quick connect + summary. Read-only; no secrets.
.EXAMPLE
    . .\ETDG-Config.ps1                                    # dot-source to reuse the helpers
    .\ETDG-Config.ps1 -GroupName "Autopilot - Devices - Pilot"   # connect + quick health summary
    (PowerShell 5.1+/7+, Microsoft.Graph SDK; connect with Connect-MgGraph)
.NOTES
    Expected results: prints the tenant, the fixed Provisioning Client AppId, and — if a group is
    named — a compact PASS/FAIL summary. The pass/fail signal is the summary line per prerequisite.
    White-label. Read-only against Microsoft Graph.
#>

[CmdletBinding()]
param(
    [string]$GroupName
)

$ErrorActionPreference = 'Stop'

# The Intune Provisioning Client first-party service principal AppId. Fixed Microsoft identifier,
# NOT a placeholder. Displayed as "Intune Provisioning Client" in some tenants and "Intune
# Autopilot ConfidentialClient" in others — always match by this AppId, never by name.
$script:ETDG_ProvisioningClientAppId = 'f1346770-5b25-470b-88bd-d5744ab7952c'

# Reference-design artifact names (override as needed).
$script:ETDG_Defaults = [ordered]@{
    WindowsPilotGroup = 'Autopilot - Devices - Pilot'
    WindowsProdGroup  = 'Autopilot - Devices - Prod'
    ApplePilotGroup   = 'iOS - Shared Devices - Pilot'
    AppleProdGroup    = 'iOS - Shared Devices - Prod'
    WindowsPolicy     = 'Autopilot DevicePrep - Shared - Prod'
    ApplePolicy       = 'ADE Enrollment - Shared iOS - Prod'
    AppleToken        = 'ADE Token - Corporate - Prod'
}

function Connect-EtdgGraph {
    <#
        Least-privilege, modern-auth connection. Pass the scopes the caller needs; read tools use
        read scopes only. No stored credentials — interactive/delegated Connect-MgGraph.
    #>
    param(
        [string[]]$Scopes = @('Group.Read.All', 'Application.Read.All', 'DeviceManagementRBAC.Read.All')
    )
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
        throw "Microsoft.Graph PowerShell SDK not found. Install with: Install-Module Microsoft.Graph -Scope CurrentUser"
    }
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    $ctx = Get-MgContext
    $haveAll = $ctx -and -not ($Scopes | Where-Object { $ctx.Scopes -notcontains $_ })
    if (-not $haveAll) {
        Connect-MgGraph -Scopes $Scopes | Out-Null
    }
    $ctx = Get-MgContext
    Write-Host "Connected to tenant: $($ctx.TenantId)" -ForegroundColor Green
    return $ctx
}

function Invoke-EtdgGraphGetAll {
    param([Parameter(Mandatory)][string]$Uri)
    $results = @()
    $next = $Uri
    while ($next) {
        $resp = Invoke-MgGraphRequest -Method GET -Uri $next
        if ($null -ne $resp.value) { $results += $resp.value } else { $results += $resp }
        $next = $resp.'@odata.nextLink'
    }
    return $results
}

function Get-EtdgGroupByName {
    param([Parameter(Mandatory)][string]$Name)
    $filter = "https://graph.microsoft.com/v1.0/groups?`$filter=displayName eq '{0}'" -f ($Name -replace "'", "''")
    return Invoke-EtdgGraphGetAll -Uri $filter
}

function Test-EtdgProvisioningClientOwner {
    <# Returns $true if the group has an owner whose appId matches the Provisioning Client AppId. #>
    param([Parameter(Mandatory)][string]$GroupId)
    $owners = Invoke-EtdgGraphGetAll -Uri "https://graph.microsoft.com/v1.0/groups/$GroupId/owners"
    foreach ($o in $owners) {
        # Owner service principals expose appId directly on the servicePrincipal object.
        if ($o.appId -eq $script:ETDG_ProvisioningClientAppId) { return $true }
    }
    return $false
}

# When run directly (not dot-sourced), print config and an optional quick summary.
if ($MyInvocation.InvocationName -ne '.') {
    Write-Host "`n=== ETDG configuration ===" -ForegroundColor Cyan
    Write-Host ("Intune Provisioning Client AppId : {0}" -f $script:ETDG_ProvisioningClientAppId)
    Write-Host  "Artifact name defaults:"
    $script:ETDG_Defaults.GetEnumerator() | ForEach-Object { Write-Host ("  {0,-18} {1}" -f $_.Key, $_.Value) }

    if ($GroupName) {
        Connect-EtdgGraph | Out-Null
        $grp = Get-EtdgGroupByName -Name $GroupName
        if (-not $grp) { Write-Host "`nGroup '$GroupName' not found." -ForegroundColor Yellow; return }
        $g = $grp[0]
        $ownerOk = Test-EtdgProvisioningClientOwner -GroupId $g.id
        Write-Host "`n=== Quick health summary: $GroupName ===" -ForegroundColor Cyan
        Write-Host ("  Security group        : {0}" -f ($(if ($g.securityEnabled) {'PASS'} else {'FAIL'})))
        Write-Host ("  Assigned membership   : {0}" -f ($(if ([string]::IsNullOrEmpty($g.membershipRule)) {'PASS'} else {'FAIL (Dynamic)'})))
        Write-Host ("  Cloud-only            : {0}" -f ($(if (-not $g.onPremisesSyncEnabled) {'PASS'} else {'FAIL (synced)'})))
        Write-Host ("  Not mail-enabled      : {0}" -f ($(if (-not $g.mailEnabled) {'PASS'} else {'FAIL'})))
        Write-Host ("  Not role-assignable   : {0}" -f ($(if (-not $g.isAssignableToRole) {'PASS'} else {'FAIL'})))
        Write-Host ("  Provisioning owner    : {0}" -f ($(if ($ownerOk) {'PASS'} else {'FAIL (add SP as owner)'}))) -ForegroundColor ($(if ($ownerOk) {'Green'} else {'Red'}))
    }
}
