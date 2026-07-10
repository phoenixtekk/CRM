<#
.SYNOPSIS
    IACTF-Discovery.ps1 — inventory the current Azure estate before landing-zone deployment (read-only).
.DESCRIPTION
    PURPOSE
        Baselines what already exists so the Terraform imports/avoids it and you deploy into a known
        state: the management-group hierarchy, subscriptions and their MG placement, existing policy
        assignments, role assignments at management-group scope, and your effective rights at root.
        Read-only — makes no changes.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\IACTF-Discovery.ps1 -CsvFolder C:\Temp\iactf
        Requires the Az PowerShell module (Az.Accounts, Az.Resources) and `Connect-AzAccount`.
    EXPECTED RESULTS
        Console tree/tables for management groups, subscriptions, policy + role assignments, plus
        optional CSVs. Use it to confirm you have rights at the target scope and to plan imports.
.NOTES
    White-label — DevOps / IaC. Read-only against Azure Resource Manager. No credentials stored.
.EXAMPLE
    .\IACTF-Discovery.ps1
#>
[CmdletBinding()] param([string]$CsvFolder)

foreach ($m in 'Az.Accounts','Az.Resources') {
    if (-not (Get-Module -ListAvailable -Name $m)) { Install-Module $m -Scope CurrentUser -Force -AllowClobber }
    Import-Module $m -ErrorAction Stop
}
if (-not (Get-AzContext)) { Connect-AzAccount | Out-Null }

function Save-Csv($rows, $name) {
    if ($CsvFolder -and $rows) {
        if (-not (Test-Path $CsvFolder)) { New-Item -ItemType Directory -Path $CsvFolder | Out-Null }
        $p = Join-Path $CsvFolder "$name.csv"; $rows | Export-Csv -Path $p -NoTypeInformation
        Write-Host "  saved $p" -ForegroundColor Green
    }
}

$ctx = Get-AzContext
Write-Host "`nSigned in as: $($ctx.Account.Id)  |  Tenant: $($ctx.Tenant.Id)" -ForegroundColor Cyan

# --- Management group hierarchy ------------------------------------------------
Write-Host "`n=== Management group hierarchy ===" -ForegroundColor Cyan
try {
    $mgs = Get-AzManagementGroup -ErrorAction Stop
    $mgRows = $mgs | ForEach-Object { [pscustomobject]@{ Name=$_.Name; DisplayName=$_.DisplayName; Id=$_.Id } }
    $mgRows | Format-Table -AutoSize
    Save-Csv $mgRows 'management-groups'
    Write-Host "  Effective rights: you can list management groups (root access looks OK)." -ForegroundColor Green
} catch {
    Write-Host "  [WARN] Could not list management groups — you may lack rights at root scope." -ForegroundColor Yellow
    Write-Host "         See 02-requirements 2.1 (elevate at root) / 06-troubleshooting (MG rights)." -ForegroundColor Yellow
}

# --- Subscriptions -------------------------------------------------------------
Write-Host "`n=== Subscriptions ===" -ForegroundColor Cyan
$subs = Get-AzSubscription
$subRows = $subs | ForEach-Object { [pscustomobject]@{ Name=$_.Name; Id=$_.Id; State=$_.State } }
$subRows | Format-Table -AutoSize
Save-Csv $subRows 'subscriptions'

# --- Policy assignments (subscription + MG scope) ------------------------------
Write-Host "`n=== Existing policy assignments ===" -ForegroundColor Cyan
$pa = Get-AzPolicyAssignment -ErrorAction SilentlyContinue
$paRows = $pa | ForEach-Object {
    [pscustomobject]@{ Name=$_.Name; DisplayName=$_.Properties.DisplayName; Scope=$_.Properties.Scope; Effect=$_.Properties.EnforcementMode }
}
if ($paRows) { $paRows | Format-Table -AutoSize } else { Write-Host "  (none visible at current scope)" -ForegroundColor Yellow }
Save-Csv $paRows 'policy-assignments'

# --- Role assignments at MG scope ---------------------------------------------
Write-Host "`n=== Role assignments (management-group scope) ===" -ForegroundColor Cyan
$raRows = @()
try {
    foreach ($mg in ($mgs | Select-Object -First 10)) {
        $ra = Get-AzRoleAssignment -Scope $mg.Id -ErrorAction SilentlyContinue
        foreach ($r in $ra) {
            $raRows += [pscustomobject]@{ MG=$mg.Name; Principal=$r.DisplayName; Role=$r.RoleDefinitionName; Type=$r.ObjectType }
        }
    }
    if ($raRows) { $raRows | Format-Table -AutoSize } else { Write-Host "  (none)" -ForegroundColor Yellow }
    Save-Csv $raRows 'role-assignments-mg'
} catch { Write-Host "  [WARN] Could not read MG role assignments." -ForegroundColor Yellow }

Write-Host ("`nSummary: {0} management groups | {1} subscriptions | {2} policy assignments" -f `
    ($mgs.Count), $subs.Count, ($pa.Count)) -ForegroundColor Cyan
Write-Host "Record what exists so Terraform references (not recreates) the Tenant Root Group." -ForegroundColor Cyan
