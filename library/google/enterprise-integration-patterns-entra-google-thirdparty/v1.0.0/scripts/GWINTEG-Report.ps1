<#
.SYNOPSIS
    GWINTEG-Report.ps1 — integration coverage / exception report classified against the pattern catalog.
.DESCRIPTION
    PURPOSE
        Read-only report that classifies each Entra-side enterprise application against the pattern
        catalog and surfaces the exceptions. For every app it infers a likely pattern from its signals
        (SAML/OIDC SSO -> P1/P5 federated SSO; a SCIM provisioning job -> P2/P6 provisioning; password
        SSO or none -> snowflake candidate), then lists the coverage summary and three exception
        buckets: snowflakes (no federated pattern), over-broad-scope integrations (P7), and credential
        risk (no-expiry / long-lived / many secrets). Use it to build the exception register and to
        target GWINTEG-Remediation.ps1.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\GWINTEG-Report.ps1
        Optional: -CsvPath .\gwinteg-coverage.csv to export the per-app classification.
        Required Graph scopes (read-only): Application.Read.All, Directory.Read.All, Policy.Read.All,
        Synchronization.Read.All.
    EXPECTED RESULTS
        A coverage summary (how many apps map to each pattern) and exception lists (snowflakes,
        over-broad scopes, credential risk). No changes are made — pass.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph.
#>
[CmdletBinding()]
param(
    [string]$CsvPath
)

$broadPerms = @('ReadWrite.All','Directory.ReadWrite.All','Mail.Read','Mail.ReadWrite','Files.ReadWrite.All','Application.ReadWrite.All')
$maxCredentialDays = 400

Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'Application.Read.All','Directory.Read.All','Policy.Read.All','Synchronization.Read.All' -NoWelcome

Write-Host "`n=== Integration Coverage / Exception Report — $(Get-Date -Format s) ===" -ForegroundColor Cyan

$rows = @()
$sps = Get-MgServicePrincipal -All

foreach ($sp in $sps) {
    $ssoMode = if ($sp.PreferredSingleSignOnMode) { $sp.PreferredSingleSignOnMode } else { 'none' }

    $syncJobs = @()
    try { $syncJobs = @(Get-MgServicePrincipalSynchronizationJob -ServicePrincipalId $sp.Id -ErrorAction SilentlyContinue) } catch { $syncJobs = @() }
    $hasProvisioning = ($syncJobs.Count -gt 0)

    # Infer the likely pattern from the signals (informational classification, not authoritative).
    $pattern = switch ($ssoMode) {
        'saml'     { 'P1/P5 federated SSO (SAML)' }
        'oidc'     { 'P1/P5 federated SSO (OIDC)' }
        'password' { 'SNOWFLAKE (password SSO)' }
        default    { if ($hasProvisioning) { 'P2/P6 provisioning-only' } else { 'unclassified' } }
    }
    if ($hasProvisioning -and $ssoMode -in @('saml','oidc')) { $pattern += ' + P2/P6 provisioning' }

    # Over-broad scope (P7).
    $appRoles = Get-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $sp.Id -All -ErrorAction SilentlyContinue
    $broadHits = @()
    foreach ($a in $appRoles) {
        $rsp = Get-MgServicePrincipal -ServicePrincipalId $a.ResourceId -ErrorAction SilentlyContinue
        $role = $rsp.AppRoles | Where-Object { $_.Id -eq $a.AppRoleId }
        if ($role -and ($broadPerms | Where-Object { $role.Value -like "*$_*" })) { $broadHits += "$($rsp.DisplayName)/$($role.Value)" }
    }

    # Credential risk.
    $creds = @($sp.PasswordCredentials) + @($sp.KeyCredentials)
    $noExpiry  = @($creds | Where-Object { -not $_.EndDateTime }).Count
    $longLived = @($creds | Where-Object { $_.EndDateTime -and $_.StartDateTime -and (($_.EndDateTime - $_.StartDateTime).TotalDays -gt $maxCredentialDays) }).Count
    $credRisk  = ($noExpiry -gt 0) -or ($longLived -gt 0) -or ($creds.Count -gt 2)

    $owners = Get-MgServicePrincipalOwner -ServicePrincipalId $sp.Id -All -ErrorAction SilentlyContinue

    $rows += [pscustomobject]@{
        DisplayName    = $sp.DisplayName
        AppId          = $sp.AppId
        SsoMode        = $ssoMode
        Provisioning   = $hasProvisioning
        Pattern        = $pattern
        BroadScopes    = ($broadHits -join '; ')
        CredentialRisk = $credRisk
        HasOwner       = [bool]$owners
    }
}

# ---- Coverage summary ----
Write-Host "`n-- Coverage by inferred pattern --" -ForegroundColor Cyan
$rows | Group-Object Pattern | Sort-Object Count -Descending | ForEach-Object {
    Write-Host ("  {0,-40} {1}" -f $_.Name, $_.Count)
}

# ---- Exception: snowflakes ----
$snowflakes = $rows | Where-Object { $_.Pattern -like 'SNOWFLAKE*' -or $_.Pattern -eq 'unclassified' }
Write-Host ("`n-- Snowflakes / unclassified ({0}) --" -f @($snowflakes).Count) -ForegroundColor Yellow
$snowflakes | ForEach-Object { Write-Host ("  • {0}  (SSO {1})  appId {2}" -f $_.DisplayName, $_.SsoMode, $_.AppId) }

# ---- Exception: over-broad scopes (P7) ----
$broad = $rows | Where-Object { $_.BroadScopes }
Write-Host ("`n-- Over-broad application permissions — P7 ({0}) --" -f @($broad).Count) -ForegroundColor Yellow
$broad | ForEach-Object { Write-Host ("  • {0}: {1}" -f $_.DisplayName, $_.BroadScopes) }

# ---- Exception: credential risk ----
$credRiskRows = $rows | Where-Object { $_.CredentialRisk }
Write-Host ("`n-- Credential risk (no-expiry / long-lived / many) ({0}) --" -f @($credRiskRows).Count) -ForegroundColor Yellow
$credRiskRows | ForEach-Object { Write-Host ("  • {0}  appId {1}" -f $_.DisplayName, $_.AppId) }

# ---- Exception: no owner ----
$noOwner = $rows | Where-Object { -not $_.HasOwner }
Write-Host ("`n-- No owner ({0}) --" -f @($noOwner).Count) -ForegroundColor Yellow
$noOwner | ForEach-Object { Write-Host ("  • {0}  appId {1}" -f $_.DisplayName, $_.AppId) }

if ($CsvPath) {
    $rows | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8
    Write-Host ("`nExported {0} rows to {1}" -f $rows.Count, $CsvPath) -ForegroundColor Green
}
Write-Host "`nRecord deliberate exceptions in the register; remediate snowflakes with GWINTEG-Remediation.ps1 (preview first)." -ForegroundColor Cyan
Disconnect-MgGraph | Out-Null
