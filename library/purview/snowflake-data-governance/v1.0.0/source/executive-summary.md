# Executive Summary — Snowflake Data Governance: Microsoft Purview

Snowflake is often the largest concentration of governed data in the estate — and the biggest blind spot in
the data catalog. If Snowflake isn't in **Microsoft Purview**, you can't see what sensitive data it holds,
can't classify it, and can't answer "where is our customer PII?" for the platform that has the most of it.
This solution closes that gap by bringing Snowflake into the **Purview Data Map and Catalog** — registered,
scanned, and classified — configured, piloted on a limited scope, validated, and defensible.

This is a complete, do-it-today package written for an administrator onboarding Snowflake to Purview for
the first time. It delivers the capability end-to-end — from reading the Data Map's collections and
integration runtimes, through preparing a **Key Vault-backed credential** (never a secret in a script),
registering the source, and running the scan on **one pilot database**, to validating assets and
classifications and only then expanding, scheduling, and curating — with every collection, source, scan,
credential, and pilot scope named once and reused everywhere. Because Purview Data Governance has its own
consumption model and the connector experience is **evolving**, the guide cites the method and flags every
capability "verify your licensing/tenant" rather than asserting a step or a cost as permanent.

## What you get
- A plain-language Solution Overview of Snowflake cataloging — register, scan, classify, curate — and how
  it differs from DLP and protection.
- A Requirements Guide with verify / implement-if-missing for every prerequisite: a Purview account with
  Data Governance, least-privilege collection roles, the Az/REST toolchain, the network path and
  integration runtime, a **Key Vault-backed** scanning credential (no secrets in code), the in-scope
  databases and pilot scope, and the classification scheme with data owners.
- An Implementation Guide of precise, ordered steps: assess, design the approach, prepare the credential and
  register the source, create and run the scan on a **pilot database**, validate assets and classifications,
  then expand, schedule, and curate.
- Five PowerShell tools — Discovery, a prerequisite/health helper, a safe Registration/Scan tool (`-WhatIf`
  by default; credential referenced by name from Key Vault), Validation, and Reporting — built on
  PowerShell/REST against Purview and Azure, **read-only or `-WhatIf` by default with no credentials in
  code**.
- Testing and Troubleshooting guides with explicit pass/fail gates, plus field-proven Best Practices.

## What this delivers
Snowflake governed from Purview: registered in the Data Map, scanned on a schedule, and its sensitive
assets classified in the catalog — proven on a pilot database before scanning the account, with the
credential Key Vault-backed and no secret in code.

## The deployment model
Assess → Design → Configure → **Pilot (one database)** → Validate → Expand — with a pilot gate before the
account and scans scheduled only after validation.

## Outcome
The Snowflake catalog blind spot closed — the largest data store visible, scanned, and classified in
Purview — with the credential Key Vault-backed and the classification scheme, data ownership, and glossary
left to the data-governance owners who make them.
