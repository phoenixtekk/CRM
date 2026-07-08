# 6. Troubleshooting — Microsoft Purview Audit (Standard & Premium)

The failure modes that make audit "find nothing," plus the configuration and export issues you'll hit.
Each: **symptom → likely cause → fix.** Many "audit is broken" reports are actually latency, licensing,
or bypass — this guide separates those from real faults.

## Search returns nothing for a user you know was active
- **Cause A — ingestion latency.** Recent activity isn't searchable immediately; events can take time to appear. **Fix:** widen the window into the past and retest before concluding absence. `PURVAUDIT-Search.ps1` reminds you of this when it returns zero.
- **Cause B — high-value events aren't licensed.** `MailItemsAccessed`, `Send`, `SearchQueryInitiated*` only exist for users with **Audit Premium** (E5 / Audit add-on) assigned. An unlicensed user legitimately shows none. **Fix:** confirm the per-user license (`PURVAUDIT-Discovery.ps1` licensing section); document "no high-value events = unlicensed, not all-clear."
- **Cause C — mailbox audit bypass.** The account is on the audit-bypass list, silently suppressing its mailbox events. **Fix:** `PURVAUDIT-Discovery.ps1` enumerates bypass; remove unintended bypass with `Set-MailboxAuditBypassAssociation -Identity <user> -AuditBypassEnabled $false`.
- **Cause D — unified audit is off.** No records are being written at all. **Fix:** enable it (Step 3); note it is **not retroactive**.

## Search returns far fewer results than expected (truncation)
- **Cause:** `Search-UnifiedAuditLog` caps a single call's results; without paging you silently get only the first block.
- **Fix:** always page with `SessionCommand ReturnLargeSet` and a stable `SessionId` (the provided `PURVAUDIT-Search.ps1` does this and prints the running total) and **keep the time window short** — split large windows into smaller ones.

## `UnifiedAuditLogIngestionEnabled` won't flip to True / is slow
- **Cause:** enabling ingestion can take time to fully activate; also requires the right role and a completed org customization.
- **Fix:** run `PURVAUDIT-Set-RetentionPolicy.ps1 -EnableUnifiedAudit -Commit`, then allow activation time and recheck with `PURVAUDIT-Discovery.ps1`. If the cmdlet errors on permissions, confirm the Audit/Exchange role (Requirement 2.2).

## `MailItemsAccessed` still missing after licensing looks right
- **Cause:** org or per-mailbox mailbox auditing disabled, or the mailbox is bypassed, or the license was only just assigned (events start after activation).
- **Fix:** confirm `AuditDisabled = False` (`Get-OrganizationConfig`), remove bypass, and remember high-value events only accrue **after** the license and auditing are active — earlier history won't appear.

## Retention policy cmdlet not found / "term not recognized"
- **Cause:** wrong endpoint. `New-/Set-/Get-/Remove-UnifiedAuditLogRetentionPolicy` are **Security & Compliance PowerShell** (`Connect-IPPSSession`), not Exchange Online.
- **Fix:** connect with `Connect-IPPSSession` for retention-policy work; use `Connect-ExchangeOnline` for `Search-UnifiedAuditLog` and `Get/Set-AdminAuditLogConfig`. Both ship in the `ExchangeOnlineManagement` module.

## Retention policy create fails on duration or priority
- **Cause A — duration/licensing.** The `RetentionDuration` value isn't accepted for your plan, or `TenYears` is requested without the ten-year add-on. **Fix:** verify accepted `RetentionDuration` values and that the tier is licensed (Requirement 2.1) before `-Commit`.
- **Cause B — duplicate priority.** Priorities must be **unique**. **Fix:** pick an unused priority (e.g. 100/200/300); lower is evaluated first.

## Retention policy doesn't seem to keep events
- **Cause:** a higher-priority (lower-number) broad policy is matching first, or the record types/operations don't match the events. **Fix:** review priority ordering and confirm the `RecordTypes`/`Operations` actually match the events (check a sample record's `RecordType`/`Operations` in `PURVAUDIT-Search.ps1` output). Note policies apply **going forward**.

## Audit visible for some admins but not others
- **Cause:** missing Audit role. Searching needs **View-Only Audit Logs / Audit Logs** (packaged as **Audit Reader/Manager**).
- **Fix:** assign the least-privilege Audit role group (Requirement 2.2); Global Admin is not required just to search.

## Management Activity API export: token or permission errors
- **Cause A — permissions/consent.** The app lacks `ActivityFeed.Read` (or `ActivityFeed.ReadDlp` for DLP) or admin consent wasn't granted. **Fix:** grant + consent the `ActivityFeed.*` application permissions in Entra.
- **Cause B — certificate.** The thumbprint isn't in the local store with its private key, or the cert isn't uploaded to the app. **Fix:** confirm `Cert:\CurrentUser\My\<thumb>` (or LocalMachine) resolves and the matching public cert is on the app registration. `PURVAUDIT-Export.ps1` uses certificate app-only auth — **no client secret**.
- **Cause C — subscription not started.** Listing shows the content type absent. **Fix:** `PURVAUDIT-Export.ps1 -Action StartSubscription -ContentType <type> -Commit`.

## SIEM shows no data even though subscriptions are "enabled"
- **Cause:** the subscription is started but nothing is pulling/receiving the content blobs, or the connector is misconfigured.
- **Fix:** for the raw API, confirm your collector is calling `subscriptions/content` and retrieving blobs; consider a **native connector** (e.g. Microsoft Sentinel's Microsoft 365 / Office 365 connector) which handles polling for you. Verify with `PURVAUDIT-Export.ps1 -Action ListAvailableContent -ContentType <type>`.

## Timestamps don't line up with other logs
- **Cause:** audit `CreationDate` is **UTC**.
- **Fix:** normalize to UTC when correlating with Entra sign-in logs, message trace, or endpoint logs.

## When to escalate beyond this solution
- **Retention-schedule adequacy, legal hold, or regulatory obligation** questions → **compliance, records, privacy, and legal** functions (this solution configures to their schedule; it does not set it).
- **Suspected active compromise** → your incident-response process; use the runbooks to gather evidence, but containment/eradication is IR, not audit configuration.
- **Feature genuinely absent despite correct licensing** → verify against current Microsoft documentation and open a Microsoft support case; Purview capabilities and search tooling evolve.
