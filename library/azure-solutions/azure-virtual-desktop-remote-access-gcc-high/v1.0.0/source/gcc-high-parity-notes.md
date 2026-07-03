# GCC High / Azure Government Parity Notes — Azure Virtual Desktop (cited)

A reference for how AVD on **Azure Government / GCC High** differs from Commercial. Use it while designing and at build time. Where Microsoft's public docs confirm a value, it is cited; where a specific has **not** been confirmed for the sovereign cloud, it is flagged **"verify for Azure Government."** Nothing here is invented — unconfirmed items are marked, not guessed.

> **Cloud relationship (cited):** GCC High and DoD are built on Azure Government and use Microsoft Entra ID Gov; Office 365 GCC High and DoD are paired with Microsoft Entra ID in Azure Government. The `.onmicrosoft.us` domain and `login.microsoftonline.us` endpoint are used only for GCC High and DoD. Feature availability is **not simultaneous** — new services and capabilities typically release in Azure Commercial first, so design for parity arriving later, not immediately. Sources: [Cloud feature availability for commercial and US Government customers](https://learn.microsoft.com/en-us/azure/security/fundamentals/feature-availability), community guidance on Azure Gov vs GCC High.

---

## 1. Admin portals & sign-in (confirmed)

| Purpose | Commercial | Azure Government / GCC High |
| --- | --- | --- |
| Azure portal | `portal.azure.com` | **`portal.azure.us`** |
| Microsoft 365 admin | `admin.microsoft.com` | **`portal.office365.us`** |
| Entra admin | `entra.microsoft.com` | **`entra.microsoft.us`** |
| Sign-in / auth | `login.microsoftonline.com` | **`login.microsoftonline.us`** |

Source: Government portals reference (msportals.io US Gov), Microsoft feature-availability doc. These `.us` admin URLs are the sovereign-cloud equivalents.

## 2. AVD client feed & web client (confirmed)

| Purpose | Commercial | Azure Government |
| --- | --- | --- |
| Client **feed URL** (subscribe) | `https://rdweb.wvd.microsoft.com` | **`https://rdweb.wvd.azure.us`** |
| Feed **discovery** | `.../api/arm/feeddiscovery?aadtenant=<domain>` | **`https://rdweb.wvd.azure.us/api/arm/feeddiscovery?aadtenant=<yourdomain>`** |
| **Web client** | `https://client.wvd.microsoft.com/arm/webclient` | **`https://rdweb.wvd.azure.us/arm/webclient/index.html`** |
| `ms-avd:` URI **`env`** value | `avdarm` | **`usgov`** |

Sources: [Required FQDNs and endpoints — Azure for US Government tab](https://learn.microsoft.com/en-us/azure/virtual-desktop/safe-url-list?tabs=azure-for-us-government); [URI schemes (`env=usgov`)](https://learn.microsoft.com/en-us/azure/virtual-desktop/uri-scheme).

## 3. Session-host & client service endpoints (confirmed — US Gov tab)

Session hosts (outbound 443 unless noted):
`*.wvd.azure.us` · `*.service.windows.usgovcloud.microsoft` · `*.windows.usgovcloud.microsoft` · `*.windows.usgovcloud-static.microsoft` · `login.microsoftonline.us` · `*.prod.warm.ingest.monitor.core.usgovcloudapi.net` · `gcs.monitoring.core.usgovcloudapi.net` · `azkms.core.usgovcloudapi.net` (1688) · `mrsglobalstugviffx.blob.core.usgovcloudapi.net` · `wvdportalstorageblob.blob.core.usgovcloudapi.net` · `ctldl.windowsupdate.com` (80) · `ocsp.msocsp.com` (80).

Clients (outbound 443): `login.microsoftonline.us` · `*.wvd.azure.us` · `*.servicebus.usgovcloudapi.net` · plus shared `go.microsoft.com`, `aka.ms`, `learn.microsoft.com`, `privacy.microsoft.com`, `*.cdn.office.net`, `graph.microsoft.com`, `windows.cloud.microsoft`, `windows365.microsoft.com`, `ecs.office.com`.

Azure fabric IPs `169.254.169.254` and `168.63.129.16` apply in all clouds and **must not be proxied/redirected**.

Source: [Required FQDNs and endpoints — Azure for US Government tab](https://learn.microsoft.com/en-us/azure/virtual-desktop/safe-url-list?tabs=azure-for-us-government).

## 4. Availability of AVD in the sovereign cloud (confirmed)

AVD is available in sovereign clouds including **Azure for US Government**. Host-pool/workspace/application-group **metadata** is stored in a supported region; session-host **compute** can be in any Gov region. Source: [Prerequisites — Azure regions / sovereign clouds](https://learn.microsoft.com/en-us/azure/virtual-desktop/prerequisites).

## 5. Identity models (confirmed same set; caveats noted)

Supported identity scenarios are the same set as Commercial: **Entra-only** (hosts Entra-joined, cloud users), **Entra ID + AD DS** (hybrid), **Entra ID + Microsoft Entra Domain Services**. Users authenticate via Microsoft Entra ID (Gov). Hybrid requires UPN or SID match across AD DS and Entra ID; the **domain-join account must not have MFA**. Source: [Prerequisites — Identity](https://learn.microsoft.com/en-us/azure/virtual-desktop/prerequisites).

## 6. Intune management of session hosts (confirmed for Gov)

Managing AVD session hosts with **Microsoft Intune** is supported in **Azure Government**, including **US Government GCC, GCC High, and DoD** (Windows 10/11 Enterprise multi-session and single-session). Caveats (all clouds): hosts joined to **Microsoft Entra Domain Services** can't be managed by Intune; **Windows Server** hosts can't enroll in Intune; cross-regional enrollment isn't supported. Sources: [Using AVD single-session with Intune](https://learn.microsoft.com/en-us/intune/solutions/azure-virtual-desktop), [Using AVD multi-session with Intune](https://learn.microsoft.com/en-us/intune/intune-service/fundamentals/azure-virtual-desktop-multi-session), [Prerequisites — Session host management](https://learn.microsoft.com/en-us/azure/virtual-desktop/prerequisites).

## 7. Known / likely parity gaps — verify before relying

- **External identities for AVD:** available in Azure public cloud **and Azure for US Government** on Windows App for Windows; **in preview** on Windows App for macOS and Android; invitations from Azure Government are noted as not supported in the preview flow. This is an actively-changing area — **verify for Azure Government** at build time. Source: search of Microsoft/AVD external-identity announcements ([authentication](https://learn.microsoft.com/en-us/azure/virtual-desktop/authentication)).
- **SSO / passwordless (Entra Kerberos, Windows Hello for Business, FIDO2):** supported for AVD generally; **verify for Azure Government** that the specific method and any Azure Files Entra-Kerberos / cloud-only path you intend is GA in your Gov tenant before committing a design. Source: [Configure single sign-on](https://learn.microsoft.com/en-us/azure/virtual-desktop/configure-single-sign-on), [authentication](https://learn.microsoft.com/en-us/azure/virtual-desktop/authentication).
- **Newest AVD features generally:** "What's new" announcements are Commercial-first; treat any recently-announced capability as **verify for Azure Government** until the Gov availability is confirmed. Source: [What's new in Azure Virtual Desktop](https://learn.microsoft.com/en-us/azure/virtual-desktop/whats-new).
- **Licensing SKUs:** AVD-eligible SKUs are documented generally (M365 E3/E5/A3/A5/F3/Business Premium; Windows Enterprise E3/E5; Windows Education A3/A5; Windows VDA; RDS CAL/SL for Server). The **Government tenant uses the G-series equivalents** (e.g., M365 G3/G5) — **verify for Azure Government** that your exact SKU is offered in your Gov agreement. Source: [Prerequisites — Operating systems and licenses](https://learn.microsoft.com/en-us/azure/virtual-desktop/prerequisites).

## 8. Region list (confirmed behavior)

The AVD metadata region list in the prerequisites doc enumerates **Commercial** regions; **Azure Government regions are separate** and selected in the Gov portal. **Verify for Azure Government** which Gov regions currently offer AVD metadata storage and your intended VM SKUs. Source: [Prerequisites — Azure regions](https://learn.microsoft.com/en-us/azure/virtual-desktop/prerequisites).

---

### How to use this file
Whenever a design or step depends on a specific portal, endpoint, or feature, check it here first. Confirmed items you can rely on; **"verify for Azure Government"** items you must re-confirm in Microsoft's current Gov documentation before you build on them. Do not substitute a Commercial value for a Gov one.
