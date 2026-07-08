# Executive Summary — Office & PDF Rights Protection (RMS/IRM), Microsoft Purview

## The problem
Most data controls stop at the perimeter. DLP inspects at egress and conditional access gates the app,
but the moment a sensitive document is forwarded, copied to a USB stick, or exported to PDF and shared,
it is a plain file that anyone can open. Perimeter-only protection leaves no control that travels **with
the content** — and PDF exports, where so much sensitive data ends up, are frequently the widest gap.
Left unaddressed, this is a compliance gap and a data-risk exposure: a single over-shared file is
readable by anyone who receives it.

## The solution
A complete, self-guided configuration of **label-based encryption and usage rights** for Office
documents and PDFs — the capability historically called Azure Rights Management (RMS) / Information
Rights Management (IRM), now delivered through Microsoft Purview sensitivity labels. Protection is
embedded in the file: the content is encrypted and carries an enforced policy for **who can open it and
what they can do** (view, edit, copy, print, forward). It configures a small set of **protection
labels** — a template-based internal grant, a user-driven Do-Not-Forward / Encrypt-Only label, and a
named-recipient view-only label — with offline-access and content-expiry, covering **Office and PDF**,
piloted on a ring and validated before it touches everyone. It uses only the Microsoft Purview portal,
Security & Compliance PowerShell, and the AIPService module — no third-party tooling.

## How it works
The engagement follows one disciplined model: **Assess → Design → Configure → Pilot → Validate →
Expand.** Assess whether the Rights Management service is activated and the current label-encryption
posture; confirm the **super-user recovery** path so encrypted content is never unrecoverable; design
the per-label usage rights with the accountable owner; configure encryption on the labels and publish
them to a **pilot ring only**; validate that the right people open Office and PDF files with the right
rights, the wrong people are denied, and recovery works; then expand to the broad policy. Because label
encryption has **no simulation mode**, the pilot ring is the safety mechanism — every write is previewed
with `-WhatIf` first. Five PowerShell tools — read-only or `-WhatIf` by default — automate discovery,
label-protection configuration, effective-settings validation, posture reporting, and a readiness/health
check.

## What is delivered
- Six implementation documents (Overview, Requirements, Implementation, Testing, Best Practices, Troubleshooting) plus this summary.
- Five PowerShell tools: posture assessment, a label-protection configuration/remediation helper (template rights, user-defined DNF/Encrypt-Only, offline/expiry, publish, remove-protection rollback), effective-settings validation, posture-matrix reporting, and a readiness/health helper.
- A named, gated, reversible rollout with a confirmed recovery path and explicit pass/fail criteria at every step.

## Business outcome
Persistent protection that **survives sharing** — sensitive Office documents and PDF exports stay
encrypted and rights-controlled wherever they travel, with a confirmed recovery path for records and
legal. The protection is configured, piloted, validated, and defensible — at a fraction of the cost of
a bespoke consulting engagement.

## Important boundaries
*Who* may access what, the content-expiry rules, and how encrypted content is preserved and produced for
legal-hold and eDiscovery are **determinations owned by your compliance, security, records, and legal
functions** — this solution provides the technical configuration method, the super-user recovery method,
and evidence, not the determination. The label taxonomy is assumed to exist; Double Key Encryption and
HYOK are separate builds. Label encryption, protected-PDF handling, and external sharing are
**licensing-/tenant-/reader-dependent** and the Purview portal is evolving — availability, portal paths,
and cmdlet/advanced-setting keys are flagged "verify your licensing/tenant," never assumed or invented.
