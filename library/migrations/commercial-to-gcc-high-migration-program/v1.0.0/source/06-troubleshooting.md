# 6. Troubleshooting — Commercial-to-GCC High Microsoft 365 & Azure Migration Program (Exchange, SharePoint, Teams, AVD)

Failure modes and fixes, grouped by area. Most cross-cloud problems trace back to two root causes: **the wrong cloud endpoint** (commercial vs. `.us`) and **assuming something synced that does not sync cross-cloud**.

---

## A. Cross-cloud auth / tenant-connection issues

**Symptom:** Migration tool authenticates to the source but fails on the GCC High target ("invalid client", "AADSTS90002 tenant not found", or silently no objects).
- **Cause:** Tool/connector pointed at commercial endpoints, or the project region is not GCC High.
- **Fix:** Select the tool's **GCC High edition/region**. Confirm the target connector uses `login.microsoftonline.us` and the GCC High tenant ID. In PowerShell use the sovereign switches: `Connect-MgGraph -Environment USGov`, `Connect-ExchangeOnline -ExchangeEnvironmentName O365USGovGCCHigh`, `Connect-AzAccount -Environment AzureUSGovernment`.

**Symptom:** Consent fails / "admin approval required" loops on the target.
- **Cause:** Tool's app registration not consented in the **GCC High** tenant (consent in commercial does not carry over).
- **Fix:** Grant admin consent separately in the GCC High tenant for the tool's enterprise app; verify `Migration SvcAcct – M365 – Target` holds the required roles (R12).

**Symptom:** Source mailbox/site moves but objects don't match a target user.
- **Cause:** Target identity not pre-created, or UPN/alias mismatch.
- **Fix:** Ensure Phase 5 created the user in `All Migrated Users – Identity – Target`; re-run object matching on UPN/alias; use `GCCHIGH-Remediation.ps1 -Mode ReStampAddresses` to align proxy addresses.

---

## B. GCC High endpoint / `.us` mistakes

**Symptom:** Scripts/portals return commercial data or "not found" when you expected GCC High.
- **Cause:** Using commercial URLs/cmdlet defaults against a GCC High tenant.
- **Fix:** Use the `.us` portals (`portal.azure.us`, `entra.microsoft.us`, `admin.exchange.microsoft.us`, `admin.teams.microsoft.us`, `<org>-admin.sharepoint.us`) and the sovereign cmdlet switches. For SharePoint PowerShell add `-Region ITAR` on `Connect-SPOService`.

**Symptom:** AzCopy/storage copy fails or lands in the wrong region.
- **Cause:** Targeting commercial storage suffix.
- **Fix:** Use the Gov suffix `*.blob.core.usgovcloudapi.net` for Azure Gov storage endpoints.

**Symptom:** ExpressRoute won't connect Gov VNet.
- **Cause:** Commercial ExpressRoute peering cannot reach Gov regions.
- **Fix:** Provision **ExpressRoute for Azure Government** to a Government peering location (R9).

---

## C. Quest / ShareGate GCC High edition pitfalls

**Symptom:** Tool licensed but no GCC High target option appears.
- **Cause:** Wrong tool edition/region (commercial-only).
- **Fix:** Re-provision the **GCC High-capable** Quest On Demand project / ShareGate build (R6/R7); confirm with the vendor it supports **commercial-source → GCC-High-target**.

**Symptom:** Throttling / very slow content throughput.
- **Cause:** Microsoft 365 service throttling under heavy concurrency.
- **Fix:** Reduce concurrency, schedule heavy passes off-hours, let the tool back off, pre-stage early and only delta in the window. Right-size waves (`GCCHIGH-Set-WavePlan.ps1 -MaxGBPerWave`).

**Symptom:** Teams chat history missing after migration.
- **Cause:** Chat fidelity varies by tool/edition; some chat is not migratable cross-cloud.
- **Fix:** Confirm the edition's chat scope; migrate what is supported, communicate fresh-start chat (best practice), and validate against documented scope (T4.4).

**Symptom:** SharePoint permissions broken / over-broad after copy.
- **Cause:** Source principals didn't map to target Entra principals.
- **Fix:** Re-run permission mapping; remediate with `GCCHIGH-Remediation.ps1 -Mode RePermission`; re-validate (T3.3).

---

## D. ASR replication failures + failover boot issues

**Symptom:** Replication health "Critical" or stuck below 100%.
- **Cause:** Bandwidth saturation, source agent issues, or churn exceeding link capacity.
- **Fix:** Check the link vs. churn (R9); stagger VMs across `Replication Group – Servers – <Wave NN>`; re-trigger with `GCCHIGH-Remediation.ps1 -Mode RetriggerASR`. Do not plan failover until health is **Normal** and RPO is met (T5.1).

**Symptom:** Test/planned failover VM doesn't boot or BSODs.
- **Cause:** Missing boot drivers, unsupported config, or incorrect VM size/disk mapping for Azure Gov.
- **Fix:** Use Azure Migrate readiness/right-sizing for the **Gov** target; enable boot diagnostics and inspect the screenshot; correct the target size/disk; re-run an **isolated test failover** (T5.2) before any planned failover.

**Symptom:** Failed-over VM has no network / unreachable.
- **Cause:** NIC/NSG/IP/DNS not attached post-failover.
- **Fix:** Attach the correct NIC in `snet-servers`, apply `NSG – Servers – Target`, set the IP, and update internal DNS (T5.4).

---

## E. AVD profile / FSLogix issues

**Symptom:** User gets a temporary profile / settings missing after AVD login.
- **Cause:** FSLogix container didn't migrate, or `VHDLocations` still points at the source share.
- **Fix:** Confirm the `.vhdx` copied to `FSLogix Share – Profiles – Target`; re-point the FSLogix `VHDLocations` GPO/registry to the target share; confirm host has access; re-test login (T7.3).

**Symptom:** Session hosts show "Unavailable".
- **Cause:** Host agent/registration token issue or identity join failure.
- **Fix:** Re-generate the host pool registration token for `Host Pool – AVD – Target`; confirm session hosts joined the GCC High identity; restart the AVD agent.

**Symptom:** Users can't see the desktop in the Gov client.
- **Cause:** Wrong client/feed URL (commercial) or no app-group assignment.
- **Fix:** Use the **Azure Government** AVD feed; assign users from `All Migrated Users – Identity – Target` to `App Group – Desktop – Target` (T7.2).

---

## F. Identity mismatches

**Symptom:** Users can't sign in to the target after cutover.
- **Cause:** Account not licensed, MFA not registered, or conditional access misconfigured.
- **Fix:** Verify license via `All Migrated Users – Identity – Target`; have users re-register MFA (does not transfer); review `CA – Require MFA – Target` (T1.1–T1.3).

**Symptom:** Expected directory sync from commercial isn't happening.
- **Cause:** There is **no** commercial→GCC High Entra Connect sync.
- **Fix:** Re-establish identity per R10 — cloud-only accounts or a **new** sync agent pointed at GCC High. Do not wait for a sync that cannot exist.

---

## G. Throttling (program-wide)

**Symptom:** Sustained slow throughput, HTTP 429s, ramped-down jobs.
- **Cause:** Microsoft 365 per-tenant/per-user throttling on bulk operations.
- **Fix:** Lower concurrency, distribute across off-hours, honor tool back-off, and size waves so deltas finish in the window despite throttling. More threads make it worse, not better.

---

## H. Domain move blockers

**Symptom:** Can't verify the domain in GCC High — "already in use".
- **Cause:** Domain still verified in the commercial tenant (a domain lives in one tenant at a time).
- **Fix:** Migrate the domain's mailboxes first, then **release** the domain from commercial, then verify in GCC High (Phase 8) and cut over MX/autodiscover/SPF/DKIM/DMARC (R11, T8.1–T8.2).

**Symptom:** Mail mis-routes or NDRs after cutover.
- **Cause:** Stale DNS / TTL, or MX not pointed at the Gov mail endpoint.
- **Fix:** Lower TTLs ahead of the window; point MX at `*.mail.protection.office365.us`; confirm with `nslookup`; re-publish SPF/DKIM/DMARC for the GCC High tenant.

---

## I. Compliance / data-residency gotchas

**Symptom:** Regulated (ITAR/EAR/CUI) data routed through a non-authorized region or exposed to non-US persons during transit.
- **Cause:** Tool data path/region or migration-team access not constrained to the authorized boundary.
- **Fix:** Configure the tool for **US-sovereign** data handling; restrict migration access to authorized (US) persons; keep staging storage in-boundary; document the data-flow for the CMMC/ITAR evidence package (R13). Treat any out-of-boundary transit as an incident, not a performance issue.

**Symptom:** Assessor asks for evidence you didn't capture.
- **Cause:** Program register/named-object list/acceptance results not kept current.
- **Fix:** Maintain the register continuously (best practice §07): named objects, change records, per-gate results, and the data-flow document are the assessment evidence — backfilling after the fact is unreliable.
