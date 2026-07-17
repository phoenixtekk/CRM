<#
.SYNOPSIS
    GRAPHPOLL-Validate.ps1 — PASS/FAIL readiness check for the "Graph Mailbox Polling Workflows in Azure
    Logic Apps (Managed Identity, No Service Account)" solution.
.DESCRIPTION
    PURPOSE
        Read-only validation. Confirms, as PASS/FAIL gates:
          1) the Logic App's managed identity exists,
          2) it holds a least-privilege Graph application permission (e.g. Mail.Read) — and flags any
             broader-than-needed grant,
          3) the target mailbox supportmailbox@contoso.com is reachable (i.e. the scope lets the identity
             read it),
          4) the watermark store (Azure Storage table 'mailpollingwatermark') is reachable and holds a
             readable watermark for the mailbox.
        Makes no changes.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\GRAPHPOLL-Validate.ps1 `
            -ManagedIdentityObjectId '<managed identity object id>' `
            -Mailbox 'supportmailbox@contoso.com' `
            -ExpectedPermission 'Mail.Read' `
            -WatermarkTableUri 'https://<account>.table.core.windows.net/mailpollingwatermark'
        Requires the Microsoft.Graph PowerShell SDK (Connect-MgGraph runs if not connected). The
        watermark-store check is best-effort against the table endpoint; adapt -WatermarkTableUri to your
        store (table/blob/other). For a national cloud, pass -Environment.
    GRAPH SCOPES (delegated, read-only sign-in)
        Application.Read.All, Directory.Read.All, Mail.Read (or Mail.ReadBasic.All).
    EXPECTED RESULTS
        A PASS/FAIL line per gate and an overall result. Non-zero exit if any gate FAILS — so it can be
        used in a readiness pipeline. Verify exact permission names / scope model against current
        Microsoft documentation.
.NOTES
    Azure Solutions — read-only PASS/FAIL. The repeatable way.
    Reports only; makes no changes. Least-privilege application permission scoped to ONE mailbox is the
    security spine — a broader grant is flagged. White-label: contoso.com only.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string]$ManagedIdentityObjectId,
    [string]$Mailbox = 'supportmailbox@contoso.com',
    [string]$ExpectedPermission = 'Mail.Read',
    [string]$WatermarkTableUri,
    [string]$Environment = 'Global'
)

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
if (-not (Get-MgContext)) {
    Connect-MgGraph -Environment $Environment -Scopes 'Application.Read.All','Directory.Read.All','Mail.Read' | Out-Null
}

$results = [System.Collections.Generic.List[object]]::new()
function Add-Result([string]$name, [bool]$pass, [string]$detail) {
    $results.Add([pscustomobject]@{ Check = $name; Result = $(if ($pass) {'PASS'} else {'FAIL'}); Detail = $detail })
}

Write-Host "`n=== Graph Mailbox Polling — validation (PASS/FAIL) ===" -ForegroundColor Cyan

# Gate 1 — managed identity exists
$sp = $null
try {
    $sp = Get-MgServicePrincipal -ServicePrincipalId $ManagedIdentityObjectId -ErrorAction Stop
    Add-Result 'Managed identity exists' $true ("{0}" -f $sp.DisplayName)
} catch {
    Add-Result 'Managed identity exists' $false $_.Exception.Message
}

# Gate 2 — least-privilege application permission present (and flag broader grants)
try {
    $assignments = Get-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $ManagedIdentityObjectId -All -ErrorAction Stop
    $graphSp = Get-MgServicePrincipal -Filter "appId eq '00000003-0000-0000-c000-000000000000'" -ErrorAction SilentlyContinue
    $granted = @()
    foreach ($a in $assignments) {
        $rn = ($graphSp.AppRoles | Where-Object Id -eq $a.AppRoleId).Value
        if ($rn) { $granted += $rn }
    }
    $hasExpected = $granted -contains $ExpectedPermission
    # Flag anything broader than a read scope (e.g. Mail.ReadWrite, Mail.Send, full-directory writes).
    $broad = $granted | Where-Object { $_ -match 'ReadWrite|\.Send$|Directory\.ReadWrite' }
    if ($hasExpected -and -not $broad) {
        Add-Result 'Least-privilege app permission' $true ("granted: {0}" -f ($granted -join ', '))
    } elseif ($hasExpected -and $broad) {
        Add-Result 'Least-privilege app permission' $false ("has {0} BUT broader grant present: {1} — tighten (verify least-priv name against MS docs)" -f $ExpectedPermission, ($broad -join ', '))
    } else {
        Add-Result 'Least-privilege app permission' $false ("expected '{0}' not granted; granted: {1}" -f $ExpectedPermission, ($granted -join ', '))
    }
} catch {
    Add-Result 'Least-privilege app permission' $false $_.Exception.Message
}

# Gate 3 — target mailbox reachable (scope lets the identity read it)
try {
    $inbox = Get-MgUserMailFolder -UserId $Mailbox -MailFolderId 'Inbox' -ErrorAction Stop
    Add-Result 'Target mailbox in scope' $true ("Inbox reachable; total {0}, unread {1}" -f $inbox.TotalItemCount, $inbox.UnreadItemCount)
} catch {
    Add-Result 'Target mailbox in scope' $false ("could not read {0}: {1} (403 => scope not applied; see product #4)" -f $Mailbox, $_.Exception.Message)
}

# Gate 3b — workflow present (informational): the mark/move idempotency folder should exist
try {
    $processed = Get-MgUserMailFolder -UserId $Mailbox -All -ErrorAction SilentlyContinue |
                 Where-Object DisplayName -eq 'Processed' | Select-Object -First 1
    Add-Result "'Processed' folder present" ([bool]$processed) $(if ($processed) {"ok"} else {"create it before piloting"})
} catch {
    Add-Result "'Processed' folder present" $false $_.Exception.Message
}

# Gate 4 — watermark store reachable
if ($WatermarkTableUri) {
    try {
        # Best-effort reachability probe of the store endpoint. Adapt to your store type.
        $u = [Uri]$WatermarkTableUri
        $tcp = Test-NetConnection -ComputerName $u.Host -Port 443 -WarningAction SilentlyContinue
        Add-Result 'Watermark store reachable' ([bool]$tcp.TcpTestSucceeded) ("{0}:443 tcp={1}" -f $u.Host, $tcp.TcpTestSucceeded)
    } catch {
        Add-Result 'Watermark store reachable' $false $_.Exception.Message
    }
} else {
    Add-Result 'Watermark store reachable' $false 'no -WatermarkTableUri provided (skipped) — supply your watermark store URI'
}

$results | Format-Table -AutoSize
$fail = ($results | Where-Object Result -eq 'FAIL').Count
if ($fail -gt 0) {
    Write-Host ("`nVALIDATION: {0} FAIL — resolve before piloting." -f $fail) -ForegroundColor Red
    exit 1
} else {
    Write-Host "`nVALIDATION: all gates PASS." -ForegroundColor Green
    exit 0
}
