# GCC High Parity Notes – Incident – Sovereign

This is the cited reference of **Commercial-vs-GCC-High** differences that change how the incident runbook is executed. It is the artifact **GCC High Parity Notes – Incident – Sovereign** referenced from `01-solution-overview.md`, `02-requirements.md`, and `03-implementation.md`.

> **Standing caveat — parity is a moving target.** Every gap below is cited to Microsoft as of authoring (2026). Microsoft's stated goal is full parity, and items marked "on engineering backlog" close over time. **Re-verify each item for your own GCC High tenant before relying on it in a live incident.** Where this document says *verify for GCC High*, it means exactly that — check the current Microsoft doc or your tenant, do not assume.

---

## 1. Admin portal URLs (use the sovereign `*.us` consoles)

| Console | Commercial | **GCC High** | Source |
|---|---|---|---|
| Sign-in / authentication | `login.microsoftonline.com` | **`login.microsoftonline.us`** | [Graph national cloud deployments](https://learn.microsoft.com/en-us/graph/deployments) · [Defender XDR for US Gov](https://learn.microsoft.com/en-us/defender-xdr/usgov) |
| Microsoft 365 admin center | `admin.microsoft.com` | **`portal.office365.us`** | [MSPortals.io – Government](https://msportals.io/usgovt.html) |
| Microsoft Entra admin center | `entra.microsoft.com` | **`entra.microsoft.us`** | [MSPortals.io – Government](https://msportals.io/usgovt.html) |
| Exchange admin center | `admin.exchange.microsoft.com` | **`admin.exchange.office365.us`** | [MSPortals.io – Government](https://msportals.io/usgovt.html) |
| Microsoft Teams admin center | `admin.teams.microsoft.com` | **`admin.gov.teams.microsoft.us`** | [Teams – GCC High deployments](https://learn.microsoft.com/en-us/microsoftteams/plan-for-government-gcc-high) |
| Microsoft Intune admin center | `intune.microsoft.com` | **`intune.microsoft.us`** | [Intune Government service overview](https://learn.microsoft.com/en-us/intune/intune-service/fundamentals/intune-govt-service-description) |
| Microsoft Purview / compliance | `compliance.microsoft.com` | **`compliance.microsoft.us`** | [MSPortals.io – Government](https://msportals.io/usgovt.html) |
| Microsoft Defender portal | `security.microsoft.com` | **`security.microsoft.us`** | [Defender XDR for US Gov](https://learn.microsoft.com/en-us/defender-xdr/usgov) |
| Azure portal | `portal.azure.com` | **`portal.azure.us`** | [Graph national cloud deployments](https://learn.microsoft.com/en-us/graph/deployments) |

> The SharePoint admin center URL in GCC High is **tenant-specific**, of the form `https://<tenant>-admin.sharepoint.us` — *verify your exact tenant hostname*.

## 2. PowerShell / API endpoints

| Surface | Commercial | **GCC High** | Source |
|---|---|---|---|
| Microsoft Graph service root | `graph.microsoft.com` | **`graph.microsoft.us`** | [Graph national cloud deployments](https://learn.microsoft.com/en-us/graph/deployments) |
| `Connect-MgGraph` environment | *(default)* | **`-Environment USGov`** | [Graph national cloud deployments](https://learn.microsoft.com/en-us/graph/deployments) |
| Azure PowerShell (`Connect-AzAccount`) | *(default)* | **`-Environment AzureUSGovernment`** | [Graph national cloud deployments](https://learn.microsoft.com/en-us/graph/deployments) |
| Exchange Online (`Connect-ExchangeOnline`) | *(default)* | **`-ExchangeEnvironmentName O365USGovGCCHigh`** | Exchange Online PowerShell module (US Gov environment name) — *verify current module version* |
| Defender XDR API | `api.security.microsoft.com` | **`api-gov.security.microsoft.us`** | [Defender XDR for US Gov](https://learn.microsoft.com/en-us/defender-xdr/usgov) |
| Defender for Endpoint API | `api.securitycenter.microsoft.com` | **`api-gov.securitycenter.microsoft.us`** | [Defender for Endpoint for US Gov](https://learn.microsoft.com/en-us/defender-endpoint/gov) |

> **Why this matters in an incident:** without `-Environment USGov`, `Connect-MgGraph` authenticates against `login.microsoftonline.com` — the Commercial endpoint — and your GCC High credentials fail. This is the single most common "my script won't connect" error on a GCC High tenant. (Source: [Graph national cloud deployments](https://learn.microsoft.com/en-us/graph/deployments).)

## 3. Feature parity gaps that change the runbook

Microsoft states Defender for US Government "doesn't have complete parity with the commercial offering" (source: [Defender XDR for US Gov](https://learn.microsoft.com/en-us/defender-xdr/usgov)). The gaps that materially affect an incident responder:

| Capability | GCC High status | Runbook impact | Source |
|---|---|---|---|
| **Microsoft Threat Experts** ("Ask a Defender expert") | **Not available** ("on engineering backlog") | Remove it from the escalation path (A5, Phase 6); the escalation is a Microsoft **support case**, not a Threat Experts request. | [Defender XDR for US Gov](https://learn.microsoft.com/en-us/defender-xdr/usgov), [Defender for Endpoint for US Gov](https://learn.microsoft.com/en-us/defender-endpoint/gov) |
| **Automated investigation & response (AIR)** | Historically Commercial/GCC-first; **lags in GCC High — verify for GCC High** | Treat the manual A6 playbooks as primary; don't stall in Diagnose waiting for auto-investigation/auto-remediation. | [Defender for Endpoint for US Gov](https://learn.microsoft.com/en-us/defender-endpoint/gov) — *feature parity section; verify current status* |
| **Microsoft Defender for IoT — enterprise IoT security** | **Not available** | Exclude enterprise-IoT-device incidents from the Defender-driven workflow. | [Defender XDR for US Gov](https://learn.microsoft.com/en-us/defender-xdr/usgov), [Defender for Endpoint for US Gov](https://learn.microsoft.com/en-us/defender-endpoint/gov) |
| **Microsoft Secure Score** | Available, but **some recommendations are not** | A Permanent-Fix action you'd normally track as a Secure Score item may be missing — track the control directly (A7). | [Defender for Endpoint for US Gov](https://learn.microsoft.com/en-us/defender-endpoint/gov) |
| **Defender Vulnerability Management** — *Report inaccuracy* & *Request CVE support* | **Not available** for GCC/GCC High/DoD | You cannot file an MDVM report-inaccuracy / CVE-support request from the tenant; raise it via a support case instead. | [Defender for Endpoint for US Gov](https://learn.microsoft.com/en-us/defender-endpoint/gov) |
| **Advanced hunting (KQL) in the Defender portal** | GA features **available** in GCC High | Usable for diagnosis. Note the separate **GCC (Moderate)** limitation — cross-table queries spanning Sentinel **and** Defender XDR aren't supported there; that limit is documented for GCC Moderate, **not** GCC High. **Verify for your tenant.** | [Defender XDR connector data types in Sentinel for GCC](https://learn.microsoft.com/en-us/azure/sentinel/microsoft-365-defender-cloud-support) |
| **Microsoft Sentinel** | Runs in **Azure Government** for GCC High | Onboard/hunt via `security.microsoft.us` + `portal.azure.us`; **some connectors/preview features differ by cloud — verify connector availability for GCC High** before depending on a data source. | [Microsoft Sentinel feature availability](https://learn.microsoft.com/en-us/azure/sentinel/feature-availability) |
| **Entra ID Protection (risk detections)** | Delivered via the **G5 Gov / EMS E5 for GCC High** (P2) stack | Risk-based diagnosis depends on the P2 entitlement; **verify Identity Protection behavior for GCC High** and fall back to raw sign-in logs if risk data is absent (R4). | [Defender XDR for US Gov – licensing](https://learn.microsoft.com/en-us/defender-xdr/usgov) |

## 4. Compliance framing (why the client is in GCC High at all)

GCC High operates in physically isolated US datacenters and is designed to meet **FedRAMP High**, **DoD Impact Level 4 (IL4)**, and **DFARS / ITAR / CMMC** requirements. Two operational consequences for incident response:

- **Keep the whole response in-boundary.** Evidence (traces, logs, screenshots), the war-room channel (R10), and the PSA/system of record (R9) should stay within approved, in-scope services — do not export incident artifacts into a Commercial tool.
- **The audit trail is a compliance obligation, not a nicety.** The named Incident Record, timeline, RCA, and change log (R12) are part of the posture the tenant is certified against.

*(Compliance-scope statements above are the general rationale for GCC High; confirm the specific certifications and obligations in the client's own authorization documentation — do not represent a certification the engagement hasn't confirmed.)*

---

## Sources

- Microsoft Learn — **Microsoft Defender XDR for US Government customers**: <https://learn.microsoft.com/en-us/defender-xdr/usgov>
- Microsoft Learn — **Microsoft Defender for Endpoint for US Government customers**: <https://learn.microsoft.com/en-us/defender-endpoint/gov>
- Microsoft Learn — **Microsoft Graph national cloud deployments**: <https://learn.microsoft.com/en-us/graph/deployments>
- Microsoft Learn — **Microsoft Teams — GCC High deployments**: <https://learn.microsoft.com/en-us/microsoftteams/plan-for-government-gcc-high>
- Microsoft Learn — **Microsoft Intune Government service overview**: <https://learn.microsoft.com/en-us/intune/intune-service/fundamentals/intune-govt-service-description>
- Microsoft Learn — **Defender XDR connector data types in Microsoft Sentinel for GCC environments**: <https://learn.microsoft.com/en-us/azure/sentinel/microsoft-365-defender-cloud-support>
- Microsoft Learn — **Microsoft Sentinel feature availability**: <https://learn.microsoft.com/en-us/azure/sentinel/feature-availability>
- MSPortals.io — **Government (US Gov) portal directory**: <https://msportals.io/usgovt.html>
