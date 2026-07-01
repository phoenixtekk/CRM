<#
.SYNOPSIS
    WDACMIG-Report.ps1 — migration coverage + would-block report from WDAC audit events.
.DESCRIPTION
    PURPOSE
        Reads the Code Integrity Operational log for events 3076 (audit / would-block) and 3077
        (enforced block) and summarizes the files/publishers involved, so you can decide what to add
        to trust BEFORE enforcing — this is the audit gate. Optionally also reports tenant-wide App
        Control policies and their ring-group assignments via Microsoft Graph. Read-only.
    HOW TO RUN
        Device audit report (elevated):
            powershell -ExecutionPolicy Bypass -File .\WDACMIG-Report.ps1 -Days 14 [-CsvPath C:\Temp\wdacmig.csv]
        Add tenant policy/assignment report:
            powershell -ExecutionPolicy Bypass -File .\WDACMIG-Report.ps1 -Tenant
            (requires Microsoft Graph SDK and DeviceManagementConfiguration.Read.All)
    EXPECTED RESULTS
        A breakdown of would-block files by type/path/publisher (review for legitimate apps to trust);
        a clean report = the audit gate is met. With -Tenant, the audit/enforce profiles and their
        assigned ring groups.
.NOTES
    Read-only.
#>
[CmdletBinding()] param([int]$Days = 14, [string]$CsvPath, [switch]$Tenant)

# --- Device-side would-block report ---
$start = (Get-Date).AddDays(-$Days)
$events = $null
try {
    $events = Get-WinEvent -FilterHashtable @{ LogName='Microsoft-Windows-CodeIntegrity/Operational'; Id=3076,3077; StartTime=$start } -ErrorAction Stop
} catch { Write-Host "No Code Integrity 3076/3077 events in the last $Days days (or log unavailable)." -ForegroundColor Yellow }

if ($events) {
    $rows = foreach ($e in $events) {
        $x = [xml]$e.ToXml()
        $d = @{}; $x.Event.EventData.Data | ForEach-Object { $d[$_.Name] = $_.'#text' }
        [pscustomobject]@{
            Time      = $e.TimeCreated
            Type      = if ($e.Id -eq 3077) { 'Enforced-Block' } else { 'Would-Block (Audit)' }
            File      = $d['File Name']
            Publisher = $d['Publisher Name']
        }
    }
    Write-Host "=== Migration would-block report (last $Days days) — $($env:COMPUTERNAME) ===" -ForegroundColor Cyan
    $rows | Group-Object Type | Select-Object Name, Count | Format-Table -AutoSize
    Write-Host "Top flagged files (re-trust legitimate apps before enforcing):" -ForegroundColor Cyan
    $rows | Group-Object File | Sort-Object Count -Descending | Select-Object -First 15 Count, Name | Format-Table -AutoSize
    if ($CsvPath) { $rows | Export-Csv -Path $CsvPath -NoTypeInformation; Write-Host "Saved $CsvPath" -ForegroundColor Green }
    Write-Host "AUDIT GATE: re-trust legitimate apps (Intune managed installer / ISG / signer rule), then re-run until clean." -ForegroundColor Gray
}

# --- Tenant policy + ring-assignment report ---
if ($Tenant) {
    Write-Host "`n=== Tenant App Control policies + ring assignments (Graph) ===" -ForegroundColor Cyan
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    Connect-MgGraph -Scopes 'DeviceManagementConfiguration.Read.All' -NoWelcome
    function Groups($uri){ try { (Invoke-MgGraphRequest -Method GET -Uri $uri).value | ForEach-Object { $_.target.groupId } | Where-Object { $_ } } catch { @() } }
    $found = 0
    foreach ($p in (Invoke-MgGraphRequest -Method GET -Uri '/beta/deviceManagement/configurationPolicies').value) {
        if ($p.name -match 'App Control|Application Control|WDAC') {
            $found++
            Write-Host ("POLICY (catalog): {0}  [groups: {1}]" -f $p.name, ((Groups "/beta/deviceManagement/configurationPolicies/$($p.id)/assignments") -join ', ')) -ForegroundColor Cyan
        }
    }
    foreach ($i in (Invoke-MgGraphRequest -Method GET -Uri '/beta/deviceManagement/intents').value) {
        if ($i.displayName -match 'App Control|Application Control|WDAC') {
            $found++
            Write-Host ("POLICY (intent):  {0}  [groups: {1}]" -f $i.displayName, ((Groups "/beta/deviceManagement/intents/$($i.id)/assignments") -join ', ')) -ForegroundColor Cyan
        }
    }
    if (-not $found) { Write-Host "No App Control policies found — confirm 'App Control - Fleet - Audit' / 'App Control - Fleet - Enforce' exist and are assigned." -ForegroundColor Yellow }
    Disconnect-MgGraph | Out-Null
}
