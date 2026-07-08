# Executive Summary — Microsoft Purview for Retail

**White-label · Industry (Retail · PCI-DSS)**

Retail runs on customer data — names, contact and address details, purchase and loyalty history — and
touches payment card data at every point of sale. That combination carries specific obligations:
**PCI-DSS** for cardholder data and privacy law for customer personal data. The common failure is not
a lack of tools but data that is never classified, never contained, and never retained on a defined
schedule — so a stray Primary Account Number (PAN) ends up in an email or a SharePoint site, quietly
pulling a general-productivity system into PCI scope, and customer data leaves through an endpoint
nobody was watching.

This is a complete, deploy-it-in-order package that configures **Microsoft Purview** into a
**Retail-tailored data-protection program**: a small sensitivity-label taxonomy, auto-labeling that
maps where cardholder data actually lives, **Data Loss Prevention** built from Microsoft's PCI-DSS and
PII templates and tuned in audit before it blocks, retention that meets the retail records schedule
while minimizing payment-data storage, and a **PCI-DSS compliance baseline** in Compliance Manager for
evidence. It is written for an administrator with no prior Purview experience.

## The retail posture — stated plainly
For most retailers, Microsoft 365 should stay **out** of PCI-DSS scope. This solution uses Purview to
**keep it that way** — detecting and blocking PAN from landing in email, collaboration, and endpoints —
while **protecting and retaining** the customer PII that legitimately does live there. Purview does not
turn Microsoft 365 into a certified cardholder-data environment; the segmented payment environment
stays separate. **PCI scope, applicable requirements, and retention periods are compliance/QSA/records
determinations** — this package delivers the technical configuration and the evidence, not the ruling.

## What you get
- A plain-language Solution Overview of the retail Purview program and how its parts work together.
- A Requirements Guide with verify / implement-if-missing for every retail-/PCI-specific prerequisite.
- An Implementation Guide of precise, ordered steps in the Microsoft Purview portal.
- Five PowerShell scripts: discovery, a safe configuration/remediation helper (`-WhatIf` first),
  validation, a classification/DLP coverage report, and a pilot-scope/health helper.
- Testing and Troubleshooting guides for a confident rollout.

## The standard deployment model
**Assess → Design → Configure → Pilot (simulate/test) → Validate → Expand (enforce)** — with a
mandatory DLP audit gate before any policy blocks, auto-labeling simulated before it labels, retention
piloted before it deletes, and a documented rollback.

## Outcome
A Retail-tailored Purview program that is configured, piloted, validated, and evidenced against
PCI-DSS — cardholder data blocked from Microsoft 365, customer PII protected and retained, and the
program defensible to an auditor — proven on a pilot before you scale.
