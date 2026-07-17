<#
.SYNOPSIS
    GRAPHSUB-Validate.ps1 — PASS/FAIL readiness check for the change-notification pattern. Read-only.
.DESCRIPTION
    PURPOSE
        Read-only PASS/FAIL validation for the "Event-Driven Mail Processing with Microsoft Graph
        Change Notifications" solution. Checks, for the target mailbox:
          1. the managed identity exists and holds a least-privilege Graph application permission
             (default Mail.Read — verify the current least-priv scope with Microsoft);
          2. an ACTIVE, non-expired change-notification subscription exists on the mailbox's message
             resource;
          3. the receiver endpoint (the subscription's notificationUrl) is reachable over HTTPS as far
             as this script can check (a best-effort GET — Graph's own validation is authoritative).
        Prints PASS/FAIL per check and an overall gate. Makes no changes.
    HOW TO RUN
        pwsh -File .\GRAPHSUB-Validate.ps1 -Mailbox 'svc-mailevents@contoso.com'
        pwsh -File .\GRAPHSUB-Validate.ps1 -Mailbox 'svc-mailevents@contoso.com' -LeastPrivPermission 'Mail.Read' -ManagedIdentityDisplayName 'logic-mailevents-receiver-pilot'
    GRAPH SCOPES (delegated, for interactive validation)
        Subscription.Read.All, Application.Read.All, Directory.Read.All
        (Connect-MgGraph -Scopes 'Subscription.Read.All','Application.Read.All','Directory.Read.All')
    EXPECTED RESULTS
        PASS on all three checks = the pattern is wired up (identity + least-priv permission, a live
        subscription on the mailbox, a reachable endpoint). Any FAIL points at the exact gap. NOTE:
        endpoint reachability here is best-effort; Graph's creation-time handshake is authoritative.
.NOTES
    Azure Solutions — read-only. The repeatable way.
    Verify all Graph specifics (max lifetime, supported resources, least-privilege permission name,
    national-cloud endpoints) against current Microsoft documentation.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string]$Mailbox,
    [string]$LeastPrivPermission = 'Mail.Read',
    [string]$ManagedIdentityDisplayName = 'logic-mailevents-receiver-pilot',
    [string]$ManagedIdentityObjectId,
    [string]$Environment = 'Global'
)

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
if (-not (Get-MgContext)) {
    Connect-MgGraph -Environment $Environment `
        -Scopes 'Subscription.Read.All','Application.Read.All','Directory.Read.All' | Out-Null
}

$results = @()
function Add-Result([string]$name,[bool]$pass,[string]$detail) {
    $script:results += [pscustomobject]@{ Check = $name; Result = $(if($pass){'PASS'}else{'FAIL'}); Detail = $detail }
}

Write-Host "`n=== Event-Driven Mail Processing — validation ===" -ForegroundColor Cyan
Write-Host ("Mailbox: {0}" -f $Mailbox)

# Check 1 — managed identity + least-privilege application permission
try {
    if ($ManagedIdentityObjectId) {
        $mi = Get-MgServicePrincipal -ServicePrincipalId $ManagedIdentityObjectId -ErrorAction Stop
    } else {
        $mi = Get-MgServicePrincipal -Filter "displayName eq '$ManagedIdentityDisplayName'" -ErrorAction Stop | Select-Object -First 1
    }
    if (-not $mi) {
        Add-Result 'Managed identity present' $false "identity '$ManagedIdentityDisplayName' not found"
    } else {
        $graph  = Get-MgServicePrincipal -Filter "appId eq '00000003-0000-0000-c000-000000000000'" -ErrorAction Stop
        $grants = Get-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $mi.Id -ErrorAction Stop |
                  Where-Object { $_.ResourceId -eq $graph.Id }
        $granted = @($grants | ForEach-Object { ($graph.AppRoles | Where-Object Id -eq $_.AppRoleId).Value })
        $hasLeastPriv = $granted -contains $LeastPrivPermission
        $hasWrite     = $granted -contains 'Mail.ReadWrite'
        $detail = "granted: $($granted -join ', ')"
        if ($hasWrite) { $detail += "  (WARNING: Mail.ReadWrite is broader than needed — verify least privilege)" }
        Add-Result "Least-privilege permission ($LeastPrivPermission) present" $hasLeastPriv $detail
    }
} catch {
    Add-Result 'Managed identity + permission' $false $_.Exception.Message
}

# Check 2 — active, non-expired subscription on the mailbox message resource
$subUrl = $null
try {
    $now  = (Get-Date).ToUniversalTime()
    $subs = Get-MgSubscription -All -ErrorAction Stop |
            Where-Object { $_.Resource -match [regex]::Escape($Mailbox) -and $_.Resource -match 'messages' }
    $active = $subs | Where-Object { [datetime]$_.ExpirationDateTime -gt $now }
    if ($active) {
        $s = $active | Select-Object -First 1
        $subUrl = $s.NotificationUrl
        Add-Result 'Active subscription on mailbox' $true ("id={0} expires={1:u}" -f $s.Id, [datetime]$s.ExpirationDateTime)
    } elseif ($subs) {
        Add-Result 'Active subscription on mailbox' $false 'a subscription exists but is EXPIRED — run GRAPHSUB-Renew.ps1'
    } else {
        Add-Result 'Active subscription on mailbox' $false 'no subscription found for this mailbox (may be owned by the MI and not visible here — verify)'
    }
} catch {
    Add-Result 'Active subscription on mailbox' $false $_.Exception.Message
}

# Check 3 — receiver endpoint reachable (best-effort)
if ($subUrl) {
    try {
        $resp = Invoke-WebRequest -Uri $subUrl -Method Get -TimeoutSec 15 -SkipHttpErrorCheck -ErrorAction Stop
        $ok = $resp.StatusCode -ge 200 -and $resp.StatusCode -lt 500
        Add-Result 'Receiver endpoint reachable (best-effort)' $ok ("HTTP {0} from {1}" -f $resp.StatusCode, ([uri]$subUrl).Host)
    } catch {
        Add-Result 'Receiver endpoint reachable (best-effort)' $false ("unreachable: {0}" -f $_.Exception.Message)
    }
} else {
    Add-Result 'Receiver endpoint reachable (best-effort)' $false 'no active subscription URL to test'
}

# Output
Write-Host ""
$results | Format-Table Check, Result, Detail -AutoSize | Out-String | Write-Host
$fail = ($results | Where-Object Result -eq 'FAIL').Count
if ($fail -eq 0) {
    Write-Host "OVERALL: PASS — identity + least-priv permission, a live subscription, and a reachable endpoint." -ForegroundColor Green
    exit 0
} else {
    Write-Host ("OVERALL: FAIL — {0} check(s) failed. Fix the gaps above." -f $fail) -ForegroundColor Red
    exit 2
}
