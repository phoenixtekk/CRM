<#
.SYNOPSIS
    GWGMAIL-Remediation.ps1 — safe remediation of migration data gaps in a batch members list.
.DESCRIPTION
    PURPOSE
        Cleans common data-quality gaps that block a batch from passing validation, working only on a
        local members/coverage CSV — never on tenant data, mail flow, or money. It flags duplicate
        UPNs, blank UPN rows, and (when a source is reachable) UPNs that do not resolve in the
        Microsoft 365 source, and it builds a re-queue list of users still missing a data type from an
        optional coverage CSV. When applied it writes a normalized, de-duplicated members CSV. Runs
        with -WhatIf by default, so it only reports unless you explicitly turn -WhatIf off.
    HOW TO RUN
        Preview (default):  powershell -ExecutionPolicy Bypass -File .\GWGMAIL-Remediation.ps1 `
                                -MembersCsv .\batch.csv
        Apply:              ...\GWGMAIL-Remediation.ps1 -MembersCsv .\batch.csv `
                                -OutputPath .\batch.clean.csv -CoverageCsv .\gwgmail-coverage.csv -Resolve -WhatIf:$false
        -Resolve additionally checks each UPN against the source tenant (needs the Microsoft Graph SDK
        and User.Read.All). -CoverageCsv (columns Upn, Mail, Calendar, Contacts) produces a re-queue
        list of users missing a data type. Without -Resolve, only local de-duplication and blank checks run.
    EXPECTED RESULTS
        In preview: a list of duplicate/blank (and, with -Resolve, unresolved) UPNs and the re-queue
        list, with what would change. When applied: a cleaned members CSV at -OutputPath (duplicates
        collapsed, blanks dropped), leaving the original untouched.
.NOTES
    White-label — the repeatable way. Local-file only unless -Resolve is used; -WhatIf by default.
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
param(
    [Parameter(Mandatory)][string]$MembersCsv,
    [string]$OutputPath,
    [string]$CoverageCsv,
    [switch]$Resolve
)

# Default to preview unless the caller turns -WhatIf off explicitly.
if (-not $PSBoundParameters.ContainsKey('WhatIf')) { $WhatIfPreference = $true }

if (-not (Test-Path $MembersCsv)) { throw "Members CSV not found: $MembersCsv" }
$rows = @(Import-Csv -Path $MembersCsv)
Write-Host "=== Exchange to Gmail — batch members remediation ===" -ForegroundColor Cyan
Write-Host ("Loaded {0} rows from {1}" -f $rows.Count, $MembersCsv)

# Blank UPN rows
$blank = $rows | Where-Object { -not $_.Upn -or $_.Upn.Trim() -eq '' }
Write-Host ("Rows with blank UPN        : {0}" -f @($blank).Count) -ForegroundColor ($(if($blank){'Yellow'}else{'Green'}))

# Duplicate UPNs
$dupGroups = $rows | Where-Object { $_.Upn } | Group-Object { $_.Upn.ToLower() } | Where-Object { $_.Count -gt 1 }
Write-Host ("Duplicate UPN groups       : {0}" -f @($dupGroups).Count) -ForegroundColor ($(if($dupGroups){'Yellow'}else{'Green'}))
foreach ($g in $dupGroups) { Write-Host ("  - {0}  (x{1})" -f $g.Name, $g.Count) -ForegroundColor Yellow }

# Optional: unresolved UPNs against the source tenant
$unresolved = @()
if ($Resolve) {
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
        Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
    }
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    Connect-MgGraph -Scopes 'User.Read.All' -NoWelcome
    foreach ($r in ($rows | Where-Object { $_.Upn })) {
        try { $null = Invoke-MgGraphRequest -Method GET -Uri ("/v1.0/users/{0}?`$select=id" -f $r.Upn) }
        catch { $unresolved += $r.Upn }
    }
    Disconnect-MgGraph | Out-Null
    Write-Host ("Unresolved UPNs (source)   : {0}" -f @($unresolved).Count) -ForegroundColor ($(if($unresolved){'Yellow'}else{'Green'}))
    foreach ($u in $unresolved) { Write-Host ("  - {0}" -f $u) -ForegroundColor Yellow }
}

# Optional: re-queue list of users still missing a data type (from a coverage CSV)
if ($CoverageCsv) {
    if (Test-Path $CoverageCsv) {
        function Test-Yes { param($v) return ($v -and ($v.Trim().ToLower() -in @('yes','y','true','1','complete','done'))) }
        $cov = @(Import-Csv -Path $CoverageCsv | Where-Object { $_.Upn })
        $reQueue = $cov | Where-Object { -not ((Test-Yes $_.Mail) -and (Test-Yes $_.Calendar) -and (Test-Yes $_.Contacts)) }
        Write-Host ("Re-queue (missing a type)  : {0}" -f @($reQueue).Count) -ForegroundColor ($(if($reQueue){'Yellow'}else{'Green'}))
        foreach ($u in $reQueue) {
            $miss = @()
            if (-not (Test-Yes $u.Mail))     { $miss += 'mail' }
            if (-not (Test-Yes $u.Calendar)) { $miss += 'calendar' }
            if (-not (Test-Yes $u.Contacts)) { $miss += 'contacts' }
            Write-Host ("  - {0}  (missing: {1})" -f $u.Upn, ($miss -join ', ')) -ForegroundColor Yellow
        }
    } else {
        Write-Host ("Coverage CSV not found: {0}" -f $CoverageCsv) -ForegroundColor Yellow
    }
}

# Build a cleaned set: drop blanks, keep the first row per lower-cased UPN.
$clean = $rows |
    Where-Object { $_.Upn -and $_.Upn.Trim() -ne '' } |
    Group-Object { $_.Upn.ToLower() } |
    ForEach-Object { $_.Group | Select-Object -First 1 }

if (-not $OutputPath) { $OutputPath = [System.IO.Path]::ChangeExtension($MembersCsv, 'clean.csv') }

if ($PSCmdlet.ShouldProcess($OutputPath, "Write cleaned members list ($(@($clean).Count) rows, duplicates collapsed, blanks dropped)")) {
    $clean | Export-Csv -Path $OutputPath -NoTypeInformation
    Write-Host ("Wrote cleaned members list: {0} ({1} rows)" -f $OutputPath, @($clean).Count) -ForegroundColor Green
    if ($unresolved.Count -gt 0) { Write-Host "Resolve the unresolved UPNs above before running the batch." -ForegroundColor Cyan }
} else {
    Write-Host "`nPreview only (-WhatIf). Re-run with -WhatIf:`$false to write the cleaned members list." -ForegroundColor Cyan
}
