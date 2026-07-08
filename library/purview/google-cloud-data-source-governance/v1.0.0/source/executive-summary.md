# Executive Summary — Google Cloud Data-Source Governance: Microsoft Purview

Most data-governance efforts stop at Microsoft 365. But some of the data that carries the most risk —
customer records, financial extracts, analytics tables — lives in **Google Cloud**, outside M365,
ungoverned and unclassified. You cannot protect, retain, or grant access to data you cannot see. This
solution implements a focused slice of the **data-estate** side of Microsoft Purview: **registering,
scanning, and classifying Google BigQuery in the Purview Data Map** — so Google Cloud data becomes a
mapped, classified, owned part of your governed estate, not a blind spot.

This is a complete, do-it-today package written for an engineer standing up the Google Cloud connector
in Purview Data Governance for the first time. Every artifact is named once and reused everywhere, the
service-account key lives in Azure Key Vault (never in code), and every scan is proven on a bounded
pilot before the estate is touched. Because the Purview Data Governance experience is evolving and its
features are consumption-billed, the guide cites the method and flags every capability "verify your
licensing/tenant" rather than asserting a path, an IAM role, or a price as permanent.

## What you get
- A plain-language Solution Overview of the Google BigQuery connector workflow — the Data Map,
  collections and roles, the service-account credential path, the self-hosted integration runtime, and
  scanning + classification — and how it complements Microsoft 365 Purview.
- A Requirements Guide with verify / implement-if-missing for every prerequisite: the Purview account,
  connector availability, least-privilege collection roles, BigQuery projects/datasets with owners, a
  read-only service account with its key in Key Vault, the SHIR and network path, a classification
  approach, and the pilot scope.
- An Implementation Guide of precise, ordered steps: design the collection/role model, establish the
  service-account credential and SHIR safely, register and **pilot-scan** a bounded BigQuery scope,
  review classifications, assign ownership, validate against the gate, then expand with scheduled
  scans.
- Five PowerShell tools for readiness/role discovery, pilot-scope capture, source registration and
  scan configuration (`-WhatIf` by default), a scan-and-classification coverage report, and a
  consolidated readiness gate — authentic Purview data-plane REST automation with **no credentials in
  code**.
- Testing and Troubleshooting guides with explicit pass/fail gates, plus field-proven Best Practices.

## What this delivers
Google Cloud data mapped into the Purview Data Map: BigQuery datasets and tables scanned and
classified, with named owners and a pilot-proven scan pattern — validated on a bounded scope before
you scale.

## The deployment model
Assess → Design → Configure → **Pilot (bounded scan)** → Validate → Expand — with a pilot gate before
any estate-wide scanning.

## Outcome
Google Cloud data discoverable, classified, and owned in the same governed map as the rest of the
estate — far beyond Microsoft 365 — with regulatory, records, and access determinations left to the
owners who make them.
