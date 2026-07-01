<#
.SYNOPSIS
    NSCASB-Report.ps1 — cloud-app usage and risk report (read-only).
.DESCRIPTION
    PURPOSE
        Produces a cloud-app usage and risk report. It builds the inventory side from Entra ID
        enterprise applications (which cloud apps exist / are integrated) and the scope-group side
        from Entra groups, then writes a CSV you can fold into the app risk register. The
        authoritative per-app risk scores and live usage come from Netskope discovery and are pulled
        via the Netskope REST API — that pull is flagged and deferred to the Netskope docs.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\NSCASB-Report.ps1 -OutCsv .\casb-report.csv
        Requires the Microsoft Graph PowerShell SDK and: Application.Read.All, Group.Read.All.
    EXPECTED RESULTS
        Console summary + a CSV listing each cloud app (inventory signal) with placeholders for
        Netskope risk score / disposition to be reconciled. No changes are made (read-only).
.NOTES
    Network / CASB — read-only. Netskope console internals deferred to the official Netskope docs.
#>
[CmdletBinding()] param(
    [string] $OutCsv = ".\casb-report.csv"
)

Write-Host "`n=== NSCASB Report — cloud-app usage and risk (read-only) ===" -ForegroundColor Cyan

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'Application.Read.All','Group.Read.All' -NoWelcome

$rows = @()
try {
    $apps = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/servicePrincipals?`$select=displayName,appId,signInAudience,tags&`$top=999").value
    foreach ($a in ($apps | Sort-Object displayName)) {
        $rows += [pscustomobject]@{
            CloudApp          = $a.displayName
            AppId             = $a.appId
            InventorySource   = 'Entra enterprise application'
            NetskopeRiskScore = ''          # reconcile from Netskope discovery (deferred)
            Disposition       = ''          # sanction / restrict / coach / block
            PolicyArtifact    = ''          # e.g. Sanctioned apps policy - In-scope apps - Configure
        }
    }
} catch {
    Write-Host ("  Could not enumerate cloud apps: {0}" -f $_.Exception.Message) -ForegroundColor Yellow
}

Write-Host ("`nCloud apps in inventory signal: {0}" -f $rows.Count) -ForegroundColor Green
$rows | Select-Object -First 25 | Format-Table CloudApp, AppId -AutoSize

try {
    $rows | Export-Csv -Path $OutCsv -NoTypeInformation -Encoding UTF8
    Write-Host ("Report written: {0}" -f (Resolve-Path $OutCsv)) -ForegroundColor Green
} catch {
    Write-Host ("Could not write CSV: {0}" -f $_.Exception.Message) -ForegroundColor Yellow
}

# --- Netskope usage + risk-score pull (FLAGGED / DEFERRED) ---
Write-Host "`n[Netskope usage & risk scores — DEFERRED]" -ForegroundColor DarkYellow
Write-Host "  Per-app risk scores (Cloud Confidence Index) and live usage volumes come from Netskope" -ForegroundColor DarkYellow
Write-Host "  discovery. Retrieve them via the Netskope REST API (tenant base URL + API token) per" -ForegroundColor DarkYellow
Write-Host "  the official Netskope documentation, then fill NetskopeRiskScore/Disposition above." -ForegroundColor DarkYellow

Disconnect-MgGraph | Out-Null
