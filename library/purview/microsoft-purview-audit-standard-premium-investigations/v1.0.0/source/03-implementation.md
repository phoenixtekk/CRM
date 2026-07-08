# 3. Implementation Guide — Microsoft Purview Audit (Standard & Premium)

Follow these steps **in order**. Configuration uses the **Microsoft Purview portal**
(`https://purview.microsoft.com`), **Exchange Online PowerShell** (`Connect-ExchangeOnline` — search,
`Get/Set-AdminAuditLogConfig`, mailbox audit), **Security & Compliance PowerShell**
(`Connect-IPPSSession` — the `*-UnifiedAuditLogRetentionPolicy` cmdlets), and **Microsoft Graph**
(licensing, Audit Log Query API). Every write is gated: scripts run **read-only or `-WhatIf` by
default** and only change state with `-Commit`. Artifact names follow the `<Purpose> – <Scope> – <Stage>`
convention from the Overview and are reused verbatim.

> **Model:** Assess what auditing/licensing you have, design the coverage, configure logging/retention/
> export, **pilot** on a limited scope in read/report mode, validate you can answer the incident
> questions, then expand. Pattern: **Assess → Design → Configure → Pilot → Validate → Expand.**
> **Audit is not retroactive** — every day this is deferred is a day of history you will not have.

## Step 1 — Assess the current audit state and licensing (Assess)
1. Run `PURVAUDIT-Discovery.ps1` (read-only). It connects to Exchange Online, S&C PowerShell, and Graph and reports:
   - `UnifiedAuditLogIngestionEnabled` (is unified audit on?),
   - org mailbox-audit state (`AuditDisabled`) and any mailbox **audit-bypass** associations,
   - whether an **Audit Premium**-bearing plan (E5 / Audit add-on) is present and how many users carry it,
   - existing **audit log retention policies** (`Get-UnifiedAuditLogRetentionPolicy`).
2. In the Purview portal, confirm **Audit** is visible under `Solutions → Audit` (visibility depends on role and licensing — Requirement 2.1/2.2).
3. Record the gaps: logging off, Premium not licensed where expected, unexpected bypass, no retention policies. These drive the steps below. **Pass gate:** you have a written current-state for each item.

## Step 2 — Design the retention and investigation coverage (Design)
1. With your compliance/records/legal stakeholders (Requirement 2.6), agree the retention per record-type class and map it to the three standard policies:
   - `Audit Retention – Mailbox High-Value – Premium` — Exchange mailbox high-value events (`MailItemsAccessed`, `Send`, `SendAs`, inbox-rule operations).
   - `Audit Retention – Privileged Actions – LongTerm` — Entra/admin privileged operations (role adds, app consents, credential/MFA changes).
   - `Audit Retention – Sign-in Events – Standard+` — authentication events (`UserLoggedIn`, `MailboxLogin`).
2. Agree the investigation scenarios and their runbooks (`Investigation – Mailbox Compromise – Runbook`, `Investigation – Data Exfiltration – Runbook`, `Investigation – Privilege Escalation – Runbook`) — Step 6 builds them.
3. Define the **pilot scope** `Audit Pilot – Investigators – Stage1` (Requirement 2.8). **Pass gate:** retention durations, runbooks, and pilot are documented and approved.

## Step 3 — Enable the foundation: unified audit + mailbox auditing (Configure)
1. If Step 1 showed unified audit **off**, enable it under change control:
   `PURVAUDIT-Set-RetentionPolicy.ps1 -EnableUnifiedAudit -WhatIf` → review → re-run with `-Commit`. (This runs `Set-AdminAuditLogConfig -UnifiedAuditLogIngestionEnabled $true`; activation can take time.)
2. Confirm org mailbox auditing is on (`AuditDisabled = False`) and remove any **unintended** audit-bypass (Requirement 2.5) — change-controlled, one account at a time, with justification.
3. **Pass gate:** re-run `PURVAUDIT-Discovery.ps1` — ingestion is `True`, mailbox auditing on, no unexpected bypass. **Rollback:** enabling audit is non-destructive; if a bypass removal is questioned, re-add it (`-AuditBypassEnabled $true`) pending review.

## Step 4 — Configure audit log retention policies (Configure)
1. Create the three designed policies with the helper, **pilot-first** (`-WhatIf` prints the exact `New-UnifiedAuditLogRetentionPolicy` it would run):
   - `PURVAUDIT-Set-RetentionPolicy.ps1 -PolicyName "Audit Retention – Mailbox High-Value – Premium" -RecordTypes ExchangeItem -Operations MailItemsAccessed,Send,SendAs,New-InboxRule,Set-InboxRule -Duration TenYears -Priority 100 -WhatIf`
   - `PURVAUDIT-Set-RetentionPolicy.ps1 -PolicyName "Audit Retention – Privileged Actions – LongTerm" -RecordTypes AzureActiveDirectory -Duration TenYears -Priority 200 -WhatIf`
   - `PURVAUDIT-Set-RetentionPolicy.ps1 -PolicyName "Audit Retention – Sign-in Events – Standard+" -RecordTypes AzureActiveDirectoryStsLogon -Duration OneYear -Priority 300 -WhatIf`
2. Review each `-WhatIf` line. Confirm the **record types**, **operations**, **duration**, and a **unique priority** (lower = evaluated first). **Verify accepted `RetentionDuration` values and that the ten-year tier is licensed in your tenant** (Requirement 2.1) before committing.
3. Re-run each with `-Commit` to create the policy in Security & Compliance PowerShell.
4. **Pass gate:** `PURVAUDIT-Discovery.ps1` lists the three policies with the expected durations/priorities. **Rollback:** `PURVAUDIT-Set-RetentionPolicy.ps1 -PolicyName "<name>" -Remove -Commit` (removes the policy; already-retained records age out by remaining rules).

## Step 5 — Validate high-value events are being captured (Configure → Pilot)
1. For a **pilot mailbox** that carries Audit Premium, generate benign activity (open a message, send a test mail), wait for latency, then run:
   `PURVAUDIT-Search.ps1 -Operations MailItemsAccessed,Send -UserIds pilot.user@contoso.com -Start (Get-Date).AddDays(-1) -End (Get-Date)`
2. Confirm `MailItemsAccessed` / `Send` records appear for the licensed pilot user. If they don't, check the license (2.1), mailbox auditing (2.5), and bypass — not the search.
3. **Pass gate:** high-value events are present for a licensed user. This is the concrete proof Premium is working; unlicensed users legitimately won't show these.

## Step 6 — Build the investigation runbooks (Configure)
Encode the standard incident questions as saved, repeatable searches. Each runbook is a documented set of `PURVAUDIT-Search.ps1` invocations (operations + record types) with a short "what this answers":
1. `Investigation – Mailbox Compromise – Runbook`:
   - Which messages did the attacker read? → `-Operations MailItemsAccessed` (Premium).
   - Did they create forwarding/inbox rules? → `-Operations New-InboxRule,Set-InboxRule,UpdateInboxRules,Set-Mailbox`.
   - Suspicious sign-ins? → `-Operations UserLoggedIn,MailboxLogin -RecordType AzureActiveDirectoryStsLogon` (corroborate with Entra sign-in logs).
2. `Investigation – Data Exfiltration – Runbook`:
   - What did a departing user download/sync? → `-Operations FileDownloaded,FileSyncDownloadedFull -RecordType SharePointFileOperation`.
   - Large or unusual searches? → `-Operations SearchQueryInitiatedExchange,SearchQueryInitiatedSharePoint` (Premium).
   - External sharing? → `-Operations SharingInvitationCreated,AnonymousLinkCreated`.
3. `Investigation – Privilege Escalation – Runbook`:
   - Who was added to a privileged role/group? → `-Operations "Add member to role.","Add member to group."`.
   - App consent / credential abuse? → `-Operations "Consent to application.","Add app role assignment grant to user.","Update user."`.
4. Store each runbook (the exact commands + interpretation notes) alongside this guide. **Pass gate:** each runbook returns results against test/benign activity for a licensed user.

## Step 7 — Wire SIEM/export (Configure → Pilot)
1. Decide the export path (Requirement 2.7): the **Office 365 Management Activity API** (this solution's helper) or a **native connector** (e.g. Microsoft Sentinel's Microsoft 365 / Office 365 connector — lower-effort, recommended where available).
2. For the Management Activity API, list current subscriptions read-only:
   `PURVAUDIT-Export.ps1 -TenantId <guid> -AppId <guid> -CertificateThumbprint <thumb> -Action ListSubscriptions`
3. Start the content subscriptions you need (pilot with one content type first):
   `PURVAUDIT-Export.ps1 ... -Action StartSubscription -ContentType Audit.AzureActiveDirectory -WhatIf` → review → `-Commit`. Repeat for `Audit.Exchange`, `Audit.SharePoint`, `Audit.General` as scoped. Label the effort `Audit Export – Management Activity API – SIEM`.
4. **Pass gate:** subscriptions show `enabled`; your SIEM receives content blobs. **Rollback:** `-Action StopSubscription -ContentType <type> -Commit`.

## Step 8 — Validate investigation-readiness (Validate)
1. Run `PURVAUDIT-Report.ps1` to produce `Audit Readiness – Tenant – Report` — a scorecard across: unified audit on, Premium licensed where expected, high-value events present in recent data, the three retention policies in place, and export active.
2. Walk the runbooks (Step 6) against the pilot scope and confirm each incident question returns an answer. Complete the **Testing Guide** before expanding.
3. **Pass gate:** the readiness report is green on every gate for the pilot scope.

## Step 9 — Expand and operationalize (Expand)
1. Once the pilot passes, extend retention/export coverage to the full agreed scope and confirm Premium licensing covers all users who need high-value events.
2. Schedule the read-only chain (`PURVAUDIT-Discovery.ps1` → `PURVAUDIT-Report.ps1`) on a cadence so drift — logging disabled, a new bypass, a lapsed license, a stopped subscription — is caught early, and re-run the runbooks during real investigations.
3. Hand the runbooks and the readiness report to your SOC/investigators as the standing procedure. **Pass gate:** readiness is green tenant-wide and the monitoring cadence is scheduled.
