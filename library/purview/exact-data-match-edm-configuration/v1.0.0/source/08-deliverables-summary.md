# 8. Deliverables Summary — Exact Data Match (EDM) in Microsoft Purview

What you receive in this solution, and what "done" looks like.

## Documentation
| Document | What it gives you |
|---|---|
| **Solution Overview** | The EDM model — the four parts (schema, source table, hashed/uploaded data, EDM SIT), how the plaintext stays local while only hashes are uploaded, and the Assess→Design→Configure→Pilot(simulate)→Validate→Expand journey; naming convention. |
| **Requirements Guide** | Solution-specific prerequisites (EDM licensing, authoring roles, `EDM_DataUploaders` authorization, the correct-cloud Upload Agent, source data + schema design, secure host + salt/plaintext handling, consuming DLP policy, pilot ring + refresh plan) each with verify/implement steps, on top of the six category prerequisites. |
| **Implementation Guide** | The exact ordered phases: assess → design the schema with the data owner → create schema + SIT → **hash & upload with the EDM Upload Agent (plaintext stays local)** → validate the SIT → build DLP **in simulation** → enforce to a pilot ring → expand + refresh; each object named, gated, with a rollback. |
| **Testing & Validation** | Pass/fail gates for the headline outcomes — exact match on real data (A), non-match of look-alikes/not-in-data values (B), policy enforcement (C), and data-store health/refresh (D) — plus simulation-first and no-secrets checks, all with sanctioned test values. |
| **Troubleshooting Guide** | The common failure modes (SIT not matching, upload/authorization failures, indexing delays, stale data, wrong-cloud Agent, over/under-matching) and how to resolve them. |
| **Best Practices** | Plaintext/salt protection, schema design for exactness, the refresh discipline, simulate-first, where to use EDM vs pattern SITs, and operations/governance. |
| **Executive Summary** | One-page business framing for approvers. |

## PowerShell tools (5) — Security & Compliance PowerShell / Graph
All tools are **read-only or `-WhatIf` by default**; writes require an explicit `-Commit`. **No
credentials, salts, or sensitive record data are stored in or read by any script** — hashing/upload is
done only by `EdmUploadAgent.exe` on the secure host. They connect via `Connect-IPPSSession` and/or
`Connect-MgGraph`.

| # | Script | Role | Default safety |
|---|---|---|---|
| 1 | **PURVEDM-Discovery.ps1** | EDM readiness/discovery: EDM licensing signals, existing EDM schemas and EDM SITs, and the `EDM_DataUploaders` group + membership (via Graph). | Read-only |
| 2 | **PURVEDM-Schema.ps1** | Schema/rule-package helper: validates a schema XML and prints the intended `New-DlpEdmSchema` call; `-Commit` creates/updates the schema. Can emit a starter schema-XML template. | `-WhatIf` (writes need `-Commit`) |
| 3 | **PURVEDM-Validate.ps1** | Validation checker: runs sample text/values through `Test-DataClassification` against the EDM SIT to confirm exact-match + supporting-element behavior. | Read-only |
| 4 | **PURVEDM-Report.ps1** | Reporting rollup: EDM schemas, their SITs, data-store row-count/last-upload signal (optionally via `EdmUploadAgent.exe /GetDataStore` when an exe path is provided), and DLP policies referencing the EDM SIT. | Read-only |
| 5 | **PURVEDM-Set-Scope.ps1** | Scope/health helper: reports and (`-Commit`) adjusts the DLP pilot policy's included/excluded users/groups (the pilot ring); surfaces refresh-scheduling guidance. | `-WhatIf` (writes need `-Commit`) |

## Definition of done
- The **EDM schema** and **EDM SIT** created (primary/searchable element + supporting elements +
  proximity + confidence), documented and versioned.
- The sensitive data **exported, hashed, and uploaded** with the EDM Upload Agent; **plaintext securely
  deleted**; the **salt** stored in a secret store; the data store **indexed and confirmed**.
- The SIT **validated** — matches in-data values, **ignores** not-in-data / unsupported values (Gates
  A & B).
- A **DLP policy** referencing the EDM SIT **proven in simulation**, then enforced to the pilot ring
  and expanded (Gate C).
- A **refresh schedule** (re-hash + re-upload) in place so the data store stays current (Gate D).
- No-secrets and safe-by-default scripts verified; change log and data-owner/privacy sign-offs captured.

> **Boundary:** the solution delivers the technical configuration and the evidence. *Which* records are
> in scope, the **enforced action**, and the **minimisation/retention of the loaded data** are
> **compliance, privacy, and legal determinations**, captured alongside the delivered evidence.
