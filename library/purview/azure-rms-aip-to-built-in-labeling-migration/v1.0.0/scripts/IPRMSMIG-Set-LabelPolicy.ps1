<#
.SYNOPSIS
    IPRMSMIG-Set-LabelPolicy.ps1 — apply label-policy advanced settings for built-in-labeling parity (-WhatIf by default; -Commit to apply).
.DESCRIPTION
    PURPOSE
        Reproduces the AIP add-in's behaviour on built-in labeling by applying the advanced settings you
        decided in the parity map (default Outlook label, mandatory-labeling posture, custom-permissions
        availability, etc.) to a named label policy via Set-LabelPolicy -AdvancedSettings. SAFE BY
        DEFAULT — previews with -WhatIf and changes nothing until you pass -Commit. Prints the current
        value of each key first so rollback is trivial. Writes "Label Policy Config - Configure".
    HOW TO RUN
        # Dry-run (no changes):
        powershell -ExecutionPolicy Bypass -File .\IPRMSMIG-Set-LabelPolicy.ps1 -PolicyName '<policy>' -SettingsPath .\parity.json -WhatIf
        # Apply:
        powershell -ExecutionPolicy Bypass -File .\IPRMSMIG-Set-LabelPolicy.ps1 -PolicyName '<policy>' -SettingsPath .\parity.json -Commit
        SettingsPath = a JSON file of { "Key": "Value", ... } advanced settings you verified against
        current documentation. PowerShell 5.1+/7+. Requires ExchangeOnlineManagement (Connect-IPPSSession).
    EXPECTED RESULTS
        Dry-run lists each advanced setting it would apply and its current value; nothing changes. With
        -Commit, Get-LabelPolicy shows the intended advanced settings. PASS = the policy's behaviour
        matches the approved parity map; no unrelated setting changed.
.NOTES
    Purview — Azure RMS / AIP to Built-in Unified Labeling Migration. Advanced-setting KEY NAMES vary and
    evolve — supply only keys you verified against Microsoft's current docs; the script does not invent
    them. Apply to the pilot policy first. No secrets in code.
#>
[CmdletBinding(DefaultParameterSetName='WhatIf')]
param(
    [Parameter(Mandatory)][string]$PolicyName,
    [Parameter(Mandatory)][string]$SettingsPath,
    [switch]$Commit,
    [switch]$WhatIf = $true,
    [string]$ReportName = 'Label Policy Config - Configure',
    [string]$CsvPath
)

if ($Commit) { $WhatIf = $false }
if (-not (Test-Path $SettingsPath)) { throw "Settings JSON not found: $SettingsPath" }

try {
    $settings = Get-Content -Raw -Path $SettingsPath | ConvertFrom-Json
} catch { throw "Could not parse settings JSON '$SettingsPath': $($_.Exception.Message)" }

$settingKeys = @($settings.PSObject.Properties.Name)
if ($settingKeys.Count -eq 0) { throw "Settings JSON contained no advanced-setting keys." }

if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force -AllowClobber
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop
Connect-IPPSSession -ShowBanner:$false

$policy = Get-LabelPolicy -Identity $PolicyName -ErrorAction SilentlyContinue
if (-not $policy) { throw "Label policy '$PolicyName' not found. Verify the name with Get-LabelPolicy." }

$mode = if ($WhatIf) { 'DRY-RUN (-WhatIf): no changes will be made' } else { 'COMMIT: changes WILL be applied' }
Write-Host ("=== {0}  —  policy '{1}'  [{2}] ===" -f $ReportName, $PolicyName, $mode) -ForegroundColor Cyan

# Snapshot current advanced settings for the rollback record.
$currentAdv = @{}
if ($policy.PSObject.Properties.Name -contains 'AdvancedSettings' -and $policy.AdvancedSettings) {
    foreach ($kv in $policy.AdvancedSettings) {
        $s = $kv.ToString()   # rendered as "Key=Value"
        if ($s -match '^(.*?)=(.*)$') { $currentAdv[$matches[1].Trim()] = $matches[2].Trim() }
    }
}

$rows = @()
foreach ($key in $settingKeys) {
    $newVal = [string]$settings.$key
    $oldVal = if ($currentAdv.ContainsKey($key)) { $currentAdv[$key] } else { '<not set>' }
    $rows += [pscustomobject]@{ Policy = $PolicyName; Key = $key; CurrentValue = $oldVal; TargetValue = $newVal }

    if ($WhatIf) {
        Write-Host ("  [WOULD SET] {0} : '{1}' -> '{2}'" -f $key, $oldVal, $newVal) -ForegroundColor Yellow
        Write-Host ("             rollback: Set-LabelPolicy -Identity '{0}' -AdvancedSettings @{{'{1}'='{2}'}}" -f $PolicyName, $key, $oldVal) -ForegroundColor DarkGray
    } else {
        try {
            Set-LabelPolicy -Identity $PolicyName -AdvancedSettings @{ $key = $newVal } -ErrorAction Stop
            Write-Host ("  [SET] {0} : '{1}' -> '{2}'   (rollback prior: '{1}')" -f $key, $oldVal, $newVal) -ForegroundColor Green
        } catch {
            Write-Host ("  [ERROR] setting '{0}' on '{1}': {2}" -f $key, $PolicyName, $_.Exception.Message) -ForegroundColor Red
        }
    }
}

if ($CsvPath) {
    $rows | Export-Csv -Path $CsvPath -NoTypeInformation
    Write-Host ("Saved '{0}' to {1}" -f $ReportName, $CsvPath) -ForegroundColor Green
}

if ($WhatIf) {
    Write-Host "`nDry-run complete. Re-run with -Commit to apply. Apply to the pilot policy first." -ForegroundColor Cyan
} else {
    Write-Host ("`nCommit complete. Verify with: Get-LabelPolicy -Identity '{0}' | Select-Object -ExpandProperty AdvancedSettings" -f $PolicyName) -ForegroundColor Green
}
