<#
.SYNOPSIS
  Remediation (SAFE BY DEFAULT / -WhatIf): resets scopes with BROKEN INHERITANCE back to inherit --
  removing their unique permissions (and the Limited Access they created) -- EXCLUDING documented
  exceptions. Dry-run unless -Commit.
.DESCRIPTION
  Connects with PnP PowerShell (modern auth, no stored credentials) and finds lists/libraries (optionally
  folders/items) with HasUniqueRoleAssignments = true. For each scope NOT listed in the -ExcludeList of
  documented, owner-approved exceptions, it calls the scope's ResetRoleInheritance() so it re-inherits
  the parent's permissions. Records the change as "Inheritance Reset - <Site> - Remediation". SAFE BY
  DEFAULT: lists the scopes it would reset and makes NO changes unless -Commit is supplied. Supports
  -WhatIf. ALWAYS capture SPOPERM-Discovery.ps1 first as the rollback before-state.
.EXAMPLE
  .\SPOPERM-Reset-Inheritance.ps1 -Url https://contoso.sharepoint.com/sites/Finance -ExcludeList .\documented-exceptions.csv -WhatIf
  # Show every scope that would be reset to inherit, honoring the exception list. No changes.
.EXAMPLE
  .\SPOPERM-Reset-Inheritance.ps1 -Url https://contoso.sharepoint.com/sites/Finance -ExcludeList .\documented-exceptions.csv -Commit
  # Reset the non-excepted scopes to inherit (removes their unique permissions / Limited Access).
  # (PowerShell 5.1+/7+, PnP.PowerShell; connect with Connect-PnPOnline -Interactive.)
.NOTES
  Expected results: a list of scopes reset to inherit (excluding exceptions). With -Commit each scope
  re-inherits; re-run SPOPERM-Discovery.ps1 to confirm broken-inheritance/Limited-Access counts dropped to
  the exception set. Requires Site Collection Admin. -ExcludeList is a CSV with a 'ScopeUrl' column matching
  SPOPERM-Discovery.ps1 output. Government cloud: use the correct site URL (*.sharepoint.us).
#>

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory = $true)][string]$Url,
    [string]$ExcludeList,
    [switch]$IncludeItems,
    [switch]$Commit
)

$doWrite = $Commit -and $PSCmdlet.ShouldProcess($Url, 'Reset broken inheritance to inherit')

Write-Host "Connecting to $Url ..." -ForegroundColor Cyan
try {
    Connect-PnPOnline -Url $Url -Interactive -ErrorAction Stop
} catch {
    Write-Error "Connect-PnPOnline failed: $($_.Exception.Message)"; return
}

# Load documented exceptions (scopes we must NOT reset).
$exceptions = @()
if ($ExcludeList) {
    if (Test-Path $ExcludeList) {
        $exceptions = (Import-Csv $ExcludeList).ScopeUrl
        Write-Host "Loaded $($exceptions.Count) documented exception scope(s) from $ExcludeList." -ForegroundColor Cyan
    } else {
        Write-Warning "ExcludeList '$ExcludeList' not found -- proceeding with NO exceptions (all broken-inheritance scopes are candidates)."
    }
}

if (-not $doWrite) {
    Write-Host "`n*** DRY-RUN (report only) -- pass -Commit to apply resets ***`n" -ForegroundColor Yellow
}

$web    = Get-PnPWeb
$reset  = New-Object System.Collections.Generic.List[object]

function Test-Excepted { param([string]$ScopeUrl) return ($exceptions -contains $ScopeUrl) }

function Invoke-ScopeReset {
    param($ClientObject, [string]$ScopeType, [string]$ScopeName, [string]$ScopeUrl)

    Get-PnPProperty -ClientObject $ClientObject -Property HasUniqueRoleAssignments | Out-Null
    if (-not $ClientObject.HasUniqueRoleAssignments) { return }

    if (Test-Excepted -ScopeUrl $ScopeUrl) {
        Write-Host ("  KEEP  {0,-5} {1}  (documented exception)" -f $ScopeType, $ScopeName) -ForegroundColor DarkGray
        return
    }

    Write-Host ("  RESET {0,-5} {1}" -f $ScopeType, $ScopeName) -ForegroundColor Yellow
    $reset.Add([pscustomobject]@{ ScopeType = $ScopeType; ScopeName = $ScopeName; ScopeUrl = $ScopeUrl })

    if ($doWrite) {
        try {
            $ClientObject.ResetRoleInheritance()
            Invoke-PnPQuery
            Write-Host ("        -> now inheriting") -ForegroundColor Green
        } catch {
            Write-Warning "  Reset failed for $ScopeName : $($_.Exception.Message)"
        }
    }
}

Write-Host "Inheritance Reset - $($web.Title) - Remediation" -ForegroundColor Green

$lists = Get-PnPList | Where-Object { -not $_.Hidden -and $_.BaseTemplate -ne 544 }
foreach ($list in $lists) {
    Invoke-ScopeReset -ClientObject $list -ScopeType 'List' -ScopeName $list.Title -ScopeUrl $list.DefaultViewUrl

    if ($IncludeItems) {
        try {
            $items = Get-PnPListItem -List $list -PageSize 500 -Fields 'ID','FileRef' -ErrorAction Stop
            foreach ($item in $items) {
                Get-PnPProperty -ClientObject $item -Property HasUniqueRoleAssignments | Out-Null
                if ($item.HasUniqueRoleAssignments) {
                    $ref = $item.FieldValues['FileRef']
                    Invoke-ScopeReset -ClientObject $item -ScopeType 'Item' -ScopeName "$($list.Title)#$($item.Id)" -ScopeUrl $ref
                }
            }
        } catch {
            Write-Warning "Item scan skipped for '$($list.Title)': $($_.Exception.Message)"
        }
    }
}

Write-Host ("`nScopes {0}: {1}" -f ($(if ($doWrite) {'reset'} else {'that would be reset'})), $reset.Count) -ForegroundColor Cyan
if (-not $doWrite) {
    Write-Host "Dry-run complete. Re-run with -Commit after confirming against the audit + owner sign-off." -ForegroundColor Yellow
} else {
    Write-Host "Commit complete. Verify with SPOPERM-Discovery.ps1 (broken-inheritance count -> exceptions only)." -ForegroundColor Cyan
}
