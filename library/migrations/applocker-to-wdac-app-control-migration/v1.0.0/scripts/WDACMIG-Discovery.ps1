<#
.SYNOPSIS
    WDACMIG-Discovery.ps1 — capture current AppLocker + WDAC (App Control) state for migration.
.DESCRIPTION
    PURPOSE
        Reads the device's current application-control posture before migration: the effective
        AppLocker policy and its rule collections (the migration source), the OS support verdict for
        App Control for Business, the current code-integrity enforcement state, any active App
        Control policies, and managed-installer status. Read-only.
    HOW TO RUN
        Elevated: powershell -ExecutionPolicy Bypass -File .\WDACMIG-Discovery.ps1 [-XmlPath C:\Temp\applocker.xml]
    EXPECTED RESULTS
        AppLocker rule-collection summary (exported to XML if -XmlPath given), OS support verdict,
        current WDAC enforcement state, and active policy list — the baseline for translation.
.NOTES
    Read-only. Run on a representative device in each migration ring.
#>
[CmdletBinding()] param([string]$XmlPath)

Write-Host "`n=== AppLocker to WDAC Migration — Discovery ($($env:COMPUTERNAME)) ===" -ForegroundColor Cyan

# --- 1. Effective AppLocker policy (the migration source) ---
Write-Host "`n[AppLocker] Effective policy:" -ForegroundColor Cyan
try {
    $apXml = Get-AppLockerPolicy -Effective -Xml -ErrorAction Stop
    if ($XmlPath) { $apXml | Out-File -FilePath $XmlPath -Encoding utf8; Write-Host "  Exported effective AppLocker policy to $XmlPath" -ForegroundColor Green }
    $doc = [xml]$apXml
    foreach ($rc in $doc.AppLockerPolicy.RuleCollection) {
        $count = @($rc.ChildNodes | Where-Object { $_.NodeType -eq 'Element' }).Count
        Write-Host ("  Collection {0,-12} EnforcementMode={1,-12} Rules={2}" -f $rc.Type, $rc.EnforcementMode, $count)
    }
    if (-not $doc.AppLockerPolicy.RuleCollection) { Write-Host "  No AppLocker rule collections found (AppLocker may not be configured here)." -ForegroundColor Yellow }
} catch { Write-Host "  Could not read AppLocker policy: $($_.Exception.Message)" -ForegroundColor Yellow }

# --- 2. AppLocker service (Application Identity) ---
try {
    $appid = Get-Service -Name AppIDSvc -ErrorAction Stop
    Write-Host ("`n[AppLocker] Application Identity service (AppIDSvc): {0}" -f $appid.Status)
} catch { Write-Host "`n[AppLocker] AppIDSvc not found." -ForegroundColor Yellow }

# --- 3. OS support for App Control for Business ---
$os = Get-CimInstance Win32_OperatingSystem
$osOk = [version]$os.Version -ge [version]'10.0.18362'  # 1903+
Write-Host ("`n[WDAC] OS supported (1903+/Win11): {0}  ({1} {2})" -f $osOk, $os.Caption, $os.Version) -ForegroundColor ($(if($osOk){'Green'}else{'Yellow'}))

# --- 4. Current code-integrity enforcement state ---
try {
    $dg = Get-CimInstance -Namespace root\Microsoft\Windows\DeviceGuard -ClassName Win32_DeviceGuard -ErrorAction Stop
    $map = @{ 0='Off'; 1='Audit'; 2='Enforced' }
    Write-Host ("[WDAC] Code Integrity enforcement : {0}" -f $map[[int]$dg.CodeIntegrityPolicyEnforcementStatus])
    Write-Host ("[WDAC] UMCI enforcement           : {0}" -f $map[[int]$dg.UsermodeCodeIntegrityPolicyEnforcementStatus])
} catch { Write-Host "[WDAC] DeviceGuard WMI not available." -ForegroundColor Yellow }

# --- 5. Active App Control policies (Windows 11 citool) ---
$citool = "$env:WINDIR\System32\citool.exe"
if (Test-Path $citool) {
    Write-Host "`n[WDAC] Active App Control policies (citool):" -ForegroundColor Cyan
    & $citool --list-policies 2>$null | Select-String 'PolicyID|FriendlyName|IsEnforced' | ForEach-Object { Write-Host "  $($_.Line.Trim())" }
} else { Write-Host "`n[WDAC] (citool not present — Windows 10; use WDACMIG-Validation.ps1 for policy state.)" -ForegroundColor Gray }

# --- 6. Managed installer indication ---
$miReg = 'HKLM:\SYSTEM\CurrentControlSet\Control\CI\Protected'
Write-Host "`n[WDAC] Managed-installer / AppLocker AppID policy hint:" -ForegroundColor Cyan
if (Test-Path $miReg) { Write-Host "  CI Protected key present (managed-installer tagging likely configured)." -ForegroundColor Green }
else { Write-Host "  No CI Protected key — confirm managed installer is enabled in Intune App Control settings." -ForegroundColor Gray }

Write-Host "`nNext: translate the AppLocker rules above into the WDAC base policy, then deploy 'App Control - Fleet - Audit'." -ForegroundColor Gray
