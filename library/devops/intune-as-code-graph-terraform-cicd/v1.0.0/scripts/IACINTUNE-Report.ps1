<#
.SYNOPSIS
    IACINTUNE-Report.ps1 — backup, restore (dry-run), and drift report for the Intune-as-code tenant.
.DESCRIPTION
    PURPOSE
        The rollback and drift toolkit for the "Intune-as-Code" solution:
          -Backup      Export all managed policy types to a timestamped JSON backup (the rollback point).
          -Restore     DRY-RUN by default — reports what a restore from a backup folder WOULD recreate.
          -DriftCheck  Run `terraform plan` with no code change; a non-empty plan means drift (a portal
                       edit made outside the pipeline).
        Backup and DriftCheck are read-only against the tenant. Restore is a safe preview unless you
        explicitly pass -Apply (gated).
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\IACINTUNE-Report.ps1 -Backup   -OutputPath .\backups
        powershell -ExecutionPolicy Bypass -File .\IACINTUNE-Report.ps1 -DriftCheck -TerraformDir ..
        powershell -ExecutionPolicy Bypass -File .\IACINTUNE-Report.ps1 -Restore   -BackupFolder .\backups\2026-07-09
        Requires the Microsoft.Graph module and (for -DriftCheck) the Terraform CLI.
        *Verify current module / provider versions and whether an endpoint is /beta.*
    EXPECTED RESULTS
        A timestamped backup, a drift verdict, or a restore preview — no unintended changes.
.NOTES
    White-label. Backup/DriftCheck are read-only. Restore defaults to a safe DRY-RUN; -Apply is gated.
#>
[CmdletBinding(DefaultParameterSetName = 'Backup')]
param(
    [Parameter(ParameterSetName='Backup')]   [switch]$Backup,
    [Parameter(ParameterSetName='Drift')]    [switch]$DriftCheck,
    [Parameter(ParameterSetName='Restore')]  [switch]$Restore,
    [string]$OutputPath = ".\backups",
    [string]$BackupFolder,
    [string]$TerraformDir = "..",
    [switch]$Apply   # only meaningful with -Restore; gated, off by default
)

$ErrorActionPreference = 'Continue'
Import-Module Microsoft.Graph.Authentication -ErrorAction SilentlyContinue

$endpoints = @(
    @{ Name='device-configuration';    Uri='https://graph.microsoft.com/v1.0/deviceManagement/deviceConfigurations' }
    @{ Name='compliance';              Uri='https://graph.microsoft.com/v1.0/deviceManagement/deviceCompliancePolicies' }
    @{ Name='app-protection-ios';      Uri='https://graph.microsoft.com/beta/deviceAppManagement/iosManagedAppProtections' }   # *verify*
    @{ Name='app-protection-android';  Uri='https://graph.microsoft.com/beta/deviceAppManagement/androidManagedAppProtections' } # *verify*
)

function Connect-Graph {
    if (-not (Get-MgContext)) {
        Connect-MgGraph -Scopes 'DeviceManagementConfiguration.Read.All','DeviceManagementApps.Read.All' | Out-Null
    }
}

if ($Backup) {
    Connect-Graph
    $stamp = Get-Date -Format 'yyyy-MM-dd_HHmmss'
    $dir = Join-Path $OutputPath $stamp
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
    foreach ($e in $endpoints) {
        try {
            $items = (Invoke-MgGraphRequest -Method GET -Uri $e.Uri).value
            $items | ConvertTo-Json -Depth 20 | Out-File (Join-Path $dir "$($e.Name).json") -Encoding utf8
            Write-Host ("Backed up {0,-22}: {1,4} item(s)" -f $e.Name, @($items).Count) -ForegroundColor Green
        } catch { Write-Warning ("Backup failed for {0}: {1}" -f $e.Name, $_.Exception.Message) }
    }
    Write-Host "`nBackup written to $dir (this is your restore point)." -ForegroundColor Cyan
}
elseif ($DriftCheck) {
    Push-Location $TerraformDir
    terraform init -input=false | Out-Null
    Write-Host "Running drift check (terraform plan, no code change)..." -ForegroundColor Cyan
    terraform plan -no-color -detailed-exitcode | Out-Host
    $code = $LASTEXITCODE
    Pop-Location
    switch ($code) {
        0 { Write-Host "NO DRIFT — tenant matches code." -ForegroundColor Green }
        2 { Write-Host "DRIFT DETECTED — a change exists outside the pipeline. Reconcile or revert." -ForegroundColor Yellow }
        default { Write-Host "Plan error (exit $code) — check state/backend." -ForegroundColor Red }
    }
}
elseif ($Restore) {
    if (-not $BackupFolder -or -not (Test-Path $BackupFolder)) {
        Write-Error "Provide -BackupFolder pointing to a valid backup directory."; return
    }
    Write-Host "Restore preview from $BackupFolder (DRY-RUN$(if($Apply){' — APPLY REQUESTED'})):" -ForegroundColor Cyan
    Get-ChildItem -Path $BackupFolder -Filter *.json | ForEach-Object {
        $items = Get-Content $_.FullName -Raw | ConvertFrom-Json
        Write-Host ("  Would restore {0,-24}: {1,4} policy object(s)" -f $_.BaseName, @($items).Count)
    }
    if ($Apply) {
        Write-Warning "Actual restore-apply is intentionally gated. Restore via a reviewed Terraform apply or an approved Graph write, not ad-hoc — see the Troubleshooting guide."
    } else {
        Write-Host "`nDry-run only. Re-run with -Apply (gated) to proceed via the reviewed path." -ForegroundColor Green
    }
}
