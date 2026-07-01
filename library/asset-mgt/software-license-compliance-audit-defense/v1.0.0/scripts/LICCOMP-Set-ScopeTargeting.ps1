<#
.SYNOPSIS
    LICCOMP-Set-ScopeTargeting.ps1 — build the reconciliation-scope group for an in-scope product.
.DESCRIPTION
    PURPOSE
        Creates (or reuses) a Microsoft Entra security group that holds the population to reconcile
        for one publisher/product — the members who could consume the in-scope license. Use it to
        define the pilot scope and to keep reconciliation consistent across cycles. Optionally seeds
        membership from a CSV of UPNs. Supports -WhatIf to preview without creating anything.
    HOW TO RUN
        Preview:
          powershell -ExecutionPolicy Bypass -File .\LICCOMP-Set-ScopeTargeting.ps1 -ProductName "Acme Designer" -WhatIf
        Create the group:
          powershell -ExecutionPolicy Bypass -File .\LICCOMP-Set-ScopeTargeting.ps1 -ProductName "Acme Designer"
        Create and seed members from a CSV (column: UserPrincipalName):
          powershell -ExecutionPolicy Bypass -File .\LICCOMP-Set-ScopeTargeting.ps1 -ProductName "Acme Designer" -MembersCsv .\scope.csv
        Requires Microsoft Graph SDK and scopes Group.ReadWrite.All, User.Read.All.
    EXPECTED RESULTS
        A security group named "LICCOMP-Scope-<Product>" reported (created or reused) and, if a CSV is
        supplied, the listed members added. In -WhatIf mode, the intended actions are printed only.
.NOTES
    Workplace Marketplace — Asset Mgt. Creates an Entra group; supports -WhatIf.
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)] [string]$ProductName,
    [string]$MembersCsv
)

$safe = ($ProductName -replace '[^A-Za-z0-9]+','-').Trim('-')
$groupName = "LICCOMP-Scope-$safe"

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'Group.ReadWrite.All','User.Read.All' -NoWelcome

Write-Host "`n=== Reconciliation scope group — $groupName ===" -ForegroundColor Cyan

# Reuse if it already exists.
$existing = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/groups?`$filter=displayName eq '$groupName'").value | Select-Object -First 1
$groupId = $existing.id

if (-not $groupId) {
    if ($PSCmdlet.ShouldProcess($groupName, "Create security group")) {
        $body = @{
            displayName     = $groupName
            description     = "Reconciliation scope for $ProductName (Effective License Position)"
            mailEnabled     = $false
            mailNickname    = $groupName.ToLower()
            securityEnabled = $true
        } | ConvertTo-Json
        $g = Invoke-MgGraphRequest -Method POST -Uri "/v1.0/groups" -Body $body -ContentType 'application/json'
        $groupId = $g.id
        Write-Host "  Created group $groupName ($groupId)" -ForegroundColor Green
    } else {
        Write-Host "  WOULD create group $groupName" -ForegroundColor Gray
    }
} else {
    Write-Host "  Reusing existing group $groupName ($groupId)" -ForegroundColor Green
}

if ($MembersCsv) {
    if (-not (Test-Path $MembersCsv)) { throw "Members CSV not found: $MembersCsv" }
    $members = Import-Csv -Path $MembersCsv
    foreach ($m in $members) {
        $upn = $m.UserPrincipalName
        if (-not $upn) { continue }
        if ($PSCmdlet.ShouldProcess($upn, "Add to $groupName")) {
            try {
                $u = Invoke-MgGraphRequest -Method GET -Uri "/v1.0/users/$upn?`$select=id"
                $ref = @{ '@odata.id' = "https://graph.microsoft.com/v1.0/directoryObjects/$($u.id)" } | ConvertTo-Json
                Invoke-MgGraphRequest -Method POST -Uri "/v1.0/groups/$groupId/members/`$ref" -Body $ref -ContentType 'application/json' | Out-Null
                Write-Host "    Added $upn" -ForegroundColor Green
            } catch {
                Write-Host ("    Skipped {0}: {1}" -f $upn, $_.Exception.Message) -ForegroundColor Yellow
            }
        } else {
            Write-Host "    WOULD add $upn" -ForegroundColor Gray
        }
    }
}

Write-Host "`nUse '$groupName' as the in-scope population for discovery and reconciliation." -ForegroundColor Green
Disconnect-MgGraph | Out-Null
