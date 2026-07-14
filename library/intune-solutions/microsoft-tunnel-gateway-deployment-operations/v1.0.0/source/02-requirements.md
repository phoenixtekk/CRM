# 2. Requirements Guide — Microsoft Tunnel Gateway: Deployment, VPN Configuration & Ongoing Operations

Verify **every** requirement before configuring. Each entry: **Description · Why · Verify ·
Implement-if-missing.** Category-wide prerequisites (Entra tenant, Intune subscription, admin roles,
device enrollment, pilot group, network access to Microsoft cloud endpoints) are in
`global-requirements-intune-solutions.md` — confirm those too; they are not repeated here.

> **Naming convention used throughout this package:** `<Purpose> – <Scope> – <Stage>`. The objects you
> create are named exactly: Site `Tunnel Site – HQ – Prod`; Server Configuration
> `Tunnel Server Config – Split Tunnel – Prod`; connection profiles `Tunnel VPN – iOS – Pilot`,
> `Tunnel VPN – Android – Pilot`, `Tunnel VPN – Windows – Pilot`, `Tunnel VPN – macOS – Pilot`;
> Conditional Access policy `Tunnel Access – Compliant Devices – Report-Only`; device groups
> `Tunnel Devices – Pilot` and `Tunnel Devices – Broad`. Reuse these verbatim in every step, test, and
> script. Use `contoso.com` / `tunnel.contoso.com` as placeholder names — never a real tenant/FQDN.

> **"Verify current Microsoft guidance" flag.** Microsoft periodically changes the supported Linux
> distributions, container runtimes, server sizing, port requirements, and client-platform matrix for
> Microsoft Tunnel. Where an item below could drift, it is marked **[verify current Microsoft
> guidance]**. Confirm the current values on Microsoft Learn for your region/cloud before you buy
> hardware or open firewall rules.

## 2.1 Intune licensing for Microsoft Tunnel
**Description:** An Intune plan that includes Microsoft Tunnel, assigned to the users who will connect.
**Why:** Tunnel is an Intune feature; users and the deployment require appropriate Intune licensing.
**Verify:** M365 admin center → **Billing → Licenses**; confirm Intune Plan 1 (or a bundle that
includes it) is assigned to pilot users. **[verify current Microsoft guidance]** on any Tunnel-specific
licensing.
**Implement:** Assign Microsoft 365 E3/E5, Business Premium, or standalone Intune Plan 1.

## 2.2 A supported Linux host for the Gateway
**Description:** A dedicated Linux server (physical or VM) to run the Tunnel Gateway container. Plan
one host per Tunnel server; plan **two or more** if you want high availability from day one.
**Why:** The Tunnel Gateway runs as a container on Linux — this host *is* the gateway.
**Verify:** You have a Linux VM/host with a supported distribution and version, adequate CPU/RAM/disk,
and network access to your internal resources. Run `TUNGW-HostPrereqCheck.sh` on the host.
**Implement:** Provision a Linux VM on a **supported distribution and version** with the documented
minimum CPU / RAM / disk. **[verify current Microsoft guidance]** — supported distros (historically
Red Hat / CentOS-family and Ubuntu), versions, and sizing change; confirm before provisioning.

## 2.3 Container runtime (Podman or Docker)
**Description:** A supported container runtime installed on the Linux host — **Podman** or **Docker**,
matched to your distribution.
**Why:** The Microsoft Tunnel agent runs as a container; the install script deploys it into this
runtime.
**Verify:** `podman --version` **or** `docker --version` returns a supported version;
`TUNGW-HostPrereqCheck.sh` reports the runtime present.
**Implement:** Install the runtime that matches your distro (**[verify current Microsoft guidance]** on
which runtime/version pairs with which distro), enable and start its service, and confirm a test
container runs.

## 2.4 TLS server certificate for the Gateway
**Description:** A TLS **server** certificate (with private key) whose subject / Subject Alternative
Name matches the **public FQDN** that clients will use to reach the Tunnel (e.g.
`tunnel.contoso.com`), plus the full trust chain.
**Why:** Clients establish a TLS session to the gateway; the certificate must be valid, trusted by the
clients, and cover the exact FQDN, or connections fail.
**Verify:** You hold the certificate and private key in the format the installer expects (commonly PEM
`.pem`/`.crt` + key, plus chain) and the FQDN is present in the SAN. Confirm expiry is comfortably in
the future. `TUNGW-HostPrereqCheck.sh` checks for the cert files and reports the not-after date.
**Implement:** Obtain a certificate from a public or internal CA for the Tunnel FQDN. **[verify current
Microsoft guidance]** on the exact file format/layout the current installer expects, and place the
files where setup will read them. Ensure clients trust the issuing chain (public CA = already trusted;
internal CA = deploy the root via a **Trusted certificate** profile).

## 2.5 Public FQDN + DNS + network path
**Description:** A public DNS name (`tunnel.contoso.com`) that resolves to the gateway's reachable
address (or to the load-balancer VIP in an HA design), and a network path from clients → gateway →
internal resources.
**Why:** Clients connect by FQDN; the gateway must reach the internal ranges you intend to publish.
**Verify:** `nslookup tunnel.contoso.com` resolves to the intended address; from the host you can reach
a representative internal resource. `TUNGW-HostPrereqCheck.sh` runs the connectivity checks.
**Implement:** Create the DNS record; open the inbound **listener port** (default TCP **443**,
configurable — **[verify current Microsoft guidance]**) from clients to the gateway/VIP; ensure the
host can route to your internal CIDR ranges.

## 2.6 Outbound connectivity from the Gateway to Microsoft services
**Description:** Outbound HTTPS from the Linux host to the Microsoft endpoints the Tunnel agent and
Intune enrollment require (Entra login, Intune/Graph management, the Tunnel service, and the container
image source at install time).
**Why:** The server registers with Intune, pulls its configuration, reports health, and downloads the
container image — all outbound to Microsoft.
**Verify:** From the host, reach `https://login.microsoftonline.com` and the Intune/Graph endpoints;
`TUNGW-HostPrereqCheck.sh` probes the key endpoints.
**Implement:** Allow the host outbound to Microsoft's published Intune/Entra/Tunnel URL & IP ranges and
the container registry used at install. **[verify current Microsoft guidance]** for the current
required FQDN/IP list.

## 2.7 Microsoft Defender for Endpoint app (mobile Tunnel client)
**Description:** The **Microsoft Defender for Endpoint** app, deployed via Intune to iOS/iPadOS and
Android devices — it provides the device-side Tunnel VPN client.
**Why:** On the natively supported mobile platforms, Defender for Endpoint is the client that
establishes the Tunnel connection defined by the VPN profile.
**Verify:** Intune → **Apps → All apps**; the Defender app is added and assigned to `Tunnel Devices –
Pilot`. **[verify current Microsoft guidance]** on the current client app for each platform.
**Implement:** Add and assign the Defender app for iOS and Android to the Tunnel device group before
you assign the VPN profiles.

## 2.8 Client authentication method decided
**Description:** How devices authenticate to the Tunnel — Microsoft Entra ID (username/password + MFA)
or **certificate-based** authentication (a SCEP/PKCS-issued client certificate).
**Why:** The VPN connection profile references the chosen method; certificate auth additionally
requires a working certificate pipeline and a trusted root on the device.
**Verify:** You have decided the method; for certificate auth, a SCEP/PKCS profile and trusted-root
profile exist (or are planned).
**Implement:** For Entra auth, no extra pipeline. For certificate auth, stand up SCEP/PKCS (a separate
effort) and plan `Tunnel Client Cert – SCEP – Pilot` and `Trusted Root – Org CA – Mobile` profiles.

## 2.9 Load balancer for high availability (if deploying HA)
**Description:** A **Layer-4 / TCP passthrough** load balancer in front of two or more Tunnel servers
in the same Site, presenting the Site FQDN VIP.
**Why:** HA and scale-out put multiple servers behind one FQDN; the TLS session must pass through
un-terminated (L4), because the gateway terminates TLS itself.
**Verify:** The load balancer does **TCP/L4 passthrough** (not TLS termination) on the listener port
and health-probes the servers.
**Implement:** Configure an L4/TCP passthrough VIP for the listener port across the server pool.
**[verify current Microsoft guidance]** on the supported balancing model and health-probe approach.

## 2.10 Microsoft Graph PowerShell (for the reporting scripts)
**Description:** The Microsoft Graph PowerShell SDK on the admin workstation.
**Why:** `TUNGW-Discovery.ps1`, `TUNGW-Validate.ps1`, and `TUNGW-Report.ps1` read Tunnel configuration
and device state via Graph.
**Verify:** `Get-Module Microsoft.Graph -ListAvailable` returns a version.
**Implement:** `Install-Module Microsoft.Graph -Scope CurrentUser`. Consent to the read scopes
(`DeviceManagementConfiguration.Read.All`, `DeviceManagementManagedDevices.Read.All`) on first connect.

## 2.11 Pilot and broad device groups
**Description:** Entra security groups `Tunnel Devices – Pilot` (a few representative devices/users)
and `Tunnel Devices – Broad` (the rest).
**Why:** Every deployment is piloted before fleet rollout.
**Verify:** Entra → **Groups**; both groups exist.
**Implement:** Entra → **Groups → New group → Security** → add members.

---
## Checklist
- [ ] Intune licensing for Tunnel assigned to pilot users
- [ ] Supported Linux host provisioned — `TUNGW-HostPrereqCheck.sh` **[verify distro/version/sizing]**
- [ ] Container runtime (Podman/Docker) installed and running — `TUNGW-HostPrereqCheck.sh`
- [ ] TLS server certificate (+ key + chain) for the Tunnel FQDN, in the expected format
- [ ] Public FQDN + DNS + inbound listener port + internal routing path
- [ ] Outbound connectivity to Microsoft endpoints — `TUNGW-HostPrereqCheck.sh`
- [ ] Microsoft Defender for Endpoint app deployed to iOS/Android pilot devices
- [ ] Client authentication method chosen (Entra or certificate)
- [ ] Load balancer (L4/TCP passthrough) if deploying HA
- [ ] Microsoft Graph PowerShell installed + read scopes consented
- [ ] `Tunnel Devices – Pilot` and `Tunnel Devices – Broad` groups created
