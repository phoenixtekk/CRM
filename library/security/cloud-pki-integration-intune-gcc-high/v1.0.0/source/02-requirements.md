# Requirements — Cloud PKI Integration with Intune (Government / GCC High)

Confirm every prerequisite below **before** you configure anything. This edition assumes a **GCC
High** tenant throughout — the portals and endpoints are the US sovereign-cloud hosts, not the
Commercial ones. Category-level prerequisites (Entra tenant, admin roles, pilot group, network
access, change control) are in `global-requirements-security.md`; the items here are
**certificate- and GCC-High-specific.**

Each requirement is written as **Description · Why · Verify · Implement if missing.**

> **Before anything else — the Cloud PKI reality check (R0).** Because **Microsoft Cloud PKI is not
> available in GCC High (planned) and not planned for DoD**, this requirements list is built for the
> **supported** path: **SCEP/PKCS certificate profiles via the Intune Certificate Connector**,
> anchored to your own CA. If your plan assumed cloud-hosted Cloud PKI issuing CAs, **stop and
> re-scope** to the connector model here. (`gcc-high-parity-notes.md` §2.)

---

## R0. Confirm Cloud PKI is out of scope for now (parity acknowledgement)

**Description:** A recorded decision that this deployment uses **SCEP/PKCS + the Intune Certificate
Connector**, because **Cloud PKI is not yet available in GCC High** (and not planned for DoD).
**Why:** Building on Cloud PKI in GCC High wastes the whole project — the capability is not present.
**Verify:** In `gcc-high-parity-notes.md` §2, and against the live *Intune Government Service
overview*, confirm **Cloud PKI is still under "features planned"** for GCC High (i.e. not yet GA). If
it has since shipped to GCC High, you may add a Cloud PKI issuing CA — otherwise use the connector.
**Implement if missing:** Record the scope decision in the design (connector-based today; Cloud PKI
as a future migration once Microsoft ships it to GCC High).

## R1. A Microsoft 365 Government – GCC High tenant

**Description:** An active **Microsoft 365 Government – GCC High** tenant (US sovereign cloud), not a
Commercial or GCC (moderate) tenant. (For Intune, **GCC = Commercial**; only **GCC High/DoD** run in
the government datacenter.)
**Why:** GCC High uses different sovereign endpoints and a different Intune feature-parity profile.
Commercial steps and URLs will not work, and Cloud PKI you may plan for does not exist here.
**Verify:** Sign in at **`https://login.microsoftonline.us`** and open **`https://intune.microsoft.us`**.
The Intune admin center loads at the `.us` host and branding indicates a US Government (GCC High)
tenant.
**Implement if missing:** GCC High requires eligibility validation and onboarding through Microsoft /
an authorized Gov reseller — you cannot self-provision it like Commercial. This is a procurement
action, not a portal click.

## R2. Government Intune licensing (G3 / G5 with Intune Plan 1)

**Description:** Intune-bearing **Government** licensing — **Microsoft 365 Government G3/G5** (which
include **Intune Plan 1**) or standalone Intune Plan 1 for Gov.
**Why:** **SCEP/PKCS certificate profiles and the Certificate Connector are standard Intune Plan 1
functionality — no add-on required.** (Cloud PKI, when it reaches GCC High, would be an **Intune
Suite / standalone add-on** on top — but it is not in scope today.)
**Verify:** `portal.office365.us` → **Billing → Licenses**; confirm **Microsoft 365 G3/G5** or Intune
Plan 1 (Gov), assigned to the admin and pilot users.
**Implement if missing:** Acquire/assign the appropriate Gov SKU through your Gov licensing channel.
(See `gcc-high-parity-notes.md` §5.)

## R3. Intune administrative roles

**Description:** **Intune Administrator** (for certificate profiles and connectors), plus the ability
to create Entra groups. For least privilege, use the custom-role certificate permissions rather than
Global Administrator.
**Why:** Creating trusted-certificate, SCEP, and PKCS profiles and installing the connector requires
elevated Intune rights.
**Verify:** `entra.microsoft.us` → **Roles and administrators**; confirm **Intune Administrator** on
the operator.
**Implement if missing:** Assign **Intune Administrator**; reserve Global Administrator for
tenant-wide changes only.

## R4. An issuing Certification Authority (AD CS) reachable on-network

**Description:** An enterprise **Active Directory Certificate Services (AD CS)** CA (root +
issuing/intermediate) whose issuing CA can sign device/user certificates, reachable from the server
that will host NDES/the connector.
**Why:** In GCC High (no Cloud PKI), the leaf certificates are signed by **your** CA. SCEP with a
Microsoft CA requires AD CS; PKCS is issued from AD CS by the connector.
**Verify:** On the CA, `certutil -ping` / the **Certification Authority** console shows the issuing CA
online; the intended **certificate templates** exist (e.g. a Wi-Fi/VPN client-auth template) and the
NDES/connector service account can enroll them.
**Implement if missing:** Stand up / designate an AD CS issuing CA, create the client-auth
certificate template(s), and grant the service account **Enroll** rights. (If you use a **partner CA**
instead of AD CS, see R7 and **verify the partner supports GCC High**.)

## R5. NDES (for SCEP with a Microsoft CA)

**Description:** The **Network Device Enrollment Service (NDES)** role installed and published (for
SCEP against an AD CS CA), on a supported Windows Server, reachable by managed devices (typically via
a reverse proxy such as Azure AD Application Proxy alternative / Web Application Proxy in the Gov
environment).
**Why:** SCEP leaf issuance from a Microsoft CA is serviced by NDES; the Intune Certificate Connector
validates the SCEP request and NDES forwards it to the CA.
**Verify:** The NDES `mscep`/`mscep_admin` endpoints respond on the NDES server; the NDES service
account and IIS are healthy.
**Implement if missing:** Install the **AD CS → Network Device Enrollment Service** role, configure
the NDES service account and templates, and publish the SCEP URL to devices through your Gov reverse
proxy. (Skip NDES if you are doing **PKCS only**, or using a **third-party SCEP CA** that does not
require the connector.)

## R6. The Certificate Connector for Microsoft Intune (installed from the GCC High portal)

**Description:** The **Certificate Connector for Microsoft Intune** installed on a supported Windows
Server (SCEP and/or PKCS and revocation features), downloaded from **`intune.microsoft.us`**.
**Why:** The connector is the bridge between Intune (US Gov cloud) and your on-prem CA/NDES — it
processes SCEP validation, PKCS issuance, imported PFX, and revocation.
**Verify:** `intune.microsoft.us` → **Tenant administration → Connectors and tokens → Certificate
connectors**; the connector shows **Active/Healthy** (not Warning/Error). Connector **Event logs**
(Applications and Services → Microsoft → Intune → Certificate Connectors) show success events.
**Implement if missing:** From `intune.microsoft.us`, download the connector, install the required
features, assign the service account, and allow its outbound HTTPS to the **US Gov** endpoints plus
**`autoupdate.msappproxy.net:443`**. Keep it on a supported version (six-month support lifecycle).
Source: *Certificate Connector overview*.

## R7. (If using a partner CA) partner-CA support for GCC High

**Description:** If you issue via a **non-Microsoft CA** (e.g. DigiCert) through the connector,
confirmation that the **partner CA integration is supported in the GCC High government cloud**.
**Why:** Like MTD connectors, partner integrations are only usable where the vendor supports GCC
High. A Commercial-only partner integration will not function in the sovereign cloud.
**Verify:** Confirm with the partner and in `intune.microsoft.us` that the partner-CA connector is
available for your GCC High tenant. **Flagged: verify for GCC High.**
**Implement if missing:** Either select a partner that supports GCC High, or use **AD CS** (R4/R5).

## R8. Network / filtering allow-list for GCC High endpoints

**Description:** Outbound HTTPS to the **GCC High sovereign endpoints** for the Intune portal,
device management, and the connector — plus device reachability to the SCEP/NDES URL.
**Why:** Enrollment, profile sync, certificate issuance/validation, connector auto-update, and script
access all use the `.us` Gov hosts. If only the `.com` Commercial hosts are allowed, GCC High
certificate flows will not function.
**Verify:** From an admin workstation and from a managed device, reach
**`https://login.microsoftonline.us`**, **`https://intune.microsoft.us`**,
**`https://graph.microsoft.us`**, and (for auto-update) **`autoupdate.msappproxy.net:443`**; from a
device, reach your published **NDES/SCEP** URL.
**Implement if missing:** Allow Microsoft's published **Office 365 U.S. Government GCC High** URL/IP
ranges (the Gov endpoint list is separate from the Commercial "Worldwide" list), plus your NDES
reverse-proxy URL, through proxy/firewall.

## R9. Enrolled devices on a supported OS, and a pilot scope + change control

**Description:** Target devices **enrolled in Intune** on a supported OS (Windows/iOS/iPadOS/
macOS/Android), a named **pilot group**, and a **change-control/rollback** process (certificate,
Wi-Fi, and VPN changes can lock users out).
**Why:** Certificate profiles only reach enrolled devices; certificate/auth changes are high-impact
and must be piloted with a rollback. SCEP/PKCS profiles support the same platforms Intune supports in
GCC High.
**Verify:** `intune.microsoft.us` → **Devices → All devices** (targets present/compliant); a pilot
Entra security group named **`SG-CPKI-Pilot`** exists (`entra.microsoft.us` → Groups); a change
ticket template with approver, window, and rollback exists.
**Implement if missing:** Enroll devices; create **`SG-CPKI-Pilot`** in `entra.microsoft.us`; adopt
the change-control process from `global-requirements-security.md` (G8).

## R10. Parity confirmation for the certificate features you intend to use

**Description:** A completed check of the **GCC High parity table** for every capability this
deployment depends on — first and foremost **Cloud PKI availability**, then partner-CA support and
any derived-credential issuer.
**Why:** Cloud PKI is **not available** in GCC High; a partner CA may be Commercial-only; derived
credentials depend on issuer support. Designing around a missing feature wastes the pilot.
**Verify:** Work through `gcc-high-parity-notes.md`; for each capability confirm status against the
live Microsoft doc **and** that the option/connector is visible in `intune.microsoft.us`.
**Implement if missing:** Where a feature is *planned / not available*, use the GA alternative (SCEP/
PKCS via AD CS + connector), and record the substitution in the design.

---

**The deployment model (all solutions):** **Assess → Configure → Pilot → Validate → Expand.**
