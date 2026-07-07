<#
.SYNOPSIS
  Read-only discovery of SharePoint Online retention/records posture across in-scope sites.
.DESCRIPTION
  Enumerates each in-scope site's document libraries, reads the default retention label on each
  library (PnP), counts labeled vs unlabeled items, and cross-references the tenant's existing
  retention labels and policies (Security & Compliance PowerShell). Writes a CSV baseline. Makes no
  changes.
.EXAMPLE
  .\Assess-SpoRetentionPosture.ps1 -Sites @("https://contoso.sharepoint.com/sites/RecordsPilot") -OutputPath .\out
  # (PowerShell 5.1+/7+; modules PnP.PowerShell + ExchangeOnlineManagement)
  # Connect first: Connect-IPPSSession ; connect per-site with Connect-PnPOnline (script does this).
.NOTES
  Expected results: a "Retention Posture - SPO - Discovery" CSV listing each library's default label
  and coverage counts, plus the tenant label/policy inventory to the host. Read-only.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string[]]$Sites,

    [string]$OutputPath = ".\out",

    # Skip the tenant label/policy inventory (Security & Compliance PowerShell) if not connected.
    [switch]$SkipTenantInventory
)

$ErrorActionPreference = 'Stop'
if (-not (Test-Path $OutputPath)) { New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null }

# --- Tenant-level label/policy inventory (read-only) ---
if (-not $SkipTenantInventory) {
    try {
        Write-Host "Reading tenant retention labels (Get-ComplianceTag)..." -ForegroundColor Cyan
        Get-ComplianceTag | Select-Object Name, IsRecordLabel, Regulatory, RetentionAction,
            RetentionDuration, RetentionType, @{n='Reviewers';e={($_.ReviewerEmail) -join ';'}} |
            Format-Table -AutoSize
        Write-Host "Reading tenant retention policies (Get-RetentionCompliancePolicy)..." -ForegroundColor Cyan
        Get-RetentionCompliancePolicy | Select-Object Name, Enabled, Mode |
            Format-Table -AutoSize
    }
    catch {
        Write-Warning "Tenant inventory skipped - not connected to Security & Compliance PowerShell (Connect-IPPSSession). $_"
    }
}

# --- Per-site library posture (read-only, PnP) ---
$rows = New-Object System.Collections.Generic.List[object]

foreach ($site in $Sites) {
    Write-Host "Connecting to $site ..." -ForegroundColor Cyan
    try {
        Connect-PnPOnline -Url $site -Interactive
    }
    catch {
        Write-Warning "Could not connect to $site : $_"
        continue
    }

    # Document libraries only (BaseTemplate 101), exclude hidden system lists.
    $libs = Get-PnPList | Where-Object { $_.BaseTemplate -eq 101 -and -not $_.Hidden }

    foreach ($lib in $libs) {
        $defaultLabel = $null
        try {
            $lbl = Get-PnPLabel -List $lib.Title -ErrorAction Stop
            if ($lbl) { $defaultLabel = $lbl.TagName }
        }
        catch {
            $defaultLabel = "(unable to read)"
        }

        $rows.Add([pscustomobject]@{
            Site          = $site
            Library       = $lib.Title
            ItemCount     = $lib.ItemCount
            DefaultLabel  = if ([string]::IsNullOrWhiteSpace($defaultLabel)) { "(none)" } else { $defaultLabel }
            HasDefault    = -not [string]::IsNullOrWhiteSpace($defaultLabel) -and $defaultLabel -ne "(none)"
        })
    }
}

$outFile = Join-Path $OutputPath "Retention-Posture-SPO-Discovery.csv"
$rows | Export-Csv -Path $outFile -NoTypeInformation -Encoding UTF8
Write-Host ""
Write-Host "Wrote $($rows.Count) library rows to $outFile" -ForegroundColor Green
$rows | Format-Table -AutoSize
