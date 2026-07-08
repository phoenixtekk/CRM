# 1. Solution Overview — Sensitivity Labeling for Power BI & Microsoft Fabric (Microsoft Purview)

## What this solution is
Analytics is where classified data is at its most concentrated and its most portable. A Power BI report
or a Microsoft Fabric item can surface data from a dozen sources at once — and then a user clicks
**Export to Excel**, and the data walks out the door in a spreadsheet that carries no protection at all.
That is the gap this solution closes. It applies **Microsoft Purview sensitivity labels** to Power BI and
Fabric content and, critically, makes those labels **flow with the data**:

- **Label the analytics artifact** — apply a sensitivity label to a Power BI **semantic model, report,
  dashboard, dataflow**, and to **Microsoft Fabric items** (lakehouses, warehouses, notebooks, etc.), so
  the content itself is classified in the Purview taxonomy.
- **Inherit from the source** — where a data source is already labeled (for example a labeled file or a
  labeled database column), the label can **flow into** the Power BI content, so classification isn't
  re-decided in the BI layer.
- **Inherit to the export** — when a user exports to **Excel, PowerPoint, or PDF**, the sensitivity label
  and its **encryption/usage rights travel with the exported file**, so a "download" is no longer a way
  to strip protection.
- **Drive it with a policy** — publish the labels to BI creators, and (after piloting) require a label on
  new/changed content with **mandatory labeling**, so coverage doesn't depend on memory.

Everything is done with the **Microsoft Purview portal** (purview.microsoft.com), the **Power BI /
Fabric admin portal**, **Security & Compliance PowerShell** (`Connect-IPPSSession`), and read-only Power
BI PowerShell — no third-party tooling. The capability is enabled, **piloted on a small ring/workspace
first**, validated against pass/fail gates, then expanded.

> **The labels are your existing Purview sensitivity labels — this solution makes analytics honor them.**
> Power BI and Fabric do not use a separate label set; they consume the same **Information Protection**
> sensitivity labels published from Purview. This solution enables analytics to apply and inherit those
> labels and enforce them on export — it does not invent BI-only labels.

## Why this matters
- **Export is the real exfiltration path.** The dashboard sits behind Power BI's access controls, but the
  exported spreadsheet doesn't — unless the label and its encryption ride along. Export inheritance turns
  every download into a still-protected file.
- **Analytics concentrates sensitivity.** One report can join HR, finance, and customer data. Labeling
  the artifact makes that concentration visible and governed instead of implicit.
- **Inheritance prevents re-classification drift.** If a labeled source flows into an unlabeled report,
  the protection is lost at the BI boundary. Source-to-content inheritance keeps the classification
  consistent from the data to the visual to the export.
- **It is defensible and auditable.** "Every workspace containing regulated data enforces labels, and
  exports inherit encryption" is a statement you can evidence with a report and admin settings, not a
  hope.

## How it works
1. **Assess.** Read the tenant's current state — which sensitivity labels exist and are published, the
   **Power BI/Fabric tenant settings** for information protection (label application, source inheritance,
   mandatory labeling, export restrictions), and the in-scope workspaces — all read-only.
2. **Design.** Decide which sensitivity labels apply to analytics, which **security group** may apply
   labels, whether **source inheritance** and **export restrictions** are on, and where **mandatory
   labeling** will eventually apply — aligned to the classification intent your stakeholders set.
3. **Configure.** Publish the labels to BI creators via a label policy, and enable the information-
   protection **tenant settings** in the Power BI/Fabric admin portal (delegated to the security group).
4. **Pilot.** Enable for a **pilot workspace / security group first** and label real content — never
   tenant-wide on day one. Mandatory labeling and export restrictions are **high-impact** for creators
   and consumers; prove them on the ring.
5. **Validate.** Confirm labels apply to artifacts, **inherit from labeled sources**, and **inherit to
   exports** (an exported Excel carries the label and its protection), against the pass/fail gates.
6. **Expand.** Broaden to all intended workspaces, enable **mandatory labeling** only after validation,
   and hand ongoing coverage and reporting to operations.

## The analytics labeling design (used throughout)
The same organizational sensitivity labels are reused; this solution governs **how analytics applies and
inherits them**. Names below are examples — the **determination** of which content warrants which label
belongs to your compliance, security, and data-governance stakeholders.

| Setting | Design intent |
|---|---|
| Labels published to BI creators | `General`, `Confidential`, `Highly Confidential` (your existing Purview labels) via `Analytics Labels – Policy` |
| Who may apply labels | `BI Labeling – Enabled Users` security group (tenant-setting delegation) |
| Source → content inheritance | **On** — labeled sources flow their label into Power BI content |
| Export → file inheritance | **On** — Excel/PowerPoint/PDF exports inherit the label + encryption |
| Mandatory labeling | **Off during pilot; on after validation** — new/changed content must be labeled |

> **Licensing / plan note — verify against your own tenant.** Applying sensitivity labels in Power BI
> requires **Power BI Pro or Premium Per User (or a Premium/Fabric capacity)** for the affected users
> **and** the sensitivity-label entitlement (Azure Information Protection P1/P2, included in Microsoft 365
> E5 / E5 Compliance). Information-protection **tenant settings** are configured in the Power BI/Fabric
> admin portal and are **evolving** — confirm the current setting names, the export-restriction behavior,
> and Fabric-item coverage for *your* tenant in Microsoft's documentation before you design. Where a
> capability is unavailable, scope to what your plan supports and record the rest as **deferred**.

## What you get
- This **Solution Overview**, a **Requirements Guide** (every prerequisite with verify /
  implement-if-missing), a precise **Implementation Guide**, a **Testing Guide** with pass/fail gates, a
  **Troubleshooting Guide**, and field-proven **Best Practices**.
- **Five PowerShell tools** — Discovery, a prerequisite/health helper, a safe Configuration/Remediation
  tool (`-WhatIf` by default), Validation, and Reporting — built on Security & Compliance PowerShell and
  read-only Power BI PowerShell, **read-only or `-WhatIf` by default and with no credentials in code**.

> **Boundary.** Which analytics content is sensitive, and any regulatory/records obligation on the data
> it surfaces, are **determinations owned by your compliance, privacy, and data-governance functions**.
> This solution provides the technical configuration and the evidence — not the determination.
