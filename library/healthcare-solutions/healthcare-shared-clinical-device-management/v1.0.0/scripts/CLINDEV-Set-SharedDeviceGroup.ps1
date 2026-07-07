<#
.SYNOPSIS
    CLINDEV-Set-SharedDeviceGroup.ps1 — Create the dynamic 'Clinical - Shared Devices' Entra group
    for shared clinical Windows devices, and optionally surface the profile/app assignment plan.

    PURPOSE
        Create (idempotently) the dynamic security group that every profile and app in this
        solution targets. Membership is keyed on the Windows Autopilot GROUP TAG (order ID) set at
        registration, so any shared clinical device that self-provisions joins automatically. The
        script is gated: it previews with -WhatIf and only creates the group when you pass -Apply.
        It can also print the recommended assignment plan (Autopilot profile, Shared PC profile,
        power profile, kiosk profile, clinical app baseline) for you to apply in the Intune console.

    HOW TO RUN
        1. Install-Module Microsoft.Graph -Scope CurrentUser   (if needed)
        2. Preview (read-only, default):
               Connect-MgGraph -Scopes "Group.Read.All","Directory.Read.All"
               .\CLINDEV-Set-SharedDeviceGroup.ps1 -GroupTag "ClinicalShared"        # -WhatIf preview
        3. Create the group (requires write scope + -Apply):
               Connect-MgGraph -Scopes "Group.ReadWrite.All","Directory.Read.All"
               .\CLINDEV-Set-SharedDeviceGroup.ps1 -GroupTag "ClinicalShared" -Apply -ShowAssignmentPlan

    EXPECTED RESULTS
        In preview: the dynamic membership rule that WOULD be created, and (with
        -ShowAssignmentPlan) the list of objects to assign to the group — with NO changes. With
        -Apply: the dynamic group 'Clinical - Shared Devices' is created (or confirmed already
        present) with the Autopilot-group-tag membership rule.

.NOTES
    Healthcare Solutions — read-only.
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [string] $GroupName        = "Clinical - Shared Devices",
    [string] $GroupTag         = "ClinicalShared",
    # First-party 'Intune Provisioning Client' SP (aka 'Intune Autopilot ConfidentialClient'). For an
    # ASSIGNED shared-device group (Windows Autopilot device preparation model), this SP must OWN the
    # group or enrollment-time grouping leaves it empty. Matched by AppId, not display name.
    [string] $ProvisioningClientAppId = "f1346770-5b25-470b-88bd-d5744ab7952c",
    [switch] $Apply,
    [switch] $ShowAssignmentPlan
)

function Assert-Graph {
    if (-not (Get-MgContext)) {
        throw "Not connected to Microsoft Graph. Run Connect-MgGraph first (see .SYNOPSIS)."
    }
}

function Test-ProvisioningClientOwner {
    # READ-ONLY: report whether the Intune Provisioning Client SP owns the targeting group.
    param([string]$GroupId, [string]$Name, [string]$AppId)
    try {
        $owners = Get-MgGroupOwner -GroupId $GroupId -All -ErrorAction Stop
        $isOwner = $owners | Where-Object { $_.AdditionalProperties['appId'] -eq $AppId }
        if ($isOwner) {
            Write-Host "  OK  : Intune Provisioning Client (AppId $AppId) is an Owner of '$Name'." -ForegroundColor Green
        } else {
            Write-Host "  NOTE: Intune Provisioning Client (AppId $AppId) is NOT an Owner of '$Name'." -ForegroundColor Yellow
            Write-Host "        For an ASSIGNED shared-device group, enrollment-time grouping needs this owner or the group stays empty at enrollment." -ForegroundColor Yellow
            Write-Host "        Add it: Entra > Groups > '$Name' > Owners > Add owners, search by AppId $AppId (not the display name)."
        }
    } catch {
        Write-Host "  NOTE: could not read owners of '$Name' ($($_.Exception.Message))." -ForegroundColor DarkGray
    }
}

if (-not $Apply) { $WhatIfPreference = $true }

# Dynamic rule: match the Autopilot order ID (group tag) stamped on the device physical IDs.
$membershipRule = "(device.devicePhysicalIds -any (_ -contains ""[OrderID]:$GroupTag""))"

try {
    Assert-Graph
    $mode = if ($Apply) { "APPLY" } else { "PREVIEW (-WhatIf) — no changes will be made" }
    Write-Host "CLINDEV-Set-SharedDeviceGroup mode: $mode" -ForegroundColor Yellow
    Write-Host "Proposed dynamic membership rule:" -ForegroundColor Cyan
    Write-Host "  $membershipRule"

    $existing = Get-MgGroup -Filter "displayName eq '$GroupName'" -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($existing) {
        Write-Host "Group '$GroupName' already exists (Id $($existing.Id)). No creation needed." -ForegroundColor Green
        # READ-ONLY: if this is an Assigned group (Windows Autopilot device preparation model),
        # report whether the Intune Provisioning Client SP owns it (enrollment-time grouping owner).
        Write-Host "Enrollment-time grouping owner check:" -ForegroundColor Cyan
        Test-ProvisioningClientOwner -GroupId $existing.Id -Name $GroupName -AppId $ProvisioningClientAppId
    }
    else {
        if ($PSCmdlet.ShouldProcess($GroupName, "Create dynamic security group with Autopilot-group-tag rule")) {
            $mailNick = ($GroupName -replace '[^a-zA-Z0-9]', '')
            New-MgGroup -DisplayName $GroupName `
                        -Description "Shared clinical Windows devices (WOWs, kiosks, nurse-station PCs, tablets) — owner-less; targeted by all CLINDEV profiles/apps." `
                        -MailEnabled:$false `
                        -MailNickname $mailNick `
                        -SecurityEnabled:$true `
                        -GroupTypes @("DynamicMembership") `
                        -MembershipRule $membershipRule `
                        -MembershipRuleProcessingState "On" `
                        -ErrorAction Stop | Out-Null
            Write-Host "Created dynamic group '$GroupName'." -ForegroundColor Green
        }
    }

    if ($ShowAssignmentPlan) {
        Write-Host "`n=== Recommended assignment plan (apply in Intune admin center) ===" -ForegroundColor Cyan
        @(
            "Autopilot deployment profile : Clinical Shared - Self-Deploying - Provision",
            "Enrollment Status Page       : Clinical Shared - ESP - Provision",
            "Shared PC config profile     : Clinical Shared - Shared PC Mode - Standardize",
            "Power config profile         : Clinical Shared - WOW Always-On - Standardize",
            "Kiosk config (single-purpose): Clinical Shared - Kiosk Assigned Access - Lock-down (kiosk sub-group only)",
            "Clinical app baseline        : assign each app as Required to '$GroupName'"
        ) | ForEach-Object { Write-Host "  -> $_  ==> $GroupName" }
        Write-Host "  (See 03-implementation.md for the exact steps and order.)"
    }

    if (-not $Apply) {
        Write-Host "`nPreview complete. Re-run with -Apply (and Group.ReadWrite.All) to create the group." -ForegroundColor Yellow
    }
}
catch {
    Write-Error "CLINDEV-Set-SharedDeviceGroup failed: $($_.Exception.Message)"
    exit 1
}
