# Executive Summary — Software Discovery & Entitlement Reconciliation (SCCM / Intune / Flexera)

Discovery tools tell you what is installed. They do not tell you whether you own it. Raw inventory
arrives as thousands of unnormalized titles, editions, and versions that map to no SKU and link to
nothing you actually bought — so the question that matters, "are we compliant and where can we
reharvest?", goes unanswered.

This package turns software discovery into a reconciled license position. It is a complete,
do-it-today method for pulling installed-software data from Configuration Manager, Microsoft Intune,
or a discovery tool such as Flexera, normalizing the noise into clean SKUs, mapping those SKUs to
your entitlements, and producing the reconciliation that drives compliance decisions and reharvesting.
It is written for a Software Asset Management (SAM) analyst with no prior reconciliation pipeline.

## What you get
- A plain-language Solution Overview of discovery sources, software normalization, the entitlement
  reconciliation model, and how the output feeds compliance and optimization.
- A Requirements Guide with verify / implement-if-missing for every prerequisite. Vendor-specific
  Flexera setup is deferred to the vendor's documentation.
- An Implementation Guide of precise, ordered steps: confirm inventory, export installed-software
  data, normalize titles/editions/versions to SKUs, map to entitlements, reconcile and flag
  exceptions, then pilot, validate, and expand to more sources.
- Five PowerShell scripts for installed-software discovery, normalization/mapping validation, a
  reconciliation and exception report, safe remediation of mapping gaps, and a discovery-scope group
  builder.
- Testing and Troubleshooting guides with explicit pass/fail gates, plus field-proven Best Practices.

## What this delivers
A repeatable reconciliation pipeline: discovery from one or more sources, normalized into a single
SKU vocabulary, matched against an authoritative entitlement count, with every unmatched install
routed to an exception register for decision. Proven on a one-source pilot before it scales.

## The deployment model
**Assess → Configure → Pilot → Validate → Expand.**

## Outcome
Raw software discovery turned into a clean, reconciled license position — normalized, mapped to
entitlements, exceptions flagged — the foundation for compliance and reharvesting, proven on a pilot
before you scale.
