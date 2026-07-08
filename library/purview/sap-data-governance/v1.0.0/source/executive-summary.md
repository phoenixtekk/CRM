# Executive Summary — SAP Data Governance: Microsoft Purview

Most data-governance efforts stop at Microsoft 365, and SAP — customer master data, financial
documents, HR and payroll records, material and vendor data — sits outside the map, unclassified and
ungoverned. You cannot protect, retain, or grant access to data you cannot see. This solution closes
that blind spot: it **registers, scans, and classifies your SAP sources into the Microsoft Purview
Data Map**, so SAP becomes a mapped, classified, owned part of the same governed estate as the rest of
your data.

This is a complete, do-it-today package written for an engineer bringing SAP into Purview for the first
time. It delivers the SAP connector workflow end-to-end — the **self-hosted integration runtime**, the
**SAP-provided driver** (SAP JCo for ECC/S/4HANA/BW, HANA JDBC for HANA), a **least-privilege SAP read
user** whose secret lives in **Azure Key Vault**, a bounded pilot scan, classification review, and
ownership — with every artifact named once and reused everywhere, and every scan proven on a bounded
pilot before the SAP estate is touched. Because the Purview connectors are evolving and
consumption-billed, the guide cites the method and flags every capability "verify your
licensing/tenant" rather than asserting a connector, a driver version, or a price as permanent.

## What you get
- A plain-language Solution Overview of the SAP sources — SAP ECC / S/4HANA / BW (over RFC using the
  SAP JCo driver on a SHIR) and SAP HANA (over JDBC) — how they scan and classify SAP **metadata**, and
  how they complement Microsoft 365 Purview.
- A Requirements Guide with verify / implement-if-missing for every prerequisite: the Purview account,
  connector availability, least-privilege collection roles, the SAP system inventory with owners, the
  SHIR, the SAP driver + Java runtime, the least-privilege SAP login held in Key Vault, a classification
  approach, and the pilot scope.
- An Implementation Guide of precise, ordered steps: design the collection/role model, stand up the
  SHIR + SAP driver, establish the SAP credential safely, register the SAP source, **pilot-scan** a
  bounded set, review classifications, assign ownership, validate against the gate, then expand with
  scheduled scans.
- Five PowerShell tools for readiness/role discovery, pilot-scope capture, SAP source registration and
  scan configuration (`-WhatIf` by default), a scan-and-classification coverage report, and a
  consolidated readiness-gate check — authentic Purview data-plane REST automation with **no
  credentials in code** (the SAP secret is referenced by name only).
- Testing and Troubleshooting guides with explicit pass/fail gates, plus field-proven Best Practices.

## What this delivers
SAP data governed from Purview: SAP systems registered into the Data Map, scanned and classified, and
owned — validated on a pilot before you scale.

## The deployment model
Assess → Design → Configure → **Pilot (bounded scan)** → Validate → Expand — with a pilot gate before
any SAP-wide scanning.

## Outcome
The SAP blind spot closed — SAP systems discoverable, classified, owned, and governed in the same
Purview Data Map as the rest of the estate — with regulatory, records, and access determinations left
to the owners who make them.
