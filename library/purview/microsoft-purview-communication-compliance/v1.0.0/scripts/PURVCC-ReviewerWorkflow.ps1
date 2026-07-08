<#
.SYNOPSIS
    PURVCC-ReviewerWorkflow.ps1 — reviewer-workflow / remediation setup helper: set policy reviewers and enforce role separation (-WhatIf by default).
.DESCRIPTION
    PURPOSE
        Wires the reviewer workflow for a Communication Compliance policy: sets the policy's
        reviewers, and populates the Communication Compliance role groups (Analysts /
        Investigators / Viewers) so that content-reviewers and escalation-investigators are the
        agreed HR/compliance people and are SEPARATED from the policy-builders (Admin). Safe by
        default: with no switch it runs -WhatIf and only DESCRIBES the change; supply -Commit to
        apply, after HR/legal sign-off. Reviewer triage and remediation ACTIONS (resolve, tag,
        notify, escalate, create case) are performed by reviewers in the Purview portal — this
        helper sets up who can do them, not the per-alert verdict.
    HOW TO RUN
        # Dry-run (default):
        powershell -ExecutionPolicy Bypass -File .\PURVCC-ReviewerWorkflow.ps1 `
            -PolicyName 'Comms Policy - Pilot - Simulation' `
            -Reviewers 'analyst1@contoso.com','analyst2@contoso.com' `
            -Analysts 'analyst1@contoso.com','analyst2@contoso.com' `
            -Investigators 'investigator1@contoso.com' -Viewers 'oversight1@contoso.com'
        # Apply (after sign-off):
        ... same parameters ... -Commit
        Requires ExchangeOnlineManagement; connects with Connect-IPPSSession.
    EXPECTED RESULTS
        Dry-run prints the reviewer set and role-group membership changes it would make, plus a
        separation check. With -Commit, reviewers are set on the policy and members are added to
        the named role groups. Verify with PURVCC-Discovery.ps1 (separation snapshot).
.NOTES
    Purview — Microsoft Purview Communication Compliance. -WhatIf by default; -Commit required. No
    credentials stored. Remediation outcomes are an HR/legal determination — this configures the
    workflow, not the verdict.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$PolicyName,
    [string[]]$Reviewers = @(),           # reviewers assigned to THIS policy
    [string[]]$Analysts = @(),            # -> 'Communication Compliance Analysts'
    [string[]]$Investigators = @(),       # -> 'Communication Compliance Investigators'
    [string[]]$Viewers = @(),             # -> 'Communication Compliance Viewers'
    [switch]$Commit
)

$whatIf = -not $Commit
$mode = if ($whatIf) { 'WHATIF (dry-run)' } else { 'COMMIT' }
Write-Host ("=== PURVCC-ReviewerWorkflow : {0} ===" -f $mode) -ForegroundColor Cyan

if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force -AllowClobber
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop
try { Connect-IPPSSession -ErrorAction Stop -WarningAction SilentlyContinue | Out-Null }
catch { Write-Error "Connect-IPPSSession failed: $($_.Exception.Message)."; return }

# --- Separation pre-check: reviewers/analysts/investigators must not also be policy-builders ---
$builders = @()
$adminMembers = Get-RoleGroupMember -Identity 'Communication Compliance Admin' -ErrorAction SilentlyContinue
if ($adminMembers) { $builders = @($adminMembers | ForEach-Object { "$($_.PrimarySmtpAddress)" } | Where-Object { $_ }) }
$proposedReviewers = @($Reviewers + $Analysts + $Investigators | Select-Object -Unique)
$conflict = $proposedReviewers | Where-Object { $builders -contains $_ }
if ($conflict) {
    Write-Host '  [SEPARATION WARNING] Proposed reviewers/investigators are also policy-builders (Admin):' -ForegroundColor Red
    $conflict | ForEach-Object { Write-Host ("    - {0}" -f $_) -ForegroundColor Red }
    Write-Host '    Resolve or obtain explicit HR/legal acceptance before committing.' -ForegroundColor Red
} else {
    Write-Host '  [OK] No builder/reviewer overlap in the proposed assignment.' -ForegroundColor Green
}

# --- Plan the role-group additions ---
$plan = @(
    @{ Group = 'Communication Compliance Analysts';      Members = $Analysts },
    @{ Group = 'Communication Compliance Investigators'; Members = $Investigators },
    @{ Group = 'Communication Compliance Viewers';       Members = $Viewers }
)

Write-Host ''
Write-Host ("Policy reviewers to set on '{0}': {1}" -f $PolicyName, (($Reviewers -join ', ') -replace '^$','(unchanged)'))
foreach ($p in $plan) {
    if ($p.Members.Count) { Write-Host ("Add to {0}: {1}" -f $p.Group, ($p.Members -join ', ')) }
}

if ($whatIf) {
    Write-Host ''
    Write-Host 'PLANNED ACTIONS (nothing is being changed):' -ForegroundColor Yellow
    if ($Reviewers.Count) {
        Write-Host ("  Set-SupervisoryReviewPolicyV2 -Identity '{0}' -Reviewers {1}" -f `
            $PolicyName, (($Reviewers | ForEach-Object { "'$_'" }) -join ','))
    }
    foreach ($p in $plan) {
        foreach ($m in $p.Members) {
            Write-Host ("  Add-RoleGroupMember -Identity '{0}' -Member '{1}'" -f $p.Group, $m)
        }
    }
    Write-Host ''
    Write-Host 'Reviewers will triage and remediate alerts in the Purview portal (resolve / tag / notify / escalate / create case).' -ForegroundColor DarkGray
    Write-Host 'Re-run with -Commit (after HR/legal sign-off) to apply.' -ForegroundColor Yellow
    return
}

# --- COMMIT ---
try {
    if ($Reviewers.Count) {
        Set-SupervisoryReviewPolicyV2 -Identity $PolicyName -Reviewers $Reviewers -ErrorAction Stop
        Write-Host ("  Reviewers set on '{0}'." -f $PolicyName) -ForegroundColor Green
    }
    foreach ($p in $plan) {
        foreach ($m in $p.Members) {
            try {
                Add-RoleGroupMember -Identity $p.Group -Member $m -Confirm:$false -ErrorAction Stop
                Write-Host ("  Added {0} to {1}." -f $m, $p.Group) -ForegroundColor Green
            } catch {
                Write-Warning ("  Could not add {0} to {1}: {2}" -f $m, $p.Group, $_.Exception.Message)
            }
        }
    }
    Write-Host 'Reviewer workflow configured. Verify separation with PURVCC-Discovery.ps1 and test end-to-end (Testing Guide Tests 7-8).' -ForegroundColor Cyan
} catch {
    Write-Error "Commit failed: $($_.Exception.Message)."
}
