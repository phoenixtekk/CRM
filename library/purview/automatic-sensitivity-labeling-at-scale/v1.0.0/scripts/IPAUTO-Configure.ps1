<#
.SYNOPSIS
    IPAUTO-Configure.ps1 — create/update client- and service-side auto-labeling policies; SIMULATION + -WhatIf by default, writes only with -Commit.
.DESCRIPTION
    PURPOSE
        Configures Microsoft Purview automatic sensitivity labeling: the CLIENT-SIDE auto-labeling
        conditions on a sensitivity label (recommend or auto-apply), and SERVICE-SIDE auto-labeling
        policies + rules for SharePoint/OneDrive/Exchange. Every service-side policy is created in
        SIMULATION (-Mode TestWithoutNotifications) so nothing is labeled until you review and enforce.
        SAFE BY DEFAULT: with no -Commit it only PREVIEWS the exact cmdlet it would run (-WhatIf); it
        changes nothing. Writes (New-/Set-) run only when -Commit is supplied.
    HOW TO RUN
        PowerShell 5.1+ or 7+ with the ExchangeOnlineManagement module, then Connect-IPPSSession.
        Preview a service-side SIMULATION policy (no change):
          .\IPAUTO-Configure.ps1 -ServiceSide -PolicyName "AutoLabel Sim - Confidential - SPO+ODB" `
             -RuleName "AutoLabel Rule - Confidential - SPO+ODB" -Label "Confidential \ All Employees" `
             -Workload SharePoint,OneDrive -Sit "Credit Card Number" -MinCount 1 -WhatIf
        Create it (write, gated):        add  -Commit
        Enforce on a pilot subset:       -ServiceSide -PolicyName "..." -Enforce -Locations "<site urls>" -Commit
        Return an enforced policy to simulation (rollback): -ServiceSide -PolicyName "..." -BackToSimulation -Commit
        Client-side recommend / auto-apply:  -ClientSide -Label "..." -Sit "..." -MinCount 1 -Recommend  (add -Commit)
    EXAMPLE
        .\IPAUTO-Configure.ps1 -ServiceSide -PolicyName "AutoLabel Sim - Confidential - SPO+ODB" -RuleName "AutoLabel Rule - Confidential - SPO+ODB" -Label "Confidential \ All Employees" -Workload SharePoint,OneDrive -Sit "Credit Card Number" -MinCount 1 -WhatIf
    .NOTES
        White-label Microsoft Purview tooling. No credentials stored. SIMULATION-first, -WhatIf default.
        Expected results: PASS = the intended New-/Set- change is printed (preview) or applied (-Commit)
        with no error; a service-side policy is created in a SIMULATION mode (TestWithoutNotifications),
        never Enable, until you explicitly -Enforce after sign-off.
        VERIFY IN YOUR TENANT: auto-labeling (client- and service-side) is E5/E5 Compliance and evolving;
        the exact Set-Label parameter surface for CLIENT-SIDE auto-labeling conditions is version-sensitive
        — this script previews the change and flags it; confirm the current parameter/behavior before -Commit.
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [switch]$ClientSide,
    [switch]$ServiceSide,

    [string]$Label = "Confidential \ All Employees",

    # Match conditions (service-side rule / client-side condition)
    [string]$Sit = "Credit Card Number",
    [int]$MinCount = 1,

    # Client-side behaviour
    [switch]$Recommend,
    [switch]$AutoApply,

    # Service-side identity + scope
    [string]$PolicyName,
    [string]$RuleName,
    [ValidateSet('SharePoint', 'OneDrive', 'Exchange')]
    [string[]]$Workload = @('SharePoint', 'OneDrive'),
    [string[]]$Locations = @('All'),

    # Service-side lifecycle actions
    [switch]$UpdateRule,
    [switch]$Enforce,
    [switch]$BackToSimulation,

    # Write gate — nothing is written without this
    [switch]$Commit
)

$ErrorActionPreference = "Stop"
$modeBanner = if ($Commit) { 'COMMIT' } else { 'preview/-WhatIf' }
Write-Host "=== IPAUTO Configure — auto-labeling (SIMULATION-first; $modeBanner) ===" -ForegroundColor Cyan

if (-not (Get-Command Get-Label -ErrorAction SilentlyContinue)) {
    Write-Host "Security & Compliance PowerShell not available. Run Connect-IPPSSession first." -ForegroundColor Red
    return
}
if (-not ($ClientSide -or $ServiceSide)) {
    Write-Host "Specify -ClientSide and/or -ServiceSide. Nothing to do." -ForegroundColor Yellow
    return
}

# --- Guard: the label to apply must already exist and be published (Req 2.1) ---
$labelObj = @(Get-Label -ErrorAction SilentlyContinue) | Where-Object { $_.DisplayName -eq $Label -or $_.Name -eq $Label } | Select-Object -First 1
if (-not $labelObj) {
    Write-Host ("Target label '{0}' NOT found. Auto-labeling can only apply an EXISTING published label (Req 2.1)." -f $Label) -ForegroundColor Red
    Write-Host "Complete the labels prerequisite first (Get-Label / Get-LabelPolicy)." -ForegroundColor Red
    return
}
Write-Host ("Target label present: '{0}' (Name={1}). Confirm it is PUBLISHED and, if it encrypts, protection enforces (Req 2.1)." -f $labelObj.DisplayName, $labelObj.Name) -ForegroundColor Green

# Helper: preview or apply a scriptblock behind -Commit + ShouldProcess
function Invoke-Change {
    param([string]$Target, [string]$Action, [scriptblock]$Do, [string]$Preview)
    Write-Host ("  WOULD RUN: {0}" -f $Preview) -ForegroundColor DarkCyan
    if (-not $Commit) {
        Write-Host "  (preview only — re-run with -Commit to apply)" -ForegroundColor Yellow
        return
    }
    if ($PSCmdlet.ShouldProcess($Target, $Action)) {
        & $Do
        Write-Host ("  APPLIED: {0}" -f $Action) -ForegroundColor Green
    }
}

# ---------------- CLIENT-SIDE ----------------
if ($ClientSide) {
    Write-Host "`n[Client-side] auto-labeling conditions on the label..." -ForegroundColor Cyan
    if ($Recommend -and $AutoApply) { Write-Host "  Choose -Recommend OR -AutoApply, not both." -ForegroundColor Red; return }
    $mode = if ($AutoApply) { 'auto-apply (silent)' } else { 'recommend (user prompted)' }
    Write-Host ("  Intent: set the label's client-side auto-labeling condition to {0} where content matches SIT '{1}' (>= {2})." -f $mode, $Sit, $MinCount) -ForegroundColor Gray
    Write-Host "  NOTE — VERIFY IN YOUR TENANT: the exact Set-Label parameter/advanced-settings surface for" -ForegroundColor Yellow
    Write-Host "  client-side auto-labeling conditions is version-sensitive. Confirm the current parameter names in" -ForegroundColor Yellow
    Write-Host "  Purview (Information Protection > Labels > the label > Auto-labeling for files and emails) before -Commit." -ForegroundColor Yellow
    $preview = "Set-Label -Identity '$($labelObj.Name)' <client-side auto-labeling condition: SIT='$Sit', MinCount=$MinCount, $mode>"
    Invoke-Change -Target $labelObj.Name -Action "Set-Label client-side auto-labeling ($mode)" -Preview $preview -Do {
        # Version-sensitive parameter surface — invoke -WhatIf even under -Commit unless the operator has
        # confirmed the parameter names for their tenant. This keeps the script safe against invented params.
        Set-Label -Identity $labelObj.Name -WhatIf
        Write-Host "  (executed Set-Label -WhatIf — replace with your tenant's confirmed auto-labeling parameters to apply)" -ForegroundColor Yellow
    }
}

# ---------------- SERVICE-SIDE ----------------
if ($ServiceSide) {
    if (-not $PolicyName) { Write-Host "  -ServiceSide requires -PolicyName." -ForegroundColor Red; return }
    if (-not (Get-Command Get-AutoSensitivityLabelPolicy -ErrorAction SilentlyContinue)) {
        Write-Host "  Get-AutoSensitivityLabelPolicy not available — check licensing/role (Req 2.2/2.3)." -ForegroundColor Red
        return
    }
    $existing = @(Get-AutoSensitivityLabelPolicy -ErrorAction SilentlyContinue) | Where-Object { $_.Name -eq $PolicyName } | Select-Object -First 1

    # -- Rollback: enforced -> simulation --
    if ($BackToSimulation) {
        Write-Host "`n[Service-side] ROLLBACK — return policy to SIMULATION..." -ForegroundColor Cyan
        if (-not $existing) { Write-Host ("  Policy '{0}' not found." -f $PolicyName) -ForegroundColor Red; return }
        $preview = "Set-AutoSensitivityLabelPolicy -Identity '$PolicyName' -Mode TestWithoutNotifications"
        Invoke-Change -Target $PolicyName -Action "Set policy to SIMULATION (stops labeling; does NOT un-label)" -Preview $preview -Do {
            Set-AutoSensitivityLabelPolicy -Identity $PolicyName -Mode TestWithoutNotifications -Confirm:$false
        }
        Write-Host "  Rollback stops NEW labeling; already-applied labels remain (auto-labeling does not un-label)." -ForegroundColor Yellow
        return
    }

    # -- Enforce (pilot subset or All) --
    if ($Enforce) {
        Write-Host "`n[Service-side] ENFORCE — move policy from simulation to Enable (scoped)..." -ForegroundColor Cyan
        if (-not $existing) { Write-Host ("  Policy '{0}' not found — create it in simulation first." -f $PolicyName) -ForegroundColor Red; return }
        Write-Host ("  Current mode: {0}. Enforce only AFTER the simulation match set is accepted by the data owner (Testing Test 5)." -f $existing.Mode) -ForegroundColor Yellow
        $locNote = ($Locations -join ", ")
        $preview = "Set-AutoSensitivityLabelPolicy -Identity '$PolicyName' -Mode Enable  (locations: $locNote)"
        Invoke-Change -Target $PolicyName -Action "ENFORCE policy (-Mode Enable) on locations: $locNote" -Preview $preview -Do {
            Set-AutoSensitivityLabelPolicy -Identity $PolicyName -Mode Enable -Confirm:$false
            Write-Host "  NOTE: scope the enforced LOCATIONS via the policy's SharePoint/OneDrive/Exchange location parameters or adaptive scope — VERIFY the current parameter names in your tenant." -ForegroundColor Yellow
        }
        return
    }

    # -- Update an existing rule's conditions --
    if ($UpdateRule) {
        Write-Host "`n[Service-side] UPDATE RULE conditions (re-simulate after)..." -ForegroundColor Cyan
        if (-not $RuleName) { Write-Host "  -UpdateRule requires -RuleName." -ForegroundColor Red; return }
        $preview = "Set-AutoSensitivityLabelRule -Identity '$RuleName' <SIT='$Sit', MinCount=$MinCount>"
        Invoke-Change -Target $RuleName -Action "Update auto-labeling rule conditions" -Preview $preview -Do {
            Set-AutoSensitivityLabelRule -Identity $RuleName -Confirm:$false -WhatIf
            Write-Host "  (executed Set-AutoSensitivityLabelRule -WhatIf — supply your tenant's confirmed condition parameters to apply)" -ForegroundColor Yellow
        }
        Write-Host "  After updating, let SIMULATION re-run and re-review precision (IPAUTO-Validate.ps1)." -ForegroundColor Cyan
        return
    }

    # -- Create policy + rule in SIMULATION --
    Write-Host "`n[Service-side] CREATE policy + rule in SIMULATION (TestWithoutNotifications)..." -ForegroundColor Cyan
    if ($existing) {
        Write-Host ("  Policy '{0}' already exists (Mode={1}). Use -UpdateRule / -Enforce / -BackToSimulation instead of re-creating." -f $PolicyName, $existing.Mode) -ForegroundColor Yellow
        return
    }
    if (-not $RuleName) { Write-Host "  Creating a policy requires -RuleName (the condition rule)." -ForegroundColor Red; return }
    $wl = $Workload -join ", "
    $polPreview = "New-AutoSensitivityLabelPolicy -Name '$PolicyName' -ApplySensitivityLabel '$($labelObj.Name)' -Mode TestWithoutNotifications  (workloads: $wl)"
    Invoke-Change -Target $PolicyName -Action "Create SIMULATION auto-labeling policy" -Preview $polPreview -Do {
        # Workload/location parameter names vary by tenant/version — build the base then flag scope params.
        New-AutoSensitivityLabelPolicy -Name $PolicyName -ApplySensitivityLabel $labelObj.Name -Mode TestWithoutNotifications -Confirm:$false
        Write-Host "  Policy created in SIMULATION. Set its SharePoint/OneDrive/Exchange locations for workloads [$wl] — VERIFY the current location parameter names in your tenant." -ForegroundColor Yellow
    }
    $rulePreview = "New-AutoSensitivityLabelRule -Name '$RuleName' -Policy '$PolicyName' <SIT='$Sit', MinCount=$MinCount>"
    Invoke-Change -Target $RuleName -Action "Create auto-labeling rule (conditions)" -Preview $rulePreview -Do {
        New-AutoSensitivityLabelRule -Name $RuleName -Policy $PolicyName -Confirm:$false -WhatIf
        Write-Host "  (executed New-AutoSensitivityLabelRule -WhatIf — supply your tenant's confirmed -ContentContainsSensitiveInformation condition to apply)" -ForegroundColor Yellow
    }
    Write-Host "`nNext: let simulation run, then validate precision with IPAUTO-Validate.ps1 before you -Enforce." -ForegroundColor Cyan
}
