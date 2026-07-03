# GCC High Parity Notes — Continuous Compliance Monitoring & Audit-Evidence Automation

This is the working reference for the **Commercial-vs-GCC High differences** that shape this
solution. The Government (GCC High) edition of Intune + Entra compliance monitoring is **not** the
Commercial portal with a different sign-in: the admin URLs are different sovereign-cloud endpoints,
the scripts must target **US Gov Graph** (`-Environment USGov`), and several Intune capabilities you
might reach for in a Commercial monitoring/remediation runbook are **planned but not yet available**
or **not available at all** in GCC High and DoD. Everything below is either **doc-confirmed** with a
Microsoft citation or explicitly **flagged "verify for GCC High/DoD"**.

> **Primary source (authoritative parity list):** Microsoft Learn — *Microsoft Intune Government
> Service overview* (feature differences vs the commercial offering), doc dated **2026-06-04**.
> `https://learn.microsoft.com/en-us/intune/intune-service/fundamentals/intune-govt-service-description`
>
> **Endpoints source:** Microsoft Learn — *Network endpoints for US government deployments —
> Microsoft Intune*, doc dated **2025-12-15**.
> `https://learn.microsoft.com/en-us/intune/intune-service/fundamentals/intune-us-government-endpoints`
>
> Microsoft states these lists change as the service ships — **re-verify against the live docs before
> you rely on any single row.** Where a row says "verify for GCC High/DoD", that is a required check,
> not a suggestion.

---

## 1. Portals & endpoints (sovereign-cloud URLs)

| Purpose | Commercial | GCC High / DoD |
| --- | --- | --- |
| Sign-in / authentication | `login.microsoftonline.com` | `login.microsoftonline.us` |
| Microsoft 365 admin center | `admin.microsoft.com` | `portal.office365.us` |
| Microsoft Intune admin center | `intune.microsoft.com` | `intune.microsoft.us` |
| Intune Company Portal (web) | `portal.manage.microsoft.com` | `portal.manage.microsoft.us` |
| Entra admin center | `entra.microsoft.com` | `entra.microsoft.us` |
| Defender / security portal | `security.microsoft.com` | `security.microsoft.us` |
| Purview / compliance portal | `compliance.microsoft.com` | `compliance.microsoft.us` |
| Azure portal | `portal.azure.com` | `portal.azure.us` |

- **Doc-confirmed (US Government customer designated endpoints):** Azure portal `https://portal.azure.us/`,
  Microsoft 365 `https://portal.office365.us/`, Intune Company Portal `https://portal.manage.microsoft.us/`,
  and **Microsoft Intune admin center `https://intune.microsoft.us/`**. Source: *Network endpoints for
  US government deployments* (Microsoft Learn, 2025-12-15).
- **Doc-confirmed:** the sign-in / STS endpoint is `https://login.microsoftonline.us` ("Evo STS"),
  and **Microsoft Graph is `https://graph.microsoft.us`** in the US Gov cloud. Source: same endpoints
  doc, *Partner service endpoints that Intune depends on*.
- **Verify for GCC High/DoD:** `entra.microsoft.us`, `security.microsoft.us`, and
  `compliance.microsoft.us` are the US Gov admin hosts; confirm the exact host your tenant redirects
  to. If any portal loads at a `.com` host, you are in the **Commercial** cloud — stop.

**Graph / PowerShell endpoints used by the scripts:**
- **Microsoft Graph US Gov (GCC High):** `graph.microsoft.us` — connect with
  `Connect-MgGraph -Environment USGov`.
- **DoD (IL5):** `dod-graph.microsoft.us` — connect with `Connect-MgGraph -Environment USGovDoD`.
  Source: Microsoft Learn — *Access national cloud deployments with the Microsoft Graph SDKs*
  (`https://learn.microsoft.com/en-us/graph/sdks/national-clouds`) and *Connect-MgGraph* reference.
- **Get the exact list on your host** with `Get-MgEnvironment` — it prints the Graph and Azure AD
  endpoint URLs for `USGov` and `USGovDoD`.

> **Important architectural note (doc-confirmed):** In the government cloud, the **Intune service
> instance is shared between GCC High and DoD tenants** (this differs from Microsoft 365/Azure, which
> have separate DoD instances). **GCC** (state/local) is the *commercial* Intune instance — it is
> **not** the government cloud. In Intune docs, "GCC High" and "DoD" mean the government cloud
> (**IL4/IL5**); "GCC" means the commercial service. Source: *Intune Government Service overview*.

---

## 2. Reporting, analytics & monitoring — parity (the core of this solution)

Compliance evidence in this solution is read from **first-party Graph configuration and device state**,
which **is available** in GCC High/DoD. But several Commercial *reporting/analytics/export* features a
team might reach for are **not** — plan the evidence pipeline around what exists.

| Capability | GCC High / DoD status | Impact on this solution |
| --- | --- | --- |
| **Standard MDM state** — compliance policies, device configuration / Settings Catalog profiles, device compliance status | **Available** (Standard MDM features) | This is what the scripts read for evidence — **works**. |
| **Advanced Analytics** (Intune advanced capabilities) | **Available** in GCC High and DoD | Endpoint/device analytics can supplement evidence — available, but **verify the specific report you need renders in `intune.microsoft.us`**. |
| **Log Analytics / Azure Monitor export** (send Intune logs to Storage, Event Hubs, or Log Analytics) | **Available** | You **can** route Intune diagnostic/audit data to a Log Analytics workspace as a durable evidence store. |
| **Intune Power BI connector for Data Warehouse (DWH)** | **Not available** — *no planning to support* | Do **not** design evidence dashboards on the Intune Power BI/DWH connector. Use Graph exports (this solution) + Log Analytics instead. |
| **Reports for feature update policies** | **Not available** — *no planning* | N/A to CIS/STIG config drift, but do not cite feature-update reports as an evidence source. |
| **App and driver compatibility reports for Windows updates** | **Not available** — *no planning* | Not an evidence source in GCC High. |
| **ServiceNow connector** | **Not available** — *no planning* | Cannot push POA&M/incidents to ServiceNow via the native Intune connector — export the POA&M CSV and import it into your ITSM/GRC manually. |

*(Statuses from the Microsoft Intune Government Service overview parity tables, 2026-06-04.)*

**Net:** the read-only measurement and evidence method in this solution is fully supported in GCC
High/DoD (it uses Standard MDM state + Graph). The **gap is in downstream analytics/integration**
(Power BI DWH connector, ServiceNow connector) — so this solution's own CSV/JSON evidence + POA&M
exports, optionally backed by **Log Analytics**, are the right pattern for a Gov tenant.

---

## 3. Remediation & update tooling — parity (affects the "fix" step)

The Remediation script re-applies your existing Intune/Entra **baseline assignment** (Graph write to
policy assignment), which **is Standard MDM** and available. But several Commercial *update/remediation
conveniences* are **planned-not-yet-available** in GCC High/DoD — do not build the remediation runbook
on them.

| Capability | GCC High / DoD status | Impact |
| --- | --- | --- |
| Re-assigning a compliance / configuration / Settings Catalog policy to a group (what this solution's Remediation does) | **Available** (Standard MDM) | Safe, preview-first remediation **works**. |
| **Windows Autopatch** | **Planned — not yet available** | Cannot rely on Autopatch to close update-related drift in GCC High yet. |
| **Feature / Quality / Expedite / Driver updates for Windows in Intune** | **Planned — not yet available** | If a CIS/STIG control depends on a specific patch level, you cannot drive it through these Intune update rings in GCC High yet — manage updates by your existing Gov-approved mechanism. |
| **BIOS configuration profiles / DFCI management** | **Planned — not yet available** | STIG rules that require BIOS/DFCI enforcement cannot be pushed via Intune BIOS profiles in GCC High yet — flag such controls as out-of-band. |
| **Remote Help** | **Planned — not yet available** | No native Intune Remote Help for hands-on remediation in GCC High yet. |
| **Cloud PKI** | **Planned — GCC High only** (not DoD) | If certificate controls are in your baseline, Cloud PKI is coming to **GCC High** but is **not** listed for **DoD** — verify for DoD. |
| **Security Copilot in Intune** | **Planned — not yet available** | Do not assume Copilot-assisted triage of drift in GCC High. |
| **Windows Device Health Attestation (DHA)** | **Planned — not yet available** | If a compliance control uses DHA/attestation as its signal, that signal may be unavailable in GCC High — verify before monitoring it. |

*(Statuses from the "Intune features planned for GCC High and DoD" table, 2026-06-04.)*

**Verify for GCC High/DoD:** these are on Microsoft's *planned* list, so status can flip to
Available. Re-check the parity doc before designing a control around any of them.

---

## 4. Identity / Entra controls — parity

The Entra half of the baseline (Conditional Access, authentication-method policy) is read from Graph
US Gov the same way as Commercial, but **feature availability in Azure for US Government can differ**.

- **Conditional Access** is available in the Entra admin center (`entra.microsoft.us` → **Entra ID →
  Conditional Access**); it is a core Zero-Trust/CMMC/NIST control surface in GCC High.
- **Continuous access evaluation (CAE)** is available in Azure Government tenants (GCC High and DoD).
- **MFA / auth methods do not migrate** from a Commercial tenant — users re-register in GCC High.
- **Verify for GCC High/DoD:** some individual Entra ID Protection / authentication features have
  different availability in Azure for US Government. Before monitoring an identity control, confirm it
  on **Microsoft Learn — *Microsoft Entra feature availability in Azure for US Government***
  (`https://learn.microsoft.com/en-us/entra/identity/authentication/feature-availability`). Do not
  assume a Commercial Entra feature is present.

---

## 5. Why continuous compliance + POA&M matters *more* here (FedRAMP High / DoD IL4–IL5)

GCC High and DoD are the clouds where continuous compliance monitoring and audit evidence are not
optional — they are the mechanics of maintaining an authorization.

- GCC High/DoD run on **Azure Government**, certified to **FedRAMP High**, with data and hardware in
  the continental United States. Source: *Intune Government Service overview* — *Intune commercial and
  government instances* / *Compliance and certifications*.
- These government instances are **IL4 (GCC High)** and **IL5 (DoD)** — "IL" = **Impact Level**.
  Source: same doc.
- Under **FedRAMP** continuous monitoring and **NIST SP 800-53 control CA-5**, a **Plan of Action &
  Milestones (POA&M)** is the required artifact for tracking weaknesses found in assessments and
  continuous monitoring; FedRAMP High programs conduct **monthly** monitoring and submit **updated
  POA&M** on a cadence, with remediation timelines commonly **30 days (High/Critical), 90 days
  (Moderate), 180 days (Low)**. Source: FedRAMP / NIST 800-53 CA-5 guidance (general framework
  reference — **verify the exact obligations that apply to your system's authorization boundary and
  ATO with your assessor/AO**).
- **STIG lockdown guidance:** Microsoft points GCC High/DoD admins to the DISA **STIGs Document
  Library** on `public.cyber.mil` for hardening Intune tenants. Source: *Intune Government Service
  overview*. (This solution **monitors** a deployed CIS/STIG baseline; the **rule content itself is
  deferred to CIS and DISA**.)

This is the "why" behind the product: a Gov tenant must **prove** — monthly, with dated evidence and a
maintained POA&M — that its CIS/STIG baseline is still true. This solution produces exactly those
artifacts.

---

## 6. Licensing note (Government SKUs)

- Intune for government is licensed through the **US Government SKUs** — Microsoft 365 **G3 / G5**
  (the Gov equivalents of E3/E5), **Enterprise Mobility + Security G3/G5**, or standalone **Intune
  Plan 1/2 for Government** — not the Commercial E-plans.
- **Advanced Analytics, Endpoint Privilege Management, Enterprise App Management** and other **Intune
  Suite / advanced** capabilities are **add-on licensed** (Gov equivalents) and are listed as
  **available** in GCC High/DoD — but confirm the exact Gov add-on that carries a feature.
- **Verify for GCC High/DoD:** confirm the Gov SKU that grants a given capability in your tenant's
  license blade (`portal.office365.us → Billing → Licenses`) before designing around it.

---

## 7. How to keep this current

The parity tables change as Microsoft ships. **Before any design decision that depends on a specific
feature being present in GCC High or DoD**, re-open the **Intune Government Service overview** and the
**Intune US government endpoints** docs and re-confirm the row. Where this document says "verify for
GCC High/DoD", that is a required step — never assume Commercial behavior carries over.

> **Sources:** Microsoft Learn — *Microsoft Intune Government Service overview* (2026-06-04);
> *Network endpoints for US government deployments — Microsoft Intune* (2025-12-15); *Access national
> cloud deployments with the Microsoft Graph SDKs*; *Connect-MgGraph* reference; *Microsoft Entra
> feature availability in Azure for US Government*; DISA *STIGs Document Library* (`public.cyber.mil`);
> FedRAMP / NIST SP 800-53 Rev. 5 **CA-5 (POA&M)** and FedRAMP continuous-monitoring guidance
> (framework reference — verify against your own ATO).
