# Implementation — Exchange Edge Transport Server Deployment & Hardening (Hybrid)

Follow these ordered steps to deploy and harden the Edge Transport server following the house model
**Assess → Design → Configure → Pilot → Validate → Expand**. Every artifact is **named** with the
convention `<Purpose> – <Scope> – <Stage>` and reused by that exact name in testing, troubleshooting,
and the scripts. **This is pilot-first**: you build and validate the Edge on a **test mail path**
before cutting production MX. The pass/fail gates and the rollback are at the end of this document.

> **Verify for your version.** All Exchange Server cmdlets, Setup switches, prerequisites, ports, and
> defaults below are **version- and CU-dependent** (2013 / 2016 / 2019 / Subscription Edition). Run
> every on-prem cmdlet in the **Exchange Management Shell (EMS)** on the correct server, and confirm
> each step against Microsoft's documentation for **your exact version and CU** before applying it in
> production.

## Naming convention — artifacts created in this solution

| Artifact | Name |
|---|---|
| Edge host (example FQDN) | `edge01.mail.<domain>` (perimeter) |
| Edge Subscription | `Edge Subscription – Perimeter – Prod` |
| EdgeSync-created internet Send connector | `EdgeSync – <site> to Internet` *(auto-named by EdgeSync)* |
| EdgeSync-created inbound Receive connector | `Default internal receive connector <edge>` *(auto)* |
| Partner/mutual-TLS Send connector (if used) | `Send – Partner TLS – Prod` |
| TLS certificate (SMTP) | `Cert – Edge SMTP – Prod` |
| Pilot accepted domain / mail path | `Accepted Domain – Pilot` |
| Anti-spam / connection-filter baseline | `Hygiene – Edge Baseline – Prod` |

---

## Stage 1 — Assess (read-only)

1. **Inventory the current perimeter and transport.** On an internal Exchange server, in EMS:
   ```powershell
   Get-ExchangeServer | Format-Table Name, ServerRole, Edition, AdminDisplayVersion
   Get-TransportService | Format-Table Name, Identity
   Get-SendConnector    | Format-Table Name, AddressSpaces, SmartHosts, Enabled
   Get-AcceptedDomain   | Format-Table Name, DomainName, DomainType, Default
   ```
2. **Confirm the Edge host readiness** (run on the Edge host once the OS is built) with the provided
   discovery script — read-only, changes nothing:
   ```powershell
   .\Get-EdgeReadiness.ps1
   ```
   It reports OS/version, domain-join state (should be **workgroup/perimeter**), AD LDS presence,
   the required ports, name resolution to the internal transport, and any installed Exchange/Edge
   bits. **Gate A (Assess):** host is in the perimeter (not internal AD), AD LDS available, ports
   50636 and 25 reachable as required, FQDN resolvable both directions.
3. **Record the baseline** (connectors, accepted domains, MX, certificate) so the rollback has a
   known-good reference.

## Stage 2 — Design (decide, don't change)

4. Decide and document: Edge topology (**workgroup vs perimeter domain**), the Edge **FQDN** and
   public mail hostname, the **certificate** subject/SAN (`Cert – Edge SMTP – Prod`), the
   **connector scope**, the **hygiene split with EOP** (what the Edge filters vs what cloud filters),
   and the **pilot mail path** (`Accepted Domain – Pilot`). For **hybrid/Government** tenants,
   confirm the cloud-side endpoints and portal URLs (`*.office365.us` on GCC High/DoD) — do not
   assume Commercial endpoints.

## Stage 3 — Configure

### 3a. Install the Edge Transport role

5. On the hardened perimeter host, install the **AD LDS** role and the Exchange **prerequisites**
   for your version/CU, then run **Exchange Setup** selecting the **Edge Transport** role.
   Unattended example (**verify the switch set and version for your build**):
   ```
   Setup.exe /Mode:Install /Roles:EdgeTransport /IAcceptExchangeServerLicenseTerms
   ```
6. Import/enable the **TLS certificate** for SMTP on the Edge (EMS on the Edge):
   ```powershell
   Import-ExchangeCertificate -FileData ([Byte[]]$(Get-Content -Path .\edge-smtp.pfx -Encoding Byte -ReadCount 0)) -Password (Read-Host 'PFX password' -AsSecureString)
   Get-ExchangeCertificate | Format-Table Thumbprint, Services, Subject, NotAfter
   Enable-ExchangeCertificate -Thumbprint <thumbprint> -Services SMTP   # names the SMTP cert 'Cert – Edge SMTP – Prod' in your records
   ```

### 3b. Create and import the Edge Subscription (EdgeSync)

> Subscribing the Edge is what makes it a member of the org for mail flow. **EdgeSync then
> auto-creates** the internet Send connector and the inbound Receive connector — do **not** hand-build
> those on a subscribed Edge.

7. **On the Edge host** (EMS on the Edge), create the subscription file:
   ```powershell
   New-EdgeSubscription -FileName "C:\EdgeSub\EdgeSubscription-Prod.xml"
   ```
   This exports the file and **resets** any manually-created Send/Receive connectors on the Edge to
   the EdgeSync-managed state — expected behavior.
8. **Copy the XML securely** to an internal Mailbox/Transport server (the file is time-sensitive —
   import it promptly).
9. **On the internal Mailbox server** (EMS), import the subscription, naming it
   `Edge Subscription – Perimeter – Prod`:
   ```powershell
   New-EdgeSubscription -FileData ([Byte[]]$(Get-Content -Path "C:\EdgeSub\EdgeSubscription-Prod.xml" -Encoding Byte -ReadCount 0)) -Site "Default-First-Site-Name"
   Get-EdgeSubscription | Format-Table Name, Site, Domain
   ```
10. **Force the first sync and check health** (internal server):
    ```powershell
    Start-EdgeSynchronization
    Test-EdgeSynchronization | Format-List
    ```
    **Gate B (EdgeSync healthy):** `Test-EdgeSynchronization` reports **Normal**; the EdgeSync-created
    Send connector (`EdgeSync – <site> to Internet`) and inbound Receive connector exist. Confirm with
    the configuration helper: `.\Set-EdgeConfig.ps1 -WhatIf` (report only).

### 3c. Accepted domains, connectors, and the pilot mail path

11. Confirm the **accepted domains** replicated to the Edge (they sync from the org). Add/confirm the
    pilot path `Accepted Domain – Pilot` on the **internal** org (accepted domains are managed
    internally and sync down):
    ```powershell
    Get-AcceptedDomain | Format-Table Name, DomainName, DomainType, Default
    ```
12. If a **partner / mutual-TLS** outbound path is required (a specific partner that mandates forced
    TLS), create `Send – Partner TLS – Prod` on the **internal** transport (it syncs to the Edge) —
    **only** if design calls for it; EdgeSync's internet Send connector handles general outbound:
    ```powershell
    New-SendConnector -Name "Send – Partner TLS – Prod" -AddressSpaces "partner.example:1" -DNSRoutingEnabled $true -TlsAuthLevel DomainValidation -Enabled $true
    ```
    **Verify `-TlsAuthLevel` / forced-TLS parameters for your version.**

### 3d. Anti-spam / connection filtering (perimeter hygiene)

> The Edge runs the **anti-spam transport agents**. In a hybrid where **EOP** is the primary hygiene
> layer, keep the Edge's role narrow (connection control + safe relay) and avoid double-filtering.
> **The exact installed agent set is version-dependent — verify for your version.**

13. Confirm the anti-spam agents are present/enabled on the Edge (EMS on the Edge):
    ```powershell
    Get-TransportAgent | Format-Table Identity, Enabled, Priority
    ```
14. Apply the **connection-filter baseline** `Hygiene – Edge Baseline – Prod` — IP Allow/Block lists
    and (optionally) IP Block List **providers** — sized to your design:
    ```powershell
    Get-IPBlockListConfig; Get-IPAllowListConfig
    # Example allow entry for a known-good relay source:
    Add-IPAllowListEntry -IPRange 203.0.113.10
    # Example block entry:
    Add-IPBlockListEntry -IPRange 198.51.100.0/24
    ```
    Report current posture read-only with `.\Get-AntiSpamReport.ps1`.
15. Confirm **Content Filtering / Sender & Recipient Filtering / Sender ID / Sender Reputation** are
    set to your design (or intentionally deferred to EOP). **Do not** enable Recipient Filtering
    tarpitting/blocking that would leak valid-address information unless your design accounts for it.

### 3e. Harden OS / TLS and close the open relay

16. **Confirm no anonymous external relay.** By default a subscribed Edge does **not** relay for
    anonymous senders to external domains. **Prove it** with the validator (safe, read-only — it does
    not actually deliver relayed mail):
    ```powershell
    .\Test-OpenRelay.ps1 -TargetHost edge01.mail.<domain>
    ```
    If any receive connector grants **anonymous** users relay permission to external recipients, that
    is an open relay — fix the connector scope on the internal org (it syncs down) before proceeding.
17. **Enforce TLS.** Confirm the SMTP cert (`Cert – Edge SMTP – Prod`) is enabled, opportunistic TLS
    is advertised, and any required **forced TLS** connectors are configured. Set the org/host TLS
    protocol posture (disable legacy TLS 1.0/1.1 where your version/OS supports it — **this is
    CU/OS-dependent; verify**). Validate with:
    ```powershell
    .\Test-OpenRelay.ps1 -TargetHost edge01.mail.<domain> -CheckTls
    ```
    **Gate C (No open relay + TLS enforced):** the validator reports **relay denied** for anonymous
    external, and **STARTTLS advertised / cert valid**.

## Stage 4 — Pilot (test mail path first)

18. **Cut only the pilot path.** Route the `Accepted Domain – Pilot` inbound mail through the new
    Edge (e.g. via a test MX for the pilot domain or an internal routing test), and send controlled
    inbound + outbound test messages. **Do not** change production MX yet.
19. Confirm mail flows both directions through the Edge (queues drain, messages deliver, headers show
    the Edge and TLS). Use `.\Get-EdgeReadiness.ps1` and message tracking on the transport servers.
    **Gate D (Mail flows):** pilot inbound and outbound test mail deliver through the Edge with TLS,
    and no queue backlog.

## Stage 5 — Validate

20. Run the full validation set (Testing document): **Gate B** EdgeSync Normal, **Gate C** no open
    relay + TLS enforced, **Gate D** mail flows, plus the anti-spam/connection-filter report. All
    gates must pass before expansion.

## Stage 6 — Expand

21. **Cut production MX** to the Edge (or add it to the MX set at equal/priority per design) under the
    change window. Watch queues and tracking closely for the first hours.
22. **Decommission/adjust** any legacy perimeter path only after production is stable on the Edge.
23. Schedule ongoing **EdgeSync health** and **anti-spam** reporting (`Get-EdgeReadiness.ps1`,
    `Get-AntiSpamReport.ps1`) and re-validate after each Exchange CU.

---

## Pass/fail gates (summary)

| Gate | Stage | Pass criteria | If fail |
|---|---|---|---|
| **A** | Assess | Host in perimeter (not internal AD), AD LDS present, ports 50636/25 reachable, FQDN resolves both ways | Fix host/ports/DNS before install |
| **B** | Configure | `Test-EdgeSynchronization` = **Normal**; EdgeSync connectors auto-created | Troubleshoot EdgeSync (see Troubleshooting) |
| **C** | Configure | Anonymous external relay **denied**; STARTTLS advertised, cert valid | Fix connector scope / TLS before pilot |
| **D** | Pilot | Pilot inbound + outbound test mail deliver via Edge with TLS; no backlog | Do not expand; roll back pilot |

## Rollback

- **Before production MX cut** — no production impact: remove the pilot routing; if abandoning the
  Edge, on the internal server `Remove-EdgeSubscription -Identity "Edge Subscription – Perimeter – Prod"`
  and on the Edge `Remove-EdgeSubscription`. Original connectors/MX untouched.
- **After production MX cut** — revert **MX** to the previous perimeter/host (DNS change, honor TTL),
  confirm mail flows on the old path, then remove the Edge subscription as above. Keep the recorded
  baseline (Stage 1, step 3) as the known-good target. Rollback is owned by the named change owner
  (Requirement 7).
