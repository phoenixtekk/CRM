<#
.SYNOPSIS
    CAIG-Validation.ps1 — validate device readiness + break-glass exclusions on GCC High.
.DESCRIPTION
    PURPOSE
        Two safety checks before you enforce Conditional Access on a GCC High tenant:
        (1) local device readiness for device-based controls (Entra joined + PRT present), and
        (2) that the break-glass emergency-access accounts you name are excluded from EVERY CA
        policy. The single most important pre-enforcement check. Read-only.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\CAIG-Validation.ps1 -Upns breakglass1@your-tenant.onmicrosoft.us,breakglass2@your-tenant.onmicrosoft.us
        Connects to US Gov Graph: Connect-MgGraph -Environment USGov with
        Policy.Read.All + User.Read.All + GroupMember.Read.All. (Replace the example UPNs with your own.)
    EXPECTED RESULTS
        Device: "DEVICE CA-READY" when Entra joined and PRT present.
        Break-glass: per policy EXCLUDED (good) or NOT EXCLUDED (fix before enforcing). Overall PASS/FAIL.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph US Gov endpoints.
#>
[CmdletBinding()] param([string[]]$Upns)

Write-Host "=== Conditional Access (GCC High) — validation: $($env:COMPUTERNAME) ===" -ForegroundColor Cyan

# --- (1) Local device readiness ---
$dsreg = (dsregcmd /status) 2>$null
$aad = ($dsreg | Select-String 'AzureAdJoined\s*:\s*YES') -ne $null
$prt = ($dsreg | Select-String 'AzureAdPrt\s*:\s*YES') -ne $null
Write-Host ("Entra joined : {0}" -f ($(if($aad){'YES'}else{'NO'}))) -ForegroundColor ($(if($aad){'Green'}else{'Yellow'}))
Write-Host ("PRT present  : {0}" -f ($(if($prt){'YES'}else{'NO'}))) -ForegroundColor ($(if($prt){'Green'}else{'Yellow'}))
if ($aad -and $prt) { Write-Host "Device result: DEVICE CA-READY" -ForegroundColor Green }
else { Write-Host "Device result: NOT CA-READY — device-based CA policies will challenge/block this device" -ForegroundColor Yellow }

if (-not $Upns) {
    Write-Host "`n(No -Upns supplied; skipping break-glass exclusion check. Pass your break-glass UPNs to run it.)" -ForegroundColor Yellow
    return
}

# --- (2) Break-glass exclusion check via US Gov Graph ---
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Environment USGov -Scopes 'Policy.Read.All','User.Read.All','GroupMember.Read.All' -NoWelcome
if ((Get-MgContext).Environment -ne 'USGov') { Write-Host "WRONG CLOUD: not USGov. Reconnect with -Environment USGov." -ForegroundColor Red; Disconnect-MgGraph | Out-Null; return }

$ids = @{}
foreach ($u in $Upns) { try { $ids[$u] = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/users/$u").id } catch { Write-Host "User not found: $u" -ForegroundColor Red } }
$pols = (Invoke-MgGraphRequest -Method GET -Uri '/v1.0/identity/conditionalAccess/policies').value
$allGood = $true
Write-Host ""
foreach ($p in $pols) {
    $exU = @($p.conditions.users.excludeUsers)
    $exG = @($p.conditions.users.excludeGroups)
    foreach ($u in $Upns) {
        $id = $ids[$u]; if (-not $id) { continue }
        $inExU = $exU -contains $id
        $inExG = $false
        foreach ($g in $exG) { try { $m = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/groups/$g/members?`$select=id").value.id; if ($m -contains $id) { $inExG = $true } } catch {} }
        $ok = $inExU -or $inExG
        if (-not $ok) { $allGood = $false }
        Write-Host ("{0,-48} {1,-52} {2}" -f $p.displayName, $u, ($(if($ok){'EXCLUDED'}else{'NOT EXCLUDED'}))) -ForegroundColor ($(if($ok){'Green'}else{'Red'}))
    }
}
Write-Host ("`n{0}" -f ($(if($allGood){'PASS — all break-glass accounts are excluded from every policy.'}else{'FAIL — fix exclusions before enforcing any policy!'}))) -ForegroundColor ($(if($allGood){'Green'}else{'Red'}))
Disconnect-MgGraph | Out-Null
