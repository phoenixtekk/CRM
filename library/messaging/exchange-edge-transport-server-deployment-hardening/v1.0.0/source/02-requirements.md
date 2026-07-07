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
