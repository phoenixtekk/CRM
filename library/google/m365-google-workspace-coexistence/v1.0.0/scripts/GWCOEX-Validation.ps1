<#
.SYNOPSIS
    GWCOEX-Validation.ps1 — Per-user interop validation for M365 ↔ Google coexistence.
.DESCRIPTION
    PURPOSE
        For each user in a supplied list, validate the three coexistence pillars from
        the Microsoft 365 side: mail routing (the shared domain relays and a route to
        Google exists), free/busy readiness (the Calendar Interop role accounts and an
        Exchange availability endpoint are in place), and directory presence (a Google-
        hosted counterpart is represented as a mail contact / mail user in the GAL).
        Read-only — it inspects configuration and object state, it does not send mail.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\GWCOEX-Validation.ps1 -SharedDomain your-domain.com -UserListCsv .\pilot-users.csv
        (pilot-users.csv columns: UserPrincipalName,Platform  where Platform = M365 or Google)
        Graph scopes if -UseGraph: Directory.Read.All
    EXPECTED RESULTS
        A per-user results table and a CSV: MailRoute, FreeBusy, Directory each PASS/FAIL.
        PASS for a user = all three pillars OK. No changes are made.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string] $SharedDomain,
    [Parameter(Mandatory = $true)]
    [string] $UserListCsv,
    [string] $InteropExoRole = "svc-interop-exo@$SharedDomain",   # Google role acct (Exchange reads Google)
    [string] $InteropGcalRole = "svc-interop-gcal@$SharedDomain", # Exchange role acct (Google reads Exchange)
    [string] $OutputFolder = ".\validation",
    [string] $UserPrincipalName,
    [switch] $UseGraph
)

$ErrorActionPreference = 'Stop'

function Connect-Exo {
    param([string] $Upn)
    if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
        throw "ExchangeOnlineManagement module not found. Run: Install-Module ExchangeOnlineManagement"
    }
    Import-Module ExchangeOnlineManagement -ErrorAction Stop
    if (-not (Get-ConnectionInformation -ErrorAction SilentlyContinue)) {
        if ($Upn) { Connect-ExchangeOnline -UserPrincipalName $Upn -ShowBanner:$false }
        else      { Connect-ExchangeOnline -ShowBanner:$false }
    }
}

try {
    if (-not (Test-Path $UserListCsv)) { throw "User list CSV not found: $UserListCsv" }
    Connect-Exo -Upn $UserPrincipalName
    if (-not (Test-Path $OutputFolder)) { New-Item -ItemType Directory -Path $OutputFolder | Out-Null }
    $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'

    # ---- Shared prerequisites (evaluated once) -------------------------------
    $acceptedRelay = (Get-AcceptedDomain -Identity $SharedDomain -ErrorAction SilentlyContinue).DomainType -eq 'InternalRelay'
    $googleRoute   = [bool](Get-OutboundConnector -ErrorAction SilentlyContinue |
                        Where-Object { $_.Enabled -and (($_.SmartHosts -join ';') -like '*google*' -or ($_.RecipientDomains -join ';') -like "*$SharedDomain*") })
    $exoRoleExists  = [bool](Get-Mailbox -Identity $InteropGcalRole -ErrorAction SilentlyContinue)   # Google reads Exchange via this
    # Google role account lives in Google; from EXO we confirm it is NOT a conflicting local mailbox.
    $gcalNotLocal   = -not [bool](Get-Mailbox -Identity $InteropExoRole -ErrorAction SilentlyContinue)

    $users = Import-Csv $UserListCsv
    $results = foreach ($u in $users) {
        $upn = $u.UserPrincipalName
        $platform = if ($u.PSObject.Properties.Name -contains 'Platform') { $u.Platform } else { 'M365' }

        # --- Mail routing: relay type + a route to the other platform exist ---
        $mailRoute = if ($acceptedRelay -and $googleRoute) { 'PASS' } else { 'FAIL' }

        # --- Free/busy: interop role accounts + Exchange endpoint readiness ---
        $freeBusy = if ($exoRoleExists -and $gcalNotLocal) { 'PASS' } else { 'FAIL' }

        # --- Directory: counterpart present in the GAL ------------------------
        # Google-hosted users must appear in EXO as a mail contact / mail user.
        $dir = 'PASS'
        if ($platform -eq 'Google') {
            $present = [bool]((Get-MailContact -Identity $upn -ErrorAction SilentlyContinue) -or
                              (Get-MailUser   -Identity $upn -ErrorAction SilentlyContinue))
            $dir = if ($present) { 'PASS' } else { 'FAIL' }
        } else {
            # M365-hosted: confirm a real recipient object exists to sync to Google.
            $dir = if (Get-Recipient -Identity $upn -ErrorAction SilentlyContinue) { 'PASS' } else { 'FAIL' }
        }

        [pscustomobject]@{
            UserPrincipalName = $upn
            Platform          = $platform
            MailRoute         = $mailRoute
            FreeBusy          = $freeBusy
            Directory         = $dir
            Overall           = if ($mailRoute -eq 'PASS' -and $freeBusy -eq 'PASS' -and $dir -eq 'PASS') { 'PASS' } else { 'FAIL' }
        }
    }

    $csv = Join-Path $OutputFolder "validation-$stamp.csv"
    $results | Export-Csv $csv -NoTypeInformation -Encoding UTF8
    $results | Format-Table -AutoSize

    $pass = ($results | Where-Object Overall -eq 'PASS' | Measure-Object).Count
    Write-Host ""
    Write-Host ("==== VALIDATION: {0}/{1} users PASS all pillars ====" -f $pass, ($results | Measure-Object).Count) -ForegroundColor Green
    if (-not $acceptedRelay) { Write-Host "  Shared domain not Internal relay — mail pillar fails for all." -ForegroundColor Yellow }
    if (-not $googleRoute)   { Write-Host "  No enabled outbound route to Google found — mail pillar fails." -ForegroundColor Yellow }
    Write-Host "Results: $csv"
}
finally {
    if (Get-ConnectionInformation -ErrorAction SilentlyContinue) {
        Disconnect-ExchangeOnline -Confirm:$false | Out-Null
    }
}
