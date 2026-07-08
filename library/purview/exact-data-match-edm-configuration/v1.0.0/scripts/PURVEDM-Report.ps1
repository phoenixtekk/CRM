<#
.SYNOPSIS
    PURVEDM-Report.ps1 — EDM inventory & data-store health report (READ-ONLY).
.DESCRIPTION
    PURPOSE
        Produces a consolidated EDM report: every EDM schema (data store) and its fields, the EDM
        sensitive information types, which DLP policies reference each EDM SIT, and — when an
        EdmUploadAgent.exe path is supplied — the data store's row-count / last-upload status via the
        Agent's read-only /GetDataStore switch. Read-only: it reports state and changes nothing, and it
        reads no sensitive record data (the Agent reports hash/store metadata only).
    HOW TO RUN
        # Inventory + policy references (S&C PowerShell only):
        powershell -File .\PURVEDM-Report.ps1
        # Also query data-store health via the Upload Agent:
        powershell -File .\PURVEDM-Report.ps1 -EdmAgentPath 'C:\Program Files\EdmUploadAgent\EdmUploadAgent.exe' -DataStoreName CustomerRecords
        # Export to CSV:
        powershell -File .\PURVEDM-Report.ps1 -CsvPath .\edm-report.csv
        Requires Security & Compliance PowerShell (Connect-IPPSSession). Agent switches vary by version/cloud.
    EXPECTED RESULTS
        Tables of schemas, EDM SITs, and referencing DLP policies. With -EdmAgentPath, prints the Agent's
        /GetDataStore output (expected row count + recent upload timestamp = healthy). Stale/absent
        upload timestamp = ATTENTION (refresh the data — see Best Practices).
.NOTES
    Purview — Exact Data Match. Read-only. No credentials, salts, or record data in code.
#>
[CmdletBinding()]
param(
    [string]$EdmAgentPath,
    [string]$DataStoreName,
    [string]$CsvPath,
    [string]$UserPrincipalName
)

function Write-Head($t) { Write-Host ("`n=== {0} ===" -f $t) -ForegroundColor Cyan }

if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) { Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force -AllowClobber }
Import-Module ExchangeOnlineManagement -ErrorAction Stop
if (-not (Get-Command Get-DlpEdmSchema -ErrorAction SilentlyContinue)) {
    if ($UserPrincipalName) { Connect-IPPSSession -UserPrincipalName $UserPrincipalName } else { Connect-IPPSSession }
}

# --- Schemas ---
Write-Head 'EDM schemas (data stores)'
$schemas = @(); try { $schemas = @(Get-DlpEdmSchema -ErrorAction Stop) } catch { Write-Host ("Read error: {0}" -f $_.Exception.Message) -ForegroundColor Yellow }
if ($schemas.Count -eq 0) { Write-Host 'None found.' }
foreach ($s in $schemas) {
    $fnames = @(); try { $fnames = @($s.Field | ForEach-Object { $_.name }) } catch {}
    Write-Host ("- {0}  fields: {1}" -f $s.Name, ($(if ($fnames) { $fnames -join ', ' } else { 'n/a' })))
}

# --- EDM SITs ---
Write-Head 'EDM sensitive information types'
$allSits = @(); try { $allSits = @(Get-DlpSensitiveInformationType -ErrorAction Stop) } catch {}
$edmSits = @($allSits | Where-Object { $_.Publisher -match 'EDM' -or $_.Name -match 'EDM' -or $_.RulePackType -match 'EDM' })
if ($edmSits.Count -eq 0) { Write-Host 'None detected.' } else { $edmSits | ForEach-Object { Write-Host ("- {0}" -f $_.Name) } }

# --- DLP policies referencing each EDM SIT ---
Write-Head 'DLP policies referencing EDM SITs'
$rows = @()
$rules = @(); try { $rules = @(Get-DlpComplianceRule -ErrorAction Stop) } catch { Write-Host ("Could not read DLP rules: {0}" -f $_.Exception.Message) -ForegroundColor Yellow }
foreach ($sit in $edmSits) {
    $refRules = @($rules | Where-Object {
        $blob = ''
        try { $blob = ($_.ContentContainsSensitiveInformation | Out-String) } catch {}
        $blob -match [regex]::Escape($sit.Name)
    })
    if ($refRules.Count -eq 0) {
        Write-Host ("- {0}: not referenced by any DLP rule yet." -f $sit.Name) -ForegroundColor DarkGray
        $rows += [pscustomobject]@{ EdmSit = $sit.Name; Policy = ''; Rule = ''; Mode = '' }
    } else {
        foreach ($r in $refRules) {
            $pol = $r.ParentPolicyName; $mode = ''
            try { $mode = (Get-DlpCompliancePolicy -Identity $pol -ErrorAction SilentlyContinue).Mode } catch {}
            Write-Host ("- {0}: policy '{1}' / rule '{2}' (Mode={3})" -f $sit.Name, $pol, $r.Name, $mode)
            $rows += [pscustomobject]@{ EdmSit = $sit.Name; Policy = $pol; Rule = $r.Name; Mode = $mode }
        }
    }
}

# --- Data store health via the Upload Agent (optional, read-only) ---
if ($EdmAgentPath) {
    Write-Head 'Data store health (EdmUploadAgent.exe /GetDataStore)'
    if (-not (Test-Path $EdmAgentPath)) {
        Write-Host ("Agent not found at {0}." -f $EdmAgentPath) -ForegroundColor Yellow
    } else {
        try {
            $args = @('/GetDataStore')
            if ($DataStoreName) { $args = @('/GetDataStore','/DataStoreName', $DataStoreName) }
            Write-Host ("Running: {0} {1}" -f $EdmAgentPath, ($args -join ' ')) -ForegroundColor DarkGray
            & $EdmAgentPath @args
            Write-Host 'Interpret: a recent upload timestamp + expected row count = healthy; missing/old = refresh the data (Best Practices).' -ForegroundColor DarkGray
        } catch {
            Write-Host ("Agent call failed: {0}. Confirm switches with 'EdmUploadAgent.exe /?'." -f $_.Exception.Message) -ForegroundColor Yellow
        }
    }
} else {
    Write-Host "`n(Data-store health check skipped — pass -EdmAgentPath to include it.)" -ForegroundColor DarkGray
}

if ($CsvPath -and $rows.Count -gt 0) { $rows | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8; Write-Host ("`nExported policy references to {0}" -f $CsvPath) -ForegroundColor Green }

Write-Head 'Summary'
Write-Host ("Schemas: {0} | EDM SITs: {1} | Policy references: {2}" -f $schemas.Count, $edmSits.Count, (@($rows | Where-Object { $_.Policy }).Count))
