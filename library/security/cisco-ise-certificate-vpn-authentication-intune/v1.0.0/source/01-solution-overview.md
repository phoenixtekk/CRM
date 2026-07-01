# 1. Solution Overview — Certificate-Based VPN Authentication for Cisco ISE with Intune (SCEP/PKCS)

## What this solution does
This solution replaces **password-based VPN sign-in** with **certificate-based EAP-TLS
authentication** that **Cisco ISE** validates. You issue a device or user certificate from
**Microsoft Intune** — using either a **SCEP** or a **PKCS** certificate profile — deploy the
**trusted-root** (and any intermediate) certificate so the chain is complete on the device, and
present Cisco ISE with a clean **EAP-TLS identity** it can trust. The result is passwordless VPN
authentication: the endpoint proves its identity with a certificate instead of a shared secret or a
phishable password.

The work divides cleanly along a **vendor boundary**:
- **Intune / Entra / certificate side** — building the Trusted certificate profile, the SCEP or PKCS
  certificate profile, the scope groups, assignment, and validation — is covered here at exact,
  click-by-click detail.
- **Cisco ISE side** — the policy set, the Certificate Authentication Profile, the identity source
  sequence, and the RADIUS/VPN head-end configuration — is described here at the correct
  architectural level and **deferred to Cisco's official documentation** for exact console steps.
  This document does not fabricate ISE menu paths.

## How EAP-TLS certificate VPN authentication works (with ISE as the RADIUS authority)
1. A VPN client (for example Cisco Secure Client / AnyConnect) initiates the VPN tunnel to the VPN
   head-end (the ASA / Firepower / Secure Firewall).
2. The head-end acts as a **RADIUS client** and forwards authentication to **Cisco ISE**, which is
   the **RADIUS authority (authentication server)**.
3. ISE and the endpoint perform an **EAP-TLS** handshake. In EAP-TLS the client presents its **client
   certificate**; ISE validates that certificate against the **trust chain** it holds and the
   **Certificate Authentication Profile** rules you configure in ISE.
4. If the certificate is trusted, unexpired, not revoked, has the **Client Authentication** EKU, and
   its identity attribute (Subject / SAN) matches an authorized identity, ISE returns
   **Access-Accept** and the VPN session is established — **no password is exchanged**.

Cisco ISE is the entity that must **trust and validate** the certificate. Intune is the entity that
**delivers** the certificate and its trust chain to the endpoint. This solution makes those two
sides meet correctly.

## The trust chain ISE must validate
For ISE to accept an EAP-TLS certificate, the **entire chain** must line up:
- The endpoint holds a **leaf client certificate** issued by your issuing CA (via Intune SCEP/PKCS).
- The endpoint also holds the **root** (and any **intermediate**) certificate — delivered by the
  Intune **Trusted certificate** profile — so the leaf chains to a trusted root **on the device**.
- **Cisco ISE** must independently hold and trust the **same root/intermediate** in its own
  certificate trust store, so ISE can build and validate the chain when the endpoint presents its
  leaf. If ISE does not trust the issuing CA, EAP-TLS fails even when the certificate is perfectly
  installed on the device.

The chain must therefore be present in **two** places: on the **device** (Intune deploys it) and in
**Cisco ISE** (you import it per Cisco's documentation). This is the single most common failure
point and is called out again in Testing and Troubleshooting.

## SCEP vs PKCS (which profile to use)
Intune can issue the client certificate two ways. Pick per your CA and identity model:

- **SCEP** — the device generates its **own private key** and requests a certificate using a
  challenge issued through the **Intune Certificate Connector** (NDES/SCEP) or a **Cloud PKI** that
  supports SCEP. The private key **never leaves the device**. Best for **device** certificates and
  the broadest platform support (Windows, iOS/iPadOS, Android, macOS).
- **PKCS** — the certificate (and its private key) is issued **through the connector** against a CA
  template and delivered to the device. Common for **user** certificates and scenarios that need a
  specific Subject/SAN pulled from **directory attributes** (for example the user's UPN in the SAN).

Guidance:
- Use **SCEP** for device-authenticated VPN where the machine identity is what ISE trusts, and where
  keeping the private key on-device is a requirement.
- Use **PKCS** for user-authenticated VPN where ISE keys off the **user identity** (UPN/email in the
  SAN) and you want the certificate subject to follow directory attributes.
- Many fleets run **one** of these for VPN; some run both (device cert for the machine tunnel, user
  cert for the user tunnel). Decide the identity ISE will key on **first**, then choose the profile
  type that produces that identity.

## Where Intune's certificate delivery meets the Cisco head-end
| Layer | Owner | This solution |
| --- | --- | --- |
| Issuing CA / Cloud PKI | Your CA / cloud PKI vendor | Named as a prerequisite; setup deferred to CA/vendor docs |
| Certificate delivery to endpoints (root + leaf) | **Intune** | **Full click-by-click detail here** |
| Scope / pilot targeting | **Intune + Entra groups** | **Full detail here** |
| Trust store on ISE (root/intermediate import) | **Cisco ISE** | Described architecturally; steps deferred to Cisco docs |
| EAP-TLS policy, Certificate Authentication Profile, identity source | **Cisco ISE** | Described architecturally; steps deferred to Cisco docs |
| VPN head-end / RADIUS client config | **Cisco ASA / Secure Firewall** | Described architecturally; steps deferred to Cisco docs |

## What you can control (Intune side)
- Which **trust chain** (root + intermediate) is deployed to devices, and to whom.
- The **Subject name** and **SAN** format of the issued certificate (from device/user attributes) —
  this is the identity ISE will read.
- **Key size / usage**, **validity period**, and **renewal threshold** (auto-renew before expiry).
- The **Client Authentication** EKU (`1.3.6.1.5.5.7.3.2`) — required for EAP-TLS.
- The **scope** of issuance via Entra security groups (pilot first, then expand).

## Limitations (be honest with buyers)
- **Cisco ISE and the VPN head-end are out of scope for exact steps.** ISE trust-store import, the
  Certificate Authentication Profile, policy sets, identity source sequences, and ASA/Secure Firewall
  VPN configuration follow **Cisco's** documentation. This solution guarantees the Intune-issued
  certificate is correct, complete, and chain-valid — the input EAP-TLS needs.
- **You must import the same root/intermediate into ISE.** Deploying the chain to devices is not
  enough; ISE has its own trust store.
- **Identity mismatch is the classic failure.** The Subject/SAN Intune issues must match what your
  ISE Certificate Authentication Profile keys on (for example UPN in SAN). Design this together.
- **Revocation checking (CRL/OCSP) is enforced by ISE**, not Intune. If ISE is set to check
  revocation, the CA's CRL/OCSP endpoints must be reachable from ISE.

## The standard deployment model
> **Deploy the trusted chain → create the SCEP/PKCS certificate profile → issue to a named pilot
> group → confirm the cert + chain land on the device → validate ISE accepts the EAP-TLS handshake →
> expand to broad.**
> Pattern: **Assess → Configure → Pilot → Validate → Expand**, with an explicit pilot gate and a
> documented rollback.
