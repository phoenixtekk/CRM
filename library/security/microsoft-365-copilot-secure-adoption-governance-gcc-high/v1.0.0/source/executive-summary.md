# Executive Summary — Microsoft 365 Copilot Secure Adoption & Governance (Government / GCC High)

## The situation

Microsoft 365 Copilot is now **generally available in GCC High** (GA December 2025, after GCC and
DoD). Government organizations can adopt it today — but on a tenant that handles **Controlled
Unclassified Information (CUI)**, adoption without governance is a risk, not a win. Copilot reasons
over **everything a user can already open**. If SharePoint and OneDrive permissions are loose,
Copilot becomes the fastest path yet to surface content a user could technically reach but was never
meant to see. In a CUI environment, that is a spillage exposure.

## What this solution delivers

A **self-guided, tested** program to adopt Copilot **securely** on GCC High, authored specifically
for the **US sovereign cloud** — not Commercial steps with a different sign-in. It covers:

- **Assess** oversharing and classification posture **before** any user is licensed.
- **Configure** the guardrails — **sensitivity labels**, **DLP**, and **Restricted SharePoint
  Search** — using the correct **`*.us` GCC High portals** (`compliance.microsoft.us`,
  `portal.office365.us`, `entra.microsoft.us`, and others).
- **Pilot** with a named security group, **Validate** with pass/fail gates, and **Expand** in
  controlled waves.
- **Five PowerShell scripts** (Discovery, Validation, Report, Remediation, Set-ScopeTargeting) that
  connect to **US Gov Microsoft Graph** (`-Environment USGov`) — read-only by default, with
  remediation gated behind `-WhatIf`.

## Why the Government edition is different (and necessary)

GCC High is **not** the Commercial portal with a different login. This edition explicitly handles:

- **Different portals** — every admin surface is a `*.us` sovereign URL; Commercial URLs fail or sign
  you into the wrong tenant.
- **US Gov Graph** — scripts use `-Environment USGov`; Commercial Graph will not resolve the tenant.
- **Web grounding OFF by default** — Copilot answers from tenant content only unless you explicitly
  enable and accept web grounding; plan for a knowledge cutoff.
- **Feature parity lag** — Teams-meeting Copilot, several Copilot Studio/agent surfaces, and Wave 2
  features are limited, staged, or not yet available; the solution flags each with **verify for GCC
  High** rather than assuming.
- **Stricter compliance framing** — FedRAMP High, DFARS, ITAR/EAR, CMMC — which is exactly why the
  pilot gate and validation evidence are mandatory.

Every parity claim is **cited** to Microsoft documentation (see the *GCC High parity notes*).

## The bottom line

**Microsoft 365 Copilot adopted correctly on GCC High** — right portals, right endpoints, oversharing
remediated, labels and DLP enforced, parity gaps handled — and **proven on a pilot before you scale.**
Self-guided, tested, at a fraction of consulting cost.
