# Testing & Validation — Exchange Edge Transport Server Deployment & Hardening (Hybrid)

Run these validation procedures at the stages indicated in the Implementation guide. Each has an
explicit **expected pass/fail**. **Do not expand to production MX until every gate below passes on the
pilot mail path.** Run on-prem cmdlets in the **Exchange Management Shell (EMS)** on the correct
server (Edge vs internal). **Verify cmdlet behavior for your Exchange version/CU.**

---

## Test 1 — Edge host readiness (Gate A)

**Procedure.** On the Edge host, run the discovery script:
```powershell
.\Get-EdgeReadiness.ps1
```
**Pass:** host is in a **workgroup / perimeter domain** (not the internal AD forest); **AD LDS**
present; port **50636** reachable from internal transport and port **25** reachable as required;
the Edge FQDN resolves from internal transport and the internal transport FQDN resolves from the
Edge.
**Fail:** host is domain-joined to internal AD, AD LDS missing, a required port blocked, or name
resolution one-way/absent — fix before installing the Edge role.

## Test 2 — EdgeSync health (Gate B)

**Procedure.** On the internal Mailbox server:
```powershell
Get-EdgeSubscription | Format-Table Name, Site, Domain
Start-EdgeSynchronization
Test-EdgeSynchronization | Format-List
```
**Pass:** the subscription `Edge Subscription – Perimeter – Prod` is listed; `Test-EdgeSynchronization`
reports **Normal**; the EdgeSync-created internet Send connector (`EdgeSync – <site> to Internet`) and
the inbound Receive connector exist on the Edge.
**Fail:** subscription missing, sync status **Failed**/**Warning**, or connectors not created — see
Troubleshooting (ports 50636, certificate/time skew, name resolution).

## Test 3 — No open relay (Gate C, part 1)

**Procedure.** From an external test point, run the validator (safe — it probes relay acceptance, it
does not deliver relayed spam):
```powershell
.\Test-OpenRelay.ps1 -TargetHost edge01.mail.<domain>
```
Also review connector scope on the internal org (syncs to Edge):
```powershell
Get-ReceiveConnector | Format-Table Name, Bindings, PermissionGroups, AuthMechanism
```
**Pass:** the Edge **rejects** an anonymous attempt to relay to an **external** recipient (e.g. a
`550 5.7.1 Unable to relay` / relay-denied response); no receive connector grants **anonymous** relay
to external domains.
**Fail:** the Edge **accepts** relay for an anonymous external recipient — this is an **open relay**;
remediate connector permissions immediately and do not proceed.

## Test 4 — TLS enforced (Gate C, part 2)

**Procedure.**
```powershell
.\Test-OpenRelay.ps1 -TargetHost edge01.mail.<domain> -CheckTls
```
On the Edge: `Get-ExchangeCertificate | ft Thumbprint,Services,Subject,NotAfter`.
**Pass:** the Edge advertises **STARTTLS**; `Cert – Edge SMTP – Prod` is enabled for **SMTP**, is not
expired, and its subject/SAN matches the public mail hostname; any forced-TLS connector negotiates TLS.
**Fail:** no STARTTLS advertised, certificate expired / name mismatch / not enabled for SMTP, or a
forced-TLS partner connector cannot negotiate — fix before pilot.

## Test 5 — Anti-spam / connection-filter posture

**Procedure.**
```powershell
.\Get-AntiSpamReport.ps1
```
On the Edge: `Get-TransportAgent | ft Identity,Enabled,Priority`.
**Pass:** the anti-spam agents are present and set to the **designed** posture (`Hygiene – Edge
Baseline – Prod`); IP Allow/Block lists match design; nothing is unintentionally disabled or
over-blocking; the hygiene split with EOP is as designed.
**Fail:** an agent unexpectedly disabled/enabled, an over-broad block that would drop legitimate mail,
or Recipient Filtering leaking valid-address data contrary to design — correct on the internal org
and re-sync.

## Test 6 — Mail flow, both directions (Gate D)

**Procedure.** On the **pilot** path only: send a controlled **inbound** message (external → a
pilot-domain mailbox) and a controlled **outbound** message (internal mailbox → external), then trace:
```powershell
Get-MessageTrackingLog -Sender <test-sender> -Start (Get-Date).AddMinutes(-15) | ft Timestamp,EventId,Source,Recipients
Get-Queue -Server edge01.mail.<domain> | ft Identity,DeliveryType,Status,MessageCount   # on/against the Edge
```
**Pass:** both messages deliver end to end **through the Edge**; message headers show the Edge hop and
**TLS**; no queue backlog on the Edge.
**Fail:** mail stalls in a queue, delivers only one direction, or bypasses TLS — diagnose per
Troubleshooting before any production MX change.

## Test 7 — Post-cut production sanity (after Expand)

**Procedure.** After the production MX cut, within the change window: send inbound + outbound
production test mail, watch `Get-Queue` on the Edge and message tracking, and re-run
`.\Get-EdgeReadiness.ps1` and `.\Get-AntiSpamReport.ps1`.
**Pass:** production mail flows both directions with TLS, queues drain normally, EdgeSync remains
**Normal**.
**Fail:** any regression — execute the **rollback** (revert MX) per the Implementation rollback
section.

---

### Validation summary

| Test | Gate | Pass signal |
|---|---|---|
| 1 Host readiness | A | Perimeter host, AD LDS, ports/DNS OK |
| 2 EdgeSync health | B | `Test-EdgeSynchronization` = Normal |
| 3 No open relay | C | Anonymous external relay **denied** |
| 4 TLS enforced | C | STARTTLS advertised, cert valid for SMTP |
| 5 Anti-spam posture | — | Agents/lists match design |
| 6 Mail flow | D | Inbound + outbound deliver via Edge w/ TLS |
| 7 Post-cut sanity | — | Production mail stable, EdgeSync Normal |
