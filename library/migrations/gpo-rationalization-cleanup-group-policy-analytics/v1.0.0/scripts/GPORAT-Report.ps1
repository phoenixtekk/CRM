<#
.SYNOPSIS
    GPORAT-Report.ps1 — redundancy / conflict + migration-readiness report.
.DESCRIPTION
    PURPOSE
        Reads the GPO XML exports from GPORAT-Discovery.ps1 and reports the cross-cutting cleanup
        targets: (1) DUPLICATED audit settings configured in more than one GPO, (2) CONFLICTING
        settings configured with different values across GPOs, and (3) likely-dead (unlinked) GPOs.
        With -UseGraph it also pulls Intune Group Policy analytics readiness from the
        groupPolicyMigrationReports endpoint so the report carries the authoritative readiness %.
        Read-only.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\GPORAT-Report.ps1 -ExportPath .\GPO-Export
        Add -UseGraph to include Intune Group Policy analytics readiness (requires the
        Microsoft.Graph module and DeviceManagementConfiguration.Read.All).
    EXPECTED RESULTS
        Console tables + CSVs in the export folder: GPORAT-DuplicateAudit.csv, GPORAT-Conflicts.csv,
        GPORAT-DeadGPOs.csv, and — with -UseGraph — GPORAT-AnalyticsReadiness.csv listing each
        Group Policy migration report and its readiness/supported counts.
.NOTES
    Workplace Marketplace — Migrations. Read-only.
#>
[CmdletBinding()]
param(
    [string] $ExportPath = ".\GPO-Export",
    [switch] $UseGraph
)

Write-Host "`n=== Redundancy / conflict + readiness report ===" -ForegroundColor Cyan
if (-not (Test-Path $ExportPath)) { Write-Host "Export path not found: $ExportPath. Run GPORAT-Discovery.ps1 first." -ForegroundColor Yellow; return }

$files = Get-ChildItem -Path $ExportPath -Filter *.xml -ErrorAction SilentlyContinue
if (-not $files) { Write-Host "No GPO XML exports found in $ExportPath." -ForegroundColor Yellow; return }

# Collect (GPO, settingName, value) tuples and audit settings across all exports.
$settings = New-Object System.Collections.Generic.List[object]
$audit    = New-Object System.Collections.Generic.List[object]
$dead     = New-Object System.Collections.Generic.List[object]

foreach ($f in $files) {
    try {
        [xml]$gpo = Get-Content $f.FullName -Raw
        if (@($gpo.GPO.LinksTo).Count -eq 0) { $dead.Add([pscustomobject]@{ Gpo = $f.BaseName; Note = 'Unlinked — retire candidate' }) }

        $exts = @($gpo.GPO.Computer.ExtensionData.Extension) + @($gpo.GPO.User.ExtensionData.Extension) | Where-Object { $_ }

        # ADMX-backed policy settings: name + state/value for conflict detection.
        foreach ($p in (@($exts.Policy) | Where-Object { $_ })) {
            $val = if ($p.State) { $p.State } elseif ($p.Value) { ($p.Value | Out-String).Trim() } else { '(set)' }
            $settings.Add([pscustomobject]@{ Gpo = $f.BaseName; Setting = $p.Name; Value = $val })
        }

        # Audit settings (advanced audit policy + legacy audit) for redundancy detection.
        foreach ($a in (@($exts.AuditSetting) | Where-Object { $_ })) {
            $name = if ($a.SubcategoryName) { $a.SubcategoryName } else { $a.PolicyTarget }
            $audit.Add([pscustomobject]@{ Gpo = $f.BaseName; AuditSetting = $name; Value = $a.SettingValue })
        }
    } catch {
        Write-Host ("  Could not parse {0}: {1}" -f $f.Name, $_.Exception.Message) -ForegroundColor Yellow
    }
}

# 1) Duplicated audit settings (same audit subcategory set in >1 GPO).
$dupAudit = $audit | Group-Object AuditSetting | Where-Object { ($_.Group | Select-Object -ExpandProperty Gpo -Unique).Count -gt 1 } |
    ForEach-Object {
        [pscustomobject]@{ AuditSetting = $_.Name; GPOs = (($_.Group.Gpo | Sort-Object -Unique) -join '; '); Count = ($_.Group.Gpo | Sort-Object -Unique).Count }
    }
Write-Host "`n--- Duplicated audit settings ---" -ForegroundColor Cyan
if ($dupAudit) { $dupAudit | Format-Table -AutoSize } else { Write-Host "  None found." -ForegroundColor Green }
$dupAudit | Export-Csv -Path (Join-Path $ExportPath 'GPORAT-DuplicateAudit.csv') -NoTypeInformation -Encoding UTF8

# 2) Conflicting settings (same setting name, different values across GPOs).
$conflicts = $settings | Group-Object Setting | Where-Object { (($_.Group.Value | Sort-Object -Unique)).Count -gt 1 } |
    ForEach-Object {
        [pscustomobject]@{ Setting = $_.Name; DistinctValues = (($_.Group.Value | Sort-Object -Unique) -join ' | '); GPOs = (($_.Group.Gpo | Sort-Object -Unique) -join '; ') }
    }
Write-Host "`n--- Conflicting settings (different values across GPOs) ---" -ForegroundColor Cyan
if ($conflicts) { $conflicts | Format-Table -AutoSize } else { Write-Host "  None found." -ForegroundColor Green }
$conflicts | Export-Csv -Path (Join-Path $ExportPath 'GPORAT-Conflicts.csv') -NoTypeInformation -Encoding UTF8

# 3) Dead (unlinked) GPOs.
Write-Host "`n--- Unlinked (dead) GPOs ---" -ForegroundColor Cyan
if ($dead.Count) { $dead | Format-Table -AutoSize } else { Write-Host "  None found." -ForegroundColor Green }
$dead | Export-Csv -Path (Join-Path $ExportPath 'GPORAT-DeadGPOs.csv') -NoTypeInformation -Encoding UTF8

Write-Host ("`nSaved: GPORAT-DuplicateAudit.csv, GPORAT-Conflicts.csv, GPORAT-DeadGPOs.csv in {0}" -f $ExportPath) -ForegroundColor Green
Write-Host "These are local heuristics; the authoritative readiness % is Intune Group Policy analytics (use -UseGraph)." -ForegroundColor Gray

if ($UseGraph) {
    Write-Host "`n=== Intune Group Policy analytics readiness (Graph) ===" -ForegroundColor Cyan
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    Connect-MgGraph -Scopes 'DeviceManagementConfiguration.Read.All' -NoWelcome
    try {
        $reports = (Invoke-MgGraphRequest -Method GET -Uri "/beta/deviceManagement/groupPolicyMigrationReports").value
        if ($reports) {
            $rrows = foreach ($r in $reports) {
                [pscustomobject]@{
                    GpoName            = $r.displayName
                    OuDistinguishedName= $r.ouDistinguishedName
                    TotalSettings      = $r.totalSettingsCount
                    SupportedSettings  = $r.supportedSettingsCount
                    ReadinessPct       = if ($r.totalSettingsCount) { [math]::Round(($r.supportedSettingsCount / $r.totalSettingsCount) * 100, 0) } else { 0 }
                    MigrationReadiness = $r.migrationReadiness
                    CreatedDateTime    = $r.createdDateTime
                }
            }
            $rrows | Sort-Object ReadinessPct | Format-Table GpoName, TotalSettings, SupportedSettings, ReadinessPct -AutoSize
            $rrows | Export-Csv -Path (Join-Path $ExportPath 'GPORAT-AnalyticsReadiness.csv') -NoTypeInformation -Encoding UTF8
            Write-Host ("Saved: GPORAT-AnalyticsReadiness.csv ({0} reports)." -f @($rrows).Count) -ForegroundColor Green
        } else {
            Write-Host "  No Group Policy migration reports found. Import GPOs in Intune > Reports > Group Policy analytics first." -ForegroundColor Yellow
        }
    } catch {
        Write-Host ("  Could not read groupPolicyMigrationReports: {0}" -f $_.Exception.Message) -ForegroundColor Yellow
    }
    Disconnect-MgGraph | Out-Null
}
