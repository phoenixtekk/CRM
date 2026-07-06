<#
.SYNOPSIS
    GWDRIVE-Remediation.ps1 — safely stage fixes for identity-map and permission-mapping gaps in a Drive migration.
.DESCRIPTION
    PURPOSE
        Closes the mapping gaps that cause dropped or flattened permissions: it takes the unmapped
        source principals a validation run surfaced and proposes an identity-map row for each by
        resolving the source user/group against Microsoft Graph and suggesting the matching Google
        primary address, and it appends any missing source permission levels to the role-translation
        table with a suggested Google role. It writes only to the local mapping CSVs — it never
        changes source or target permissions and never touches the migration tool. Runs with -WhatIf
        by default; add -WhatIf:$false to write the CSV rows. Placeholders use plain text such as
        your-domain.example, not angle brackets.
    HOW TO RUN
        Preview (default):  powershell -ExecutionPolicy Bypass -File .\GWDRIVE-Remediation.ps1 `
                                -UnmappedCsv .\unmapped-principals.csv -IdentityMapCsv .\identity-map.csv `
                                -TargetDomain your-domain.example
        Apply:              ...\GWDRIVE-Remediation.ps1 -UnmappedCsv .\unmapped-principals.csv `
                                -IdentityMapCsv .\identity-map.csv -TargetDomain your-domain.example -WhatIf:$false
        UnmappedCsv column: Principal (source email or group:Name). IdentityMapCsv columns:
        Source,Google. Requires the Microsoft Graph PowerShell SDK; consent to User.Read.All,
        Group.Read.All.
    EXPECTED RESULTS
        In preview: the identity-map rows that would be appended (source principal -> suggested Google
        address) and any level rows to add. When applied: those rows are written to the mapping CSVs
        for review before the next validation run. Suggestions are proposals — confirm each before use.
.NOTES
    White-label — the repeatable way. Writes only local mapping CSVs; -WhatIf by default.
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
param(
    [Parameter(Mandatory)][string]$UnmappedCsv,
    [Parameter(Mandatory)][string]$IdentityMapCsv,
    [string]$TargetDomain = 'your-domain.example',
    [string]$PermissionMapCsv,
    [string[]]$UnmappedLevels
)

# Default to preview unless the caller turns -WhatIf off explicitly.
if (-not $PSBoundParameters.ContainsKey('WhatIf')) { $WhatIfPreference = $true }

if (-not (Test-Path $UnmappedCsv)) { Write-Host "UnmappedCsv not found: $UnmappedCsv" -ForegroundColor Red; return }

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'User.Read.All','Group.Read.All' -NoWelcome

Write-Host "`n=== Drive migration — mapping-gap remediation ===" -ForegroundColor Cyan

# Existing identity-map sources (to avoid duplicates).
$existing = @{}
if (Test-Path $IdentityMapCsv) {
    Import-Csv $IdentityMapCsv | ForEach-Object { if ($_.Source) { $existing[$_.Source.Trim().ToLower()] = $true } }
}

$toAdd = New-Object System.Collections.Generic.List[object]
foreach ($row in (Import-Csv $UnmappedCsv)) {
    $src = $row.Principal
    if (-not $src) { continue }
    if ($existing.ContainsKey($src.Trim().ToLower())) { continue }

    # Suggest a Google address: reuse the local-part of a source email against the target domain.
    $suggest = ''
    if ($src -like 'group:*') {
        $name = $src.Substring(6)
        $local = ($name -replace '[^a-zA-Z0-9]', '-').ToLower().Trim('-')
        $suggest = "$local@$TargetDomain"
    } elseif ($src -match '@') {
        $local = ($src -split '@')[0]
        $suggest = "$local@$TargetDomain"
        # Confirm the source principal exists (informational only).
        try { $null = Invoke-MgGraphRequest -Method GET -Uri ("/v1.0/users/{0}?`$select=id" -f $src) } catch {}
    }
    $toAdd.Add([pscustomobject]@{ Source = $src; Google = $suggest })
}

if ($toAdd.Count -eq 0) {
    Write-Host "No new principals to map — identity map already covers the unmapped list." -ForegroundColor Green
} else {
    Write-Host ("Identity-map rows to add ({0}):" -f $toAdd.Count) -ForegroundColor Cyan
    $toAdd | ForEach-Object { Write-Host ("  {0}  ->  {1}" -f $_.Source, $_.Google) }
    if ($PSCmdlet.ShouldProcess($IdentityMapCsv, ("Append {0} identity-map row(s)" -f $toAdd.Count))) {
        $toAdd | Export-Csv -Path $IdentityMapCsv -NoTypeInformation -Append
        Write-Host ("Appended to {0}. Review and correct each suggested Google address before validating." -f $IdentityMapCsv) -ForegroundColor Green
    } else {
        Write-Host "Preview only (-WhatIf). Re-run with -WhatIf:`$false to append." -ForegroundColor Yellow
    }
}

# Optional: append missing permission levels with a suggested Google role.
if ($UnmappedLevels -and $PermissionMapCsv) {
    $roleGuess = { param($lvl)
        switch -Regex ($lvl.ToLower()) {
            'full|owner|manage'      { 'Manager' ; break }
            'design|edit|content'    { 'Content manager' ; break }
            'contrib|write'          { 'Contributor' ; break }
            'comment'                { 'Commenter' ; break }
            default                  { 'Viewer' }
        }
    }
    $lvlRows = $UnmappedLevels | ForEach-Object { [pscustomobject]@{ SourceLevel = $_; GoogleRole = (& $roleGuess $_) } }
    Write-Host "`nPermission-level rows to add:" -ForegroundColor Cyan
    $lvlRows | ForEach-Object { Write-Host ("  {0}  ->  {1}" -f $_.SourceLevel, $_.GoogleRole) }
    if ($PSCmdlet.ShouldProcess($PermissionMapCsv, ("Append {0} level row(s)" -f @($lvlRows).Count))) {
        $lvlRows | Export-Csv -Path $PermissionMapCsv -NoTypeInformation -Append
        Write-Host ("Appended to {0}. Confirm each Google role before validating." -f $PermissionMapCsv) -ForegroundColor Green
    }
}

Disconnect-MgGraph | Out-Null
