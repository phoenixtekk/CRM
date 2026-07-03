# GCC High Parity Notes (Cited) — Egress Filtering for M365/Intune Endpoints

This reference records the **GCC High–specific facts** this solution relies on, each tied to Microsoft
US Government documentation. Where a fact could not be confirmed against Gov documentation, it is
flagged **"verify for GCC High."** Nothing here is invented; Microsoft's rotating IP ranges are
**derived at run time from the `USGovGCCHigh` instance**, never copied into this document.

> **Currency note:** Microsoft updates GCC High endpoint data monthly (additions published 30 days in
> advance). FQDNs below are stable, documented Gov service/portal names; the authoritative, current
> IP/URL/port set is always what the web service returns for `USGOVGCCHigh`. Re-verify against the
> cited pages before a major change.

---

## 1. The web service and its instances

- The Microsoft 365 IP Address and URL data is generated from a REST web service. Valid **instances**
  are **`Worldwide`**, **`China`**, **`USGovDoD`**, and **`USGovGCCHigh`**. The `Instance` parameter is
  **required** on the endpoints web method. `ClientRequestId=<guid>` is a **required** GUID you
  generate per calling machine (do not reuse Microsoft's example GUIDs). Source: *Microsoft 365 IP
  Address and URL web service*, Microsoft Learn —
  `https://learn.microsoft.com/en-us/microsoft-365/enterprise/microsoft-365-ip-web-service`.
- This solution uses **`USGovGCCHigh`** everywhere. Example live URLs (generate your own GUID):
  - Version: `https://endpoints.office.com/version/USGOVGCCHigh?clientrequestid=<guid>`
  - Endpoints (JSON): `https://endpoints.office.com/endpoints/USGOVGCCHigh?clientrequestid=<guid>`
  - Change-log RSS: `https://endpoints.office.com/version/USGOVGCCHigh?allversions=true&format=rss&clientrequestid=<guid>`
  Source: *Microsoft 365 U.S. Government GCC High endpoints*, Microsoft Learn —
  `https://learn.microsoft.com/en-us/microsoft-365/enterprise/microsoft-365-u-s-government-gcc-high-endpoints`.
- Endpoints data is updated monthly; **new IPs/URLs are published 30 days in advance** of being active.
  Source: same GCC High endpoints page.

## 2. GCC High admin portals (differ from Commercial)

| Portal | GCC High URL |
| --- | --- |
| Microsoft 365 | `https://portal.office365.us/` |
| Azure | `https://portal.azure.us/` |
| Microsoft Intune admin center | `https://intune.microsoft.us/` |
| Intune Company Portal | `https://portal.manage.microsoft.us/` |
| Microsoft Defender portal | `https://security.microsoft.us` |
| Compliance / Purview | `https://compliance.microsoft.us` / `https://purview.microsoft.us` |
| Sign-in (identity) | `https://login.microsoftonline.us` |

Sources: *Network endpoints for US government deployments* (Intune), Microsoft Learn —
`https://learn.microsoft.com/en-us/intune/intune-service/fundamentals/intune-us-government-endpoints`
(lists `portal.azure.us`, `portal.office365.us`, `portal.manage.microsoft.us`, `intune.microsoft.us`);
*Microsoft Defender for Endpoint for US Government customers*, Microsoft Learn —
`https://learn.microsoft.com/en-us/defender-endpoint/gov` (Defender portal `security.microsoft.us`,
API `api-gov.security.microsoft.us`, login `login.microsoftonline.us`); *Microsoft 365 U.S. Government
GCC High endpoints* (compliance/purview/security under `*.security.microsoft.us`).

## 3. Intune Gov service endpoints and no-inspect rule

- Intune client uses **HTTP (80)** and **HTTPS (443)**. Some tasks require **unauthenticated** proxy
  access to **`manage.microsoft.us`**.
- Communication endpoint wildcard: **`*.manage.microsoft.us`**. Enrollment:
  **`enterpriseregistration.microsoftonline.us`**.
- **SSL inspection is NOT supported on `*.manage.microsoft.us` or `has.spserv.microsoft.com`.**
- Partner/dependency endpoints: Evo STS `login.microsoftonline.us`; MS Graph `graph.microsoft.us`;
  Azure AD Graph `directory.microsoftazure.us` / `graph.microsoftazure.us`; ADRS
  `enterpriseregistration.microsoftonline.us`.
- Windows/Win32 & PowerShell script delivery CDN uses `*.manage.microsoft.com` (imeswdsc-afd-*)
  hostnames and `*.events.data.microsoft.com` diagnostics — **verify for GCC High** which apply to your
  tenant's scale unit.
Source: *Network endpoints for US government deployments* (Intune), Microsoft Learn (URL above).

## 4. Defender for Endpoint / EPM Gov device channel and no-inspect rule

- Defender for Endpoint and **Endpoint Privilege Management** use **`*.dm.microsoft.us`** for
  client↔cloud enrollment/check-in/reporting.
- **SSL inspection is NOT supported on the endpoints required for Defender for Endpoint or EPM**
  (`*.dm.microsoft.us`).
- Defender Gov portal `security.microsoft.us`; Gov API `api-gov.security.microsoft.us`. Standard vs
  streamlined connectivity URL sets exist for Gov — **verify for GCC High** which set applies to your
  OS versions.
Sources: *Network endpoints for US government deployments* (Intune) — Defender/EPM sections;
*Microsoft Defender for Endpoint standard/streamlined connectivity URLs - US government*, Microsoft
Learn — `https://learn.microsoft.com/en-us/defender-endpoint/standard-device-connectivity-urls-gov`
and `.../streamlined-device-connectivity-urls-gov`.

## 5. Core workload Gov FQDNs (from the USGovGCCHigh endpoint set)

Representative required Gov addresses (authoritative current list is what the web service returns):

- **Exchange Online:** `outlook.office365.us`; `*.protection.office365.us`, `*.manage.office365.us`,
  `*.scc.office365.us`; mail ports TCP 25/143/587/993/995.
- **SharePoint/OneDrive:** `*.sharepoint.us`, `admin.onedrive.us`.
- **Teams:** `*.gov.teams.microsoft.us`; media **UDP 3478–3481**. Media processors route only through
  **USGov Arizona / USGov Texas** datacenters.
- **Common/identity:** `login.microsoftonline.us`, `*.auth.microsoft.us`, `*.gov.us.microsoftonline.com`,
  `graph.microsoft.us`; Office Online `*.gov.online.office365.us`, `www.office365.us`,
  `*.osi.office365.us`.
- **Security/compliance:** `*.security.microsoft.us`, `security.microsoft.us`, `compliance.microsoft.us`,
  `purview.microsoft.us`.
- **Unified domains (must allow):** `*.usgovcloud.microsoft`, `*.usgovcloud-static.microsoft`,
  `*.usgovcloud-usercontent.microsoft` (TCP 443/80, UDP 443).
Source: *Microsoft 365 U.S. Government GCC High endpoints*, Microsoft Learn (URL above).

## 6. Graph PowerShell environment

- Microsoft Graph for US Gov (GCC High) is `graph.microsoft.us`. In PowerShell, connect with
  **`Connect-MgGraph -Environment USGov`** — the default targets Commercial Graph and fails on a GCC
  High tenant. Source: Microsoft Graph PowerShell national-cloud guidance;
  `graph.microsoft.us` per the Intune Gov endpoints page (URL above).

## 7. Commercial vs GCC High — parity gaps to watch

- **Different endpoint set entirely.** GCC (moderate) uses the **Worldwide** instance; only **GCC High**
  and **DoD** have their own instances. Do not apply GCC High values to a GCC/Commercial tenant or vice
  versa. Source: *Microsoft 365 U.S. Government GCC High endpoints* (links to the separate Worldwide,
  DoD, and 21Vianet endpoint pages).
- **ExpressRoute support varies per endpoint set** (the `expressRoute`/`ER` flag differs by row and by
  cloud). **Verify for GCC High** which of your workloads are on ER. Source: same page (ER column and
  Entra Connect special-considerations note).
- **Feature availability can lag or differ.** Some Commercial capabilities are limited or absent in GCC
  High. Treat any capability whose Gov behavior you have not confirmed as **"verify for GCC High"** and
  check current Gov documentation before relying on it.
- **PST Import / eDiscovery Export** in the Security & Compliance Center depend on Azure Blob Storage
  and don't support ExpressRoute with only M365 route filters — separate connectivity required. Source:
  *Microsoft 365 U.S. Government GCC High endpoints* (notes for the Common/Office Online table).

---

### Sources

- Microsoft 365 IP Address and URL web service — https://learn.microsoft.com/en-us/microsoft-365/enterprise/microsoft-365-ip-web-service
- Microsoft 365 U.S. Government GCC High endpoints — https://learn.microsoft.com/en-us/microsoft-365/enterprise/microsoft-365-u-s-government-gcc-high-endpoints
- Network endpoints for US government deployments (Intune) — https://learn.microsoft.com/en-us/intune/intune-service/fundamentals/intune-us-government-endpoints
- Microsoft Defender for Endpoint for US Government customers — https://learn.microsoft.com/en-us/defender-endpoint/gov
- Microsoft Defender for Endpoint standard connectivity URLs - US government — https://learn.microsoft.com/en-us/defender-endpoint/standard-device-connectivity-urls-gov
- Microsoft Defender for Endpoint streamlined connectivity URLs - US government — https://learn.microsoft.com/en-us/defender-endpoint/streamlined-device-connectivity-urls-gov
