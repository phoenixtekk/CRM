<#
.SYNOPSIS
    CLSCUSTOM-Set-Scope.ps1 — export/back up the current custom-SIT rule package, or apply an updated one (-WhatIf by default).
.DESCRIPTION
    PURPOSE
        Rule-package lifecycle helper. -Export writes the CURRENT custom rule package XML to disk (a
        backup you take BEFORE every change, and your version-control artifact) — read-only. Applying an
        updated rule package is safe by default: with no switch it shows the planned Set-... and changes
        nothing (-WhatIf); supply -Commit to apply. Tuning the SIT (regex / supporting evidence /
        proximity / confidence) is done by editing the exported XML and re-applying, then re-validating.
    HOW TO RUN
        # Back up the current custom rule package (read-only):
        powershell -ExecutionPolicy Bypass -File .\CLSCUSTOM-Set-Scope.ps1 -Export -OutPath .\CustomSIT-RulePackage.backup.xml
        # Dry-run applying an edited package (default) — shows the planned Set-..., changes nothing:
        powershell -ExecutionPolicy Bypass -File .\CLSCUSTOM-Set-Scope.ps1 -RulePackagePath .\CustomSIT-RulePackage.xml
        # Apply the edit (after CLSCUSTOM-Validation.ps1 passes):
        powershell -ExecutionPolicy Bypass -File .\CLSCUSTOM-Set-Scope.ps1 -RulePackagePath .\CustomSIT-RulePackage.xml -Commit
        Requires ExchangeOnlineManagement; connects with Connect-IPPSSession.
    EXPECTED RESULTS
        -Export: the current custom rule package XML written to -OutPath. Apply dry-run: the planned
        Set-DlpSensitiveInformationTypeRulePackage. -Commit: the package updated and echoed back.
        Re-validate with CLSCUSTOM-Validation.ps1 after any change.
.NOTES
    Purview — Custom Sensitive Information Types. -Export is read-only; applying is -WhatIf by default
    and needs -Commit. No credentials stored. Always back up (-Export) before editing. A SIT only
    DETECTS — enforcement lives in the consuming policy. Schema/cmdlets evolve — verify against your tenant.
#>
[CmdletBinding(DefaultParameterSetName='Apply')]
param(
    [Parameter(ParameterSetName='Export', Mandatory)][switch]$Export,
    [Parameter(ParameterSetName='Export')][string]$PackageName = 'Custom SIT Rule Package - Pilot',
    [Parameter(ParameterSetName='Export', Mandatory)][string]$OutPath,

    [Parameter(ParameterSetName='Apply', Mandatory)][string]$RulePackagePath,
    [Parameter(ParameterSetName='Apply')][switch]$Commit
)

# --- Connect ---
if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force -AllowClobber
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop
try { Connect-IPPSSession -ErrorAction Stop -WarningAction SilentlyContinue | Out-Null }
catch { Write-Error "Connect-IPPSSession failed: $($_.Exception.Message)."; return }

# ============================ EXPORT (read-only backup) ============================
if ($Export) {
    Write-Host ("=== CLSCUSTOM-Set-Scope : EXPORT (read-only) — '{0}' ===" -f $PackageName) -ForegroundColor Cyan
    $pkg = Get-DlpSensitiveInformationTypeRulePackage -Identity $PackageName -ErrorAction SilentlyContinue
    if (-not $pkg) {
        Write-Warning "Rule package '$PackageName' not found. List packages with CLSCUSTOM-Discovery.ps1."
        return
    }
    try {
        # The package's serialized rule XML is exposed on the returned object (SerializedClassificationRuleCollection).
        $content = $pkg.SerializedClassificationRuleCollection
        if ($content -is [byte[]]) {
            [System.IO.File]::WriteAllBytes($OutPath, $content)
        } else {
            Set-Content -LiteralPath $OutPath -Value $content -Encoding UTF8
        }
        Write-Host ("  [OK] Current rule package written to {0}" -f $OutPath) -ForegroundColor Green
        Write-Host '  Keep this in source control. Edit a copy, validate, then apply with -Commit.' -ForegroundColor DarkGray
    } catch {
        Write-Error "Export failed: $($_.Exception.Message). You can also export the XML from the Purview portal."
    }
    return
}

# ============================ APPLY (WhatIf default) ============================
$whatIf = -not $Commit
$mode = if ($whatIf) { 'WHATIF (dry-run)' } else { 'COMMIT' }
Write-Host ("=== CLSCUSTOM-Set-Scope : APPLY {0} ===" -f $mode) -ForegroundColor Cyan
Write-Host ("Rule package XML : {0}" -f $RulePackagePath)

if (-not (Test-Path -LiteralPath $RulePackagePath)) { Write-Error "Rule-package XML not found: $RulePackagePath"; return }
try {
    [xml]$xml = Get-Content -LiteralPath $RulePackagePath -Raw -ErrorAction Stop
    $patterns = @($xml.SelectNodes('//*[local-name()="Pattern"]'))
    Write-Host ("  [OK] XML well-formed: {0} pattern(s)." -f $patterns.Count) -ForegroundColor Green
} catch {
    Write-Error "XML is not well-formed: $($_.Exception.Message)"; return
}

Write-Host ''
if ($whatIf) {
    Write-Host 'PLANNED ACTION (nothing is being changed):' -ForegroundColor Yellow
    Write-Host ("  Set-DlpSensitiveInformationTypeRulePackage -FileData ([Byte[]] <bytes of {0}>)" -f $RulePackagePath)
    Write-Host ''
    Write-Host 'Re-run with -Commit (after CLSCUSTOM-Validation.ps1 passes) to update the package. Back up first with -Export.' -ForegroundColor Yellow
    return
}

try {
    $bytes = [System.IO.File]::ReadAllBytes((Resolve-Path -LiteralPath $RulePackagePath).Path)
    Write-Host 'Updating rule package...' -ForegroundColor Green
    Set-DlpSensitiveInformationTypeRulePackage -FileData $bytes -ErrorAction Stop
    Write-Host '  Updated. Allow publish time, then re-validate with CLSCUSTOM-Validation.ps1.' -ForegroundColor Cyan
} catch {
    Write-Error "Commit failed: $($_.Exception.Message). Confirm the XML matches the current schema and your role permits managing sensitive info types."
}
