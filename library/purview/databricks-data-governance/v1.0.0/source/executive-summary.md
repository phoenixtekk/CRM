# Executive Summary — Databricks Data Governance (Unity Catalog / lakehouse): Microsoft Purview

Most data-governance efforts stop at Microsoft 365, and the lakehouse — customer records, financial
extracts, PII, and model features in Azure Databricks — sits outside the map, unclassified and ungoverned.
You cannot protect, retain, or grant access to data you cannot see, and analysts create tables faster than
any manual process can track them. This solution closes that blind spot: it **registers, scans, classifies,
and catalogs your Azure Databricks / lakehouse (Unity Catalog) assets into the Microsoft Purview Data Map,
with lineage**, so lakehouse data becomes a mapped, classified, owned part of the same governed estate as
the rest of your data.

This is a complete, do-it-today package written for an engineer bringing Databricks into Purview for the
first time. It delivers the connector workflow end-to-end — the safe **Key Vault** scan credential, the
integration-runtime network path, a bounded pilot scan of one catalog/schema, classification review,
**Unity Catalog lineage**, catalog curation, and ownership — with every artifact named once and reused
everywhere, and every scan proven on a bounded pilot before the whole metastore is touched. Because the
Purview Data Governance connectors are evolving and consumption-billed, the guide cites the method and
flags every capability "verify your licensing/tenant" rather than asserting a connector, a portal path, or
a price as permanent.

## What you get
- A plain-language Solution Overview of the Databricks connectors — **Unity Catalog** (the lineage-rich
  path this solution is written for) and **Hive metastore** (legacy) — how they scan and classify, and how
  they complement Microsoft 365 Purview.
- A Requirements Guide with verify / implement-if-missing for every prerequisite: the Purview account,
  connector confirmation, least-privilege collection roles, the Az/REST toolchain, the workspace and its
  metastore, the Key Vault scan credential, the integration-runtime network path, the stakeholders and
  classification intent, and the bounded pilot scope.
- An Implementation Guide of precise, ordered steps: design the collection/role model, establish the Key
  Vault credential and network path safely, register the Databricks source, **pilot-scan** one
  catalog/schema, review classifications and lineage, curate the catalog and assign ownership, validate
  against the gate, then expand with scheduled scans.
- Five PowerShell tools for readiness/role discovery, pilot-scope and schedule capture, Databricks source
  registration and scan configuration (`-WhatIf` by default), a CSV export of assets/classification/lineage
  coverage, and a consolidated readiness-gate check — authentic Purview data-plane REST automation with
  **no credentials in code** (the Databricks secret referenced by name only).
- Testing and Troubleshooting guides with explicit pass/fail gates, plus field-proven Best Practices.

## What this delivers
Databricks / lakehouse data governed from Purview: the Unity Catalog workspace registered into the Data
Map, scanned and classified, cataloged with lineage, and owned — validated on a pilot before you scale.

## The deployment model
Assess → Design → Configure → **Pilot (bounded scan)** → Validate → Expand — with a pilot gate before any
metastore-wide scanning.

## Outcome
The lakehouse blind spot closed — Databricks catalogs, schemas, and tables discoverable, classified,
lineage-wired, cataloged, and owned in the same Purview Data Map as the rest of the estate — with
regulatory, records, and access determinations left to the owners who make them.
