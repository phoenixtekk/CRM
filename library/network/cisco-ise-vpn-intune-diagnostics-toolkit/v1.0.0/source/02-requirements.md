# Requirements

Before you can diagnose the Cisco Secure Client + ISE + Intune stack, you need read access to each plane that holds evidence, and the vantage points where each layer's failure shows up. This section lists what to have ready. Each item follows **Description / Why / Verify / Implement if missing**.

Gather these *before* an incident where possible — assembling access mid-incident wastes the outage. Everything here is **read-only**; you never need write/remediation rights to run this toolkit.

> Naming convention used throughout this toolkit (reuse these names verbatim):
> - Entra application registration for compliance reads: **CISEDIAG-Compliance-Reader**
> - Pilot / test device security group in Entra: **CISEDIAG-Pilot-Devices**
> - The certificate the VPN uses for authentication: the **VPN client-authentication certificate**
> - The Intune profiles in scope: the **VPN configuration profile**, the **certificate configuration profile** (SCEP/PKCS), and the **trusted-root certificate profile**

---

## R1. Intune (Microsoft Intune admin center) read access

**Description:** Sign-in to the Microsoft Intune admin center (`https://intune.microsoft.com`) with at least a read-only role that can view devices, configuration profiles, and compliance policies.

**Why:** Layer 1 (certificate/profile) and the Intune half of Layer 4 (compliance) live here. You need to see whether the certificate, trusted-root, and VPN profiles are **assigned** and **applied (succeeded)** on the failing device, and whether the device is **compliant** and **enrolled**.

**Verify:** Browse to `https://intune.microsoft.com` → **Devices → All devices** and open the failing device; confirm you can read its **Configuration** (profile status) and **Compliance** tabs.

**Implement if missing:** In Entra (`https://entra.microsoft.com`) → **Roles & admins**, assign the operator the built-in **Intune Administrator** role, or for least privilege a custom role / the **Global Reader** role, which grants tenant-wide read without change rights. Prefer read-only.

---

## R2. Microsoft Graph read access (for the diagnostic scripts)

**Description:** The ability to run the toolkit's PowerShell scripts against Microsoft Graph with the read-only scopes `DeviceManagementManagedDevices.Read.All`, `DeviceManagementConfiguration.Read.All`, and `Directory.Read.All`.

**Why:** The scripts (`CISEDIAG-Check-Compliance.ps1`, `CISEDIAG-Collect.ps1`) read the same managed-device and profile state ISE would evaluate — compliance, enrollment, ownership, and profile-assignment — so you can compare "what Intune says" against "what the device shows" without clicking through the portal per device.

**Verify:** Run `Connect-MgGraph -Scopes "DeviceManagementManagedDevices.Read.All","DeviceManagementConfiguration.Read.All","Directory.Read.All"` (interactive) and confirm consent succeeds; `Get-MgContext` shows the scopes granted.

**Implement if missing:** Install the Microsoft Graph PowerShell SDK (`Install-Module Microsoft.Graph -Scope CurrentUser`). Consent to the delegated scopes above at first connect, or use the app-only path in R4. All three scopes are **read** scopes — no write consent is required or requested.

---

## R3. Access to the failing device (or its logs)

**Description:** Local (or remote-management) access to the enrolled Windows device that fails to connect — enough to run the device-side scripts and read its certificate store and Secure Client state.

**Why:** Layers 1 and 2 have a device-side truth that the cloud cannot see: whether the **VPN client-authentication certificate** is actually present with a private key and a valid chain, and whether Cisco Secure Client actually has the **VPN configuration profile** it needs. The scripts `CISEDIAG-Validate-Certificate.ps1` and `CISEDIAG-Check-VpnClient.ps1` run **on this device**.

**Verify:** You can open a PowerShell session on the device and run `Get-ChildItem Cert:\CurrentUser\My` (and `Cert:\LocalMachine\My`) and see certificates listed.

**Implement if missing:** Arrange local admin (or standard-user) access, a remote session (RDP / remote PowerShell), or have the end user run the read-only collection script and return the bundle. No changes are made to the device.

---

## R4. An Entra application for compliance reads (app-only, optional but recommended)

**Description:** A dedicated Entra application registration — **CISEDIAG-Compliance-Reader** — with application (app-only) Microsoft Graph permissions `DeviceManagementManagedDevices.Read.All` and `Directory.Read.All`, used for unattended/repeatable compliance reads.

**Why:** For repeatable triage (scheduled collection, or reading compliance for a device you're not signed in on), an app-only identity is cleaner than interactive delegated sign-in and mirrors how ISE itself reads compliance through its own service connection. It keeps the diagnostic reads consistent and auditable.

**Verify:** Entra → **App registrations → CISEDIAG-Compliance-Reader → API permissions**; the two application permissions above show **Granted** (green check). Test: `Connect-MgGraph -ClientId your-app-id -TenantId your-tenant-id -CertificateThumbprint your-cert-thumbprint` connects and `Get-MgContext` reports `AuthType: AppOnly`.

**Implement if missing:** Entra → **App registrations → New registration**, name it **CISEDIAG-Compliance-Reader**. Under **API permissions → Add a permission → Microsoft Graph → Application permissions**, add `DeviceManagementManagedDevices.Read.All` and `Directory.Read.All`, then **Grant admin consent**. Add a **certificate** (preferred) or client secret under **Certificates & secrets**. Record the application (client) ID, tenant ID, and certificate thumbprint for the scripts — never hard-code a secret into a script; pass it at runtime or store it in a secret vault.

---

## R5. Cisco Secure Client vantage point (device side, evidence-only)

**Description:** The ability to view Cisco Secure Client's connection status on the failing device and to collect its **DART** (Diagnostic and Reporting Tool) log bundle.

**Why:** Layer 2 (client connect) failures — profile not loaded, gateway unreachable, transport blocked, certificate-selection failure — surface in the Secure Client UI and DART logs. This is where you confirm the client even *tried* the right head-end with the right certificate.

**Verify:** The Secure Client shows a connection status/message on the failing device, and you can locate its diagnostic/DART tool to produce a log bundle.

**Implement if missing:** Ensure Cisco Secure Client with the DART module is installed on the device. **Exact DART collection steps and log locations are deferred to Cisco's official documentation** and your Secure Client version — this toolkit tells you *what* the log should show; Cisco tells you *how* to collect it.

---

## R6. Cisco ISE live-log vantage point (network side, evidence-only)

**Description:** Read access to the Cisco ISE authentication **live logs** and the detailed authentication report for a connection attempt, held by whoever administers ISE.

**Why:** Layers 3 (EAP-TLS) and 4 (posture/authorization) are only fully visible from ISE. The ISE authentication detail report tells you whether the attempt **reached** ISE, whether **EAP-TLS** passed or failed (and why — chain, revocation, identity mapping), and which **authorization rule** matched (permit vs. quarantine vs. deny). Without this, L3/L4 diagnosis is guesswork.

**Verify:** You (or the ISE administrator on the call) can open the ISE live logs and pull the **detailed authentication report** for a specific failing attempt, matched by username/MAC/timestamp.

**Implement if missing:** Arrange ISE read access, or an agreed hand-off where the ISE administrator pulls the detail report for a timestamp you provide. **Exact ISE console navigation, live-log fields, and posture policy are deferred to Cisco's official documentation** — this toolkit names the field to read (e.g. the EAP-TLS failure reason, the matched authorization rule); Cisco docs cover where it lives in your ISE version.

---

## R7. A known-good reference (baseline)

**Description:** At least one device on which the VPN + ISE posture flow **currently works**, and the expected names/values: the VPN gateway/head-end address, the issuing CA, the trusted-root subject, and the expected **VPN configuration profile** name.

**Why:** Diagnosis is comparison. A working reference device turns "is this certificate right?" into "does this certificate match the working one's issuer and template?" and turns "is the profile correct?" into a diff. It also proves the *service* is up, isolating the fault to the failing device.

**Verify:** Confirm one device connects and is authorized right now; record its certificate issuer/template, its VPN profile name, and the gateway it uses.

**Implement if missing:** Use a pilot device from the **CISEDIAG-Pilot-Devices** group as the known-good reference. If nothing currently works, the fault is likely a shared/service-level break (CA, ISE, connector) rather than a single device — note that and start the tree at the top layer.
