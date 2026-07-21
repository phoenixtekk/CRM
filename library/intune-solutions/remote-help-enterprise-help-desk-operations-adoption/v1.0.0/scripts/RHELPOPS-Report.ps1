<#
.SYNOPSIS
    RHELPOPS-Report.ps1 — export Remote Help usage / outcome / adoption KPIs to CSV (Graph).
.DESCRIPTION
    PURPOSE
        Pulls the Remote Help usage/audit activity available via Graph and shapes it into the
        operating-model KPIs: session volume (overall and, where derivable, per tier), attended vs
        unattended counts, and the raw activity needed to compute average handle time, first-contact
        resolution, escalation rate, consent/decline rate, and adoption rate. Outcome/adoption KPIs
        that the platform cannot show are exported as columns for you to complete from ITSM ticket
        data. Read-only.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\RHELPOPS-Report.ps1 -Days 30 -CsvPath C:\Temp\rhelpops-kpis.csv
        Requires the Microsoft Graph PowerShell SDK.
    GRAPH SCOPES
        DeviceManagementApps.Read.All, AuditLog.Read.All
        (Verify the current Remote Help usage endpoint/scopes against Microsoft documentation — the
         data exposed via Graph vs. the Intune portal usage report changes over time.)
    EXPECTED RESULTS
        A console summary of the KPIs that can be computed from platform data, plus a CSV at -CsvPath
        containing per-session rows and KPI columns (platform-derived populated; ITSM-dependent left
        blank to fill from ticket data). Changes nothing.
.NOTES
    White-label — Intune Solutions. Read-only against Graph.
    Combine this export with your ITSM ticket data to complete outcome + adoption KPIs.
#>
[CmdletBinding()] param(
    [int]$Days = 30,
    [string]$CsvPath
)

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'DeviceManagementApps.Read.All' -NoWelcome

$since = (Get-Date).AddDays(-$Days)
$rows = @()
try {
    $events = (Invoke-MgGraphRequest -Method GET -Uri '/beta/deviceManagement/auditEvents?$top=500').value
    $rh = $events | Where-Object {
        ($_.category -match 'RemoteAssistance|RemoteHelp') -or ($_.displayName -match 'Remote Help|Remote Assistance')
    } | Where-Object { [datetime]$_.activityDateTime -ge $since }

    foreach ($e in $rh) {
        $rows += [pscustomobject]@{
            Time             = $e.activityDateTime
            Activity         = $e.displayName
            Agent            = $e.actor.userPrincipalName
            Category         = $e.category
            # Tier is derived from the agent's group membership in your tenant; left for enrichment.
            Tier             = ''
            AttendedOrUnattended = ''   # populate from ticket log (Step 5b) — platform may not distinguish
            HandleTimeMin    = ''       # from session start/end on the ticket
            FirstContactResolved = ''   # from ticket outcome
            Escalated        = ''       # from ticket escalation
            ConsentResult    = ''       # consent / decline, from session where available
            TicketId         = ''       # link to ITSM ticket
        }
    }
} catch {
    Write-Host "Could not read Remote Help usage via this Graph endpoint — verify the current endpoint against Microsoft documentation, or use Intune > Tenant administration > Remote Help usage report." -ForegroundColor Yellow
}

$total = $rows.Count
Write-Host "===== Remote Help KPI summary (last $Days days) =====" -ForegroundColor Cyan
Write-Host ("Session/activity volume (platform): {0}" -f $total)
Write-Host "Per-tier volume, attended vs unattended, handle time, FCR, escalation, consent, adoption:"
Write-Host "  complete these from the CSV once enriched with ITSM ticket data (columns provided)." -ForegroundColor DarkGray

if ($CsvPath) {
    if ($total) { $rows | Sort-Object Time -Descending | Export-Csv -Path $CsvPath -NoTypeInformation }
    else {
        # still emit the header/columns so the analyst has the KPI template
        [pscustomobject]@{ Time='';Activity='';Agent='';Category='';Tier='';AttendedOrUnattended='';HandleTimeMin='';FirstContactResolved='';Escalated='';ConsentResult='';TicketId='' } |
            Export-Csv -Path $CsvPath -NoTypeInformation
    }
    Write-Host ("Saved KPI export: {0}" -f $CsvPath) -ForegroundColor Green
} else {
    if ($total) { $rows | Sort-Object Time -Descending | Select-Object -First 25 | Format-Table -AutoSize }
    Write-Host "Tip: pass -CsvPath to export the full KPI template." -ForegroundColor DarkGray
}
Disconnect-MgGraph | Out-Null
