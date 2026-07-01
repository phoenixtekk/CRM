<#
.SYNOPSIS
    ADOBELIC-Validation.ps1 — classify Adobe seats as active, idle, or over-provisioned.
.DESCRIPTION
    PURPOSE
        Joins the seat inventory (from ADOBELIC-Discovery.ps1) to an activity / last-active signal and
        classifies each seat: ACTIVE, IDLE (no activity beyond the threshold), or OVER-PROVISIONED
        (an all-apps seat whose evidence shows single-app use). Produces the right-sizing register.
        Read-only — it never changes an assignment.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\ADOBELIC-Validation.ps1 `
            -InventoryPath .\Seat-Inventory-Pilot-Assess.csv `
            -ActivityPath  .\adobe-activity-export.csv `
            -IdleDays 60
    EXPECTED RESULTS
        Right-Sizing-Register-Pilot-Validate.csv with one row per user: current profile, recommended
        action (keep / downsize / reclaim), evidence, and an empty ConfirmationOwner column to fill in.
.NOTES
    White-label SAM tooling. Read-only.
    Adobe specifics: the activity / last-active signal source and its columns are deferred to Adobe's
    reporting. Where no last-active field is available, supply assignment age and note the limitation.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$InventoryPath,
    [string]$ActivityPath,
    [int]$IdleDays = 60,
    [string]$AllAppsProfilePattern = 'all.?apps',
    [string]$OutPath = ".\Right-Sizing-Register-Pilot-Validate.csv"
)

if (-not (Test-Path $InventoryPath)) { throw "Inventory not found: $InventoryPath (run ADOBELIC-Discovery.ps1)" }
$inv = Import-Csv -Path $InventoryPath

# ADOBE-SPECIFIC: map your activity export's columns. Expect at least User and LastActive (a date).
# Optionally AppsUsed (e.g. a count or list) to detect over-provisioned all-apps seats.
$activity = @{}
if ($ActivityPath -and (Test-Path $ActivityPath)) {
    foreach ($a in Import-Csv -Path $ActivityPath) {
        $u = $a.User ?? $a.Email ?? $a.Username
        if ($u) { $activity[$u] = $a }
    }
} else {
    Write-Host "No activity export supplied — classifying on assignment evidence only (note this limitation)." -ForegroundColor Yellow
}

$today = Get-Date
$register = foreach ($row in $inv) {
    $act = $activity[$row.User]
    $lastActive = $null
    if ($act -and $act.LastActive) { [datetime]::TryParse($act.LastActive, [ref]$lastActive) | Out-Null }

    $isAllApps = $row.ProductProfile -match $AllAppsProfilePattern
    $appsUsed  = if ($act) { $act.AppsUsed } else { $null }

    $action = 'keep'; $evidence = ''
    if ($lastActive) {
        $days = [int]($today - $lastActive).TotalDays
        $evidence = "last active $days days ago"
        if ($days -gt $IdleDays) { $action = 'reclaim' }
    } elseif (-not $act) {
        $evidence = 'no activity signal'
    }
    if ($action -eq 'keep' -and $isAllApps -and $appsUsed -and ([int]($appsUsed -replace '\D','') -le 1)) {
        $action = 'downsize'; $evidence = "all-apps seat, single-app use ($evidence)".Trim()
    }

    [pscustomobject]@{
        User              = $row.User
        ProductProfile    = $row.ProductProfile
        Product           = $row.Product
        Classification    = switch ($action) { 'reclaim' {'IDLE'} 'downsize' {'OVER-PROVISIONED'} default {'ACTIVE'} }
        RecommendedAction = $action
        Evidence          = $evidence
        ConfirmationOwner = ''   # fill in before any reclamation (Best Practices)
    }
}

$register | Export-Csv -Path $OutPath -NoTypeInformation
Write-Host "=== Classification summary ===" -ForegroundColor Cyan
$register | Group-Object Classification | ForEach-Object { Write-Host ("  {0,-18} {1}" -f $_.Name, $_.Count) }
Write-Host ("`nRight-sizing register written to {0}  (Right-Sizing Register - Pilot Scope - Validate)" -f $OutPath) -ForegroundColor Green
Write-Host "Reclaim/downsize rows require a ConfirmationOwner before any removal." -ForegroundColor Yellow
