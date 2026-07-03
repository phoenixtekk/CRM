<#
.SYNOPSIS
    COPILOTG-Set-ScopeTargeting.ps1 — Build/populate Copilot pilot & wave groups on GCC High (WhatIf-by-default).
.DESCRIPTION
    PURPOSE
        Creates and populates the staged-rollout Entra security groups (SG-COPILOTG-Pilot,
        SG-COPILOTG-Wave2) used to scope Microsoft 365 Copilot licensing on a GCC High tenant. Runs
        in preview (-WhatIf) by DEFAULT and changes nothing until you pass -Apply. Provide members
        via a CSV of UPNs — replace the sample path with your own, plain text like 'your-members.csv'.
    HOW TO RUN
        Preview (default, no changes):
          powershell -ExecutionPolicy Bypass -File .\COPILOTG-Set-ScopeTargeting.ps1 -GroupName 'SG-COPILOTG-Pilot' -MembersCsv .\pilot-members.csv
        Apply (deliberate):
          powershell -ExecutionPolicy Bypass -File .\COPILOTG-Set-ScopeTargeting.ps1 -GroupName 'SG-COPILOTG-Pilot' -MembersCsv .\pilot-members.csv -Apply
        (Graph scopes: Group.ReadWrite.All, User.Read.All for apply; connects with -Environment USGov.)
    EXPECTED RESULTS
        In preview: the group + membership that WOULD be created, no changes. On -Apply: the group is
        created/updated. PASS = preview matches intent, apply completes; FAIL = not on USGov (see
        Troubleshooting T1) or insufficient rights.
.NOTES
    White-label — the repeatable way. Read-only by default against Microsoft Graph US Gov endpoints; writes only with -Apply.
#>

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [switch] $Apply,
    [Parameter(Mandatory = $true)][string] $GroupName,   # e.g. SG-COPILOTG-Pilot or SG-COPILOTG-Wave2
    [string] $MembersCsv,                                 # CSV with a UserPrincipalName column
    [string] $MailNickname
)

$ErrorActionPreference = 'Stop'
if (-not $Apply) { $WhatIfPreference = $true }
if (-not $MailNickname) { $MailNickname = ($GroupName -replace '[^A-Za-z0-9]','') }

$RequiredScopes = if ($Apply) { @('Group.ReadWrite.All','User.Read.All') } else { @('Group.Read.All','User.Read.All') }

try {
    Connect-MgGraph -Environment USGov -Scopes $RequiredScopes | Out-Null
    $ctx = Get-MgContext
    if ($ctx.Environment -ne 'USGov') { throw "Not on USGov (Environment=$($ctx.Environment)). GCC High requires -Environment USGov. See Troubleshooting T1." }

    if ($Apply) { Write-Host 'MODE: APPLY — the group WILL be created/updated.' -ForegroundColor Yellow }
    else        { Write-Host 'MODE: PREVIEW (-WhatIf) — no changes. Re-run with -Apply after review.' -ForegroundColor Cyan }

    # --- Resolve or plan the group ---
    $group = Get-MgGroup -Filter "displayName eq '$GroupName'" -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $group) {
        if ($PSCmdlet.ShouldProcess($GroupName, 'Create security group')) {
            $group = New-MgGroup -DisplayName $GroupName -MailEnabled:$false -MailNickname $MailNickname `
                                 -SecurityEnabled:$true -GroupTypes @()
            Write-Host "  CREATED group '$GroupName' ($($group.Id))" -ForegroundColor Green
        } else {
            Write-Host "  WOULD CREATE security group '$GroupName' (mailNickname: $MailNickname)" -ForegroundColor Cyan
        }
    } else {
        Write-Host "  Group '$GroupName' already exists ($($group.Id))" -ForegroundColor Green
    }

    # --- Members ---
    if ($MembersCsv) {
        if (-not (Test-Path $MembersCsv)) { throw "MembersCsv not found: $MembersCsv" }
        $rows = Import-Csv -Path $MembersCsv
        if (-not ($rows | Get-Member -Name UserPrincipalName -ErrorAction SilentlyContinue)) {
            throw "MembersCsv must contain a 'UserPrincipalName' column."
        }
        Write-Host ("Processing {0} member(s) for '{1}'..." -f ($rows|Measure-Object).Count, $GroupName) -ForegroundColor Cyan
        foreach ($r in $rows) {
            $upn = $r.UserPrincipalName
            $user = Get-MgUser -Filter "userPrincipalName eq '$upn'" -ErrorAction SilentlyContinue | Select-Object -First 1
            if (-not $user) { Write-Host "  SKIP (not found): $upn" -ForegroundColor Yellow; continue }
            if ($PSCmdlet.ShouldProcess($upn, "Add to group '$GroupName'")) {
                if ($group -and $group.Id) {
                    New-MgGroupMember -GroupId $group.Id -DirectoryObjectId $user.Id -ErrorAction SilentlyContinue
                    Write-Host "  ADDED: $upn" -ForegroundColor Green
                }
            } else {
                Write-Host "  WOULD ADD: $upn" -ForegroundColor Cyan
            }
        }
    } else {
        Write-Host 'No -MembersCsv provided; group membership unchanged (create-only plan).' -ForegroundColor Cyan
    }

    Write-Host ''
    if ($Apply) {
        Write-Host "Done. Assign the Microsoft 365 Copilot add-on to '$GroupName' via group-based licensing (entra.microsoft.us)." -ForegroundColor Green
    } else {
        Write-Host "Preview complete. Re-run with -Apply after review, then license '$GroupName' (Implementation 2.2)." -ForegroundColor Yellow
    }
}
catch {
    Write-Error "Set-ScopeTargeting failed: $($_.Exception.Message)"
    exit 1
}
finally {
    Disconnect-MgGraph -ErrorAction SilentlyContinue | Out-Null
}
