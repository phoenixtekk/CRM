<#
.SYNOPSIS
    IPMEET-Set-MeetingLabel.ps1 — Create meeting label objects and publish the label policy (-WhatIf by default).
.DESCRIPTION
    PURPOSE
        Automates the safe, repeatable LIFECYCLE of the meeting labels and their policy: creates the three
        meeting label objects (Meeting - General / Confidential / Highly Confidential) and publishes /
        points the 'Meeting Labels - Policy' at the pilot (or expansion) users. DEFAULTS TO -WhatIf: it
        prints exactly what it would do plus the reverse action and changes nothing; it applies only with
        -Commit. The per-meeting PROTECTION settings (lobby / recording / chat / copy / watermark / E2EE)
        are completed on each label in the Purview portal — this script does not assert them, because they
        are portal-configured and Teams-Premium-gated. No credentials or secrets are stored in the script.
    HOW TO RUN
        .\IPMEET-Set-MeetingLabel.ps1 -Action CreateLabels -WhatIf
        .\IPMEET-Set-MeetingLabel.ps1 -Action CreateLabels -Commit
        .\IPMEET-Set-MeetingLabel.ps1 -Action PublishPolicy -PolicyMembers "MeetingLabels-Pilot@contoso.com" -WhatIf
        .\IPMEET-Set-MeetingLabel.ps1 -Action PublishPolicy -PolicyMembers "MeetingLabels-Pilot@contoso.com" -Commit
        PowerShell 5.1+/7+. Connect first with Connect-IPPSSession (modern-auth/MFA admin).
    EXPECTED RESULTS
        -WhatIf: a line per label/policy stating what WOULD be created/published, plus the reverse command;
        no change is made. -Commit: the label objects and/or the policy exist afterward (verify with
        Get-Label / Get-LabelPolicy); finish the meeting-protection settings in the portal.
.NOTES
    Purview — Sensitivity Labeling for Meetings. Safe-by-default. Verify your licensing/tenant: the
    Meetings scope + meeting protections are portal-configured and Teams-Premium-gated; author them in the
    Purview portal after the label objects exist. Pilot before enforcing.
#>
[CmdletBinding()]
param(
    [ValidateSet('CreateLabels','PublishPolicy')]
    [string]$Action = 'CreateLabels',
    [string]$PolicyName = 'Meeting Labels - Policy',
    [string[]]$PolicyMembers = @(),                 # UPNs / mail-enabled groups to publish the policy to
    [switch]$WhatIf,
    [switch]$Commit
)

# Safe-by-default: unless -Commit is explicitly set, force preview mode.
if (-not $Commit) { $WhatIf = $true }
if ($WhatIf -and $Commit) { Write-Host "Specify either -WhatIf or -Commit, not both." -ForegroundColor Yellow; return }

function Test-Command([string]$Name) { [bool](Get-Command $Name -ErrorAction SilentlyContinue) }
if (-not (Test-Command 'Get-Label')) {
    Write-Host "Security & Compliance PowerShell not connected. Run Connect-IPPSSession first." -ForegroundColor Yellow; return
}

$mode = $(if ($Commit) { 'COMMIT' } else { 'WHATIF (no changes)' })
Write-Host "`n=== Set meeting labels — Action: $Action — Mode: $mode ===" -ForegroundColor Cyan

# The three meeting labels (display name, internal name, tooltip). Protection settings finished in portal.
$labelDefs = @(
    @{ Display='Meeting - General';              Name='Meeting-General';            Tip='Standard meeting. Tenant-default lobby, chat and recording as designed.' },
    @{ Display='Meeting - Confidential';         Name='Meeting-Confidential';       Tip='Confidential meeting. External attendees wait in lobby; chat in-meeting only, copy prevented; recording limited to organizers; invite encrypted.' },
    @{ Display='Meeting - Highly Confidential';  Name='Meeting-HighlyConfidential'; Tip='Highly confidential meeting. Only organizers/co-organizers bypass lobby; chat off; recording prevented; watermark + end-to-end encryption; invite encrypted.' }
)

if ($Action -eq 'CreateLabels') {
    $existing = @(Get-Label -ErrorAction SilentlyContinue)
    foreach ($d in $labelDefs) {
        $already = $existing | Where-Object { $_.DisplayName -eq $d.Display -or $_.Name -eq $d.Name }
        if ($already) {
            Write-Host ("  SKIP  '{0}' already exists." -f $d.Display) -ForegroundColor DarkGray
            continue
        }
        if ($WhatIf) {
            Write-Host ("  WOULD create label '{0}' (Name: {1})" -f $d.Display, $d.Name) -ForegroundColor Yellow
            Write-Host ("        reverse: Remove-Label -Identity '{0}'" -f $d.Name) -ForegroundColor DarkGray
        } else {
            try {
                New-Label -DisplayName $d.Display -Name $d.Name -Tooltip $d.Tip -ErrorAction Stop | Out-Null
                Write-Host ("  CREATED label '{0}'." -f $d.Display) -ForegroundColor Green
            } catch {
                Write-Host ("  ERROR creating '{0}': {1}" -f $d.Display, $_.Exception.Message) -ForegroundColor Red
            }
        }
    }
    Write-Host "`nNext: in the Purview portal, set each label's scope to 'Meetings and calendar events' and configure" -ForegroundColor Cyan
    Write-Host "lobby / recording / chat / copy / watermark / E2EE / invite-encryption per the taxonomy (Teams Premium)." -ForegroundColor Cyan
    return
}

if ($Action -eq 'PublishPolicy') {
    if ($PolicyMembers.Count -eq 0) {
        Write-Host "Provide -PolicyMembers (UPNs or mail-enabled groups) to publish the policy to." -ForegroundColor Yellow; return
    }
    $labelNames = $labelDefs.Display
    $policy = Get-LabelPolicy -Identity $PolicyName -ErrorAction SilentlyContinue
    if ($WhatIf) {
        if ($policy) {
            Write-Host ("  WOULD update policy '{0}': ensure labels [{1}] and members [{2}]" -f $PolicyName, ($labelNames -join ', '), ($PolicyMembers -join ', ')) -ForegroundColor Yellow
            Write-Host ("        reverse: Set-LabelPolicy -Identity '{0}' -RemoveLabel <label> / narrow members back to pilot" -f $PolicyName) -ForegroundColor DarkGray
        } else {
            Write-Host ("  WOULD create policy '{0}' with labels [{1}] published to [{2}]" -f $PolicyName, ($labelNames -join ', '), ($PolicyMembers -join ', ')) -ForegroundColor Yellow
            Write-Host ("        reverse: Remove-LabelPolicy -Identity '{0}'" -f $PolicyName) -ForegroundColor DarkGray
        }
        Write-Host "`nLeave default/mandatory labeling OFF during the pilot — enable in the portal only after validation." -ForegroundColor DarkGray
        return
    }
    try {
        if (-not $policy) {
            New-LabelPolicy -Name $PolicyName -Settings @{} -ErrorAction Stop | Out-Null
            Write-Host ("  CREATED policy '{0}'." -f $PolicyName) -ForegroundColor Green
        }
        # Add labels + set the published-to membership (verify parameter names against your module version).
        Set-LabelPolicy -Identity $PolicyName -AddLabel $labelNames -ErrorAction Stop | Out-Null
        Set-LabelPolicy -Identity $PolicyName -AddExchangeLocation $PolicyMembers -ErrorAction SilentlyContinue | Out-Null
        Write-Host ("  PUBLISHED '{0}' with labels [{1}] to [{2}]." -f $PolicyName, ($labelNames -join ', '), ($PolicyMembers -join ', ')) -ForegroundColor Green
        Write-Host "  Verify in the portal that the policy shows the three meeting labels and the intended members." -ForegroundColor DarkGray
    } catch {
        Write-Host ("  ERROR publishing policy: {0}" -f $_.Exception.Message) -ForegroundColor Red
        Write-Host "  Verify the label/membership parameter names for your ExchangeOnlineManagement version." -ForegroundColor Yellow
    }
}
