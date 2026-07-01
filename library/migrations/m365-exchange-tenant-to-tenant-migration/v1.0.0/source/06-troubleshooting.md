# 6. Troubleshooting — Microsoft 365 Exchange Online Tenant-to-Tenant Migration (1:1 Domains)

Use this guide top-down: start with the symptom, work through the ordered checks, and stop when the issue resolves. References to named objects (e.g. `Coexistence – Source→Target Connector`, `svc-quest-migration`) match `03-implementation.md` verbatim.

---

## 1. Tenant connection / authentication failures (Quest On Demand or PowerShell)

**Symptoms:** Quest On Demand shows a tenant as **Not connected / consent expired**; Exchange Online PowerShell sign-in fails; migration tasks immediately error with auth/permission messages.

**Diagnose, in order:**
1. **Service account state.** In each tenant's **Microsoft 365 admin center → Users → Active users**, confirm `svc-quest-migration` is **enabled** and the password is current.
2. **MFA / Conditional Access (most common cause).** In **Microsoft Entra admin center → Protection → Conditional Access → Policies**, confirm `svc-quest-migration` is in the **Exclude** list of every blocking policy (R8). A newly added or changed CA policy can silently re-block the account. Check **Sign-in logs** (Entra → Monitoring) for the account and read the failure reason.
3. **Consent / enterprise app.** In the Quest On Demand portal → **Tenants**, re-run the consent flow for the affected tenant (sign in as a Global Admin and re-accept). For native MRS, confirm the migration application and `New-MigrationEndpoint` are still valid.
4. **Roles.** Confirm the account still holds the roles the engine needs (Migration / Mail Recipients / application access for native; the consented app permissions for Quest).

**Resolve:** correct the CA exclusion or re-consent, then retry. Never disable CA tenant-wide — scope the exclusion to the service account.

---

## 2. Throttling / slow throughput

**Symptoms:** copy/delta passes crawl; mailboxes sit "in progress" for a long time; engine logs mention throttling or transient errors.

**Diagnose:**
1. **Expect throttling — it's by design.** Microsoft caps per-mailbox and per-tenant migration throughput; you cannot remove the cap. Compare elapsed time against realistic throughput, not raw bandwidth.
2. **Concurrency.** Reduce the number of concurrent mailboxes per wave if the engine is hitting tenant-level limits.
3. **Large mailboxes clustered.** Check whether several multi-GB mailboxes are in the same pass; spread them across waves.
4. **Competing load.** Avoid running discovery, migration, and reporting at peak simultaneously against the same tenant.
5. **Network path.** Confirm the proxy/firewall isn't rate-limiting or intermittently blocking the engine/Microsoft endpoints (R7).

**Resolve:** lower concurrency, re-balance large mailboxes across waves, and lean on **early pre-staging + scheduled deltas** so throughput pressure doesn't fall in the cutover window.

---

## 3. Stuck or failed mailboxes

**Symptoms:** `EXOMIG-Report.ps1` shows mailboxes in **Failed** (or perpetually **InProgress**).

**Diagnose:**
1. **Read the engine error per mailbox** (Quest task detail, or `Get-MigrationUserStatistics` for native). The message usually names the cause.
2. **Target not provisioned / unlicensed** — run `EXOMIG-Validation.ps1` pre-flight; a missing or unlicensed target mailbox (R1/R10) fails the copy.
3. **Corrupt / oversized items** — a small number of bad items can stall a mailbox; raise the engine's bad-item / large-item tolerance and retry that mailbox.
4. **Mapping error** — confirm the `mapping.csv` row points to the correct `TargetUPN`/routing address (R11).
5. **Auth blip** — if failures cluster in time, re-check section 1 (CA/MFA on `svc-quest-migration`).

**Resolve:** fix the specific cause, then **retry just the failed mailboxes** (do not re-run the whole wave). Re-run `EXOMIG-Report.ps1` until **zero unresolved failures** (Test T5 gate).

---

## 4. Domain won't remove from the source tenant (lingering references)

**Symptoms:** **Settings → Domains → contoso.com → Remove** in the source fails with "this domain is being used by …".

**Diagnose — Microsoft blocks removal while ANY object references the domain:**
1. **Re-run source discovery** (`EXOMIG-Discovery.ps1`) and search every export for `@contoso.com`.
2. Check, specifically:
   - **User UPNs and proxy addresses** still on `@contoso.com` (re-stamp to `source.onmicrosoft.com`).
   - **Distribution groups** and **Microsoft 365 groups** with `@contoso.com` addresses.
   - **Shared / room / equipment mailboxes** with `@contoso.com` addresses.
   - **Connectors, transport rules**, and **email address policies** referencing the domain.
   - **Guest / external** objects or app registrations using the domain.
3. The portal's domain page lists offending object **types**; clear each one.

**Resolve:** re-stamp/remove all `@contoso.com` references onto `source.onmicrosoft.com` (step 6.2 of the runbook), wait a few minutes for replication, then retry **Remove domain**. This is the single most common cutover blocker — budget time for it.

---

## 5. Domain verification fails in the target tenant

**Symptoms:** **Settings → Domains → Add domain → contoso.com** won't verify, or stays "Pending/Verifying".

**Diagnose, in order:**
1. **Source hasn't released the domain yet.** A domain can be in only one tenant at a time — verification in the target **cannot** succeed until **section 4** is done and the domain is fully removed from the source. Confirm it's gone from the source first.
2. **TXT record wrong or not propagated.** Confirm the exact **TXT verification value** from the target portal is published at the apex of `contoso.com` at the DNS host (R5). Check with `nslookup -type=txt contoso.com`.
3. **TTL / propagation delay.** If TTLs were high, wait for propagation; this is why TTLs are lowered in advance (best practices).
4. **Typo / wrong zone** — verify you edited the correct, authoritative DNS zone.

**Resolve:** ensure source release is complete, publish the correct TXT, wait for propagation, then click **Verify** again.

---

## 6. Mail-flow gaps during coexistence

**Symptoms:** mail to migrated users bounces or doesn't arrive; mail loops; NDRs reference the routing domain.

**Diagnose:**
1. **Connectors exist and are enabled** — confirm `Coexistence – Source→Target Connector` (source) and `Coexistence – Target→Source Connector` (target) are present and **Enabled** (`Get-OutboundConnector`).
2. **Routing address present** — migrated target mailboxes must carry the routing address (e.g. `user@target.onmicrosoft.com`); `EXOMIG-Validation.ps1` flags missing routing addresses.
3. **Smart host / recipient domain** — confirm each connector's `SmartHosts` and `RecipientDomains` point at the **other** tenant's MX endpoint and routing domain.
4. **Forwarding rules causing loops** — review user forwarding rules carried over from source; remove rules that bounce mail back and forth.
5. **Accepted domain type** — the routing domain should be an accepted domain of the correct type (Internal Relay) on the target.

**Resolve:** correct the connector definition (re-run `EXOMIG-Set-Coexistence.ps1`), add the missing routing address, and remove loop-inducing forwards. Use **message trace** (Exchange admin center → **Mail flow → Message trace**) in both tenants to follow a stuck message end-to-end.

---

## 7. Autodiscover / Outlook won't reconnect after cutover

**Symptoms:** after the domain move, Outlook desktop/mobile keeps prompting for credentials, shows "disconnected", or still points at the old tenant.

**Diagnose:**
1. **Autodiscover DNS** — confirm the Autodiscover CNAME for `contoso.com` points to `autodiscover.outlook.com` and has propagated (`nslookup -type=cname autodiscover.contoso.com`). High TTLs delay this — hence lowering TTL beforehand.
2. **MX correct** — `nslookup -type=mx contoso.com` should resolve to the **target** endpoint.
3. **Cached profile** — Outlook may cling to the old profile. Have the user restart Outlook; if it persists, **recreate the Outlook profile** pointing at the target mailbox.
4. **Credentials** — users authenticate against the **target** tenant now; confirm they have target credentials and have completed MFA registration there.
5. **Mobile** — on Outlook mobile, remove and re-add the account.

**Resolve:** fix DNS first, then reprofile clients that don't auto-reconnect. A small number of manual reprofiles is normal at cutover.

---

## 8. Free/busy not working (cross-mailbox or during coexistence)

**Symptoms:** users see hashmarks instead of availability; "No information" when scheduling.

**Diagnose:**
1. **During coexistence** — free/busy across tenants only works if **GAL sync + free/busy coexistence** was enabled in the Quest On Demand project. If it wasn't, cross-tenant availability is expected to be unavailable until cutover.
2. **After cutover (within the target tenant)** — availability should work natively. If not:
   - Confirm both users' mailboxes are fully migrated and licensed in the target.
   - Confirm the primary SMTP was stamped correctly (`EXOMIG-Validation.ps1`); a mismatched primary address breaks availability lookups.
   - Check **delegation/calendar permissions** were re-applied (`EXOMIG-Remediation.ps1`) — delegate free/busy depends on them.
3. **Test directly** — in Outlook on the web (https://outlook.office.com) on the target, open the scheduling assistant for two migrated users.

**Resolve:** for coexistence gaps, enable free/busy coexistence in the engine; for post-cutover gaps, fix licensing/primary-SMTP/delegation, then re-test in the scheduling assistant.

---

## Quick reference — symptom to section

| Symptom | Section |
|---------|---------|
| Engine/tenant auth fails | 1 |
| Migration slow | 2 |
| Individual mailboxes fail/stuck | 3 |
| Can't remove domain from source | 4 |
| Can't verify domain in target | 5 |
| Mail bounces/loops mid-migration | 6 |
| Outlook won't reconnect after cutover | 7 |
| Free/busy broken | 8 |
