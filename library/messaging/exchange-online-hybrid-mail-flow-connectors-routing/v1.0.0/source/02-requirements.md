# Requirements

These are the **solution-specific** prerequisites for designing and troubleshooting Exchange/M365
hybrid mail flow. They build on the shared **Global Requirements — Microsoft 365 / Exchange Messaging
Solutions** (`global-requirements-messaging.md`): a Microsoft 365 tenant with Exchange Online (GR-1),
least-privilege admin roles (GR-2), the EXO V3 + Graph toolchain (GR-3), DNS control for the mail
domains (GR-4), hybrid Exchange/AD/AAD-Connect access for hybrid solutions (GR-5), and a pilot scope
plus change control (GR-6). Verify those first; the items below are additional and specific to
mail-flow architecture, connectors, and routing.

---

## R1. Healthy Exchange hybrid configuration (for hybrid scenarios)

- **Description:** A hybrid deployment configured by a **current** run of the Exchange **Hybrid
  Configuration Wizard (HCW)**, with the HCW-created **hybrid connectors** (`Inbound from on-prem`,
  `Outbound to on-prem`) present and healthy, and a supported on-prem Exchange build/CU.
- **Why required:** Hybrid mail flow depends on HCW-managed connectors, certificates, and organization
  relationships. Hand-editing HCW connectors, or a mismatched/old CU, is a leading cause of hybrid
  mail-flow breakage. Supported CU levels are **version-dependent** — verify against Microsoft's
  current Exchange Server supportability matrix for your build.
- **How to verify:** In on-prem Exchange Management Shell, `Get-HybridConfiguration`; in EXO PowerShell,
  `Get-InboundConnector`, `Get-OutboundConnector` and confirm the hybrid connectors exist with
  `ConnectorType`/`ConnectorSource` = `HybridWizard`. Confirm the on-prem build/CU with
  `Get-ExchangeServer | Format-List Name,AdminDisplayVersion,Edition`.
- **How to implement if missing:** Re-run the current HCW from a supported on-prem Exchange server;
  do **not** create the hybrid connectors by hand. If pure cloud (no on-prem), this requirement is
  N/A — skip the hybrid legs of the implementation.

## R2. Documented current-state routing (MX, connectors, accepted domains)

- **Description:** A captured baseline of the **current** mail-flow topology: MX records for every mail
  domain, all inbound/outbound connectors and their type/source, and every accepted domain with its
  **domain type** (authoritative / internal relay / external relay).
- **Why required:** You cannot safely change routing you have not documented. The domain **type** in
  particular determines whether unknown recipients NDR or relay — the single most common hybrid
  mail-flow surprise.
- **How to verify:** Run the Discovery script (`Invoke-MailFlowDiscovery.ps1`, read-only) or manually:
  `Get-AcceptedDomain | Format-Table Name,DomainName,DomainType,Default`;
  `Get-InboundConnector`, `Get-OutboundConnector`; and resolve public MX for each domain
  (`Resolve-DnsName <domain> -Type MX`).
- **How to implement if missing:** Run the Discovery script and save its report as the baseline before
  making any change; store it with the change record.

## R3. Correct accepted-domain type for each mail domain

- **Description:** Each mail domain must be set to the accepted-domain **type** that matches reality:
  **authoritative** when all recipients are in this Exchange organization; **internal relay** when the
  domain is shared with on-prem or another system during coexistence. The coexistence domain in this
  solution is named `Accepted Domain – Primary – Prod`.
- **Why required:** An authoritative domain NDRs mail for any recipient it does not know — so if some
  mailboxes are still on-prem (or in a partner system) and the domain is authoritative, those users
  silently stop receiving mail. Internal relay forwards unknowns out the outbound connector instead.
- **How to verify:** `Get-AcceptedDomain "<domain>" | Format-List DomainName,DomainType`. Cross-check
  against where mailboxes actually live (EXO vs on-prem).
- **How to implement if missing:** Set the type under change control:
  `Set-AcceptedDomain -Identity "<domain>" -DomainType InternalRelay` (during coexistence), reverting
  to `Authoritative` only after all recipients are migrated. Test in pilot first.

## R4. Connector authentication material (certificates / IPs)

- **Description:** The TLS **certificate subject** (or sending IP ranges) used to identify and secure
  connector traffic between on-prem/partner systems and Exchange Online — for both HCW hybrid
  connectors and any partner connector (`Inbound Connector – Partner – Prod`).
- **Why required:** Inbound connectors validate senders by certificate subject or IP; outbound
  connectors and partner connectors can **require TLS**. Wrong/expired certificate subject or an
  un-listed IP causes rejected or unencrypted mail.
- **How to verify:** For hybrid, HCW manages this — confirm with `Get-InboundConnector | Format-List
  Name,TlsSenderCertificateName,SenderIPAddresses,RequireTls`. For partners, obtain the partner's
  sending domain/cert subject or IP ranges and their required-TLS posture.
- **How to implement if missing:** For hybrid, re-run HCW so it re-provisions certificate/subject
  matching. For partners, collect the cert subject or IPs from the partner and set them on the named
  partner connector under change control.

## R5. Message trace / reporting access and retention awareness

- **Description:** The ability to run **message trace** (real-time and historical) and read message
  headers — via EAC (**Mail flow → Message trace**) and EXO PowerShell (`Get-MessageTraceV2` for
  recent, `Start-HistoricalSearch` for older). Awareness that real-time trace covers roughly the last
  **~10 days** and historical search extends further (retention/window is **version-/service-dependent
  — verify in your tenant**).
- **Why required:** The layered diagnostic starts with message trace; without trace access and an
  understanding of its time window, older incidents can't be investigated the same way.
- **How to verify:** Confirm the admin role includes message-trace rights (e.g. via a
  Compliance/Reporting-capable role); run a small `Get-MessageTraceV2` for a known recent message.
- **How to implement if missing:** Assign the least-privilege role that grants trace/reporting; for
  older messages, plan to use historical search and note its longer processing time.

## R6. On-prem transport visibility (hybrid only): queues and protocol logs

- **Description:** For hybrid, access to the **on-premises** transport server(s) to inspect **queues**
  (`Get-Queue`, `Get-Message`) and **protocol/connectivity logs** — the legs of the path that cloud
  message trace cannot see.
- **Why required:** When trace shows a message handed to on-prem (or received from on-prem), the queue
  and SMTP logs on that server are the only way to see what happened on the on-prem hop.
- **How to verify:** From on-prem Exchange Management Shell, `Get-Queue` returns without error; confirm
  the transport logging paths exist (`Get-TransportService | Format-List *LogPath*`).
- **How to implement if missing:** Obtain on-prem Exchange admin access and confirm transport logging
  is enabled before an incident, so the evidence exists when you need it.

## R7. Government cloud awareness (if applicable)

- **Description:** If the tenant is **GCC High / DoD** (or GCC), awareness that portal URLs and some
  endpoints differ (e.g. admin/Defender/Purview portals on `*.office365.us`) and that certain features
  or connector behaviors may differ or lag Commercial.
- **Why required:** Following Commercial portal paths on a sovereign cloud sends admins to the wrong
  URLs and can misstate feature availability. Per the house Commercial-vs-Government rule, sovereign
  differences are flagged, not assumed away.
- **How to verify:** Confirm the cloud instance of the tenant (Commercial vs GCC/GCC High/DoD) and use
  the matching portal endpoints for that cloud.
- **How to implement if missing:** Substitute the Government portal URLs and **verify each
  feature/endpoint in your own cloud** before relying on a Commercial-documented behavior.
