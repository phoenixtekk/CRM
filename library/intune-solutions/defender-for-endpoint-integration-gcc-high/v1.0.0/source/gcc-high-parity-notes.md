# GCC High Parity Notes — Microsoft Defender for Endpoint (Government)

**What this is:** the cited Commercial-vs-US-Government reference for MDE, so you configure a GCC High
(or GCC / DoD) tenant correctly and know which capabilities to **verify in your own tenant** before
you depend on them. MDE for US Government is built in the Azure US Government environment and uses the
**same underlying prevention/detection/investigation/remediation technology** as Commercial — but it
**does not have complete parity**.

> **Primary source:** Microsoft Learn, *"Microsoft Defender for Endpoint for US Government
> customers"* (`learn.microsoft.com/en-us/defender-endpoint/gov`). Availability changes over time —
> **re-check the live page** and **verify each item in your tenant**. Where this file says
> *verify for GCC High/DoD*, treat the capability as unconfirmed until you see it in
> `security.microsoft.us`.

---

## 1. Portal URLs (which portal is *your* portal)

| Customer type | Defender portal URL |
| --- | --- |
| GCC | `https://security.microsoft.com` |
| **GCC High** | **`https://security.microsoft.us`** |
| DoD | `https://security.apps.mil` |

> GCC customers migrating from Commercial to GCC can reach legacy Commercial data at
> `https://transition.security.microsoft.com`. Cited: Microsoft — Portal URLs.

Companion sovereign admin portals: `login.microsoftonline.us` (sign-in), `entra.microsoft.us`,
`portal.azure.us`, `intune.microsoft.us`, `compliance.microsoft.us`, `portal.office365.us`.

## 2. API base URIs (for custom tooling)

| Endpoint type | GCC | GCC High & DoD |
| --- | --- | --- |
| Sign in | `https://login.microsoftonline.com` | `https://login.microsoftonline.us` |
| Defender for Endpoint API | `https://api-gcc.securitycenter.microsoft.us` | `https://api-gov.securitycenter.microsoft.us` |

Do **not** use the public `api.securitycenter.microsoft.com`. Cited: Microsoft — API.

## 3. Licensing (US Gov SKUs)

**Desktop licensing**

| GCC | GCC High | DoD |
| --- | --- | --- |
| Microsoft 365 GCC G5 | Microsoft 365 E5 for GCC High | Microsoft 365 G5 for DOD |
| Microsoft 365 G5 Security GCC | Microsoft 365 G5 Security for GCC High | Microsoft 365 G5 Security for DOD |
| Microsoft Defender for Endpoint - GCC | Microsoft Defender for Endpoint for GCC High | Microsoft Defender for Endpoint for DOD |
| Windows 10 Enterprise E5 GCC | Windows 10 Enterprise E5 for GCC High | Windows 10 Enterprise E5 for DOD |

**G3 includes Microsoft Defender for Endpoint Plan 1.**

**Server licensing**

| GCC | GCC High | DoD |
| --- | --- | --- |
| Microsoft Defender for Endpoint Server GCC | Microsoft Defender for Endpoint Server for GCC High | Microsoft Defender for Endpoint Server for DOD |
| Microsoft Defender for servers | Microsoft Defender for servers - Government | Microsoft Defender for servers - Government |

Cited: Microsoft — Licensing requirements.

## 4. Connectivity (US Gov endpoints devices must reach)

If a proxy/firewall allows only specific domains, add the Microsoft-published **Gov/GCC/DoD** URLs to
the allow-list. Two lists exist:

- **Streamlined Connectivity URL list for Gov/GCC/DoD** — a reduced URL set (or static IP ranges); a
  dedicated endpoint group supports streamlined connectivity in Government and consolidates several
  service dependencies into fewer URLs. *(Marked Preview on the source page — verify for GCC
  High/DoD.)*
- **Standard Connectivity URL list for Gov/GCC/DoD** — the full per-service DNS records.

**Downlevel/MMA:** choose **Azure US Government** as the Azure Cloud (or set
`OPINSIGHTS_WORKSPACE_AZURE_CLOUD_TYPE=1`). A required KB may need to be deployed **before**
onboarding so a downlevel device registers to the correct (Gov) environment. Cited: Microsoft —
Required connectivity settings; Endpoint versions.

## 5. Feature parity gaps (the part that changes your design)

MDE for US Government does not have complete parity with Commercial. **Known gaps** per Microsoft:

| Feature | GCC | GCC High | DoD |
| --- | --- | --- | --- |
| Microsoft Secure Score | Available* | Available | Available |
| **Microsoft Threat Experts** | **Not available** | **Not available** | **Not available** |
| MDE Security Configuration Management | Available | Available | Available |
| **Microsoft Defender for IoT (enterprise IoT security)** | **Not available** | **Not available** | **Not available** |

\* **Secure Score** is available for GCC/GCC High/DoD, but **some security recommendations are not
available**. Cited: Microsoft — Feature parity with commercial (note).

**Mobile Threat Defense (MDE on Android & iOS)** — these are available for GCC/GCC High/DoD per the
source page: Reports (Web content filtering; Device health); Web Protection (anti-phishing + custom
indicators); Malware Protection (Android-only); Jailbreak Detection (iOS-only); Conditional
Access/Conditional Launch; Support for MAM; Privacy Controls; Microsoft Defender Vulnerability
Management **core** capabilities (in Defender for Endpoint Plan 2) and **premium** capabilities.

**Defender Vulnerability Management — not available** for GCC/GCC High/DoD:
- **Report inaccuracy**
- **Request CVE support**

Cited: Microsoft — Feature parity with commercial (Mobile Threat Defense table + Defender
Vulnerability Management note).

## 6. Capabilities to verify in your tenant (do not assume from Commercial docs)

The greatest parity gaps have historically been in **analytics, reporting, and integration**
surfaces, and some features are preview/roadmap in Government. **Before you depend on any of these,
confirm in `security.microsoft.us` that it is present in your GCC High/DoD tenant — flag
"verify for GCC High/DoD" until confirmed:**

- **Automated Investigation & Response (AIR)** — commonly cited as lagging/limited in GCC High/DoD
  vs Commercial. *Verify for GCC High/DoD.*
- **Advanced hunting / third-party SIEM & connector integrations** — integration surfaces lag. *Verify.*
- **Managed threat hunting / Threat Experts** — listed **Not available** above; Microsoft has
  signaled a managed threat-hunting service *may* come to Government later, with **no committed
  date**. *Verify.*
- **Streamlined connectivity URL list** — marked **Preview** for Gov/GCC/DoD on the source page.
  *Verify.*
- **Newer analytics/reporting dashboards** — Government feature rollout trails Commercial; a
  dashboard present in Commercial may be absent or delayed in GCC High/DoD. *Verify.*

> **Rule:** for any capability not in the "Available" rows above and not personally confirmed in your
> tenant, treat it as **unconfirmed** and write a manual playbook rather than assuming the Commercial
> behavior. Never invent a GCC High specific.

---
*Primary source: Microsoft Learn, "Microsoft Defender for Endpoint for US Government customers"
(learn.microsoft.com/en-us/defender-endpoint/gov), page dated 2026 — Portal URLs, API, Licensing,
Endpoint versions, Required connectivity settings, Feature parity with commercial. Cross-reference:
"Integrate Microsoft Defender for Endpoint with Intune for Device Compliance." All GCC High / DoD
specifics must be re-verified against the live page and your tenant.*
