# Executive Summary — Microsoft Purview CMMC Compliance Program

**White-label · Purview Solutions**

For organizations in the Defense Industrial Base, **CMMC** is no longer optional: handling Controlled
Unclassified Information (CUI) means implementing — and **evidencing** — the **110 security requirements
of NIST SP 800-171** that underpin **CMMC Level 2**, and eventually proving it to a **C3PAO** assessor.
The common failure is not a lack of controls; it is a lack of a **measured, owned, evidenced record** of
them. "Are we compliant?" gets a shrug instead of a number, and the gaps surface during the assessment
rather than before it.

This is a complete, deploy-it-in-order package for standing up a **Purview-backed CMMC compliance
program** using **Microsoft Purview Compliance Manager**. It uses the **CMMC Level 2 / NIST SP 800-171
assessment template** to turn CMMC into a **measured posture**, maps each requirement to the control and
improvement action that satisfies it, assigns owners, attaches evidence, and validates the technical
evidence from your Microsoft 365 configuration — piloted on a single assessment first, validated, then
expanded. It is written for an administrator with no prior Compliance Manager experience and uses only
the Microsoft Purview portal, Security & Compliance PowerShell, and Microsoft Graph.

## What you get
- A plain-language Solution Overview of Compliance Manager, the CMMC/NIST 800-171 template, control
  mapping, evidence, and the role-separation model — and how they work together.
- A Requirements Guide with verify / implement-if-missing for every prerequisite, including licensing,
  cloud (Commercial vs GCC/GCC High), roles, and the CUI boundary/SSP.
- An Implementation Guide of precise, ordered steps in the Purview portal and PowerShell/Graph.
- Five PowerShell scripts: readiness/role discovery, technical-signal validation, a posture report, a
  safe (`-WhatIf`) action-plan/control-map/evidence builder, and a least-privilege role-scope tool.
- Testing and Troubleshooting guides for a confident rollout.

## What this delivers
A named, reusable program — a CMMC Level 2 / NIST 800-171 assessment, an owned improvement-action plan,
a requirement-to-action **control map**, an evidence register, and least-privilege role separation —
deployed on the assess-design-configure-pilot model with technical remediation piloted in
simulation/test, and a maintained posture report.

## The standard deployment model
**Assess → Design → Configure → Pilot (simulate/test) → Validate → Expand.**

## What this does not do
This program **measures and evidences**; it does **not** issue a CMMC certification, produce a formal
assessment determination, or compute your **SPRS** score. **CMMC applicability, the target level,
evidence adequacy, scoring, and certification are deferred to the C3PAO and to your compliance,
security, and legal functions.** The high-impact technical changes an action recommends are separate,
piloted changes owned by their own solution.

## Outcome
A defensible, evidenced CMMC program in Microsoft Purview — requirements mapped to configured controls,
technical evidence validated, and a maintained posture proven on a pilot before you scale toward the
C3PAO assessment.
