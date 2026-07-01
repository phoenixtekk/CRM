# Certificate-Based VPN Authentication for Cisco ISE with Intune (SCEP/PKCS)

> **Version 1.0.0** · Category: Security · Solution code: CISECERT

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary — Certificate-Based VPN Authentication for Cisco ISE with Intune

## The problem
Password-based VPN is the weak link Cisco ISE was built to remove. Passwords are phishable, shared,
and reused; they give no proof that the connecting device is trusted. The fix — issuing the right
device or user certificate to every endpoint, with a trust chain ISE will validate — defeats most
teams because it spans three moving parts (a certificate authority, Intune delivery, and the Cisco
head-end) that must line up exactly.

## The solution
This package stands up **certificate-based VPN authentication end to end**. You issue a device or
user certificate from **Microsoft Intune** — via **SCEP** (Certificate Connector / NDES or a Cloud
PKI) or **PKCS** — deploy the **trusted-root** and certificate profiles so the chain is complete on
each device, and hand **Cisco ISE** a clean **EAP-TLS identity** to authenticate. The result is
passwordless VPN: the endpoint proves itself with a certificate instead of a secret.

It is delivered **pilot-first and rollback-ready**, following a disciplined **Assess → Configure →
Pilot → Validate → Expand** model with explicit pass/fail gates — cert present, chain valid, ISE
EAP-TLS authentication success — so a misconfiguration is caught on a handful of pilot devices, never
on the fleet.

## What you get
- A **Solution Overview** explaining EAP-TLS with ISE as the RADIUS authority, the SCEP-vs-PKCS
  choice, and the trust chain ISE must validate.
- A **Requirements Guide** covering every prerequisite with how to verify and implement each.
- A click-by-click **Implementation Guide** for the Intune/Entra/certificate side.
- **Five PowerShell scripts** for readiness discovery, per-device certificate + chain validation,
  fleet coverage/expiry reporting, safe remediation, and pilot-group targeting.
- **Testing, Troubleshooting, and Best-Practices** guides with real pass/fail gates and field-proven
  renewal, revocation, and key-protection guidance.

## Scope and boundary
The **Intune, Entra, and certificate** side is authored at exact, click-by-click detail. **Cisco ISE
and VPN head-end console internals** (trust-store import, Certificate Authentication Profile, policy
sets, identity sources, RADIUS/VPN connection profiles) are **deferred to Cisco's official
documentation** — this solution guarantees ISE receives a correct, complete, chain-valid certificate
to authenticate.

## The bottom line
Every VPN user authenticated by a certificate Cisco ISE trusts — no passwords, delivered from Intune,
and proven on a pilot before you scale. Self-guided and tested, at a fraction of the cost of a
consulting engagement.


---


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


---


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


---


# Global Requirements — Security solutions (Intune + Entra ID + cloud PKI) (category-level)

These requirements apply to **every** solution in the **Security solutions (Intune + Entra ID +
cloud PKI)** category. They are published once at the category level so individual listings stay
small. Confirm these before deploying *any* security solution in this category. Each entry:
**Description · Why · Verify · Implement-if-missing.**

## G1. Microsoft Entra ID tenant
**Description:** An active Microsoft Entra ID tenant.
**Why:** It is the identity backbone for every cloud-managed device, certificate, and security policy.
**Verify:** Sign in to `https://entra.microsoft.com` as an administrator.
**Implement:** Create a Microsoft 365 / Azure subscription, which provisions a tenant.

## G2. Microsoft Intune subscription
**Description:** An Intune-bearing license plan.
**Why:** Intune delivers the configuration, certificate, compliance, and security policies these solutions rely on.
**Verify:** `https://intune.microsoft.com` loads; **Tenant administration → Tenant status** shows active.
**Implement:** Assign Microsoft 365 E3/E5, Business Premium, or standalone Intune Plan 1.

## G3. Administrative roles
**Description:** Appropriate Entra/Intune admin roles for the operator.
**Why:** Creating certificate profiles, connectors, and security policies requires elevated rights.
**Verify:** Entra → **Roles and administrators**; confirm **Intune Administrator**.
**Implement:** Assign **Intune Administrator**; reserve Global Administrator for tenant-wide changes.

## G4. Device enrollment in Intune
**Description:** Targeted devices are enrolled and manageable.
**Why:** Certificate and security policies only reach enrolled devices.
**Verify:** Intune → **Devices → All devices**; the device appears and is **compliant**.
**Implement:** Enable **Automatic Enrollment** and join devices to Entra ID.

## G5. Pilot security group
**Description:** A Microsoft Entra security group for pilot/targeted users or devices.
**Why:** Every solution in this category is piloted before fleet rollout — especially anything that touches authentication.
**Verify:** Entra → **Groups**; the pilot group exists.
**Implement:** Entra → **Groups → New group** → **Security** → add members.

## G6. Supported, current OS baseline
**Description:** Devices on a vendor-supported, currently-patched OS (Windows 10/11, iOS/iPadOS, Android, or macOS as applicable).
**Why:** Modern Intune certificate and security features assume a supported, patched OS.
**Verify:** `winver` (Windows), device **Settings → About**, or Intune → device → **Hardware**.
**Implement:** Patch/upgrade to a supported build before deploying policies.

## G7. Network access to Microsoft cloud endpoints
**Description:** Outbound HTTPS to Microsoft 365, Entra, and Intune service URLs.
**Why:** Enrollment, policy sync, certificate issuance, and authentication depend on these endpoints.
**Verify:** From a device, reach `https://login.microsoftonline.com` and `https://enrollment.manage.microsoft.com`.
**Implement:** Allow Microsoft's published Microsoft 365 / Intune URL and IP ranges through proxy/firewall.

## G8. Change control for authentication-impacting changes
**Description:** A documented change-control / rollback process for any change that touches certificates, Wi-Fi, VPN, or sign-in.
**Why:** Certificate and authentication changes can lock users out of network or apps if misconfigured; a pilot gate and rollback are mandatory.
**Verify:** A change ticket exists with an approver, a maintenance window, and a documented rollback step.
**Implement:** Record the change, name a pilot group, define the rollback, and get approval before assigning to production.

---
**The deployment model (all solutions):** **Assess → Configure → Pilot → Validate → Expand.**


---


# 3. Implementation — Certificate-Based VPN Authentication for Cisco ISE with Intune

This is the ordered, click-by-click procedure. Follow the steps in order — the **trust chain must be
deployed before the certificate profile**, and everything is **piloted before it is expanded**.
Deployment model: **Assess → Configure → Pilot → Validate → Expand.**

**Object names used here (reuse verbatim):**
`Cisco VPN – Trusted Root` · `Cisco VPN – SCEP Device Cert` · `Cisco VPN – SCEP User Cert` ·
`Cisco VPN – PKCS User Cert` · `PILOT – Cisco Cert VPN Users` · `BROAD – Cisco Cert VPN Users`

**Vendor boundary:** Steps 1–6 (Intune/Entra/certificate) are exact. Step 7 (Cisco ISE + head-end)
is described at the architectural level and points to Cisco's documentation for exact console steps —
do not expect ISE menu paths here.

---

## Step 0 — Assess and decide (before you touch Intune)
1. Confirm all requirements in **`02-requirements.md`** and the category
   **`global-requirements-security.md`**.
2. **Decide the identity ISE will key on.** This drives everything:
   - **Device identity** (machine authenticates the tunnel) → use a **SCEP device** certificate
     (`Cisco VPN – SCEP Device Cert`). Typical Subject/SAN: device name / hardware identifier.
   - **User identity** (user authenticates) → use a **SCEP user** or **PKCS user** certificate
     (`Cisco VPN – SCEP User Cert` / `Cisco VPN – PKCS User Cert`). Typical SAN: **UPN**.
3. Choose **SCEP vs PKCS** (see `01-solution-overview.md`). Default to **SCEP** unless you need a
   directory-attribute Subject/SAN that your connector only produces via **PKCS**.
4. **Record the exact Subject/SAN format** you will issue — you must hand ISE the same identity to
   key on (coordinate with whoever configures ISE).
5. Ensure a change ticket exists with an approver, a maintenance window, and a rollback step
   (global R8).

**Gate 0 (pass/fail):** Identity model, profile type (SCEP/PKCS), and Subject/SAN format are decided
and written down. **Fail** = stop; do not build profiles until the identity is agreed with ISE.

---

## Step 1 — Create the scope groups
Create the pilot and broad groups first so profiles can be assigned to them.

**Option A — portal:**
1. Go to **`https://entra.microsoft.com`** → **Groups → All groups → New group**.
2. **Group type:** Security. **Group name:** `PILOT – Cisco Cert VPN Users`. Create.
3. Repeat for `BROAD – Cisco Cert VPN Users`.
4. Add a few **pilot** members (the test users, or their devices if you chose device certs) to
   `PILOT – Cisco Cert VPN Users`. Leave `BROAD` empty for now.

**Option B — script:** run **`CISECERT-Set-ScopeTargeting.ps1 -Apply`** to create both groups
idempotently, then add pilot members.

**Gate 1:** Both groups exist; pilot group has test members. 

---

## Step 2 — Build the Trusted certificate profile (`Cisco VPN – Trusted Root`)
The chain must be on the device **before** the leaf.

1. In **`https://intune.microsoft.com`**, go to **Devices → Manage devices → Configuration →
   Policies → Create → New Policy**.
2. **Platform:** choose your target platform (e.g. **Windows 10 and later**). **Profile type:**
   **Templates → Trusted certificate**. Click **Create**.
3. **Name:** `Cisco VPN – Trusted Root`. **Description:** "Root CA for Cisco EAP-TLS VPN — deploys
   the trust chain the leaf certificate must chain to." **Next.**
4. **Configuration settings:** **Certificate file** → upload the **root** CA `.cer` (from R3).
   For Windows, set **Destination store** = **Computer certificate store – Root**.
5. **Next** through Scope tags (optional).
6. **Assignments:** add group **`PILOT – Cisco Cert VPN Users`** to **Included groups**. **Next.**
7. **Review + create.**
8. **If you have an intermediate CA:** repeat Steps 2.1–2.7 with the intermediate `.cer`, naming it
   **`Cisco VPN – Trusted Root (Intermediate)`** and destination store
   **Computer certificate store – Intermediate**. Assign the same pilot group.

> **Do the equivalent import on Cisco ISE (Step 7):** ISE needs the **same** root/intermediate in its
> own trust store. Deploying to devices alone is not sufficient.

**Gate 2:** `Cisco VPN – Trusted Root` (and intermediate, if any) exists and is assigned to
`PILOT – Cisco Cert VPN Users`.

---

## Step 3 — Build the SCEP or PKCS certificate profile
Do **3A** for SCEP **or** **3B** for PKCS — matching the choice from Step 0.

### 3A — SCEP certificate profile (`Cisco VPN – SCEP Device Cert` or `… SCEP User Cert`)
1. **Devices → Manage devices → Configuration → Policies → Create → New Policy.**
2. **Platform:** your platform. **Profile type: Templates → SCEP certificate.** **Create.**
3. **Name:** `Cisco VPN – SCEP Device Cert` (device) **or** `Cisco VPN – SCEP User Cert` (user).
   **Next.**
4. **Configuration settings:**
   - **Certificate type:** **Device** or **User** (match your identity decision).
   - **Subject name format:** set to the identity you agreed with ISE (e.g. `CN={{DeviceName}}` for
     device, or `CN={{UserPrincipalName}}` for user).
   - **Subject alternative name:** add the SAN ISE keys on — commonly **UPN** =
     `{{UserPrincipalName}}` for user certs. **This must match the ISE Certificate Authentication
     Profile.**
   - **Certificate validity period:** e.g. **1 year**.
   - **Key storage provider (KSP):** Enroll to TPM if present, otherwise Software KSP (Windows).
   - **Key usage:** Digital signature + Key encipherment.
   - **Extended key usage (EKU):** add **Client Authentication** (`1.3.6.1.5.5.7.3.2`). **Required
     for EAP-TLS.**
   - **Renewal threshold (%):** e.g. **20%** (auto-renew before expiry).
   - **Root Certificate:** select the **`Cisco VPN – Trusted Root`** profile from Step 2.
   - **SCEP Server URLs:** the NDES/SCEP URL from your Certificate Connector (or the Cloud PKI SCEP
     URL).
5. **Next** → Scope tags (optional) → **Assignments:** include **`PILOT – Cisco Cert VPN Users`**.
6. **Review + create.**

### 3B — PKCS certificate profile (`Cisco VPN – PKCS User Cert`)
1. **Devices → Manage devices → Configuration → Policies → Create → New Policy.**
2. **Platform:** your platform. **Profile type: Templates → PKCS certificate.** **Create.**
3. **Name:** `Cisco VPN – PKCS User Cert`. **Next.**
4. **Configuration settings:**
   - **Certification authority:** the FQDN of your issuing CA.
   - **Certification authority name:** the CA common name.
   - **Certificate template name:** the client-auth template published on the CA (R1).
   - **Certificate type:** **User** (typical for PKCS).
   - **Subject name format / SAN:** the identity ISE keys on (e.g. SAN **UPN** =
     `{{UserPrincipalName}}`).
   - **Extended key usage:** include **Client Authentication** (`1.3.6.1.5.5.7.3.2`).
   - **Root Certificate:** select **`Cisco VPN – Trusted Root`** from Step 2.
   - **Renewal threshold (%):** e.g. **20%**.
5. **Next** → Scope tags (optional) → **Assignments:** include **`PILOT – Cisco Cert VPN Users`**.
6. **Review + create.**

**Gate 3:** The SCEP or PKCS profile exists, includes the **Client Authentication** EKU, references
`Cisco VPN – Trusted Root`, issues the agreed Subject/SAN, and is assigned to the pilot group.

---

## Step 4 — Confirm the certificate lands on a pilot device
1. On a pilot device (a member of `PILOT – Cisco Cert VPN Users`), force an Intune sync
   (**Settings → Accounts → Access work or school → Info → Sync**, or wait for check-in).
2. Run **`CISECERT-Validation.ps1 -IssuingCaName "your-issuing-ca-name"`** on the device
   (elevated). It confirms: root trusted, leaf present and issued by your CA, chain valid, **Client
   Authentication** EKU present, and within validity.
3. Alternatively check manually: `certlm.msc` → **Personal → Certificates** shows the leaf; **Trusted
   Root** / **Intermediate** shows the CA chain.

**Gate 4 (device-side):** Validation reports **PASS** on all checks — cert present, chain valid, EKU
present. **Fail** = go to Troubleshooting **A (no cert)** / **B (chain incomplete)** before
proceeding to ISE. **Do not test ISE until this gate passes.**

---

## Step 5 — Validate ISE accepts the EAP-TLS handshake (vendor boundary)
This step happens on the **Cisco** side. It is described here architecturally; **exact ISE / head-end
console steps are Cisco's** — follow Cisco's official documentation.

1. **Ensure ISE trusts the CA:** the same **root/intermediate** from Step 2 is imported into ISE's
   trusted-certificate store. *(Cisco docs — ISE trusted certificates import.)*
2. **Ensure a Certificate Authentication Profile** in ISE reads the identity from the **same
   Subject/SAN** you issued in Step 3 (e.g. SAN UPN). *(Cisco docs — Certificate Authentication
   Profile.)*
3. **Ensure the VPN policy set** allows **EAP-TLS** and authorizes the pilot identity for VPN.
   *(Cisco docs — policy sets / authorization.)*
4. **Ensure the head-end** (ASA / Secure Firewall) points its VPN connection profile at ISE for
   RADIUS with certificate/EAP-TLS auth. *(Cisco docs — VPN connection profile / RADIUS.)*
5. **Connect the VPN** from the pilot device using the certificate identity (no password).
6. **Confirm in ISE Live Logs** that the authentication is **EAP-TLS** and the result is
   **Access-Accept** / success. *(Cisco docs — RADIUS Live Logs.)*

**Gate 5 (end-to-end):** ISE Live Logs show a successful **EAP-TLS Access-Accept** for the pilot
identity and the VPN session establishes **without a password**. **Fail** = Troubleshooting **C (ISE
rejects EAP-TLS)**.

---

## Step 6 — Pilot soak
1. Keep the pilot group live for your agreed soak window (e.g. 3–5 business days).
2. Run **`CISECERT-Report.ps1`** to confirm the pilot devices show **Succeeded** on the certificate
   profile and no `Error`/`Pending` laggards.
3. Watch for renewal behavior and any ISE rejections in Live Logs.

**Gate 6:** Pilot is stable for the full window — certs issued and renewing, ISE consistently
accepting EAP-TLS, zero password fallbacks. **Fail** = fix before expanding.

---

## Step 7 — Expand to broad
1. Add production members to **`BROAD – Cisco Cert VPN Users`** (or convert it to a dynamic group).
2. Add **`BROAD – Cisco Cert VPN Users`** to the **Included groups** of `Cisco VPN – Trusted Root`
   (and intermediate) **and** the SCEP/PKCS profile — the **same profiles** you piloted.
3. Expand in waves; after each wave run **`CISECERT-Report.ps1`** to confirm coverage and chase
   laggards, and spot-check ISE Live Logs.
4. Once broad coverage is confirmed and stable, plan removal of password-based VPN fallback per your
   change process.

**Gate 7:** Target fleet shows certificate coverage, ISE accepts EAP-TLS across the fleet, and the
report shows no unresolved `Error`/`Pending`. Rollout complete.

---

## Rollback (any gate fails)
- **Unassign** the SCEP/PKCS profile (and Trusted Root if needed) from the affected group — this
  stops new issuance; existing tunnels using passwords remain available if you have not yet removed
  the password fallback.
- **Do not** delete issued certificates from devices reactively; unassigning the profile and letting
  ISE fall back to the prior VPN auth method is the safe path.
- Keep the password/legacy VPN auth method enabled on the head-end until broad certificate auth is
  proven (Gate 6+), so a failure never locks users out of VPN.


---


# 5. Testing & Validation — Certificate-Based VPN Authentication for Cisco ISE with Intune

Run these tests in order. Each has an explicit **pass/fail gate**. Do not advance past a failed gate
— a failure here prevents a lockout in production. The three gates that matter most: **cert present,
chain valid, ISE EAP-TLS auth success.**

> Object names referenced: `Cisco VPN – Trusted Root`, `Cisco VPN – SCEP Device Cert` /
> `Cisco VPN – SCEP User Cert` / `Cisco VPN – PKCS User Cert`, `PILOT – Cisco Cert VPN Users`.

---

## Test 1 — Profiles exist and are assigned (readiness)
**How:** Run **`CISECERT-Discovery.ps1`**. Confirm the certificate connector is present/active and
that `Cisco VPN – Trusted Root` and your SCEP/PKCS profile appear with the pilot group assigned.
Alternatively, in **Intune → Devices → Manage devices → Configuration → Policies**, confirm both
profiles and their assignments.
**PASS:** Connector active; Trusted Root + SCEP/PKCS profiles exist and are assigned to
`PILOT – Cisco Cert VPN Users`.
**FAIL:** Missing connector or profile → Troubleshooting **A**; revisit Implementation Steps 2–3.

---

## Test 2 — The trust chain is present on the device
**How:** On a pilot device, run **`CISECERT-Validation.ps1 -IssuingCaName "your-issuing-ca-name"`**
(elevated). Check the **root trusted** result. Or open `certlm.msc` → **Trusted Root Certification
Authorities** (and **Intermediate** if applicable) and confirm the CA is present.
**PASS:** The root (and intermediate) CA certificate is present in the device trust store.
**FAIL:** Chain incomplete → Troubleshooting **B**. Do not proceed — the leaf cannot chain.

---

## Test 3 — The leaf certificate is issued and valid (cert present)
**How:** On the pilot device, from the same `CISECERT-Validation.ps1` run, check: **leaf present**,
**issued by your CA**, **chain valid**, **Client Authentication EKU present**, **within validity**.
Or `certlm.msc` → **Personal → Certificates** and inspect the leaf's **Issuer**, **EKU** (Client
Authentication), and **valid-to** date.
**PASS:** A leaf certificate issued by your CA is present, chains to the trusted root, carries the
**Client Authentication** EKU (`1.3.6.1.5.5.7.3.2`), and is unexpired.
**FAIL:** No cert / wrong EKU / broken chain → Troubleshooting **A** (no cert) or **B** (chain).

---

## Test 4 — Subject/SAN matches what ISE keys on (identity)
**How:** Inspect the leaf's **Subject** and **Subject Alternative Name** (`certlm.msc` → cert →
Details, or the Subject line printed by `CISECERT-Validation.ps1`). Compare to the identity attribute
your ISE **Certificate Authentication Profile** reads (e.g. SAN **UPN**).
**PASS:** The issued Subject/SAN exactly matches the attribute ISE is configured to key on.
**FAIL:** Mismatch → fix the SCEP/PKCS **Subject name / SAN** (Implementation Step 3) or align the
ISE Certificate Authentication Profile (Cisco docs). This is the classic silent failure.

---

## Test 5 — ISE accepts the EAP-TLS handshake (auth success)
**How:** Connect the VPN from the pilot device using the certificate (no password). Confirm success
in **ISE RADIUS Live Logs** (*Cisco docs*): the authentication method is **EAP-TLS** and the result
is **Access-Accept**.
**PASS:** ISE Live Logs show **EAP-TLS → Access-Accept** for the pilot identity and the VPN session
establishes **without a password**.
**FAIL:** ISE rejects → Troubleshooting **C**. Common causes: ISE does not trust the CA, the
Certificate Authentication Profile keys on a different attribute, revocation check fails, or the
head-end is not passing EAP-TLS.

---

## Test 6 — Renewal works before expiry
**How:** Confirm the profile's **renewal threshold** is set (e.g. 20%). For a fast check, review a
pilot device near threshold, force a sync, and re-run `CISECERT-Validation.ps1` to confirm a fresh
`NotAfter`. Use **`CISECERT-Report.ps1`** to watch for devices trending toward expiry.
**PASS:** Certificates renew automatically before expiry; no device drops to an expired leaf.
**FAIL:** Renewal not firing → Troubleshooting **D** (renewal failures).

---

## Test 7 — Fleet coverage before expansion
**How:** Run **`CISECERT-Report.ps1`** (optionally `-CsvPath`). Review Succeeded / Error / Pending
counts for the certificate profile.
**PASS:** Pilot (then each expansion wave) shows the expected Succeeded count with no unresolved
Error/Pending.
**FAIL:** Laggards present → run **`CISECERT-Remediation.ps1`** (default `-WhatIf`, then `-Apply`) to
trigger re-evaluation, re-check, then expand.

---

## Exit criteria (all must pass before broad rollout)
- Test 1 (readiness), Test 2 (**chain valid**), Test 3 (**cert present**), Test 4 (identity),
  Test 5 (**ISE EAP-TLS auth success**), Test 6 (renewal), Test 7 (coverage) all **PASS** on the
  pilot.
- A rollback step is documented and the password/legacy VPN auth path remains available until broad
  certificate auth is proven.


---


# 6. Troubleshooting — Certificate-Based VPN Authentication for Cisco ISE with Intune

Work top-down: confirm the **certificate is on the device (A)**, then the **chain is complete (B)**,
then that **ISE accepts EAP-TLS (C)**, then **renewal (D)**. Most "ISE rejects" cases are actually a
device-side chain or identity problem — fix A/B before touching ISE.

> Diagnostic scripts: `CISECERT-Discovery.ps1` (tenant readiness), `CISECERT-Validation.ps1`
> (this device), `CISECERT-Report.ps1` (fleet), `CISECERT-Remediation.ps1` (safe re-trigger).

---

## A. No certificate on the device
**Symptom:** `CISECERT-Validation.ps1` reports no leaf in `LocalMachine\My` (or user store); the
SCEP/PKCS profile shows **Error**/**Pending** in Intune.

**Check and fix:**
1. **Assignment.** Is the device/user actually in `PILOT – Cisco Cert VPN Users`, and is that group
   assigned to the SCEP/PKCS profile? (`CISECERT-Discovery.ps1` shows assigned groups.)
2. **Device check-in.** Force an Intune sync; issuance only happens on check-in. Devices offline will
   not receive the cert.
3. **Connector health.** In **Intune → Tenant administration → Connectors and tokens → Certificate
   connectors**, confirm the connector is **Active** with a recent last-connection. A stale/errored
   connector blocks all SCEP/PKCS issuance.
4. **SCEP URL / NDES.** For SCEP, verify the SCEP Server URL in the profile is correct and NDES is
   reachable/healthy. For PKCS, verify the CA name and template name are correct and the CA is online.
5. **Template permissions (PKCS/AD CS).** The connector's service account must have **Enroll** rights
   on the client-auth template.
6. **Re-trigger.** Run `CISECERT-Remediation.ps1 -CertProfileMatch "Cisco VPN" -Apply` to send a
   sync and re-evaluate issuance, then re-check with `CISECERT-Report.ps1`.

---

## B. Chain incomplete / certificate not trusted on the device
**Symptom:** The leaf is present but `CISECERT-Validation.ps1` reports **chain valid = FAIL**, or the
root is not found in the Trusted Root store.

**Check and fix:**
1. **Trusted Root profile assigned?** Confirm `Cisco VPN – Trusted Root` is assigned to the same
   group and has reached the device (`certlm.msc → Trusted Root`).
2. **Missing intermediate.** If your CA has an intermediate, you need
   `Cisco VPN – Trusted Root (Intermediate)` deployed to the **Intermediate** store. A missing
   intermediate is the most common broken-chain cause.
3. **Right store.** Windows device certs must chain via the **Computer** (LocalMachine) stores; a
   root deployed to the user store won't help a machine cert.
4. **Correct root.** Verify the deployed root is the CA that actually **issued** the leaf (issuer of
   the leaf == subject of the root).
5. Re-run `CISECERT-Validation.ps1` until **chain valid = PASS** before testing ISE.

---

## C. ISE rejects the EAP-TLS handshake
**Symptom:** VPN connects with a certificate but fails; ISE Live Logs show EAP-TLS failure /
Access-Reject (or no EAP-TLS at all). *(ISE console steps are Cisco's — this section tells you what
to check and where the boundary is.)*

**Device-side first (fix before blaming ISE):**
1. **Chain valid on device?** Confirm Test 2/3 PASS — a device that can't build its own chain will
   fail EAP-TLS.
2. **Client Authentication EKU present?** `CISECERT-Validation.ps1` reports this. Missing EKU → fix
   the SCEP/PKCS profile EKU (Implementation Step 3) and reissue.
3. **Identity match (the classic).** The leaf **Subject/SAN** must match the attribute the ISE
   **Certificate Authentication Profile** keys on (Test 4). A UPN-in-SAN cert against an ISE profile
   keyed on Subject CN silently fails.

**ISE-side (per Cisco documentation):**
4. **ISE trusts the CA.** The same **root/intermediate** must be imported into ISE's trusted-
   certificate store. If ISE doesn't trust the issuing CA, every EAP-TLS attempt is rejected. *(Cisco
   docs — ISE trusted certificates.)*
5. **EAP-TLS allowed in the policy set** and the identity authorized for VPN. *(Cisco docs — policy
   sets / authorization.)*
6. **Revocation reachability.** If ISE enforces CRL/OCSP, ISE must reach the CA's CRL/OCSP endpoints
   (R9); an unreachable CRL causes rejects even for valid certs. *(Cisco docs — revocation settings.)*
7. **Head-end passing EAP-TLS.** The ASA/Secure Firewall VPN connection profile must forward
   certificate/EAP-TLS auth to ISE as RADIUS. *(Cisco docs — VPN connection profile / RADIUS.)*
8. **Read the ISE Live Log detail** — it names the exact failure reason (unknown CA, identity not
   found, revocation, expired), which maps back to one of the checks above.

---

## D. Renewal failures
**Symptom:** Certificates expire instead of renewing; users lose VPN at cert expiry;
`CISECERT-Report.ps1` shows devices trending to expiry or dropping to Error.

**Check and fix:**
1. **Renewal threshold set?** Confirm the SCEP/PKCS profile has a **renewal threshold (%)** (e.g.
   20%). Without it, no auto-renewal.
2. **Device checking in?** Renewal only fires on Intune check-in; offline/stale devices miss the
   window. Chase stale check-ins.
3. **Connector/CA still healthy?** Renewal re-requests through the same connector/CA path as initial
   issuance — re-run Section A checks 3–5.
4. **Same identity on renewal.** Confirm the renewed cert keeps the **same Subject/SAN** so ISE still
   accepts it; a changed SAN format breaks a previously working device.
5. **ISE revocation of the old cert.** Renewal issues a new cert; ensure the superseded cert isn't
   still being presented (clear old certs if a device accumulates multiples with the same EKU).

---

## Quick reference: symptom → section
| Symptom | Go to |
| --- | --- |
| No leaf certificate on device; profile Error/Pending | A |
| Leaf present but chain invalid / root not trusted | B |
| VPN cert connects but ISE rejects / Access-Reject | C |
| Cert expires instead of renewing | D |
| Not sure if profiles/connector are even set up | Run `CISECERT-Discovery.ps1` |
| Need fleet-wide coverage/expiry picture | Run `CISECERT-Report.ps1` |


---


# 7. Best Practices — Certificate-Based VPN Authentication for Cisco ISE with Intune

Field-proven practices for running certificate-based EAP-TLS VPN authentication safely over time.
Focus areas: **renewal, revocation, and key protection.**

## Renewal
- **Set a renewal threshold** on every SCEP/PKCS profile (e.g. **20%** of validity). Auto-renewal
  before expiry is what keeps users from silently losing VPN access.
- **Keep validity periods sane.** Shorter validity (e.g. 1 year) limits exposure but means renewal
  must be reliable; do not set validity so short that renewal churn becomes a support burden.
- **Monitor upcoming expiry** with `CISECERT-Report.ps1` on a schedule; chase devices that miss a
  renewal window before their leaf expires.
- **Confirm the device checks in.** Renewal only fires when the device syncs with Intune — devices
  offline past their threshold will not renew. Track stale check-ins.
- **Test renewal in the pilot**, not in production. Verify a device near threshold actually receives
  a fresh certificate and that ISE accepts the renewed cert (same Subject/SAN).

## Revocation
- **Decide who enforces revocation.** In this design **Cisco ISE** performs revocation checking
  (CRL/OCSP) during EAP-TLS. Make that policy explicit with whoever owns ISE.
- **Ensure CRL/OCSP reachability from ISE** (R9). A valid certificate is rejected if ISE cannot
  complete a required revocation check — keep the CA's CRL distribution point / OCSP responder
  published and reachable.
- **Have a revocation runbook.** When a device is lost/retired, revoke its certificate at the CA (or
  via the Cloud PKI / connector) **and** retire the device in Intune. Revocation on the CA is what
  makes ISE deny a compromised certificate; removing the Intune assignment alone does not revoke an
  already-issued cert.
- **Keep CRL publication frequent enough** that revocation takes effect within your risk tolerance;
  prefer **OCSP** where low-latency revocation matters.

## Key protection
- **Prefer SCEP for device certs** so the **private key is generated on the device and never
  leaves it**.
- **Use the TPM** as the key storage provider where available (Windows) so the private key is
  hardware-protected and non-exportable.
- **Mark keys non-exportable.** Do not issue exportable private keys for VPN authentication unless a
  specific, documented reason exists.
- **For PKCS**, understand the key is generated at the connector/CA and delivered — protect the
  connector server accordingly and restrict who can issue against the client-auth template.

## Identity and trust hygiene
- **One agreed identity attribute.** Fix the Subject/SAN Intune issues and the attribute ISE keys on
  as a single documented decision; changing one without the other silently breaks authentication.
- **Import the chain into ISE deliberately.** Track which root/intermediate ISE trusts; rotate ISE's
  trust when the CA rotates. Deploying a new chain to devices without updating ISE breaks EAP-TLS.
- **Least-privilege EKU.** Issue leaf certificates with **Client Authentication** only unless another
  EKU is genuinely required.

## Rollout and operations
- **Always pilot first**, with a documented rollback and the password/legacy VPN path kept available
  until certificate auth is proven (Gate 6+). Never remove the fallback before broad success.
- **Expand in waves**, validating coverage with `CISECERT-Report.ps1` and spot-checking ISE Live
  Logs each wave.
- **Name every object per convention** (`Cisco VPN – …`, `PILOT – …`, `BROAD – …`) so the Intune,
  Entra, and ISE sides stay legible to the next operator.
- **Keep change control** on anything touching certificates or VPN auth (global R8) — these changes
  can lock users out of the network.
- **Respect the vendor boundary.** Own the Intune/Entra/certificate side precisely; follow Cisco's
  official documentation for ISE and head-end configuration and keep those steps in your ISE runbook.


---


# 8. Deliverables Summary — Certificate-Based VPN Authentication for Cisco ISE with Intune

## What's in this solution
A complete, self-guided package to replace password-based Cisco VPN sign-in with **certificate-based
EAP-TLS authentication** — certificates issued from **Intune** (SCEP or PKCS) with a trust chain
**Cisco ISE** validates, deployed pilot-first and rollback-ready.

## Documents
| File | What it gives you |
| --- | --- |
| `01-solution-overview.md` | How EAP-TLS certificate VPN auth works with ISE as the RADIUS authority; SCEP vs PKCS; the trust chain ISE must validate; where Intune delivery meets the Cisco head-end. |
| `02-requirements.md` | Every prerequisite (CA/Cloud PKI, Certificate Connector/NDES, trusted-root + SCEP/PKCS profiles, Entra groups, ISE for EAP-TLS, head-end, revocation) with Description / Why / Verify / Implement. |
| `03-implementation.md` | Ordered, click-by-click steps: scope groups → Trusted Root profile → SCEP/PKCS profile → confirm cert lands → validate ISE EAP-TLS → pilot → expand, with pass/fail gates and rollback. |
| `05-testing.md` | Seven validation tests with explicit gates (cert present, chain valid, ISE auth success). |
| `06-troubleshooting.md` | The failure modes: no cert, chain incomplete, ISE rejects EAP-TLS, renewal failures — with concrete fixes. |
| `07-best-practices.md` | Renewal, revocation, and key-protection practices for steady-state operation. |
| `global-requirements-security.md` | Category-level prerequisites shared across all security solutions. |
| `executive-summary.md` | One-page business case for decision-makers. |

## PowerShell scripts (read-only / safe by default)
| Script | Purpose | Default posture |
| --- | --- | --- |
| `CISECERT-Discovery.ps1` | Certificate readiness: Intune certificate connectors + trusted-root/SCEP/PKCS profiles (Graph). | Read-only |
| `CISECERT-Validation.ps1` | Confirm the VPN cert + full chain are present on **this** device (local cert store checks). | Read-only |
| `CISECERT-Report.ps1` | Certificate deployment + expiry coverage across the fleet (Graph). | Read-only |
| `CISECERT-Remediation.ps1` | Safely re-trigger missing/failed cert issuance. | `-WhatIf` by default |
| `CISECERT-Set-ScopeTargeting.ps1` | Create/populate the pilot/broad Entra group(s). | `-WhatIf` by default |

All Graph scripts require the Microsoft Graph PowerShell SDK and read-only scopes (Remediation and
group creation request write scopes only for their explicit `-Apply` action).

## Named objects you will create (reuse verbatim)
- `Cisco VPN – Trusted Root` (and `Cisco VPN – Trusted Root (Intermediate)` if applicable)
- `Cisco VPN – SCEP Device Cert` / `Cisco VPN – SCEP User Cert` / `Cisco VPN – PKCS User Cert`
- `PILOT – Cisco Cert VPN Users` / `BROAD – Cisco Cert VPN Users`

## Vendor boundary
The Intune / Entra / certificate side is documented at exact, click-by-click detail. **Cisco ISE and
VPN head-end (ASA / Secure Firewall) console configuration — trust-store import, Certificate
Authentication Profile, policy sets, identity sources, RADIUS/VPN connection profiles — is deferred
to Cisco's official documentation.** This solution guarantees ISE receives a correct, complete,
chain-valid EAP-TLS certificate to authenticate.

## Definition of done
Every targeted VPN user authenticated by a certificate Cisco ISE trusts — no passwords, issued from
Intune, proven on a pilot (Gates 0–6) before expanding to the fleet (Gate 7), with renewal and
revocation operationalized and a rollback path kept available throughout.
