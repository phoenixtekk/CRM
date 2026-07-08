# Executive Summary — Data Lineage Implementation (Microsoft Purview)

"Where did this number come from, and what breaks if we change it?" is a question most data programs
cannot answer with evidence. Without **data lineage**, nobody can trace a report back to its sources or
forward to its consumers — which is both a compliance exposure and an operational risk every time a
source changes or a data-quality issue surfaces. This solution implements **data lineage in Microsoft
Purview**, end to end, so that for the in-scope estate data can be traced **source → report and back**,
defensibly.

It gives you a repeatable way to stand lineage up on the **Microsoft Purview Data Map / Unified
Catalog**: register and scan the in-scope sources so assets exist as lineage endpoints, **connect the
integration systems** (Azure Data Factory, Synapse, Data Share, Power BI) that report lineage
automatically, **push custom lineage** through the Apache Atlas–compatible catalog API for the systems
that don't self-report, and **visualize and validate** the resulting graph — using only the Purview
portal and PowerShell/REST against the documented Azure Purview data-plane APIs, with no credentials
stored in code.

This is a complete, deploy-it-today package for implementing data lineage, written for a competent
Azure/Purview data-governance administrator.

## What you get
- A plain-language Solution Overview of lineage in the Purview Data Map, the capture model (automatic
  connectors vs. custom Atlas lineage), and the phased approach.
- A Requirements Guide with verify / implement-if-missing for every prerequisite — the Purview Data
  Governance account, least-privilege data-plane roles, the Az + REST toolchain, and registered/scanned
  sources.
- An Implementation Guide of precise, ordered portal + PowerShell/REST steps, with lineage connected and
  pushed **pilot-first** and every asset named by qualified name.
- Five PowerShell scripts: source/scan/lineage-capability discovery, a custom-lineage push helper
  (`-WhatIf` by default), a lineage-graph validator, a coverage report, and a scope/health helper.
- Testing and Troubleshooting guides for a confident, safe rollout.

## What this delivers
In-scope sources registered and scanned into the Data Map, automatic lineage flowing from the connected
integration systems, custom lineage pushed for the systems that don't self-report, the graph validated
for **correctness** (not just presence) on a pilot scope, and **coverage measured** against the
governance target so gaps are explicit and closed deliberately.

## The deployment model
Assess → Design → Configure → Pilot → Validate → Expand.

## Scope boundary
This solution delivers **lineage** on the Data Map foundation. Building the classification/label
program, DLP, retention/records, insider risk, and communication compliance are each the subject of a
dedicated Purview solution and are not duplicated here. Data lineage is a **Data Governance (Data Map)**
capability — separately provisioned and Azure-metered, distinct from Microsoft 365 E5 compliance; verify
the current provisioning model, pricing, roles, and portal paths against Microsoft's documentation and
your own tenant. What lineage coverage is *required* for a regulatory/records obligation, and which
source is *authoritative* for a data element, are deferred to the data-governance, records, privacy, and
legal functions — this solution provides the technical capability, the graph, and the coverage evidence,
not the determination.

## Outcome
Data lineage implemented in Microsoft Purview the right way — sources scanned, integration systems
connected, custom lineage pushed where needed, the graph validated and coverage measured — so your
organization can trace data from source to report and back, and answer "what breaks if we change this?"
with a graph instead of a guess.
