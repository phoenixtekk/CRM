# Executive Summary — Oracle Data Governance: Microsoft Purview

Most data-governance efforts stop at Microsoft 365, and the Oracle estate — customer masters, ERP and
line-of-business schemas, data-warehouse staging — sits outside the map, unclassified and ungoverned.
You cannot protect, retain, or grant access to data you cannot see. This solution closes that blind
spot: it **registers, scans, and classifies your Oracle databases into the Microsoft Purview Data
Map**, so Oracle data becomes a mapped, classified, owned part of the same governed estate as the rest
of your data.

This is a complete, do-it-today package written for an engineer bringing Oracle into Purview for the
first time. It delivers the Oracle connector workflow end-to-end — a least-privilege read-only database
login, a **Key Vault** credential referenced by name, a **self-hosted integration runtime** with the
Oracle JDBC driver, a bounded pilot scan, classification review, and ownership — with every artifact
named once and reused everywhere, and every scan proven on a bounded pilot before the Oracle estate is
touched. Because the Purview connectors are evolving and consumption-billed, the guide cites the method
and flags every capability "verify your licensing/tenant" rather than asserting a connector, a
supported version, or a price as permanent.

## What you get
- A plain-language Solution Overview of the Oracle source — how Purview reaches Oracle (host/service on
  the listener port through a SHIR), how it authenticates (Basic auth via a Key Vault secret referenced
  by name), how it scans and classifies schemas/tables/columns, and how it complements Microsoft 365
  Purview.
- A Requirements Guide with verify / implement-if-missing for every prerequisite: the Purview account,
  connector and version support, least-privilege collection roles, the Oracle inventory with owners, a
  least-privilege read login, the Key Vault credential, the SHIR + network path + JDBC driver, a
  classification approach, and the pilot scope.
- An Implementation Guide of precise, ordered steps: design the collection/role model, create the read
  login, establish the Key Vault credential and SHIR/network/driver safely, register the Oracle source,
  **pilot-scan** a bounded set of schemas, review classifications, assign ownership, validate against
  the gate, then expand with scheduled scans.
- Five PowerShell tools for readiness/role discovery, pilot-scope capture, Oracle source registration
  and scan configuration (`-WhatIf` by default), a scan-and-classification coverage report, and a
  consolidated readiness-gate check — authentic Purview data-plane REST automation with **no
  credentials in code** (the Oracle secret referenced by Key Vault name only).
- Testing and Troubleshooting guides with explicit pass/fail gates, plus field-proven Best Practices.

## What this delivers
Oracle data governed from Purview: databases and schemas registered into the Data Map, scanned and
classified, and owned — validated on a pilot before you scale.

## The deployment model
Assess → Design → Configure → **Pilot (bounded scan)** → Validate → Expand — with a pilot gate before
any Oracle-wide scanning.

## Outcome
The Oracle blind spot closed — databases and schemas discoverable, classified, owned, and governed in
the same Purview Data Map as the rest of the estate — with regulatory, records, and access
determinations left to the owners who make them.
