<#
.SYNOPSIS
    GRAPHSUB-Renew.ps1 — renew/extend a Microsoft Graph change-notification subscription nearing
    expiry. The ONLY state-changing script here. DEFAULTS TO -WhatIf (previews, changes nothing).
.DESCRIPTION
    PURPOSE
        Safe renewal for the "Event-Driven Mail Processing with Microsoft Graph Change Notifications"
        solution. Finds the subscription on the target mailbox (or a subscription id you pass) and
        extends its expirationDateTime by a requested amount that must stay WITHIN Graph's current
        maximum lifetime for the resource. If the subscription has already expired/been deleted, it can
        optionally RECREATE it (requires -NotificationUrl and -ClientState).
        DEFAULTS TO -WhatIf — it prints the change it would make and changes nothing until you pass
        -Execute. This is the manual/operator companion to the wf-SubscriptionRenewal workflow.
    HOW TO RUN
        Preview (default, no change):
            pwsh -File .\GRAPHSUB-Renew.ps1 -Mailbox 'svc-mailevents@contoso.com'
            pwsh -File .\GRAPHSUB-Renew.ps1 -SubscriptionId '<id>' -ExtendMinutes 4230
        Apply for real (explicit):
            pwsh -File .\GRAPHSUB-Renew.ps1 -Mailbox 'svc-mailevents@contoso.com' -Execute
        Recreate if already expired (explicit):
            pwsh -File .\GRAPHSUB-Renew.ps1 -Mailbox 'svc-mailevents@contoso.com' -RecreateIfMissing `
                 -NotificationUrl '<wf-NotificationReceiver URL>' -ClientState '<MailEvents-ClientState value>' -Execute
    GRAPH SCOPES (delegated)
        Subscription.Read.All   — find the subscription
        Subscription.ReadWrite  — PATCH (extend) / POST (recreate) the subscription   [verify exact scope name with Microsoft]
        (Connect-MgGraph -Scopes 'Subscription.ReadWrite','Subscription.Read.All')
    EXPECTED RESULTS
        In -WhatIf mode (default): a printed description of the extend (or recreate) — nothing changes.
        With -Execute: the subscription's expirationDateTime moves forward (or it is recreated) and the
        new value is printed. The requested -ExtendMinutes MUST be within Graph's current max lifetime
        for a mail resource — verify against current Microsoft documentation; an over-long value is
        rejected by Graph.
.NOTES
    Azure Solutions — DEFAULTS TO -WhatIf. The repeatable way.
    The default -ExtendMinutes is a conservative placeholder; the true maximum is version-specific —
    verify against current Microsoft documentation and never hard-code a lifetime you have not checked.
#>
[CmdletBinding()]
param(
    [string]$Mailbox,
    [string]$SubscriptionId,
    [int]$ExtendMinutes = 4230,                 # placeholder — VERIFY the current max lifetime with Microsoft
    [switch]$RecreateIfMissing,
    [string]$NotificationUrl,                    # required for recreate
    [string]$ClientState,                       # required for recreate
    [string]$Resource,                          # recreate: defaults to users/<Mailbox>/messages
    [string]$ChangeType = 'created',
    [string]$Environment = 'Global',
    [switch]$Execute                            # omit for -WhatIf (default safe mode)
)

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
if (-not (Get-MgContext)) {
    Connect-MgGraph -Environment $Environment -Scopes 'Subscription.ReadWrite','Subscription.Read.All' | Out-Null
}

$whatIf = -not $Execute
$newExpiry = (Get-Date).ToUniversalTime().AddMinutes($ExtendMinutes).ToString('o')

Write-Host "`n=== Event-Driven Mail Processing — subscription renewal ===" -ForegroundColor Cyan
Write-Host ("Mode: {0}" -f $(if ($whatIf) {'WhatIf (no changes)'} else {'EXECUTE'})) -ForegroundColor $(if ($whatIf){'Yellow'}else{'Green'})
Write-Host ("Requested new expiry: {0}  (+{1} min — VERIFY within Graph max lifetime)" -f $newExpiry, $ExtendMinutes)

# Locate the target subscription
$sub = $null
try {
    if ($SubscriptionId) {
        $sub = Get-MgSubscription -SubscriptionId $SubscriptionId -ErrorAction SilentlyContinue
    } elseif ($Mailbox) {
        $sub = Get-MgSubscription -All -ErrorAction Stop |
               Where-Object { $_.Resource -match [regex]::Escape($Mailbox) -and $_.Resource -match 'messages' } |
               Select-Object -First 1
    } else {
        Write-Host "Provide -Mailbox or -SubscriptionId." -ForegroundColor Red; exit 1
    }
} catch {
    Write-Host ("Lookup failed: {0}" -f $_.Exception.Message) -ForegroundColor Yellow
}

if ($sub) {
    Write-Host ("Found subscription id={0}  resource={1}  currentExpiry={2}" -f $sub.Id, $sub.Resource, $sub.ExpirationDateTime)
    if ($whatIf) {
        Write-Host ("[WhatIf] Would extend subscription {0} to {1}. No change made. Re-run with -Execute." -f $sub.Id, $newExpiry) -ForegroundColor Yellow
    } else {
        try {
            Update-MgSubscription -SubscriptionId $sub.Id -ExpirationDateTime $newExpiry -ErrorAction Stop | Out-Null
            $after = Get-MgSubscription -SubscriptionId $sub.Id
            Write-Host ("Extended subscription {0} — new expiry {1}." -f $sub.Id, $after.ExpirationDateTime) -ForegroundColor Green
        } catch {
            Write-Host ("Extend failed (is -ExtendMinutes within the current max lifetime? verify with Microsoft): {0}" -f $_.Exception.Message) -ForegroundColor Red
        }
    }
} else {
    Write-Host "No matching subscription found (expired/deleted, or not visible to this identity)." -ForegroundColor Yellow
    if ($RecreateIfMissing) {
        if (-not $Resource -and $Mailbox) { $Resource = "users/$Mailbox/messages" }
        if (-not $NotificationUrl -or -not $ClientState -or -not $Resource) {
            Write-Host "Recreate needs -NotificationUrl, -ClientState, and a resolvable -Resource (or -Mailbox)." -ForegroundColor Red; exit 1
        }
        if ($whatIf) {
            Write-Host ("[WhatIf] Would CREATE a new subscription: resource={0} changeType={1} expiry={2}. No change made. Re-run with -Execute." -f $Resource, $ChangeType, $newExpiry) -ForegroundColor Yellow
        } else {
            try {
                $params = @{
                    changeType         = $ChangeType
                    notificationUrl    = $NotificationUrl
                    resource           = $Resource
                    expirationDateTime = $newExpiry
                    clientState        = $ClientState
                }
                $created = New-MgSubscription -BodyParameter $params -ErrorAction Stop
                Write-Host ("Recreated subscription id={0} expiry={1} (Graph re-ran the validation handshake)." -f $created.Id, $created.ExpirationDateTime) -ForegroundColor Green
            } catch {
                Write-Host ("Recreate failed (endpoint handshake or scoping?): {0}" -f $_.Exception.Message) -ForegroundColor Red
            }
        }
    }
}

Write-Host ("`nRenewal complete ({0})." -f $(if ($whatIf){'WhatIf — no changes'}else{'executed'})) -ForegroundColor $(if ($whatIf){'Yellow'}else{'Green'})
