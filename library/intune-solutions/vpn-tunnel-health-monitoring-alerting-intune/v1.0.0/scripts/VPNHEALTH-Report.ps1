<#
.SYNOPSIS
    VPNHEALTH-Report.ps1 — fleet tunnel-health rollup export (per device: VPN type, verdict, cert days-to-expiry).

.DESCRIPTION
    PURPOSE
        Exports a fleet health rollup to CSV so you have evidence of tunnel health over time. For each
        device reporting from the health-check package it captures the VPN type, the health verdict
        (Healthy / Degraded / Unhealthy), and the certificate days-to-expiry. Two data sources are
        supported:
          -Source Graph  (default): reads per-device run states + detection output from the Proactive
                          Remediations package via Microsoft Graph (read-only), parsing the structured
                          health line the detection script emits.
          -Source Local  : parses on-device C:\ProgramData\VPNHealth\tunnel-health.log files you have
                          collected (useful before the Log Analytics path is wired).
        Read-only. The equivalent Log Analytics KQL for the same rollup is included as a comment below.

    HOW TO RUN
        Install-Module Microsoft.Graph -Scope CurrentUser   # once
        .\VPNHEALTH-Report.ps1
        .\VPNHEALTH-Report.ps1 -PackageName 'VPNHEALTH - Tunnel Health - Detect - Pilot'
        .\VPNHEALTH-Report.ps1 -CsvPath C:\Temp\vpnhealth.csv
        .\VPNHEALTH-Report.ps1 -Source Local -LocalLogFolder C:\Collected\VPNHealthLogs

    GRAPH SCOPES (read-only)
        DeviceManagementConfiguration.Read.All   (only for -Source Graph)

    EXPECTED RESULTS
        A CSV (one row per device) with VpnType, Verdict, CertDaysToExpiry, and the raw health line,
        plus a printed rollup by VpnType and Gateway. (deviceHealthScripts run states / detection output
        are BETA — verify against current Microsoft documentation; property names may change.)

.NOTES
    White-label — Intune Solutions. Read-only.

    ------------------------------------------------------------------------------------------------
    EQUIVALENT LOG ANALYTICS KQL — 'VPN Tunnel Health - Fleet Rollup' (by VPN type and gateway).
    Replace VpnTunnelHealth_CL with the table your health data actually lands in (verify per
    Implementation Step 7 — do NOT assume this table name).

        VpnTunnelHealth_CL
        | summarize arg_max(TimeGenerated, *) by DeviceName_s
        | summarize
            Devices          = count(),
            Healthy          = countif(Verdict_s == "Healthy"),
            Degraded         = countif(Verdict_s == "Degraded"),
            Unhealthy        = countif(Verdict_s == "Unhealthy"),
            CertExpiringSoon = countif(CertDaysToExpiry_d <= 30 and CertDaysToExpiry_d >= 0)
            by VpnType_s, Gateway_s
        | extend UnhealthyPct = round(100.0 * Unhealthy / Devices, 1)
        | sort by Unhealthy desc, Degraded desc
    ------------------------------------------------------------------------------------------------
#>
[CmdletBinding()]
param(
    [ValidateSet('Graph','Local')] [string]$Source = 'Graph',
    [string]$PackageName = 'VPNHEALTH - Tunnel Health - Detect - Pilot',
    [string]$LocalLogFolder,
    [string]$CsvPath = "$PSScriptRoot\vpnhealth-$(Get-Date -Format yyyyMMdd-HHmm).csv"
)

function Parse-HealthLine([string]$line, [string]$device) {
    # Parses "VPNHealth verdict=Healthy type=MicrosoftTunnel gateway=vpn.contoso.com certDaysToExpiry=87 ..."
    $get = { param($k) if ($line -match "$k=([^\s]+)") { $Matches[1] } else { $null } }
    [pscustomobject]@{
        DeviceName       = $device
        VpnType          = (& $get 'type')
        Gateway          = (& $get 'gateway')
        Verdict          = (& $get 'verdict')
        CertDaysToExpiry = (& $get 'certDaysToExpiry')
        Raw              = $line
    }
}

$rows = @()

if ($Source -eq 'Local') {
    if (-not $LocalLogFolder -or -not (Test-Path $LocalLogFolder)) {
        Write-Host "Provide -LocalLogFolder pointing at collected tunnel-health.log files." -ForegroundColor Yellow; return
    }
    Get-ChildItem $LocalLogFolder -Recurse -Filter 'tunnel-health.log' | ForEach-Object {
        $last = Get-Content $_.FullName | Select-Object -Last 1
        if ($last) {
            try {
                $obj = $last | ConvertFrom-Json
                $rows += [pscustomobject]@{ DeviceName=$obj.DeviceName; VpnType=$obj.VpnType; Gateway=$obj.Gateway; Verdict=$obj.Verdict; CertDaysToExpiry=$obj.CertDaysToExpiry; Raw=$last }
            } catch {}
        }
    }
}
else {
    $ErrorActionPreference = 'Stop'
    Connect-MgGraph -Scopes 'DeviceManagementConfiguration.Read.All' | Out-Null
    function GraphGet($uri) { $i=@(); do { $r=Invoke-MgGraphRequest -Method GET -Uri $uri; $i+=$r.value; $uri=$r.'@odata.nextLink' } while ($uri); return $i }
    $base = 'https://graph.microsoft.com/beta/deviceManagement/deviceHealthScripts'
    $pkg = $null
    try { $pkg = (GraphGet "$base`?`$select=id,displayName") | Where-Object { $_.displayName -eq $PackageName } | Select-Object -First 1 } catch {}
    if (-not $pkg) { Write-Host "Package '$PackageName' not found (verify name / entitlement)." -ForegroundColor Yellow; return }
    $states = @(); try { $states = GraphGet "$base/$($pkg.id)/deviceRunStates?`$expand=managedDevice" } catch {}
    foreach ($s in $states) {
        $dev  = $s.managedDevice.deviceName; if (-not $dev) { $dev = $s.id }
        $out  = "$($s.preRemediationDetectionScriptOutput) $($s.postRemediationDetectionScriptOutput)".Trim()
        if ($out -match 'VPNHealth') { $rows += Parse-HealthLine $out $dev }
        else { $rows += [pscustomobject]@{ DeviceName=$dev; VpnType=$null; Gateway=$null; Verdict=$s.detectionState; CertDaysToExpiry=$null; Raw=$out } }
    }
}

if (-not $rows) { Write-Host 'No health data found. Allow a schedule cycle, or wire telemetry (Implementation Step 7).' -ForegroundColor Yellow; return }

$rows | Export-Csv -NoTypeInformation -Path $CsvPath
Write-Host "CSV written: $CsvPath" -ForegroundColor Cyan
Write-Host ''
Write-Host 'Fleet rollup by VPN type and gateway:' -ForegroundColor Cyan
$rows | Group-Object VpnType, Gateway | ForEach-Object {
    $g = $_.Group
    [pscustomobject]@{
        VpnType          = $g[0].VpnType
        Gateway          = $g[0].Gateway
        Devices          = $g.Count
        Healthy          = ($g | Where-Object Verdict -eq 'Healthy').Count
        Degraded         = ($g | Where-Object Verdict -eq 'Degraded').Count
        Unhealthy        = ($g | Where-Object Verdict -eq 'Unhealthy').Count
        CertExpiringSoon = ($g | Where-Object { $_.CertDaysToExpiry -match '^\d+$' -and [int]$_.CertDaysToExpiry -le 30 }).Count
    }
} | Format-Table -AutoSize
Write-Host ''
Write-Host 'A rising Unhealthy/Degraded count for a VPN type or gateway = a cohort problem — investigate that layer (Triage runbook).' -ForegroundColor Yellow
