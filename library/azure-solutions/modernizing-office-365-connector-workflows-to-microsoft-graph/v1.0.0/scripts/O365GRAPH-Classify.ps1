<#
.SYNOPSIS
    O365GRAPH-Classify.ps1 — score each discovered connector flow by risk and Graph-migratability
    and write the migration register.
.DESCRIPTION
    PURPOSE
        Read-only classification for the migration program. Reads the discovery register
        ("Connector-Flow-Inventory - Estate - Program.csv"), scores every flow on two axes, assigns
        the sibling migration pattern, and writes the "Migration-Register - Estate - Program.csv".
        Makes NO changes.

        RISK score (higher = migrate sooner):
            +3  Service account / stored secret (standing credential, shared blast radius)
            +2  Interactive user (delegated token)
            +1  Over-scope signal (touches many mailboxes / broad access)
             0  Already a managed identity
        GRAPH-MIGRATABILITY class:
            Clean       — Logic App whose action has a direct Graph equivalent and can take a
                          managed identity
            Redesign    — behaviour maps to Graph but the flow needs restructuring
            Re-platform — Power Automate flow that cannot take an Azure managed identity (its modern
                          target is a re-platform to a Logic App or a least-privilege service
                          principal / connection) — VERIFY per flow against current Microsoft docs
        SIBLING PATTERN (the per-flow build the program references, does not reproduce):
            #1 send/read/move mail · #2 change-notification trigger · #3 scheduled polling ·
            #5 managed-identity foundation · every mail flow tagged "scope per #4"
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\O365GRAPH-Classify.ps1 `
            -InputCsv '.\Connector-Flow-Inventory - Estate - Program.csv' `
            -OutputCsv '.\Migration-Register - Estate - Program.csv'
    SCOPES / ROLES
        None beyond read access to the input CSV — this is an offline scoring pass over discovery output.
    EXPECTED RESULTS
        The migration register: each flow with a RiskScore, RiskBand (High/Med/Low), Migratability
        class, assigned SiblingPattern, ScopePerSibling4 flag, and a suggested Wave — sorted so the
        highest-risk + cleanest flows lead. Tag the pilot cohort from the top of this list.
.NOTES
    Azure Solutions — read-only. Scores discovery output; makes no changes.
    White-label sample values use contoso.com. "Re-platform" viability is a verify-against-docs item.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$InputCsv,
    [string]$OutputCsv = ".\Migration-Register - Estate - Program.csv"
)

if (-not (Test-Path $InputCsv)) { throw "Input register not found: $InputCsv (run O365GRAPH-Discovery.ps1 first)." }
$flows = Import-Csv -Path $InputCsv

$out = foreach ($f in $flows) {
    $risk = 0
    switch -Regex ($f.AuthModel) {
        'Service account|secret|standing' { $risk += 3 }
        'Interactive user|delegated'      { $risk += 2 }
        'Managed identity'                { $risk += 0 }
        default                           { $risk += 2 }   # Unknown treated as delegated-risk until confirmed
    }
    if ($f.MailboxesOrResources -match ';' ) { $risk += 1 }   # multiple targets = over-scope signal

    $band = if ($risk -ge 3) { 'High' } elseif ($risk -ge 2) { 'Med' } else { 'Low' }

    # Migratability
    $mig = if     ($f.Platform -eq 'PowerAutomate') { 'Re-platform (verify MI support)' }
           elseif ($f.AuthModel -match 'Managed identity') { 'Clean' }
           else   { 'Clean' }   # Logic App default; downgrade to Redesign on review if no direct Graph equivalent

    # Sibling pattern (heuristic on connector/name; confirm against the flow's actual trigger/action)
    $pattern = 'unassigned'
    if     ($f.Connectors -match 'excel')            { $pattern = '#5 (MI foundation) + Graph Excel — verify' }
    elseif ($f.FlowName   -match 'poll|schedule|recurr') { $pattern = '#3 polling' }
    elseif ($f.FlowName   -match 'arriv|trigger|notif')  { $pattern = '#2 change-notification' }
    elseif ($f.Connectors -match 'office365users')   { $pattern = '#5 (MI foundation) + Graph Users' }
    else   { $pattern = '#1 send/read mail' }

    $scope4 = if ($f.Connectors -match 'office365(;|$)|office365users|excel') { 'YES — scope per #4' } else { 'review' }

    [pscustomobject]@{
        FlowName         = $f.FlowName
        Platform         = $f.Platform
        Connectors       = $f.Connectors
        AuthModel        = $f.AuthModel
        RiskScore        = $risk
        RiskBand         = $band
        Migratability    = $mig
        SiblingPattern   = $pattern
        ScopePerSibling4 = $scope4
        SuggestedWave    = ''      # fill: PILOT - Connector Migration - Pilot, then Wave 01..NN
        ResourceId       = $f.ResourceId
    }
}

# Sort: highest risk first, then Clean before Redesign/Re-platform.
$sorted = $out | Sort-Object -Property @{Expression='RiskScore';Descending=$true}, @{Expression='Migratability';Descending=$false}
$sorted | Export-Csv -Path $OutputCsv -NoTypeInformation -Encoding UTF8

Write-Host ("Classified {0} flow(s) -> {1}" -f ($sorted | Measure-Object).Count, $OutputCsv) -ForegroundColor Green
Write-Host ("  High risk: {0}  Med: {1}  Low: {2}" -f `
    (($sorted | Where-Object RiskBand -eq 'High') | Measure-Object).Count, `
    (($sorted | Where-Object RiskBand -eq 'Med')  | Measure-Object).Count, `
    (($sorted | Where-Object RiskBand -eq 'Low')  | Measure-Object).Count) -ForegroundColor Cyan
Write-Host "Tag the pilot cohort 'PILOT - Connector Migration - Pilot' from the top of the register." -ForegroundColor Cyan
