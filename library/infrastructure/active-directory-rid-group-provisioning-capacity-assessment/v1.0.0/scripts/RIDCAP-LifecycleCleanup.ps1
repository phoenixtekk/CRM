<#
.SYNOPSIS
    RIDCAP-LifecycleCleanup.ps1 — Preview the disable/stage/delete of orphaned project groups.
.DESCRIPTION
    PURPOSE
        Drives the lifecycle pipeline for project groups whose project is no longer active:
        disable, then stage (move to a quarantine OU), then delete after a retention window.
        Defaults to preview (-WhatIf) so nothing changes until you explicitly commit.
        Run it against your-domain with an active-projects list to reclaim sprawl safely.
    HOW TO RUN
        Preview (default, safe):
          powershell -ExecutionPolicy Bypass -File .\RIDCAP-LifecycleCleanup.ps1 -ProjectGroupsOU "OU=ProjectGroups,OU=Provisioned,DC=your-domain-dn" -ActiveProjectsFile .\active-projects.txt -Stage Disable
        Commit a stage:
          add -Commit  (removes -WhatIf). Stages: Disable, Stage, Delete.
        Requires the RSAT ActiveDirectory module and write rights on the OU for -Commit.
    EXPECTED RESULTS
        A list of orphaned groups and the action that WOULD run per stage. With -Commit the
        chosen stage is applied. Deletes only touch groups already in the quarantine OU.
.NOTES
    White-label — the repeatable way. Preview-only by default; commit is explicit and staged.
#>

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory = $true)]
    [string]$ProjectGroupsOU,

    [Parameter(Mandatory = $true)]
    [string]$ActiveProjectsFile,

    [ValidateSet('Disable', 'Stage', 'Delete')]
    [string]$Stage = 'Disable',

    # Quarantine OU that staged (pending-delete) groups are moved into.
    [string]$QuarantineOU,

    # Which hyphen-delimited field holds the project id in PRJ-projectid-role.
    [int]$ProjectIdField = 1,

    # Explicit opt-in to make changes. Without it the script previews (forces -WhatIf).
    [switch]$Commit
)

Import-Module ActiveDirectory -ErrorAction Stop

# Safety: unless -Commit is passed, force preview mode so nothing is changed.
if (-not $Commit) {
    $WhatIfPreference = $true
    Write-Host "PREVIEW MODE (no -Commit): no changes will be made." -ForegroundColor Green
} else {
    Write-Host "COMMIT MODE: stage '$Stage' will be APPLIED to orphaned groups." -ForegroundColor Red
}

if (-not (Test-Path $ActiveProjectsFile)) {
    Write-Host "Active-projects file not found: $ActiveProjectsFile" -ForegroundColor Red
    exit 1
}

$activeIds = Get-Content $ActiveProjectsFile | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' }
$activeSet = [System.Collections.Generic.HashSet[string]]::new(
    [string[]]$activeIds, [System.StringComparer]::OrdinalIgnoreCase)

$groups  = Get-ADGroup -SearchBase $ProjectGroupsOU -Filter * -Properties whenCreated
$orphans = $groups | Where-Object {
    $projId = ($_.Name -split '-')[$ProjectIdField]
    -not $activeSet.Contains($projId)
}
$orphanCount = @($orphans).Count

Write-Host ""
Write-Host "=== RIDCAP Lifecycle Cleanup — stage: $Stage ===" -ForegroundColor Cyan
Write-Host "Orphaned project groups (project id not on active list): $orphanCount"
if ($orphanCount -eq 0) {
    Write-Host "Nothing to do." -ForegroundColor Green
    exit 0
}
$orphans | Select-Object Name, whenCreated | Sort-Object whenCreated | Format-Table -AutoSize

foreach ($g in $orphans) {
    switch ($Stage) {

        'Disable' {
            # Disabling a security group has no built-in flag; we mark it via a description/info
            # stamp and (optionally) empty its members later. Here we annotate for the pipeline.
            $mark = "RIDCAP-LIFECYCLE: disabled (pending stage) $(Get-Date -Format yyyy-MM-dd)"
            if ($PSCmdlet.ShouldProcess($g.Name, "Annotate as disabled ('$mark')")) {
                Set-ADGroup -Identity $g.DistinguishedName -Replace @{ info = $mark }
            }
        }

        'Stage' {
            if (-not $QuarantineOU) {
                Write-Host "Stage requires -QuarantineOU (target OU for pending-delete groups)." -ForegroundColor Red
                break
            }
            if ($PSCmdlet.ShouldProcess($g.Name, "Move to quarantine OU '$QuarantineOU'")) {
                Move-ADObject -Identity $g.DistinguishedName -TargetPath $QuarantineOU
            }
        }

        'Delete' {
            # Only delete groups that are already staged in the quarantine OU (defense in depth).
            $inQuarantine = $QuarantineOU -and ($g.DistinguishedName -like "*$QuarantineOU")
            if (-not $inQuarantine) {
                Write-Host "SKIP delete (not in quarantine OU): $($g.Name)" -ForegroundColor Yellow
                continue
            }
            if ($PSCmdlet.ShouldProcess($g.Name, "DELETE group")) {
                Remove-ADGroup -Identity $g.DistinguishedName -Confirm:$false
            }
        }
    }
}

Write-Host ""
if (-not $Commit) {
    Write-Host "Preview complete. Re-run with -Commit to apply stage '$Stage'." -ForegroundColor Green
} else {
    Write-Host "Stage '$Stage' applied to orphaned groups." -ForegroundColor Cyan
}
Write-Host ""
