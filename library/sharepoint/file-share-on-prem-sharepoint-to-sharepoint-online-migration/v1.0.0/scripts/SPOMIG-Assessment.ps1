<#
.SYNOPSIS
    SPOMIG-Assessment.ps1 — read-only source assessment for a file share migrating to SharePoint Online.
.DESCRIPTION
    Scans a file share (UNC or local path) for the blockers that fail SPO migrations: path/URL length
    approaching the limit, invalid characters and reserved names, blocked file types, oversized files,
    and deep nesting; and summarizes the permission surface (distinct principals across the NTFS ACLs).
    The current SPO limits are PASSED IN as parameters so the check tracks Microsoft's real, current
    numbers (verify them in Microsoft's SharePoint limits docs for your cloud). Read-only — changes
    nothing. Emits the report "Source Assessment - FileShare+SP - Discovery".
.EXAMPLE
    .\SPOMIG-Assessment.ps1 -Path \\fs01\Finance -MaxUrlLength 400 -MaxFileSizeGB 250 -CsvPath .\SourceAssessment.csv
    # dry-run by nature (read-only); PowerShell 5.1+/7+. No SPO connection needed to assess a file share.
.NOTES
    Expected results: a console summary (counts of each blocker type + distinct principals) and, with
    -CsvPath, a per-flagged-item CSV. Zero data is modified. Limit values default to commonly cited
    figures but SHOULD be overridden with the values you confirmed for your tenant/cloud.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$Path,
    # SPO service limits — override with the CURRENT documented values for your cloud (Commercial vs Government differ).
    [int]$MaxUrlLength = 400,          # decoded URL/path length limit (verify in Microsoft docs)
    [int]$MaxSegmentLength = 255,      # single file/folder name length
    [double]$MaxFileSizeGB = 250,      # per-file size limit (verify in Microsoft docs)
    [string]$TargetBaseUrl = 'https://contoso.sharepoint.com/sites/Target/Shared Documents',
    [string]$CsvPath
)

if (-not (Test-Path -LiteralPath $Path)) { throw "Source path not found or not accessible: $Path" }

# SPO-invalid characters and reserved leaf names (verify current list in Microsoft docs).
$invalidChars   = '["*:<>?/\|]'
$reservedNames  = @('.lock','CON','PRN','AUX','NUL','COM1','COM2','COM3','COM4','COM5','COM6','COM7','COM8','COM9',
                    'LPT1','LPT2','LPT3','LPT4','LPT5','LPT6','LPT7','LPT8','LPT9','_vti_','desktop.ini')
$blockedExt     = @('.tmp','.ds_store','.pst')   # example set — confirm your tenant's blocked-file-type policy
$maxFileBytes   = [int64]($MaxFileSizeGB * 1GB)
$rootLen        = ($Path.TrimEnd('\')).Length

Write-Host ("=== Source Assessment - FileShare+SP - Discovery ===") -ForegroundColor Cyan
Write-Host ("Source: {0}" -f $Path)
Write-Host ("Limits: UrlLen<={0}  SegLen<={1}  FileSize<={2}GB" -f $MaxUrlLength,$MaxSegmentLength,$MaxFileSizeGB)

$flagged   = New-Object System.Collections.Generic.List[object]
$principals = New-Object System.Collections.Generic.HashSet[string]
$total = 0

Get-ChildItem -LiteralPath $Path -Recurse -Force -ErrorAction SilentlyContinue | ForEach-Object {
    $total++
    $item = $_
    # Projected SPO URL length = target base + relative path (with spaces URL-encoded as %20, +2 per space).
    $rel  = $item.FullName.Substring($rootLen)
    $projected = $TargetBaseUrl.Length + $rel.Length + (([regex]::Matches($rel,' ')).Count * 2)
    $reasons = @()
    if ($projected -gt $MaxUrlLength)            { $reasons += "UrlLen($projected)" }
    if ($item.Name.Length -gt $MaxSegmentLength) { $reasons += "SegLen($($item.Name.Length))" }
    if ($item.Name -match $invalidChars)         { $reasons += 'InvalidChar' }
    if ($item.Name.EndsWith(' ') -or $item.Name.EndsWith('.')) { $reasons += 'TrailingSpaceOrDot' }
    if ($reservedNames -contains $item.Name -or ($reservedNames | Where-Object { $item.Name -like "$_*" })) { $reasons += 'ReservedName' }
    if (-not $item.PSIsContainer) {
        if ($blockedExt -contains $item.Extension.ToLower()) { $reasons += "BlockedType($($item.Extension))" }
        if ($item.Length -gt $maxFileBytes) { $reasons += "Oversize($([math]::Round($item.Length/1GB,1))GB)" }
    }
    # Permission surface: collect distinct principals from explicit (non-inherited) ACEs.
    try {
        $acl = Get-Acl -LiteralPath $item.FullName -ErrorAction Stop
        foreach ($ace in $acl.Access) { if (-not $ace.IsInherited) { [void]$principals.Add($ace.IdentityReference.Value) } }
    } catch { }

    if ($reasons.Count -gt 0) {
        $flagged.Add([pscustomobject]@{
            FullName      = $item.FullName
            Type          = if ($item.PSIsContainer) {'Folder'} else {'File'}
            ProjectedUrlLen = $projected
            Reasons       = ($reasons -join '; ')
        })
    }
}

Write-Host ("--- Scanned {0} items; {1} flagged; {2} distinct explicit principals ---" -f $total,$flagged.Count,$principals.Count) -ForegroundColor Cyan
$flagged | Group-Object { ($_.Reasons -split ';')[0].Trim() } |
    Sort-Object Count -Descending | Select-Object Count, @{n='TopReason';e={$_.Name}} | Format-Table -AutoSize

if ($CsvPath) {
    $flagged | Export-Csv -LiteralPath $CsvPath -NoTypeInformation
    Write-Host ("Saved 'Source Assessment - FileShare+SP - Discovery' to {0}" -f $CsvPath) -ForegroundColor Green
    Write-Host ("Distinct principals: {0}" -f (($principals) -join ', ')) -ForegroundColor DarkGray
}
if ($flagged.Count -eq 0) { Write-Host 'No blockers found against the supplied limits — proceed to design.' -ForegroundColor Green }
else { Write-Host 'Blockers found — build the Remediation Plan - Source - PreMigration before migrating.' -ForegroundColor Yellow }
