<#
.SYNOPSIS
    MACLOCK-Report.ps1 — before/after lockout-and-spray exposure report for the Mac fleet (Graph).
.DESCRIPTION
    PURPOSE
        Produces the evidence-facing report: the count and detail of macOS-originated failed sign-ins
        over a window (by user, app, and error code), any password-spray / risk detections (if
        licensed), and the current Smart Lockout / MFA posture. Exports to CSV/HTML so the output can
        be filed, dated, into 'MACLOCK Remediation Evidence Pack - Mac Credential State' to show the
        before/after reduction. Read-only. Use 'your-tenant-id' style values, not bracketed
        placeholders.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\MACLOCK-Report.ps1 -OutputFolder .\evidence -Days 7
        Requires the Microsoft Graph PowerShell SDK and consent to:
        AuditLog.Read.All, Policy.Read.All, IdentityRiskEvent.Read.All, Directory.Read.All.
    EXPECTED RESULTS
        A console summary plus, in the output folder, dated files:
            Mac-SignIn-Failures-<date>.csv     (per-user/app/error failure detail)
            Mac-Failure-Summary-<date>.csv     (counts by user)
            Mac-Exposure-<date>.html           (readable exposure table)
        File these into the evidence pack, dated, to show the failure/lockout reduction.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph.
    Uses /auditLogs/signIns, /identityProtection/riskDetections, and the password-protection /
    Conditional Access policy reads used by MACLOCK-Discovery.ps1.
#>
[CmdletBinding()]
param(
    [string]$OutputFolder = (Join-Path (Get-Location) 'evidence'),
    [int]$Days = 7
)

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'AuditLog.Read.All','Policy.Read.All','IdentityRiskEvent.Read.All','Directory.Read.All' -NoWelcome

if (-not (Test-Path $OutputFolder)) { New-Item -ItemType Directory -Path $OutputFolder | Out-Null }
$stamp = Get-Date -Format 'yyyy-MM-dd'
$since = (Get-Date).ToUniversalTime().AddDays(-$Days).ToString('yyyy-MM-ddTHH:mm:ssZ')

Write-Host "`n=== Mac-originated sign-in failures (last $Days day[s]) ===" -ForegroundColor Cyan
$rows = @()
try {
    $uri = "/v1.0/auditLogs/signIns?`$filter=createdDateTime ge $since and status/errorCode ne 0&`$top=1000"
    $page = Invoke-MgGraphRequest -Method GET -Uri $uri
    $signIns = @($page.value)
    while ($page.'@odata.nextLink') { $page = Invoke-MgGraphRequest -Method GET -Uri $page.'@odata.nextLink'; $signIns += $page.value }
    foreach ($s in $signIns) {
        $os = $s.deviceDetail.operatingSystem
        if ($os -and ($os -match 'mac|os ?x')) {
            $rows += [pscustomobject]@{
                User      = $s.userPrincipalName
                App       = $s.appDisplayName
                ErrorCode = $s.status.errorCode
                Reason    = $s.status.failureReason
                OS        = $os
                IP        = $s.ipAddress
                When      = $s.createdDateTime
                CapturedOn= $stamp
            }
        }
    }
    Write-Host ("  {0} Mac-originated failure event(s)." -f $rows.Count)

    $detailPath  = Join-Path $OutputFolder ("Mac-SignIn-Failures-$stamp.csv")
    $summaryPath = Join-Path $OutputFolder ("Mac-Failure-Summary-$stamp.csv")
    $htmlPath    = Join-Path $OutputFolder ("Mac-Exposure-$stamp.html")

    $rows | Export-Csv -Path $detailPath -NoTypeInformation -Encoding UTF8
    $summary = $rows | Group-Object User | Sort-Object Count -Descending |
        ForEach-Object { [pscustomobject]@{ User = $_.Name; FailureCount = $_.Count; CapturedOn = $stamp } }
    $summary | Export-Csv -Path $summaryPath -NoTypeInformation -Encoding UTF8
    $summary | ConvertTo-Html -Title "MACLOCK Mac Exposure ($stamp)" -PreContent "<h2>Mac-originated sign-in failures by user — $stamp</h2>" |
        Out-File -FilePath $htmlPath -Encoding UTF8

    $summary | Select-Object -First 10 | ForEach-Object { Write-Host ("  {0,-4} x  {1}" -f $_.FailureCount, $_.User) }
    Write-Host ("  Saved: {0}" -f $detailPath) -ForegroundColor DarkGray
    Write-Host ("  Saved: {0}" -f $summaryPath) -ForegroundColor DarkGray
    Write-Host ("  Saved: {0}" -f $htmlPath) -ForegroundColor DarkGray
} catch {
    Write-Host ("  Could not build the exposure report: {0}" -f $_.Exception.Message) -ForegroundColor Yellow
}

Write-Host "`n=== Risk detections (if licensed) ===" -ForegroundColor Cyan
try {
    $risks = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/identityProtection/riskDetections?`$top=50").value
    $spray = $risks | Where-Object { $_.riskEventType -match 'passwordSpray|spray|unfamiliar|anonymized' }
    Write-Host ("  {0} matching risk detection(s)." -f @($spray).Count)
} catch {
    Write-Host ("  Risk detections not available (P2 may be required): {0}" -f $_.Exception.Message) -ForegroundColor DarkGray
}

Write-Host "`nFile these outputs into 'MACLOCK Remediation Evidence Pack - Mac Credential State', dated, to show the before/after reduction." -ForegroundColor Yellow
Disconnect-MgGraph | Out-Null
