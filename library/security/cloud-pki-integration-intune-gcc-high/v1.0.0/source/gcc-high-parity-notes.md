# GCC High Parity Notes — Cloud PKI Integration with Intune (Certificate Management)

This is the working reference for the **Commercial-vs-GCC High differences** that shape this
solution. The Government (GCC High) edition of certificate management is **not** the Commercial
portal with a different sign-in: the admin URLs are different sovereign-cloud endpoints, and — most
importantly for this topic — **Microsoft Cloud PKI itself is not yet available in GCC High** (it is
*planned*), and is **not planned for DoD**. Everything below is either **doc-confirmed** with a
Microsoft citation or explicitly **flagged "verify for GCC High"**.

> **THE HEADLINE PARITY GAP (read first):** In Microsoft's *Intune Government Service overview*,
> **Cloud PKI is listed under "Intune features planned for GCC High and DoD"** — i.e. it is
> **currently not available and not supported** in GCC High and DoD — and the row is annotated
> **"(GCC High only)"**, meaning the *plan* to support it covers GCC High but **not DoD**. So:
> **Cloud PKI is NOT GA in GCC High today (planned), and is NOT on the roadmap for DoD.** Design
> certificate management in GCC High around **SCEP/PKCS with the Intune Certificate Connector**
> (which **is** available and supported in government), and treat Cloud PKI as a *future migration*
> once Microsoft ships it to GCC High.
> Source: Microsoft Learn — *Microsoft Intune Government Service overview*, table
> "Intune features planned for GCC High and DoD," row **Cloud PKI (GCC High only)**.
> `https://learn.microsoft.com/en-us/intune/fundamentals/government-service` (doc dated 2026-06-04).

> **Status legend (Microsoft's own terms):** *Available/Supported* = usable in GCC High today ·
> *Planned* = "planning is started" but **not yet available** · *Not available (no plan)* = absent
> and no announced plan. Microsoft states this status "is subject to change" — **re-verify against
> the live doc before you rely on any single row.**

---

## 1. Portals & endpoints (sovereign-cloud URLs)

| Purpose | Commercial | GCC High |
| --- | --- | --- |
| Sign-in / authentication | `login.microsoftonline.com` | `login.microsoftonline.us` |
| Microsoft 365 admin center | `admin.microsoft.com` | `portal.office365.us` |
| Microsoft Intune admin center | `intune.microsoft.com` / `endpoint.microsoft.com` | `intune.microsoft.us` |
| Defender / security portal | `security.microsoft.com` | `security.microsoft.us` |
| Entra admin center | `entra.microsoft.com` | `entra.microsoft.us` |
| Azure portal | `portal.azure.com` | `portal.azure.us` |
| Microsoft Graph (scripts) | `graph.microsoft.com` (`-Environment Global`) | `graph.microsoft.us` (`-Environment USGov`) |

- **Doc-confirmed:** Intune GCC High/DoD is built on **Microsoft Azure Government Cloud** and is a
  physically separate datacenter from Commercial (known as **IL4/IL5**). The GCC High Intune admin
  center is **`intune.microsoft.us`**. Source: Microsoft Learn — *Microsoft Intune Government Service
  overview* (`https://learn.microsoft.com/en-us/intune/fundamentals/government-service`).
- **Doc-confirmed:** `portal.office365.us`, `security.microsoft.us`, `entra.microsoft.us`,
  `portal.azure.us` are the GCC High endpoints. Source: MSPortals.io US Government portal reference
  (`https://msportals.io/usgovt.html`).
- **Doc-confirmed:** `login.microsoftonline.us` is the GCC High Azure AD authentication endpoint (the
  US Gov identity cloud, `AzureUSGovernment`). Source: Microsoft "US Government national clouds"
  guidance — `https://learn.microsoft.com/en-us/entra/identity-platform/authentication-national-cloud`.
- **Note (Intune GCC vs GCC High):** Intune has **no separate GCC (moderate) instance** — GCC uses
  the **Commercial** Intune service. Only **GCC High** and **DoD** run in the government datacenter.
  So "GCC High/DoD" here means the sovereign government cloud; "GCC" for Intune = Commercial.
  Source: *Intune Government Service overview*.

**Graph / PowerShell endpoints (used by the scripts):**
- Microsoft Graph US Gov: `graph.microsoft.us` — connect with `Connect-MgGraph -Environment USGov`.
  (DoD tenants use `USGovDoD` / `dod-graph.microsoft.us`; GCC High = `USGov`.)

---

## 2. Cloud PKI — the central parity gap

| Capability | GCC High status | DoD status | Source |
| --- | --- | --- | --- |
| **Microsoft Cloud PKI (Intune Suite / standalone add-on)** | **Planned — NOT yet available** | **Not planned / not available** | *Intune Government Service overview*, "features planned" table, row "Cloud PKI (GCC High only)" |

- **Doc-confirmed:** Cloud PKI appears in the **"Intune features planned for GCC High and DoD"**
  table, whose preamble reads: *"The following features are currently not available and aren't
  supported in GCC High and DoD clouds. Planning is started to support these features…"* The row is
  annotated **"(GCC High only)"** — the plan targets **GCC High**, not DoD. **Therefore Cloud PKI is
  not usable in GCC High today, and is not slated for DoD at all.**
- **Corroborating (licensing/marketplace):** Third-party compliance/marketplace references list
  *Intune Suite for Cloud PKI* / *Cloud PKI* as **not currently available in GCC High** (available in
  the Commercial/GCC space). Microsoft public-sector messaging indicates Cloud PKI, EPM, and EAM are
  expected to reach **a Government cloud environment during 2026** — **treat any date as an ETA, not
  a commitment; verify for GCC High before planning a go-live around it.**
  Sources: Secureframe marketplace entries for *Intune Suite Cloud PKI* /
  *Microsoft Cloud PKI for Government (GCC)*; Microsoft Community Hub — *Advancing Microsoft 365
  Government: New Capabilities and Pricing Update*.
- **What Cloud PKI would be (for the future migration):** a cloud-hosted two-tier PKI (root +
  issuing CA) with a built-in **SCEP** certificate registration authority, CRL/AIA hosting, and
  HSM-backed keys — **no on-premises CA, NDES, or Intune Certificate Connector required**. It issues
  **leaf certificates via the SCEP profile** to Intune-enrolled Android/iOS/macOS/Windows devices.
  Source: Microsoft Learn — *Microsoft Cloud PKI for Microsoft Intune*
  (`https://learn.microsoft.com/en-us/intune/cloud-pki/`).
- **Design consequence:** Until Cloud PKI ships to GCC High, **do not** design on it. Use the
  **supported** government path in §3. When Cloud PKI reaches GCC High (GA — verify), the certificate
  *profiles* (SCEP/trusted-root) you build now largely carry forward; you would swap the issuing
  authority from your connector-backed CA to a Cloud PKI issuing CA.

---

## 3. Supported certificate path in GCC High — SCEP / PKCS via the Intune Certificate Connector

Because Cloud PKI is unavailable, the **supported** way to issue certificates to Intune-managed
devices in GCC High is the **on-premises-anchored** model: your **Active Directory Certificate
Services (AD CS)** CA + the **Certificate Connector for Microsoft Intune**, driving **SCEP** and/or
**PKCS** certificate profiles.

| Component | GCC High status | Notes / Source |
| --- | --- | --- |
| **SCEP certificate profiles** (Intune device configuration) | **Available** (Standard MDM feature) | *Intune Government Service overview* lists "Standard MDM features … device configuration profiles" as available in GCC High. SCEP profiles are standard device configuration. |
| **PKCS certificate profiles** | **Available** | Same "Standard MDM features" support. |
| **Imported PKCS (PFX) certificates** (e.g. S/MIME) | **Available** | Standard MDM feature; delivered by the connector. |
| **Trusted certificate profiles** (root/intermediate) | **Available** | Standard MDM feature. |
| **Certificate Connector for Microsoft Intune** | **Available** (on-prem connector; installed from `intune.microsoft.us`) | Each connector instance has the **same network requirements as a managed device**; in GCC High those are the **US Gov** endpoints. Source: Microsoft Learn — *Overview of Certificate Connector for Microsoft Intune* (`https://learn.microsoft.com/en-us/intune/intune-service/protect/certificate-connector-overview`). |
| **NDES (Network Device Enrollment Service)** for SCEP with a Microsoft CA | **Required for SCEP with AD CS** | To issue SCEP with an AD CS (Microsoft) CA you must configure NDES on the connector-adjacent server. Source: *Certificate Connector overview* — Capabilities. Third-party SCEP CAs do **not** require the connector. |
| **Third-party / partner CA connectors (e.g. DigiCert)** via the connector | **Available where the partner supports GCC High** | The connector supports partner-CA PKCS/revocation flows; **verify the specific partner supports the GCC High government cloud** before designing on it (compare to how MTD connectors are limited to vendors that support GCC High). |

- **Connector network requirement (GCC High):** the connector needs outbound HTTPS to the **US Gov**
  Intune/Graph/login endpoints (not the Commercial list) plus the auto-update endpoint
  **`autoupdate.msappproxy.net:443`**. Source: *Certificate Connector overview* (network + auto-update).
- **SCEP OID allow-list (all clouds):** starting connector v6.2510.3.2002, the SCEP validation
  service **blocks unknown certificate-extension OIDs**; only a fixed allow-list (Basic Constraints,
  Subject Key Identifier, CA Version, Certificate Template Name, etc.) is honored. Keep SCEP profiles
  to standard extensions. Source: *Certificate Connector overview* — "Allowed list of SCEP OIDs."
- **Verify for GCC High:** confirm your intended CA (AD CS on-prem, or a partner CA) and the
  connector version are supported for the government cloud, and that filtering allows the `.us`
  endpoints, before piloting.

---

## 4. Adjacent Intune certificate/security features — parity

| Feature | GCC High status | Source |
| --- | --- | --- |
| Standard MDM (config profiles, compliance, apps) | **Available** | *Intune Government Service overview* — "Standard MDM features." |
| Endpoint Privilege Management (EPM) | **Available** (advanced capability) | Same doc — advanced capabilities supported in GCC High/DoD. |
| Enterprise Application Management (EAM) | **Available** | Same doc. |
| Microsoft Tunnel for MAM | **Available** | Same doc. |
| Advanced Analytics | **Available** | Same doc. |
| Defender for Endpoint security settings management | **Available** (GCC, GCC High, DoD) | Same doc. |
| **Cloud PKI** | **Planned (GCC High only) — not available; not planned for DoD** | Same doc — "features planned." §2 above. |
| **Remote Help** | **Planned — not yet available** | Same doc — "features planned." |
| Windows Autopilot (classic) | **Not available (no plan)** | Same doc — "features not available." (Autopilot **device preparation** is partially available/planned.) |
| Windows Autopatch, feature/quality/driver/expedite updates | **Planned — not yet available** | Same doc — "features planned." |
| Derived credentials (e.g. for CAC/PIV-anchored device certs) | **Verify for GCC High** | Not enumerated in the government table pulled here; confirm derived-credential issuer support against Microsoft's derived-credentials docs for your issuer before designing on it. |

---

## 5. Licensing note (Government SKUs)

- **SCEP/PKCS certificate profiles and the Intune Certificate Connector** are **standard Intune
  functionality** — covered by **Intune Plan 1** (included in **Microsoft 365 Government G3/G5** /
  the Gov equivalents), no add-on required.
- **Cloud PKI** (when it reaches GCC High) requires an **add-on to Intune Plan 1/2** — via the
  **Microsoft Intune Suite** or the **standalone Cloud PKI** add-on. Source: Microsoft Learn —
  *Microsoft Cloud PKI for Microsoft Intune*, "Prerequisites → Licensing requirements." **Verify the
  exact Gov SKU that will carry Cloud PKI in GCC High when it ships.**
- **Verify for GCC High:** confirm the Gov SKU that carries each feature in the *Microsoft Intune
  plans* / service description and your tenant's license blade before designing.

---

## 6. How to keep this current

The parity status changes as Microsoft ships. **Before any design decision that depends on Cloud PKI
being present**, re-open the *Microsoft Intune Government Service overview* page and the Microsoft 365
Roadmap filtered to **GCC High**, and re-confirm the **Cloud PKI** row. Where this document says
"verify for GCC High", that is a required step, not a suggestion — never assume Commercial behavior
carries over.
