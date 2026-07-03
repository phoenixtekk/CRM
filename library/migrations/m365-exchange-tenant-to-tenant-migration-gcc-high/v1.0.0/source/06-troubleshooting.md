# Troubleshooting — Exchange Online Tenant-to-Tenant Migration (Government / GCC High)

Diagnosis for the failures you actually hit during a GCC High move. Symptoms are grouped; each has cause, GCC-High context, and fix. Run the read-only scripts (`EXOMIGG-Validation.ps1`, `EXOMIGG-Report.ps1`) to confirm state before and after any change.

---

## 1. "Tenant not found" / login redirects to the wrong place / auth fails

**Symptom.** `Connect-MgGraph` or `Connect-ExchangeOnline` errors, redirects to `login.microsoftonline.com`, or reports the tenant doesn't exist even though it does.

**Cause.** The tool is authenticating against the **Commercial** cloud. This is the single most common GCC High problem.

**Fix.**
- Exchange: `Connect-ExchangeOnline -ExchangeEnvironmentName O365USGovGCCHigh` (do **not** also pass `-ConnectionUri`).
- Graph: `Connect-MgGraph -Environment USGov`.
- Confirm the sign-in URL is **`login.microsoftonline.us`** and portals are **`*.us`**.
- Update modules if the environment value is unrecognized (R5). (Microsoft Learn, *Connect to Exchange Online PowerShell*; *national cloud deployments*.)

---

## 2. Native cross-tenant migration option is missing or blocked

**Symptom.** The native cross-tenant move can't be configured, or an org-relationship `-MailboxMoveCapability` step fails.

**Cause.** Either a **cross-cloud** attempt (unsupported) or a **preview-availability** gap in GCC High.

**Fix.**
- If either tenant is **Commercial**: native is **not supported** across clouds — switch to a **third-party tool or PST** (R7). *"Cross cloud tenant to tenant migration isn't supported."*
- If both are **GCC High**: native cross-tenant is **Public Preview** in government clouds — **confirm eligibility with Microsoft / your account team** before proceeding. Use a third-party tool if preview access isn't available. (verify for GCC High.)
- Ensure the org relationship is created by an **Organization Administrator** — "Only the organization administrator can alter the `-MailboxMoveCapability` setting." (Microsoft Learn.)

---

## 3. `CrossTenantMigrationWithoutLicensePermanentException`

**Symptom.** A native move fails with: *"No license was found for the source recipient … or the target recipient. A Cross-tenant User Data Migration license is required."*

**Cause.** Missing the **Cross-Tenant User Data Migration** add-on. It is enforced — "Migrations fail if this step isn't completed. Microsoft doesn't offer exceptions."

**Fix.** Assign the add-on to the migrating user (source or target object). In GCC High, purchase it through your **authorized US Gov reseller / AOS-G partner**; **verify it is orderable on your Gov agreement** — if not, use a third-party/PST path (which doesn't require it). (Microsoft Learn, *Cross-tenant mailbox migration*.)

---

## 4. Target gets a new empty mailbox instead of the migrated one

**Symptom.** After the move (or after licensing), the target user has an empty mailbox rather than the source content.

**Cause.** A license (Exchange plan) was applied to the target MailUser **before** its `ExchangeGUID` was stamped, provisioning a new mailbox; or the target MailUser had a **mismatched previous ExchangeGUID**.

**Fix.**
- Do **not** license the target MailUser before `ExchangeGUID` + proxies are set; assign licenses during the 30-day grace window after the move.
- Clear a mismatched GUID: `Set-User <identity> -PermanentlyClearPreviousMailboxInfo`, then re-stamp the source `ExchangeGUID`. `EXOMIGG-Remediation.ps1` performs this (default `-WhatIf`). (Microsoft Learn.)

---

## 5. Proxy addresses disappear after licensing

**Symptom.** External/secondary SMTP addresses (e.g., an unverified domain) vanish from a MailUser after an Exchange plan is applied.

**Cause.** **Proxy-address scrubbing** — when an Exchange service plan is applied, Entra ID removes SMTP addresses on domains the local tenant hasn't verified (anti-spoofing).

**Fix.** Expected behavior. To retain external branding, strip the license until after the move, or verify the domain first. Plan address handling accordingly. (Microsoft Learn.)

---

## 6. Domain won't verify in the target tenant

**Symptom.** Adding the migrating domain in the target (`portal.office365.us` → Domains) fails verification.

**Cause.** The domain is still in use in the **source** tenant (expected until release), or DNS TXT hasn't propagated.

**Fix.**
- Before cutover, **verification failing is normal** — pre-adding just lets DNS propagate (up to 72h).
- At cutover, fully **release** the domain from the source (reset default/proxy addresses to `*.onmicrosoft.us`, set default domain to initial), then verify in target. Use `Get-Recipient`/Discovery to find lingering objects still binding the domain.

---

## 7. Mail flow broken after MX cutover

**Symptom.** Inbound mail bounces or doesn't arrive after pointing MX to the target.

**Cause.** TTL not expired, MX/Autodiscord pointing to wrong tenant, or transport rules/connectors not recreated in target.

**Fix.**
- Verify MX with `nslookup -type=mx <domain>` / MxToolbox; wait out the (lowered) TTL.
- Recreate transport rules, connectors, and allow/block lists in the **target** EAC (`admin.exchange.office365.us`).
- If needed, roll back: re-point MX/Autodiscover to source from the `EXOMIGG-baseline\` records.

---

## 8. Reply NDRs on migrated threads

**Symptom.** Users get NDRs replying to pre-migration emails.

**Cause.** Outlook Auto-Complete (nickname cache) holds old legacy DN routing.

**Fix.** Clear the Auto-Complete list, or add the old legacy DN as an **X.500** proxy address on migrated users.

---

## 9. Scripts/portals work in Commercial but "can't find" things in GCC High

**Symptom.** A step from a Commercial guide references a portal/feature that doesn't exist for you.

**Cause.** GCC High **feature lag/absence** and different URLs. Graph Explorer, Cross-Tenant Identity Mapping, and some newer conveniences are **not available** in GCC High.

**Fix.** Map every Commercial reference through **`gcc-high-parity-notes.md`**. Validate Graph via **PowerShell**, not Graph Explorer. Assume a newer Commercial feature is absent until Microsoft documents it for US Gov. (verify for GCC High; Microsoft Learn, *national cloud deployments*.)

---

## 10. Endpoints blocked by proxy/firewall

**Symptom.** Timeouts reaching `graph.microsoft.us`, `outlook.office365.us`, or the `*.us` portals.

**Cause.** Firewall allow-lists Commercial ranges only; GCC High uses a **separate** endpoint list.

**Fix.** Allow-list the **GCC High `.us`** URLs/IPs from Microsoft's *Office 365 U.S. Government GCC High endpoints* article; ensure **TLS 1.2+**. Re-check monthly (GCC High publishes changes 30 days ahead).

---

## Escalation

If a native move remains blocked after the above and both tenants are confirmed GCC High, open a Microsoft support case referencing **cross-tenant mailbox migration in GCC High (Public Preview)** and confirm current availability for your tenants. For cross-cloud moves, do not escalate for native support — it does not exist; proceed with a third-party tool or PST.

---

## Sources

- Microsoft Learn — *Cross-tenant mailbox migration* (`learn.microsoft.com/microsoft-365/enterprise/cross-tenant-mailbox-migration`).
- Microsoft Learn — *How to migrate mailboxes … to another* (`learn.microsoft.com/exchange/mailbox-migration/migrate-mailboxes-across-tenants`).
- Microsoft Learn — *Connect to Exchange Online PowerShell* (`learn.microsoft.com/powershell/exchange/connect-to-exchange-online-powershell`).
- Microsoft Learn — *Microsoft Graph national cloud deployments* (`learn.microsoft.com/graph/deployments`).
- Microsoft Learn — *Microsoft 365 U.S. Government GCC High endpoints*.
