<#
.SYNOPSIS
    CPADMDX-Report-Findings.ps1 - Consolidate the outputs of the other diagnostic scripts into a single
    findings file (CPADMDX-Findings.json + a readable CPADMDX-Findings.txt) with the resolved root-cause
    branch and recommended next action. READ-ONLY.

.DESCRIPTION
    PURPOSE
      Aggregates CPADMDX-Preflight.json, CPADMDX-Probe.json, CPADMDX-Scopes.json, and
      CPADMDX-Fallbacks.json (whichever exist) into one artifact you can keep or attach to a Microsoft
      support case. It derives the single most likely branch from the collected facts. It creates the
      CPADMDX-Diagnostics folder if missing and changes nothing in the tenant.

    HOW TO RUN
      1. Run the other scripts first (Preflight, Probe, Resolve-Scopes, optionally Test-Fallbacks).
      2. Run:
           .\CPADMDX-Report-Findings.ps1
           .\CPADMDX-Report-Findings.ps1 -OutputFolder .\CPADMDX-Diagnostics

    EXPECTED RESULTS
      Writes CPADMDX-Diagnostics\CPADMDX-Findings.json and CPADMDX-Findings.txt, and prints the summary:
      the failing call, the resolved branch, and the recommended next step (fix or supported fallback).

.NOTES
    Copilot category - read-only diagnostics for the Microsoft Graph Copilot admin (beta) API.
    The summary is heuristic; always confirm against the runbook branches and current Microsoft docs.
#>
[CmdletBinding()]
param(
    [string]$OutputFolder = '.\CPADMDX-Diagnostics'
)

$ErrorActionPreference = 'Stop'
if (-not (Test-Path $OutputFolder)) { New-Item -ItemType Directory -Path $OutputFolder | Out-Null }

function Read-Json([string]$file) {
    $p = Join-Path $OutputFolder $file
    if (Test-Path $p) { try { return (Get-Content $p -Raw | ConvertFrom-Json) } catch { return $null } }
    return $null
}

$pre   = Read-Json 'CPADMDX-Preflight.json'
$probe = Read-Json 'CPADMDX-Probe.json'
$scope = Read-Json 'CPADMDX-Scopes.json'
$fb    = Read-Json 'CPADMDX-Fallbacks.json'

# Derive a single resolved branch from the collected facts.
$branch = 'Insufficient data - run CPADMDX-Preflight.ps1 and CPADMDX-Probe-Endpoint.ps1 first.'
$action = 'Collect Step 0 facts, then branch.'

if ($probe) {
    switch ([int]$probe.StatusCode) {
        200 { $branch = 'RESOLVED - call returns 200.'; $action = 'Proceed; apply the GA-vs-beta dependency decision in best-practices.' }
        401 { $branch = 'A - Authentication.'; $action = 'Reconnect with a fresh token in the correct cloud.' }
        403 {
            if ($probe.ErrorMessage -match 'user context is required' -or $pre.AuthType -eq 'AppOnly') {
                $branch = 'B - App-only rejected.'; $action = 'Switch to delegated interactive sign-in as an admin.'
            }
            elseif ($scope -and -not $scope.ScopeSatisfied) {
                $branch = 'C/D - Missing scope / consent.'; $action = "Reconnect requesting $($scope.NeedScopes -join ', '); admin-consent if blocked."
            }
            elseif ($scope -and $scope.AdminRoleNeeded -and -not $scope.RoleSatisfied) {
                $branch = 'E - Missing admin role.'; $action = 'Assign AI Administrator (or Global Administrator) to the caller.'
            }
            elseif ($pre.Environment -and $pre.Environment -ne 'Global') {
                $branch = 'F - Cloud not enabled.'; $action = 'Copilot admin beta is Global-only; use supported fallbacks in your cloud.'
            }
            else {
                $branch = 'F/G/R8 - Tenant/cloud/license/flighting.'; $action = 'Confirm licensing (Agent 365 - customer excluded), tenant flighting, and cloud; else fallback.'
            }
        }
        404 { $branch = 'H - Path/version not found.'; $action = 'Verify exact route + version against current docs; if correct, suspect flighting/cloud (F/R8).' }
        429 { $branch = 'I - Throttling.'; $action = "Honor Retry-After ($($probe.RetryAfter)); back off exponentially." }
        default { $branch = 'J - Review; possible product limitation.'; $action = 'Reproduce in a known-good tenant; else use supported fallback.' }
    }
}

$summary = [pscustomobject]@{
    Timestamp    = (Get-Date).ToString('o')
    Solution     = 'CPADMDX - Microsoft Graph Beta Copilot Admin API Access & Troubleshooting Runbook'
    Preflight    = $pre
    Probe        = $probe
    ScopeResolve = $scope
    Fallbacks    = $fb
    ResolvedBranch = $branch
    RecommendedAction = $action
    Disclaimer   = 'Beta endpoints are subject to change; confirm every claim against current Microsoft documentation.'
}

$jsonPath = Join-Path $OutputFolder 'CPADMDX-Findings.json'
$summary | ConvertTo-Json -Depth 12 | Set-Content -Path $jsonPath -Encoding UTF8

$txt = @()
$txt += "CPADMDX - Diagnostic Findings"
$txt += "Generated : $($summary.Timestamp)"
$txt += "Failing call : $($probe.Uri)"
$txt += "HTTP status  : $($probe.StatusCode)  $($probe.ErrorCode)"
$txt += "Message      : $($probe.ErrorMessage)"
$txt += "Auth type    : $($pre.AuthType)   Cloud: $($pre.Environment)"
$txt += "Scopes held  : $($pre.Scopes -join ', ')"
$txt += "Roles held   : $($pre.DirectoryRoles -join ', ')"
$txt += ""
$txt += "RESOLVED BRANCH  : $branch"
$txt += "RECOMMENDED ACTION: $action"
$txt += ""
$txt += "Note: Beta endpoints change without notice; verify against current Microsoft documentation."
$txtPath = Join-Path $OutputFolder 'CPADMDX-Findings.txt'
$txt -join [Environment]::NewLine | Set-Content -Path $txtPath -Encoding UTF8

Write-Host "== CPADMDX Findings ==" -ForegroundColor Cyan
Write-Host "Resolved branch  : $branch" -ForegroundColor Yellow
Write-Host "Recommended action: $action"
Write-Host ""
Write-Host "Saved: $jsonPath" -ForegroundColor Green
Write-Host "Saved: $txtPath" -ForegroundColor Green
return $summary
