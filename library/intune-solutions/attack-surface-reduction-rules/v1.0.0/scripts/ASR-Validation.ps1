<#
.SYNOPSIS
    ASR-Validation.ps1 — confirm the high-value ASR rules are configured in the expected mode.
.DESCRIPTION
    PURPOSE
        Verifies the eight high-value rules this solution deploys are present and set to the
        expected action. Pass -ExpectBlock to require Block (post-enforcement); default expects Audit or Block.
    HOW TO RUN
        Elevated: powershell -ExecutionPolicy Bypass -File .\ASR-Validation.ps1 [-ExpectBlock]
    EXPECTED RESULTS
        "ASR OK" when all checked rules are configured in the expected mode.
.NOTES
    White-label — Intune Solutions. Read-only.
#>
[CmdletBinding()] param([switch]$ExpectBlock)
$rules = @{
  'd4f940ab-401b-4efc-aadc-ad5f3c50688a'='Office child processes'
  '9e6c4e1f-7d60-472f-ba1a-a39ef669e4b2'='Credential theft (LSASS)'
  'be9ba2d9-53ea-4cdc-84e5-9b1eeee46550'='Executable content from email'
  '5beb7efe-fd9a-4556-801d-275e5ffc04cc'='Obfuscated scripts'
  '75668c1f-73b5-4cf0-bb93-3ecf5cb7cc84'='Office code injection'
  '92e97fa1-2edf-4476-bdd6-9dd0b4dddc7b'='Win32 API from Office macros'
  'd1e49aac-8f56-4280-b9ba-993a6d77406c'='Process creation from PSExec/WMI'
  'c1db55ab-c21a-4637-bb3f-a12568109d35'='Advanced ransomware protection'
}
$pref = Get-MpPreference
$ids = @($pref.AttackSurfaceReductionRules_Ids); $acts = @($pref.AttackSurfaceReductionRules_Actions)
$lookup = @{}; for ($i=0;$i -lt $ids.Count;$i++){ $lookup[$ids[$i].ToLower()] = [int]$acts[$i] }
$ok = $true
Write-Host "=== ASR Validation — $($env:COMPUTERNAME) (expect $(if($ExpectBlock){'Block'}else{'Audit/Block'})) ===" -ForegroundColor Cyan
foreach ($g in $rules.Keys) {
    $a = $lookup[$g.ToLower()]
    $good = if ($ExpectBlock) { $a -eq 1 } else { $a -in 1,2 }
    $ok = $ok -and $good
    $mode = switch ($a) { 1{'Block'} 2{'Audit'} 6{'Warn'} default{'Not configured'} }
    Write-Host ("{0,-34}: {1}" -f $rules[$g], $mode) -ForegroundColor ($(if($good){'Green'}else{'Yellow'}))
}
if ($ok) { Write-Host "`nResult: ASR OK" -ForegroundColor Green; exit 0 } else { Write-Host "`nResult: SOME RULES NOT IN EXPECTED MODE — check policy/sync" -ForegroundColor Yellow; exit 1 }
