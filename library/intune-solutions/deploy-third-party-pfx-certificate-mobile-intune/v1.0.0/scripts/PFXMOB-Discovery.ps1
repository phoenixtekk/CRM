<#
.SYNOPSIS
    PFXMOB-Discovery.ps1 — inventory imported PFX objects, Certificate Connector status, and
    existing certificate configuration profiles in Intune. READ-ONLY.
.DESCRIPTION
    PURPOSE
        Establishes the "what exists today" baseline for delivering a third-party PFX to iOS:
          1. Lists imported/user PFX certificate objects already in Intune/Graph (the "PFX exists in
             Graph" state) so you can confirm the import without assuming it delivered.
          2. Reports Intune Certificate Connector health (REQUIRED for the PKCS imported-certificate
             path — it decrypts the imported PFX at delivery time).
          3. Lists existing iOS certificate-related configuration profiles (PKCS imported certificate,
             trusted certificate, and custom profiles) so you can see what is already assigned.
    HOW TO RUN
        Install the Graph SDK once:  Install-Module Microsoft.Graph -Scope CurrentUser
        Then:  powershell -ExecutionPolicy Bypass -File .\PFXMOB-Discovery.ps1
        Sign in when prompted (read scopes only).
    EXPECTED RESULTS
        A list of imported PFX objects, the Certificate Connector(s) and their state, and the iOS
        certificate/custom profiles present in the tenant. No changes are made.
.NOTES
    Workplace Marketplace — Intune Solutions. Read-only. Uses documented Microsoft Graph
    deviceManagement endpoints via Invoke-MgGraphRequest. Reports against Microsoft Graph beta for the
    userPfxCertificates / ndesConnectors resources where v1.0 coverage is incomplete (clearly noted).
#>
[CmdletBinding()] param()

Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
# Read-only scopes for discovery.
Connect-MgGraph -Scopes 'DeviceManagementConfiguration.Read.All','DeviceManagementServiceConfig.Read.All' -NoWelcome

Write-Host "`n=== Third-Party PFX to Mobile — Discovery ===" -ForegroundColor Cyan

# 1. Imported / user PFX certificate objects (the "PFX exists in Graph" state).
#    Documented resource: deviceManagement/userPfxCertificates (Graph beta).
Write-Host "`n[1] Imported PFX certificate objects (userPfxCertificates):" -ForegroundColor Cyan
try {
    $pfx = Invoke-MgGraphRequest -Method GET `
        -Uri 'https://graph.microsoft.com/beta/deviceManagement/userPfxCertificates'
    if ($pfx.value -and $pfx.value.Count -gt 0) {
        $pfx.value | ForEach-Object {
            Write-Host ("  - UPN: {0} | Thumbprint: {1} | IntendedPurpose: {2} | Provider: {3}" -f `
                $_.userPrincipalName, $_.thumbprint, $_.intendedPurpose, $_.keyStorageProvider)
        }
        Write-Host ("  NOTE: an imported object existing here does NOT mean it reached a device — a " +
            "PKCS imported certificate PROFILE must be assigned to the user/group.") -ForegroundColor Yellow
    } else { Write-Host "  (none found)" -ForegroundColor Yellow }
} catch {
    Write-Host ("  Could not query userPfxCertificates: {0}" -f $_.Exception.Message) -ForegroundColor Yellow
}

# 2. Intune Certificate Connector(s) — REQUIRED for the imported-PFX path (decrypts the PFX).
#    Documented resource: deviceManagement/ndesConnectors (Graph beta).
Write-Host "`n[2] Intune Certificate Connector(s):" -ForegroundColor Cyan
try {
    $conn = Invoke-MgGraphRequest -Method GET `
        -Uri 'https://graph.microsoft.com/beta/deviceManagement/ndesConnectors'
    if ($conn.value -and $conn.value.Count -gt 0) {
        $conn.value | ForEach-Object {
            $colour = if ($_.state -eq 'active') { 'Green' } else { 'Yellow' }
            Write-Host ("  - {0} | State: {1} | LastConnection: {2}" -f `
                $_.displayName, $_.state, $_.lastConnectionDateTime) -ForegroundColor $colour
        }
        Write-Host "  (Verify health in: Tenant administration > Connectors and tokens > Certificate connectors)"
    } else {
        Write-Host ("  (no connector found) — REQUIRED for the PKCS imported certificate path. " +
            "Use the custom PKCS12 profile path if you cannot run a connector.") -ForegroundColor Yellow
    }
} catch {
    Write-Host ("  Could not query certificate connectors: {0}" -f $_.Exception.Message) -ForegroundColor Yellow
}

# 3. Existing iOS certificate-related configuration profiles.
Write-Host "`n[3] iOS certificate / custom configuration profiles:" -ForegroundColor Cyan
try {
    $profiles = Invoke-MgGraphRequest -Method GET `
        -Uri 'https://graph.microsoft.com/v1.0/deviceManagement/deviceConfigurations'
    $match = $profiles.value | Where-Object {
        $_.'@odata.type' -match 'ios' -and (
            $_.'@odata.type' -match 'PkcsCertificate' -or
            $_.'@odata.type' -match 'ImportedPFXCertificate' -or
            $_.'@odata.type' -match 'TrustedRootCertificate' -or
            $_.'@odata.type' -match 'CustomConfiguration'
        )
    }
    if ($match) {
        $match | ForEach-Object {
            Write-Host ("  - {0}  [{1}]" -f $_.displayName, ($_.'@odata.type' -replace '#microsoft.graph.',''))
        }
    } else { Write-Host "  (no iOS certificate/custom profiles found)" -ForegroundColor Yellow }
} catch {
    Write-Host ("  Could not query device configurations: {0}" -f $_.Exception.Message) -ForegroundColor Yellow
}

Write-Host "`nDiscovery complete (read-only)." -ForegroundColor Green
Disconnect-MgGraph | Out-Null
