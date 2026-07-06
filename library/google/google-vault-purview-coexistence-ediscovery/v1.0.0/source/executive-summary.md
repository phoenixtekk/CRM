# Executive Summary — Vault ↔ Purview Coexistence: eDiscovery, Legal Hold & Retention

During a transition between Microsoft 365 and Google Workspace, your organization's records live in
**two governance ecosystems at once** — Microsoft Purview over the M365 estate and Google Vault over
the Workspace estate. Legal and compliance must be able to hold, retain, and discover across **both**.
The dangerous assumption is that a hold placed in one tool reaches the other. It does not. A single
custodian frequently has data on both sides, so a preservation gap here is a legal risk, not a
technical inconvenience.

This is a complete, deploy-it-in-order package for designing **Vault ↔ Purview coexistence** for
eDiscovery, legal hold, and retention — written for a competent administrator partnering with legal
and eDiscovery stakeholders. It gives you the repeatable way to establish what is governed where,
configure Google Vault retention and holds, map them to their Purview counterparts, run defensible
discovery across both systems, and prove it all on a controlled pilot before you scale.

## What you get
- A plain-language Solution Overview of the dual-ecosystem governance model — what data lives in
  Purview vs Vault during coexistence, and how holds, retention, and discovery are coordinated across
  the two (parallel holds, longer-of-two retention, most-restrictive-wins, cross-system reconciliation).
- A Requirements Guide with verify / implement-if-missing for every prerequisite — a Vault-capable
  Workspace edition, Purview eDiscovery access and licensing, legal/eDiscovery stakeholders, a
  retention policy, a matter naming convention, and a pilot custodian scope.
- An Implementation Guide of precise, ordered steps: configure Vault retention rules and holds inside
  named matters, map each to a parallel Purview eDiscovery case/hold, define the discovery workflow
  across both, validate on a pilot, then expand.
- Five PowerShell scripts for retention/hold discovery across the estate, per-scope hold and retention
  validation, a coverage/gap report, safe remediation (default `-WhatIf`), and a scope helper.
- Testing and Troubleshooting guides with explicit validation gates — holds effective, retention
  applied, discovery returns — plus Best Practices for defensible eDiscovery.

## What this delivers
Defensible eDiscovery, legal hold, and retention across **both** Google Vault and Microsoft Purview
— every custodian held and discoverable on both ecosystems, retention aligned so neither side purges a
held record, and discovery reconciled into a single production — with no compliance gap during
coexistence, proven on a pilot before you scale.

## A note on scope: technical mapping, not legal advice
This package provides the **technical** mapping of governance across Vault and Purview. Whether a
retention period, hold scope, or discovery approach satisfies a specific legal or regulatory
obligation is a determination for **legal/records counsel** — engaged here as a named stakeholder.
Vendor-specific specifics (Vault's Gemini-app hold/retention support, the evolving Purview eDiscovery
experience) are cited from current documentation or flagged **"verify in your tenant,"** never invented.

## The deployment model
**Assess → Configure → Pilot → Validate → Expand** — with a pilot gate and a rollback at every stage.

## Outcome
A coexistence governance model a single administrator can run and legal can defend at audit: what's
governed where is mapped, Vault holds and retention are configured and mirrored to Purview, discovery
runs across both and reconciles, and the whole loop is proven on a pilot custodian scope before the
full population depends on it — with legal/records counsel owning the legal determinations throughout.
