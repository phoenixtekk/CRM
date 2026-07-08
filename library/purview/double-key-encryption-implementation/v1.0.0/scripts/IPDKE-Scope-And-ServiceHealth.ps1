<#
.SYNOPSIS
    IPDKE-Scope-And-ServiceHealth.ps1 — build the DKE scope groups and probe the key-service endpoint.
.DESCRIPTION
    PURPOSE
        Two safe helpers for a Double Key Encryption rollout: (1) create/update the Microsoft Entra
        security groups the DKE label is piloted and scoped to — 'Purview - DKE Pilot Users' and
        'SG - DKE Ultra Confidential Readers' — and add supplied members; and (2) run a read-only
        health probe of the customer-held DKE key service endpoint (reachability, HTTPS/TLS, and that
        it returns public-key JSON). Group changes are gated by -Apply (ShouldProcess/-WhatIf); the
        endpoint probe is always read-only.
    HOW TO RUN
        Install-Module Microsoft.Graph -Scope CurrentUser
        Probe only (no group change):
            powershell -ExecutionPolicy Bypass -File .\IPDKE-Scope-And-ServiceHealth.ps1 `
                -DkeEndpointUrl 'https://dke.contoso.com/DKE-Key-01'
        Preview group build:
            .\IPDKE-Scope-And-ServiceHealth.ps1 -Members user1@contoso.com,user2@contoso.com -WhatIf
        Apply group build + probe:
            .\IPDKE-Scope-And-ServiceHealth.ps1 -Members user1@contoso.com -Apply `
                -DkeEndpointUrl 'https://dke.contoso.com/DKE-Key-01'
        Sign in with rights to create groups (Groups Administrator) when prompted.
    EXPECTED RESULTS
        The named group(s) exist (created if missing, with -Apply) and members are added; the endpoint
        probe reports PASS/FAIL for HTTPS reachability, TLS, HTTP 200, and JSON-shaped body.
.NOTES
    White-label — Purview Solutions. No secrets. Group writes gated by -Apply; endpoint probe is
    read-only (Invoke-WebRequest GET). Uses Microsoft Graph (New-MgGroup / New-MgGroupMemberByRef).
#>
[CmdletBinding(SupportsShouldProcess=$true)] param(
    [switch]$Apply,
    [string]$GroupName       = 'Purview - DKE Pilot Users',
    [string]$ReadersGroup    = 'SG - DKE Ultra Confidential Readers',
    [string[]]$Members       = @(),
    [string]$DkeEndpointUrl  = ''
)

function Ensure-Group([string]$name){
    $g = Get-MgGroup -Filter "displayName eq '$name'" -ConsistencyLevel eventual -CountVariable c -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($g) { Write-Host ("  Group '{0}' already exists (id {1})." -f $name,$g.Id) -ForegroundColor Green; return $g }
    if ($Apply -and $PSCmdlet.ShouldProcess($name,'Create security group')) {
        $nick = ($name -replace '[^A-Za-z0-9]','')
        $g = New-MgGroup -DisplayName $name -MailEnabled:$false -MailNickname $nick -SecurityEnabled:$true `
                -Description 'Microsoft Purview DKE scope'
        Write-Host ("  Created group '{0}' (id {1})." -f $name,$g.Id) -ForegroundColor Green
        return $g
    }
    Write-Host ("  WOULD create group '{0}' (re-run with -Apply)." -f $name) -ForegroundColor Yellow
    return $null
}

# ---- Part 1: scope groups (Graph) ----
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Groups)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Groups -ErrorAction Stop
Import-Module Microsoft.Graph.Users  -ErrorAction Stop
Connect-MgGraph -Scopes 'Group.ReadWrite.All','User.Read.All' -NoWelcome

Write-Host "`n=== DKE scope groups ===" -ForegroundColor Cyan
$pilot = Ensure-Group $GroupName
Ensure-Group $ReadersGroup | Out-Null

foreach ($m in $Members) {
    $user = Get-MgUser -Filter "userPrincipalName eq '$m'" -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $user) { Write-Host ("  User not found: {0}" -f $m) -ForegroundColor Yellow; continue }
    if ($pilot -and $Apply -and $PSCmdlet.ShouldProcess($m,"Add to $GroupName")) {
        try {
            New-MgGroupMemberByRef -GroupId $pilot.Id -BodyParameter @{ '@odata.id' = "https://graph.microsoft.com/v1.0/directoryObjects/$($user.Id)" } -ErrorAction Stop
            Write-Host ("  Added {0} to {1}." -f $m,$GroupName) -ForegroundColor Green
        } catch {
            if ($_.Exception.Message -match 'already exist') { Write-Host ("  {0} already a member." -f $m) -ForegroundColor Green }
            else { Write-Host ("  Could not add {0}: {1}" -f $m,$_.Exception.Message) -ForegroundColor Yellow }
        }
    } elseif (-not $Apply) {
        Write-Host ("  WOULD add {0} to {1} (re-run with -Apply)." -f $m,$GroupName) -ForegroundColor Yellow
    }
}
Disconnect-MgGraph | Out-Null

# ---- Part 2: DKE key-service health probe (read-only) ----
if ($DkeEndpointUrl) {
    Write-Host ("`n=== DKE key-service health probe — {0} ===" -f $DkeEndpointUrl) -ForegroundColor Cyan
    $https = $DkeEndpointUrl.StartsWith('https://')
    Write-Host ("  [{0}] endpoint uses HTTPS" -f $(if($https){'PASS'}else{'FAIL'})) -ForegroundColor $(if($https){'Green'}else{'Red'})
    try {
        $resp = Invoke-WebRequest -Uri $DkeEndpointUrl -Method Get -UseBasicParsing -TimeoutSec 20 -ErrorAction Stop
        $ok200 = ($resp.StatusCode -eq 200)
        Write-Host ("  [{0}] reachable (HTTP {1})" -f $(if($ok200){'PASS'}else{'FAIL'}),$resp.StatusCode) -ForegroundColor $(if($ok200){'Green'}else{'Red'})
        $isJson = $false
        try { $null = $resp.Content | ConvertFrom-Json -ErrorAction Stop; $isJson = $true } catch { $isJson = $false }
        Write-Host ("  [{0}] response is JSON (expected: public-key document)" -f $(if($isJson){'PASS'}else{'WARN'})) -ForegroundColor $(if($isJson){'Green'}else{'Yellow'})
    } catch {
        Write-Host ("  [FAIL] endpoint not reachable — {0}" -f $_.Exception.Message) -ForegroundColor Red
    }
    Write-Host "  Note: a healthy probe confirms reachability only; validate key correctness by applying the label (Testing Guide Test 3)." -ForegroundColor Gray
} else {
    Write-Host "`n  (No -DkeEndpointUrl supplied — skipped the key-service health probe.)" -ForegroundColor Gray
}

Write-Host "`nDone." -ForegroundColor Green
