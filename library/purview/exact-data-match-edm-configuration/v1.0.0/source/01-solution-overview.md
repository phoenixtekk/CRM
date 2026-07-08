# Solution Overview — Exact Data Match (EDM) in Microsoft Purview

## What this solution delivers

Pattern-based classifiers are guessers. A built-in **Credit Card Number** or **U.S. SSN** detector
fires on *anything shaped like* a card number or an SSN — including test data, a colleague's own SSN,
or a random nine-digit string — so it over-matches, floods triage with false positives, and gets
tuned down or turned off. **Exact Data Match (EDM)** replaces the guess with certainty: it matches on
**your actual records** — the exact account numbers, patient IDs, or customer rows in *your*
database — and matches on nothing else. The result is a sensitive information type (SIT) with a
**near-zero false-positive rate** that you can safely enforce.

This solution walks a competent-but-novice administrator through a **complete, repeatable EDM
deployment** in Microsoft Purview:

1. **Design the schema** — define the structure of the sensitive data (the columns, which field is
   the **primary/searchable element**, which are **supporting elements**, and the per-field
   configurable-match options).
2. **Prepare the sensitive-data source** — export the actual records to a delimited (`.csv`/`.tsv`)
   file whose header row matches the schema.
3. **Hash and upload the data with the EDM Upload Agent** — the source records are **hashed and
   salted on your own machine** by `EdmUploadAgent.exe`; **only the one-way hashes leave your
   environment** — the plaintext sensitive data is **never** uploaded to the service.
4. **Create the EDM sensitive information type** — a SIT that references the schema, requires an
   **exact match on the primary element** (against the uploaded hashes) plus **supporting elements
   in proximity**, at a defined confidence.
5. **Wire it into a policy and pilot in SIMULATION** — use the EDM SIT in a **DLP policy** (and,
   optionally, auto-labeling / retention) run in **simulation/test first**, validate, then enforce.
6. **Operate the refresh** — keep the hashed data current on a schedule, because a stale EDM data
   store silently degrades matching.

Together these turn a **noisy, pattern-based guess** into an **exact, evidence-backed** detector:
strong where it needs to be, silent everywhere else — configured, piloted, validated, and defensible.

## How EDM keeps your data safe — read this first

EDM is **privacy-preserving by design**, and understanding why is central to deploying it correctly:

- **The plaintext never leaves your tenant boundary.** `EdmUploadAgent.exe` runs **on a machine you
  control**, reads the source file locally, and computes a **salted one-way hash** of each cell.
  Only those hashes (plus the schema metadata) are uploaded. Microsoft's service stores **hashes,
  not values** — it cannot reconstruct the original records from them.
- **You own the salt.** You supply (or let the agent generate) a **salt** used in the hashing. Keep
  it secret and consistent — it is part of what makes the hashes non-reversible and is required to
  re-hash matching data later.
- **The source data is real sensitive data — handle it as such.** The `.csv`/`.tsv` export contains
  live records (account numbers, IDs, PII). Generate it under change control, keep it on an
  access-controlled host, hash it, and **securely delete the plaintext export** when done. **Which
  data is lawful to load, and its retention, are privacy/compliance/legal determinations** — this
  solution provides the technical method and the guardrails, not the determination (see
  `global-requirements-purview.md` §5).

> **Deploy this with your data owners, privacy, and compliance stakeholders.** EDM loads a hashed
> copy of a real records set into a Microsoft service; the **applicability, minimisation, and
> retention of that data** are governance decisions for your organization.

## The EDM model — how the pieces fit

EDM has **four moving parts**. Get their relationship right and the rest is mechanical:

- **1. The EDM schema (the data store definition).** An XML/portal-defined structure listing the
  **fields** (columns) in your sensitive data. Each field can be marked:
  - **Searchable / primary element** — a field EDM builds a fast lookup index on; a document must
    contain an **exact match to one of these** to be a candidate. At least one field must be
    searchable.
  - **Configurable match** per field — **ignore case** and/or **ignore delimiters** (so a stored
    `123-45-6789` still matches a document's `123456789`).
- **2. The sensitive information source table (your data).** A delimited file (`.csv` or `.tsv`)
  whose **first row is the field names** (matching the schema) and each subsequent row is one record.
  The data store name ties this file to its schema.
- **3. The hashed & uploaded data.** `EdmUploadAgent.exe` hashes the source table locally and uploads
  the hashes to the EDM service's **data store** for that schema. This is what documents are matched
  against — and it must be **refreshed** as the underlying data changes.
- **4. The EDM sensitive information type (the SIT / rule package).** The classifier that references
  the schema and says: *"match when a document contains an exact value from the **primary element**
  index **and** N **supporting elements** within a **proximity window**, at confidence X."* This SIT
  then behaves like any other SIT — usable in DLP, auto-labeling, retention, Communication
  Compliance, eDiscovery, and Insider Risk.

> **Two authoring paths.** The **Microsoft Purview portal** *Exact data match (EDM)* wizard creates
> the **schema and the SIT together** and is the recommended path. The equivalent **PowerShell/XML**
> path (`New-DlpEdmSchema`, `New-DlpSensitiveInformationTypeRulePackage`) is available for
> repeatable, source-controlled definitions. **The hashing/upload step is always the EDM Upload
> Agent** — there is no portal upload of plaintext. Portal paths and schema limits (field counts,
> row/size caps) **evolve and are licensing-dependent — verify against Microsoft Learn and your
> tenant** rather than assuming.

## The standard deployment model

Every step follows the same repeatable model, with an explicit **pass/fail gate** between phases:

**Assess → Design → Configure → Pilot (simulation/test) → Validate → Expand (enforce).**

- **Assess** — confirm licensing (**E5 / E5 Compliance / Information Protection & Governance** for
  EDM), the EDM/authoring roles, the **EDM_DataUploaders** authorization, the in-scope data source,
  and data-owner/privacy sign-off.
- **Design** — define the schema (fields, primary vs supporting, configurable match), the SIT logic
  (primary element + supporting elements + proximity + confidence), the source-file export, the DLP
  pilot policy, and **name every object** — with the data owners.
- **Configure** — create the schema and SIT, then hash-and-upload the data with the Upload Agent, and
  confirm the data store indexed.
- **Pilot** — build the DLP policy in **simulation/test**, scoped to a pilot ring, and confirm it
  *would* match on real values without blocking anyone.
- **Validate** — run the pass/fail gates in `05-testing.md` (exact match hits, near-miss correctly
  ignored, supporting-element/proximity behavior, false-positive rate).
- **Expand** — enforce to the pilot ring, widen deliberately, and stand up the **refresh schedule**.

## What's in the box

- This overview, a **Requirements** guide, an ordered **Implementation** guide, **Testing** (pass/fail
  gates), **Troubleshooting**, **Best Practices**, and a **Deliverables Summary** + **Executive
  Summary**.
- **Five PowerShell tools** (Security & Compliance PowerShell / Graph, wrapping the EDM Upload Agent
  where relevant): an EDM **readiness/discovery** assessment, a **schema/rule-package** helper
  (`-WhatIf` first), a **validation** checker (test values against the SIT), a **reporting** rollup
  (schemas, SITs, data-store/refresh status, referencing policies), and a **scope/health** helper —
  read-only or `-WhatIf` by default; **no credentials, salts, or sensitive data in code**.

> **Sources:** Microsoft Learn — *Learn about exact data match based sensitive information types*,
> *Get started with exact data match based sensitive information types* (schema, EDM Upload Agent,
> hashing/upload, refresh), *Create custom sensitive information types with EDM*, and the DLP
> simulation-mode documentation. EDM is **licensing-dependent** (Microsoft 365 **E5 / E5 Compliance /
> Information Protection & Governance**) and the Purview portal, schema limits, and Upload Agent
> switches **evolve** — **verify capability, limits, and portal paths against your licensing/tenant**
> rather than assuming.
