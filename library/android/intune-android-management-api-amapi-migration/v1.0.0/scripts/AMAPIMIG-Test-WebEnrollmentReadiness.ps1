<#
.SYNOPSIS
    AMAPIMIG-Test-WebEnrollmentReadiness.ps1 — check prerequisite signals for web / account-driven Android enrollment (read-only).
.DESCRIPTION
    Reports the prerequisite signals for the newer web / account-driven Android enrollment path: the
    managed Google Play binding, presence of Android device-owner enrollment profiles/tokens, and
    reminders for the required Google/Microsoft network endpoints. Read-only; makes no changes. It
    does NOT assert that web/account-driven enrollment is available — that availability is evolving
    and must be confirmed against current Microsoft guidance for your enrollment model and tenant.
.EXAMPLE
    .\AMAPIMIG-Test-WebEnrollmentReadiness.ps1
    (PowerShell 5.1+/7+, Microsoft.Graph SDK; connect with Connect-MgGraph)
.NOTES
    Expected results: a readiness checklist (binding / profiles / endpoints). Pass = prerequisites
    present AND you have verified the method is available for your model in current Microsoft docs.
    Fail = a prerequisite missing, or availability unverified. White-label. Read-only. No secrets.
#>

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

function Connect-AmapiGraph {
    param([string[]]$Scopes)
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
        throw "Microsoft.Graph PowerShell SDK not found. Install with: Install-Module Microsoft.Graph -Scope CurrentUser"
    }
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    $ctx = Get-MgContext
    if (-not $ctx -or ($Scopes | Where-Object { $ctx.Scopes -notcontains $_ })) {
        Connect-MgGraph -Scopes $Scopes | Out-Null
    }
    Write-Host "Connected to tenant: $((Get-MgContext).TenantId)" -ForegroundColor Green
}

function Invoke-AmapiGraphGetAll {
    param([Parameter(Mandatory)][string]$Uri)
    $results = @(); $next = $Uri
    while ($next) {
        $resp = Invoke-MgGraphRequest -Method GET -Uri $next
        if ($null -ne $resp.value) { $results += $resp.value } else { $results += $resp }
        $next = $resp.'@odata.nextLink'
    }
    return $results
}

Connect-AmapiGraph -Scopes @('DeviceManagementServiceConfig.Read.All','DeviceManagementConfiguration.Read.All')

function Row($check, $ok, $detail) {
    [pscustomobject]@{ Check = $check; Result = $(if ($ok) { 'PASS' } else { 'REVIEW' }); Detail = $detail }
}

$rows = @()

# 1) Managed Google Play binding present.
try {
    $b = Invoke-MgGraphRequest -Method GET `
        -Uri 'https://graph.microsoft.com/beta/deviceManagement/androidManagedStoreAccountEnterpriseSettings'
    $bound = ($b.bindStatus -and ($b.bindStatus -match 'bound|success|connected'))
    $rows += Row 'Managed Google Play binding' $bound "bindStatus=$($b.bindStatus); lastAppSync=$($b.lastAppSyncDateTime)"
} catch {
    $rows += Row 'Managed Google Play binding' $false "Could not read binding: $($_.Exception.Message)"
}

# 2) Android device-owner enrollment profiles/tokens exist (fully managed / dedicated).
try {
    $profiles = Invoke-AmapiGraphGetAll -Uri 'https://graph.microsoft.com/beta/deviceManagement/androidDeviceOwnerEnrollmentProfiles?$select=id,displayName,enrollmentMode,tokenExpirationDateTime'
    $rows += Row 'Android device-owner enrollment profiles' ([bool]$profiles) "count=$(@($profiles).Count)"
    foreach ($p in $profiles) {
        $rows += Row "  profile: $($p.displayName)" $true "mode=$($p.enrollmentMode); tokenExpires=$($p.tokenExpirationDateTime)"
    }
} catch {
    $rows += Row 'Android device-owner enrollment profiles' $false "Could not read profiles: $($_.Exception.Message)"
}

Write-Host "`n=== Web / account-driven enrollment readiness (prerequisite signals) ===" -ForegroundColor Cyan
$rows | Format-Table -AutoSize

Write-Host "`nNetwork reachability (verify on the device network — not checkable from here):" -ForegroundColor Cyan
Write-Host "  - Google managed Play / Android services endpoints reachable" -ForegroundColor Gray
Write-Host "  - Microsoft Intune / Entra sign-in endpoints reachable" -ForegroundColor Gray
Write-Host "  (Blocked endpoints are a top cause of 'can't add a Google account' at enrollment.)" -ForegroundColor Gray

Write-Host "`nCRITICAL — availability is evolving:" -ForegroundColor Yellow
Write-Host "  Web / account-driven enrollment availability, the exact user flow, and which enrollment" -ForegroundColor Yellow
Write-Host "  models it supports are NOT asserted by this script. Confirm the method is available for" -ForegroundColor Yellow
Write-Host "  each enrollment model against CURRENT Microsoft guidance / your tenant before designing a" -ForegroundColor Yellow
Write-Host "  wave around it. Readiness here = prerequisites present, not availability confirmed." -ForegroundColor Yellow
