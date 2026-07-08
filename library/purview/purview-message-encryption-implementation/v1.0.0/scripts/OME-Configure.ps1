<#
.SYNOPSIS
    OME-Configure.ps1 — configure OME branding and the Audit-mode mail flow rules (SAFE: -WhatIf by default; -Commit required).
.DESCRIPTION
    PURPOSE
        Configuration/remediation helper for Purview Message Encryption (OME). With -Action Branding it
        previews and (with -Commit) sets the OME branding via Set-OMEConfiguration on the default
        configuration (or New/Set on a custom template for Advanced Message Encryption). With -Action
        MailFlowRules it prints and (with -Commit) creates the two OME transport rules
        (OME-Encrypt-Outbound-Pilot -> Encrypt; OME-DoNotForward-Confidential -> Do Not Forward) IN
        'Audit' MODE, scoped to the pilot group — the rule matches and logs but DOES NOT ENCRYPT.
        SAFE BY DEFAULT: prints intended actions under -WhatIf; changes only with -Commit; a rule is
        flipped to 'Enforce' only when you additionally pass -Enforce. No cmdlets invented; no secrets.
    HOW TO RUN
        PowerShell 5.1+ or 7+ with ExchangeOnlineManagement; Connect-ExchangeOnline as an Exchange admin.
        Preview branding:    .\OME-Configure.ps1 -Action Branding -WhatIf
        Apply branding:      .\OME-Configure.ps1 -Action Branding -Commit -EmailText "Your org sent you a protected message."
        Preview rules:       .\OME-Configure.ps1 -Action MailFlowRules -WhatIf
        Create rules (Audit):.\OME-Configure.ps1 -Action MailFlowRules -Commit -PilotGroup "SG-OME-Pilot@contoso.com"
        Flip a rule to Enforce (deliberate): .\OME-Configure.ps1 -Action MailFlowRules -Commit -Enforce -RuleName "OME-Encrypt-Outbound-Pilot"
    EXPECTED RESULTS
        Branding: Get-OMEConfiguration reflects the values you set. MailFlowRules: the two rules exist,
        enabled, Mode=Audit (until -Enforce). Nothing changes without -Commit; enforcement requires -Enforce.
.NOTES
    White-label. SAFE-by-default (-WhatIf). Rules created in Audit mode per the category pilot model.
    Exchange Online PowerShell. No credentials in code. Custom branding templates / Advanced features are
    licensing-dependent (E5 / E5 Compliance) — verify in your tenant. Determinations about WHAT to encrypt
    remain with compliance/privacy. No cmdlets invented.
#>

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('Branding','MailFlowRules')]
    [string] $Action,

    # Branding
    [string] $ConfigurationName = 'OME Configuration',   # the default OME configuration identity
    [string] $EmailText,
    [string] $PortalText,
    [string] $DisclaimerText,
    [string] $BackgroundColor,                            # e.g. '#0F6CBD'
    [string] $LogoPath,                                   # local file; converted to bytes for -Image
    [switch] $CustomTemplate,                             # create/use a custom template (Advanced only)
    [string] $CustomTemplateName = 'OME-Branding-Corp',

    # MailFlowRules
    [string] $PilotGroup = 'SG-OME-Pilot@contoso.com',
    [string] $EncryptKeyword = '[encrypt]',
    [string] $LabelHeaderName = 'msip_labels',
    [string] $HighlyConfidentialLabelGuid,               # GUID of the Highly Confidential label (verify)
    [ValidateSet('OME-Encrypt-Outbound-Pilot','OME-DoNotForward-Confidential')]
    [string] $RuleName,
    [switch] $Enforce,                                   # flip named rule(s) from Audit to Enforce

    [switch] $Commit
)

$ErrorActionPreference = 'Stop'
Write-Host "=== OME-Configure — Action=$Action (SAFE: -WhatIf; -Commit required to change) ===" -ForegroundColor Cyan

if (-not (Get-Command Get-IRMConfiguration -ErrorAction SilentlyContinue)) {
    Write-Host 'Not connected to Exchange Online. Run Connect-ExchangeOnline first.' -ForegroundColor Red
    return
}

function Invoke-Change([string]$desc, [scriptblock]$change) {
    if (-not $Commit) { Write-Host "  [DRY-RUN] Would: $desc  (re-run with -Commit)" -ForegroundColor Yellow; return }
    if ($PSCmdlet.ShouldProcess($desc)) {
        & $change
        Write-Host "  [DONE] $desc" -ForegroundColor Green
    } else {
        Write-Host "  [SKIPPED] $desc" -ForegroundColor Yellow
    }
}

switch ($Action) {

    'Branding' {
        # Confirm RMS is on first — branding is meaningless without the encryption foundation.
        try {
            $irm = Get-IRMConfiguration -ErrorAction Stop
            if (-not $irm.AzureRMSLicensingEnabled) {
                Write-Host 'WARNING: AzureRMSLicensingEnabled is False. Enable RMS before branding (see R2).' -ForegroundColor Yellow
            }
        } catch { }

        $target = if ($CustomTemplate) { $CustomTemplateName } else { $ConfigurationName }
        Write-Host ("Target OME configuration: {0}" -f $target) -ForegroundColor Cyan
        if ($CustomTemplate) {
            Write-Host 'NOTE: custom branding templates require Advanced Message Encryption (E5 / E5 Compliance). Verify licensing.' -ForegroundColor Yellow
            $exists = @(Get-OMEConfiguration -ErrorAction SilentlyContinue | Where-Object { $_.Identity -eq $CustomTemplateName })
            if ($exists.Count -eq 0) {
                Invoke-Change "New-OMEConfiguration -Identity '$CustomTemplateName'" {
                    New-OMEConfiguration -Identity $CustomTemplateName | Out-Null
                }
            } else { Write-Host "  Custom template '$CustomTemplateName' already exists." }
        }

        # Build the Set-OMEConfiguration parameter splat from whatever the caller supplied.
        $params = @{ Identity = $target }
        if ($EmailText)      { $params['EmailText']      = $EmailText }
        if ($PortalText)     { $params['PortalText']     = $PortalText }
        if ($DisclaimerText) { $params['DisclaimerText'] = $DisclaimerText }
        if ($BackgroundColor){ $params['BackgroundColor']= $BackgroundColor }
        if ($LogoPath) {
            if (Test-Path $LogoPath) {
                $params['Image'] = [System.IO.File]::ReadAllBytes((Resolve-Path $LogoPath))
                Write-Host "  Logo will be read from: $LogoPath (verify current size/format limits)."
            } else { Write-Host "  Logo path not found: $LogoPath (skipping -Image)." -ForegroundColor Yellow }
        }

        if ($params.Keys.Count -le 1) {
            Write-Host 'No branding properties supplied. Pass -EmailText/-PortalText/-DisclaimerText/-BackgroundColor/-LogoPath.' -ForegroundColor Yellow
            Write-Host 'Current configuration:'
            Get-OMEConfiguration -Identity $target -ErrorAction SilentlyContinue | Format-List Identity, EmailText, PortalText, DisclaimerText, BackgroundColor
            return
        }

        Write-Host 'Intended branding values:'; ($params.GetEnumerator() | Where-Object { $_.Key -ne 'Image' } | Format-Table -AutoSize | Out-String) | Write-Host
        Invoke-Change "Set-OMEConfiguration -Identity '$target' (branding)" {
            Set-OMEConfiguration @params
        }
        Write-Host 'TIP: preview the branding in the Exchange/Purview portal; some rendering is portal-only.' -ForegroundColor Cyan
    }

    'MailFlowRules' {
        # ---- Enforce path: flip an existing Audit rule to Enforce (deliberate) ----
        if ($Enforce) {
            $targets = if ($RuleName) { @($RuleName) } else { @('OME-Encrypt-Outbound-Pilot','OME-DoNotForward-Confidential') }
            foreach ($rn in $targets) {
                $r = Get-TransportRule -Identity $rn -ErrorAction SilentlyContinue
                if (-not $r) { Write-Host "  Rule '$rn' not found (create it in Audit first)." -ForegroundColor Yellow; continue }
                Write-Host "  Rule '$rn' current Mode=$($r.Mode). Flipping to Enforce is HIGH-IMPACT — ensure gates in 05-testing.md pass." -ForegroundColor Yellow
                Invoke-Change "Set-TransportRule -Identity '$rn' -Mode Enforce" {
                    Set-TransportRule -Identity $rn -Mode Enforce
                }
            }
            return
        }

        # ---- Create path: build the two rules in AUDIT mode ----
        Write-Host "Pilot group scope: $PilotGroup   (rules created in Mode=Audit — they match/log but do NOT encrypt)" -ForegroundColor Cyan

        # Rule 1 — Encrypt on keyword OR external recipient, from pilot senders
        $r1 = 'OME-Encrypt-Outbound-Pilot'
        $exists1 = Get-TransportRule -Identity $r1 -ErrorAction SilentlyContinue
        if ($exists1) { Write-Host "  Rule '$r1' already exists (Mode=$($exists1.Mode)); not recreating." }
        else {
            Write-Host "  Plan: '$r1' — From member of $PilotGroup AND (Subject contains '$EncryptKeyword' OR SentTo external) -> Apply 'Encrypt' (Audit)"
            Invoke-Change "New-TransportRule '$r1' (Encrypt, Audit)" {
                New-TransportRule -Name $r1 `
                    -FromMemberOf $PilotGroup `
                    -SentToScope 'NotInOrganization' `
                    -SubjectContainsWords $EncryptKeyword `
                    -ApplyRightsProtectionTemplate 'Encrypt' `
                    -Mode Audit | Out-Null
            }
            Write-Host "    (To brand with a custom template add -ApplyRightsProtectionCustomizationTemplate '$CustomTemplateName' — verify the exact parameter in your tenant.)"
        }

        # Rule 2 — Do Not Forward on the Highly Confidential label header, from pilot senders
        $r2 = 'OME-DoNotForward-Confidential'
        $exists2 = Get-TransportRule -Identity $r2 -ErrorAction SilentlyContinue
        if ($exists2) { Write-Host "  Rule '$r2' already exists (Mode=$($exists2.Mode)); not recreating." }
        elseif (-not $HighlyConfidentialLabelGuid) {
            Write-Host "  Rule '$r2' NOT planned: supply -HighlyConfidentialLabelGuid (the label GUID matched in the '$LabelHeaderName' header)." -ForegroundColor Yellow
            Write-Host "    Alternatively key on a keyword/classification per your Phase-1 design (03-implementation.md)."
        }
        else {
            Write-Host "  Plan: '$r2' — From member of $PilotGroup AND header '$LabelHeaderName' matches '$HighlyConfidentialLabelGuid' -> Apply 'Do Not Forward' (Audit)"
            Invoke-Change "New-TransportRule '$r2' (Do Not Forward, Audit)" {
                New-TransportRule -Name $r2 `
                    -FromMemberOf $PilotGroup `
                    -HeaderMatchesMessageHeader $LabelHeaderName `
                    -HeaderMatchesPatterns $HighlyConfidentialLabelGuid `
                    -ApplyRightsProtectionTemplate 'Do Not Forward' `
                    -Mode Audit | Out-Null
            }
        }

        Write-Host ''
        Write-Host 'Rules are in AUDIT mode. Validate with OME-Validate.ps1, then flip to Enforce deliberately:' -ForegroundColor Cyan
        Write-Host '  .\OME-Configure.ps1 -Action MailFlowRules -Commit -Enforce   (see 03-implementation.md Phase 5)'
    }
}
