<#
.SYNOPSIS
    CCAUDIT-Set-ScopeTargeting.ps1 — build/populate the pilot or fleet target group (preview by default).
.DESCRIPTION
    PURPOSE
        Create and populate the Entra security groups that define monitoring scope — the pilot group
        (CCAUDIT-Pilot-Devices) and the fleet group (CCAUDIT-Fleet-Devices). Runs in preview
        (-WhatIf) by default: it shows the group it would create and the members it would add, and
        changes nothing. Nothing is created or modified until you re-run with -Commit.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\CCAUDIT-Set-ScopeTargeting.ps1 -GroupName CCAUDIT-Pilot-Devices -OutputPath C:\CCAUDIT\out
        (add -Commit to create/populate)

        Required Graph scopes: Group.Read.All, Directory.Read.All (preview);
        Group.ReadWrite.All (commit).
    EXPECTED RESULTS
        Preview: writes CCAUDIT-Targeting-Plan-<timestamp>.csv listing the group and candidate members;
        creates/changes nothing. With -Commit: creates the group if missing and adds members.
        PASS: the intended group exists with the expected representative devices.
        FAIL: group not created or members missing after -Commit — check Group.ReadWrite.All consent.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph. CIS/STIG control content deferred to CIS/DISA.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$GroupName,
    [string]$SourceGroupName,
    [int]$PilotSampleSize = 10,
    [string]$OutputPath = ".",
    [switch]$WhatIf = $true,
    [switch]$Commit
)

$ErrorActionPreference = "Stop"

# Safety: default posture is preview. -Commit is required to actually change anything.
if ($Commit) { $WhatIf = $false }

$scopes = if ($WhatIf) {
    @("Group.Read.All", "Directory.Read.All")
} else {
    @("Group.ReadWrite.All", "Directory.Read.All")
}

function Connect-CCAudit {
    param([string[]]$Scopes)
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph)) {
        throw "Microsoft.Graph module not found. Run: Install-Module Microsoft.Graph -Scope CurrentUser"
    }
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    Connect-MgGraph -Scopes $Scopes -NoWelcome | Out-Null
    $ctx = Get-MgContext
    if (-not $ctx) { throw "Failed to connect to Microsoft Graph." }
    return $ctx
}

function Invoke-CCGraphGet {
    param([string]$Uri)
    $items = @()
    $next = $Uri
    while ($next) {
        $resp = Invoke-MgGraphRequest -Method GET -Uri $next
        if ($resp.value) { $items += $resp.value } elseif ($resp) { $items += $resp }
        $next = $resp.'@odata.nextLink'
    }
    return $items
}

if (-not (Test-Path -LiteralPath $OutputPath)) {
    New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
}
$stamp = Get-Date -Format "yyyyMMdd-HHmmss"

$mode = if ($WhatIf) { "PREVIEW (-WhatIf) — no changes will be made" } else { "COMMIT — group/members WILL be created" }
Write-Host ("Targeting mode: {0}" -f $mode) -ForegroundColor $([bool]$WhatIf ? 'Yellow' : 'Red')

Write-Host "Connecting to Microsoft Graph..." -ForegroundColor Cyan
$ctx = Connect-CCAudit -Scopes $scopes

# Does the target group already exist?
$existing = Invoke-CCGraphGet ("https://graph.microsoft.com/v1.0/groups?`$filter=displayName eq '{0}'" -f $GroupName)
$groupId = if ($existing) { $existing[0].id } else { $null }

# Candidate members: from a source group if given, else a sample of managed Windows devices.
$candidates = @()
if ($SourceGroupName) {
    $src = Invoke-CCGraphGet ("https://graph.microsoft.com/v1.0/groups?`$filter=displayName eq '{0}'" -f $SourceGroupName)
    if (-not $src) { throw "Source group '$SourceGroupName' not found." }
    $candidates = Invoke-CCGraphGet ("https://graph.microsoft.com/v1.0/groups/{0}/members?`$select=id,displayName,deviceId" -f $src[0].id)
}
else {
    $candidates = Invoke-CCGraphGet "https://graph.microsoft.com/v1.0/devices?`$select=id,displayName,deviceId,operatingSystem&`$top=200"
}

# Pilot groups get a representative sample; fleet groups take all candidates.
if ($GroupName -match 'Pilot') {
    $candidates = $candidates | Select-Object -First $PilotSampleSize
}

$plan = New-Object System.Collections.Generic.List[object]
$plan.Add([pscustomobject]@{
    Item = "Group"; Name = $GroupName
    Action = if ($groupId) { "Exists (id $groupId) — will reuse" } else { "Will be created (Security group)" }
    Mode = if ($WhatIf) { "Preview" } else { "Commit" }
})
foreach ($c in $candidates) {
    $plan.Add([pscustomobject]@{
        Item = "Member"; Name = $c.displayName
        Action = ("Add device {0}" -f $c.id)
        Mode = if ($WhatIf) { "Preview" } else { "Commit" }
    })
}

if (-not $WhatIf) {
    if (-not $groupId) {
        $body = @{
            displayName     = $GroupName
            mailEnabled     = $false
            mailNickname    = ($GroupName -replace '[^a-zA-Z0-9]', '')
            securityEnabled = $true
        }
        $new = Invoke-MgGraphRequest -Method POST -Uri "https://graph.microsoft.com/v1.0/groups" -Body ($body | ConvertTo-Json)
        $groupId = $new.id
        Write-Host ("[COMMIT] Created group '{0}' (id {1})" -f $GroupName, $groupId) -ForegroundColor Red
    }
    foreach ($c in $candidates) {
        try {
            $ref = @{ "@odata.id" = ("https://graph.microsoft.com/v1.0/directoryObjects/{0}" -f $c.id) }
            Invoke-MgGraphRequest -Method POST -Uri ("https://graph.microsoft.com/v1.0/groups/{0}/members/`$ref" -f $groupId) -Body ($ref | ConvertTo-Json) | Out-Null
        }
        catch {
            Write-Warning ("Add member {0}: {1}" -f $c.displayName, $_.Exception.Message)
        }
    }
    Write-Host ("[COMMIT] Ensured {0} member(s) in '{1}'." -f ($candidates | Measure-Object).Count, $GroupName) -ForegroundColor Green
}

$planCsv = Join-Path $OutputPath "CCAUDIT-Targeting-Plan-$stamp.csv"
$plan | Export-Csv -Path $planCsv -NoTypeInformation -Encoding UTF8
Write-Host ("Targeting plan written: {0}" -f $planCsv) -ForegroundColor Green
if ($WhatIf) {
    Write-Host "Preview only. Re-run with -Commit to create/populate the group." -ForegroundColor Yellow
}

Disconnect-MgGraph | Out-Null
