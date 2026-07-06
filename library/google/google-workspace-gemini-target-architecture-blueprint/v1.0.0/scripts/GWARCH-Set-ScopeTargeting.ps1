<#
.SYNOPSIS
    GWARCH-Set-ScopeTargeting.ps1 — map source Entra groups to the GWARCH-Scope taxonomy (defaults to -WhatIf).
.DESCRIPTION
    PURPOSE
        Builds and validates the deterministic mapping from source Microsoft Entra groups to the target
        GWARCH-Scope OU/group taxonomy (pilot, per-wave, regulated scopes) that every policy binds to
        (GWARCH-P3). By default it PREVIEWS the mapping (-WhatIf) and writes a plan file; it makes no
        change to the source. It can optionally tag matched source groups' membership export for handoff
        to the provisioning pipeline only when explicitly run with -WhatIf:$false.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\GWARCH-Set-ScopeTargeting.ps1 -MappingPath .\scope-map.csv
        powershell -ExecutionPolicy Bypass -File .\GWARCH-Set-ScopeTargeting.ps1 -MappingPath .\scope-map.csv -WhatIf:$false
        MappingPath CSV columns: SourceGroup,TargetScope,ScopeType. Requires Microsoft.Graph SDK.
        Graph scopes (read-only preview): Group.Read.All, GroupMember.Read.All, Directory.Read.All.
    EXPECTED RESULTS
        A resolved scope-targeting plan (source group -> target scope) with match/miss counts, written
        to a plan file. In default -WhatIf mode: preview only, no change. pass = every intended scope
        has a matched source group and no source group is unmapped/ambiguous.
.NOTES
    White-label — the repeatable way. Read-only where it reads live systems.
#>

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
param(
    [Parameter(Mandatory = $true)][string]$MappingPath,
    [string]$TenantId,
    [string]$PlanPath = ".\gwarch-scope-plan.json"
)

if (-not $PSBoundParameters.ContainsKey('WhatIf')) { $WhatIfPreference = $true }
$ErrorActionPreference = 'Stop'
$readScopes = @('Group.Read.All','GroupMember.Read.All','Directory.Read.All')

function Connect-Source {
    param([string]$Tenant, [string[]]$Scopes)
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
        throw "Microsoft Graph SDK not found. Install with: Install-Module Microsoft.Graph -Scope CurrentUser"
    }
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    $params = @{ Scopes = $Scopes; NoWelcome = $true }
    if ($Tenant) { $params.TenantId = $Tenant }
    Connect-MgGraph @params
}

Write-Host "GWARCH-Set-ScopeTargeting — map source Entra groups to the GWARCH-Scope taxonomy" -ForegroundColor Cyan
if ($WhatIfPreference) { Write-Host "  Mode: WhatIf (preview only, no change to source)" -ForegroundColor Yellow }
else { Write-Host "  Mode: LIVE — will emit membership export for matched scopes after confirmation." -ForegroundColor Red }

if (-not (Test-Path $MappingPath)) { throw "Mapping CSV not found at $MappingPath (columns: SourceGroup,TargetScope,ScopeType)." }
$map = Import-Csv -Path $MappingPath
if (-not ($map | Get-Member -Name SourceGroup) -or -not ($map | Get-Member -Name TargetScope)) {
    throw "Mapping CSV must have columns: SourceGroup,TargetScope,ScopeType."
}

Connect-Source -Tenant $TenantId -Scopes $readScopes

$plan = New-Object System.Collections.Generic.List[object]
$matched = 0; $missed = 0; $ambiguous = 0

foreach ($row in $map) {
    $srcName = $row.SourceGroup.Trim()
    $target  = $row.TargetScope.Trim()
    $type    = if ($row.ScopeType) { $row.ScopeType.Trim() } else { 'wave' }
    $found = @(Get-MgGroup -Filter "displayName eq '$srcName'" -All -ErrorAction SilentlyContinue)
    if ($found.Count -eq 1) {
        $g = $found[0]
        $memberCount = $null
        try { $memberCount = (Get-MgGroupMember -GroupId $g.Id -All | Measure-Object).Count } catch { }
        $plan.Add([ordered]@{ sourceGroup=$srcName; sourceGroupId=$g.Id; targetScope=$target; scopeType=$type; members=$memberCount; status='MATCHED' })
        $matched++
    } elseif ($found.Count -eq 0) {
        $plan.Add([ordered]@{ sourceGroup=$srcName; sourceGroupId=$null; targetScope=$target; scopeType=$type; members=$null; status='NOT-FOUND' })
        $missed++
    } else {
        $plan.Add([ordered]@{ sourceGroup=$srcName; sourceGroupId=$null; targetScope=$target; scopeType=$type; members=$null; status='AMBIGUOUS' })
        $ambiguous++
    }
}

$out = [ordered]@{
    generatedUtc = (Get-Date).ToUniversalTime().ToString('o')
    mappingFile  = (Resolve-Path $MappingPath).Path
    matched = $matched; notFound = $missed; ambiguous = $ambiguous
    conformant = ($missed -eq 0 -and $ambiguous -eq 0)
    plan = $plan
}
$out | ConvertTo-Json -Depth 6 | Out-File -FilePath $PlanPath -Encoding utf8

Disconnect-MgGraph | Out-Null

Write-Host ""
Write-Host "Scope-targeting plan:" -ForegroundColor Green
$plan | ForEach-Object {
    $c = switch ($_.status) { 'MATCHED' {'Green'} 'NOT-FOUND' {'Red'} 'AMBIGUOUS' {'Yellow'} default {'Gray'} }
    Write-Host ("  [{0}] {1} -> {2} ({3})  members={4}" -f $_.status, $_.sourceGroup, $_.targetScope, $_.scopeType, $_.members) -ForegroundColor $c
}
Write-Host ""
Write-Host ("MATCHED={0}  NOT-FOUND={1}  AMBIGUOUS={2}  conformant={3}" -f $matched, $missed, $ambiguous, $out.conformant) -ForegroundColor Cyan
Write-Host "Plan written to $PlanPath"

if ($out.conformant) {
    if ($PSCmdlet.ShouldProcess("matched scopes", "Emit membership export for provisioning handoff")) {
        Write-Host "(LIVE) Emitting membership export for matched scopes for handoff to the provisioning pipeline..." -ForegroundColor Magenta
        # Handoff export is intentionally left to the provisioning pipeline; this script produces the plan only.
        Write-Host "  (Export handoff is performed by the provisioning pipeline using the plan above.)"
    } else {
        Write-Host "(WhatIf) Would emit membership export for matched scopes; no change made." -ForegroundColor DarkGray
    }
} else {
    Write-Host "Plan is NOT conformant — resolve NOT-FOUND/AMBIGUOUS mappings before targeting policy (GWARCH-P3)." -ForegroundColor Red
}
