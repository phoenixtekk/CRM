# Solution Overview — Microsoft 365 Copilot Secure Adoption & Governance (Government / GCC High)

This is the **Government (GCC High)** edition of *Microsoft 365 Copilot Secure Adoption &
Governance*. It takes the same discipline — get your data estate governed *before* you turn Copilot
loose on it — and re-authors every step for the **US sovereign cloud (GCC High)**: the correct
`*.us` admin portals, the US Gov Microsoft Graph endpoints (`-Environment USGov`), and the
**Commercial-vs-GCC-High parity gaps** that make Commercial click-paths silently fail on a
government tenant.

> **Read this first — Copilot availability in GCC High (as of this writing, verify for your
> tenant).** Microsoft 365 Copilot **reached general availability in GCC High in December 2025**,
> after earlier launches in GCC and DoD. So Copilot *is* available on GCC High today — this is **not**
> a "wait until it ships" solution. **But** two things are true at once, and both shape this guide:
> 1. **Copilot is live**, so the governance work here (oversharing remediation, sensitivity labels,
>    Restricted SharePoint Search) is not hypothetical — it is the gate you must clear *before*
>    users start prompting against your CUI.
> 2. **GCC High is not at feature parity with Commercial.** Several capabilities are OFF by default,
>    limited, or not yet available (web grounding, some Copilot Studio surfaces, Teams meeting
>    Copilot, Wave 2 features). Those gaps are called out inline where they matter.
>
> Source: [Microsoft — M365 Copilot is now available in GCC High](https://techcommunity.microsoft.com/blog/publicsectorblog/microsoft-365-copilot-is-now-available-in-gcc-high/4473310)
> and [Understand Microsoft US government cloud environments](https://learn.microsoft.com/en-us/microsoft-365/copilot/gov-overview).
> **Always verify current availability for your own GCC High tenant** — the roadmap moves.

---

## What this solution does

Microsoft 365 Copilot answers a user's prompt by reasoning over **everything that user can already
open** — every SharePoint site, Teams channel, and OneDrive file their account has access to. In a
government tenant that reasons over **CUI**, that is exactly the risk: if permissions are loose,
Copilot becomes a very fast way to surface content a user could *technically* reach but was never
meant to see. This solution puts the **governance guardrails** in place first, then adopts Copilot
in a controlled, piloted, validated way:

- **Assess** the oversharing exposure and label/DLP posture *before* Copilot is enabled for anyone.
- **Configure** the guardrails — sensitivity labels, DLP, Restricted SharePoint Search (RSS),
  Copilot-relevant Purview and SharePoint controls — using the **GCC High portals**.
- **Pilot** Copilot with a **named security group** (`SG-COPILOTG-Pilot`), not the whole tenant.
- **Validate** with the included scripts and manual checks (pass/fail gates).
- **Expand** in controlled waves, each gated on the prior wave's results.

The deliverables — this guide, the requirements and implementation guides, the testing and
troubleshooting guides, and **five PowerShell scripts** — are all authored for GCC High.

---

## Commercial vs GCC High — what's different

This is the section that saves you from following a Commercial tutorial into a dead end. If you have
run Copilot governance on a Commercial tenant, **assume nothing carries over unchanged.**

### 1. The admin portals are different URLs (`*.us`, not `.com`)

Every portal you touch has a sovereign-cloud address. Using the Commercial URL will either fail to
load your tenant or, worse, sign you into the wrong tenant.

| Purpose | Commercial (do **not** use) | GCC High (use this) |
| --- | --- | --- |
| Sign-in / identity authority | `login.microsoftonline.com` | `login.microsoftonline.us` |
| Microsoft 365 admin center | `admin.microsoft.com` | `portal.office365.us` |
| Microsoft Entra admin center | `entra.microsoft.com` | `entra.microsoft.us` |
| Microsoft Purview | `purview.microsoft.com` / `compliance.microsoft.com` | `compliance.microsoft.us` |
| Microsoft Defender | `security.microsoft.com` | `security.microsoft.us` |
| Intune / Endpoint | `intune.microsoft.com` / `endpoint.microsoft.com` | `endpoint.microsoft.us` |
| Azure portal | `portal.azure.com` | `portal.azure.us` |
| Copilot Studio | `copilotstudio.microsoft.com` | `high.powerva.microsoft.us` |
| Power Platform admin | `admin.powerplatform.microsoft.com` | `high.admin.powerplatform.microsoft.us` |

Source for the sovereign portal set: [Microsoft US Gov cloud overview](https://learn.microsoft.com/en-us/microsoft-365/copilot/gov-overview)
and [Copilot Studio US Government service URLs](https://learn.microsoft.com/en-us/microsoft-copilot-studio/requirements-licensing-gcc).
**Verify each portal loads *your* GCC High tenant before configuring anything.**

### 2. Identity is Entra ID **for Government**

GCC High uses **Microsoft Entra ID for Government** (the US Gov sovereign directory), not the public
Entra ID that GCC uses. Scripts must connect to the **US Gov Graph** with `-Environment USGov`;
Commercial Graph calls will not resolve your tenant. (Source:
[Copilot Studio US Gov requirements](https://learn.microsoft.com/en-us/microsoft-copilot-studio/requirements-licensing-gcc).)

### 3. Web grounding is **OFF by default** in GCC High

To keep sensitive government data inside the compliance boundary, Microsoft ships Copilot to GCC High
with **web grounding OFF by default**. Practically: Copilot answers only from tenant content (and its
trained model), so responses can be subject to a **knowledge cutoff** and may be dated. Do not design
adoption around "Copilot will look it up on the web" — plan for **tenant-grounded answers only**
unless your organization explicitly enables and accepts web grounding. (Source:
[M365 Copilot in GCC High](https://techcommunity.microsoft.com/blog/publicsectorblog/microsoft-365-copilot-is-now-available-in-gcc-high/4473310).)

### 4. Feature parity lags — several surfaces are limited or not yet available

Release timing in GCC High typically **lags Commercial**, and some integrations are more restricted
by design. At the time of writing:

- **Copilot in Microsoft 365 apps** (Word, Excel, PowerPoint, Outlook) and **Copilot Chat
  (work grounding)** are available in GCC High.
- **Teams meeting Copilot** and **Copilot in Teams chat/channels** have historically been
  **limited or not yet available** in GCC High — **verify current status for your tenant.**
- **Copilot Studio / agents in GCC High** are **more restricted** than Commercial: the Copilot
  Studio **Teams app experience**, the **Teams & M365 Copilot channel**, **Copilot agents that
  extend M365**, **Prompt Action**, and **transfer-to-agent** are listed **not available in GCC
  High**; **triggers / autonomous agents** and **Azure AI Search as a knowledge source** are not
  available in GCC or GCC High. (Source:
  [Copilot Studio US Gov feature limitations](https://learn.microsoft.com/en-us/microsoft-copilot-studio/requirements-licensing-gcc).)
- **Wave 2 features** (e.g. GPT-5, image generation, code interpreter, Researcher/Analyst agents)
  are staged into GCC High through **H1 2026** — **verify what has actually landed** before you
  promise it to users. (Source:
  [M365 Copilot in GCC High](https://techcommunity.microsoft.com/blog/publicsectorblog/microsoft-365-copilot-is-now-available-in-gcc-high/4473310).)

> **Authoring rule for this whole solution:** where a step depends on a capability that may not be
> at parity, the guide says so and tells you to **verify for GCC High** rather than assuming. We
> never invent a GCC High behavior we could not cite.

### 5. Compliance framing is stricter

GCC High is built for **FedRAMP High, DFARS, ITAR/EAR, and CMMC** workloads handling **CUI**. That
raises the stakes on the governance work: an oversharing gap is not just an IT hygiene issue, it is a
potential **CUI spillage** path once Copilot can reason over it. Treat the pilot gate as mandatory.

---

## The deployment model (all editions)

**Assess → Configure → Pilot → Validate → Expand**, with a gate at each arrow. You do not enable
Copilot for a user until the data those users can reach has been assessed and remediated, and you do
not expand past the pilot until validation passes. This edition simply runs that model on the **GCC
High portals and US Gov Graph endpoints**.

## Named objects you will create and reuse

| Object | Name | Used for |
| --- | --- | --- |
| Pilot security group | `SG-COPILOTG-Pilot` | First wave of Copilot-licensed users |
| Expansion security group | `SG-COPILOTG-Wave2` | Second controlled wave |
| Sensitivity label (baseline) | `CUI//BASIC` (or your org's CUI label set) | Labeling CUI so DLP/Copilot honor it |
| RSS allow-list | `Copilot Search Allowed Sites` | Sites Copilot may search once RSS is on |

Names are used consistently across the implementation, testing, troubleshooting, and script docs so a
novice admin can follow one thread end to end. Substitute your organization's own CUI label taxonomy
where indicated — **do not invent a label scheme; use the one your program already mandates.**

---

## What you get

1. This **Solution Overview** (Commercial-vs-GCC-High differences, Copilot availability caveat).
2. **Requirements Guide** — every prerequisite, how to verify and how to implement, GCC High
   licensing (G3/G5 Gov + Copilot add-on), roles, sovereign portal access, endpoints.
3. **Implementation Guide** — ordered steps on the GCC High portals with parity caveats inline.
4. **Testing Guide** — pass/fail validation gates.
5. **Troubleshooting Guide** — GCC-High-specific gotchas.
6. **Best Practices** and a **Deliverables Summary**.
7. **GCC High parity notes** (cited reference).
8. **Five PowerShell scripts** — Discovery, Validation, Report, Remediation, Set-ScopeTargeting —
   all connecting to **US Gov Graph** (`-Environment USGov`).
