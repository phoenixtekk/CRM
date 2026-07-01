# Cisco ISE 802.1X Certificate Authentication for Wi-Fi & Wired via Intune

> **Version 1.0.0** · Category: Network · Solution code: ISE8021X

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary

## The risk

Pre-shared Wi-Fi keys and open switch ports are an open door. A shared passphrase can be copied off a
whiteboard or extracted from one device; an unattended network jack lets anything that plugs in reach
the corporate network. Neither approach establishes **who** or **what** is connecting. As the fleet
grows, this is an unmanaged, unauditable attack surface sitting underneath everything else.

## The outcome

Every managed device **proves its identity with a certificate before it is allowed onto the network** —
on both **Wi-Fi and wired**. Access is granted by **certificate**, not by a password anyone can share.
A device without a valid certificate simply cannot connect. This is on-premises **Network Access
Control (NAC)** done the strong way, and it is the wired/wireless counterpart to certificate-based VPN.

## The approach

The solution combines two proven platforms across a clean boundary:

- **Microsoft Intune** issues the device certificate (SCEP/PKCS, or Microsoft Cloud PKI) and delivers
  the **Wi-Fi and wired 802.1X network profiles** to every managed device — automatically, at scale.
- **Cisco ISE** acts as the **RADIUS authentication authority**, validating each device's certificate
  over **EAP-TLS** and admitting or denying it. The switches and wireless controllers enforce the
  verdict at the port.

The Intune, Entra, and certificate work is documented at **exact, click-by-click detail**. The Cisco
ISE and network-infrastructure configuration is addressed at the **architectural level with pointers
to Cisco's official documentation** — this solution never fabricates ISE or switch menu paths.

## How it is delivered

A disciplined, reversible rollout: **Assess → Configure → Pilot → Validate → Expand**, with three
explicit pass/fail gates — **certificate present**, **profile applied**, **ISE 802.1X authentication
success** — proven on a small pilot group before any fleet-wide expansion, and a documented rollback
at every step.

Included: full requirements, implementation, testing, troubleshooting, and best-practice guides, plus
**five PowerShell scripts** for readiness discovery, per-device validation, fleet coverage reporting,
safe remediation, and pilot-group targeting — all read-only or `-WhatIf` by default.

## The bottom line

Every device certificate-authenticated onto Wi-Fi and wired by Cisco ISE — profiles and certificates
delivered from Intune, and proven on a pilot before you scale. Self-guided, tested, and repeatable, at
a fraction of the cost of a bespoke consulting engagement.


---


# Solution Overview

## What this solution delivers

This solution makes **every managed device prove its identity with a certificate** before it is
allowed onto your Wi-Fi or a wired switch port. It does that by using **Microsoft Intune** to issue
the device certificate and to push the **Wi-Fi and wired 802.1X network profiles**, and by using
**Cisco Identity Services Engine (ISE)** as the **RADIUS authentication authority** that checks the
certificate and admits (or denies) the device. The authentication method is **EAP-TLS** — the
mutual-certificate flavor of 802.1X — which is the strongest, most phishing-resistant network
authentication method in common use.

In plain terms: pre-shared Wi-Fi keys and open switch ports are replaced by **certificate-based
network access control (NAC)**. A device that lacks a valid certificate simply cannot get on the
network.

## How 802.1X / EAP-TLS works (the moving parts)

802.1X is a three-party conversation:

1. **Supplicant** — the software on the endpoint (Windows/macOS/iOS/Android native 802.1X client)
   that presents the certificate. Intune configures the supplicant through the Wi-Fi and wired
   network profiles.
2. **Authenticator** — the network device that controls the port: a **wireless LAN controller (WLC)
   or access point** for Wi-Fi, or an **Ethernet switch** for wired. It does not decide who gets in;
   it relays credentials to the RADIUS server and enforces the verdict (open the port / VLAN, or
   keep it closed).
3. **Authentication server** — **Cisco ISE**, acting as the **RADIUS** server. ISE validates the
   presented certificate against a trusted certificate authority (CA), applies its policy, and
   returns **Access-Accept** or **Access-Reject** to the authenticator.

With **EAP-TLS**, authentication is *mutual and certificate-based*:

- The **device presents a client certificate** (issued by your CA via Intune).
- **ISE presents its own server certificate**, which the device trusts because Intune also delivered
  the **trusted root** for ISE's certificate chain.
- Both sides validate each other's certificate chain. No passwords cross the wire. There is no
  pre-shared key to steal, phish, or leak.

The same EAP-TLS mechanism secures **both** transports:

- **Wi-Fi** — the endpoint associates to a corporate SSID configured for **WPA2/WPA3-Enterprise**;
  the WLC/AP brokers the EAP-TLS exchange to ISE.
- **Wired** — the endpoint plugs into an 802.1X-enabled switch port; the switch brokers the same
  EAP-TLS exchange to ISE.

Because the credential is a certificate on the device (not a user password), this works for
**user-attended laptops and unattended/headless devices** alike.

## The certificate + network-profile model (what Intune delivers)

Intune's job is to put four things on every in-scope device, all named consistently and reused
verbatim throughout this solution:

| Object (named) | What it is | Role |
| --- | --- | --- |
| `Cisco 802.1X – Trusted Root` | Trusted-certificate profile | Installs the root/intermediate CA that signed **ISE's server certificate**, so the device trusts ISE. |
| `Cisco 802.1X – SCEP Cert` | SCEP (or PKCS) certificate profile | Enrolls the **device client certificate** used as the 802.1X (EAP-TLS) identity. |
| `Corp Wi-Fi – EAP-TLS` | Wi-Fi device-configuration profile | Configures the corporate SSID for WPA2/WPA3-Enterprise + EAP-TLS and points the supplicant at the SCEP-issued client cert. |
| `Wired 802.1X – EAP-TLS` | Wired (Ethernet) device-configuration profile | Configures the wired 802.1X supplicant for EAP-TLS using the same client cert. |

The certificate profiles and the network profiles are **linked**: the Wi-Fi and wired profiles are
told *which* certificate to present (the one from `Cisco 802.1X – SCEP Cert`) and *which* root to
trust for the server (`Cisco 802.1X – Trusted Root`). Get the linkage wrong and the supplicant has
nothing to present — the number-one cause of "profile applied but auth fails."

> **SCEP vs PKCS:** Both deliver a device client certificate. **SCEP** uses the Intune Certificate
> Connector plus a **NDES/SCEP** endpoint (or **Microsoft Cloud PKI**, which provides a managed CA +
> SCEP service with no on-prem NDES). **PKCS** uses the connector against an on-prem enterprise CA.
> This solution is written for **SCEP** (the common path, and the one Cloud PKI uses) and notes the
> PKCS equivalent where it differs. Pick one per certificate profile.

## Where Intune delivery meets Cisco switching / wireless

There is a clean division of responsibility, and this solution respects it deliberately:

- **Intune / Entra / certificate side (authored here in exact click-by-click detail):** issuing the
  client certificate, delivering the trusted root, and building + assigning the Wi-Fi and wired
  802.1X profiles to a pilot group, then expanding.
- **Cisco ISE + network-infrastructure side (architectural level + vendor-doc pointers only):**
  configuring ISE as the RADIUS authority (policy sets, certificate authentication profile,
  authorization results), and configuring the **WLC/AP** and **switches** to point at ISE as their
  RADIUS server and to enable 802.1X on the SSID / ports.

> **Vendor boundary (important):** The exact ISE console screens (policy sets, authorization
> profiles, certificate authentication profile), and the switch/WLC RADIUS and `dot1x`
> configuration, **change across versions and are deferred to Cisco's official documentation**. This
> guide tells you *what* must be true on the Cisco side and *how to verify it from the Intune/device
> side*; it does **not** fabricate ISE or IOS/AireOS menu paths. Follow Cisco's documentation for the
> named ISE/switch/WLC step and confirm the precise control in your console.

## The trust chain, end to end

For a device to authenticate successfully, this full chain must line up:

```
Your CA (on-prem AD CS or Microsoft Cloud PKI)
    │  issues
    ├── ISE server certificate  ──────────────► trusted by device via  Cisco 802.1X – Trusted Root
    └── device client certificate  ───────────► delivered by  Cisco 802.1X – SCEP Cert
                                                        │ presented over EAP-TLS by
                                        Corp Wi-Fi – EAP-TLS   /   Wired 802.1X – EAP-TLS
                                                        │ brokered by
                                              WLC / AP   or   802.1X switch  (RADIUS client)
                                                        │ validated by
                                                    Cisco ISE  (RADIUS authority)
                                                        │
                                             Access-Accept → device on the network
```

Every downstream document — requirements, implementation, testing, troubleshooting — walks this
chain in order and gates each link with a pass/fail check.

## Deployment model

This solution follows the standard staged model, with an explicit gate at each step:

**Assess → Configure → Pilot → Validate → Expand.**

- **Assess** — confirm the CA/PKI, Intune certificate connector, ISE RADIUS readiness, and Entra
  groups (see *Requirements*).
- **Configure** — build the four named Intune objects (trusted root, SCEP cert, Wi-Fi, wired).
- **Pilot** — assign only to `PILOT – 802.1X Devices` and prove the full chain on a handful of
  devices.
- **Validate** — cert present ✔, profile applied ✔, ISE 802.1X auth success ✔ (the three gates).
- **Expand** — widen assignment to the broader fleet once the pilot passes, keeping a documented
  rollback.


---


# Requirements

Confirm every prerequisite below **before** you build anything. Each entry follows the same shape —
**Description / Why / Verify / Implement if missing** — so you can walk the list top to bottom and
close each gap. The category-level prerequisites (Entra tenant, Intune, admin roles, network
fundamentals, pilot group, change control) are covered once in
**`global-requirements-network.md`** — read that first; the items below are the ones **specific to
802.1X EAP-TLS with Cisco ISE**.

> **Vendor boundary:** Where a requirement lives on the **Cisco ISE, switch, or WLC** side, it is
> stated at the architectural level with a pointer to Cisco's documentation. Do not expect fabricated
> ISE/IOS menu paths here — confirm the exact control in your Cisco console.

---

## R1. A certificate authority (CA) or Cloud PKI

**Description:** A certificate authority that can issue **device client certificates** (for the
EAP-TLS identity) and whose chain also signs **ISE's server certificate**. This is either an on-prem
**Active Directory Certificate Services (AD CS)** enterprise CA, or **Microsoft Cloud PKI** (a
managed CA + SCEP service in Intune).

**Why:** EAP-TLS is entirely certificate-based. Without a CA there is nothing to issue the device
identity or to anchor the trust between the device and ISE.

**Verify:** Confirm you have either (a) an AD CS enterprise CA reachable from the Intune Certificate
Connector host, or (b) **Microsoft Cloud PKI** provisioned in Intune (Intune admin center →
**Tenant administration → Cloud PKI**, a CA is listed and *Active*).

**Implement if missing:** Stand up an AD CS enterprise CA, **or** provision **Microsoft Cloud PKI**
(Intune → **Tenant administration → Cloud PKI → Create** a root or issuing CA). Cloud PKI is the
lower-friction path because it removes the on-prem NDES/SCEP server.

---

## R2. Intune Certificate Connector (for SCEP or PKCS)

**Description:** The **Intune Certificate Connector** installed and healthy, connecting Intune to your
SCEP/NDES endpoint (SCEP) or to your enterprise CA (PKCS). *Not required if you use Microsoft Cloud
PKI*, which provides the SCEP service natively.

**Why:** It is the bridge that lets Intune request and deliver certificates from your CA to devices.

**Verify:** Intune admin center → **Tenant administration → Connectors and tokens → Certificate
connectors**. The connector is listed with a **green/Active** status and a recent last-check-in time.

**Implement if missing:** Download and install the Certificate Connector on a supported Windows
Server that can reach your CA/NDES, sign in with an Intune admin during setup, and confirm it reports
*Active*. (Skip entirely if using Cloud PKI.)

---

## R3. Trusted-root certificate profile source

**Description:** The **root (and any intermediate) CA certificate that signed ISE's server
certificate**, exported as a `.cer` file, ready to import into a Trusted certificate profile named
`Cisco 802.1X – Trusted Root`.

**Why:** During EAP-TLS the device must **trust ISE's server certificate**. If the device does not
have ISE's issuing root, it rejects the server and authentication fails — even when the device's own
certificate is perfect.

**Verify:** You have the correct root `.cer` on hand, and it matches the chain of the certificate ISE
presents for EAP (ask whoever administers ISE which CA signed the **ISE EAP/RADIUS server
certificate**).

**Implement if missing:** Export the root (and intermediates) from your CA as Base-64/DER `.cer`
files. If ISE uses its own internal CA or a public CA for its EAP certificate, obtain **that** chain
instead — the root must match whatever ISE presents.

---

## R4. SCEP (or PKCS) certificate profile settings

**Description:** The certificate-request settings for the device client certificate delivered by
`Cisco 802.1X – SCEP Cert` — key size, validity, **Subject** and **Subject Alternative Name (SAN)**
format, **Extended Key Usage = Client Authentication**, and the **SCEP URL / certification-authority**
reference.

**Why:** ISE matches the incoming certificate against its policy (e.g. it reads a SAN or CN to
identify the device). The certificate must contain **Client Authentication** EKU and the identity
fields ISE expects, or ISE will reject or misclassify it.

**Verify:** Agree with the ISE administrator on the **SAN type/value** (commonly a **DNS name** or
**UPN**) and CN that ISE's certificate authentication profile will read, plus **Client
Authentication** EKU. Confirm your SCEP URL (or Cloud PKI SCEP endpoint) is known.

**Implement if missing:** Define these values now (they are entered when building
`Cisco 802.1X – SCEP Cert` in *Implementation*). For SCEP you also need a matching **NDES/SCEP
certificate template**; for Cloud PKI the issuing CA supplies the SCEP endpoint automatically.

---

## R5. Wi-Fi 802.1X profile settings

**Description:** The parameters for the Wi-Fi profile `Corp Wi-Fi – EAP-TLS`: the **corporate SSID**,
**WPA2 or WPA3-Enterprise** security, **EAP-TLS** as the EAP type, the **client certificate** source
(`Cisco 802.1X – SCEP Cert`), and the **trusted server certificate/root** (`Cisco 802.1X – Trusted
Root`), plus optional trusted **server-name** matching for ISE.

**Why:** These settings tell the Wi-Fi supplicant *how* to authenticate and *which* certificate to
present, and *which* server (ISE) to trust.

**Verify:** You know the exact **SSID string** (case-sensitive) as configured on the WLC, and whether
it is WPA2 or WPA3-Enterprise.

**Implement if missing:** Obtain the SSID and security mode from the wireless administrator. The SSID
must already exist on the WLC and be configured for 802.1X/RADIUS to ISE (see R7).

---

## R6. Wired 802.1X profile settings

**Description:** The parameters for the wired profile `Wired 802.1X – EAP-TLS`: **EAP-TLS** as the EAP
type, the same **client certificate** source (`Cisco 802.1X – SCEP Cert`) and **trusted root**
(`Cisco 802.1X – Trusted Root`), and the authentication mode (e.g. user/machine).

**Why:** Wired 802.1X uses the OS's **Wired AutoConfig** supplicant, which is **not enabled by
default** on Windows. The Intune wired profile both enables the supplicant and configures EAP-TLS.

**Verify:** Confirm the target OS supports Intune wired 802.1X profiles (Windows 10/11 primarily) and
that switch ports are (or will be) 802.1X-enabled (see R7).

**Implement if missing:** Plan the wired profile settings now; they are entered when building
`Wired 802.1X – EAP-TLS` in *Implementation*. Ensure **Wired AutoConfig (dot3svc)** will be running
(the profile can enforce this).

---

## R7. Cisco ISE configured as the RADIUS authority for EAP-TLS *(vendor side)*

**Description:** **Cisco ISE** reachable as a **RADIUS** server, with a **policy set** that permits
**EAP-TLS**, a **certificate authentication profile** that reads the certificate field your SCEP
profile populates (R4), and an **authorization result** (VLAN/permit) for authenticated devices —
plus the **WLC/AP and switches configured as RADIUS clients/NADs** pointing at ISE, with 802.1X
enabled on the SSID (R5) and the target switch ports (R6).

**Why:** ISE is the authority that actually validates the certificate and admits the device. Without
the ISE policy and the network devices trusting ISE, the supplicant has nothing to authenticate to.

**Verify:** Ask the ISE/network administrator to confirm: EAP-TLS is allowed in the relevant policy
set; ISE **trusts the CA** that issued the *device* certificates (the CA chain from R1 is in ISE's
trusted certificate store); the WLC and switches are defined as **network access devices** with a
shared RADIUS secret; and 802.1X is enabled on the SSID and ports.

**Implement if missing:** This is **Cisco-side work deferred to Cisco documentation** — configure the
ISE policy set, certificate authentication profile, authorization profile, and network-device
definitions per **Cisco ISE documentation**, and enable 802.1X/`dot1x` + RADIUS on the WLC and
switches per **Cisco WLC/IOS documentation**. Do not proceed to Pilot until ISE trusts your device CA
and the network devices point at ISE.

---

## R8. Entra security groups (assignment targets)

**Description:** Entra ID security groups used to target the profiles — at minimum the pilot group
`PILOT – 802.1X Devices`, and later a broader production group (e.g. `Corp – 802.1X Devices`).

**Why:** Intune profiles are assigned to groups. A dedicated group set gives you staged rollout and a
clean rollback (remove the group assignment).

**Verify:** Entra admin center → **Groups**; `PILOT – 802.1X Devices` exists (create it now if not).

**Implement if missing:** Create the groups in Entra (**Groups → New group → Security**), or use the
provided **`ISE8021X-Set-ScopeTargeting.ps1`** script to create and populate the pilot group. Use
**device** groups for device-certificate/machine authentication.

---

## R9. A pilot group and change control

**Description:** A defined pilot cohort (`PILOT – 802.1X Devices`) and an approved **change window +
rollback path**, as required for every Network solution (see `global-requirements-network.md`, G6/G7).

**Why:** 802.1X touches live network access — a misconfiguration can lock devices off Wi-Fi or a
switch port. Piloting and a rollback plan make the change safe and reversible.

**Verify:** The pilot group has a small set of representative devices; a rollback (remove profile
assignment / switch port fallback) is written and approved.

**Implement if missing:** Populate `PILOT – 802.1X Devices` with a handful of test devices, and agree
a rollback with the network team (e.g. keep a **fail-open** or MAB fallback on pilot switch ports
during validation — see *Best Practices*).


---


# Global Requirements — Network (category-level)

These requirements apply to **every** solution in the **Network** category (SASE/SSE, secure web
gateway, Zero Trust network access, and related network-security work — Netskope-centric). They are
published once at the category level so individual listings stay small. Confirm these before deploying
*any* Network solution. Each entry: **Description · Why · Verify · Implement-if-missing.**

> **Vendor note:** these solutions are authored at the correct architectural and procedural level.
> Exact, current **Netskope console** screens, menu paths, and tenant-specific options change over
> time and are **deferred to the official Netskope documentation and your Netskope tenant** — follow
> the named step and confirm the precise control in your console.

## G1. A Netskope tenant
**Description:** An active, licensed Netskope tenant with admin access.
**Why:** It is the control plane for SWG, ZTNA, SSL inspection, and policy.
**Verify:** Sign in to your Netskope tenant admin console as an administrator.
**Implement:** Engage your Netskope account team / reseller to provision a tenant and the required modules.

## G2. Microsoft Entra ID tenant
**Description:** An active Microsoft Entra ID (Azure AD) tenant.
**Why:** Identity is the backbone for SSO, identity-based policy, and user/group steering.
**Verify:** Sign in to `https://entra.microsoft.com` as an administrator.
**Implement:** Create a Microsoft 365 / Azure subscription, which provisions a tenant.

## G3. Endpoint management (Intune)
**Description:** Microsoft Intune (or an equivalent) able to deploy the client and certificates to endpoints.
**Why:** The Netskope client, root/decryption certificates, and steering config are delivered to managed devices.
**Verify:** `https://intune.microsoft.com` loads and target devices are enrolled and compliant.
**Implement:** Assign an Intune-bearing license plan and enroll the target devices.

## G4. Administrative roles
**Description:** Appropriate admin roles in Netskope, Entra ID, and Intune for the operator.
**Why:** Creating policies, app definitions, and deployments requires elevated rights in each plane.
**Verify:** Confirm an admin role in each console (Netskope admin; Entra/Intune admin).
**Implement:** Assign least-privilege admin roles; reserve Global Administrator for tenant-wide changes.

## G5. Network and identity fundamentals in place
**Description:** Working DNS, routing/egress, and an identity source (Entra ID / Active Directory) for users and groups.
**Why:** Traffic steering, SSL inspection, and identity-based policy depend on resolvable, routable, identified traffic.
**Verify:** Endpoints resolve DNS and reach the internet; users/groups are present in Entra ID.
**Implement:** Remediate DNS/egress; sync Active Directory to Entra ID if hybrid.

## G6. A pilot group
**Description:** A Microsoft Entra security group of pilot users/devices for staged rollout.
**Why:** Every solution is piloted before fleet rollout to validate steering, policy, and performance.
**Verify:** Entra → **Groups**; the pilot group exists.
**Implement:** Entra → **Groups → New group → Security** → add members.

## G7. Change control and a rollback path
**Description:** A change window and a documented rollback (disable steering / remove client / revert policy).
**Why:** Inline proxy, decryption, and ZTNA changes affect live traffic and must be reversible.
**Verify:** A rollback procedure is written and approved before enabling inline enforcement.
**Implement:** Define the rollback (e.g. steering exception, client uninstall, policy disable) and a comms plan.

---
**The standard deployment model (all solutions):** **Assess → Configure → Pilot → Validate → Expand.**


---


# Implementation

Follow these steps **in order**. The order matters: the **trusted root** must exist before the SCEP
profile references it, the **SCEP certificate** must exist before the Wi-Fi/wired profiles reference
it, and everything is assigned to **`PILOT – 802.1X Devices`** first — never the whole fleet.

All Intune steps use the **Microsoft Intune admin center** at `https://intune.microsoft.com`. Object
names are exact and are **reused verbatim** in *Testing* and *Troubleshooting*.

> **Vendor boundary:** Steps 6–7 (ISE and switch/WLC) are stated at the architectural level and
> **deferred to Cisco documentation**. Do not expect ISE/IOS menu paths here.

---

## Step 0 — Pre-flight

1. Confirm all *Requirements* are green (CA/Cloud PKI, Certificate Connector or Cloud PKI, ISE
   RADIUS readiness, Entra pilot group).
2. Confirm the Entra group **`PILOT – 802.1X Devices`** exists and holds a few representative test
   devices. If not, create it (Entra → **Groups → New group → Security**) or run
   `ISE8021X-Set-ScopeTargeting.ps1`.
3. Have on hand: the **root `.cer`** for ISE's server chain (R3), the agreed **SAN/CN format**
   (R4), the **SSID string** (R5), and your **SCEP URL** (or Cloud PKI issuing CA).

**Gate:** Do not continue until every item above is confirmed.

---

## Step 1 — Create the trusted-root profile `Cisco 802.1X – Trusted Root`

1. Go to **Devices → Manage devices → Configuration → Create → New policy**.
2. **Platform:** choose your target (e.g. **Windows 10 and later**). **Profile type:** **Templates →
   Trusted certificate**. Click **Create**.
3. **Name:** `Cisco 802.1X – Trusted Root`. **Description:** "Root CA for Cisco ISE EAP server
   certificate — 802.1X EAP-TLS." Click **Next**.
4. **Configuration settings:** upload the **root `.cer`** file that signed ISE's server certificate
   (from R3). For Windows, set **Destination store = Computer certificate store – Root**. Click
   **Next**.
5. **Assignments:** **Add groups → `PILOT – 802.1X Devices`**. Click **Next**.
6. **Review + create → Create.**

> If ISE's chain has intermediates, repeat Step 1 for each intermediate as a separate Trusted
> certificate profile (name them `Cisco 802.1X – Trusted Root (Intermediate)`), destination store
> **Intermediate**.

**Gate:** Profile shows **Assigned**; on a pilot device the ISE root appears under the machine's
**Trusted Root Certification Authorities** store.

---

## Step 2 — Create the SCEP certificate profile `Cisco 802.1X – SCEP Cert`

*(If you use PKCS instead of SCEP, choose **PKCS certificate** as the profile type and reference your
CA/template instead of a SCEP URL; the identity settings below are the same.)*

1. **Devices → Configuration → Create → New policy.**
2. **Platform:** same target. **Profile type:** **Templates → SCEP certificate**. Click **Create**.
3. **Name:** `Cisco 802.1X – SCEP Cert`. **Description:** "Device client certificate for 802.1X
   EAP-TLS to Cisco ISE." **Next**.
4. **Configuration settings:**
   - **Certificate type:** **Device** (machine certificate for device/machine authentication).
   - **Subject name format:** e.g. `CN={{DeviceName}}` (match what ISE expects).
   - **Subject alternative name:** add the type ISE reads (per R4), e.g. **DNS =
     `{{DeviceName}}`** or **UPN**.
   - **Certificate validity period:** e.g. **1 year**.
   - **Key storage provider (KSP):** **Enroll to TPM if present, otherwise software**.
   - **Key usage:** **Digital signature** and **Key encipherment**.
   - **Extended key usage:** ensure **Client Authentication (1.3.6.1.5.5.7.3.2)** is present.
   - **Root certificate:** select the trusted-root profile **`Cisco 802.1X – Trusted Root`**.
   - **SCEP server URLs:** enter your SCEP/NDES URL, **or** select your **Cloud PKI** issuing CA's
     SCEP endpoint.
   Click **Next**.
5. **Assignments:** **Add groups → `PILOT – 802.1X Devices`**. **Next**.
6. **Review + create → Create.**

**Gate:** Profile shows **Assigned**; on a pilot device a certificate with **Client Authentication**
EKU and the expected Subject/SAN appears in the **machine personal (My)** store, chaining to the ISE
root.

---

## Step 3 — Create the Wi-Fi 802.1X profile `Corp Wi-Fi – EAP-TLS`

1. **Devices → Configuration → Create → New policy.**
2. **Platform:** target. **Profile type:** **Templates → Wi-Fi**. Click **Create**.
3. **Name:** `Corp Wi-Fi – EAP-TLS`. **Description:** "Corporate Wi-Fi, WPA2/WPA3-Enterprise,
   EAP-TLS to Cisco ISE." **Next**.
4. **Configuration settings:**
   - **Wi-Fi type:** **Enterprise**.
   - **SSID:** the exact corporate **SSID** (case-sensitive, from R5).
   - **Connect automatically** = Yes; **Connect to this network even when not broadcasting** as
     appropriate.
   - **Security type:** **WPA2-Enterprise** (or **WPA3-Enterprise** if supported end-to-end).
   - **EAP type:** **EAP-TLS**.
   - **Client certificate for on-client authentication (identity certificate):** select
     **`Cisco 802.1X – SCEP Cert`**.
   - **Certificate server names / Root certificate for server validation:** select
     **`Cisco 802.1X – Trusted Root`**; where available, add ISE's **server name(s)** for
     server-name matching.
   Click **Next**.
5. **Assignments:** **Add groups → `PILOT – 802.1X Devices`**. **Next**.
6. **Review + create → Create.**

**Gate:** Profile shows **Assigned**; a pilot device sees the corporate SSID provisioned and, if in
range, associates using the device certificate.

---

## Step 4 — Create the wired 802.1X profile `Wired 802.1X – EAP-TLS`

1. **Devices → Configuration → Create → New policy.**
2. **Platform:** **Windows 10 and later**. **Profile type:** **Templates → Wired network**. Click
   **Create**. *(If "Wired network" is not present as a template, use the Settings Catalog "Wired
   Network" category; the fields map one-to-one.)*
3. **Name:** `Wired 802.1X – EAP-TLS`. **Description:** "Wired 802.1X, EAP-TLS to Cisco ISE." **Next**.
4. **Configuration settings:**
   - **Authentication mode:** e.g. **Machine** (device certificate) — match your ISE policy.
   - **EAP type:** **EAP-TLS**.
   - **Client certificate (identity):** select **`Cisco 802.1X – SCEP Cert`**.
   - **Trusted server / root certificate:** select **`Cisco 802.1X – Trusted Root`**; add ISE
     server-name matching where available.
   - Enable **remember/cache** and **single sign-on** settings per your standard; ensure the
     profile **starts the Wired AutoConfig (dot3svc) service**.
   Click **Next**.
5. **Assignments:** **Add groups → `PILOT – 802.1X Devices`**. **Next**.
6. **Review + create → Create.**

**Gate:** Profile shows **Assigned**; on a pilot device the **Wired AutoConfig** service is running
and the wired NIC is set to authenticate with EAP-TLS.

---

## Step 5 — Sync a pilot device and confirm delivery

1. On a pilot device: **Settings → Accounts → Access work or school → Info → Sync** (or run
   `ISE8021X-Validation.ps1` locally).
2. Confirm all four objects landed: trusted root present, client cert present (Client
   Authentication EKU), Wi-Fi profile present, wired profile present + dot3svc running.
3. In Intune, **Devices → Configuration**, open each profile → **Device status** shows the pilot
   device **Succeeded**.

**Gate (Intune side):** cert present ✔ and all profiles **Succeeded** on the pilot device.

---

## Step 6 — Confirm the Cisco ISE + network side *(vendor side — deferred to Cisco docs)*

Before an authentication can succeed, the ISE/network side (R7) must be true. Confirm with the ISE/
network administrator, per **Cisco ISE / WLC / IOS documentation**:

- ISE **trusts the CA** that issued the device certificate (device CA chain in ISE's trusted store).
- An ISE **policy set** permits **EAP-TLS**, with a **certificate authentication profile** reading
  the certificate field your SCEP profile populated (R4), and an **authorization result**
  (permit/VLAN) for authenticated devices.
- The **WLC/AP** and target **switches** are defined in ISE as network access devices with the
  shared RADIUS secret, and **802.1X is enabled** on the SSID and the target switch ports.

Do **not** fabricate these ISE/switch steps — follow Cisco documentation and confirm each control in
the Cisco console.

**Gate (Cisco side):** ISE is reachable as RADIUS, trusts the device CA, and the network devices
point at ISE.

---

## Step 7 — Validate end-to-end authentication (pilot)

1. **Wi-Fi:** connect a pilot device to the corporate SSID; confirm it associates **without** a
   password prompt (certificate is used).
2. **Wired:** plug a pilot device into an 802.1X-enabled port; confirm the port authorizes.
3. In **ISE → Operations → RADIUS → Live Logs** (Cisco side), confirm an **Access-Accept** with
   **EAP-TLS** for the pilot device. A **reject** here points back to the trust chain or ISE policy
   (see *Troubleshooting*).

**Gate (the three gates together):** cert present ✔, profile applied ✔, **ISE 802.1X auth success**
✔. Do not expand until all three pass on multiple pilot devices.

---

## Step 8 — Expand to the fleet

1. Once the pilot passes on Wi-Fi **and** wired across representative device types, add the broader
   production group (e.g. `Corp – 802.1X Devices`) to the **Assignments** of all four profiles.
2. Expand in **waves** (add device batches to the production group), watching Intune profile status
   and ISE Live Logs after each wave.
3. Keep `PILOT – 802.1X Devices` assigned for ongoing testing of changes.

**Rollback at any point:** remove the profile **assignment** from the affected group (and, if
necessary, keep a fail-open/MAB fallback on switch ports during rollout) — see *Best Practices* and
`global-requirements-network.md` (G7).


---


# Testing & Validation

Testing is organized around the **three gates** used throughout this solution. A device is not
"done" until all three pass, on **both** Wi-Fi and wired, across representative device types.

> **The three gates:** **(1) cert present** → **(2) profile applied** → **(3) ISE 802.1X auth
> success.** They are ordered — a failure at gate 1 or 2 explains most gate-3 failures, so always
> test in order.

Run the validation from two angles: **per-device** (`ISE8021X-Validation.ps1` on a pilot device) and
**fleet-wide** (`ISE8021X-Report.ps1` against Graph). The Cisco-side confirmation (ISE Live Logs) is
**deferred to the Cisco console** and noted where relevant.

---

## Gate 1 — Certificate present (device identity)

| Check | How to test | Pass | Fail |
| --- | --- | --- | --- |
| Trusted root installed | Machine **Trusted Root Certification Authorities** store (certlm.msc) or `ISE8021X-Validation.ps1` | ISE's issuing root is present | Root missing → Wi-Fi/wired will reject ISE's server cert |
| Client cert issued | Machine **Personal (My)** store | A cert with **Client Authentication** EKU, expected Subject/SAN, chaining to the ISE root | No cert, or wrong EKU/SAN |
| Cert not expired | Inspect validity dates | Valid and not near expiry | Expired/near expiry → renewal not working (see Troubleshooting) |

**Gate 1 pass condition:** trusted root present **and** a valid client cert with Client
Authentication EKU and the ISE-expected Subject/SAN.

---

## Gate 2 — Profiles applied (supplicant configured)

| Check | How to test | Pass | Fail |
| --- | --- | --- | --- |
| `Cisco 802.1X – Trusted Root` | Intune → profile → **Device status**; or `ISE8021X-Validation.ps1` | **Succeeded** on device | Error/pending |
| `Cisco 802.1X – SCEP Cert` | Intune → profile → **Device status** | **Succeeded** | Error → connector/template/SCEP URL issue |
| `Corp Wi-Fi – EAP-TLS` | `netsh wlan show profiles` / Intune status | Corporate SSID profile present, EAP-TLS | Missing profile |
| `Wired 802.1X – EAP-TLS` | `netsh lan show profiles`; **dot3svc** running (`sc query dot3svc`) | Wired profile present, EAP-TLS, Wired AutoConfig running | Missing profile or dot3svc stopped |

**Gate 2 pass condition:** all four Intune objects **Succeeded**, both network profiles present with
**EAP-TLS**, and **Wired AutoConfig (dot3svc)** running for wired.

---

## Gate 3 — ISE 802.1X authentication success (end to end)

| Check | How to test | Pass | Fail |
| --- | --- | --- | --- |
| Wi-Fi association | Connect pilot device to corporate SSID | Associates with **no password prompt** (cert used); has network access | Prompts for password / fails to associate |
| Wired authorization | Plug pilot device into 802.1X-enabled port | Port authorizes; device gets its VLAN/access | Port stays unauthorized / no network |
| ISE verdict *(Cisco side)* | **ISE → Operations → RADIUS → Live Logs** (per Cisco docs) | **Access-Accept**, method **EAP-TLS**, for the device | **Access-Reject** — read the ISE failure reason |

**Gate 3 pass condition:** Wi-Fi **and** wired both authenticate, and ISE Live Logs show
**Access-Accept / EAP-TLS** for the device.

---

## Pilot exit criteria (all must be true before Expand)

- [ ] Gate 1, 2, 3 pass on **multiple** pilot devices.
- [ ] Both **Wi-Fi and wired** authenticate via EAP-TLS.
- [ ] Representative **device types/OS** covered (e.g. Windows laptop + any other in scope).
- [ ] **Certificate renewal** verified (a cert nearing expiry re-enrolls; test by shortening validity
      on a lab device or confirming the renewal threshold).
- [ ] **Rollback** exercised once (remove assignment → device falls back cleanly per plan).
- [ ] ISE Live Logs are clean (no unexpected rejects) across the pilot window.

Only when every box is checked do you widen assignment to the production group (Implementation, Step
8).

---

## Fleet coverage (ongoing)

Run **`ISE8021X-Report.ps1`** to produce a coverage report across the fleet:

- devices with the **client certificate** present,
- devices with **`Corp Wi-Fi – EAP-TLS`** applied,
- devices with **`Wired 802.1X – EAP-TLS`** applied,
- gaps (in the target group but missing a cert or profile).

Coverage gaps are the input to **`ISE8021X-Remediation.ps1`** (which defaults to `-WhatIf`).


---


# Troubleshooting

Work the problem in the order of the **three gates** — most authentication failures are actually a
missing certificate (gate 1) or a mis-linked profile (gate 2) surfacing as an ISE reject (gate 3).
Object names below are the exact ones created in *Implementation*.

> **Vendor boundary:** ISE Live Logs, ISE policy, and switch/WLC configuration are on the **Cisco
> side** and are referenced at the architectural level — read the ISE failure reason and the switch
> port state per **Cisco documentation**; this guide does not fabricate ISE/IOS menu paths.

---

## A. No certificate on the device (gate 1)

**Symptom:** `ISE8021X-Validation.ps1` reports no client cert, or the machine **Personal (My)** store
has no Client-Authentication cert.

- **`Cisco 802.1X – SCEP Cert` shows an error in Intune (Device status).** Check the **Certificate
  Connector** health (Tenant administration → Connectors and tokens) — if it is down, no SCEP request
  succeeds. For Cloud PKI, confirm the issuing CA is **Active**.
- **Connector healthy but still no cert.** Verify the **SCEP URL** is reachable from the device and
  the **NDES/SCEP template** matches the profile (key usage, EKU, validity). A template mismatch
  causes silent enrollment failure.
- **Root not present, so the chain can't build.** Confirm `Cisco 802.1X – Trusted Root` deployed
  **first** and is in the machine Root store; the SCEP profile references it under **Root
  certificate**.
- **Wrong device targeting.** Confirm the device is in `PILOT – 802.1X Devices` and the profile
  assignment includes that group.

---

## B. Profile not applied (gate 2)

**Symptom:** cert is present but the Wi-Fi or wired profile is missing / shows an error.

- **Profile shows "Error"/"Conflict" in Intune.** Open **Device status** on the specific profile; a
  **conflict** usually means another Wi-Fi/wired profile targets the same device with different
  settings — remove the conflicting one.
- **Wi-Fi profile applied but SSID never appears.** The **SSID string is case-sensitive** and must
  match the WLC exactly. Re-check `Corp Wi-Fi – EAP-TLS` against the real SSID.
- **Wired profile applied but nothing happens.** Confirm **Wired AutoConfig (dot3svc)** is running
  (`sc query dot3svc`); the wired profile should start it. If stopped, the supplicant never engages
  the port.
- **Platform mismatch.** A Windows wired profile won't apply to a non-Windows device — confirm the
  profile **platform** matches the target OS.
- **Not synced yet.** Force a sync (Company Portal / Settings → Access work or school → Sync) and
  re-check.

---

## C. ISE rejects the authentication (gate 3)

**Symptom:** cert + profiles present, but the device won't get on the network; ISE Live Logs show
**Access-Reject** *(read the ISE reason — Cisco side)*.

- **"Untrusted certificate" / chain not trusted at ISE.** ISE does not trust the **CA that issued the
  device certificate**. The device CA chain must be in **ISE's trusted certificate store** — a
  Cisco-side fix per Cisco docs.
- **Device rejects ISE's server certificate.** The device is missing **ISE's** root — confirm
  `Cisco 802.1X – Trusted Root` is the correct root for ISE's *server/EAP* certificate (not the
  device CA), and that server-name matching (if enabled) matches ISE's actual name.
- **Identity/SAN mismatch.** ISE's **certificate authentication profile** reads a field (CN, SAN-DNS,
  SAN-UPN) that your `Cisco 802.1X – SCEP Cert` does not populate the way ISE expects. Align the
  **Subject/SAN format** (R4) with what ISE reads — coordinate with the ISE admin.
- **EAP-TLS not permitted / wrong policy set.** ISE's policy set for this SSID/port range doesn't
  allow EAP-TLS or lacks an authorization result — Cisco-side policy fix per Cisco docs.
- **Device unknown to ISE as a NAD path.** The **WLC/switch isn't defined in ISE** as a network
  access device, or the **shared RADIUS secret** is wrong — Cisco-side fix.

---

## D. Supplicant issues

- **Windows keeps prompting for a password on the corporate SSID.** The supplicant isn't using
  EAP-TLS / the client cert. Confirm `Corp Wi-Fi – EAP-TLS` sets **EAP type = EAP-TLS** and points at
  `Cisco 802.1X – SCEP Cert`; confirm a matching cert exists in the store it looks in (machine vs
  user).
- **Machine vs user certificate mismatch.** If ISE expects a **machine** cert but the profile presents
  a **user** cert (or vice-versa), it rejects. Match the **certificate type** (Device/User) and the
  profile's **authentication mode** to ISE's policy.
- **Server-name validation failing.** If you enabled trusted **server-name** matching, a mismatch with
  ISE's real certificate name blocks auth — correct the server name(s) in the profile.
- **TPM / key provider errors.** If **Enroll to TPM if present** is set on a device without a working
  TPM, enrollment can fail — allow software KSP fallback or fix the TPM.

---

## E. Wired vs wireless differences (why one works and the other doesn't)

- **Wired needs Wired AutoConfig (dot3svc); Wi-Fi needs WLAN AutoConfig (wlansvc).** These are
  *different* services. Wi-Fi can authenticate while wired does nothing simply because **dot3svc is
  stopped** — start/enforce it via `Wired 802.1X – EAP-TLS`.
- **Different profiles, different fixes.** `Corp Wi-Fi – EAP-TLS` and `Wired 802.1X – EAP-TLS` are
  separate objects; a fix to one does not apply to the other. Validate and troubleshoot each
  independently.
- **The switch port vs the SSID.** Wired auth also depends on **802.1X being enabled on that specific
  switch port** with the right host mode; Wi-Fi depends on the **SSID** being 802.1X-enabled on the
  WLC. A device that authenticates on Wi-Fi but not wired often just hit a **non-802.1X or
  differently-configured switch port** — a Cisco-side check.
- **Order of authentication (machine vs user) can differ** between the wired and Wi-Fi profiles;
  align both with ISE's expected policy.

---

## F. Fast triage checklist

1. Run **`ISE8021X-Validation.ps1`** on the device → is the **cert** present? (gate 1)
2. Are **both** profiles **Succeeded** in Intune, and is **dot3svc** running? (gate 2)
3. In **ISE Live Logs** *(Cisco side)*, is it **Accept** or **Reject** — and what is the **reason**?
   (gate 3)
4. Reject reason points the fix: **untrusted cert** → trust chain (device CA in ISE / ISE root on
   device); **identity mismatch** → SAN/CN vs ISE cert-auth profile; **method not allowed** → ISE
   policy set; **unknown NAD** → WLC/switch RADIUS definition.
5. If only **one transport** fails, compare the Wi-Fi vs wired profile and the service (wlansvc vs
   dot3svc) and the network device (SSID vs switch port).


---


# Best Practices

Operating 802.1X EAP-TLS well is mostly about **the supplicant**, **certificate lifecycle**, and
choosing the right **failure behavior**. The practices below keep the deployment reliable and
reversible.

## Supplicant configuration

- **Prefer device (machine) certificates for unattended access.** A machine certificate authenticates
  the device before/without a logged-in user, which is essential for kiosks, headless devices, and
  boot-time network access. Reserve user certificates for scenarios that truly need per-user identity
  on the network.
- **Always enable server-certificate (server-name) validation.** Configure the Wi-Fi and wired
  profiles to validate ISE's server certificate **and** match ISE's server name(s). Without this the
  supplicant will trust *any* server presenting a cert from the trusted root — a rogue-RADIUS risk.
- **Deliver the supplicant config from Intune, never by hand.** Both `Corp Wi-Fi – EAP-TLS` and
  `Wired 802.1X – EAP-TLS` should be the single source of truth. Manual `netsh`/GUI edits drift and
  are impossible to audit at fleet scale.
- **Ensure Wired AutoConfig (dot3svc) is running** on every wired-802.1X device — the wired profile
  should start/enforce it. A stopped dot3svc is the classic "wired profile applied but port never
  authenticates" cause.
- **Keep the certificate ↔ profile linkage intact.** The Wi-Fi/wired profiles must reference
  `Cisco 802.1X – SCEP Cert` (identity) and `Cisco 802.1X – Trusted Root` (server trust). If you
  rebuild a cert profile, re-point the network profiles at it.

## Certificate lifecycle & renewal

- **Set a sensible validity + renewal threshold.** Typical: 1-year device certificates with SCEP
  renewal starting at ~20% remaining lifetime, so devices re-enroll well before expiry. Verify
  renewal actually happens during the pilot — expired certs are the most common cause of a device
  silently dropping off the network.
- **Watch the Certificate Connector / Cloud PKI health.** Renewals fail silently if the connector is
  down or the SCEP endpoint is unreachable. Monitor connector status; alert on it.
- **Plan for CA rotation.** If ISE's issuing CA or your device CA is rotated, deploy the **new root**
  via a new/updated `Cisco 802.1X – Trusted Root` **before** the old chain is retired, and ensure ISE
  trusts the new device CA — otherwise a rotation locks the fleet off the network.
- **Protect keys with the TPM.** Prefer **Enroll to TPM if present** so the private key is
  non-exportable and bound to the device.

## Fail-open vs fail-closed (choose deliberately)

This is a network-infrastructure decision (configured on the **switch/WLC**, Cisco-side) but you must
choose it consciously:

- **Fail-closed (default-deny):** an unauthenticated device gets **no access**. Most secure; also the
  most disruptive if certificates or ISE break. Appropriate for high-security segments once the
  deployment is proven.
- **Fail-open / low-impact modes:** during rollout, network teams often run 802.1X in **monitor
  mode** (a.k.a. open/low-impact) or with a **MAB (MAC Authentication Bypass) fallback** and/or a
  **critical-VLAN** so that an ISE outage or a cert problem doesn't strand devices. Use this during
  **Pilot and early Expand**, then tighten toward fail-closed once confidence is high.
- **Always have a rollback.** Keep the ability to remove the Intune profile assignment *and* a
  network-side fallback (fail-open/MAB/critical-VLAN) so a bad change never becomes an outage. This
  satisfies the category rollback requirement (`global-requirements-network.md`, G7).

> **Vendor boundary:** the exact monitor-mode/MAB/critical-VLAN configuration lives on the Cisco
> switch/WLC and in ISE — configure it per **Cisco documentation**.

## Rollout discipline

- **Pilot first, expand in waves.** Assign to `PILOT – 802.1X Devices`, prove all three gates on
  Wi-Fi and wired, then widen to the production group in batches — never the whole fleet at once.
- **Test both transports and multiple OS types.** Wi-Fi and wired behave differently (different
  supplicant, dot3svc for wired); validate each.
- **Keep names consistent.** Reuse the exact object names so reports, remediation, and troubleshooting
  line up across tools and teammates.

## Operations & monitoring

- **Run the coverage report regularly.** `ISE8021X-Report.ps1` surfaces devices missing a cert or a
  profile before users notice. Feed gaps into `ISE8021X-Remediation.ps1` (default `-WhatIf`).
- **Watch ISE Live Logs after every wave and every ISE/CA change** (Cisco-side) — a spike in rejects
  is the earliest warning of a trust-chain or policy regression.
- **Document the trust chain.** Record which CA issues device certs, which CA signs ISE's server
  cert, and the SAN/CN format ISE reads — so a future admin can reason about a reject in minutes.


---


# Deliverables Summary

Everything included in this solution, and where to use it.

## Documentation

| Document | Purpose |
| --- | --- |
| **Executive Summary** | One-page business framing: the risk, the outcome, the approach. |
| **01 – Solution Overview** | How 802.1X / EAP-TLS works for Wi-Fi and wired with Cisco ISE as RADIUS authority; the certificate + network-profile model; where Intune delivery meets Cisco switching/wireless. |
| **02 – Requirements** | Every 802.1X-specific prerequisite with **Description / Why / Verify / Implement-if-missing** (CA/Cloud PKI, Certificate Connector, trusted root, SCEP/PKCS, Wi-Fi/wired settings, ISE RADIUS readiness, Entra groups, pilot). |
| **03 – Implementation** | Exact, ordered Intune steps: trusted root → SCEP cert → Wi-Fi 802.1X → wired 802.1X → assign to pilot → confirm ISE → validate → expand. |
| **05 – Testing & Validation** | The three pass/fail gates (cert present, profile applied, ISE auth success) and pilot exit criteria. |
| **06 – Troubleshooting** | The common failure modes: no cert, profile not applied, ISE rejects, supplicant issues, wired-vs-wireless differences. |
| **07 – Best Practices** | Supplicant, certificate renewal, and fail-open vs fail-closed guidance. |
| **Global Requirements (Network)** | Category-level prerequisites shared by all Network solutions. |

## Named objects created (reused verbatim across all docs and scripts)

| Object | Type | Role |
| --- | --- | --- |
| `Cisco 802.1X – Trusted Root` | Intune Trusted certificate profile | Installs the root that signed ISE's server certificate. |
| `Cisco 802.1X – SCEP Cert` | Intune SCEP (or PKCS) certificate profile | Issues the device client certificate (EAP-TLS identity). |
| `Corp Wi-Fi – EAP-TLS` | Intune Wi-Fi profile | WPA2/WPA3-Enterprise + EAP-TLS corporate SSID. |
| `Wired 802.1X – EAP-TLS` | Intune Wired network profile | Wired 802.1X EAP-TLS supplicant. |
| `PILOT – 802.1X Devices` | Entra security group | Pilot assignment target. |
| `Corp – 802.1X Devices` | Entra security group | Production assignment target (Expand phase). |

## PowerShell scripts

All scripts are **read-only** against Microsoft Graph except remediation/scope-targeting, which
**default to `-WhatIf`**. Cisco ISE and network-infrastructure internals are **deferred to vendor
documentation** — no script touches ISE, switches, or the WLC.

| Script | What it does |
| --- | --- |
| **ISE8021X-Discovery.ps1** | Tenant-wide 802.1X readiness: certificate connectors, and the trusted-root / SCEP / PKCS / Wi-Fi / wired 802.1X profiles present in Intune. |
| **ISE8021X-Validation.ps1** | On **this** device: confirms the client certificate and the Wi-Fi + wired 802.1X profiles are applied (the three gates, device side). |
| **ISE8021X-Report.ps1** | Fleet coverage: which devices have the certificate and the Wi-Fi/wired profiles, and where the gaps are. |
| **ISE8021X-Remediation.ps1** | Safely fixes missing profile/cert assignments (adds devices/groups to the right profiles). **Default `-WhatIf`.** |
| **ISE8021X-Set-ScopeTargeting.ps1** | Creates/populates the pilot Entra group(s) used as assignment targets. **Default `-WhatIf`.** |

## Deployment model

**Assess → Configure → Pilot → Validate → Expand**, gated by **cert present → profile applied → ISE
802.1X auth success**, with a documented rollback (remove assignment + network-side fallback) at every
step.
