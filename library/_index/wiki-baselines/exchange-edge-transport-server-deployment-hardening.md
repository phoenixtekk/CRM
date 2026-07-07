# Exchange Edge Transport Server Deployment & Hardening (Hybrid)

> **Version 1.0.0** · Category: Messaging · Solution code: EXOEDGE

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary — Exchange Edge Transport Server Deployment & Hardening (Hybrid)

## Outcome

A perimeter **Edge Transport** tier that is **correct and secure**: subscribed to the Exchange
organization via a healthy **EdgeSync** relationship, with scoped **connectors** and **accepted
domains**, first-layer **anti-spam / connection filtering**, a hardened **OS and enforced TLS**, and
**no open relay** — validated by controlled inbound and outbound mail flow before any production
cutover. The result is a hardened front door to the messaging estate that complements, rather than
duplicates, cloud hygiene (EOP / Defender for Office 365).

## Approach

The solution follows a disciplined, pilot-first model — **Assess → Design → Configure → Pilot →
Validate → Expand** — with **named artifacts**, explicit **pass/fail gates**, and a documented
**rollback**. It deploys the Edge role on a standalone hardened perimeter host, creates and imports
the **Edge Subscription** (letting EdgeSync auto-provision the internet connectors), configures the
connector / accepted-domain / hygiene / TLS posture, and proves secure mail flow on a **test mail
path** before cutting production MX. Five PowerShell tools support the work: read-only readiness
discovery, a safe (`-WhatIf`) configuration helper, an open-relay + TLS validator, an anti-spam /
connection-filter report, and a scope/health helper — all read-only or dry-run by default, with no
credentials in code.

## Why it is low-risk

- **Pilot-first with hard gates.** Nothing touches production MX until EdgeSync is healthy, the
  open-relay hole is provably closed, TLS is enforced, and pilot mail flows both ways.
- **Reversible.** A recorded baseline and a documented MX/subscription rollback mean any failed gate is
  recoverable within the change window.
- **Safe-by-default tooling.** Every provided script defaults to read-only or `-WhatIf`; writes require
  an explicit switch, and there are no stored secrets.
- **Version-honest.** Exchange Server behavior is version- and CU-dependent; the guide flags every such
  point as "verify for your version" rather than assuming, so the operator applies the correct steps
  for their exact build — and for Government (GCC/GCC High/DoD) cloud endpoints where hybrid touch
  points differ.

**Bottom line:** a hardened, validated perimeter Edge Transport tier — EdgeSync healthy, no open relay,
TLS enforced, mail flowing — delivered with a repeatable, low-risk procedure and supporting automation.


---


# Solution Overview — Exchange Edge Transport Server Deployment & Hardening (Hybrid)

## What this is

This solution deploys and hardens an **Exchange Edge Transport** server in the perimeter of a
hybrid Exchange organization, and validates that inbound and outbound SMTP flow securely with no
open relay. The Edge Transport role is a purpose-built, minimized Exchange installation that sits
in a perimeter network (screened subnet / DMZ), is **not** joined to the internal Active Directory
forest, and handles internet-facing SMTP plus a first layer of mail hygiene before mail reaches the
internal Mailbox servers.

The work covers the full lifecycle: install the Edge Transport role on a hardened host, create and
import an **Edge Subscription** so EdgeSync one-way replication provisions the connectors and
recipient/config data the Edge needs, configure **Send/Receive connectors** and **accepted
domains**, apply the **anti-spam transport agents** and **connection filtering**, harden the
**OS and TLS** posture (closing the open-relay hole), and prove secure mail flow end to end. Five
PowerShell tools accompany the guide for read-only discovery, safe (`-WhatIf`) configuration, open-
relay/TLS validation, an anti-spam/connection-filter report, and a scope/health helper.

> **Version note — verify for your version.** Exchange Server behavior differs by **version and
> Cumulative Update (CU)** — Exchange Server 2013, 2016, 2019, and the **Subscription Edition (SE)**
> each have their own supported build, prerequisites, and default hygiene agent set. TLS defaults,
> the Extended Protection posture, and supported .NET/OS versions in particular are CU-dependent.
> Before applying any step, **confirm it against Microsoft's documentation for your exact Exchange
> Server version and CU** and against your organization's build. Where this guide states a default,
> treat it as "verify in your version".

## How it works — the reference design

```
   Internet
      │  inbound SMTP (25/TLS)
      ▼
 ┌─────────────────────────────┐   Perimeter network (DMZ / screened subnet)
 │  Edge Transport server      │   • Standalone (workgroup or perimeter domain), NOT internal AD
 │  • Receive connector(s)     │   • AD LDS (ADAM) holds synced config + recipients
 │  • Send connector(s)        │   • Anti-spam agents + Connection Filtering
 │  • Anti-spam / conn filter  │   • TLS enforced; open relay closed
 └─────────────┬───────────────┘
   EdgeSync    │  one-way replication (secure LDAP 50636), internal → Edge
   inbound 25  ▼
 ┌─────────────────────────────┐   Internal network
 │  Mailbox (Transport) server │   • Subscribes the Edge; runs Microsoft Exchange EdgeSync svc
 │  Active Directory / AD DS   │   • Internet send/receive connectors auto-created by EdgeSync
 └─────────────────────────────┘
      │  hybrid connectors (where hybrid)
      ▼
 Exchange Online / EOP  (cloud hygiene complements the Edge)
```

Key mechanics an operator must hold in mind:

- **The Edge is standalone.** It is deployed in a **workgroup or a dedicated perimeter domain**,
  never joined to the internal production AD. It stores its configuration and a read-only copy of
  recipient data in a local **Active Directory Lightweight Directory Services (AD LDS)** instance,
  not in AD DS.
- **EdgeSync provisions it.** You create an **Edge Subscription** file on the Edge, import it on an
  internal **Mailbox server** (the Transport service), and the **Microsoft Exchange EdgeSync**
  service then replicates configuration and recipient/safelist data **one way, internal → Edge**,
  over secure LDAP. EdgeSync **automatically creates** the internet Send connector and the inbound
  Receive connector, so you generally do **not** hand-build those on a subscribed Edge.
- **Hygiene at the perimeter.** The Edge runs the **anti-spam transport agents** (Connection
  Filtering / IP Allow & Block lists, Content Filtering, Sender/Recipient Filtering, Sender ID,
  Sender Reputation, Attachment/Protocol agents where installed). In a hybrid where **Exchange
  Online Protection (EOP)** is the primary hygiene layer, the Edge's job is narrower — perimeter
  connection control, TLS termination, and safe relay — with cloud hygiene doing the heavy lifting.
- **No open relay.** A default, correctly-scoped Edge does **not** relay for anonymous internet
  senders to external domains. The hardening work makes that guarantee explicit and *tested*.

## The deployment model

This solution follows the house model for high-impact messaging changes:

**Assess → Design → Configure → Pilot → Validate → Expand**, pilot-first, with explicit pass/fail
gates and a documented rollback at every stage. Perimeter mail flow, connectors, DNS (MX), and TLS
are **high-impact to production mail** — a mistake can black-hole inbound mail or expose an open
relay — so every change is staged, validated against a gate, and reversible.

- **Assess** — inventory the current perimeter, existing Edge/transport, connectors, certificates,
  firewall/DNS, and Exchange version/CU.
- **Design** — decide the Edge host topology (workgroup vs perimeter domain), naming, certificate,
  connector scope, and hygiene split with EOP.
- **Configure** — install the role, subscribe (EdgeSync), and apply connector/hygiene/TLS settings
  using the named artifacts.
- **Pilot** — cut a **single test domain / low-risk mail path** over to the new Edge first.
- **Validate** — run the pass/fail gates (EdgeSync healthy, no open relay, TLS enforced, mail flows).
- **Expand** — move production MX / full mail flow only after the pilot gates pass; keep rollback ready.

## Benefits

- **Correct, secure perimeter transport** — EdgeSync healthy, connectors scoped, TLS enforced, and
  the open-relay hole provably closed.
- **First-layer hygiene at the edge** that complements cloud (EOP/Defender for Office 365) hygiene
  rather than duplicating it.
- **Repeatable, tested procedure** with named artifacts, pass/fail gates, and rollback — safe for
  production mail.
- **PowerShell tooling** for read-only discovery, safe configuration, open-relay/TLS validation, and
  ongoing reporting.

## Limitations & scope

- This solution deploys and hardens the **Edge Transport role and its mail flow**; it is **not** a
  full Exchange org build, a migration, or an EOP/Defender policy design (those are separate).
- **Exchange version/CU-specific** build numbers, prerequisites, TLS/Extended Protection defaults,
  and the exact anti-spam agent set are **verify-in-your-version** items — this guide gives the
  procedure and the cmdlets, not a substitute for Microsoft's per-version documentation.
- **Third-party perimeter gateways** (secure email gateways, hygiene appliances) are integrated at
  the pattern level; their consoles are deferred to the vendor's own docs. If a third-party gateway
  is the internet-facing MX, the Edge role may be redundant — that design choice is called out in
  Best Practices.
- **Commercial vs Government (GCC/GCC High/DoD):** the on-prem Edge steps are cloud-independent, but
  the **hybrid/cloud** touch points (EOP, connector endpoints, admin portal URLs such as
  `*.office365.us`) differ on sovereign clouds — flagged where relevant, not assumed Commercial.


---


# Requirements — Exchange Edge Transport Server Deployment & Hardening (Hybrid)

These are the **solution-specific** prerequisites for deploying and hardening an Edge Transport
server. They build **on top of** the shared category requirements in
`global-requirements-messaging.md` — that file already covers the M365 tenant + Exchange Online,
least-privilege admin roles, the EXO V3 / Graph toolchain, DNS control for the mail domains, the
on-prem Exchange/AD/Azure AD Connect access needed for any hybrid solution, and the pilot scope +
change control. **Verify the shared six first**, then satisfy the Edge-specific items below.

> **Verify for your version.** Exchange Server prerequisites, supported OS/.NET builds, and the
> exact anti-spam agent set are **version- and CU-dependent** (2013 / 2016 / 2019 / Subscription
> Edition). Confirm each requirement against Microsoft's documentation for **your exact Exchange
> Server version and CU** before you build the host.

---

## 1. A dedicated, hardened perimeter host for the Edge role

- **Description:** A dedicated server (physical or VM) sitting in the **perimeter network** (DMZ /
  screened subnet), running a **supported Windows Server version for your Exchange Server
  version/CU**, **not joined** to the internal production Active Directory. It should be in a
  **workgroup** or a **dedicated perimeter/DMZ domain**, with a resolvable **FQDN**, sufficient
  disk for the transport queue database, and the OS hardened (minimal roles, patched).
- **Why required:** The Edge role is designed to run standalone in the perimeter to reduce the
  attack surface; it must not be a domain-joined internal server.
- **How to verify:** Confirm the host is reachable, has the correct FQDN and DNS suffix, is **not**
  a member of the internal AD forest (`(Get-WmiObject Win32_ComputerSystem).PartOfDomain` /
  `systeminfo`), and meets the OS/CPU/RAM/disk baseline for your Exchange version.
- **How to implement if missing:** Provision the host in the perimeter, set its FQDN, place it in a
  workgroup/perimeter domain, patch and harden the OS, then continue. (The discovery script
  `Get-EdgeReadiness.ps1` in this solution checks the local readiness signals.)

## 2. Active Directory Lightweight Directory Services (AD LDS) + Exchange prerequisites

- **Description:** The Edge role requires the **AD LDS** role (formerly ADAM) and the Windows
  prerequisites/features and .NET/Visual C++ runtimes that your Exchange Server version/CU mandates
  for the Edge Transport role.
- **Why required:** The Edge stores its synced configuration and recipient data in a local AD LDS
  instance; Setup will not install the Edge role without AD LDS and the required OS features.
- **How to verify:** `Get-WindowsFeature ADLDS` (or `AD-LDS`) shows **Installed**; the Exchange
  readiness checks in Setup pass.
- **How to implement if missing:** Install AD LDS and the prerequisite features per Microsoft's
  **"Exchange Server prerequisites"** guidance for your version, reboot if required, then run
  Exchange Setup. **Verify the exact feature/runtime list for your version and CU.**

## 3. DNS name resolution between Edge and internal transport (and the reverse)

- **Description:** The Edge host must be able to **resolve the internal Mailbox/Transport server(s)**
  it subscribes to, and those internal servers must be able to **resolve the Edge host's FQDN** —
  by DNS or, if necessary, HOSTS entries. Public **DNS MX and A/PTR** records for the mail domain
  must point to the Edge's internet-facing address (this is staged, not switched, until pilot
  validation passes).
- **Why required:** EdgeSync and mail flow are name-based; if either side cannot resolve the other,
  subscription import and SMTP will fail. PTR (reverse DNS) affects deliverability and reputation.
- **How to verify:** From the Edge, resolve the internal transport server FQDN; from an internal
  transport server, resolve the Edge FQDN. Confirm the public MX/A and PTR records for the mail
  domain.
- **How to implement if missing:** Add the needed DNS/HOSTS entries; coordinate public MX/A/PTR
  changes through DNS change control (do **not** switch production MX until the pilot gate passes).

## 4. Firewall ports open between Edge, internal transport, and the internet

- **Description:** The required TCP paths must be open: **inbound SMTP 25/TCP** from the internet to
  the Edge; **SMTP 25/TCP** between the Edge and internal transport (both directions for inbound and
  outbound); and **secure LDAP 50636/TCP** from the internal transport server(s) to the Edge for
  **EdgeSync** (Edge listens on 50636 for the sync; 50389 is the non-secure LDAP port for local
  tooling).
- **Why required:** EdgeSync replicates over **50636** and mail flows over **25**; a blocked port is
  the single most common cause of a failed subscription or one-way mail flow.
- **How to verify:** `Test-NetConnection <edge-fqdn> -Port 50636` from an internal transport server,
  and `Test-NetConnection <internal-transport-fqdn> -Port 25` from the Edge; confirm inbound 25 from
  the internet reaches the Edge.
- **How to implement if missing:** Open the ports on the perimeter and internal firewalls under
  change control. **Verify the exact EdgeSync port(s) for your Exchange version** — the defaults are
  50636 (secure) / 50389 (LDAP), but confirm they have not been customized.

## 5. A valid TLS certificate for the Edge SMTP service

- **Description:** A **TLS certificate** whose subject/SAN matches the Edge's public mail hostname
  (the name used in the MX record / HELO), issued by a CA the sending/receiving partners trust
  (public CA for internet TLS). It must be enabled for the **SMTP** service on the Edge.
- **Why required:** Opportunistic and forced TLS for inbound/outbound SMTP, and mutual TLS for any
  partner/hybrid connectors, depend on a valid certificate; a name mismatch or expired cert breaks
  secure mail flow.
- **How to verify:** `Get-ExchangeCertificate` on the Edge shows a valid cert with **SMTP** in its
  Services and a matching subject/SAN and non-expired validity.
- **How to implement if missing:** Request/import the certificate on the Edge and enable it for SMTP
  (`Enable-ExchangeCertificate -Services SMTP`). For hybrid, ensure the certificate aligns with the
  Hybrid Configuration / connector requirements.

## 6. Internal Exchange organization healthy and at a compatible version/CU

- **Description:** A healthy on-prem **Exchange organization** with at least one **Mailbox server
  (Transport service)** to host the Edge Subscription, at a **version/CU compatible** with the Edge
  server's version. Directory sync (Azure AD Connect) healthy where the org is hybrid.
- **Why required:** EdgeSync runs from the internal Transport service; the Edge and internal
  Exchange must be at compatible versions, and a broken internal org cannot subscribe an Edge.
- **How to verify:** `Get-ExchangeServer` shows the internal server and roles; the internal server's
  version/CU is compatible with the Edge; `Get-EdgeSubscription` (once done) lists the subscription.
- **How to implement if missing:** Bring the internal org to a compatible, supported CU and confirm
  transport health before subscribing the Edge. **Verify the Edge↔internal version compatibility
  matrix for your versions.**

## 7. Change window, pilot mail path, and rollback owner

- **Description:** An agreed **change window**, a **pilot mail path** (a single test accepted domain
  or low-risk inbound/outbound flow to validate before cutting production MX), and a named owner who
  can execute the **rollback** (revert MX, remove the subscription) if a gate fails.
- **Why required:** Perimeter mail flow, MX, and TLS changes are high-impact; the pilot-first model
  and a ready rollback protect production mail.
- **How to verify:** Confirm the change window is booked, the pilot path/domain is identified, and
  the rollback owner and steps are documented (see the Implementation rollback section).
- **How to implement if missing:** Schedule the window, define the pilot path, and document rollback
  with the messaging/service owner before making any production-facing change.


---


# Global Requirements — Microsoft 365 / Exchange Messaging Solutions

These requirements apply to **every** solution in the **Messaging** category (Exchange Online &
Exchange hybrid mail flow, connectors, mail hygiene, email authentication, federation, archiving,
client connectivity, and messaging support operations). They are the common foundation each solution
assumes is already in place (or stands up as part of its own Requirements section). Verify each before
starting a solution's implementation steps.

> **Vendor boundary (applies to every Messaging solution).** The **Exchange admin center (EAC)**, the
> **Microsoft 365 admin center**, **Exchange Online PowerShell (EXO V3 module)**, **Microsoft Graph**,
> and on-premises **Exchange Server / Active Directory** are authored at exact, current click-by-click
> and cmdlet detail from Microsoft's public documentation. Where a capability, default, or portal path
> is **version- or plan-dependent** (Exchange Server build/CU, EOP vs Defender for Office 365 plan,
> Exchange Online Archiving / auto-expanding archive availability, Commercial vs Government cloud), it
> is **cited or flagged "verify in your tenant/version"** — never invented. **Third-party mail hygiene,
> archiving, and signature/gateway products** are integrated at the pattern level; their internal
> consoles are deferred to the vendor's own docs. **Commercial vs Government (GCC/GCC High/DoD)** portal
> URLs and endpoints differ — where a solution's setup materially differs on a sovereign cloud, flag it
> (per the house Commercial-vs-Government rule). Automation is delivered as **PowerShell** (Exchange
> Online PowerShell / Graph) — never with hardcoded credentials or secrets in code.

## 1. Microsoft 365 tenant with Exchange Online
- **Description:** A Microsoft 365 tenant with **Exchange Online** and the appropriate licensing for the
  capability in scope (e.g. Exchange Online Plan 1/2, EOP, **Defender for Office 365** for advanced
  hygiene, Exchange Online Archiving / auto-expanding archive where required).
- **Why required:** All mail-flow, hygiene, archiving, and client configuration is performed against
  this tenant and depends on the right plan.
- **How to verify:** Sign in to the Microsoft 365 admin center; confirm the Exchange Online subscription
  and license counts under **Billing > Licenses**.
- **How to implement if missing:** Provision/assign the required licensing before starting.

## 2. Administrative access (least-privilege Exchange/365 roles)
- **Description:** Administrative access with the **least-privilege role** the solution names —
  typically **Exchange Administrator** (or specific EAC role groups such as Organization Management,
  Recipient/Records/Hygiene Management), and **Global Administrator** only where genuinely required
  (e.g. federation/ADFS, connector auth).
- **Why required:** Mail-flow, connector, hygiene, archiving, and federation changes require the
  corresponding admin role.
- **How to verify:** Confirm the role assignment in the Microsoft 365 admin center / Entra roles.
- **How to implement if missing:** Have a Global Admin assign the least-privilege role under change control.

## 3. Exchange Online PowerShell (EXO V3) + Graph toolchain
- **Description:** A workstation with the **ExchangeOnlineManagement (EXO V3)** PowerShell module and,
  where used, **Microsoft Graph PowerShell**; modern-auth / MFA-capable admin sign-in.
- **Why required:** Configuration, automation, and the provided scripts run through EXO PowerShell /
  Graph; Basic Auth is retired.
- **How to verify:** `Connect-ExchangeOnline` succeeds with the admin account; `Get-Module
  ExchangeOnlineManagement`.
- **How to implement if missing:** Install the module (`Install-Module ExchangeOnlineManagement`) and
  confirm modern-auth sign-in before running the steps.

## 4. DNS control for the mail domains
- **Description:** Ability to create/modify **DNS records** (MX, SPF (TXT), DKIM (CNAME), DMARC (TXT),
  Autodiscover, and connector/host records) for the domains in scope.
- **Why required:** Email authentication, mail routing/coexistence, connector validation, and client
  autodiscover all depend on DNS.
- **How to verify:** Confirm access to the authoritative DNS zone for each mail domain.
- **How to implement if missing:** Coordinate with whoever controls DNS; stage changes under change
  control (mail-flow and authentication changes are high-impact).

## 5. Hybrid Exchange & Active Directory (for hybrid solutions)
- **Description:** For **hybrid / on-premises** solutions, access to the on-premises **Exchange Server**
  organization (correct roles/CU), **Active Directory**, **Azure AD Connect** (directory sync), and the
  relevant network/firewall paths (e.g. for Edge/transport, hybrid connectors, autodiscover).
- **Why required:** Hybrid mail flow, Edge Transport, connectors, and federation read from and change
  the on-premises side.
- **How to verify:** Confirm on-prem Exchange admin access, AD access, and that directory sync is healthy.
- **How to implement if missing:** Obtain access and confirm the on-prem Exchange/AD/AAD-Connect health
  before making hybrid changes.

## 6. A pilot scope and change control
- **Description:** A **pilot group / accepted-domain / test mail flow** to validate on before fleet-wide
  rollout, and a **change-control** process for production changes (mail flow, connectors, DNS,
  authentication, hygiene policy are all high-impact).
- **Why required:** Every solution follows an **Assess → Design → Configure → Pilot → Validate → Expand**
  model; the pilot proves the design and change control protects production mail flow.
- **How to verify:** Confirm a named pilot scope and an approval/change window are available.
- **How to implement if missing:** Define a pilot scope and agree change control with the messaging/
  service owners before making production changes.

*The deployment model across every Messaging solution is the same: **Assess → Design → Configure →
Pilot → Validate → Expand**, with explicit pass/fail gates and a documented rollback for production
changes. Automation is delivered as **PowerShell** (Exchange Online PowerShell / Graph) — never with
hardcoded credentials or secrets in code.*


---


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


---


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


---


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


---


# Best Practices — Exchange Edge Transport Server Deployment & Hardening (Hybrid)

Durable practices for a secure, maintainable Edge Transport tier. **Verify version-specific defaults
against Microsoft's documentation for your Exchange Server version/CU.**

## Topology & host hygiene

- **Keep the Edge standalone in the perimeter.** Workgroup or a dedicated perimeter/DMZ domain — never
  the internal production AD forest. That isolation is the whole point of the role.
- **Minimize the host.** Only the Edge role, AD LDS, and required OS features; no extra roles or
  general-purpose software. Patch the OS and Exchange on a defined cadence.
- **One responsibility.** Don't co-locate other internet-facing services on the Edge host.

## EdgeSync

- **Let EdgeSync own the internet connectors.** After subscribing, the internet Send connector
  (`EdgeSync – <site> to Internet`) and the inbound Receive connector are **auto-managed** — don't
  hand-edit them on the Edge; make connector/accepted-domain changes on the **internal** org and let
  them replicate down.
- **Re-subscribe when config drifts.** If EdgeSync health degrades or you change the Edge's role
  fundamentals, the clean fix is often to remove and **re-create the subscription** rather than
  hand-patching.
- **Watch clock skew and certificates.** EdgeSync uses a self-signed cert and secure LDAP (50636);
  time skew and cert expiry are common silent failure causes — monitor both.

## Connectors, accepted domains, relay

- **Never grant anonymous relay to external recipients.** Scope Receive connectors so anonymous
  internet senders can deliver **only** to your accepted domains — that is the anti-open-relay
  guarantee. Any internal application relay should use an **authenticated** or **IP-scoped** connector,
  not anonymous-to-anywhere.
- **Manage accepted domains internally.** They sync to the Edge; don't try to author them on the Edge.
- **Prefer least privilege on connector permissions** (`PermissionGroups` / `AuthMechanism`) and
  review them after every CU.

## TLS & authentication

- **Enforce TLS.** Keep a valid public certificate (`Cert – Edge SMTP – Prod`) enabled for SMTP with a
  matching subject/SAN; advertise STARTTLS. Use **forced/mutual TLS** for partners and hybrid paths
  that require it.
- **Disable legacy TLS** (1.0/1.1) and weak ciphers where your Exchange version/CU and OS support it —
  **this is version/OS-dependent; verify** and stage it, because it can break older partners.
- **Track certificate expiry** with the reporting/health scripts; a lapsed cert breaks secure flow and
  EdgeSync trust.

## Hygiene split with the cloud (hybrid)

- **Don't double-filter.** In a hybrid where **EOP / Defender for Office 365** is the primary hygiene
  layer, keep the Edge focused on **perimeter connection control, TLS, and safe relay**; let cloud do
  content/anti-phish. Duplicated aggressive filtering causes false positives and hard-to-trace drops.
- **If a third-party secure email gateway is your internet-facing MX,** the Edge role may be redundant
  — decide deliberately whether you need Edge at all, or whether it becomes an internal-facing relay.
- **Tune IP Allow/Block and providers conservatively.** Over-broad blocks silently drop legitimate
  mail; document every entry in `Hygiene – Edge Baseline – Prod`.

## Change control, monitoring & lifecycle

- **Pilot-first, always.** Validate on a test mail path and pass Gates B–D before cutting production MX.
  Keep a recorded baseline and a ready **rollback** (revert MX, remove subscription).
- **Monitor continuously:** EdgeSync health (`Test-EdgeSynchronization`), queues (`Get-Queue`),
  certificate expiry, and anti-spam posture. Schedule `Get-EdgeReadiness.ps1` and
  `Get-AntiSpamReport.ps1`.
- **Re-validate after every CU.** Exchange CUs can change TLS/Extended Protection defaults and agent
  behavior — re-run the validation set after each update.
- **Automation is read-only or `-WhatIf` by default.** Never store credentials in scripts; use
  interactive modern-auth for any cloud/EXO steps.

## Commercial vs Government

- The on-prem Edge steps are cloud-independent, but **hybrid/cloud touch points differ on
  GCC/GCC High/DoD** (EOP endpoints, connector targets, admin portal URLs such as `*.office365.us`).
  Confirm the correct sovereign-cloud endpoints; do **not** assume Commercial paths.


---


# Deliverables Summary — Exchange Edge Transport Server Deployment & Hardening (Hybrid)

Everything included in this solution, at a glance.

## Documentation

| Document | What it covers |
|---|---|
| **Solution Overview** | The Edge Transport role in a hybrid perimeter — EdgeSync, connectors, anti-spam agents, TLS, the reference design, benefits/limits, and the Assess→Design→Configure→Pilot→Validate→Expand model. |
| **Requirements Guide** | Solution-specific prerequisites (perimeter host, AD LDS + Exchange prereqs, DNS both directions, firewall ports 50636/25, SMTP certificate, healthy internal org, change window/pilot/rollback), each with verify/implement — on top of the shared Messaging requirements. |
| **Implementation Guide** | Exact ordered steps: install the Edge role, create + import the Edge Subscription (EdgeSync), configure connectors + accepted domains, apply anti-spam/connection filtering, harden OS/TLS and close the open relay — pilot-first, every artifact named, with pass/fail gates and rollback. |
| **Testing & Validation** | Seven procedures each with expected pass/fail, mapped to Gates A–D (host readiness, EdgeSync health, no open relay, TLS enforced, anti-spam posture, mail flow, post-cut sanity). |
| **Troubleshooting** | Common failure modes (EdgeSync failed, one-way mail flow, open relay found, TLS/cert errors, over-blocking hygiene) with root cause and resolution. |
| **Best Practices** | Durable practices — standalone perimeter host, EdgeSync ownership of connectors, no anonymous external relay, TLS enforcement, hygiene split with EOP, change control/monitoring, and Commercial-vs-Government notes. |
| **Executive Summary** | One-page outcome/approach/why-low-risk for decision-makers. |

## PowerShell scripts (5) — safe-by-default (read-only or `-WhatIf`), no credentials in code

| # | Script | What it does | Safe default |
|---|---|---|---|
| 1 | **`Get-EdgeReadiness.ps1`** | Read-only readiness/discovery — OS/version, workgroup-vs-domain state, AD LDS presence, ports 50636/25 reachability, DNS both directions, and existing EdgeSync state. Backs **Gate A**. | Read-only |
| 2 | **`Set-EdgeConfig.ps1`** | EdgeSync/connector setup helper — reports the subscription, EdgeSync-managed connectors, and accepted domains; can stage a partner mutual-TLS Send connector. Report-only unless `-Commit`, and every write honors `-WhatIf`. Backs **Gate B**. | Report-only / `-WhatIf` |
| 3 | **`Test-OpenRelay.ps1`** | Open-relay + TLS validator — probes the Edge SMTP listener to confirm anonymous external relay is **denied** and (optionally) STARTTLS is advertised. Non-delivering (stops before DATA). Backs **Gate C**. | Read-only / non-delivering |
| 4 | **`Get-AntiSpamReport.ps1`** | Read-only anti-spam / connection-filter report — transport agents, IP Allow/Block lists + providers, and filtering configs; optional JSON snapshot of `Hygiene – Edge Baseline – Prod`. | Read-only |
| 5 | **`Get-EdgeScopeHealth.ps1`** | Scope/health helper — consolidated read-only scorecard: EdgeSync status, connector scope, SMTP certificate expiry, and queue depth, mapped to the gates. Re-run after each CU. | Read-only |

> All scripts use modern-auth interactive sign-in where cloud/EXO is involved and contain **no
> hardcoded credentials or secrets**. On-prem cmdlets run in the **Exchange Management Shell** on the
> correct server (Edge vs internal). **Exchange behavior is version/CU-dependent — verify for your
> version** before applying any change.
