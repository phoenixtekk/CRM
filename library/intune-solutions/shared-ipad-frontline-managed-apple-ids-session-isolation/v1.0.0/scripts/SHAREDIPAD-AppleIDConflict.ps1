<#
.SYNOPSIS
    SHAREDIPAD-AppleIDConflict.ps1 — builds the Entra-side CANDIDATE worklist for the Managed Apple ID
    reclamation campaign.

.DESCRIPTION
    PURPOSE
        Every Shared iPad user needs a Managed Apple ID issued by Apple Business Manager. ABM CANNOT
        issue a Managed Apple ID at an address that is already in use by a PERSONAL Apple ID — so any
        staff member who once created a personal Apple ID with their work email address is a blocked
        Shared iPad user until that conflict is resolved (Requirements R14).

        This script reads Microsoft Entra ID and produces the CANDIDATE worklist: every user who would
        need a Managed Apple ID, with the address that would be used, exported to CSV with tracking
        columns for the reclamation campaign.

        READ-ONLY. This script makes no changes of any kind.

    *** READ THIS — WHAT THIS SCRIPT IS NOT ***
        THIS SCRIPT CANNOT QUERY APPLE. It has no visibility of Apple ID state whatsoever.
        It CANNOT tell you which addresses actually collide with a personal Apple ID.

        THE AUTHORITATIVE CONFLICT LIST COMES FROM APPLE BUSINESS MANAGER — ABM is the only source
        that knows which addresses on your verified domain are already in use by a personal Apple ID.

        What this script gives you is the CANDIDATE / TRACKING list:
            * WHO would need a Managed Apple ID (so you know the size of the campaign).
            * WHICH address would be used (so you know what to reconcile against ABM).
            * A tracking skeleton (Status / ABMConflict / ResolvedDate / Notes) to run the campaign in.

        The correct workflow is:
            1. Run this script  -> candidate list (planning + tracking).
            2. Get the conflict list from ABM  -> truth.
            3. Reconcile 2 into 1  -> your campaign worklist.
        See Implementation Step 3.

    *** THE DECISION IS NOT YOURS ***
        Whether to require staff to rename or surrender a personal Apple ID tied to their work address
        is an IDENTITY, HR, LEGAL, and COMMUNICATIONS decision. It reaches the staff member's personal
        iPhone, personal Mac, iCloud photo library, and App Store purchases — not just the work iPad.
        Present the options and their impact to the customer's HR, legal, and identity owners and let
        THEM decide. Do not make the call, and do not let running this script become the decision.
        Do not send a single staff notification without executive sponsorship and an agreed
        communications plan and grace period (Requirements R18).

    HOW TO RUN
        Install-Module Microsoft.Graph -Scope CurrentUser      # once

        # Pilot scope — just the two test users:
        .\SHAREDIPAD-AppleIDConflict.ps1 -GroupName 'PILOT – Shared iPad Users' -CsvPath .\appleid-candidates-pilot.csv

        # Campaign scope — a domain:
        .\SHAREDIPAD-AppleIDConflict.ps1 -Domain 'contoso.com' -CsvPath .\appleid-candidates.csv

        # Campaign scope — a group of frontline staff:
        .\SHAREDIPAD-AppleIDConflict.ps1 -GroupName 'Frontline Field Staff' -CsvPath .\appleid-candidates.csv

    REQUIRED GRAPH SCOPES
        User.Read.All       (read user UPN / mail / department / account state)
        Group.Read.All      (resolve -GroupName membership)

    EXPECTED RESULTS
        A summary count and a CSV containing one row per candidate user with the address that would
        become their Managed Apple ID, plus empty tracking columns to fill in from ABM and as the
        campaign progresses. Reconcile the CSV against the ABM conflict list before acting on it.

.NOTES
    Intune Solutions — read-only. Makes no changes. Cannot query Apple.
#>
[CmdletBinding()]
param(
    [string]$GroupName,
    [string]$Domain,
    [string]$CsvPath = '.\appleid-candidates.csv',

    # The address form ABM would issue the Managed Apple ID on. 'Mail' = the user's primary SMTP
    # address; 'UPN' = the userPrincipalName. Confirm which your ABM/federation configuration uses
    # before you rely on this column — VERIFY WITH APPLE.
    [ValidateSet('Mail','UPN')]
    [string]$AddressSource = 'Mail'
)

$ErrorActionPreference = 'Stop'

Connect-MgGraph -Scopes @('User.Read.All','Group.Read.All') | Out-Null

function Get-GraphCollection {
    param([string]$Uri)
    $items = @(); $next = $Uri
    while ($next) {
        $page = Invoke-MgGraphRequest -Method GET -Uri $next
        if ($page.value) { $items += $page.value }
        $next = $page.'@odata.nextLink'
    }
    return $items
}

Write-Host ''
Write-Host '=== Managed Apple ID — CANDIDATE worklist (read-only, Entra-side only) ===' -ForegroundColor Cyan
Write-Host ''
Write-Host ' THIS SCRIPT CANNOT QUERY APPLE.' -ForegroundColor Yellow
Write-Host ' It produces the CANDIDATE list — who would need a Managed Apple ID and at which address.' -ForegroundColor Yellow
Write-Host ' The AUTHORITATIVE list of addresses that actually conflict with a personal Apple ID comes' -ForegroundColor Yellow
Write-Host ' from APPLE BUSINESS MANAGER. Reconcile this CSV against ABM before acting on it.' -ForegroundColor Yellow
Write-Host ''

$select = 'id,displayName,userPrincipalName,mail,department,jobTitle,accountEnabled,userType,companyName'
$users  = @()

if ($GroupName) {
    $escaped = $GroupName.Replace("'", "''")
    $grp = Get-GraphCollection -Uri "https://graph.microsoft.com/v1.0/groups?`$filter=displayName eq '$escaped'&`$select=id,displayName"
    if (-not $grp) { throw "Group '$GroupName' not found. Check the name — it must match exactly (note the en dash in 'PILOT – Shared iPad Users')." }
    Write-Host "Scope: group '$GroupName'" -ForegroundColor Cyan
    $users = Get-GraphCollection -Uri "https://graph.microsoft.com/v1.0/groups/$($grp[0].id)/members/microsoft.graph.user?`$select=$select"
}
elseif ($Domain) {
    Write-Host "Scope: domain '$Domain'" -ForegroundColor Cyan
    $all = Get-GraphCollection -Uri "https://graph.microsoft.com/v1.0/users?`$select=$select&`$top=999"
    $users = $all | Where-Object {
        ($_.userPrincipalName -and $_.userPrincipalName -like "*@$Domain") -or
        ($_.mail -and $_.mail -like "*@$Domain")
    }
}
else {
    throw "Specify a scope: -GroupName '<Entra group>' or -Domain '<contoso.com>'. Do not run this unscoped across the whole tenant — you will produce a worklist nobody can action."
}

if (-not $users) {
    Write-Host 'No users found in scope.' -ForegroundColor Yellow
    return
}

$candidates = foreach ($u in $users) {
    $address = if ($AddressSource -eq 'Mail') {
        if ($u.mail) { $u.mail } else { $u.userPrincipalName }
    } else {
        $u.userPrincipalName
    }

    # Flag rows the campaign owner must look at by hand before including them.
    $notes = @()
    if (-not $u.mail)                 { $notes += 'no primary SMTP address — UPN used; confirm the address ABM will issue on' }
    if (-not $u.accountEnabled)       { $notes += 'account DISABLED — should this person be in the campaign at all?' }
    if ($u.userType -eq 'Guest')      { $notes += 'GUEST account — almost certainly out of scope; exclude' }
    if ($address -and $address -notmatch '^[^@]+@[^@]+\.[^@]+$') { $notes += 'address does not look like a valid email — check' }
    if ($u.mail -and $u.userPrincipalName -and $u.mail -ne $u.userPrincipalName) {
        $notes += 'mail and UPN DIFFER — confirm which address ABM issues the Managed Apple ID on (VERIFY WITH APPLE)'
    }

    [pscustomobject]@{
        DisplayName        = $u.displayName
        UserPrincipalName  = $u.userPrincipalName
        Mail               = $u.mail
        # The address that would become this person's Managed Apple ID — and therefore the address
        # that MAY already be in use by their personal Apple ID.
        CandidateAppleID   = $address
        Department         = $u.department
        JobTitle           = $u.jobTitle
        AccountEnabled     = $u.accountEnabled
        UserType           = $u.userType

        # --- Campaign tracking columns. Fill these in; this script cannot. ---
        # Fill from Apple Business Manager: Yes / No / Unknown. ABM IS THE ONLY SOURCE OF TRUTH.
        ABMConflict        = 'UNKNOWN — get from Apple Business Manager'
        # Not started / Notified / In progress / Resolved / Refused / Excluded
        Status             = 'Not started'
        NotifiedDate       = ''
        ResolvedDate       = ''
        ManagedAppleIDIssued = ''
        Notes              = ($notes -join '; ')
    }
}

$candidates = $candidates | Sort-Object Department, DisplayName

Write-Host '--- Candidates ---' -ForegroundColor Cyan
$candidates | Format-Table DisplayName, CandidateAppleID, Department, AccountEnabled, Notes -AutoSize

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
$needsReview = @($candidates | Where-Object { $_.Notes })
Write-Host ''
Write-Host '--- Summary ---' -ForegroundColor Cyan
Write-Host "  Candidate users needing a Managed Apple ID:  $($candidates.Count)"
Write-Host "  Rows flagged for manual review:              $($needsReview.Count)" -ForegroundColor $(if ($needsReview.Count) { 'Yellow' } else { 'Green' })
Write-Host ''
Write-Host "  How many of these ACTUALLY conflict with a personal Apple ID: UNKNOWN." -ForegroundColor Yellow
Write-Host "  This script cannot know. Only Apple Business Manager can tell you." -ForegroundColor Yellow

$candidates | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8
Write-Host ''
Write-Host "Candidate worklist exported to: $CsvPath" -ForegroundColor Green

Write-Host ''
Write-Host '--- What to do next ---' -ForegroundColor Cyan
Write-Host '  1. Sign in to Apple Business Manager (https://business.apple.com) and confirm your domain'
Write-Host '     is verified (R5). Obtain the AUTHORITATIVE list of addresses on that domain already in'
Write-Host '     use by a personal Apple ID. VERIFY WITH APPLE — the flow name, the ABM navigation, what'
Write-Host '     Apple notifies the user, the grace period, and the outcome for non-responders are'
Write-Host "     Apple's and they change. Get them from current ABM documentation."
Write-Host '  2. Fill the ABMConflict column in the CSV from that list. ABM is the truth; the CSV is the'
Write-Host '     tracker.'
Write-Host '  3. Take the OPTIONS to the customer HR, legal, and identity owners and let THEM decide'
Write-Host '     (Implementation Step 3c). This touches personal devices and personal data. It is not a'
Write-Host '     technical decision and it is not yours to make.'
Write-Host '  4. Only after sponsorship and an agreed comms plan and grace period exist (R18), run the'
Write-Host '     campaign and track Status in this CSV.'
Write-Host '  5. GATE: your PILOT – Shared iPad Users must be clear of conflict before the pilot'
Write-Host '     (Implementation Step 12). A conflicted user cannot sign in and the pilot will fail at'
Write-Host '     Test 4.'
