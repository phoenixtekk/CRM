# Executive Summary — Microsoft Purview for Healthcare (HIPAA/PHI)

**White-label · Purview / Industry (Healthcare)**

Healthcare runs on protected health information (PHI), and PHI leaks and retention gaps almost always
trace back to the same root: data that is never classified, never protected, and never retained on a
defined schedule. Microsoft Purview fixes that — but rolled out generically it confuses clinicians,
floods the help desk with Data Loss Prevention (DLP) false positives, and — worst of all — can block
legitimate care coordination or break a clinical app. This solution delivers Purview **tuned for a PHI
data estate**, on a pilot-first model so patient care is never disrupted.

This is a complete, deploy-it-in-order package for implementing a **Healthcare-tailored Microsoft
Purview program** aligned to HIPAA/PHI: a PHI-aware sensitivity-label taxonomy with auto-labeling, DLP
built on the built-in **U.S. Health Insurance Act (HIPAA)** template that starts in audit and is tuned
before it enforces, and retention/records driven by **your** records schedule. It is written for an
administrator with no prior Purview experience.

## What you get
- A plain-language Solution Overview of PHI sensitivity labels, auto-labeling, DLP across Microsoft
  365 and endpoints, and retention/records — and how they work together for a PHI estate.
- A Requirements Guide with verify / implement-if-missing for every Healthcare/PHI prerequisite —
  including licensing, least-privilege roles, and a clinical-continuity / emergency-access plan for
  label encryption.
- An Implementation Guide of precise, ordered steps in the Microsoft Purview portal.
- Five PowerShell scripts for configuration discovery, coverage validation, a PHI classification and
  DLP-event report, safe remediation of gaps, and a PHI pilot-scope group builder.
- Testing and Troubleshooting guides for a confident, clinician-safe rollout.

## What this delivers
A named, reusable set of objects — a PHI sensitivity-label taxonomy, label policies, an auto-labeling
policy, a HIPAA DLP policy, and retention labels/policies — deployed on the assess-configure-pilot
model with a mandatory DLP audit gate before any policy switches to enforce, and a documented rollback.

## Scope boundary
Regulatory, records-retention, and legal determinations — which data is a designated record set, how
long medical records must be kept (state law, records schedule), records file plans, legal holds, and
insider-risk / communication-compliance case actions — are **deferred to your compliance, records,
privacy, and legal functions**. The solution provides the technical method and the evidence, not the
determination. Purview features are **licensing-/plan-dependent and evolving — verify your
licensing/tenant.**

## The standard deployment model
**Assess → Design → Configure → Pilot (simulate/test) → Validate → Expand (enforce).**

## Outcome
PHI classified, protected, and retained with Microsoft Purview — a clear PHI label taxonomy with
auto-labeling, HIPAA DLP tuned in audit before it enforces, and retention that meets your records
schedule — proven on a pilot before you scale, and defensible in an audit.
