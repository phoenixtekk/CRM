<#
.SYNOPSIS
    GWARCH-Validation.ps1 — read-only architecture-conformance checks against the M365/Entra source estate.
.DESCRIPTION
    PURPOSE
        Runs the machine-checkable subset of the target-architecture conformance gates against the
        source Microsoft 365 / Entra ID estate: single identity source of truth (no shadow
        provisioning), break-glass admin independent of the federated IdP, scope-based targeting, and
        bounded-coexistence indicators. Emits pass/fail per check to feed Gates 0-2 of the blueprint.
        Read-only: it evaluates, it never changes the source. Provide your-tenant-id via -TenantId.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\GWARCH-Validation.ps1
        powershell -ExecutionPolicy Bypass -File .\GWARCH-Validation.ps1 -TenantId your-tenant-id -OutputPath .\gwarch-validation.json
        Requires: Microsoft.Graph SDK. Graph scopes (read-only): Directory.Read.All, User.Read.All,
        Group.Read.All, Organization.Read.All, RoleManagement.Read.Directory, Policy.Read.All.
    EXPECTED RESULTS
        A pass/fail table per conformance check plus a JSON report. PASS = conformant; FAIL = a gap to
        remediate (see GWARCH-Remediation.ps1) or record as an ARB exception ADR.
.NOTES
    White-label — the repeatable way. Read-only where it reads live systems.
#>

[CmdletBinding()]
param(
    [string]$TenantId,
    [string]$OutputPath = ".\gwarch-validation.json"
)

$ErrorActionPreference = 'Stop'
$readScopes = @(
    'Directory.Read.All','User.Read.All','Group.Read.All',
    'Organization.Read.All','RoleManagement.Read.Directory','Policy.Read.All'
)

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

$results = New-Object System.Collections.Generic.List[object]
function Add-Check {
    param([string]$Id, [string]$Gate, [string]$Principle, [string]$Name, [ValidateSet('PASS','FAIL','WARN','INFO')][string]$Status, [string]$Detail)
    $results.Add([ordered]@{ id=$Id; gate=$Gate; principle=$Principle; check=$Name; status=$Status; detail=$Detail })
}

Write-Host "GWARCH-Validation — read-only architecture-conformance checks (source M365/Entra)" -ForegroundColor Cyan
Connect-Source -Tenant $TenantId -Scopes $readScopes

# Check 1 — single identity source of truth (no mixed shadow provisioning)
try {
    $org = Get-MgOrganization | Select-Object -First 1
    $sample = Get-MgUser -Top 500 -Property Id,OnPremisesSyncEnabled
    $onPrem = ($sample | Where-Object { $_.OnPremisesSyncEnabled }).Count
    $cloud  = $sample.Count - $onPrem
    if ($org.OnPremisesSyncEnabled -and $onPrem -gt 0 -and $cloud -gt 0) {
        Add-Check 'C1' 'Gate 1' 'GWARCH-ID-1' 'Single identity source (no shadow provisioning)' 'FAIL' "Sample shows $onPrem on-prem-synced and $cloud cloud-only users; confirm one authoritative source (ADR GWARCH-ADR-ID-01)."
    } elseif ($org.OnPremisesSyncEnabled) {
        Add-Check 'C1' 'Gate 1' 'GWARCH-ID-1' 'Single identity source (no shadow provisioning)' 'PASS' "On-prem synced source; sample is consistent."
    } else {
        Add-Check 'C1' 'Gate 1' 'GWARCH-ID-1' 'Single identity source (no shadow provisioning)' 'PASS' "Cloud-only source; sample is consistent."
    }
} catch { Add-Check 'C1' 'Gate 1' 'GWARCH-ID-1' 'Single identity source (no shadow provisioning)' 'WARN' "Could not evaluate: $($_.Exception.Message)" }

# Check 2 — break-glass admin independent of federated IdP (cloud-only privileged account exists)
try {
    $gaRole = Get-MgDirectoryRole -All | Where-Object { $_.DisplayName -match 'Global Administrator' } | Select-Object -First 1
    if ($gaRole) {
        $admins = Get-MgDirectoryRoleMember -DirectoryRoleId $gaRole.Id -All
        $cloudOnlyAdmin = $false
        foreach ($m in $admins) {
            try {
                $u = Get-MgUser -UserId $m.Id -Property OnPremisesSyncEnabled -ErrorAction Stop
                if (-not $u.OnPremisesSyncEnabled) { $cloudOnlyAdmin = $true; break }
            } catch { }
        }
        if ($cloudOnlyAdmin) {
            Add-Check 'C2' 'Gate 1' 'GWARCH-ID-2' 'Break-glass admin independent of federated IdP' 'PASS' "At least one cloud-only privileged account exists (candidate break-glass path)."
        } else {
            Add-Check 'C2' 'Gate 1' 'GWARCH-ID-2' 'Break-glass admin independent of federated IdP' 'FAIL' "No cloud-only privileged account found; an IdP outage could lock out administration."
        }
    } else {
        Add-Check 'C2' 'Gate 1' 'GWARCH-ID-2' 'Break-glass admin independent of federated IdP' 'WARN' "Global Administrator role not activated/enumerable in this session."
    }
} catch { Add-Check 'C2' 'Gate 1' 'GWARCH-ID-2' 'Break-glass admin independent of federated IdP' 'WARN' "Could not evaluate: $($_.Exception.Message)" }

# Check 3 — scope-based targeting is possible (governance groups exist to bind policy to)
try {
    $groupCount = (Get-MgGroup -All -Property Id | Measure-Object).Count
    if ($groupCount -gt 0) {
        Add-Check 'C3' 'Gate 0' 'GWARCH-P3' 'Scope model available (groups to target policy)' 'PASS' "$groupCount groups available to map to the GWARCH-Scope taxonomy."
    } else {
        Add-Check 'C3' 'Gate 0' 'GWARCH-P3' 'Scope model available (groups to target policy)' 'FAIL' "No groups found; cannot govern by scope. Define the GWARCH-Scope taxonomy (ADR GWARCH-ADR-SCOPE-01)."
    }
} catch { Add-Check 'C3' 'Gate 0' 'GWARCH-P3' 'Scope model available (groups to target policy)' 'WARN' "Could not evaluate: $($_.Exception.Message)" }

# Check 4 — bounded coexistence: verified domains present (mail-flow/coexistence design surface)
try {
    $verified = (Get-MgDomain -All | Where-Object { $_.IsVerified }).Count
    Add-Check 'C4' 'Gate 2' 'GWARCH-P5' 'Coexistence design surface (verified domains)' 'INFO' "$verified verified domain(s). Each routed domain's coexistence bridge must carry a sunset condition (GWARCH-COL-2)."
} catch { Add-Check 'C4' 'Gate 2' 'GWARCH-P5' 'Coexistence design surface (verified domains)' 'WARN' "Could not evaluate: $($_.Exception.Message)" }

Disconnect-MgGraph | Out-Null

$summary = [ordered]@{
    generatedUtc = (Get-Date).ToUniversalTime().ToString('o')
    pass = ($results | Where-Object { $_.status -eq 'PASS' }).Count
    fail = ($results | Where-Object { $_.status -eq 'FAIL' }).Count
    warn = ($results | Where-Object { $_.status -eq 'WARN' }).Count
    checks = $results
}
$summary | ConvertTo-Json -Depth 6 | Out-File -FilePath $OutputPath -Encoding utf8

Write-Host ""
Write-Host "Conformance results:" -ForegroundColor Green
$results | ForEach-Object {
    $color = switch ($_.status) { 'PASS' {'Green'} 'FAIL' {'Red'} 'WARN' {'Yellow'} default {'Gray'} }
    Write-Host ("  [{0}] {1} ({2}) — {3}" -f $_.status, $_.check, $_.principle, $_.detail) -ForegroundColor $color
}
Write-Host ""
Write-Host ("PASS={0}  FAIL={1}  WARN={2}" -f $summary.pass, $summary.fail, $summary.warn) -ForegroundColor Cyan
Write-Host "Full report written to $OutputPath"
if ($summary.fail -gt 0) { Write-Host "One or more conformance FAILs — remediate (GWARCH-Remediation.ps1) or record an ARB exception ADR." -ForegroundColor Red }
