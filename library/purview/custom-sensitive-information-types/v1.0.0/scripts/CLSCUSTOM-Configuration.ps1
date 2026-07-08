<#
.SYNOPSIS
    CLSCUSTOM-Configuration.ps1 — import/update a custom sensitive information type from a rule-package XML (-WhatIf by default).
.DESCRIPTION
    PURPOSE
        Imports a new custom sensitive information type (SIT) rule package, or updates an existing one,
        from a rule-package XML file you author (Entity + Pattern confidenceLevel + IdMatch regex +
        supporting Match keyword + patternsProximity). Safe by default: with no switch it VALIDATES the
        XML and prints the planned New-/Set-DlpSensitiveInformationTypeRulePackage without changing
        anything (-WhatIf). Supply -Commit to apply — only after the validation gate (CLSCUSTOM-
        Validation.ps1) passes. A SIT only DETECTS; the enforcement action lives in a consuming policy.
    HOW TO RUN
        # Dry-run (default) — validates the XML and shows the planned import, changes nothing:
        powershell -ExecutionPolicy Bypass -File .\CLSCUSTOM-Configuration.ps1 -RulePackagePath .\CustomSIT-RulePackage.xml
        # Update an already-imported package (same file, edited):
        powershell -ExecutionPolicy Bypass -File .\CLSCUSTOM-Configuration.ps1 -RulePackagePath .\CustomSIT-RulePackage.xml -Update
        # Apply (after validation passes):
        ... same parameters ... -Commit
        Requires ExchangeOnlineManagement; connects with Connect-IPPSSession. Back up the current
        package first with CLSCUSTOM-Set-Scope.ps1 -Export.
    EXPECTED RESULTS
        Dry-run: "XML valid" plus the exact New-DlpSensitiveInformationTypeRulePackage (or
        Set-... with -Update) it would run. With -Commit, the rule package is imported/updated and
        echoed back. Verify with CLSCUSTOM-Report.ps1 and validate with CLSCUSTOM-Validation.ps1.
.NOTES
    Purview — Custom Sensitive Information Types. -WhatIf by default; -Commit required to change the
    tenant. No credentials stored. The rule-package XML schema evolves — verify against Microsoft's
    current "create a custom sensitive information type in PowerShell" documentation for your tenant.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$RulePackagePath,   # path to the rule-package XML you authored
    [switch]$Update,                                  # update an existing package (Set-...) instead of creating
    [switch]$Commit
)

$whatIf = -not $Commit
$mode = if ($whatIf) { 'WHATIF (dry-run)' } else { 'COMMIT' }
Write-Host ("=== CLSCUSTOM-Configuration : {0} ===" -f $mode) -ForegroundColor Cyan
Write-Host ("Rule package XML : {0}" -f $RulePackagePath)
Write-Host ("Operation        : {0}" -f (if ($Update) { 'UPDATE existing (Set-...)' } else { 'CREATE new (New-...)' }))

# --- Validate the XML file exists and is well-formed ---
if (-not (Test-Path -LiteralPath $RulePackagePath)) {
    Write-Error "Rule-package XML not found: $RulePackagePath"
    return
}
try {
    [xml]$xml = Get-Content -LiteralPath $RulePackagePath -Raw -ErrorAction Stop
    $entities = @($xml.SelectNodes('//*[local-name()="Entity"]'))
    $patterns = @($xml.SelectNodes('//*[local-name()="Pattern"]'))
    if ($entities.Count -eq 0) { Write-Warning 'No <Entity> found — is this a valid SIT rule package?' }
    Write-Host ("  [OK] XML well-formed: {0} entity(ies), {1} pattern(s)." -f $entities.Count, $patterns.Count) -ForegroundColor Green
} catch {
    Write-Error "XML is not well-formed: $($_.Exception.Message)"
    return
}

# --- Connect ---
if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force -AllowClobber
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop
try { Connect-IPPSSession -ErrorAction Stop -WarningAction SilentlyContinue | Out-Null }
catch { Write-Error "Connect-IPPSSession failed: $($_.Exception.Message)."; return }

Write-Host ''
if ($whatIf) {
    Write-Host 'PLANNED ACTION (nothing is being changed):' -ForegroundColor Yellow
    if ($Update) {
        Write-Host ("  Set-DlpSensitiveInformationTypeRulePackage -FileData ([Byte[]](Get-Content -Path '{0}' -Encoding Byte -ReadCount 0))" -f $RulePackagePath)
    } else {
        Write-Host ("  New-DlpSensitiveInformationTypeRulePackage -FileData ([Byte[]](Get-Content -Path '{0}' -Encoding Byte -ReadCount 0))" -f $RulePackagePath)
    }
    Write-Host ''
    Write-Host 'Re-run with -Commit (after CLSCUSTOM-Validation.ps1 passes) to import the custom SIT.' -ForegroundColor Yellow
    Write-Host 'Tip: back up the current package first with CLSCUSTOM-Set-Scope.ps1 -Export.' -ForegroundColor DarkGray
    return
}

# --- COMMIT ---
try {
    $bytes = [System.IO.File]::ReadAllBytes((Resolve-Path -LiteralPath $RulePackagePath).Path)
    if ($Update) {
        Write-Host 'Updating existing rule package...' -ForegroundColor Green
        Set-DlpSensitiveInformationTypeRulePackage -FileData $bytes -ErrorAction Stop
    } else {
        Write-Host 'Importing new rule package...' -ForegroundColor Green
        New-DlpSensitiveInformationTypeRulePackage -FileData $bytes -ErrorAction Stop
    }
    Write-Host '  Rule package imported. Allow time for the SIT to publish, then validate with CLSCUSTOM-Validation.ps1.' -ForegroundColor Cyan
    Write-Host '  Remember: a SIT only DETECTS — configure the enforcement action in a consuming policy (piloted in simulation first).' -ForegroundColor DarkGray
} catch {
    Write-Error "Commit failed: $($_.Exception.Message). Confirm the XML matches the current rule-package schema and your role permits managing sensitive info types."
}
