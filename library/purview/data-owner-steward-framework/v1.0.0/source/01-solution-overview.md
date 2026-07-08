# 1. Solution Overview — Data-Owner & Steward Framework (Microsoft Purview)

## What this solution is
Data assets accumulate faster than accountability for them does. A SharePoint site, a sensitivity
label, a DLP policy, a governance domain in the Purview Unified Catalog, a set of retention rules — all
exist, but ask "who *owns* this?" and the honest answer is usually "nobody in particular." This solution
delivers the missing layer: a **data-owner and data-steward operating framework** inside Microsoft
Purview. It assigns **named accountability** to data assets and to the Purview objects that govern them,
records that accountability in a **RACI** (who is Responsible, Accountable, Consulted, Informed for each
governance activity), and puts it on a **review cadence** so ownership stays current instead of decaying
the day the project ends.

It is the *operating model* — roles, RACI, and cadence — not a new technical control. It sits **on top
of** the Purview capabilities you already run (sensitivity labels, DLP, retention/records, the Unified
Catalog / Data Map, insider risk, communication compliance) and gives each of them an accountable owner
and a steward who keeps it healthy. Everything is done with the **Microsoft Purview portal**
(purview.microsoft.com), **Security & Compliance PowerShell** (`Connect-IPPSSession`), and **Microsoft
Graph** — no third-party tooling.

> **Boundary.** This solution provides the technical method to *define stewardship roles, assign named
> owners and stewards, record a RACI, and run a review cadence* in Microsoft Purview. It does **not**
> make the business, regulatory, records, or legal **determinations** — *what a data asset is worth*,
> *what its retention or records schedule is*, *which classification applies*, or *who is permitted to
> hold a sensitive role*. Those belong to the organization's data owners, compliance, records, privacy,
> and legal functions. The framework gives them a governed structure to *record and operate* those
> decisions; it never invents the decision.

## Why this matters
- **Unowned data is an accountability gap and a risk exposure.** When no one owns a data asset, no one
  re-certifies its classification, notices its DLP policy is in test mode a year later, or answers for it
  in an audit. "Who signed off on this?" has no answer.
- **Ownership without a RACI is ambiguous.** Two people each assuming the other owns re-certification is
  the same as nobody owning it. A RACI removes the ambiguity: exactly one **Accountable** party per
  activity, named **Responsible** doers, and explicit **Consulted / Informed** parties.
- **Ownership without a cadence decays.** A framework defined once and never revisited is stale within a
  quarter. The review cadence — re-certify owned assets, chase unowned gaps, retire what's obsolete — is
  what keeps the framework *alive*, and it is a first-class deliverable here, evidenced by the scripts.
- **Purview objects need owners too.** Labels, DLP policies, retention policies, and governance domains
  are governance *controls*; a control with no owner drifts. This framework names an owner and steward
  for the controls as well as the data.

## The three building blocks
This solution stands up three things, each named once in the Implementation Guide and reused everywhere.

1. **Roles** — the named stewardship roles and who fills them:
   - **Data Owner** — accountable for a data asset or a governance domain and for the decisions about it
     (classification intent, retention intent, access intent). Business-side, senior, few in number.
   - **Data Steward** — curates the asset day to day: keeps classification/labels, ownership metadata,
     and status current, runs the review cadence, and surfaces gaps. The operational role.
   - **Governance Domain Owner** — owns a governance domain in the Purview Unified Catalog and its role
     assignments (where the Data Governance capability is in use).
   - **Data Custodian / Control Owner** — accountable for a specific Purview *control* (a label, a DLP
     policy, a retention policy) — often IT/compliance — distinct from the *data* owner.
   - Sensitive-data roles (**Insider Risk**, **Communication Compliance**, **eDiscovery**) are named and
     **kept strictly separate**; who may hold them is an HR/privacy/legal determination.

2. **RACI** — for each recurring governance activity (classify/label an asset, author or tune a DLP or
   retention policy, re-certify ownership, review a disposition, respond to an access request, close an
   audit finding), the RACI names exactly one **Accountable** party and the **Responsible / Consulted /
   Informed** parties. The RACI is the contract that turns roles into unambiguous responsibility.

3. **Review cadence** — the recurring rhythm the steward runs: re-certify owned assets on a schedule,
   escalate unowned or overdue assets to the Data Owner, retire obsolete assignments, and produce the
   accountability report. Cadence is what prevents decay.

## Roles and least privilege
Where the framework touches Purview permissions, it uses **least-privilege built-in roles**, assigned at
the narrowest scope that works. Day-to-day compliance stewardship uses S&C role groups (e.g. **Compliance
Administrator**, **Information Protection Admin**, **Records Management**); Unified Catalog stewardship
uses **governance-domain-level** roles (**governance domain owner**, **data owner**, **data steward**,
**data reader**). Account-level administration is reserved for a minimal named group. Least-privilege
assignment is an explicit step in the Implementation Guide, not an afterthought — each role is named at
the stage it is needed.

## Pilot-first, safe by design
Defining a framework is low-blast-radius (recording that Jane owns a domain changes no user data), but
the same discipline applies: **pilot on a bounded scope first** — one or two governance domains / a small
named asset set — validate the RACI and cadence there, and only then **expand** to the full estate. Any
role assignment the scripts perform is **`-WhatIf` by default**, gated behind an explicit `-Commit`, and
prints the exact reverse command. **No secret is ever stored in a script or document.** This mirrors the
category model: **Assess → Design → Configure → Pilot → Validate → Expand.**

## Licensing and the evolving portal
The compliance-side surfaces this framework operates over (labels, DLP, retention, role groups) require
the corresponding **Microsoft 365 / E5 / E5 Compliance** licensing per capability. The **Unified Catalog
/ Data Governance** side (governance domains, data products, governance-domain roles) is billed through a
**consumption / pay-as-you-go** model tied to an **Azure subscription** and is **actively evolving** —
feature names, portal paths, and data-plane API versions may have moved or may be in preview. **Verify
current availability, pricing, portal paths, and API versions for your own tenant** in Microsoft's
documentation and in the Purview portal before you plan. This solution cites the method; it never asserts
a price, a portal path, or an API version as permanent, and it does not invent cmdlets.

## What this is not
This is the *accountability operating model*. It is **not** the label taxonomy design, the DLP/retention
policy build, the full Data Map / scanning rollout, or the business-glossary term-curation program —
those are separate Purview solutions this framework complements. A steward here may operate a glossary or
a set of labels, but *building* them is out of scope. This solution focuses squarely on **who is
accountable, for what, and how often it is reviewed.**

## Naming convention (used in every doc and script)
Artifacts follow `<Purpose> – Purview – <Stage>` and are reused verbatim across docs, scripts, and portal.

| Artifact | Name |
|---|---|
| Ownership / coverage assessment export | `Data Ownership Inventory – Steward – Assess` |
| The RACI matrix (roles × activities) | `Data-Owner/Steward RACI – Design` |
| Applied stewardship role assignments | `Stewardship Assignments – Configure` |
| Accountability / coverage report | `Accountability Coverage – Report` |
| Review-cadence health snapshot | `Review Cadence – Health` |
| Pilot domain / bounded scope | `Stewardship Pilot Domain – Stage1` |

## The standard deployment model
> Assess current ownership coverage and gaps → design the role model and RACI → configure the role
> assignments and cadence → pilot on a bounded domain/asset set → validate every gate → expand across the
> estate. Pattern: **Assess → Design → Configure → Pilot → Validate → Expand.**
