# 1. Solution Overview — Configuration Manager Cloud Management Gateway (CMG)

## What a Cloud Management Gateway is
A Cloud Management Gateway (CMG) is a service you deploy in Microsoft Azure that lets Configuration
Manager (Microsoft Endpoint Configuration Manager / SCCM current branch) manage Windows clients
that are on the internet — laptops that left the LAN and rarely come back. The CMG is a secure
front door: clients on the internet authenticate to it, and it forwards their management traffic to
your on-premises Configuration Manager site through a companion component called the CMG connection
point. No VPN is required, and no inbound firewall holes are opened to your site — all traffic is
outbound from the client to Azure and outbound from your site server to Azure.

## How it works
1. A `CMG – Internet Clients – Pilot` cloud service is deployed in your Azure subscription. It is the
   public endpoint internet clients reach (an Azure cloud service, fronted by a DNS name and a server
   authentication certificate).
2. A CMG connection point site system role inside your Configuration Manager site connects outbound to
   the CMG and relays client traffic to the management point (MP) and software update point (SUP).
3. Internet clients authenticate using either Microsoft Entra ID (Azure AD) token-based authentication
   (the modern default, no client PKI certificate needed) or PKI client authentication certificates.
4. The management point and software update point are configured to allow CMG traffic, so internet
   clients receive policy, send hardware/software inventory, run software deployments, and get
   software updates.
5. Clients are told they may use the CMG through the `Cloud Services` client settings, and you assign
   them to a pilot collection first (`CMG – Internet Clients – Pilot`) before expanding.
6. CMG health, client reach, and traffic are monitored in the Configuration Manager console and the
   Azure portal.

## Token vs. PKI authentication (pick one model)
- Microsoft Entra ID token authentication (recommended): clients that are Entra-joined or
  hybrid-Entra-joined authenticate with a token. This avoids issuing and managing client PKI
  certificates. It requires the site to be onboarded to Azure AD (Cloud Management) and clients to be
  Entra-registered.
- PKI client authentication: clients present a client authentication certificate issued by your
  internal CA. Use this when devices are not Entra-joined. It requires distributing client
  certificates and trusting your CA chain.
- Either way, the CMG itself always needs a server authentication certificate that internet clients
  trust (commonly a public certificate matching the CMG DNS name).

## What you can control
- Which clients may use the CMG (via `Cloud Services` client settings and collection scoping).
- Authentication model (Entra token and/or PKI client certificates).
- Whether the management point and software update point allow CMG traffic.
- Content delivery to internet clients (CMG can act as a cloud distribution point / serve content).
- Capacity (number of CMG virtual machine instances) and cost.

## Benefits
- Reach — internet-based clients receive policy, updates, inventory, and deployments with no VPN.
- Security — no inbound firewall ports to your site; traffic is outbound to Azure, authenticated by
  token or PKI, and TLS-encrypted.
- Visibility — devices that used to go dark off-LAN report health and inventory again.
- Coexistence — works alongside on-premises management points and distribution points, and alongside
  co-management with Microsoft Intune.

## Limitations (be honest with buyers)
- A CMG runs in Azure and incurs ongoing Azure cost (compute, storage, egress) that you must budget.
- It requires a supported Configuration Manager current branch version and an Azure subscription you
  control.
- The CMG server authentication certificate (and, for PKI auth, client certificates) is real
  certificate work — your CA/PKI team is involved.
- A CMG manages Configuration Manager clients; it is not a replacement for Intune. In co-managed
  environments, decide which authority owns each workload.

## The standard deployment model
> Onboard Azure → create the `CMG – Internet Clients – Pilot` cloud service → add the CMG connection
> point → enable the MP and SUP for CMG → configure clients for cloud management → pilot → validate →
> expand. The repeatable model: Assess → Configure → Pilot → Validate → Expand.
