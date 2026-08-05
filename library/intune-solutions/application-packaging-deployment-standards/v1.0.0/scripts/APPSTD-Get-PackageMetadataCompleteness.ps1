<#
.SYNOPSIS
    APPSTD-Get-PackageMetadataCompleteness.ps1 — scores each app's metadata completeness against the
    packaging specification (publisher, category, standardised description, owner/developer, info URL,
    logo) and reports a 0-100 score per app.
.DESCRIPTION
    PURPOSE
        Read-only. For every managed Windows app it scores the metadata fields the standard requires
        before release (Implementation Step 4d):
          - Publisher present and not a placeholder            (weight 20)
          - App category assigned                              (weight 20)
          - Description has the three mandatory lines          (weight 25)
              Business purpose: / Business owner: / Package record:
          - Developer (packager) set                           (weight 10)
          - Owner (business owner) set                         (weight 10)
          - Information URL set                                (weight 10)
          - Logo/icon present                                  (weight  5)
        Apps scoring below -MinimumScore are listed for remediation. Feed the CSV to
        APPSTD-Set-AppMetadataStandard.ps1 to normalise the mechanical gaps.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\APPSTD-Get-PackageMetadataCompleteness.ps1
        powershell -ExecutionPolicy Bypass -File .\APPSTD-Get-PackageMetadataCompleteness.ps1 -MinimumScore 100 -CsvPath C:\Temp\metadata.csv
        Requires the Microsoft Graph PowerShell SDK and DeviceManagementApps.Read.All.
    EXPECTED RESULTS
        A per-app score table and a list of apps below the threshold, plus a CSV for remediation.
        Nothing is changed — read-only.
.NOTES
    Intune Solutions — read-only against Microsoft Graph. No changes are made to the tenant.
#>
[CmdletBinding()]
param(
    [ValidateRange(0,100)][int]$MinimumScore = 100,
    [string]$CsvPath
)

$BadPublishers = @('', 'it', 'unknown', 'n/a', 'na', 'tbd', 'publisher', 'company', 'default')

function Connect-Graph {
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
        Write-Host 'Installing Microsoft.Graph (CurrentUser)...' -ForegroundColor Yellow
        Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
    }
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    Connect-MgGraph -Scopes 'DeviceManagementApps.Read.All' -NoWelcome
}

Connect-Graph

$apps = @(); $uri = '/v1.0/deviceAppManagement/mobileApps?$top=100&$expand=categories'
do { $r = Invoke-MgGraphRequest -Method GET -Uri $uri; $apps += $r.value; $uri = $r.'@odata.nextLink' } while ($uri)
$wanted = @('win32','winGet','windowsMsi','StoreForBusiness','UniversalAppX','MobileMSI')
$apps = $apps | Where-Object { $t = $_.'@odata.type'; $wanted | Where-Object { $t -like "*$_*" } }
if (-not $apps) { Write-Host 'No matching Windows apps found.' -ForegroundColor Yellow; Disconnect-MgGraph | Out-Null; return }

$rows = foreach ($a in $apps) {
    $pub   = ([string]$a.publisher).Trim()
    $desc  = [string]$a.description
    $lines = $desc -split "`r?`n"
    $hasPurpose = [bool]($lines -match '^\s*Business purpose\s*:\s*\S')
    $hasOwner   = [bool]($lines -match '^\s*Business owner\s*:\s*\S')
    $hasRecord  = [bool]($lines -match '^\s*Package record\s*:\s*\S')
    $cats  = @($a.categories) | ForEach-Object { $_.displayName }

    $score = 0; $gaps = @()
    if ($BadPublishers -notcontains $pub.ToLower()) { $score += 20 } else { $gaps += 'publisher' }
    if ($cats.Count -gt 0)                          { $score += 20 } else { $gaps += 'category' }
    if ($hasPurpose -and $hasOwner -and $hasRecord) { $score += 25 } else { $gaps += 'description-3-lines' }
    if (-not [string]::IsNullOrWhiteSpace([string]$a.developer)) { $score += 10 } else { $gaps += 'developer' }
    if (-not [string]::IsNullOrWhiteSpace([string]$a.owner))     { $score += 10 } else { $gaps += 'owner' }
    if (-not [string]::IsNullOrWhiteSpace([string]$a.informationUrl)) { $score += 10 } else { $gaps += 'information-url' }
    if ($a.largeIcon -and $a.largeIcon.value)       { $score += 5 }  else { $gaps += 'logo' }

    [pscustomobject]@{
        App          = $a.displayName
        Score        = $score
        Publisher    = if ($BadPublishers -notcontains $pub.ToLower()) {'ok'} else {"MISSING:'$pub'"}
        Category     = if ($cats.Count) { ($cats -join ',') } else {'MISSING'}
        Description  = if ($hasPurpose -and $hasOwner -and $hasRecord) {'ok'} else {'NON-STANDARD'}
        Developer    = if ($a.developer) {'ok'} else {'MISSING'}
        Owner        = if ($a.owner) {'ok'} else {'MISSING'}
        Gaps         = ($gaps -join '; ')
    }
}

$avg = if ($rows.Count) { [math]::Round(($rows | Measure-Object Score -Average).Average,1) } else { 0 }
Write-Host ''
Write-Host '=== Package Metadata Completeness ===' -ForegroundColor Cyan
Write-Host ("  Apps scored   : {0}" -f $rows.Count)
Write-Host ("  Average score : {0}/100" -f $avg) -ForegroundColor (if ($avg -ge 90){'Green'}elseif($avg -ge 70){'Yellow'}else{'Red'})
Write-Host ("  Below {0}      : {1}" -f $MinimumScore, ($rows | Where-Object { $_.Score -lt $MinimumScore }).Count)
Write-Host ''
$rows | Where-Object { $_.Score -lt $MinimumScore } | Sort-Object Score |
    Format-Table App, Score, Gaps -AutoSize

if ($CsvPath) {
    $rows | Sort-Object Score, App | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8
    Write-Host ("Saved: {0}" -f $CsvPath) -ForegroundColor Green
}

Disconnect-MgGraph | Out-Null
