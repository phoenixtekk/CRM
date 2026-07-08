# Executive Summary — Purview Message Encryption (OME) in Microsoft Purview

## The problem

Email is still the main way sensitive information leaves an organization — contracts, payroll, health
and financial details, account numbers — and by default it leaves **unprotected**. Once a message
reaches an external recipient it can be forwarded, printed, copied, and stored anywhere, with no
control and no record. That is a compliance gap and a data-risk exposure at the same time: the
information is out, and there is no way to restrict or account for what happens to it.

## The solution

This solution implements **Purview Message Encryption** — the current **Office 365 Message Encryption
(OME)**, built on **Azure Rights Management** — so that outbound email can be **encrypted, branded, and
usage-restricted**, to any recipient, on any device:

- **Encrypt** — the message is protected in transit and at rest; the recipient can read and reply.
- **Do Not Forward** — the message is encrypted **and** the recipient **cannot forward, print, or
  copy** it, for the most sensitive sends.
- **Your branding** — the encryption experience carries **your** logo, colour, and text, so recipients
  trust it rather than mistaking it for phishing.
- **Automatic, rule-driven** — mail flow rules apply the right protection when a message matches a
  condition (a keyword, a sensitivity label, an external recipient), so protection doesn't depend on a
  user remembering.

## How it works

We follow a repeatable model — **Assess → Design → Configure → Pilot → Validate → Expand** — that
enables the **encryption foundation first** (Azure RMS, proven healthy), sets the **branding**, then
builds the mail flow rules in **Audit mode scoped to a pilot group**, where they **match and log but do
not yet encrypt**. Only after sanctioned test sends prove the experience end to end — encrypted,
branded, readable by internal and external recipients, and (for Do Not Forward) genuinely
non-forwardable — do the rules move to **Enforce**, and scope widens deliberately.

The solution ships as **self-guided documentation plus five PowerShell tools** (Exchange Online /
Security & Compliance PowerShell / Graph) that assess readiness and RMS health, configure branding and
the rules (Audit-first), validate the wiring, and produce a leadership rollup — all **read-only or
`-WhatIf`/Audit-mode by default**, with **no credentials in code**.

## Why it matters

- **Sensitive email is protected** — encrypted and, where needed, non-forwardable, instead of leaving
  in the clear.
- **Recipients trust it** — a branded experience that reaches anyone, inside or outside the
  organization.
- **Automatic and defensible** — rule-driven encryption with an evidence trail (message trace),
  piloted before it enforces, so nothing breaks silently.
- **A fraction of consulting cost** — the same disciplined method a specialist would use, delivered as
  a repeatable, tested runbook.

## Important boundaries

OME is **licensing-dependent**: **Basic OME** (via Azure Information Protection, included in common
E3/E5 plans) provides encryption, the two templates, and a **single default** branding; **custom
branding templates, message revocation, and expiration** require **Advanced Message Encryption**
(Microsoft 365 E5 / E5 Compliance) — capability availability and exact portal paths/parameters should
be **verified against your licensing and tenant**. Deciding **what is sensitive** — which mail must be
encrypted and what triggers Do Not Forward — is a **compliance, privacy, and legal determination** for
your organization; this solution provides the technical method, the pilot discipline, and the evidence,
not the determination.
