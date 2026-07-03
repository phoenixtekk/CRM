# GCC High Parity Notes — Microsoft 365 Security Baseline & Audit Readiness

This reference backs every "different in GCC High" claim in the solution with a **citation** to
Microsoft documentation. Where Microsoft does not explicitly confirm a GCC High behavior, the item is
flagged **"verify for GCC High"** rather than asserted. Nothing here is invented.

> **Sources verified:** July 2026. Microsoft frequently closes GCC High parity gaps; re-check the cited
> pages before relying on a specific "not available" or "in development" status.

---

## 1. Sovereign admin portal URLs (Commercial → GCC High)

GCC High uses the **US Government (`*.us`)** endpoints, not the Commercial ones.

| Service | Commercial | GCC High |
| --- | --- | --- |
| Microsoft Entra admin center | `entra.microsoft.com` | `entra.microsoft.us` |
| Microsoft 365 admin center | `admin.microsoft.com` | `portal.office365.us` |
| Microsoft Defender portal (Secure Score) | `security.microsoft.com` | `security.microsoft.us` |
| Microsoft Purview / Compliance portal (Compliance Manager) | `compliance.microsoft.com` | `compliance.microsoft.us` |
| Intune / endpoint | `intune.microsoft.com` / `endpoint.microsoft.com` | `intune.microsoft.us` / `endpoint.microsoft.us` |
| Azure portal | `portal.azure.com` | `portal.azure.us` |
| Sign-in / token authority | `login.microsoftonline.com` | `login.microsoftonline.us` |

**Citations:**
- Microsoft Defender for Endpoint for US Government customers — **Portal URLs** table lists GCC High
  Defender portal as `https://security.microsoft.us`.
  <https://learn.microsoft.com/en-us/defender-endpoint/gov>
- Microsoft Graph national cloud deployments — **App registration and token service root endpoints**
  lists Azure US Government portal `https://portal.azure.us` and Entra endpoint
  `https://login.microsoftonline.us`.
  <https://learn.microsoft.com/en-us/graph/deployments>
- Plan for Microsoft Purview — GCC High deployments (Compliance Portal / Compliance Manager listed as
  **Available** for GCC High).
  <https://learn.microsoft.com/en-us/office365/servicedescriptions/microsoft-365-service-descriptions/microsoft-365-tenantlevel-services-licensing-guidance/plan-for-microsoft-purview-gcc-high-deployments>

> **Note (verify for GCC High):** `portal.office365.us`, `entra.microsoft.us`, `intune.microsoft.us`,
> `endpoint.microsoft.us`, and `compliance.microsoft.us` are the widely-documented GCC High portal
> hosts and are used consistently across Microsoft's Government portal reference material; the two
> URLs directly quoted from primary Microsoft Learn pages above are `security.microsoft.us`,
> `portal.azure.us`, and `login.microsoftonline.us`. Confirm each host resolves in your own tenant.

---

## 2. Microsoft Graph endpoints & PowerShell environment

| National cloud | Microsoft Graph service root | `Connect-MgGraph` |
| --- | --- | --- |
| Commercial (global) | `https://graph.microsoft.com` | `Connect-MgGraph` (default) |
| **GCC High (US Gov L4)** | `https://graph.microsoft.us` | `Connect-MgGraph -Environment USGov` |
| DoD (US Gov L5) | `https://dod-graph.microsoft.us` | `Connect-MgGraph -Environment USGovDoD` |
| GCC Moderate | `https://graph.microsoft.com` (worldwide) | `Connect-MgGraph` (default) |

Key facts from the source:
- **GCC High** = *US Government L4* → Graph root **`https://graph.microsoft.us`**.
- **DoD** = *US Government L5* → Graph root **`https://dod-graph.microsoft.us`**.
- **GCC (Moderate)** continues to use the **worldwide** endpoints (`portal.azure.com`,
  `graph.microsoft.com`) — so a GCC Moderate tenant does **not** use this edition's `*.us` Graph root.
- **Graph Explorer is "Not supported"** for the US Government Graph endpoints.
- Access tokens for a national cloud are **not interchangeable** with the global service.

**Citation:** Microsoft Graph national cloud deployments — **Microsoft Graph and Graph Explorer service
root endpoints** table and the "US Government context" guidance.
<https://learn.microsoft.com/en-us/graph/deployments>

> **Note:** The `USGov` environment name for GCC High and the requirement to pass `-Environment USGov`
> are consistent with Microsoft's `Connect-MgGraph` / `Get-MgEnvironment` guidance for US Gov
> national clouds; confirm the exact environment name in your SDK version with `Get-MgEnvironment`.
> <https://learn.microsoft.com/en-us/powershell/module/microsoft.graph.authentication/connect-mggraph>

---

## 3. Microsoft Secure Score in GCC High

- Secure Score **is available** for **GCC, GCC High, and DoD**.
- **However, some security recommendations are not available** in these government clouds — i.e., the
  action list and achievable total differ from Commercial.

**Citation (direct quote):** Microsoft Defender for Endpoint for US Government customers — **Feature
parity with commercial** table marks **Microsoft Secure Score** as available for GCC/GCC High/DoD, with
the note: *"While Microsoft Secure Score is available for GCC, GCC High and DoD customers, there are
some security recommendations that aren't available."*
<https://learn.microsoft.com/en-us/defender-endpoint/gov>

**Related parity gaps that affect which improvement actions can complete:**
- **Microsoft Threat Experts — Not available** (GCC / GCC High / DoD).
- **Microsoft Defender for IoT (enterprise IoT security) — Not available** (GCC / GCC High / DoD).
- Defender Vulnerability Management: **Report inaccuracy** and **Request CVE support** are **not
  available** for GCC/GCC High/DoD.

**Citation:** same **Feature parity with commercial** table.
<https://learn.microsoft.com/en-us/defender-endpoint/gov>

**Defender for Endpoint API base URI (GCC High & DoD):** `https://api-gov.securitycenter.microsoft.us`
(vs. `https://api-gcc.securitycenter.microsoft.us` for GCC); sign-in authority
`https://login.microsoftonline.us`.
**Citation:** same page, **API** table.
<https://learn.microsoft.com/en-us/defender-endpoint/gov>

> **Verify for GCC High:** Microsoft does not publish an exhaustive list of *which* individual Secure
> Score recommendations are omitted in GCC High, and the set changes over time. Treat any Commercial
> recommendation that is absent from your GCC High Secure Score as expected parity, and record it as
> "N/A — GCC High" rather than a finding.

---

## 4. Microsoft Purview Compliance Manager in GCC High

- **Compliance Portal** and **Microsoft Purview Compliance Manager** are **Available** in GCC High.
- **Out-of-the-box assessments for non-Microsoft 365 assets** and **double byte character support** are
  **Available**.
- Some Compliance Manager capabilities are **not yet at parity** in GCC High:
  - **Alerts and notifications — In development.**
  - **Continuous compliance assessments — Rolling out.**
  - **Recommended engine for bulk assessment creation — In development.**

**Citation:** Plan for Microsoft Purview — GCC High deployments, **Compliance posture → Compliance
Management** rows.
<https://learn.microsoft.com/en-us/office365/servicedescriptions/microsoft-365-service-descriptions/microsoft-365-tenantlevel-services-licensing-guidance/plan-for-microsoft-purview-gcc-high-deployments>

**Included assessment templates / licensing:**
- The **Microsoft Data Protection Baseline** is included for all organizations.
- For **US Government GCC Moderate, GCC High, and DoD** customers, **CMMC Levels 1–5** assessment
  templates are **included with G5 (Gov)** licensing, in addition to the Data Protection Baseline.
- Compliance Manager also offers premium templates such as **FedRAMP High/Moderate, DFARS, NIST SP
  800-171, CJIS**.

**Citations:**
- Microsoft Purview Compliance Manager regulations list.
  <https://learn.microsoft.com/en-us/purview/compliance-manager-regulations-list>
- Get started with Microsoft Purview Compliance Manager (Data Protection Baseline included; CMMC
  included for GCC/GCC High/DoD with G5).
  <https://learn.microsoft.com/en-us/purview/compliance-manager-setup>

**GCC High / DoD permission handling:**
- In **GCC High and DoD**, Compliance Manager **user permissions and roles can only be set in Microsoft
  Entra ID** (not via the portal's own role UI as in Commercial).

**Citation:** Get started with Microsoft Purview Compliance Manager.
<https://learn.microsoft.com/en-us/purview/compliance-manager-setup>

---

## 5. FedRAMP / DoD authorization context (why this edition exists)

- Microsoft 365 Government (GCC High) is built in the Azure US Government environment, is designed to
  **DoD Security Requirements Guide (SRG) Impact Level 4/5** controls, has completed **FedRAMP High**
  audits, and services **Agency ATOs**.

**Citations:**
- FedRAMP — Microsoft Compliance.
  <https://learn.microsoft.com/en-us/compliance/regulatory/offering-fedramp>
- Support for FedRAMP in Microsoft 365 Government (GCC High).
  <https://techcommunity.microsoft.com/blog/publicsectorblog/support-for-fedramp-in-microsoft-365-government-gcc-high/4112262>
- Understanding Compliance Between Commercial, Government, DoD & Secret Offerings.
  <https://techcommunity.microsoft.com/blog/publicsectorblog/understanding-compliance-between-commercial-government-dod--secret-offerings---m/4225436>

---

## 6. Summary: what to do differently in GCC High

1. Use the **`*.us` portals** for every task (Section 1).
2. Connect Graph with **`-Environment USGov`** → `graph.microsoft.us` (Section 2).
3. Expect a **reduced Secure Score recommendation set**; don't chase absent actions (Section 3).
4. Use **included templates** (Data Protection Baseline; **CMMC L1–5 with G5 Gov**), set **Compliance
   Manager roles in Entra**, and expect a few CM features to still be **in development / rolling out**
   (Section 4).
5. Do **not** stage improvement actions that depend on **Threat Experts** or **enterprise IoT** — they
   are absent in GCC High (Section 3).
