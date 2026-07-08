# Executive Summary — Microsoft Purview ITAR Compliance Program

**White-label · Purview Solutions**

The International Traffic in Arms Regulations (**ITAR**) govern **defense articles and technical data** on
the U.S. Munitions List. For a data-security program the obligation is sharp: **export-controlled
technical data must not reach unauthorized persons** — and under ITAR, giving a **foreign person** access
to technical data, even inside your own systems, is a **"deemed export"** with serious legal consequence.
Left to generic defaults, a USML drawing leaks through email, a USB drive, a browser upload, or simply a
foreign colleague's access — and an audit or voluntary disclosure finds no evidence the controls existed.

This is a complete, deploy-it-in-order package that stands up an **ITAR-aligned export-control program in
Microsoft Purview**: a **sensitivity label that encrypts and restricts technical data to authorized U.S.
persons**, a **custom classifier for your USML/ITAR markings**, **DLP that hard-blocks** export-controlled
data to unauthorized recipients (tuned in audit first, with endpoint coverage for USB/print/upload),
defensible **export-record retention**, and **export-control / NIST SP 800-171 evidence** tracked in
Compliance Manager. It is written for an administrator with no prior Purview experience.

## What you get
- A plain-language Solution Overview of the export-control program and how the label, custom SIT, auto-
  labeling, DLP, retention, and Compliance Manager work together.
- A Requirements Guide with verify / implement-if-missing for every ITAR prerequisite — including the
  **sovereign-cloud (GCC High)** and authorized-U.S.-person inputs.
- An Implementation Guide of precise, ordered steps in the Microsoft Purview portal.
- Five PowerShell scripts for posture discovery, coverage validation, a cross-control evidence report,
  safe remediation of gaps, and an authorized-person pilot-scope group builder.
- Testing and Troubleshooting guides for a confident rollout.

## What this delivers
A named, reusable set of objects — a control map, an `ITAR Evidence – Register`, a `Sensitivity Label -
ITAR Technical Data - Authorized US Persons` label, a `SIT - ITAR/USML Markers` classifier, auto-labeling
(simulated first), a `DLP Policy - ITAR Export-Controlled` policy, and export-record retention — deployed
on the assess-design-pilot model with a mandatory **DLP audit gate** before any policy enforces, a
recipient **hard-block**, and a documented rollback.

## The standard deployment model
**Assess → Design → Configure → Pilot (simulate/test) → Validate → Expand (enforce).**

## Scope boundary
The solution provides the **technical configuration and evidence**. **ITAR applicability, USML
classification, the U.S.-person determination, licenses and agreements (TAA, DSP-5, etc.), the sovereign-
cloud decision, retention schedules, and any voluntary-disclosure decision are export-control and legal
determinations** deferred to those functions.

## Outcome
Export-controlled technical data classified, encrypted to authorized U.S. persons, protected against
unauthorized recipients, retained, and evidenced with Microsoft Purview — DLP tuned in audit before it
hard-blocks, endpoint leak paths covered, and export-control / NIST 800-171 readiness — proven on a pilot
before you scale, and never widened beyond authorized persons.
