<#
.SYNOPSIS
    ANDROIDGW-Readiness.ps1 — read-only integration-readiness + identity checker for the Google Workspace <-> Intune third-party EMM integration.
.DESCRIPTION
    PURPOSE
        Checks the Intune-side prerequisites you can read via Graph and prints a readiness checklist:
        current managed Google Play bind state, presence/licensing of the pilot users, the Google
        identity <-> Entra identity mapping to confirm, and the manual Google Admin console items the
        script cannot read. Read-only — makes NO changes. Writes "Integration Readiness -
        Workspace+Intune - Assess".
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\ANDROIDGW-Readiness.ps1 -PilotUpns user1@contoso.com,user2@contoso.com -CsvPath C:\Temp\ANDROIDGW-Readiness.csv
        Requires the Microsoft Graph PowerShell SDK and (read-only) scopes:
        DeviceManagementServiceConfig.Read.All, User.Read.All, Organization.Read.All.
    EXPECTED RESULTS
        PASS: each pilot user exists and is licensed, Intune reachable, and the identity checklist is
        confirmed. FAIL: a pilot user missing/unlicensed, or a domain/identity mismatch to resolve.
        The Google Admin console super-admin items are printed as MANUAL verifications.
.NOTES
    Android — Google Workspace <-> Intune Third-Party EMM. Read-only. Google Admin console menu paths
    change — verify the third-party EMM setting against current Google guidance.
#>
[CmdletBinding()]
param(
    [string[]]$PilotUpns = @(),
    [string]$CsvPath,
    [string]$ReportName = 'Integration Readiness - Workspace+Intune - Assess'
)

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'DeviceManagementServiceConfig.Read.All','User.Read.All','Organization.Read.All' -NoWelcome

Write-Host ("=== {0} ===" -f $ReportName) -ForegroundColor Cyan

$checks = @()
function Add-Check([string]$item,[string]$status,[string]$detail) {
    $script:checks += [pscustomobject]@{ Check=$item; Status=$status; Detail=$detail }
    $color = switch ($status) { 'PASS' {'Green'} 'FAIL' {'Red'} 'MANUAL' {'Yellow'} default {'Gray'} }
    Write-Host ("[{0}] {1} — {2}" -f $status, $item, $detail) -ForegroundColor $color
}

# --- Tenant / verified domains (identity model) ---
try {
    $org = (Invoke-MgGraphRequest -Method GET -Uri '/v1.0/organization').value | Select-Object -First 1
    $verified = @($org.verifiedDomains | ForEach-Object { $_.name })
    Add-Check 'Verified domains (Entra)' 'PASS' ("Entra verified domains: {0}" -f ($verified -join ', '))
    Add-Check 'Domain match to Google Workspace' 'MANUAL' 'Confirm your Google Workspace primary domain matches an Entra verified domain used for UPNs (Requirement 2.5).'
} catch {
    Add-Check 'Verified domains (Entra)' 'FAIL' $_.Exception.Message
}

# --- Managed Google Play connection reachable (Intune side) ---
try {
    $binding = Invoke-MgGraphRequest -Method GET -Uri '/beta/deviceManagement/androidManagedStoreAccountEnterpriseSettings'
    $bs = if ($binding.bindStatus) { $binding.bindStatus } else { 'unknown' }
    Add-Check 'Managed Google Play connection (Intune)' 'PASS' ("Readable; bindStatus = {0} (verify beta shape against current guidance)" -f $bs)
} catch {
    Add-Check 'Managed Google Play connection (Intune)' 'MANUAL' ("Not readable yet ({0}) — expected before the connection is completed; verify in Intune." -f $_.Exception.Message)
}

# --- Pilot users exist + licensed ---
foreach ($upn in $PilotUpns) {
    if (-not $upn) { continue }
    try {
        $u = Invoke-MgGraphRequest -Method GET -Uri ("/v1.0/users/{0}?`$select=userPrincipalName,accountEnabled,assignedLicenses,displayName" -f [uri]::EscapeDataString($upn))
        $licCount = @($u.assignedLicenses).Count
        if ($u.accountEnabled -and $licCount -gt 0) {
            Add-Check ("Pilot user {0}" -f $upn) 'PASS' ("enabled, {0} license(s) — confirm Intune/Android entitlement" -f $licCount)
        } else {
            Add-Check ("Pilot user {0}" -f $upn) 'FAIL' ("enabled={0}, licenses={1} — fix before piloting" -f $u.accountEnabled, $licCount)
        }
    } catch {
        Add-Check ("Pilot user {0}" -f $upn) 'FAIL' ("not found / unreadable: {0}" -f $_.Exception.Message)
    }
}
if ($PilotUpns.Count -eq 0) {
    Add-Check 'Pilot users' 'MANUAL' 'No -PilotUpns supplied — provide the pilot users to validate presence + licensing.'
}

# --- Manual items the script cannot read (Google side + network) ---
Add-Check 'Google super-admin available' 'MANUAL' 'Confirm a Google super-admin will act in the Google Admin console (Requirement 2.2).'
Add-Check 'Google Admin console third-party EMM setting' 'MANUAL' 'Verify the CURRENT menu path for enabling a third-party Android EMM against live Google guidance (it moves).'
Add-Check 'Endpoint reachability' 'MANUAL' 'Confirm managed Google Play / Google sign-in + Intune/Entra endpoints are reachable on the pilot network (Requirement 2.7).'
Add-Check 'Change control + rollback' 'MANUAL' 'Confirm an approved change window and a verified rollback are documented (Requirement 2.8).'
Add-Check 'Correct model confirmed' 'MANUAL' 'Confirm Workspace third-party EMM is the right model (not account-enterprise / ANDROIDENT) — one model per tenant (GR 2).'

$fail = @($checks | Where-Object { $_.Status -eq 'FAIL' }).Count
$manual = @($checks | Where-Object { $_.Status -eq 'MANUAL' }).Count
Write-Host ("--- Readiness: {0} checks, {1} FAIL, {2} MANUAL to confirm ---" -f $checks.Count, $fail, $manual) -ForegroundColor Cyan
if ($fail -gt 0) { Write-Host 'Resolve all FAIL items before piloting.' -ForegroundColor Red }

if ($CsvPath) {
    $checks | Export-Csv -Path $CsvPath -NoTypeInformation
    Write-Host ("Saved '{0}' to {1}" -f $ReportName, $CsvPath) -ForegroundColor Green
}

Disconnect-MgGraph | Out-Null
