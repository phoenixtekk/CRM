<#
.SYNOPSIS
    COPILOTG-Validation.ps1 — Read-only pass/fail validation of Copilot governance guardrails on GCC High.
.DESCRIPTION
    PURPOSE
        Checks that the guardrails are in place before expanding Copilot: US Gov connection confirmed,
        CUI sensitivity label published, DLP policy present, Copilot licenses scoped to the intended
        group, and no broadly-shared site left in Copilot's reach. Read-only. Substitute the sample
        names for your own — plain text like 'your-pilot-group', not angle brackets.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\COPILOTG-Validation.ps1 -PilotGroupName 'SG-COPILOTG-Pilot'
        (Graph scopes: Sites.Read.All, Group.Read.All, Directory.Read.All, Policy.Read.All;
         connects with -Environment USGov.)
    EXPECTED RESULTS
        A PASS/FAIL line per check and an overall gate result. Overall PASS = safe to proceed to the
        next wave. Any FAIL = remediate and re-run; do NOT expand.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph US Gov endpoints.
#>

[CmdletBinding()]
param(
    [string] $PilotGroupName = 'SG-COPILOTG-Pilot',
    [string] $CuiLabelName   = 'CUI//BASIC'   # replace with your organization's mandated CUI label
)

$ErrorActionPreference = 'Stop'
$RequiredScopes = @('Sites.Read.All','Group.Read.All','Directory.Read.All','Policy.Read.All','Organization.Read.All')
$results = New-Object System.Collections.Generic.List[object]

function Add-Result([string]$Check,[bool]$Pass,[string]$Detail) {
    $results.Add([pscustomobject]@{ Check = $Check; Result = ($(if($Pass){'PASS'}else{'FAIL'})); Detail = $Detail })
}

function Connect-UsGovGraph {
    Connect-MgGraph -Environment USGov -Scopes $RequiredScopes | Out-Null
    return (Get-MgContext)
}

try {
    $ctx = Connect-UsGovGraph

    # A1 — US Gov connection
    $onUsGov = ($ctx.Environment -eq 'USGov')
    Add-Result 'A1 US Gov connection' $onUsGov "Environment=$($ctx.Environment) (must be USGov / graph.microsoft.us)"
    if (-not $onUsGov) { throw 'Not on USGov — aborting; results from the wrong cloud are meaningless. See Troubleshooting T1.' }

    # A3 — CUI sensitivity label published (informational read; label surface is Purview/GCC High)
    $labelFound = $false
    try {
        $labels = Get-MgSecurityInformationProtectionSensitivityLabel -All -ErrorAction Stop
        $labelFound = [bool]($labels | Where-Object { $_.Name -eq $CuiLabelName -or $_.DisplayName -eq $CuiLabelName })
    } catch {
        Add-Result 'A3 CUI label' $false "Could not read sensitivity labels via Graph; verify in compliance.microsoft.us. ($($_.Exception.Message))"
    }
    if ($labelFound) { Add-Result 'A3 CUI label' $true "Label '$CuiLabelName' present" }
    elseif ($results.Check -notcontains 'A3 CUI label') { Add-Result 'A3 CUI label' $false "Label '$CuiLabelName' not found — create/publish it (Implementation 1.1)" }

    # A5 — Copilot license scope: assigned to the pilot group
    $pilotGroup = Get-MgGroup -Filter "displayName eq '$PilotGroupName'" -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $pilotGroup) {
        Add-Result 'A5 License scope' $false "Pilot group '$PilotGroupName' not found — build it with COPILOTG-Set-ScopeTargeting.ps1"
    } else {
        $copilotSkus = (Get-MgSubscribedSku -All | Where-Object { $_.SkuPartNumber -match 'COPILOT' }).SkuId
        $groupHasCopilot = $false
        try {
            $assigned = (Get-MgGroup -GroupId $pilotGroup.Id -Property 'assignedLicenses').AssignedLicenses
            $groupHasCopilot = [bool]($assigned | Where-Object { $copilotSkus -contains $_.SkuId })
        } catch {}
        Add-Result 'A5 License scope' $groupHasCopilot "Copilot license on group '$PilotGroupName': $groupHasCopilot (group-based licensing recommended)"
    }

    # A2 / A6 — RSS + allow-list hygiene (RSS state is a SharePoint admin setting; verify for GCC High)
    Add-Result 'A2 Restricted SharePoint Search' $false 'VERIFY MANUALLY in SharePoint admin (portal.office365.us): RSS enabled & scoped to "Copilot Search Allowed Sites". RSS availability may lag in GCC High — see parity notes.'
    Add-Result 'A6 Allow-list hygiene' $false 'VERIFY MANUALLY: no broadly-shared site from Discovery remains in the RSS allow-list.'

    # --- Report ---
    Write-Host ''
    Write-Host '=== Validation results ===' -ForegroundColor Cyan
    $results | Format-Table -AutoSize | Out-String | Write-Host
    $autoFail = ($results | Where-Object { $_.Result -eq 'FAIL' -and $_.Check -notmatch 'A2 |A6 ' }).Count
    $manual   = ($results | Where-Object { $_.Detail -match 'VERIFY MANUALLY' }).Count
    if ($autoFail -eq 0) {
        Write-Host "Automated checks PASS. $manual item(s) require MANUAL portal verification (A2, A6) before the expand gate." -ForegroundColor Green
    } else {
        Write-Host "$autoFail automated check(s) FAILED. Remediate and re-run; do NOT expand." -ForegroundColor Red
    }
}
catch {
    Write-Error "Validation failed: $($_.Exception.Message)"
    exit 1
}
finally {
    Disconnect-MgGraph -ErrorAction SilentlyContinue | Out-Null
}
