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
