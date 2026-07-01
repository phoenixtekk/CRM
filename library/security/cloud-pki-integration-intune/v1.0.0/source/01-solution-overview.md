# 1. Solution Overview — Cloud PKI Integration with Intune (Certificate Management Modernization)

## What a cloud PKI integration with Intune is
A **cloud PKI** is a hosted certification authority (CA) service that issues and manages the
certificates your fleet needs — for Wi-Fi, VPN, and user/device authentication — without you running
and maintaining an on-prem CA. When that cloud PKI offers an **Intune integration** (a connector or
plugin registered to your tenant), Intune becomes the delivery mechanism: it deploys the cloud PKI's
**trust chain** to devices and issues certificates from the cloud PKI through standard Intune
**SCEP** and **PKCS** certificate profiles. The result is the same certificate-backed scenarios you
have today, but issued from the cloud and managed end-to-end through Intune.

This solution is **vendor-neutral**: it treats the cloud PKI as "a cloud PKI with an Intune
connector/plugin." The specific product's console, connector installation, and CA-template internals
are deferred to that vendor's documentation. What you get here is the correct, repeatable
**Intune-side** procedure that works regardless of which cloud PKI you choose.

## Why modernize off an on-prem CA (the *why*)
- **Fragility.** An on-prem CA plus the legacy Intune **certificate connector (NDES/SCEP)** is a
  multi-server chain (CA, NDES, connector, IIS) that is hard to make highly available and is a single
  point of failure for network access.
- **Scale and maintenance.** Patching, certificate-template management, and connector upkeep are
  ongoing burdens; the cloud PKI shifts CA operations to the vendor.
- **Cert sprawl and visibility.** Without central reporting it is hard to know which devices have
  valid certificates and which are about to expire. A cloud PKI plus Intune profiles gives one
  consistent issuance and reporting surface.
- **Reduced on-prem footprint.** Retiring the on-prem CA dependency removes servers, firewall
  exceptions, and a class of outages from the environment.

## How it works
1. The cloud PKI's **Intune connector/plugin** is connected to your tenant (per the vendor's
   documentation), so Intune can request certificates from the cloud PKI's issuing CA.
2. Intune deploys the cloud PKI's **trusted root** and any **intermediate** certificate(s) to devices
   via **Trusted certificate** profiles — the chain must be present before any leaf certificate is useful.
3. Intune **SCEP** certificate profiles (challenge-based, the private key generated on-device) and/or
   **PKCS** certificate profiles (CA-issued through the connector) request certificates from the cloud
   PKI and install them on assigned devices.
4. Certificate-backed profiles — **Wi-Fi**, **VPN**, and authentication scenarios — reference the
   issued certificate, so devices authenticate using the cloud-issued identity.
5. Issuance and trust status is observable in Intune (per-profile device status) and via the included
   reporting scripts (coverage + expiry).

## SCEP vs PKCS (which profile to use)
- **SCEP** — the device generates its own private key and requests a certificate using a challenge.
  Best for **device** certificates and the broadest platform support; the private key never leaves the
  device.
- **PKCS** — the certificate is issued through the connector and delivered to the device. Common for
  **user** certificates and scenarios that need a specific subject/SAN from directory attributes.
- Many fleets use **both**: SCEP for device authentication (Wi-Fi/VPN), PKCS for user authentication.
  Confirm which your cloud PKI's Intune integration supports — most support SCEP, many support PKCS.

## What you can control
- Which **trust chain** (root + intermediate) is deployed, and to whom.
- The **subject name** and **SAN** format of issued certificates (from device/user attributes).
- **Key size/usage**, **validity period**, and **renewal threshold** (auto-renew before expiry).
- The **scope** of issuance via Entra security groups (pilot first, then broad).
- The certificate-backed **Wi-Fi/VPN/auth** profiles that consume the issued certificate.

## Limitations (be honest with buyers)
- The **cloud PKI product itself is out of scope** here — its console, connector install, and CA
  configuration follow the **vendor's** documentation. This solution covers the Intune integration and
  rollout.
- **PKCS** support and exact SCEP challenge/connector behavior **vary by cloud PKI**; confirm against
  the vendor's docs before designing user-certificate flows.
- **Migration off a legacy CA is a coexistence exercise**, not a switch flip — old and new chains must
  both be trusted during the transition, and certificate-backed profiles (Wi-Fi/VPN) must be re-pointed
  carefully to avoid lockouts.
- Some scripts that touch **cloud-PKI-product-specific** APIs are flagged and deferred to vendor docs;
  the Intune/Graph-side discovery, validation, and reporting are fully covered.

## The standard deployment model
> **Connect the cloud PKI → deploy the trusted chain → create SCEP/PKCS profiles → issue to a pilot →
> validate Wi-Fi/VPN/auth → migrate workloads off the legacy CA (coexist, then retire) → expand.**
> Pattern: **Assess → Configure → Pilot → Validate → Expand**, with a pilot gate and rollback.
