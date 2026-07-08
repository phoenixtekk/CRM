# 1. Solution Overview — Snowflake Data Governance (Microsoft Purview)

## What this solution is
Snowflake is often the largest concentration of governed data in the estate — and the biggest blind spot
in the data catalog. If Snowflake isn't in **Microsoft Purview**, you can't see what sensitive data it
holds, can't classify it, and can't answer "where is our customer PII?" for the platform that has the most
of it. This solution closes that gap by bringing Snowflake into the **Purview Data Map and Data Catalog**:

- **Register** the Snowflake source in the Purview **Data Map** under a governance collection, so it's a
  first-class part of the catalog.
- **Scan** Snowflake — connecting with a securely-stored credential (never a secret in a script), through
  a **self-hosted or managed integration runtime** where network access requires it — to extract the
  technical metadata (databases, schemas, tables, columns).
- **Classify** the scanned assets against Purview's **classifications / sensitive information types**
  (credit-card, national ID, and your custom types) so sensitive columns are identified automatically.
- **Catalog and curate** the results — assets discoverable in the Purview catalog, with scope for glossary
  terms, data owners, and lineage — so the platform is governed, not just connected.

Everything is done with the **Microsoft Purview portal** (purview.microsoft.com), the **Purview Data Map**,
and PowerShell/REST against Purview and Azure — no third-party tooling. The source is registered, **scanned
first on a limited pilot scope (one database/schema)**, validated against pass/fail gates, then expanded.

> **This is data *governance* (Data Map/Catalog), not data *loss prevention*.** This solution catalogs and
> classifies Snowflake so you can *see and understand* the data. It does not enforce DLP on Snowflake or
> apply protection inside Snowflake — that's a different capability. Cataloging is the foundation that
> makes downstream governance decisions possible; this solution delivers that foundation.

## Why this matters
- **You can't govern what you can't see.** A data catalog that omits Snowflake is missing the platform
  most likely to hold regulated data. Registering and scanning it makes the largest data store visible.
- **Classification finds the sensitive columns for you.** Scanning against classifications/SITs surfaces
  which Snowflake columns look like PII, financial, or health data — at scale, instead of by interview.
- **The catalog answers the questions auditors ask.** "Where is customer PII, who owns it, and how is it
  classified?" becomes a catalog query once Snowflake is scanned and curated.
- **It is defensible and auditable.** "Snowflake is registered, scanned on a schedule, and its sensitive
  assets are classified in the catalog" is a statement you can evidence with the Data Map and a report,
  not a hope.

## How it works
1. **Assess.** Read the Purview account, its **collections**, existing **registered sources** and scans,
   and confirm the network path to Snowflake and where a **self-hosted integration runtime (SHIR)** is
   required — all read-only.
2. **Design.** Decide the **collection** for Snowflake, the **credential** approach (a securely-stored
   secret in **Azure Key Vault**, referenced by Purview — never in a script), the **scan rule set**
   (which classifications apply), the **scope** (which databases/schemas), and the **pilot scope** (one
   database/schema). The classification scheme and data-owner assignments are stakeholder determinations.
3. **Configure.** Register the **`Snowflake – Source`** in the Data Map under the collection, create the
   **`Snowflake – Scan`** with its scan rule set and Key Vault-backed credential, scoped to the pilot.
4. **Pilot.** Run the scan on the **pilot scope first** (one database/schema) — never the whole account on
   day one. Scans consume resources and surface findings that need curation; prove the scope and results
   first.
5. **Validate.** Confirm the scan completed, assets appear in the catalog with the expected metadata, and
   classifications applied where expected, against the pass/fail gates.
6. **Expand.** Broaden the scan scope to the intended databases/schemas, put the scan on a **schedule**,
   curate ownership/glossary, and hand ongoing cataloging and reporting to the data-governance team.

## The governance design (used throughout)
Names below are examples; the **classification scheme, data owners, and glossary** are stakeholder
**determinations** owned by your data-governance function — this solution provides the technical
registration/scan/classification.

| Element | Design intent |
|---|---|
| Collection | `Snowflake – Collection` (under the Purview account root/domain) |
| Registered source | `Snowflake – Source` (the Snowflake account/server in the Data Map) |
| Scan | `Snowflake – Scan` (credential + scan rule set + scope + schedule) |
| Scan rule set | `Snowflake – Scan Rule Set` (which classifications/SITs apply) |
| Credential (Key Vault-backed) | `Snowflake – Scan Credential` — secret stored in Azure Key Vault, referenced by Purview |
| Pilot scope | `Snowflake – Pilot Scope – Stage1` — one database/schema |
| Design map | `Snowflake Governance – Map` |
| Coverage report | `Snowflake – Coverage Report` |

> **Licensing / plan note — verify against your own tenant.** Microsoft Purview **Data Governance** (the
> Data Map / Unified Catalog) has its own **consumption/capacity** and licensing model, distinct from the
> Microsoft 365 E5 compliance licensing used by DLP/labels — and the Data Governance experience is
> **actively evolving** (the classic Data Map and the newer unified catalog experience). Confirm the
> current Snowflake connector support, the exact registration/scan steps, integration-runtime
> requirements, and the pricing/consumption model for *your* Purview account in Microsoft's documentation
> before you design. Where a capability differs in your tenant, follow the current portal flow and record
> deviations in `Snowflake Governance – Map`.

## What you get
- This **Solution Overview**, a **Requirements Guide** (every prerequisite with verify /
  implement-if-missing), a precise **Implementation Guide**, a **Testing Guide** with pass/fail gates, a
  **Troubleshooting Guide**, and field-proven **Best Practices**.
- **Five PowerShell tools** — Discovery, a prerequisite/health helper, a safe Registration/Scan tool
  (`-WhatIf` by default; credential referenced from Key Vault, never a secret in code), Validation, and
  Reporting — built on PowerShell/REST against Purview and Azure, **read-only or `-WhatIf` by default and
  with no credentials in code**.

> **Boundary.** The **classification scheme**, the **data owners/stewards**, the **glossary**, and any
> regulatory obligation on Snowflake data are **determinations owned by your data-governance, compliance,
> and privacy functions**. This solution provides the technical registration, scan, and classification —
> and never embeds a Snowflake secret — not the determination.
