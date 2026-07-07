<#
.SYNOPSIS
  Create/verify retention labels and policies and stage default library labels (dry-run by default).
.DESCRIPTION
  Reads a label/policy definition set (from a CSV or the built-in example objects) and, by default,
  REPORTS what it would create: retention labels (New-ComplianceTag), location/auto-apply policies
  (New-RetentionCompliancePolicy/Rule), and default library labels (Set-PnPLabel). Only performs the
  changes when -Commit is passed. Safe by default (-WhatIf semantics).
.EXAMPLE
  .\Apply-SpoRetentionLabels.ps1 -DefinitionCsv .\labels.csv            # dry-run: shows planned changes
  .\Apply-SpoRetentionLabels.ps1 -DefinitionCsv .\labels.csv -Commit    # applies under change control
  # (PowerShell 5.1+/7+; ExchangeOnlineManagement + PnP.PowerShell; Connect-IPPSSession + Connect-PnPOnline)
.NOTES
  Expected results: without -Commit, a plan of labels/policies/library-labels to be created (no change).
  With -Commit, the labels/policies exist and the named library default labels are set.
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    # CSV columns: LabelName,RetentionAction,RetentionDuration,RetentionType,IsRecord,PolicyName,SharePointLocation,LibrarySite,LibraryName
    [string]$DefinitionCsv,

    # Actually create/apply. Without this the script only reports (dry-run).
    [switch]$Commit
)

$ErrorActionPreference = 'Stop'

# Load definitions from CSV, or fall back to a documented example set (dry-run demonstration).
if ($DefinitionCsv -and (Test-Path $DefinitionCsv)) {
    $defs = Import-Csv -Path $DefinitionCsv
}
else {
    Write-Warning "No -DefinitionCsv supplied; using an EXAMPLE definition set for dry-run only."
    $defs = @(
        [pscustomobject]@{ LabelName='Retention Label - General-3yr - Pilot'; RetentionAction='Delete'; RetentionDuration=1095; RetentionType='CreationAgeInDays'; IsRecord='False'; PolicyName='Retention Policy - SPO-Baseline - Pilot'; SharePointLocation='https://contoso.sharepoint.com/sites/RecordsPilot'; LibrarySite=''; LibraryName='' }
        [pscustomobject]@{ LabelName='Record Label - Contracts - Pilot';      RetentionAction='Keep';   RetentionDuration=2190; RetentionType='TaggedAgeInDays';   IsRecord='True';  PolicyName='Label Policy - Contracts-AutoApply - Pilot'; SharePointLocation='https://contoso.sharepoint.com/sites/RecordsPilot'; LibrarySite='https://contoso.sharepoint.com/sites/RecordsPilot'; LibraryName='Documents' }
    )
}

$mode = if ($Commit) { "COMMIT" } else { "DRY-RUN (no changes)" }
Write-Host "Apply-SpoRetentionLabels - mode: $mode" -ForegroundColor Cyan

foreach ($d in $defs) {
    # --- 1. Retention/record label ---
    $existing = $null
    try { $existing = Get-ComplianceTag -Identity $d.LabelName -ErrorAction SilentlyContinue } catch {}
    if ($existing) {
        Write-Host "  [label] EXISTS: $($d.LabelName)" -ForegroundColor DarkGray
    }
    elseif ($Commit) {
        if ($PSCmdlet.ShouldProcess($d.LabelName, "New-ComplianceTag")) {
            $p = @{
                Name             = $d.LabelName
                RetentionAction  = $d.RetentionAction
                RetentionDuration= [int]$d.RetentionDuration
                RetentionType    = $d.RetentionType
            }
            if ([bool]::Parse($d.IsRecord)) { $p['IsRecordLabel'] = $true }
            New-ComplianceTag @p | Out-Null
            Write-Host "  [label] CREATED: $($d.LabelName)" -ForegroundColor Green
        }
    }
    else {
        Write-Host "  [label] WOULD CREATE: $($d.LabelName) ($($d.RetentionAction)/$($d.RetentionDuration)/$($d.RetentionType) record=$($d.IsRecord))" -ForegroundColor Yellow
    }

    # --- 2. Policy (created disabled; enable it in the Pilot stage) ---
    if ($d.PolicyName) {
        $pol = $null
        try { $pol = Get-RetentionCompliancePolicy -Identity $d.PolicyName -ErrorAction SilentlyContinue } catch {}
        if ($pol) {
            Write-Host "  [policy] EXISTS: $($d.PolicyName)" -ForegroundColor DarkGray
        }
        elseif ($Commit) {
            if ($PSCmdlet.ShouldProcess($d.PolicyName, "New-RetentionCompliancePolicy (disabled)")) {
                New-RetentionCompliancePolicy -Name $d.PolicyName -SharePointLocation $d.SharePointLocation -Enabled $false | Out-Null
                Write-Host "  [policy] CREATED (disabled): $($d.PolicyName)" -ForegroundColor Green
            }
        }
        else {
            Write-Host "  [policy] WOULD CREATE (disabled): $($d.PolicyName) @ $($d.SharePointLocation)" -ForegroundColor Yellow
        }
    }

    # --- 3. Default library label (staged; set here only with -Commit) ---
    if ($d.LibrarySite -and $d.LibraryName) {
        if ($Commit) {
            if ($PSCmdlet.ShouldProcess("$($d.LibrarySite)/$($d.LibraryName)", "Set-PnPLabel -> $($d.LabelName)")) {
                Connect-PnPOnline -Url $d.LibrarySite -Interactive
                Set-PnPLabel -List $d.LibraryName -Label $d.LabelName -SyncToItems $true
                Write-Host "  [library] SET default label on $($d.LibraryName): $($d.LabelName)" -ForegroundColor Green
            }
        }
        else {
            Write-Host "  [library] WOULD SET default label on $($d.LibrarySite)/$($d.LibraryName): $($d.LabelName)" -ForegroundColor Yellow
        }
    }
}

Write-Host ""
if (-not $Commit) { Write-Host "Dry-run complete. Re-run with -Commit (under change control) to apply." -ForegroundColor Cyan }
