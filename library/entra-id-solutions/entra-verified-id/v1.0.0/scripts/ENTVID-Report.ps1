<#
.SYNOPSIS
    ENTVID-Report.ps1 — Verified ID governance report: credential types and issuance/revocation activity.
.DESCRIPTION
    PURPOSE
        Produces a governance report for Verified ID: the onboarded issuer authority, the published
        credential types (contracts), and — where the tenant exposes it — issuance/revocation signals from
        the Entra audit log (VerifiableCredential / Verified ID category). Read-only — it changes nothing.
        Optionally writes a CSV of the audit rows. Reporting depth depends on what your tenant logs and
        the admin API surface available, both of which are VERIFY-flagged.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\ENTVID-Report.ps1 -Days 30 -CsvPath .\entvid-report.csv
        Connects to Microsoft Graph read scopes: AuditLog.Read.All and (best effort)
        VerifiableCredential.Authority.Read.All (VERIFY the current scope for your tenant).
    EXPECTED RESULTS
        The issuer authority + credential types, and a table of recent Verified ID audit events (issuance,
        revocation, config changes) over the last N days where available. Read-only.
.NOTES
    White-label. Read-only. Verified ID admin API/scopes and audit categories are VERIFY-flagged.
#>
[CmdletBinding()]
param(
    [int]$Days = 30,
    [string]$CsvPath
)

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
try { Connect-MgGraph -Scopes 'AuditLog.Read.All','VerifiableCredential.Authority.Read.All' -NoWelcome }
catch { Write-Host "Verified ID read scope not consentable — VERIFY for your tenant. Continuing with AuditLog.Read.All only." -ForegroundColor Yellow; Connect-MgGraph -Scopes 'AuditLog.Read.All' -NoWelcome }

Write-Host "`n=== ENTVID — governance report (last $Days days) ===" -ForegroundColor Cyan

# 1) Issuer authority + credential types (best effort)
try {
    $auths = @((Invoke-MgGraphRequest -Method GET -Uri '/beta/verifiableCredentials/authorities').value)
    Write-Host ("[Issuer authorities] : {0}" -f $auths.Count) -ForegroundColor Yellow
    foreach ($a in $auths) {
        Write-Host ("  - {0}  (DID: {1})" -f $a.name, $a.didModel.did)
        try { $c = @((Invoke-MgGraphRequest -Method GET -Uri "/beta/verifiableCredentials/authorities/$($a.id)/contracts").value); Write-Host ("      credential types: {0}" -f (($c.name) -join ', ')) } catch {}
    }
} catch { Write-Host "[Issuer authorities] : admin API not available — VERIFY for your tenant; use the Verified ID portal blade." -ForegroundColor Yellow }

# 2) Verified ID audit activity (best effort — category/service naming is tenant-dependent)
$since = (Get-Date).AddDays(-$Days).ToString('yyyy-MM-ddTHH:mm:ssZ')
$rows = @()
try {
    $filter = "activityDateTime ge $since"
    $audit = @((Invoke-MgGraphRequest -Method GET -Uri "/v1.0/auditLogs/directoryAudits?`$filter=$([uri]::EscapeDataString($filter))&`$top=999").value)
    $vc = @($audit | Where-Object { ($_.loggedByService -match 'Verif') -or ($_.category -match 'Verif') -or ($_.activityDisplayName -match 'credential') })
    Write-Host ("`n[Verified ID audit events] : {0} of {1} directory-audit rows matched" -f $vc.Count, $audit.Count) -ForegroundColor Yellow
    $rows = $vc | ForEach-Object { [pscustomobject]@{ When=$_.activityDateTime; Activity=$_.activityDisplayName; Service=$_.loggedByService; Result=$_.result; Initiator=$_.initiatedBy.user.userPrincipalName } }
    $rows | Sort-Object When -Descending | Select-Object -First 50 | Format-Table When, Activity, Result, Initiator -AutoSize
} catch { Write-Host "  Could not read directory audit logs: $($_.Exception.Message)" -ForegroundColor Yellow }

if ($CsvPath -and $rows.Count -gt 0) { $rows | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8; Write-Host "CSV written: $CsvPath" -ForegroundColor Green }

Write-Host "`nDone. Read-only. Reporting depth depends on tenant logging + admin API (VERIFY for your tenant)." -ForegroundColor Green
Disconnect-MgGraph | Out-Null
