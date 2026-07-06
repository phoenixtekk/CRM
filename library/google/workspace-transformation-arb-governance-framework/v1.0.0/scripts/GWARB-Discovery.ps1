<#
.SYNOPSIS
    GWARB-Discovery.ps1 — inventory in-flight design decisions and their governance state.
.DESCRIPTION
    PURPOSE
        Reads the Architecture and Design Review Board (ARB) tracking list and emits a design/decision
        inventory: every submitted design, its review gate, current state, owning workstream, and
        whether a decision record exists. Feeds the Decision Register. Read-only.
        Point it at your ARB tracker export (CSV) or, if you keep the tracker as a Microsoft List /
        SharePoint list, at a Microsoft Graph list so the board's live queue is captured.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\GWARB-Discovery.ps1 -TrackerCsv C:\Temp\arb-tracker.csv
        Or read a Microsoft List via Graph:
            powershell -ExecutionPolicy Bypass -File .\GWARB-Discovery.ps1 -SiteId your-site-id -ListId your-list-id
        Graph mode requires the Microsoft Graph PowerShell SDK and the Sites.Read.All scope (read-only).
        Tracker CSV columns: DesignId,Title,Gate,State,Workstream,DecisionRecordId,Submitted,Owner
    EXPECTED RESULTS
        A per-design table (id, gate, state, workstream, has-decision-record) and counts by gate and
        state. Rows in a review gate with no decision record are flagged as open items. No system is
        changed. Pass = the inventory reconciles with the board's tracker and no submitted design is
        missing a gate or owner.
.NOTES
    White-label — the repeatable way. Read-only where it reads live systems.
#>
[CmdletBinding(DefaultParameterSetName = 'Csv')]
param(
    [Parameter(ParameterSetName = 'Csv')][string]$TrackerCsv,
    [Parameter(ParameterSetName = 'Graph', Mandatory)][string]$SiteId,
    [Parameter(ParameterSetName = 'Graph', Mandatory)][string]$ListId,
    [string]$CsvPath
)

$KnownGates = 'Migration Wave Plan','Identity & Sync Model','Security Configuration',
              'Data-Migration Pattern','Work-Transformation Approach'

function Get-DesignRows {
    if ($PSCmdlet.ParameterSetName -eq 'Graph') {
        if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
            Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
        }
        Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
        Connect-MgGraph -Scopes 'Sites.Read.All' -NoWelcome
        $uri = "/v1.0/sites/$SiteId/lists/$ListId/items?`$expand=fields&`$top=200"
        $rows = @()
        do {
            $r = Invoke-MgGraphRequest -Method GET -Uri $uri
            foreach ($i in $r.value) {
                $f = $i.fields
                $rows += [pscustomobject]@{
                    DesignId         = $f.DesignId
                    Title            = $f.Title
                    Gate             = $f.Gate
                    State            = $f.State
                    Workstream       = $f.Workstream
                    DecisionRecordId = $f.DecisionRecordId
                    Submitted        = $f.Submitted
                    Owner            = $f.Owner
                }
            }
            $uri = $r.'@odata.nextLink'
        } while ($uri)
        Disconnect-MgGraph | Out-Null
        return $rows
    }
    if (-not $TrackerCsv -or -not (Test-Path $TrackerCsv)) {
        Write-Host "Tracker CSV not found: $TrackerCsv" -ForegroundColor Red
        Write-Host "Columns: DesignId,Title,Gate,State,Workstream,DecisionRecordId,Submitted,Owner" -ForegroundColor DarkYellow
        exit 2
    }
    return Import-Csv $TrackerCsv
}

$rows = Get-DesignRows
if (-not $rows) { Write-Host "No design records found." -ForegroundColor DarkYellow; exit 0 }

Write-Host "`n=== Design / decision inventory ===" -ForegroundColor Cyan
$inventory = foreach ($d in $rows) {
    [pscustomobject]@{
        DesignId   = $d.DesignId
        Gate       = $d.Gate
        State      = $d.State
        Workstream = $d.Workstream
        HasRecord  = if ($d.DecisionRecordId) { 'yes' } else { 'no' }
        Owner      = $d.Owner
    }
}
$inventory | Sort-Object Gate, DesignId | Format-Table DesignId, Gate, State, Workstream, HasRecord, Owner -AutoSize

Write-Host "`n--- By review gate ---" -ForegroundColor Cyan
$inventory | Group-Object Gate | Sort-Object Name | ForEach-Object {
    Write-Host ("  {0,-28} {1}" -f $_.Name, $_.Count)
}
Write-Host "`n--- By state ---" -ForegroundColor Cyan
$inventory | Group-Object State | Sort-Object Name | ForEach-Object {
    Write-Host ("  {0,-28} {1}" -f $_.Name, $_.Count)
}

# Open items: in a review gate but with no decision record recorded yet.
$open = $inventory | Where-Object { $_.HasRecord -eq 'no' -and $_.State -notmatch 'Approved|Rejected|Withdrawn' }
Write-Host ("`nOpen items awaiting a decision record: {0}" -f $open.Count) -ForegroundColor Yellow

$unknownGate = $inventory | Where-Object { $KnownGates -notcontains $_.Gate }
if ($unknownGate) {
    Write-Host ("Designs with a gate outside the standard five ({0}) — confirm classification:" -f ($KnownGates -join ', ')) -ForegroundColor DarkYellow
    $unknownGate | Format-Table DesignId, Gate -AutoSize
}

if ($CsvPath) { $inventory | Export-Csv -Path $CsvPath -NoTypeInformation; Write-Host "Saved $CsvPath" -ForegroundColor Green }
Write-Host "Record this inventory against the Decision Register - Transformation ARB - Program-Wide." -ForegroundColor DarkYellow
