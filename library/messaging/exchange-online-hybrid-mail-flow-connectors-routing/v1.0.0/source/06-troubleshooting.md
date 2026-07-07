# Troubleshooting

A symptom → root-cause → fix playbook for Exchange/M365 hybrid mail flow, driven by the layered
diagnostic: **message trace → message headers → queues/SMTP logs**. Start at trace; escalate only when
the prior layer is inconclusive. Use the named artifacts from Implementation and the trace helper
(`Get-MailFlowTraceHelper.ps1`).

## Diagnostic method (apply to every symptom)

1. **Message trace** — where did the message go, and what was the last status? EAC → Mail flow →
   Message trace, or `Get-MessageTraceV2` (recent, ~last 10 days — **verify window in your tenant**) /
   `Start-HistoricalSearch` (older). Note the final `Status` and the connector referenced.
2. **Message headers** — export the full headers and read the `Received:` chain bottom-up (the true
   path), plus `Authentication-Results` (SPF/DKIM/DMARC), `X-Forefront-Antispam-Report`, and SCL. Use
   `Get-MailFlowTraceHelper.ps1 -HeaderFile <file>` or the Message Header Analyzer.
3. **Queues / SMTP logs (on-prem)** — for hybrid legs cloud trace can't see, on the hybrid transport
   server run `Get-Queue`, `Get-Message -Queue <q>`, and review protocol/connectivity logs
   (`Get-TransportService | Format-List *LogPath*`).

---

## Symptom: some recipients on a shared domain get "recipient not found" NDRs

- **Trace shows:** message reaches EXO and NDRs with `550 5.1.10 / RESOLVER.ADR.RecipNotFound` at the
  cloud hop; recipient's mailbox actually lives on-prem/partner.
- **Root cause:** the accepted domain is **`Authoritative`** but not all recipients are in EXO — EXO
  NDRs unknown recipients instead of relaying them.
- **Fix:** set the domain to **internal relay**: `Set-AcceptedDomain -Identity "<domain>" -DomainType
  InternalRelay` (Implementation 3a). Confirm an outbound connector to on-prem exists so unknowns relay.
  Retest (T5).

## Symptom: outbound mail routes the "long way" (through on-prem) unexpectedly

- **Trace shows:** outbound from EXO handed to `Outbound to on-prem` / the on-prem connector before
  reaching the internet.
- **Root cause:** **centralized mail transport (CMT)** is enabled when it shouldn't be.
- **Fix:** if on-prem does not need to process outbound cloud mail, disable CMT by **re-running HCW**
  and choosing not to route outbound through on-premises. Do not hand-edit HCW connectors. Retest (T4).

## Symptom: mail loops / duplicates / "too many hops" NDR

- **Trace/headers show:** the same `MessageId` appears many times, or the `Received:` chain repeats a
  hop between EXO and on-prem (or a message oscillates between two transport rules).
- **Root cause:** a routing loop — commonly two mutually-redirecting transport rules, an internal-relay
  domain pointing back to a system that relays it back, or an on-prem/EXO connector pair misrouting.
- **Fix:** identify the loop with `Get-MailFlowTraceHelper.ps1` (flags >=25 Received hops / repeat trace
  events) or `Test-MailFlowValidation.ps1 -CheckLoops`. **Disable** the offending transport rule first
  (`Disable-TransportRule`) or the connector, confirm recovery, then redesign the routing (Rollback).
  Retest (T6).

## Symptom: partner mail rejected or delivered without TLS

- **Trace/headers show:** partner mail bounces on connector validation, or arrives without TLS.
- **Root cause:** wrong/expired certificate subject on `Inbound Connector – Partner – Prod`, a sender IP
  not listed, or `RequireTls` not set.
- **Fix:** confirm the partner's current cert subject/IPs (R4); update the connector
  (`Set-InboundConnector "Inbound Connector – Partner – Prod" -TlsSenderCertificateName "<subject>"
  -RequireTls $true`, or set `SenderIPAddresses`). For outbound to a partner smart host, verify
  `TlsSettings`/`TlsDomain` on `Outbound Connector – Partner – Prod`. Retest (T2, T7).

## Symptom: legitimate pilot mail marked as spam / high SCL

- **Headers show:** high `X-MS-Exchange-Organization-SCL`, `dmarc=fail`/`spf=fail` in
  `Authentication-Results`.
- **Root cause:** a routing change altered the sending path so SPF/DKIM/DMARC no longer pass (e.g. mail
  now egresses from an IP not in SPF), or a transport rule set an unexpected SCL.
- **Fix:** correlate the auth result with the new path in the `Received:` chain. If SPF broke because
  mail now leaves via a different connector/host, update the SPF record for that path (DNS, R4/GR-4) —
  change DNS last and under change control. Check no transport rule is setting SCL unintentionally.
  Retest (T8).

## Symptom: HCW hybrid connector "keeps changing back" / breaks after HCW run

- **Symptom:** a manually edited hybrid connector setting reverts, or hybrid mail flow breaks after the
  next HCW run.
- **Root cause:** the connector is **HCW-sourced** (`ConnectorSource = HybridWizard`) and was hand-edited
  — HCW re-provisions/overwrites it.
- **Fix:** never hand-edit HCW connectors. Make the change **through HCW** (re-run it). Validate with
  `Test-MailFlowValidation.ps1 -CheckConnectors` (flags non-HCW-sourced hybrid connectors). Retest (T2).

## Symptom: message "delivered" per trace but user never received it

- **Trace shows:** `Delivered`, but to an unexpected location, or the last cloud event hands off to
  on-prem and trace goes dark.
- **Root cause:** delivery to on-prem (internal-relay) where the on-prem hop failed or delivered to the
  wrong mailbox/folder; cloud trace can't see the on-prem leg.
- **Fix:** escalate to the **third layer** — on the on-prem hybrid transport server, `Get-Queue` /
  `Get-Message` and the protocol logs to follow the on-prem hop. Confirm the recipient object/routing on
  on-prem. This is exactly the leg the layered method exists for.

## Symptom: message trace returns nothing for an older incident

- **Root cause:** real-time trace only covers roughly the last ~10 days (**window is service-dependent —
  verify in your tenant**).
- **Fix:** use **historical search** (`Start-HistoricalSearch` / EAC historical search) for older mail;
  expect longer processing time. Going forward, capture traces/headers at incident time.

---

**Escalation rule:** if trace is `Delivered`/clean and headers look correct but the user still reports
loss, the problem is almost always on the **on-prem leg** (queues/SMTP logs) or in the recipient's
mailbox rules/forwarding — not in cloud routing. Keep the `MailFlow Baseline – Tenant – Prod` report
handy to compare current config against a known-good state.
