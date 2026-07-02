<#
.SYNOPSIS
    ASR-Discovery.ps1 — Defender AV state and current ASR rule configuration.
.DESCRIPTION
    PURPOSE
        Reports whether Defender Antivirus is active with real-time protection (required for ASR)
        and lists the device's currently configured ASR rules and their actions.
    HOW TO RUN
        Elevated: powershell -ExecutionPolicy Bypass -File .\ASR-Discovery.ps1
    EXPECTED RESULTS
        Defender state plus a table of configured ASR rule GUIDs and their action (Off/Block/Audit/Warn).
.NOTES
    White-label — Intune Solutions. Read-only.
#>
[CmdletBinding()] param()
Write-Host "`n=== ASR Discovery ($($env:COMPUTERNAME)) ===" -ForegroundColor Cyan
try { $mp = Get-MpComputerStatus } catch { $mp = $null }
Write-Host ("Defender AV running     : {0}" -f ($(if($mp){$mp.AMRunning}else{'?'}))) -ForegroundColor ($(if($mp.AMRunning){'Green'}else{'Yellow'}))
Write-Host ("Real-time protection    : {0}" -f ($(if($mp){$mp.RealTimeProtectionEnabled}else{'?'}))) -ForegroundColor ($(if($mp.RealTimeProtectionEnabled){'Green'}else{'Yellow'}))
$pref = Get-MpPreference
$ids = $pref.AttackSurfaceReductionRules_Ids
$acts = $pref.AttackSurfaceReductionRules_Actions
$map = @{ 0='Off (Not configured)'; 1='Block'; 2='Audit'; 6='Warn' }
if (-not $ids) { Write-Host "`nNo ASR rules configured on this device." -ForegroundColor Yellow; return }
$rows = for ($i=0; $i -lt $ids.Count; $i++) { [pscustomobject]@{ RuleId=$ids[$i]; Action=$map[[int]$acts[$i]] } }
Write-Host "`nConfigured ASR rules:" -ForegroundColor Cyan
$rows | Format-Table -AutoSize
Write-Host "Run ASR-RuleReference.ps1 to map GUIDs to friendly names." -ForegroundColor Gray
