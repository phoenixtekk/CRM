# GCC High Parity Notes — Device Compliance Policies (cited reference)

This reference collects the **Commercial-vs-GCC-High** differences that affect device
compliance, each tied to a Microsoft source. Where Microsoft's documentation is silent or
self-contradictory, the item is explicitly flagged **"verify for GCC High"** — nothing here is
invented. Re-check these before every deployment; feature availability in the sovereign cloud
changes over time.

## Sources

- **[MS-GOV-SVC]** Microsoft Learn — *Microsoft Intune Government Service overview* (GCC High
  and DoD feature differences; supported / planned / not-available tables).
  `https://learn.microsoft.com/en-us/intune/fundamentals/government-service`
- **[MS-GOV-EP]** Microsoft Learn — *Network endpoints for US government deployments*
  (sovereign portal URLs, `*.manage.microsoft.us`, Graph, sign-in, SSL-inspection notes).
  `https://learn.microsoft.com/en-us/intune/intune-service/fundamentals/intune-us-government-endpoints`
- **[MS-WIN-COMPL]** Microsoft Learn — *Windows compliance settings in Microsoft Intune*
  (Device Health / DHA settings; encryption; Defender risk score).
  `https://learn.microsoft.com/en-us/intune/device-security/compliance/ref-windows-settings`
- **[MS-GRAPH-ENV]** Microsoft Learn — *Connect-MgGraph* / Microsoft Graph PowerShell
  authentication (national-cloud `-Environment` values).
  `https://learn.microsoft.com/en-us/powershell/module/microsoft.graph.authentication/connect-mggraph`
- **[MS-MTD-COMPL]** Microsoft Learn — *Create Mobile Threat Defense compliance policies in
  Intune* (device-threat-level compliance setting).
  `https://learn.microsoft.com/en-us/intune/device-security/mobile-threat-defense/create-compliance-policy`

---

## 1. Portals and endpoints (confirmed)

| Purpose | Commercial | GCC High / DoD | Source |
| --- | --- | --- | --- |
| Intune admin center | `intune.microsoft.com` | **`https://intune.microsoft.us/`** | [MS-GOV-EP] |
| Azure portal | `portal.azure.com` | **`https://portal.azure.us/`** | [MS-GOV-EP] |
| Microsoft 365 admin | `admin.microsoft.com` | **`https://portal.office365.us/`** | [MS-GOV-EP] |
| Company Portal service | `portal.manage.microsoft.com` | **`https://portal.manage.microsoft.us/`** | [MS-GOV-EP] |
| Client ↔ service | `*.manage.microsoft.com` | **`*.manage.microsoft.us`** | [MS-GOV-EP] |
| Sign-in (Evo STS) | `login.microsoftonline.com` | **`https://login.microsoftonline.us`** | [MS-GOV-EP] |
| Microsoft Graph | `graph.microsoft.com` | **`https://graph.microsoft.us`** (DoD: `dod-graph.microsoft.us`) | [MS-GOV-EP], [MS-GRAPH-ENV] |
| Device registration (ADRS) | `enterpriseregistration.windows.net` | **`https://enterpriseregistration.microsoftonline.us`** | [MS-GOV-EP] |

> **Verify for GCC High — `endpoint.microsoft.us`.** This solution's source spec referenced
> `endpoint.microsoft.us` as the admin portal. Microsoft's **published US Government
> designated endpoints** name the Intune admin center as **`https://intune.microsoft.us/`**;
> `endpoint.microsoft.us` is **not** listed there. Use `intune.microsoft.us` and confirm it
> loads for your tenant. [MS-GOV-EP]

> **SSL inspection.** Microsoft states TLS inspection is **not supported** on
> `*.manage.microsoft.us` (nor on `has.spserv.microsoft.com`, nor the Defender/EPM
> `*.dm.microsoft.us` endpoints). Inspecting them breaks enrollment and compliance
> check-in. [MS-GOV-EP]

## 2. Microsoft Graph PowerShell environment (confirmed)

- GCC High: **`Connect-MgGraph -Environment USGov`** → `graph.microsoft.us`, sign-in
  `login.microsoftonline.us`.
- DoD: **`Connect-MgGraph -Environment USGovDoD`** → `dod-graph.microsoft.us`.
- The Commercial default (`Global` → `graph.microsoft.com`) returns no GCC High data. Set
  `$PSDefaultParameterValues['Connect-MgGraph:Environment'] = 'USGov'` to prevent mistakes.
  [MS-GRAPH-ENV]

## 3. Device Health Attestation (DHA) — the key contradiction ⚠️ VERIFY

DHA is the attestation service behind three Windows compliance settings: **Require BitLocker**,
**Require Secure Boot**, and **Require code integrity**. [MS-WIN-COMPL]

**Microsoft's docs disagree on GCC High availability:**

- **[MS-GOV-SVC]** lists **"Windows Device Health Attestation (DHA)"** in the
  *features planned for GCC High and DoD* table — i.e. **not yet available**.
- **[MS-WIN-COMPL]** states: *"Devices across Intune commercial, US Government GCC High, and
  DoD services running Windows 10 use the Device Health Attestation (DHA) service."* — i.e.
  **available**.

**Guidance:** treat these three settings as **unverified on GCC High** until proven on a pilot
device (see `05-testing.md`, Test 4). If they do not resolve to a real Compliant/Not-compliant
result, fall back to **Encryption of data storage on a device** (BitLocker check without DHA)
and **TPM** under System Security, which do **not** depend on attestation. [MS-WIN-COMPL]

> Boot-time note: DHA-measured settings only settle **after a reboot** — even when BitLocker is
> already fully encrypted, a device won't report compliant for *Require BitLocker* until it
> reboots. [MS-WIN-COMPL]

## 4. Mobile Threat Defense (MTD) as a compliance signal — partial ⚠️ VERIFY VENDOR

- The device-threat-level compliance setting (*"Require the device to be at or under the Device
  Threat Level"*) works on GCC High **only if your MTD vendor also supports GCC High.** When
  signed into a GCC High tenant, only the connectors available for that environment are shown.
  [MS-GOV-SVC], [MS-MTD-COMPL]
- Fewer MTD partners support GCC High than Commercial — confirm your vendor before designing a
  mobile threat-level rule; otherwise leave the setting **Not configured**.
- The mobile *Device Threat Level* setting supports **user groups only**, not device groups
  (Commercial behavior that also applies here). [MS-MTD-COMPL]

## 5. Microsoft Defender for Endpoint risk score — supported (confirmed)

- **MDE security settings management is supported in GCC, GCC High, and DoD.** The Windows
  compliance setting *"Require the device to be at or under the machine risk score"* can
  therefore be used on GCC High **when MDE is onboarded**; if MDE is not onboarded, leave it
  **Not configured**. [MS-GOV-SVC], [MS-WIN-COMPL]

## 6. Features NOT available in GCC High / DoD that touch enrollment or compliance workflow (confirmed)

Per [MS-GOV-SVC], these are **not available** (no planning listed) and should not be designed
into a GCC High compliance rollout:

- **Chrome Enterprise Connector** (ChromeOS device compliance/enrollment).
- **Windows Autopilot** (enroll via automatic enrollment / Entra join instead).
- **Microsoft Store for Business** (affects app delivery, not compliance rules directly).
- **On-premises Exchange Connector**, **ServiceNow connector**, **TeamViewer connector**.
- Several **Windows update reporting** features (feature-update reports, compatibility reports).

**Planned but not yet available** per [MS-GOV-SVC] (re-check for ETAs): Cloud PKI (GCC High
only), Remote Help, Windows Autopatch and Windows update management (feature/quality/expedite/
driver updates), BIOS/DFCI configuration, Security Copilot, and DHA (see §3).

## 7. Migration and tenancy (confirmed)

- There is **no in-place migration** between Commercial and the government cloud (either
  direction). Devices must **unenroll and re-enroll**. Plan compliance rollout as a fresh
  deployment on the GCC High tenant. [MS-GOV-SVC]

---

**Standing caution.** GCC High feature parity is a moving target — Microsoft periodically
promotes "planned" features to "available." Before each deployment, re-open [MS-GOV-SVC] and
[MS-GOV-EP] and confirm the items above still hold for your tenant. Never assume a Commercial
capability exists in GCC High without checking.
