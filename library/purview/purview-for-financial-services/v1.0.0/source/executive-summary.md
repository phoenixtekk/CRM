# Executive Summary — Microsoft Purview for Financial Services

**White-label · Purview / Industry (FINRA · SEC · GLBA)**

Financial Services firms carry specific data-protection and books-and-records obligations — protecting
customer nonpublic personal information (NPI) under **GLBA / Reg S-P**, preserving communications and
records under **SEC Rule 17a-4 / FINRA Rule 4511** and **SEC Rule 204-2**, and supervising employee
communications under **FINRA Rule 3110**. Microsoft Purview can deliver all of this — but rolled out
carelessly, labels confuse users, Data Loss Prevention (DLP) floods advisers and traders with false
positives, retention either deletes too much or locks the wrong thing forever, and supervision creates
privacy risk.

This is a complete, deploy-it-in-order package for standing up a **Financial Services-tailored Purview
program** with a repeatable, safe method: an FS sensitivity-label taxonomy that protects NPI and MNPI,
DLP policies that start in audit and are tuned before they enforce, retention/records aligned to the
firm's schedule (with an immutability mechanism for SEC/FINRA/CFTC electronic-records rules applied
only after sign-off), and a communication-compliance program with strict role separation. It is
written for an administrator with no prior Purview experience.

## What you get
- A plain-language Solution Overview of the four capabilities — sensitivity labels, DLP, data
  lifecycle & records, communication compliance — and how they align to FINRA/SEC/GLBA.
- A Requirements Guide with verify / implement-if-missing for every FS-specific prerequisite,
  including separated communication-compliance roles.
- An Implementation Guide of precise, ordered steps in the Microsoft Purview portal.
- Five PowerShell scripts for discovery, validation, a classification/DLP report, safe remediation,
  and a pilot-scope group builder — read-only or `-WhatIf` by default, no credentials in code.
- Testing and Troubleshooting guides for a confident rollout.

## What this delivers
A named, reusable set of objects — an FS label taxonomy, auto-labeling for NPI, DLP policies,
retention labels/records, and a supervision policy — deployed on the assess-design-configure-pilot
model with a mandatory DLP audit gate before enforce, a records/legal sign-off gate before
Preservation Lock, and a documented rollback.

## Boundary
The package delivers the **technical method and evidence**, not the regulatory determination. The
record set, retention periods, regulatory-record declarations, the supervision scheme, and any
FINRA/SEC/GLBA applicability are deferred to the firm's compliance, records, privacy, and legal
functions. Purview capabilities are licensing-dependent (largely **E5 / E5 Compliance**) and the
portal evolves — verify your licensing/tenant.

## The standard deployment model
**Assess → Design → Configure → Pilot (simulate/test) → Validate → Expand (enforce).**

## Outcome
A Financial Services Purview program — NPI/MNPI protected, DLP tuned in audit before it enforces,
retention/records aligned to the firm's schedule with an immutability mechanism for SEC/FINRA/CFTC
rules, and supervision with role separation — proven on a pilot before you scale, and defensible.
