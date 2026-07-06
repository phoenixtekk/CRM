# 1. Solution Overview — Regulated Google Workspace: Assured Controls, ITAR & DFARS

## What this solution does
Enterprises with **ITAR** (International Traffic in Arms Regulations) or **DFARS** (Defense Federal
Acquisition Regulation Supplement) obligations cannot simply turn on Google Workspace for
controlled data. Controlled Unclassified Information (CUI), export-controlled technical data, and
similar regulated content need three technical boundaries in place: **where the data lives**
(sovereignty / residency), **who can touch it in support** (provider-access controls), and
**a policy configuration** that aligns Workspace to the applicable regime and to internal compliance
policy. This solution configures those boundaries in Google Workspace using **Assured Controls** and
the related **data-region**, **access-management**, and **access-approval** capabilities — deployed
**pilot-first** and **rollback-ready**.

> **Regulatory interpretation is deferred to legal / compliance.** This solution provides the
> **technical configuration and the evidence** — it does **not** make legal determinations about
> whether a given configuration satisfies ITAR, DFARS/NIST 800-171, or any other regime for your data.
> Which controlled-data categories apply, whether a specific control set is sufficient, and how
> encryption carve-outs are interpreted are decisions for your **legal / export-compliance and
> security** stakeholders. The technical steps below cite Google's public documentation; anything not
> confirmable from that documentation (or that depends on your contract/edition) is flagged
> **"verify in your tenant."**

## The Google capabilities this solution configures
Assured Controls is a **paid add-on** for Google Workspace, offered as **Assured Controls** and
**Assured Controls Plus**, available with **Frontline Plus or Enterprise Plus** editions
([Google — About Assured Controls][ac]). The capabilities that matter for controlled data are:

- **Access Management** — geographically and eligibility-limits the **Google support staff** who can
  take support actions on your data. Policy options published by Google: **No preference**;
  **U.S. Google staff only** (U.S. persons in a physical U.S. location); **CJIS / IRS 1075-authorized
  staff only** (U.S. persons in a U.S. location who have completed appropriate background checks); and
  an **EU staff** option ([Google — Access Management][am]). This is the control most directly relevant
  to export-controlled data's "no unauthorized foreign-person access" concern — **subject to your
  legal team's interpretation.**
- **Access Approvals** — requires Google staff to **request and receive approval** before viewing data
  in the course of support. Approvals are surfaced in **Access Transparency** logs
  ([Google — Access Approvals][aa]).
- **Access Transparency** — near-real-time **logs of Google-staff access** to your content, the
  audit/evidence surface behind Access Management and Access Approvals
  ([Google — Access Transparency logs][at]).
- **Data regions** — pins **data at rest** to a chosen geography (**No Preference / United States /
  Europe**), configurable per **OU or configuration group** via **Data regions → Advanced settings**
  ([Google — Data regions advanced settings][dr]). For ITAR/DFARS, **United States** residency is the
  typical target — **confirm scope with legal.**
- **Client-Side Encryption (CSE)** — encrypts content with keys you control, so it is indecipherable to
  Google. Google's public ITAR guidance positions **Workspace CSE** as usable, when properly
  configured, to meet the ITAR **end-to-end-encryption carve-out** for export-controlled technical data
  ([Google Cloud — ITAR][itar]). **This carve-out is a legal interpretation — do not treat CSE
  configuration alone as ITAR compliance; confirm with export-compliance counsel.**
- **Compliance supporting features bundled with the add-on** — **compliance data exports**,
  **data-regions advanced reporting**, **local data storage**, **policy-compliance log events**, and
  **Google Meet compliance recording** ([Google — About Assured Controls][ac]). These are the
  **evidence and reporting** surfaces this solution uses to demonstrate coverage.

## How the controls map to controlled-data requirements
| Controlled-data need | Google capability this solution configures | Evidence surface |
|---|---|---|
| Data residency / sovereignty (keep data at rest in-region, e.g. U.S.) | **Data regions** (Data at rest = United States), per OU/group | Data-regions advanced reporting |
| Limit provider (Google support) access by nationality / location / clearance | **Access Management** (U.S.-only / CJIS-IRS-1075) | Access Transparency logs |
| Require approval before any provider access | **Access Approvals** | Access Transparency logs |
| Provider-access visibility / audit | **Access Transparency** | Access Transparency log events |
| Keep content indecipherable to the provider (ITAR e2ee carve-out — *legal-gated*) | **Client-Side Encryption (CSE)** | CSE / policy-compliance logs |
| Demonstrable, exportable compliance evidence | **Compliance data exports, policy-compliance log events** | Reports / exports |

> The mapping shows **which technical control addresses which requirement**. Whether the combination is
> **sufficient** for your ITAR/DFARS obligations is a **legal/compliance determination**, not a
> technical one.

## What this solution does *not* do
- It does **not** provide legal or export-compliance advice, nor certify ITAR/DFARS/NIST 800-171
  compliance. It provides the configuration and the evidence for your compliance team to assess.
- It does **not** invent Assured Controls specifics. Where Google's public documentation does not state
  a detail, or where a feature is edition-/contract-dependent, the step is **cited or flagged
  "verify in your tenant"** rather than asserted.
- It does **not** replace **Google Cloud Assured Workloads** (the Cloud/ITAR data-boundary product for
  Google Cloud Platform resources). This solution is about **Google Workspace** controlled-data
  configuration; the GCP-side ITAR data boundary is referenced but its console steps are deferred to
  Google Cloud documentation.

## Benefits
- **Sovereignty** — controlled data at rest pinned to the required region (typically U.S.).
- **Provider-access boundaries** — Google support access limited by location / eligibility and gated by
  approval, with a transparent access log for evidence.
- **Compliance-aligned policy set** — a named, reusable configuration mapped to controlled-data
  requirements, applied by OU/group.
- **Evidence-first** — Access Transparency logs, compliance data exports, and policy-compliance log
  events give auditors demonstrable coverage.
- **Controlled blast radius** — a pilot OU/group proves the configuration before fleet-wide rollout,
  with a documented rollback.

## Limitations (be honest with buyers)
- **Legal interpretation is out of scope** — technical configuration and evidence only; compliance
  determinations belong to legal/compliance.
- Assured Controls / Access Management **feature availability and policy options are edition- and
  contract-dependent** and evolve; every add-on-gated step is flagged **"verify in your tenant."**
- Access Management policies apply **only to users in OUs that hold Assured Controls licenses**
  ([Google — Access Management][am]) — licensing scope is a prerequisite, not an afterthought.
- CSE's ITAR carve-out is a **legal position**, not a checkbox; correct CSE key management and scope are
  required and still require counsel's sign-off.

## The deployment model
> **Assess controlled-data posture → Configure residency, access-management/approval, and the policy set
> → Pilot on a curated OU/group → Validate against the compliance requirements → Expand**, with explicit
> pass/fail gates and a documented rollback for every production change. This is the standard
> **Assess → Configure → Pilot → Validate → Expand** model for the Google category.

---
[ac]: https://support.google.com/a/answer/13880647 "About Assured Controls and Assured Controls Plus — Google Workspace Admin Help"
[am]: https://support.google.com/a/answer/10343878 "Access Management: Limit the Google staff who can take support actions related to your data — Google Workspace Admin Help"
[aa]: https://support.google.com/a/answer/12410469 "Access Approvals — Google Workspace Admin Help"
[at]: https://support.google.com/a/answer/9230474 "Access Transparency: View logs on Google access to user content — Google Workspace Admin Help"
[dr]: https://knowledge.workspace.google.com/admin/compliance/set-up-advanced-settings-for-data-regions "Set up advanced settings for data regions — Google Workspace Admin Help"
[itar]: https://cloud.google.com/security/compliance/itar "International Traffic in Arms Regulations (ITAR) — Google Cloud"
