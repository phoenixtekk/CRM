<#
.SYNOPSIS
    ASR-RuleReference.ps1 — print the ASR rule GUID → friendly-name reference, with this device's state.
.DESCRIPTION
    PURPOSE
        A quick reference mapping each Attack Surface Reduction rule GUID to its friendly name, and
        (when run on a device) the current action for each rule. Useful when reading event logs or
        Get-MpPreference output, which only show GUIDs.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\ASR-RuleReference.ps1
    EXPECTED RESULTS
        A table of GUID, rule name, and the current local action.
.NOTES
    Phoenixtekk Workplace Marketplace — Intune Solutions. Read-only.
#>
[CmdletBinding()] param()
$rules = [ordered]@{
  'd4f940ab-401b-4efc-aadc-ad5f3c50688a'='Block all Office applications from creating child processes'
  '9e6c4e1f-7d60-472f-ba1a-a39ef669e4b2'='Block credential stealing from LSASS'
  'be9ba2d9-53ea-4cdc-84e5-9b1eeee46550'='Block executable content from email/webmail'
  '5beb7efe-fd9a-4556-801d-275e5ffc04cc'='Block execution of potentially obfuscated scripts'
  '75668c1f-73b5-4cf0-bb93-3ecf5cb7cc84'='Block Office apps from injecting code into other processes'
  '92e97fa1-2edf-4476-bdd6-9dd0b4dddc7b'='Block Win32 API calls from Office macros'
  'd1e49aac-8f56-4280-b9ba-993a6d77406c'='Block process creations from PSExec and WMI commands'
  'c1db55ab-c21a-4637-bb3f-a12568109d35'='Use advanced protection against ransomware'
  '3b576869-a4ec-4529-8536-b80a7769e899'='Block Office apps from creating executable content'
  'd3e037e1-3eb8-44c8-a917-57927947596d'='Block JavaScript/VBScript from launching downloaded executable content'
  'e6db77e5-3df2-4cf1-b95a-636979351e5b'='Block persistence through WMI event subscription'
}
$map = @{ 0='Off'; 1='Block'; 2='Audit'; 6='Warn' }
$pref = $null; try { $pref = Get-MpPreference } catch {}
$lookup = @{}; if ($pref) { $ids=@($pref.AttackSurfaceReductionRules_Ids); $acts=@($pref.AttackSurfaceReductionRules_Actions); for($i=0;$i -lt $ids.Count;$i++){ $lookup[$ids[$i].ToLower()] = [int]$acts[$i] } }
$rows = foreach ($g in $rules.Keys) { [pscustomobject]@{ GUID=$g; Rule=$rules[$g]; LocalAction=$(if($lookup.ContainsKey($g.ToLower())){$map[$lookup[$g.ToLower()]]}else{'Not configured'}) } }
$rows | Format-Table -AutoSize -Wrap
