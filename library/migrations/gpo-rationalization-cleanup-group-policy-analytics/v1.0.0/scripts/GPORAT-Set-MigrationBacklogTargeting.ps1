<#
.SYNOPSIS
    GPORAT-Set-MigrationBacklogTargeting.ps1 — build the sequenced backlog + Entra scope groups.
.DESCRIPTION
    PURPOSE
        Two jobs: (1) builds the sequenced migration backlog CSV
        ('Migration Backlog - Sequenced - Configure') from the rationalization register — keep and
        consolidate-surviving GPOs ordered by readiness % (high first), replace items tagged with
        their re-implementation surface, retire items excluded; and (2) creates (idempotently) the
        two Entra security scope groups used to drive the later migration, named to convention:
            'Rationalization Scope - Devices - Pilot'
            'Rationalization Scope - Devices - Broad'
        Existing groups of the same name are reused, not duplicated. Optionally seeds the pilot ring.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\GPORAT-Set-MigrationBacklogTargeting.ps1 -RegisterPath .\GPO-Export\GPORAT-Rationalization-Register.csv
        Seed pilot members:  ... -PilotDeviceIds 'objId1','objId2'
        Skip group creation (backlog only):  ... -SkipGroups
        Requires the Microsoft.Graph module and Group.ReadWrite.All (admin consent) for the groups.
    EXPECTED RESULTS
        GPORAT-Migration-Backlog.csv written next to the register (sequenced, with Disposition,
        ReadinessPct, ReplaceSurface, Intent, Order); both scope groups exist (created or found) with
        their object IDs printed; any supplied pilot device object IDs added to the pilot group.
.NOTES
    Workplace Marketplace — Migrations. Writes a CSV and (unless -SkipGroups) creates/updates Entra
    groups only.
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [string]   $RegisterPath = ".\GPO-Export\GPORAT-Rationalization-Register.csv",
    [string[]] $PilotDeviceIds = @(),
    [switch]   $SkipGroups
)

$pilotName = 'Rationalization Scope - Devices - Pilot'
$broadName = 'Rationalization Scope - Devices - Broad'

# ---- 1) Build the sequenced migration backlog from the register -------------------------------
Write-Host "`n=== Building 'Migration Backlog - Sequenced - Configure' ===" -ForegroundColor Cyan
if (-not (Test-Path $RegisterPath)) { Write-Host "Register not found: $RegisterPath. Run GPORAT-Discovery.ps1 and classify first." -ForegroundColor Yellow; return }
$rows = Import-Csv -Path $RegisterPath

# Include keep + consolidate-survivors + replace; exclude retire and merged-away consolidate rows.
$included = @($rows | Where-Object {
    $d = ($_.Disposition).ToString().Trim().ToLower()
    ($d -eq 'keep') -or ($d -eq 'replace') -or ($d -eq 'consolidate' -and -not ($_.ConsolidateInto).ToString().Trim())
})

# Sort by readiness % descending (blank readiness sorts last); keep/consolidate before replace.
$ordered = $included | Sort-Object `
    @{ Expression = { switch (($_.Disposition).ToString().Trim().ToLower()) { 'replace' { 1 } default { 0 } } } }, `
    @{ Expression = { if (($_.ReadinessPct).ToString().Trim() -as [int]) { [int]$_.ReadinessPct } else { -1 } }; Descending = $true }, `
    DisplayName

$i = 0
$backlog = foreach ($r in $ordered) {
    $i++
    [pscustomobject]@{
        Order          = $i
        DisplayName    = $r.DisplayName
        Disposition    = $r.Disposition
        ReadinessPct   = $r.ReadinessPct
        ReplaceSurface = $r.ReplaceSurface
        Intent         = $r.Intent
        Owner          = $r.Owner
    }
}

$backlogCsv = Join-Path (Split-Path $RegisterPath -Parent) 'GPORAT-Migration-Backlog.csv'
$backlog | Export-Csv -Path $backlogCsv -NoTypeInformation -Encoding UTF8
$retired = @($rows | Where-Object { ($_.Disposition).ToString().Trim().ToLower() -eq 'retire' }).Count
$mergedAway = @($rows | Where-Object { ($_.Disposition).ToString().Trim().ToLower() -eq 'consolidate' -and ($_.ConsolidateInto).ToString().Trim() }).Count
Write-Host ("Backlog: {0} item(s) sequenced; excluded {1} retire + {2} merged-away. Saved: {3}" -f $backlog.Count, $retired, $mergedAway, $backlogCsv) -ForegroundColor Green
$backlog | Format-Table Order, DisplayName, Disposition, ReadinessPct -AutoSize

# ---- 2) Build the Entra scope groups ----------------------------------------------------------
if ($SkipGroups) { Write-Host "`n-SkipGroups set — backlog only, no Entra groups created." -ForegroundColor Gray; return }

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'Group.ReadWrite.All' -NoWelcome

function Get-OrNewGroup {
    param([string] $Name)
    $existing = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/groups?`$filter=displayName eq '$Name'").value
    if ($existing) { Write-Host ("  Found : {0}  ({1})" -f $Name, $existing[0].id) -ForegroundColor Green; return $existing[0].id }
    if ($PSCmdlet.ShouldProcess($Name, "Create Entra security group")) {
        $body = @{
            displayName     = $Name
            mailEnabled     = $false
            mailNickname    = ($Name -replace '[^a-zA-Z0-9]', '')
            securityEnabled = $true
        }
        $g = Invoke-MgGraphRequest -Method POST -Uri "/v1.0/groups" -Body ($body | ConvertTo-Json)
        Write-Host ("  Created: {0}  ({1})" -f $Name, $g.id) -ForegroundColor Green
        return $g.id
    }
}

Write-Host "`n=== Building rationalization scope groups ===" -ForegroundColor Cyan
$pilotId = Get-OrNewGroup -Name $pilotName
$broadId = Get-OrNewGroup -Name $broadName

foreach ($id in $PilotDeviceIds) {
    if ($PSCmdlet.ShouldProcess($id, "Add device to '$pilotName'")) {
        try {
            $ref = @{ '@odata.id' = "https://graph.microsoft.com/v1.0/devices/$id" }
            Invoke-MgGraphRequest -Method POST -Uri "/v1.0/groups/$pilotId/members/`$ref" -Body ($ref | ConvertTo-Json)
            Write-Host ("  Added device {0} to pilot scope." -f $id) -ForegroundColor Green
        } catch {
            Write-Host ("  Could not add {0}: {1}" -f $id, $_.Exception.Message) -ForegroundColor Yellow
        }
    }
}

Write-Host "`nUse these names verbatim in the later migration's assignments:" -ForegroundColor Cyan
Write-Host ("  {0}" -f $pilotName)
Write-Host ("  {0}" -f $broadName)
Disconnect-MgGraph | Out-Null
