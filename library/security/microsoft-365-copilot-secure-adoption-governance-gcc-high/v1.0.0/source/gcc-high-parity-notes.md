# GCC High Parity Notes — Microsoft 365 Copilot (cited reference)

This is the cited reference for **how Microsoft 365 Copilot on GCC High differs from Commercial**.
Every claim here is sourced to Microsoft documentation or Microsoft's public sector announcements.
Where Microsoft's own docs are ambiguous or a capability is on a moving roadmap, the note says
**verify for GCC High** — this solution never invents a GCC High behavior.

> **Snapshot date:** authored July 2026. GCC High availability moves; **re-verify against the cited
> sources for your own tenant** before relying on any single line.

---

## 1. Availability — Copilot IS in GCC High (GA December 2025)

Microsoft 365 Copilot **reached general availability in GCC High in December 2025**, following earlier
availability in GCC and DoD. Copilot operates **entirely within the customer's US government cloud
tenant** — prompts, responses, and generated content remain in the government cloud.

- Sources:
  [M365 Copilot is now available in GCC High (Microsoft public sector blog)](https://techcommunity.microsoft.com/blog/publicsectorblog/microsoft-365-copilot-is-now-available-in-gcc-high/4473310);
  [Understand Microsoft US government cloud environments for M365 and M365 Copilot (Microsoft Learn)](https://learn.microsoft.com/en-us/microsoft-365/copilot/gov-overview);
  [Microsoft makes Copilot available to secure cloud customers (Nextgov/FCW)](https://www.nextgov.com/acquisition/2025/12/microsoft-makes-copilot-available-secure-cloud-customers/409912/).

**Implication for this solution:** the governance work (oversharing remediation, labels, RSS) is a
live prerequisite, not preparation for a future launch.

---

## 2. Cloud environments — GCC vs GCC High vs DoD

| Environment | Isolation / target | Identity authority |
| --- | --- | --- |
| **GCC** | US data residency, FedRAMP Moderate-aligned; civilian/SLG/contractors | **Public** Microsoft Entra ID |
| **GCC High** | Elevated isolation for **CUI**; FedRAMP High, DFARS, ITAR/EAR, CMMC | **Microsoft Entra ID for Government** |
| **DoD** | Highest isolation; DoD SRG IL5 | Gov identity, DoD-restricted |

- Source: [Microsoft US government cloud overview (Microsoft Learn)](https://learn.microsoft.com/en-us/microsoft-365/copilot/gov-overview).

**Implication:** GCC High uses **Entra ID for Government** — scripts must use `-Environment USGov`;
public/Commercial Graph will not resolve the tenant.

---

## 3. Web grounding — OFF by default

To keep sensitive government data inside the compliance boundary, Microsoft delivers Copilot to GCC
High with **web grounding OFF by default**. With web grounding off, Copilot is subject to a
**knowledge cutoff** and responses may be dated (no live web lookups).

- Source: [M365 Copilot is now available in GCC High (Microsoft public sector blog)](https://techcommunity.microsoft.com/blog/publicsectorblog/microsoft-365-copilot-is-now-available-in-gcc-high/4473310).

**Implication:** design adoption around **tenant-grounded** answers; enable web grounding only if the
organization explicitly accepts the data-boundary tradeoff.

---

## 4. Licensing — base plan + Copilot add-on (US Government)

Microsoft 365 Copilot is available in **GCC, GCC High, and DoD** as an **add-on** to eligible base
plans, including **Microsoft 365 G3, G5, F1** and **Office 365 G1/G3/G5/F3** (plus eligible
Exchange/SharePoint/OneDrive/Project/Visio plans).

- Source: [License options for Microsoft 365 Copilot — US Government licenses (Microsoft Learn)](https://learn.microsoft.com/en-us/microsoft-365/copilot/microsoft-365-copilot-licensing).

**Plan-content caveat (verify for your contract):** **G5 (GCC High)** includes the Purview and
Defender suites Copilot leans on (sensitivity labeling, DLP, threat protection); **G3** typically
needs **Defender Suite GCCH** and **Purview Suite GCCH** add-ons to reach comparable coverage.
Confirm your SKU actually includes the Purview capabilities this solution configures.

---

## 5. Copilot Studio / agents — restricted in GCC High

Several Copilot Studio surfaces are **limited or unavailable** in GCC High. From Microsoft's US Gov
feature-limitations table:

| Feature / capability | GCC | GCC High |
| --- | --- | --- |
| Copilot Studio Microsoft Teams app experience | Yes | **No** |
| Teams channel in the Copilot Studio web app | Yes | **No** |
| Teams & M365 Copilot channel | Yes | **No** |
| Copilot agents that extend M365 | Yes | **No** |
| Prompt Action | Yes | **No** |
| Transfer to agents | Yes | **No** |
| Generative Answers (Enhanced Search) | No | **Yes** |
| Generative Orchestration | Yes | Yes |
| Triggers / Autonomous Agents | **No** | **No** |
| Azure AI Search as a knowledge source | **No** | **No** |
| Preview models for answer generation | No | No |

- Source: [US Government customers — Microsoft Copilot Studio, feature limitations (Microsoft Learn)](https://learn.microsoft.com/en-us/microsoft-copilot-studio/requirements-licensing-gcc).

**Implication:** design agent scenarios only around surfaces confirmed available in GCC High. Also
note Copilot Studio US Gov client apps are **web-user client** and historically **not in Teams**.

---

## 6. Teams meeting Copilot / Copilot in Teams

Copilot in **Word/Excel/PowerPoint/Outlook** and **Copilot Chat (work grounding)** are available in
GCC High. **Teams meeting Copilot** and **Copilot in Teams chat/channels** have been reported as
**limited or not yet available** in GCC High.

- Source: [Continuing our momentum: Expanding Microsoft 365 Copilot capabilities across U.S. Government clouds (Microsoft public sector blog)](https://techcommunity.microsoft.com/blog/publicsectorblog/continuing-our-momentum-expanding-microsoft-365-copilot-capabilities-across-u-s-/4506954);
  [M365 Copilot is now available in GCC High (Microsoft public sector blog)](https://techcommunity.microsoft.com/blog/publicsectorblog/microsoft-365-copilot-is-now-available-in-gcc-high/4473310).

**Verify for GCC High** before promising Teams-meeting Copilot to users.

---

## 7. Wave 2 roadmap — staged into H1 2026

Microsoft has stated **Wave 2** features ship to GCC High in the **first half of 2026**, including
**GPT-5**, **image generation**, **code interpreter**, and the **Researcher** (and **Analyst**)
agents; agent-creation capabilities (Agent Builder, Copilot Studio publishing) have been expanding in
US Gov clouds.

- Sources: [M365 Copilot is now available in GCC High (Microsoft public sector blog)](https://techcommunity.microsoft.com/blog/publicsectorblog/microsoft-365-copilot-is-now-available-in-gcc-high/4473310);
  [Continuing our momentum: Expanding M365 Copilot across US Government clouds (Microsoft public sector blog)](https://techcommunity.microsoft.com/blog/publicsectorblog/continuing-our-momentum-expanding-microsoft-365-copilot-capabilities-across-u-s-/4506954).

**Verify for GCC High:** confirm what has actually landed for your tenant before committing it in an
adoption plan.

---

## 8. Sovereign portals & endpoints

| Purpose | Commercial | GCC High |
| --- | --- | --- |
| Sign-in authority | `login.microsoftonline.com` | `login.microsoftonline.us` |
| M365 admin | `admin.microsoft.com` | `portal.office365.us` |
| Entra | `entra.microsoft.com` | `entra.microsoft.us` |
| Purview | `compliance.microsoft.com` | `compliance.microsoft.us` |
| Defender | `security.microsoft.com` | `security.microsoft.us` |
| Intune/Endpoint | `endpoint.microsoft.com` | `endpoint.microsoft.us` |
| Azure | `portal.azure.com` | `portal.azure.us` |
| Copilot Studio | `copilotstudio.microsoft.com` | `high.powerva.microsoft.us` |
| Power Platform admin | `admin.powerplatform.microsoft.com` | `high.admin.powerplatform.microsoft.us` |
| Microsoft Graph | `graph.microsoft.com` | `graph.microsoft.us` (`-Environment USGov`) |

- Sources: [Copilot Studio US Government service URLs (Microsoft Learn)](https://learn.microsoft.com/en-us/microsoft-copilot-studio/requirements-licensing-gcc);
  [Microsoft US government cloud overview (Microsoft Learn)](https://learn.microsoft.com/en-us/microsoft-365/copilot/gov-overview).

Network allow-list for GCC High includes `*.microsoft.us`, `*.azure.us`, `*.usgovcloudapi.net`,
`*.windows.net`, and the `AzureCloud.usgovvirginia` / `AzureCloud.usgovtexas` IP ranges.

---

## 9. Compliance framing

GCC High targets **FedRAMP High, DFARS, ITAR/EAR, and CMMC** for **CUI** workloads, with data in
US datacenters accessed only by screened US-person personnel. Customers remain responsible for
configuring M365 and Copilot to meet their specific obligations.

- Sources: [Microsoft US government cloud overview (Microsoft Learn)](https://learn.microsoft.com/en-us/microsoft-365/copilot/gov-overview);
  [US Government customers — Microsoft Copilot Studio (Microsoft Learn)](https://learn.microsoft.com/en-us/microsoft-copilot-studio/requirements-licensing-gcc).

---

## Sources

- [Microsoft 365 Copilot is now available in GCC High — Microsoft public sector blog](https://techcommunity.microsoft.com/blog/publicsectorblog/microsoft-365-copilot-is-now-available-in-gcc-high/4473310)
- [Understand Microsoft U.S. government cloud environments for Microsoft 365 and Microsoft 365 Copilot — Microsoft Learn](https://learn.microsoft.com/en-us/microsoft-365/copilot/gov-overview)
- [License Options for Microsoft 365 Copilot (US Government licenses) — Microsoft Learn](https://learn.microsoft.com/en-us/microsoft-365/copilot/microsoft-365-copilot-licensing)
- [US Government customers — Microsoft Copilot Studio — Microsoft Learn](https://learn.microsoft.com/en-us/microsoft-copilot-studio/requirements-licensing-gcc)
- [Continuing our momentum: Expanding Microsoft 365 Copilot capabilities across U.S. Government clouds — Microsoft public sector blog](https://techcommunity.microsoft.com/blog/publicsectorblog/continuing-our-momentum-expanding-microsoft-365-copilot-capabilities-across-u-s-/4506954)
- [Microsoft makes Copilot available to secure cloud customers — Nextgov/FCW](https://www.nextgov.com/acquisition/2025/12/microsoft-makes-copilot-available-secure-cloud-customers/409912/)
