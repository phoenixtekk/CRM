# 2. Requirements — Certificate-Based VPN Authentication for Cisco ISE with Intune

> These are the **solution-specific** prerequisites. The **category-level** prerequisites (Entra
> tenant, Intune subscription, admin roles, device enrollment, pilot group, supported OS, network
> access, change control) are in **`global-requirements-security.md`** — confirm those first.
>
> Object-naming convention used throughout this solution (reuse verbatim):
> - Trusted root profile: **`Cisco VPN – Trusted Root`**
> - SCEP device certificate profile: **`Cisco VPN – SCEP Device Cert`**
> - SCEP user certificate profile: **`Cisco VPN – SCEP User Cert`**
> - PKCS user certificate profile: **`Cisco VPN – PKCS User Cert`**
> - Pilot scope group: **`PILOT – Cisco Cert VPN Users`**
> - Broad scope group: **`BROAD – Cisco Cert VPN Users`**

Each requirement below is stated as **Description / Why required / How to verify / How to implement
if missing.**

---

## R1. An issuing Certificate Authority (on-prem CA or Cloud PKI)
**Description:** A CA that can issue **client-authentication** certificates — either an on-prem
Microsoft Enterprise CA (AD CS) or a **Cloud PKI** service that integrates with Intune.
**Why required:** The leaf certificate ISE validates must be issued by a CA. There is no
certificate-based VPN without one.
**How to verify:** For AD CS, the CA is online and has a certificate template with **Client
Authentication** EKU. For Cloud PKI, the vendor's issuing CA is provisioned and its Intune
integration is registered.
**How to implement if missing:** Stand up an AD CS Enterprise CA and publish a client-auth template,
**or** provision a Cloud PKI (for example Microsoft Cloud PKI or a third-party) per the vendor's
documentation. CA build steps are deferred to Microsoft/CA-vendor docs.

## R2. The Intune Certificate Connector (SCEP via NDES) — for on-prem CA SCEP/PKCS
**Description:** The **Intune Certificate Connector** installed on a Windows server, connected to
your tenant, and (for SCEP) fronted by **NDES** with the SCEP/NDES policy module. PKCS also uses
this connector.
**Why required:** SCEP/PKCS issuance from an **on-prem** CA flows through this connector. (A Cloud
PKI with native Intune SCEP may not need NDES — confirm with the vendor.)
**How to verify:** **Intune admin center → Tenant administration → Connectors and tokens →
Certificate connectors** (`https://intune.microsoft.com`) shows the connector with a recent
**last-connection** time and an **Active** state.
**How to implement if missing:** Install the Certificate Connector on a supported Windows Server,
sign in with an Intune Administrator during setup, and (for SCEP) configure **NDES + the SCEP policy
module**. Deferred to Microsoft's connector/NDES documentation.

## R3. Trusted-root (and intermediate) certificate file(s)
**Description:** The **root CA certificate** (and any **intermediate** CA certificate) as `.cer`
files, exported from your issuing CA / Cloud PKI.
**Why required:** The Intune **Trusted certificate** profile deploys these so the device can chain
the leaf certificate to a trusted root. Without the chain on the device, the leaf is unusable and
EAP-TLS fails.
**How to verify:** You have the root `.cer` (Base-64/DER) on hand; open it and confirm it is the CA
that will issue the leaf. If there is an intermediate, you have that too.
**How to implement if missing:** Export the root/intermediate from the CA console (AD CS: **certutil
-ca.cert** or the CA MMC) or download it from the Cloud PKI portal.

## R4. Trusted-root certificate profile in Intune
**Description:** An Intune **Trusted certificate** profile named **`Cisco VPN – Trusted Root`** that
deploys the root (and, if separate, a second profile or the same profile chain for the intermediate).
**Why required:** It places the CA root/intermediate into the device's Trusted Root store so the leaf
chains correctly.
**How to verify:** **Intune admin center → Devices → Manage devices → Configuration → Policies**;
the profile **`Cisco VPN – Trusted Root`** exists and is assigned.
**How to implement if missing:** Build it in Implementation **Step 2** (this is core solution work).

## R5. SCEP or PKCS certificate profile in Intune
**Description:** An Intune **SCEP** or **PKCS** certificate profile (named per convention, e.g.
**`Cisco VPN – SCEP Device Cert`** or **`Cisco VPN – PKCS User Cert`**) that issues the leaf with the
**Client Authentication** EKU and the Subject/SAN ISE will key on.
**Why required:** This issues the actual certificate ISE authenticates. Its EKU and Subject/SAN must
match what ISE expects.
**How to verify:** The profile exists under **Configuration → Policies** and its EKU includes
**Client Authentication**.
**How to implement if missing:** Build it in Implementation **Step 3** (core solution work).

## R6. Entra security groups for scope (pilot and broad)
**Description:** Two Entra security groups: **`PILOT – Cisco Cert VPN Users`** and
**`BROAD – Cisco Cert VPN Users`** (device- or user-based to match your chosen certificate type).
**Why required:** Certificate rollout is piloted before fleet-wide — mandatory for anything that
touches authentication (see global R8, change control).
**How to verify:** **Entra admin center → Groups → All groups** (`https://entra.microsoft.com`); both
groups exist.
**How to implement if missing:** Create them in Entra, or run **`CISECERT-Set-ScopeTargeting.ps1`**
(included) to create them idempotently.

## R7. Cisco ISE configured for EAP-TLS (trust store + certificate authentication)
**Description:** Cisco ISE is deployed as the RADIUS authority and configured to accept **EAP-TLS**:
the **same root/intermediate** imported into ISE's trusted-certificate store, a **Certificate
Authentication Profile** that reads the identity from the certificate (Subject or SAN), and a policy
set that authorizes VPN access.
**Why required:** ISE is the entity that trusts and validates the certificate. If ISE does not trust
the issuing CA or is not configured for EAP-TLS, authentication fails regardless of a perfect
device-side certificate.
**How to verify:** In the ISE console, the issuing CA's root/intermediate appears in the trusted
certificates store, a Certificate Authentication Profile exists, and EAP-TLS is allowed in the
relevant policy set. **Exact ISE navigation is deferred to Cisco's documentation.**
**How to implement if missing:** Import the CA chain into ISE, create the Certificate Authentication
Profile, and enable EAP-TLS in the VPN policy set **per Cisco's official ISE documentation.** This
solution provides the correct certificate for ISE to consume; the ISE console steps are Cisco's.

## R8. Cisco VPN head-end pointing at ISE for RADIUS (EAP-TLS enabled)
**Description:** The VPN head-end (Cisco ASA / Secure Firewall) configured to use **ISE as its
RADIUS server** for the VPN connection profile/tunnel-group, with EAP-TLS / certificate
authentication enabled and a matching VPN client profile (e.g. Cisco Secure Client / AnyConnect).
**Why required:** The head-end is the RADIUS client that hands the EAP-TLS session to ISE; without it
the certificate is never presented to ISE.
**How to verify:** The head-end's VPN connection profile references ISE as RADIUS and permits
certificate/EAP-TLS authentication. **Exact head-end steps are deferred to Cisco's documentation.**
**How to implement if missing:** Configure the ASA/Secure Firewall VPN connection profile to use ISE
RADIUS with EAP-TLS **per Cisco's documentation.**

## R9. Revocation reachability (if ISE enforces CRL/OCSP)
**Description:** If ISE is configured to check certificate revocation, the CA's **CRL distribution
point** and/or **OCSP responder** must be reachable **from ISE**.
**Why required:** ISE will reject an otherwise-valid certificate if it cannot complete a required
revocation check.
**How to verify:** ISE can reach the CRL/OCSP URLs embedded in the issued certificate (test from
ISE / the network per Cisco docs).
**How to implement if missing:** Publish the CRL/OCSP endpoints and allow ISE to reach them, or
adjust ISE's revocation policy per Cisco's documentation.
