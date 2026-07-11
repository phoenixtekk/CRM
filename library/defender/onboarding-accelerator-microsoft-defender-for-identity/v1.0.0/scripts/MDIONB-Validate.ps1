<#
.SYNOPSIS
    MDIONB-Validate.ps1 — targeted validation of Defender for Identity onboarding
    (DSA, sensor health, sensitive-entity tags, honeytoken tags).
.DESCRIPTION
    PURPOSE
        Read-only validation for the "Onboarding Accelerator — Microsoft Defender for Identity"
        solution. Confirms the piece named by -Check: the Directory Service Account, pilot sensor
        health, sensitive-entity tagging, or honeytoken tagging. Maps to the Testing Guide gates.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\MDIONB-Validate.ps1 -Check Sensor
        -Check accepts: DSA | Sensor | Sensitive | Honeytoken | All (default All).
        Uses Microsoft.Graph.Authentication and the Microsoft 365 Defender / Graph Security APIs.
        Reads the MDI security profile; makes no changes.
    EXPECTED RESULTS
        PASS/REVIEW lines per check with the object names from the Implementation Guide, so you can
        confirm each Testing Guide gate before expanding beyond the pilot domain controller.
.NOTES
    White-label. Read-only. Some MDI settings are surfaced through the portal only — where an API
    read is unavailable the script prints the exact portal path to confirm manually.
#>
[CmdletBinding()]
param(
    [ValidateSet('DSA','Sensor','Sensitive','Honeytoken','All')]
    [string]$Check = 'All'
)

Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
if (-not (Get-MgContext)) {
    Connect-MgGraph -Scopes 'SecurityIdentitiesSensors.Read.All','SecurityIdentitiesHealth.Read.All','ThreatHunting.Read.All','SecurityEvents.Read.All' -NoWelcome | Out-Null
}
Write-Host "`n=== Defender for Identity — validation ($Check) ===" -ForegroundColor Cyan

function Test-DSA {
    Write-Host "`n[DSA] Directory Service Account 'MDI Directory Service Account - Tenant - Prod'" -ForegroundColor Cyan
    Write-Host "   Confirm registration in: Settings > Identities > Directory Service accounts" -ForegroundColor DarkGray
    Write-Host "   REVIEW: verify the gMSA is listed and sensors can retrieve its password." -ForegroundColor Yellow
}

function Test-Sensor {
    Write-Host "`n[Sensor] Pilot sensor 'MDI Sensor Host - Pilot DC - Pilot'" -ForegroundColor Cyan
    try {
        $sensors = (Invoke-MgGraphRequest -Method GET -Uri 'https://graph.microsoft.com/beta/security/identities/sensors' -ErrorAction Stop).value
        if ($sensors) {
            foreach ($s in $sensors) { Write-Host ("   {0,-40} health={1} status={2}" -f $s.displayName, $s.healthStatus, $s.sensorType) }
            $healthy = @($sensors | Where-Object { $_.healthStatus -eq 'healthy' }).Count
            Write-Host ("   PASS if healthy sensors > 0. Healthy: {0}/{1}" -f $healthy, $sensors.Count) -ForegroundColor $(if ($healthy -gt 0) { 'Green' } else { 'Yellow' })
        } else { Write-Host "   No sensors returned — confirm in Settings > Identities > Sensors." -ForegroundColor Yellow }
    } catch {
        Write-Host ("   Sensor API read unavailable ({0})." -f $_.Exception.Message) -ForegroundColor Yellow
        Write-Host "   REVIEW manually: Settings > Identities > Sensors — pilot DC shows Running/Healthy." -ForegroundColor DarkGray
    }
}

function Test-Tags($kind) {
    $obj = if ($kind -eq 'Sensitive') { 'MDI Sensitive Entities - Tier0 - Prod' } else { 'MDI Honeytoken - Decoy Identity - Pilot' }
    Write-Host "`n[$kind] Entity tags '$obj'" -ForegroundColor Cyan
    Write-Host "   Confirm in: Settings > Identities > Entity tags > $kind" -ForegroundColor DarkGray
    Write-Host "   REVIEW: verify each planned entity appears under the $kind tag." -ForegroundColor Yellow
}

switch ($Check) {
    'DSA'        { Test-DSA }
    'Sensor'     { Test-Sensor }
    'Sensitive'  { Test-Tags 'Sensitive' }
    'Honeytoken' { Test-Tags 'Honeytoken' }
    'All'        { Test-DSA; Test-Sensor; Test-Tags 'Sensitive'; Test-Tags 'Honeytoken' }
}
Write-Host "`nValidation complete (read-only). Resolve any REVIEW items before expanding." -ForegroundColor Green
