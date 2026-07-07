# Testing & Validation

Each test states a **procedure** and an explicit **pass/fail**. Run them in the pilot scope first
(Gate G4), then re-run the relevant tests after each expansion step (Gate G5). Use the named artifacts
from Implementation: `Accepted Domain – Primary – Prod`, `Inbound Connector – OnPrem – Prod`,
`Outbound Connector – OnPrem – Prod`, `Inbound/Outbound Connector – Partner – Prod`, and the named
transport rules. The Validation script `Test-MailFlowValidation.ps1` automates the checks below where
noted (read-only).

---

## T1. Accepted-domain types are correct

- **Procedure:** `Get-AcceptedDomain | Format-Table Name,DomainName,DomainType,Default`. Cross-check
  each against where recipients live. (Automated: `Test-MailFlowValidation.ps1 -CheckAcceptedDomains`.)
- **Pass:** every domain's `DomainType` matches reality — `InternalRelay` for any domain still shared
  with on-prem/partner; `Authoritative` only where all recipients are in EXO.
- **Fail:** a shared domain is `Authoritative` (silent-NDR risk) or a fully-migrated domain is still
  `InternalRelay` (mail may relay out unnecessarily). Correct per Implementation 3a.

## T2. Connectors exist with the right type/source

- **Procedure:** `Get-InboundConnector | Format-Table Name,ConnectorType,ConnectorSource,RequireTls`;
  same for `Get-OutboundConnector`. (Automated: `Test-MailFlowValidation.ps1 -CheckConnectors`.)
- **Pass:** hybrid connectors show `ConnectorSource = HybridWizard`; partner connectors are named
  `… – Partner – Prod` with `RequireTls = True` (or the intended IP restriction); no unexpected/orphan
  connectors.
- **Fail:** a hybrid connector has been hand-edited (source no longer `HybridWizard`), a partner
  connector lacks required TLS, or an unknown connector exists. Re-run HCW / correct the partner
  connector.

## T3. Inbound mail delivers and traces to the expected path

- **Procedure:** From an external address you control, send to `pilot-rx@<Accepted Domain – Primary –
  Prod>`. Then `Get-MessageTraceV2 -RecipientAddress pilot-rx@<domain> -StartDate … -EndDate …` (or
  EAC → Mail flow → Message trace).
- **Pass:** status `Delivered`; the trace/headers show the expected inbound path (EOP for
  cloud-authoritative, or the on-prem inbound connector for on-prem-inbound topologies).
- **Fail:** `Failed`/NDR, or the message arrived via an unexpected connector. Investigate per
  `06-troubleshooting.md` (trace → headers → queues).

## T4. Outbound mail delivers and traces to the expected path

- **Procedure:** From `pilot-tx@<domain>`, send to an external address you control. Trace by sender.
- **Pass:** `Delivered`; trace shows outbound **direct from EXO** when CMT is off, or **via on-prem**
  when CMT is on — matching the G2 design.
- **Fail:** outbound routes the "wrong way" (via on-prem when CMT should be off, or vice versa), or
  fails. Re-check the CMT decision and outbound connector.

## T5. Internal-relay recipient relays (does not NDR)

- **Procedure:** Send to a recipient on `Accepted Domain – Primary – Prod` whose mailbox is still
  **on-prem**. Trace the message.
- **Pass:** the message **relays out** `Outbound Connector – OnPrem – Prod` (or the HCW outbound
  connector) to on-prem and delivers there.
- **Fail:** the message NDRs at EXO ("recipient not found") — the domain is wrongly `Authoritative`.
  Fix the domain type (Implementation 3a) and retest.

## T6. No routing loops

- **Procedure:** Trace each test message end to end; inspect the `Received:` header chain for repeated
  hops between EXO and on-prem or repeated transport-rule redirects. (Automated heuristic:
  `Test-MailFlowValidation.ps1 -CheckLoops` flags traces with excessive hops/redirects.)
- **Pass:** each message follows a single, forward path; no hop repeats; transport rules do not
  redirect a message back into a rule that redirects it again.
- **Fail:** the header chain shows the same hop twice, or trace shows a message oscillating. Disable the
  offending transport rule / connector (Rollback) and redesign.

## T7. Transport rules fire only as intended

- **Procedure:** Send messages that **should** and **should not** match each named rule (e.g. to/from
  the partner domain for `Transport Rule – Partner TLS – Prod`). Confirm the action via headers (e.g.
  a stamped header, forced TLS, or an external tag) and via
  `Get-MessageTraceDetailV2` / rule match reporting where available.
- **Pass:** the rule's action applies to matching mail only; non-matching mail is untouched; priority
  ordering produces the intended result.
- **Fail:** the rule applies too broadly/narrowly, or a higher-priority rule pre-empts it. Re-scope /
  reorder and retest.

## T8. Headers show expected authentication and connector

- **Procedure:** For a delivered test message, open the full headers (paste into the Message Header
  Analyzer or read `Authentication-Results`, `Received-SPF`, and the `Received:` chain).
- **Pass:** SPF/DKIM/DMARC results are as expected for the domain; the connector used matches the
  design; SCL/spam verdict is sane (not silently marking legitimate pilot mail as spam).
- **Fail:** auth failures the design didn't anticipate, wrong connector in the chain, or an unexpected
  high SCL. Correlate with the routing change and adjust.

## T9. Health report matches the design

- **Procedure:** Run `New-MailFlowHealthReport.ps1 -OutputPath .\report`. Compare against the approved
  G2 design and the Phase 1 baseline.
- **Pass:** reported accepted-domain types, connectors, transport rules, and routing match the design;
  no orphan/unexpected artifacts; hybrid connectors still HCW-sourced.
- **Fail:** drift from the design (an extra connector, a changed domain type, a hand-edited hybrid
  connector). Reconcile before declaring the change complete.

---

**Overall exit criteria:** T1–T9 pass in pilot (Gate G4) and again across production after expansion
(Gate G5): mail routes correctly inbound, outbound, and for internal-relay recipients; no loops;
traces clean; transport rules fire only as intended; and the health report matches the approved design.
