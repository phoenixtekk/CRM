# Executive Summary — Zero Trust Architecture: Conditional Access Baseline & Rollout

White-label · Entra ID Solutions · Government (GCC High) edition

This is the **Government (GCC High)** edition for US public-sector and defense-industrial-base tenants operating in **Microsoft Entra for GCC High / Azure Government**. It mirrors the commercial method exactly, adapted for the sovereign cloud — the Azure Government portal (`portal.azure.us` → Microsoft Entra ID), Azure Government sign-in (`login.microsoftonline.us`), the GCC High Graph host (`graph.microsoft.us`; DoD/IL5 `dod-graph.microsoft.us`), and PowerShell targeting the US Gov cloud (`Connect-MgGraph -Environment USGov`). It is the direct answer to the **federal Zero Trust mandate — OMB M-22-09** (phishing-resistant MFA, Zero Trust architecture aligned to the CISA Maturity Model and NIST SP 800-207) and to **CMMC 2.0 / NIST SP 800-171** access-control expectations for the DIB. Because parity in GCC High/DoD can lag commercial — notably risk-based CA (Entra ID P2 / Identity Protection) — every such capability is flagged to **verify against current Microsoft Government documentation** (see the included `gcc-high-parity-notes.md`).

Zero Trust starts at identity, and in Microsoft Entra the engine that enforces it is Conditional
Access (CA). Every sign-in is evaluated against policy — who you are, what device you are on, how
risky the sign-in looks — and access is granted only when the conditions are met. Done well, CA is
the strongest control you have. Done carelessly, a single overbroad policy locks the whole tenant out
of its own directory. The difference is method: personas, report-only validation, break-glass
protection, and a staged rollout.

This is a complete, deploy-it-today package for designing and rolling out a Conditional Access
baseline in Microsoft Entra, written for an administrator with no prior CA-architecture experience.
It gives you a repeatable way to define access personas, build a numbered set of baseline policies
(MFA, compliant/hybrid device, risk-based, session controls, block legacy auth), validate every one
of them in **report-only** with the What-If tool before it can block anyone, and enforce them in
waves with break-glass accounts and a rollback path.

## What you get
- A plain-language Solution Overview of the Conditional Access model — signals, conditions, grant and
  session controls, authentication strengths, report-only mode, and the persona approach to Zero
  Trust.
- A Requirements Guide with verify / implement-if-missing for every solution-specific prerequisite.
- An Implementation Guide of precise, click-by-click Entra steps that builds a named, numbered
  baseline and rolls it out report-only -> validate -> enforce, wave by wave.
- Five PowerShell scripts for CA and persona discovery, report-only impact reporting, baseline policy
  creation (preview by default), persona-group targeting, and a validation check.
- Testing and Troubleshooting guides for a confident, staged rollout.

## What this delivers
A production Zero Trust Conditional Access baseline — personas defined for admins, internal staff,
external/guest users, and service accounts; a numbered set of baseline policies enforcing MFA,
device compliance, risk-based access, and session controls; every policy proven in report-only and
What-If before enforcement; break-glass accounts excluded throughout; and a wave-based rollout with a
one-click rollback — deployed without ever locking out the tenant.

## The standard deployment model
Assess -> Configure -> Pilot -> Validate -> Expand.

## Outcome
Least-privilege, Zero Trust access enforced at the identity plane — a clean, numbered Conditional
Access baseline rolled out safely in waves, validated in report-only first, with break-glass and
rollback so there are no lock-outs.

> Some controls in the baseline require Microsoft Entra ID P2 (sign-in and user risk conditions) or
> Intune device compliance. Where a policy depends on a specific license or product this package flags
> it — *verify current availability in your tenant* and substitute an equivalent control if you are
> P1-only.
