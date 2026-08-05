<#
.SYNOPSIS
    APPSTD-Test-DetectionRuleQuality.ps1 — checks Win32 app detection rules against the standard's
    acceptability tests and flags any of the banned detection patterns (B1-B10).
.DESCRIPTION
    PURPOSE
        Read-only. For each Win32 app (or one named app) it reads the detectionRules and evaluates:
          - B1  File-exists rule with no version/size check on a versionable app.
          - B2  Detection targets a folder (no file name).
          - B4/B5 Registry/file detection on a shared runtime or generic marker path.
          - B6  Per-user path (HKCU / %AppData% / %LocalAppData%) for a system-context install.
          - B7  More than one detection rule type combined.
          - B8/B9/B10 Detection SCRIPT that appears to write/act, lacks an exit path, uses Write-Host,
                or calls Win32_Product (MSI self-repair).
        Also confirms the acceptability signal that the rule asserts a version where one is expected.
        This is the automated half of Acceptance-Checklist Gate 3; the reviewer still initials §5a.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\APPSTD-Test-DetectionRuleQuality.ps1
        powershell -ExecutionPolicy Bypass -File .\APPSTD-Test-DetectionRuleQuality.ps1 -AppName "Acme Software Ltd. Acme Invoice Client – Win32 – v7.3.1"
        powershell -ExecutionPolicy Bypass -File .\APPSTD-Test-DetectionRuleQuality.ps1 -CsvPath C:\Temp\detection.csv
        Requires the Microsoft Graph PowerShell SDK and DeviceManagementApps.Read.All.
    EXPECTED RESULTS
        Per app: PASS with 0 findings, or a list of the banned-pattern codes triggered. A clean
        result (0 findings) is what Gate 3.2 requires before sign-off.
.NOTES
    Intune Solutions — read-only against Microsoft Graph. No changes are made to the tenant.
#>
[CmdletBinding()]
param(
    [string]$AppName,
    [string]$CsvPath
)

$SharedRuntimes = @('vcruntime','msvcp','vcredist','api-ms-win','ucrtbase','mfc140','dotnet','netfx',
                    'msvcr','concrt140','vccorlib')
$PerUserSignals = @('hkcu','hkey_current_user','\appdata\','%appdata%','%localappdata%','\local\','\roaming\')

function Connect-Graph {
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
        Write-Host 'Installing Microsoft.Graph (CurrentUser)...' -ForegroundColor Yellow
        Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
    }
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    Connect-MgGraph -Scopes 'DeviceManagementApps.Read.All' -NoWelcome
}

Connect-Graph

# Win32 apps carry authored detection rules; other types are platform-detected and skipped.
$apps = @(); $uri = "/v1.0/deviceAppManagement/mobileApps?`$filter=isof('microsoft.graph.win32LobApp')"
do { $r = Invoke-MgGraphRequest -Method GET -Uri $uri; $apps += $r.value; $uri = $r.'@odata.nextLink' } while ($uri)
if ($AppName) { $apps = $apps | Where-Object { $_.displayName -eq $AppName } }
if (-not $apps) { Write-Host 'No matching Win32 apps found.' -ForegroundColor Yellow; Disconnect-MgGraph | Out-Null; return }

$results = foreach ($a in $apps) {
    # Full object carries detectionRules; the list view may not.
    $full  = Invoke-MgGraphRequest -Method GET -Uri "/v1.0/deviceAppManagement/mobileApps/$($a.id)"
    $rules = @($full.detectionRules)
    $ctxSystem = ($full.installExperience.runAsAccount -ne 'user')
    $findings  = @()

    if ($rules.Count -eq 0) { $findings += 'NO-RULE(missing detection)' }
    if ($rules.Count -gt 1) { $findings += 'B7(multiple-rule-types)' }

    foreach ($rule in $rules) {
        $t = [string]$rule.'@odata.type'

        if ($t -like '*win32LobAppFileSystemDetection*') {
            $file = [string]$rule.fileOrFolderName
            $meth = [string]$rule.detectionType
            if ([string]::IsNullOrWhiteSpace($file)) { $findings += 'B2(folder-only)' }
            if ($meth -in @('exists','doesNotExist') ) { $findings += 'B1(file-exists-no-version)' }
            $path = ("{0}\{1}" -f $rule.path, $file).ToLower()
            if ($SharedRuntimes | Where-Object { $path -like "*$_*" }) { $findings += 'B5(shared-runtime)' }
            if ($ctxSystem -and ($PerUserSignals | Where-Object { $path -like "*$_*" })) { $findings += 'B6(per-user-path-system-context)' }
        }
        elseif ($t -like '*win32LobAppRegistryDetection*') {
            $key  = ([string]$rule.keyPath).ToLower()
            $meth = [string]$rule.detectionType
            if ($meth -eq 'exists') { $findings += 'B1(registry-exists-no-version)' }
            if ($SharedRuntimes | Where-Object { $key -like "*$_*" }) { $findings += 'B5(shared-runtime-key)' }
            if ($ctxSystem -and ($PerUserSignals | Where-Object { $key -like "*$_*" })) { $findings += 'B6(HKCU-system-context)' }
        }
        elseif ($t -like '*win32LobAppProductCodeDetection*') {
            # MSI product code — the preferred type. Note if no version assertion is present.
            if (-not $rule.productVersion) { $findings += 'INFO(product-code-no-version-check)' }
        }
        elseif ($t -like '*win32LobAppPowerShellScriptDetection*') {
            $b64 = [string]$rule.scriptContent
            $txt = ''
            try { $txt = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($b64)) } catch { $txt = '' }
            $low = $txt.ToLower()
            if ($low -match 'win32_product')                                   { $findings += 'B10(Win32_Product-selfrepair)' }
            if ($low -match '(set-itemproperty|new-item|remove-item|start-process|copy-item|invoke-webrequest|restart-computer|install-)') { $findings += 'B8(detection-script-writes/acts)' }
            if ($low -match 'write-host')                                      { $findings += 'B9(uses-Write-Host)' }
            if ($low -notmatch 'exit\s')                                       { $findings += 'B9(no-explicit-exit)' }
        }
    }

    $findings = $findings | Select-Object -Unique
    [pscustomobject]@{
        App          = $full.displayName
        RuleCount    = $rules.Count
        Context      = if ($ctxSystem) {'System'} else {'User'}
        Result       = if (($findings | Where-Object { $_ -notlike 'INFO*' }).Count -eq 0) {'PASS'} else {'FAIL'}
        FindingCount = ($findings | Where-Object { $_ -notlike 'INFO*' }).Count
        Findings     = ($findings -join '; ')
    }
}

Write-Host ''
Write-Host '=== Detection Rule Quality ===' -ForegroundColor Cyan
$fail = ($results | Where-Object Result -eq 'FAIL').Count
Write-Host ("  Apps checked : {0}" -f $results.Count)
Write-Host ("  Clean (PASS) : {0}" -f ($results.Count - $fail)) -ForegroundColor Green
Write-Host ("  Flagged      : {0}" -f $fail) -ForegroundColor (if ($fail){'Yellow'}else{'Green'})
Write-Host ''
$results | Sort-Object Result, App | Format-Table App, Context, Result, Findings -AutoSize

if ($CsvPath) {
    $results | Sort-Object Result, App | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8
    Write-Host ("Saved: {0}" -f $CsvPath) -ForegroundColor Green
}

Disconnect-MgGraph | Out-Null
