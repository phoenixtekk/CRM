# GCC High Parity Notes — Purview DLP, Sensitivity Labels & Retention

This is the working reference for the **Commercial-vs-GCC High differences** that shape this
solution. The Government (GCC High) edition of Microsoft Purview is **not** the Commercial portal
with a different sign-in: the admin URLs are different sovereign-cloud endpoints, and several Purview
capabilities are GA, in preview, "in development", or "on the engineering backlog" in GCC High while
they are generally available in Commercial. Everything below is either **doc-confirmed** with a
Microsoft citation or explicitly **flagged "verify for GCC High"**.

> **Primary source (authoritative parity table):** Microsoft Learn — *Plan for Microsoft Purview —
> GCC High deployments* (Service Descriptions), "Step 4: Understand which capabilities are currently
> unavailable or disabled by default in Microsoft 365 Government – GCC High." Doc dated 2025-05-21,
> updated 2025-12-02.
> `https://learn.microsoft.com/en-us/office365/servicedescriptions/microsoft-365-service-descriptions/microsoft-365-tenantlevel-services-licensing-guidance/plan-for-microsoft-purview-gcc-high-deployments`
>
> **Status legend (Microsoft's own terms):** *Available* = GA in GCC High · *Rolling out* =
> deploying now · *Public Preview* = preview only · *In development* / *On engineering backlog* =
> **not yet available** in GCC High. Microsoft states this status "is subject to change as project
> plans and priorities are reevaluated" — **re-verify against the live doc before you rely on any
> single row.**

---

## 1. Portals & endpoints (sovereign-cloud URLs)

| Purpose | Commercial | GCC High |
| --- | --- | --- |
| Sign-in / authentication | `login.microsoftonline.com` | `login.microsoftonline.us` |
| Microsoft 365 admin center | `admin.microsoft.com` | `portal.office365.us` |
| Purview compliance portal | `compliance.microsoft.com` / `purview.microsoft.com` | `compliance.microsoft.us` (Purview portal is rolling to `purview.microsoft.us`) |
| Defender / security portal | `security.microsoft.com` | `security.microsoft.us` |
| Entra admin center | `entra.microsoft.com` | `entra.microsoft.us` |
| Azure portal | `portal.azure.com` | `portal.azure.us` |

- **Doc-confirmed:** `portal.office365.us`, `security.microsoft.us`, `entra.microsoft.us`,
  `portal.azure.us`, and the shared `purview.microsoft.us` admin center are the GCC High endpoints.
  Source: MSPortals.io US Government portal reference (`https://msportals.io/usgovt.html`).
- **Doc-confirmed:** `login.microsoftonline.us` is the GCC High Azure AD authentication endpoint
  (the US Gov identity cloud, `AzureUSGovernment`). Source: Microsoft "US Government national clouds"
  guidance — `https://learn.microsoft.com/en-us/entra/identity-platform/authentication-national-cloud`.
- **Verify for GCC High:** Microsoft is consolidating the Purview compliance portal to
  `purview.microsoft.us`. The legacy `compliance.microsoft.us` still resolves at time of writing.
  Confirm which host your tenant redirects to; both reach the same GCC High Purview service.

**Graph / PowerShell endpoints (used by the scripts):**
- Microsoft Graph US Gov: `graph.microsoft.us` — connect with `Connect-MgGraph -Environment USGov`.
  (DoD tenants use `USGovDoD` / `dod-graph.microsoft.us`; GCC High = `USGov`.)
- Security & Compliance PowerShell (Exchange Online / Purview cmdlets) uses the GCC High connection
  URI `https://ps.compliance.protection.office365.us/powershell-liveid/` via
  `Connect-IPPSSession -ConnectionUri ...` with `-ExchangeEnvironmentName O365USGovGCCHigh`.
  Source: Microsoft "Connect to Security & Compliance PowerShell" —
  `https://learn.microsoft.com/en-us/powershell/exchange/connect-to-scc-powershell`.

---

## 2. Sensitivity labels & auto-labeling — parity

| Capability | GCC High status | Notes |
| --- | --- | --- |
| Manual labels | **Available** | Publish and apply labels manually — GA. |
| Mandatory labels | **Available** | Require a label before save/send — GA. |
| Unified labeling client and scanner | **Available** | On-prem scanner supported. |
| Auto-classification & labeling — Exchange Online, SharePoint Online, OneDrive (service-side) | **Available** | Server-side auto-labeling GA. |
| Auto-classification & labeling — Office apps (Word/Excel/PowerPoint/Outlook) across web, Android, iOS, Windows, Mac (client-side) | **Available** | Client-side auto-labeling GA. |
| Machine-learning classifiers with auto-labeling on Office apps / client side | **Available** | Trainable-classifier-driven client-side auto-labeling GA. |
| **Automatic classification & labeling for Office clients (Mobile)** | **On engineering backlog** | **Not available** in GCC High — do not promise mobile-client auto-labeling. |
| Apply a **default label** to an unlabeled file uploaded to a SharePoint Online library | **In development** | **Not available** — plan around it. |
| Apply **default label policies** to documents being edited | **In development** | **Not available**. |
| **Granular Conditional Access via sensitivity labels for SharePoint Online sites** | **On engineering backlog** | **Not available** — container/site protection via label is limited. Verify container-label support separately. |
| New conditions for auto-labeling in Exchange Online | **In development** | Newer EXO auto-label conditions may be missing. |
| PDF files encrypted with a sensitivity label can be searched / eDiscovered | **On engineering backlog** | Encrypted-PDF search/eDiscovery gap. |
| Co-authoring on encrypted (labeled) documents | **Available** | GA. |
| Auto-labeling overwrite of manual label + encrypt mail from any org | **Available** | GA. |

**Trainable classifiers:** the parity table lists *"Machine learning classifiers with auto labeling
on Office apps/client side" = Available* and *"Apply record policies automatically with trainable
classifiers" = In development*. So trainable classifiers work for **client-side auto-labeling** in
GCC High but are **not yet available to auto-apply *records* labels**. **Verify for GCC High:**
confirm the specific pre-trained classifier you intend to use is listed/selectable in
`compliance.microsoft.us` before designing a policy around it — classifier availability can lag.

---

## 3. Data Loss Prevention (DLP) — parity

| Capability | GCC High status |
| --- | --- |
| DLP for Files (SharePoint / OneDrive) and email | **Available** |
| DLP for Teams chat and channel conversations | **Available** |
| Endpoint DLP | **Available** |
| DLP on-premises scanner | **Available** |
| Alerts dashboard and alerting experience | **Available** |
| Data surfaced in Activity Explorer | **Available** |
| Microsoft Defender for Cloud Apps integration | **Available** |
| **Adaptive Protection integration with DLP** (risk-based DLP driven by Insider Risk levels) | **Available / rolling out to Gov clouds** — see §5 |

**Sensitive information types (SITs):**
- Exact Data Match (EDM) — **Available**.
- **Named entity SITs and policy-authoring templates — On engineering backlog** → **not available**
  in GCC High. Build DLP conditions from **built-in SITs, EDM, keyword dictionaries, and
  regular-expression SITs** instead of named-entity SITs.

---

## 4. Retention & Records Management — parity

| Capability | GCC High status |
| --- | --- |
| Retention policies (org-wide; specific locations/users; condition-based e.g. keyword/SIT; event-based) | **Available** |
| Retention policies for Teams chat, meeting recordings, private channels | **Available** |
| Adaptive scopes for retention and labeling policies | **Available** |
| Manual (non-record) retention labels | **Available** |
| Apply default retention labels (SPO/ODB libraries/folders/document sets; Exchange inboxes; M365 Groups) | **Available** |
| Preservation Lock | **Available** |
| Records management: apply record label manually / default | **Available** |
| Records management: apply record policies automatically by condition (keyword/SIT) or event | **Available** |
| Disposition review; multi-stage disposition review | **Available** / multi-stage **Rolling out** |
| File plan manager, regulatory records, proof of disposal, records versioning | **Available** |
| **Apply retention *label* action at end of retention period** | **On engineering backlog** → **not available** |
| **Apply record policies automatically with trainable classifiers** | **In development** → **not available** |
| Configure option to block editing metadata for records / disable unlocking of records | **In development** (records unlock-disable via records mgmt shows **Available** in one row and **In development** in another — **verify for GCC High**) |
| **Power Automate integration for Records Management** | **On engineering backlog** → **not available** |
| Graph APIs for Records Management | **In development** → **not available** |

---

## 5. Adjacent capabilities that affect a Purview rollout

| Capability | GCC High status | Source |
| --- | --- | --- |
| Insider Risk Management — core | Mixed: many templates **Available**, several **Public Preview** / **In development** | Parity table (IRM section) |
| **Adaptive Protection** (Insider Risk → dynamic DLP/CA) | **Rolling out to GCC, GCC High, DoD** (Gov rollout began ~Feb–Mar 2025; DLP integration listed Available for Gov clouds) | Microsoft message-center MC803011; Microsoft Learn *Adaptive Protection* docs |
| Data Security Posture Management (DSPM) for AI | **Available**, but **"Browse to URL" policy cannot be created**; only supported AI sites are available in GCC-H/DoD | Parity table footnote ^2^ |
| Communication Compliance | Most **Available**; retention-period setting **On backlog**; Power Automate integration **Public Preview** | Parity table (Comm. Compliance) |
| Audit (Premium) — 1-year and 10-year log retention | **Available** | Parity table (Audit Premium) |
| First-party data connectors (HR, physical badging) | **Available**; HR 1.2 **In development**; several Graph export/eDiscovery/records APIs **In development** | Parity table (Ecosystem) |
| Microsoft Priva (Privacy Risk Mgmt, Subject Rights Requests) | **In development** → **not available** in GCC High | Parity table (Privacy) |

---

## 6. Licensing note (Government SKUs)

- Purview information protection, DLP, and retention are licensed through **Microsoft 365 Government
  G3 / G5** (the Gov equivalents of E3/E5), **G5 Compliance**, and **G5 Information Protection &
  Governance** add-ons — the Gov SKUs, not the Commercial E-plans.
- Feature availability follows the **same E3-vs-E5 split as Commercial** (e.g. auto-labeling,
  records management, Adaptive Protection are E5/G5-class), **layered on top of** the GCC High
  parity gaps above. **Verify for GCC High:** confirm the exact Gov SKU that carries a given feature
  in the *Microsoft Purview service description* and your tenant's license blade before designing.
  Source: Microsoft Learn — *Microsoft Purview service description*
  (`https://learn.microsoft.com/en-us/office365/servicedescriptions/microsoft-365-service-descriptions/microsoft-365-tenantlevel-services-licensing-guidance/microsoft-purview-service-description`).

---

## 7. How to keep this current

The parity table changes as Microsoft ships. **Before any design decision that depends on a specific
feature being present**, re-open the *Plan for Microsoft Purview — GCC High deployments* page and the
Microsoft 365 Roadmap filtered to **GCC High** and re-confirm the row. Where this document says
"verify for GCC High", that is a required step, not a suggestion — never assume Commercial behavior
carries over.
