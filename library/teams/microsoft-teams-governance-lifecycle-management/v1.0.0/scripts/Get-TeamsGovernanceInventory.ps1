<#
.SYNOPSIS
  Read-only discovery/gap assessment of all Teams/M365 Groups: flags ownerless, stale, duplicate, and
  unclassified teams, and reports current creation-control posture. Makes NO changes.
.DESCRIPTION
  Enumerates every Microsoft 365 Group (which back teams) via Microsoft Graph, evaluating owner count,
  last activity/renewal age, near-duplicate display names, and sensitivity-label (classification)
  presence. Also reads the Group.Unified directory setting to show whether open creation is still on.
  Exports a CSV baseline used for the governance report and rollback reference.
.EXAMPLE
  .\Get-TeamsGovernanceInventory.ps1 -StaleDays 180 -MinOwners 2 -OutCsv .\teams-inventory.csv
  (PowerShell 5.1+/7+, Microsoft.Graph + Microsoft.Graph.Beta; connect with Connect-MgGraph)
.NOTES
  Expected results: a table + CSV of every team with Ownerless/Stale/Duplicate/Unclassified flags and a
  banner showing whether EnableGroupCreation is still true (open creation). Read-only — safe to run anytime.
#>
[CmdletBinding()]
param(
    [int]$StaleDays = 180,
    [int]$MinOwners = 2,
    [string]$OutCsv = ".\teams-governance-inventory.csv"
)

$ErrorActionPreference = 'Stop'

function Ensure-MgConnection {
    if (-not (Get-MgContext)) {
        Write-Host "Connecting to Microsoft Graph (read scopes)..." -ForegroundColor Cyan
        Connect-MgGraph -Scopes "Group.Read.All","Directory.Read.All","GroupMember.Read.All" | Out-Null
    }
}

Ensure-MgConnection

# --- Current creation-control posture (Group.Unified directory setting) ---
Write-Host "`n=== Creation-control posture ===" -ForegroundColor Yellow
$creationOpen = $true
try {
    $dirSetting = Get-MgBetaDirectorySetting -All | Where-Object { $_.DisplayName -eq 'Group.Unified' }
    if ($dirSetting) {
        $enable = ($dirSetting.Values | Where-Object Name -eq 'EnableGroupCreation').Value
        $allowedGroup = ($dirSetting.Values | Where-Object Name -eq 'GroupCreationAllowedGroupId').Value
        $creationOpen = ($enable -ne 'false')
        Write-Host ("  EnableGroupCreation      : {0}" -f $enable)
        Write-Host ("  GroupCreationAllowedGroup: {0}" -f ($allowedGroup ? $allowedGroup : '<none>'))
    } else {
        Write-Host "  Group.Unified setting not present -> creation is OPEN (default)." -ForegroundColor Red
    }
} catch {
    Write-Warning "Could not read directory settings (need Microsoft.Graph.Beta + Directory.Read.All): $($_.Exception.Message)"
}
if ($creationOpen) { Write-Host "  RESULT: open creation is ENABLED (governance gap)." -ForegroundColor Red }
else               { Write-Host "  RESULT: creation is controlled." -ForegroundColor Green }

# --- Enumerate M365 Groups (teams) ---
Write-Host "`nEnumerating Microsoft 365 Groups (this may take a while)..." -ForegroundColor Cyan
$groups = Get-MgGroup -Filter "groupTypes/any(c:c eq 'Unified')" -All `
    -Property "id,displayName,createdDateTime,renewedDateTime,visibility,assignedLabels,resourceProvisioningOptions"

$now = Get-Date
$rows = foreach ($g in $groups) {
    $isTeam = $g.ResourceProvisioningOptions -contains 'Team'
    $owners = @(Get-MgGroupOwner -GroupId $g.Id -All -ErrorAction SilentlyContinue)
    $ownerCount = $owners.Count
    $lastTouch = if ($g.RenewedDateTime) { $g.RenewedDateTime } else { $g.CreatedDateTime }
    $ageDays = if ($lastTouch) { [int]($now - $lastTouch).TotalDays } else { $null }
    $labelled = ($g.AssignedLabels | Measure-Object).Count -gt 0

    [pscustomobject]@{
        DisplayName   = $g.DisplayName
        GroupId       = $g.Id
        IsTeam        = $isTeam
        Owners        = $ownerCount
        Ownerless     = ($ownerCount -eq 0)
        UnderOwned    = ($ownerCount -lt $MinOwners)
        AgeDays       = $ageDays
        Stale         = ($ageDays -ne $null -and $ageDays -ge $StaleDays)
        Classified    = $labelled
        Unclassified  = (-not $labelled)
        Visibility    = $g.Visibility
        NameKey       = ($g.DisplayName -replace '[^a-zA-Z0-9]','').ToLower()
    }
}

# --- Duplicate detection (normalized display-name collision) ---
$dupKeys = $rows | Group-Object NameKey | Where-Object Count -gt 1 | Select-Object -ExpandProperty Name
foreach ($r in $rows) { $r | Add-Member -NotePropertyName Duplicate -NotePropertyValue ($dupKeys -contains $r.NameKey) -Force }

# --- Summary ---
Write-Host "`n=== Governance gap summary ===" -ForegroundColor Yellow
Write-Host ("  Total groups/teams : {0}" -f $rows.Count)
Write-Host ("  Ownerless          : {0}" -f (@($rows | Where-Object Ownerless).Count)) -ForegroundColor Red
Write-Host ("  Under-owned (<{0})   : {1}" -f $MinOwners, (@($rows | Where-Object UnderOwned).Count))
Write-Host ("  Stale (>= {0}d)      : {1}" -f $StaleDays, (@($rows | Where-Object Stale).Count)) -ForegroundColor Red
Write-Host ("  Unclassified       : {0}" -f (@($rows | Where-Object Unclassified).Count))
Write-Host ("  Duplicate names    : {0}" -f (@($rows | Where-Object Duplicate).Count))

$rows | Sort-Object DisplayName | Format-Table DisplayName,Owners,AgeDays,Ownerless,Stale,Unclassified,Duplicate -AutoSize
$rows | Sort-Object DisplayName | Export-Csv -Path $OutCsv -NoTypeInformation -Encoding UTF8
Write-Host "`nBaseline inventory written to $OutCsv" -ForegroundColor Green
