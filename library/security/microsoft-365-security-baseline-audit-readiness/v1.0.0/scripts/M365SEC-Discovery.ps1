<#
.SYNOPSIS
    M365SEC-Discovery.ps1 — Microsoft 365 secure-configuration readiness: Secure Score + key service config (Graph).
.DESCRIPTION
    PURPOSE
        Reads the tenant's current Microsoft Secure Score and the secure-score control profiles, plus
        the key organization/service configuration signals used by the baseline register
        (organization info and, where available, security-related settings), so you can record the
        current posture in the baseline register before you configure anything. Read-only.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\M365SEC-Discovery.ps1
        Requires the Microsoft Graph PowerShell SDK and consent to:
        SecurityEvents.Read.All, Organization.Read.All, Directory.Read.All.
    EXPECTED RESULTS
        The latest Secure Score (current / max / percentage), the top control profiles with their
        implementation state, and basic organization/service configuration — printed so you can
        transcribe each into the baseline register 'M365 Security Baseline Register - Tenant Services
        - Baseline'.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph.
    Uses documented endpoints: /security/secureScores, /security/secureScoreControlProfiles,
    /organization. Product/service-specific deep config is captured via the admin centers per the
    Implementation Guide.
#>
[CmdletBinding()] param()

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'SecurityEvents.Read.All','Organization.Read.All','Directory.Read.All' -NoWelcome

Write-Host "`n=== Microsoft Secure Score (latest) ===" -ForegroundColor Cyan
try {
    $scores = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/security/secureScores?`$top=1").value
    if ($scores) {
        $s = $scores[0]
        $pct = if ($s.maxScore) { [math]::Round(($s.currentScore / $s.maxScore) * 100, 1) } else { 0 }
        Write-Host ("  Current: {0} / {1}  ({2}%)  as of {3}" -f $s.currentScore, $s.maxScore, $pct, $s.createdDateTime)
        Write-Host ("  Active user count: {0}" -f $s.activeUserCount)
    } else {
        Write-Host "  No Secure Score returned. Confirm licensing surfaces Secure Score and try again." -ForegroundColor Yellow
    }
} catch {
    Write-Host ("  Could not read Secure Score: {0}" -f $_.Exception.Message) -ForegroundColor Yellow
}

Write-Host "`n=== Secure Score control profiles (implementation state) ===" -ForegroundColor Cyan
try {
    $profiles = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/security/secureScoreControlProfiles?`$top=999").value
    if ($profiles) {
        $profiles |
            Sort-Object { [double]($_.maxScore) } -Descending |
            Select-Object -First 25 |
            ForEach-Object {
                Write-Host ("  [{0}] {1}  (max {2}, category {3})" -f $_.controlCategory, $_.id, $_.maxScore, $_.actionType)
            }
        Write-Host ("  ... {0} control profiles total." -f $profiles.Count) -ForegroundColor DarkGray
    } else {
        Write-Host "  No control profiles returned." -ForegroundColor Yellow
    }
} catch {
    Write-Host ("  Could not read control profiles: {0}" -f $_.Exception.Message) -ForegroundColor Yellow
}

Write-Host "`n=== Organization / service configuration ===" -ForegroundColor Cyan
try {
    $org = (Invoke-MgGraphRequest -Method GET -Uri '/v1.0/organization').value
    foreach ($o in $org) {
        Write-Host ("  Tenant: {0}  (id {1})" -f $o.displayName, $o.id)
        Write-Host ("  Verified domains: {0}" -f (($o.verifiedDomains | ForEach-Object { $_.name }) -join ', '))
        Write-Host ("  On-prem sync enabled: {0}" -f $o.onPremisesSyncEnabled)
    }
} catch {
    Write-Host ("  Could not read organization: {0}" -f $_.Exception.Message) -ForegroundColor Yellow
}

Write-Host "`nTranscribe the current values above into the baseline register" -ForegroundColor Yellow
Write-Host "'M365 Security Baseline Register - Tenant Services - Baseline', then set desired values." -ForegroundColor Yellow
Disconnect-MgGraph | Out-Null
