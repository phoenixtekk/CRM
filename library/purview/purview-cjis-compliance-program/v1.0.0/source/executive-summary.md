# Executive Summary — Microsoft Purview CJIS Compliance Program

## The problem
Agencies that handle **Criminal Justice Information (CJI)** must satisfy the **FBI CJIS Security Policy**
and **prove** it at a formal audit — or risk losing access to CJI systems. Microsoft Purview provides
much of the technical machinery (classification, encryption, DLP, retention, audit logging), but out of
the box none of it is **mapped to CJIS**, **configured against CJI**, or assembled into **audit
evidence**. Left as generic tenant settings, Purview does not answer the auditor's question — *show me
how CJI is protected, monitored, and retained* — and the agency scrambles to reconstruct evidence each
cycle.

## The solution
A complete, self-guided **CJIS-aligned Purview program**: a **control map** from the relevant CJIS
Security Policy areas to concrete Purview capabilities; the **configured controls** — a CJI sensitivity
label with encryption, a CJI-exfiltration DLP policy, CJI retention, and audit logging — **piloted in
simulation/test first**; and a repeatable **formal-audit evidence package** the agency's CJIS auditor and
CSA can review. Five safe-by-default PowerShell tools (read-only, or `-WhatIf`/`-Commit` with a separate
`-Enforce -Commit` for the only high-impact changes) do the assessment, scope/health checks,
configuration, validation, and evidence generation — using only Security & Compliance PowerShell,
Exchange Online, and Microsoft Graph.

## What you get
- **A CJIS-to-Purview control map** — each in-scope policy area (auditing & accountability, access
  control / information flow, information protection, media/records, personnel) mapped to the Purview
  object that implements it, with owners and status.
- **Configured CJI controls** — a `CJI – Protected – Label` with encryption, a `CJI Protection –
  Exfiltration – Policy` DLP policy (piloted in **test mode**), `CJI Records – Retention – Policy`, and
  **unified audit logging** with an audit-retention target.
- **A pilot-first, reversible rollout** — every high-impact control validated on a bounded CJI scope and
  reviewed with the security officer before enforcement.
- **A repeatable audit-evidence package** — per control, the implementing object, its state, and the
  audit reference, produced the same way every cycle for the formal audit.
- **Separation of duties by design** — the CJI configurer, audit-evidence reader, and any insider-risk
  reviewer are distinct roles; insider-risk indicators are aggregate/de-identified.

## Approach
Delivery follows a disciplined, reversible model — **Assess → Design → Configure → Pilot (simulate/test)
→ Validate → Expand** — with pass/fail gates and documented rollback, and the DLP/label/retention
controls piloted in simulation/test **before** any enforcement.

## Boundaries
CJIS is generally satisfied only in a **CJIS-authorized cloud** — **Microsoft 365 GCC High** or **Azure
Government** — under a signed Microsoft **CJIS Security Addendum**; **commercial M365 is generally not
CJIS-authorized.** Capabilities are **licensing-/cloud-dependent and evolving** — availability is cited
or flagged **"verify your environment/licensing/tenant,"** never assumed. Whether the configured controls
**satisfy** CJIS, whether the **environment** is authorized, the **records-retention schedule**, and any
**regulatory/legal determination** are **deferred to your CSA, CJIS auditor, records, and legal
functions** — the solution provides the technical method and the evidence, not the judgement.

## The bottom line
Meet CJIS with a Purview-backed program — control mapping, configured controls, and audit evidence —
**configured, piloted, validated, and defensible** in Microsoft Purview, so the next formal audit finds
the controls in place and the evidence already assembled.
