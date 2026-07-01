<#
.SYNOPSIS
    SAMPROG-Discovery.ps1 — Software Asset Management program readiness and data-coverage discovery.
.DESCRIPTION
    PURPOSE
        Reports SAM-program readiness signals so you can assess current state before standing up the
        program: whether a tenant entitlement source (assigned licenses) and a deployment/usage
        discovery source (Intune managed devices) are reachable, and a high-level count of managed
        Windows devices and subscribed SKUs. Read-only. This supports the Assess step — it does not
        change any tenant data.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\SAMPROG-Discovery.ps1
        Requires the Microsoft Graph PowerShell SDK. On first run, consent to the read scopes:
        Organization.Read.All, DeviceManagementManagedDevices.Read.All.
    EXPECTED RESULTS
        A readiness summary: subscribed SKU count (entitlement source), managed Windows device count
        (discovery source), and a PASS/GAP line per signal you can record against the Requirements
        checklist.
.NOTES
    Asset Mgt — SAM Program. Read-only against Microsoft Graph. The repeatable way.
#>
[CmdletBinding()] param()

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'Organization.Read.All','DeviceManagementManagedDevices.Read.All' -NoWelcome

Write-Host "`n=== SAM Program — readiness discovery ===" -ForegroundColor Cyan

# Entitlement source: subscribed SKUs (assigned licenses) as a proxy for a tenant entitlement feed.
$skuCount = 0
try {
    $skus = (Invoke-MgGraphRequest -Method GET -Uri '/v1.0/subscribedSkus').value
    $skuCount = @($skus).Count
    Write-Host ("Entitlement source : {0} subscribed SKUs visible" -f $skuCount)
} catch {
    Write-Host ("Entitlement source : not reachable ({0})" -f $_.Exception.Message) -ForegroundColor Yellow
}
$entOk = $skuCount -gt 0
Write-Host ("  Signal           : {0}" -f ($(if($entOk){'PASS — a tenant entitlement source is readable'}else{'GAP — confirm an entitlement system of record'}))) -ForegroundColor ($(if($entOk){'Green'}else{'Yellow'}))

# Discovery source: managed Windows devices (deployment/usage data).
$devCount = 0
try {
    $uri = "/v1.0/deviceManagement/managedDevices?`$filter=operatingSystem eq 'Windows'&`$select=id"
    do { $r = Invoke-MgGraphRequest -Method GET -Uri $uri; $devCount += @($r.value).Count; $uri = $r.'@odata.nextLink' } while ($uri)
    Write-Host ("Discovery source   : {0} managed Windows devices" -f $devCount)
} catch {
    Write-Host ("Discovery source   : not reachable ({0})" -f $_.Exception.Message) -ForegroundColor Yellow
}
$discOk = $devCount -gt 0
Write-Host ("  Signal           : {0}" -f ($(if($discOk){'PASS — a deployment/usage discovery source is readable'}else{'GAP — enable Intune/discovery or SaaS usage reporting'}))) -ForegroundColor ($(if($discOk){'Green'}else{'Yellow'}))

Write-Host "`nRecord these signals against the Requirements checklist; remediate any GAP before configuring the program." -ForegroundColor Cyan
Disconnect-MgGraph | Out-Null
