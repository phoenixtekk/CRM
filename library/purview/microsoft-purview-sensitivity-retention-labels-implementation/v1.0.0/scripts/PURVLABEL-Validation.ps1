<#
.SYNOPSIS
    PURVLABEL-Validation.ps1 — read-only scope/config health helper: preview adaptive-scope membership and run a full label/policy health check.
.DESCRIPTION
    Two read-only modes. -ScopeName previews an adaptive scope's resolved membership so you can confirm
    it is non-empty and correctly targeted before binding it to a retention policy. -Full runs an
    end-to-end health check: sensitivity labels published, auto-labeling mode (simulation vs enforced),
    retention policies and their scope binding, and adaptive scopes present. Makes no changes.
.EXAMPLE
    .\PURVLABEL-Validation.ps1 -ScopeName "Scope - Users - Finance"
    Previews the membership the adaptive scope currently resolves.
.EXAMPLE
    .\PURVLABEL-Validation.ps1 -Full
    Runs the full label/policy/scope health check and prints a PASS/CHECK summary.
.NOTES
    Requires PowerShell 5.1+/7+ and ExchangeOnlineManagement (Connect-IPPSSession).
    Role: Information Protection / Records Management (read). Adaptive scopes are licensing-gated (verify your licensing/tenant).
    Expected results: PASS = scope resolves the expected non-empty membership / all health rows green.
    FAIL/CHECK = scope empty or too broad, a policy bound to the wrong scope, or auto-labeling enforcing
    before sign-off — investigate before expanding.
#>
[CmdletBinding(DefaultParameterSetName='Full')]
param(
    [Parameter(ParameterSetName='Scope')][string]$ScopeName,
    [Parameter(ParameterSetName='Full')][switch]$Full
)

Import-Module ExchangeOnlineManagement -ErrorAction Stop
if (-not (Get-Command Get-AdaptiveScope -ErrorAction SilentlyContinue)) {
    Connect-IPPSSession -ShowBanner:$false
}

if ($PSCmdlet.ParameterSetName -eq 'Scope') {
    if (-not $ScopeName) { throw 'Provide -ScopeName, or use -Full.' }
    Write-Host ("=== Adaptive scope membership preview: {0} ===" -f $ScopeName) -ForegroundColor Cyan
    $scope = Get-AdaptiveScope -Identity $ScopeName -ErrorAction SilentlyContinue
    if (-not $scope) { Write-Warning "Scope '$ScopeName' not found (or adaptive scopes not licensed)."; return }
    Write-Host ("LocationType : {0}" -f $scope.LocationType)
    Write-Host ("Query        : {0}" -f $scope.RawQuery)
    # Membership preview surfaces through the portal's scope preview and Get-AdaptiveScope reporting.
    # Where the cmdlet exposes a preview count, show it; otherwise direct to the portal (verify in tenant).
    if ($scope.PSObject.Properties.Name -contains 'CountOfObjects' -and $scope.CountOfObjects) {
        Write-Host ("Resolved objects: {0}" -f $scope.CountOfObjects) -ForegroundColor Cyan
        if ([int]$scope.CountOfObjects -eq 0) { Write-Host 'CHECK: scope resolves 0 objects — verify the query attribute is populated (Req 2.7).' -ForegroundColor Yellow }
        else { Write-Host 'PASS: scope resolves a non-empty membership.' -ForegroundColor Green }
    } else {
        Write-Host 'Preview membership in the portal: Data Lifecycle Management -> Adaptive scopes -> ' -NoNewline
        Write-Host "'$ScopeName' -> preview (portal path version-sensitive — verify in your tenant)." -ForegroundColor DarkGray
    }
    return
}

# --- Full health check ---
Write-Host '=== PURVLABEL full health check (read-only) ===' -ForegroundColor Cyan
$rows = @()
function Add-Row($area,$item,$status,$note){ $script:rows += [pscustomobject]@{ Area=$area; Item=$item; Status=$status; Note=$note } }

# Sensitivity label policies published
foreach ($p in (Get-LabelPolicy -ErrorAction SilentlyContinue)) {
    $status = if ($p.Enabled) { 'PASS' } else { 'CHECK' }
    Add-Row 'Sensitivity' $p.Name $status ("Mode={0}; Labels={1}" -f $p.Mode, (($p.Labels) -join ','))
}
# Auto-labeling mode (simulation vs enforced)
foreach ($a in (Get-AutoSensitivityLabelPolicy -ErrorAction SilentlyContinue)) {
    $status = if ($a.Mode -eq 'Enable') { 'ENFORCING' } elseif ($a.Mode -like 'Test*') { 'SIMULATION' } else { $a.Mode }
    Add-Row 'Auto-label' $a.Name $status ("ApplyLabel={0}" -f $a.ApplySensitivityLabel)
}
# Retention policies + scope binding
foreach ($r in (Get-RetentionCompliancePolicy -ErrorAction SilentlyContinue)) {
    $scopeKind = if ($r.IsAdaptiveScopeSelected) { 'Adaptive' } else { 'Static' }
    $status = if ($r.Enabled) { 'PASS' } else { 'CHECK' }
    Add-Row 'Retention' $r.Name $status ("Scope={0}; Mode={1}" -f $scopeKind, $r.Mode)
}
# Adaptive scopes present
foreach ($s in (Get-AdaptiveScope -ErrorAction SilentlyContinue)) {
    Add-Row 'AdaptiveScope' $s.Name 'INFO' ("LocationType={0}" -f $s.LocationType)
}

if ($rows.Count -eq 0) { Write-Host 'No label/policy/scope objects found (or features not licensed — verify your licensing/tenant).' -ForegroundColor Yellow }
else { $rows | Format-Table -AutoSize }

$enforcing = @($rows | Where-Object { $_.Status -eq 'ENFORCING' })
if ($enforcing.Count) {
    Write-Host "`nNOTE: the following auto-labeling policies are ENFORCING — confirm each passed simulation precision sign-off (Testing Guide Test 6/7):" -ForegroundColor Yellow
    $enforcing | ForEach-Object { Write-Host ("  - {0}" -f $_.Item) -ForegroundColor Yellow }
}
Write-Host "`n=== Health check complete (no changes made) ===" -ForegroundColor Green
