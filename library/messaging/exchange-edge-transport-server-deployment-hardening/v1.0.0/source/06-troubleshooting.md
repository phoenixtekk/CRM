# Troubleshooting — Exchange Edge Transport Server Deployment & Hardening (Hybrid)

Common failure modes and how to resolve them. Run on-prem cmdlets in the **Exchange Management Shell
(EMS)** on the correct server (Edge vs internal). **Verify cmdlet behavior and defaults for your
Exchange Server version/CU** — several failure modes below are version/CU-specific.

---

## 1. EdgeSync fails — `Test-EdgeSynchronization` not Normal (Gate B fail)

**Symptoms.** `Test-EdgeSynchronization` returns **Failed**/**Warning**; EdgeSync-created connectors
missing; recipient/config data not appearing on the Edge.
**Likely causes & fixes:**
- **Port 50636 blocked** between internal transport and the Edge — the single most common cause.
  Verify: `Test-NetConnection <edge-fqdn> -Port 50636` from the internal server (or run
  `Get-EdgeReadiness.ps1 -InternalTransport <edge-fqdn>`). Open the port under change control.
- **Name resolution one-way** — the internal server can't resolve the Edge FQDN (or vice versa). Add
  DNS/HOSTS entries both directions.
- **Clock skew / expired EdgeSync certificate** — EdgeSync uses a self-signed cert and is time-
  sensitive. Sync the clocks (NTP) on both hosts; if the subscription cert has expired, **re-create
  the subscription** (Step 2 below).
- **Stale/partial subscription** — the clean fix is often to re-subscribe: on the internal server
  `Remove-EdgeSubscription -Identity "Edge Subscription – Perimeter – Prod"`, on the Edge
  `Remove-EdgeSubscription`, then re-run `New-EdgeSubscription` on the Edge and re-import internally,
  followed by `Start-EdgeSynchronization` / `Test-EdgeSynchronization`.

## 2. Subscription import fails or "file is expired/invalid"

**Symptoms.** `New-EdgeSubscription` import errors on the internal server.
**Cause & fix.** The subscription XML is **time-sensitive** and single-use — import it promptly after
generating it on the Edge, to the intended **AD site**. Regenerate on the Edge
(`New-EdgeSubscription -FileName ...`), copy securely, and import immediately with the correct
`-Site`. Confirm the Edge and internal Exchange are at **compatible versions/CUs**.

## 3. Mail flows only one direction

**Symptoms.** Inbound works but outbound stalls (or vice versa); messages sit in a queue.
**Likely causes & fixes:**
- **SMTP (25) blocked** on one leg — verify Edge↔internal and Edge↔internet on port 25 with
  `Test-NetConnection ... -Port 25`. Open the missing direction.
- **EdgeSync unhealthy** — the internet Send connector is auto-created by EdgeSync; if sync is broken
  the outbound connector may be missing. Fix EdgeSync (item 1) first.
- **Send connector scope/smart host wrong** — check `Get-SendConnector` on the internal org (it syncs
  down); confirm address spaces and any smart-host/DNS routing match design.
- **Queue held / TLS negotiation failing to a forced-TLS partner** — `Get-Queue` for the queue status;
  if a `Send – Partner TLS – Prod` connector can't negotiate TLS, see item 5.

## 4. Open relay detected (Gate C fail)

**Symptoms.** `Test-OpenRelay.ps1` reports the Edge **accepted** an anonymous external recipient
(`250` at RCPT TO), or a Receive connector grants anonymous relay to external domains.
**Cause & fix.** A Receive connector's permission scope is too broad. On the **internal** org (syncs
to Edge), review `Get-ReceiveConnector | ft Name,PermissionGroups,AuthMechanism`; ensure anonymous
internet senders can deliver **only** to your **accepted domains**, never relay to external
recipients. Any application/internal relay must be **authenticated** or **IP-scoped**, not
anonymous-to-anywhere. Re-run `Start-EdgeSynchronization` then re-validate with `Test-OpenRelay.ps1`.
**This is urgent — an open relay is a security incident; do not expand to production until resolved.**

## 5. TLS / certificate errors (Gate C fail)

**Symptoms.** `Test-OpenRelay.ps1 -CheckTls` shows **no STARTTLS**; partners report TLS failures; or
`Get-ExchangeCertificate` shows an expired/mismatched cert.
**Likely causes & fixes:**
- **Certificate not enabled for SMTP** — `Enable-ExchangeCertificate -Thumbprint <t> -Services SMTP`
  on the Edge (this is `Cert – Edge SMTP – Prod`).
- **Subject/SAN mismatch** with the public mail hostname / HELO — reissue the cert with the correct
  name.
- **Expired certificate** — replace and re-enable; certificate expiry also breaks EdgeSync trust
  (item 1). Track expiry with `Get-EdgeScopeHealth.ps1`.
- **Legacy-TLS hardening broke a partner** — if you disabled TLS 1.0/1.1 and an older partner can no
  longer connect, that trade-off is expected; coordinate with the partner or stage the change. **TLS
  protocol/cipher control is version/CU/OS-dependent — verify for your version.**

## 6. Anti-spam over-blocking or unexpected agent state

**Symptoms.** Legitimate mail dropped/quarantined at the Edge; `Get-AntiSpamReport.ps1` shows an
agent unexpectedly enabled/disabled or an over-broad IP block.
**Cause & fix.** Compare the report against your designed `Hygiene – Edge Baseline – Prod`. Remove
over-broad `Add-IPBlockListEntry` CIDRs; re-enable any agent that should be on; and in a **hybrid**
where **EOP** is primary, avoid double-filtering — keep the Edge narrow (connection control + TLS +
safe relay) and let cloud do content/anti-phish. Recipient Filtering that discloses valid addresses
should be off unless design accounts for it.

## 7. AD LDS / prerequisite / Setup failures during install

**Symptoms.** Exchange Setup blocks on prerequisites; Edge role won't install.
**Cause & fix.** The **AD LDS** role and the exact OS features / .NET / Visual C++ runtimes required
are **version/CU-specific**. Install AD LDS (`Get-WindowsFeature ADLDS`), apply the prerequisite set
from Microsoft's **"Exchange Server prerequisites"** doc **for your version**, reboot if required, and
re-run Setup. Confirm the host is **not** joined to the internal AD forest.

## 8. Version/CU mismatch or post-CU regression

**Symptoms.** EdgeSync/connectors/hygiene worked, then broke after an update; or Edge↔internal refuse
to subscribe.
**Cause & fix.** Exchange CUs can change TLS/Extended Protection defaults, supported builds, and agent
behavior, and Edge/internal must be at **compatible versions**. Re-validate after **every CU** with
the full Testing set (`Get-EdgeReadiness.ps1`, `Test-OpenRelay.ps1`, `Get-AntiSpamReport.ps1`,
`Get-EdgeScopeHealth.ps1`); bring both sides to a compatible, supported CU. **Confirm the Edge↔internal
version compatibility matrix for your exact versions.**

---

### If a gate cannot be passed — roll back

If EdgeSync, open-relay, TLS, or mail-flow gates cannot be cleared within the change window and
production MX has already been cut, **execute the rollback** (revert MX to the previous perimeter/host,
honor TTL, confirm mail on the old path, then remove the subscription) per the Implementation rollback
section. Never leave production on an Edge that fails Gate C (open relay / TLS).
