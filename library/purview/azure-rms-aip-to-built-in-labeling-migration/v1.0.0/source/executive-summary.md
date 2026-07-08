# Executive Summary — Azure RMS / AIP → Built-in Unified Labeling Migration (Microsoft Purview)

The **Azure Information Protection (AIP) add-in for Office** is being retired. Microsoft has disabled it
by default and moved to **built-in labeling** — the sensitivity-labeling experience built directly into
Word, Excel, PowerPoint, and Outlook, no add-in required. Organizations still on the add-in face a
compliance gap (labeling on a client at end of life) and a data-risk exposure (protection that may stop
working). This solution moves you off the AIP add-in, and off legacy **Azure Rights Management (RMS)
departmental templates**, to **built-in unified labeling** in Microsoft Purview — **with policy parity**,
so the labels, encryption, and behaviour your users see after the cutover match what they had before.

It gives you a repeatable, end-to-end migration: inventory the current labels, label policies, and RMS
templates; build a **parity map** from every AIP add-in feature and departmental template to its
built-in equivalent; tune **label-policy advanced settings** for behavioural parity; cut a **pilot ring**
over in a change window; validate parity against explicit pass/fail gates; then expand tenant-wide and
decommission the add-in — using only the Microsoft Purview portal, Security & Compliance PowerShell, the
AIPService protection module, Microsoft Graph, and Office client policy.

This is a complete, deploy-it-today package for a competent M365 / information-protection administrator
running the migration.

## What you get
- A plain-language Solution Overview of the AIP add-in retirement, the move to built-in labeling with
  parity, legacy RMS/template mapping, and the parity dimensions.
- A Requirements Guide with verify / implement-if-missing for every prerequisite — licensing, roles,
  the S&C PowerShell + AIPService + Graph toolchain, RMS activation, Office builds, and the client-policy
  delivery mechanism.
- An Implementation Guide of precise, ordered portal + PowerShell + client-policy steps, applied
  pilot-first, with each label, feature, template, and policy named.
- Five PowerShell scripts: estate inventory, a label-policy advanced-settings helper (`-WhatIf` by
  default), a parity check, a migration/parity report, and an RMS/scope-health helper.
- Testing and Troubleshooting guides for a confident, safe cutover.

## What this delivers
An inventoried estate; a parity map that leaves no label, feature, or template unaccounted for;
label-policy settings that reproduce the add-in behaviour; a pilot ring cut over to built-in labeling
with the add-in gone; encryption, custom permissions, and departmental-template protection reproduced;
previously protected content still opening; and a validated, evidenced expansion tenant-wide.

## The deployment model
Assess → Design → Configure → Pilot → Validate → Expand — with high-impact cutover changes piloted on a
ring and validated before enforcement.

## Scope boundary
This is a **migration**, not a taxonomy or auto-labeling project. Designing new labels, authoring
auto-labeling or DLP, and standing up the Information Protection scanner are separate Purview solutions.
Feature availability and minimum Office builds are licensing-/build-dependent and cited or flagged
"verify your version/licensing," never invented. Whether a legacy departmental template still applies is
a records/compliance determination, deferred to the organization's compliance, records, privacy, and
legal functions — this solution provides the technical method and evidence, not the determination.

## Outcome
Off the retiring AIP add-in and legacy RMS templates, onto built-in unified labeling in Microsoft
Purview — with parity, piloted, validated, and defensible.
