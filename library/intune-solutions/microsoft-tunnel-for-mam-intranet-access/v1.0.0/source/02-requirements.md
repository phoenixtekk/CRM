# 2. Requirements Guide — Microsoft Tunnel for MAM

Verify every requirement before configuring. Each entry: Description · Why · Verify ·
Implement-if-missing. Category-wide prerequisites are in `global-requirements-intune-solutions.md`.

## 2.1 Licensing
Description: Microsoft Intune Plan 1 (included in Microsoft 365 E3/E5 and Business Premium), plus
Microsoft Entra ID for Conditional Access if used.
Why: Microsoft Tunnel and app protection policies are delivered by Intune; a licensed tenant is
required to configure the gateway, connector, and MAM policies.
Verify: Microsoft 365 admin center → Billing → Licenses; confirm Intune-bearing licenses on the
in-scope users.
Implement: Assign Microsoft 365 E3/E5 or Business Premium (Intune included) to the pilot users.

## 2.2 Supported Linux host for the Tunnel Gateway
Description: A physical or virtual Linux host running a Microsoft-supported distribution and a
container engine (Docker CE or Podman), with sufficient CPU/RAM/disk per Microsoft sizing guidance.
Why: The Tunnel Gateway runs only as a container on Linux; it is the VPN endpoint the managed apps
connect to.
Verify: On the host run `cat /etc/os-release`, `docker --version` (or `podman --version`), and
confirm the distro/version and container engine are on Microsoft's supported list; run
`TUNMAM-Discovery.ps1` to confirm the server later appears in Intune.
Implement: Provision a supported Linux VM, install Docker CE or Podman, and apply current OS
patches before installing the gateway.

## 2.3 TLS server certificate for the gateway
Description: A TLS certificate (with private key) whose subject/SAN matches the public FQDN clients
use to reach the Tunnel Gateway, from a CA the clients trust.
Why: The gateway presents this certificate to establish the encrypted tunnel; a mismatched or
untrusted certificate breaks every connection.
Verify: Confirm the certificate FQDN matches the gateway's published name and that the issuing CA
chain is trusted on iOS/Android; check the not-after (expiry) date.
Implement: Obtain a certificate (public CA or an enterprise PKI trusted by the devices) for the
gateway FQDN, export it with its private key and full chain, and stage it for the install script.

## 2.4 Network paths and firewall
Description: Inbound access from clients to the gateway on the configured TLS port (default TCP/UDP
443), and outbound from the gateway host to the internal resources plus to Microsoft Tunnel service
endpoints.
Why: Clients must reach the gateway; the gateway must reach both Intune (for the connector) and the
internal resources it forwards traffic to.
Verify: From the internet reach the gateway FQDN on the chosen port; from the gateway host reach the
internal target and Microsoft's Tunnel/Intune endpoints; run `TUNMAM-Validation.ps1` for the
Intune-side health signal.
Implement: Open the inbound tunnel port to the gateway, allow the gateway host outbound to internal
targets and to Microsoft's published Intune/Tunnel URLs and IP ranges through the firewall/proxy.

## 2.5 Internal DNS resolution
Description: DNS servers reachable from the gateway that resolve the internal names the managed apps
will request, plus the correct DNS suffix(es).
Why: A managed app can reach the tunnel yet still fail if the internal hostname does not resolve.
Verify: From the gateway host resolve the internal resource FQDN; confirm the same DNS servers are
set in the server configuration.
Implement: Set the internal DNS servers and DNS suffix search list in the Tunnel server
configuration; ensure split DNS is configured if only some names should resolve through the tunnel.

## 2.6 MAM client apps in scope
Description: The specific MAM-protected apps that must reach the intranet — Microsoft Edge on
iOS/Android, and any Intune App SDK / wrapped line-of-business apps — installed on the target
devices.
Why: Tunnel for MAM routes traffic only from supported, policy-managed apps; unsupported apps cannot
use the app tunnel.
Verify: Confirm each in-scope app is a supported Tunnel-for-MAM client and is deployed to the pilot
users; run `TUNMAM-Discovery.ps1` to list the app protection / MAM configuration.
Implement: Deploy the supported apps (for iOS, publisher Microsoft Corporation — Microsoft Edge
bundle ID `com.microsoft.msedge`; for Android, package `com.microsoft.emmx`) and confirm each LOB app
is Intune App SDK enabled.

## 2.7 App protection policies (MAM)
Description: iOS and Android app protection policies targeting the in-scope apps and pilot users.
Why: The Tunnel (MAM) configuration is delivered alongside app protection; without an APP the apps
are not managed and cannot be configured for the tunnel.
Verify: Intune → Apps → App protection policies; confirm an iOS and an Android policy targets the
apps and the pilot group.
Implement: Create app protection policies for iOS and Android targeting the in-scope apps and the
pilot group before adding the tunnel configuration.

## 2.8 Pilot group
Description: A Microsoft Entra security group of pilot users for the MAM tunnel configuration and
app protection policies.
Why: The tunnel is validated on a pilot before broad rollout.
Verify: Entra → Groups; the pilot group exists with the intended members.
Implement: Entra → Groups → New group → Security; add the pilot users. Name it
`Tunnel MAM Users – Pilot – Ring1`.

---
## Checklist
- [ ] Intune licensing assigned to in-scope users
- [ ] Supported Linux host with Docker/Podman ready
- [ ] TLS server certificate (FQDN match, trusted chain) staged
- [ ] Inbound tunnel port open; gateway outbound to internal + Microsoft endpoints
- [ ] Internal DNS resolves the target names from the gateway
- [ ] Supported MAM apps deployed to pilot users
- [ ] iOS + Android app protection policies targeting the apps
- [ ] Pilot Entra group created — `Tunnel MAM Users – Pilot – Ring1`
