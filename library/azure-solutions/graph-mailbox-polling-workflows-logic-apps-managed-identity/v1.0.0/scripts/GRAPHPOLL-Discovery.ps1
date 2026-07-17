<#
.SYNOPSIS
    GRAPHPOLL-Discovery.ps1 — read-only inventory for the "Graph Mailbox Polling Workflows in Azure
    Logic Apps (Managed Identity, No Service Account)" solution: the managed identity's Graph
    application-permission grants, target mailbox reachability, and current message/backlog counts.
.DESCRIPTION
    PURPOSE
        Read-only discovery. For the Logic App's managed identity (by object id) it lists the Microsoft
        Graph application (app-role) permissions granted, confirms the target mailbox
        supportmailbox@contoso.com is reachable, and reports current total / unread message counts so you
        can see the backlog before building the poller. Makes no changes.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\GRAPHPOLL-Discovery.ps1 `
            -ManagedIdentityObjectId '<managed identity object id>' `
            -Mailbox 'supportmailbox@contoso.com'
        Requires the Microsoft.Graph PowerShell SDK. The script runs Connect-MgGraph if not already
        connected. For a national cloud (e.g. GCC High / DoD), pass -Environment (e.g. 'USGov',
        'USGovDoD') so it targets the correct Graph endpoint — verify the exact name against current
        Microsoft documentation.
    GRAPH SCOPES (delegated, for this script's read-only sign-in)
        Application.Read.All, Directory.Read.All, Mail.Read (or Mail.ReadBasic.All) — read-only.
        (The workflow itself uses an APPLICATION Mail.Read permission on the managed identity; this
        script only reads configuration and counts.)
    EXPECTED RESULTS
        A snapshot: the managed identity's granted Graph app roles, whether the target mailbox resolves
        and is readable, and total/unread message counts — the readiness picture before you build the
        recurrence polling workflow.
.NOTES
    Azure Solutions — read-only. The repeatable way.
    Reports on configuration/identifiers and counts only; makes no changes to identities, permissions,
    mailboxes, or messages. White-label: examples use contoso.com only.
    Version-, scope-, throttling-, and national-cloud-specific details: verify against current Microsoft
    documentation.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string]$ManagedIdentityObjectId,
    [string]$Mailbox = 'supportmailbox@contoso.com',
    [string]$Environment = 'Global'   # e.g. 'USGov' / 'USGovDoD' for national clouds — verify exact name
)

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph)) {
    Write-Host "Installing Microsoft.Graph (CurrentUser)..." -ForegroundColor Yellow
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop

if (-not (Get-MgContext)) {
    Connect-MgGraph -Environment $Environment `
        -Scopes 'Application.Read.All','Directory.Read.All','Mail.Read' | Out-Null
}

Write-Host "`n=== Graph Mailbox Polling — discovery (read-only) ===" -ForegroundColor Cyan
Write-Host ("Managed identity object id: {0}" -f $ManagedIdentityObjectId)
Write-Host ("Target mailbox            : {0}" -f $Mailbox)

# --- Application (app-role) permissions granted to the managed identity ---
Write-Host "`n-- Granted Microsoft Graph application permissions (app roles) --" -ForegroundColor Cyan
try {
    $assignments = Get-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $ManagedIdentityObjectId -All -ErrorAction Stop
    if ($assignments) {
        # Resolve the Graph service principal so we can name the app roles.
        $graphSp = Get-MgServicePrincipal -Filter "appId eq '00000003-0000-0000-c000-000000000000'" -ErrorAction SilentlyContinue
        foreach ($a in $assignments) {
            $roleName = ($graphSp.AppRoles | Where-Object Id -eq $a.AppRoleId).Value
            if (-not $roleName) { $roleName = $a.AppRoleId }
            Write-Host ("   {0,-30} (resource: {1})" -f $roleName, $a.ResourceDisplayName)
        }
    } else {
        Write-Host "   (no application permissions granted to this identity)" -ForegroundColor Yellow
    }
} catch {
    Write-Host ("   Could not read app-role assignments: {0}" -f $_.Exception.Message) -ForegroundColor Yellow
}

# --- Target mailbox reachability + backlog counts ---
Write-Host "`n-- Target mailbox reachability + backlog --" -ForegroundColor Cyan
try {
    $inbox = Get-MgUserMailFolder -UserId $Mailbox -MailFolderId 'Inbox' -ErrorAction Stop
    Write-Host ("   Inbox reachable. Total items: {0}  Unread: {1}" -f $inbox.TotalItemCount, $inbox.UnreadItemCount) -ForegroundColor Green
    # Note whether a 'Processed' idempotency folder already exists.
    $processed = Get-MgUserMailFolder -UserId $Mailbox -All -ErrorAction SilentlyContinue |
                 Where-Object DisplayName -eq 'Processed' | Select-Object -First 1
    if ($processed) {
        Write-Host ("   'Processed' folder present. Items: {0}" -f $processed.TotalItemCount)
    } else {
        Write-Host "   'Processed' folder not found — create it before piloting (Implementation Step 4/5)." -ForegroundColor Yellow
    }
} catch {
    Write-Host ("   Could not read mailbox '{0}': {1}" -f $Mailbox, $_.Exception.Message) -ForegroundColor Yellow
    Write-Host "   (403 here usually means the app permission isn't scoped to this mailbox yet — see product #4.)" -ForegroundColor Yellow
}

Write-Host "`nDiscovery complete (read-only)." -ForegroundColor Green
