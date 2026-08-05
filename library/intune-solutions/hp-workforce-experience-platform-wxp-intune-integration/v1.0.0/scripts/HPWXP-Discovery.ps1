<#
.SYNOPSIS
    HPWXP-Discovery.ps1 — integration-readiness check for HP Workforce Experience Platform (WXP) + Intune.
.DESCRIPTION
    PURPOSE
        Confirms your Intune/Entra tenant is ready for (and wired to) the HP Workforce Experience
        Platform (WXP) integration — the two halves of the integration are checked:
          (1) AGENT-VIA-INTUNE: an Intune Win32/LOB app for the HP WXP agent exists
              (deviceAppManagement/mobileApps, matched by -AppName, default 'HP WXP Agent'), and it has
              at least one assignment.
          (2) TENANT CONNECTOR: an Entra enterprise application / service principal representing HP WXP
              exists (servicePrincipals, matched by -ConnectorAppName, default 'HP Workforce
              Experience') — created when a Global Admin consents to the WXP->Intune connection.
        HP has renamed this platform (formerly HP TechPulse / Proactive Insights / Adaptive Endpoint
        Management), so the connector app's DISPLAY NAME varies between tenants — VERIFY IT IN YOUR
        TENANT (Entra > Enterprise applications) and pass it via -ConnectorAppName. Read-only.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\HPWXP-Discovery.ps1
        Optional: -AppName 'HP WXP Agent'  -ConnectorAppName 'HP Workforce Experience'
        (Install once: Install-Module Microsoft.Graph -Scope CurrentUser)
        Required Graph scopes: DeviceManagementApps.Read.All, Application.Read.All
    EXPECTED RESULTS
        A PASS/FAIL line per check and an overall verdict. A READY tenant shows the HP WXP agent Win32
        app present and assigned, and the HP WXP connector service principal present. The connector
        check is informational when the display name differs — re-run with the -ConnectorAppName shown
        in your tenant before concluding it is missing.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph.
#>
[CmdletBinding()]
param(
    [string]$AppName = 'HP WXP Agent',
    [string]$ConnectorAppName = 'HP Workforce Experience'
)

$ErrorActionPreference = 'Stop'
Connect-MgGraph -Scopes 'DeviceManagementApps.Read.All','Application.Read.All' | Out-Null

function R($Name, $Pass, $Detail) {
    [pscustomobject]@{ Check = $Name; Result = $(if ($Pass) { 'PASS' } else { 'FAIL' }); Detail = $Detail }
}

$results = New-Object System.Collections.Generic.List[object]

# 1) HP WXP agent Win32/LOB app present in Intune
$agentApp = $null
try {
    $apps = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/deviceAppManagement/mobileApps?`$filter=contains(displayName,'$AppName')"
    $agentApp = @($apps.value | Where-Object { $_.displayName -match [regex]::Escape($AppName) } | Select-Object -First 1)
    if ($agentApp -is [array]) { $agentApp = $agentApp[0] }
    $results.Add( (R "HP WXP agent app present (name contains '$AppName')" ($null -ne $agentApp) $(if ($agentApp) { "'$($agentApp.displayName)' ($($agentApp.'@odata.type'))" } else { "No app matched '$AppName' — check the app name / -AppName" })) )
} catch { $results.Add( (R "HP WXP agent app present (name contains '$AppName')" $false $_.Exception.Message) ) }

# 2) Agent app is assigned (Required)
if ($agentApp) {
    try {
        $asg = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/deviceAppManagement/mobileApps/$($agentApp.id)/assignments"
        $count = @($asg.value).Count
        $req   = @($asg.value | Where-Object { "$($_.intent)" -match 'required' }).Count
        $results.Add( (R 'HP WXP agent app is assigned' ($count -gt 0) "$count assignment(s), $req Required") )
    } catch { $results.Add( (R 'HP WXP agent app is assigned' $false $_.Exception.Message) ) }
} else {
    $results.Add( (R 'HP WXP agent app is assigned' $false 'Skipped — agent app not found') )
}

# 3) HP WXP tenant-connector enterprise application / service principal (name VARIES — verify in tenant)
try {
    $sp = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/servicePrincipals?`$filter=startswith(displayName,'$ConnectorAppName')"
    $match = @($sp.value)
    if (-not $match.Count) {
        # Broaden: any service principal whose name mentions HP + workforce/experience/techpulse/proactive
        $all = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/servicePrincipals?`$search=`"displayName:HP`"" -Headers @{ ConsistencyLevel = 'eventual' }
        $match = @($all.value | Where-Object { $_.displayName -match 'workforce|experience|techpulse|proactive|adaptive endpoint' })
    }
    $found = $match.Count -gt 0
    $names = ($match | ForEach-Object { $_.displayName } | Select-Object -Unique) -join '; '
    $results.Add( (R "HP WXP connector service principal present (name varies — verify in tenant)" $found $(if ($found) { "Matched: $names" } else { "No service principal matched '$ConnectorAppName' or HP WXP name variants — verify the display name in Entra > Enterprise applications and re-run with -ConnectorAppName" })) )
} catch { $results.Add( (R 'HP WXP connector service principal present' $false $_.Exception.Message) ) }

$results | Format-Table -AutoSize
$fail = @($results | Where-Object Result -eq 'FAIL').Count
Write-Host ''
Write-Host "NOTE: HP renamed this platform (TechPulse / Proactive Insights / Adaptive Endpoint Management -> Workforce Experience Platform). The connector app display name and the agent app name vary — pass -ConnectorAppName / -AppName to match your tenant before treating a FAIL as real." -ForegroundColor DarkGray
if ($fail -eq 0) { Write-Host 'OVERALL: READY — HP WXP agent app is present/assigned and the connector service principal is present.' -ForegroundColor Green }
else { Write-Host "OVERALL: NOT READY — $fail check(s) failed. Resolve (or re-run with the correct -AppName / -ConnectorAppName) before piloting." -ForegroundColor Yellow }
