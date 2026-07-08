# Executive Summary — Cloud-App DLP (Defender for Cloud Apps): Microsoft Purview

## The problem
Sensitive data does not stay inside Microsoft 365. It lives in the third-party SaaS apps the business runs
on — file-sharing (Box, Dropbox, Google Drive), CRM (Salesforce), ITSM (ServiceNow), HR, and more. Native
Microsoft Purview DLP protects Exchange, SharePoint, OneDrive, Teams, and endpoints — but not those
non-Microsoft clouds. That gap is a compliance exposure and a real data-loss risk: a customer list synced to
personal Dropbox, a contract shared "anyone with the link" from Box, or a bulk export pulled from Salesforce
onto an unmanaged laptop never touches a Microsoft workload, so native DLP never sees it.

## The solution
Extend DLP to third-party cloud apps with **Microsoft Defender for Cloud Apps (MDCA)** — Microsoft's
Cloud Access Security Broker — using two complementary controls, and nothing outside the Microsoft stack:

- **File policies** inspect files **at rest** in connected SaaS apps (via each app's API connector), match
  their content against Purview **sensitive information types** and **sensitivity labels**, and apply
  governance — alert, remove external sharing, apply a label, or quarantine.
- **Session policies** apply **real-time** controls as users work in cloud apps (via **Conditional Access
  App Control**) — monitor, block download/upload/copy/print, or protect on download.

The defining discipline mirrors the rest of the Purview estate: **every control is piloted in a safe test
mode first** — Conditional Access in **report-only**, session policies **Monitor only**, file policies
**alert-only** — proven on a **pilot ring**, tuned for a **low false-positive rate**, then enforced and
expanded. The result: cloud-app leaks are controlled without blocking the business.

## What it delivers
- The **two control planes wired** — target apps connected for at-rest file governance, and onboarded to
  Conditional Access App Control for real-time session control.
- **File policies and session policies** that reuse your existing Purview SITs/labels, each proven in test
  mode, tuned, and enforced through governance actions or real-time block/protect.
- A **measured false-positive rate** kept at/under an agreed threshold — the difference between a control
  people trust and one they switch off.
- An **incident/alert triage workflow** so every match is acted on, surfaced in the Microsoft Defender portal
  with optional SIEM/Sentinel forwarding.
- **Five PowerShell tools** (posture discovery, two-plane readiness checker, policy config helper, match/
  false-positive report, session-scope helper) — read-only or `-WhatIf` by default, no credentials in code.

## Business outcomes
- **The SaaS blind spot closed** — sensitive data is governed where it actually accumulates and leaks, not
  only inside Microsoft 365.
- **Minimal disruption** — test-mode-first plus tuning means the control catches leaks without a wave of
  false positives, and any session control reverts to report-only instantly if needed.
- **Operable and auditable** — matches raise alerts that are triaged to disposition, with evidence retained.
- **Self-guided at a fraction of consulting cost** — the same method a specialist would use, documented and
  tooled to run in-house.

## Boundaries (so scope is clear)
Cloud-app DLP is licensing-/plan-dependent — **MDCA, content inspection, and Conditional Access App Control
require the appropriate licensing** (verify your tenant), file policies require a **connected app**, and
session policies require **CA App Control routing** (with app/activity coverage limits). This solution
provides the **technical configuration and the evidence**; *which* apps and data categories are in scope,
*which* classifiers legally apply, the **governance/session action per category**, and the **acceptable
false-positive threshold** are **compliance, privacy, and legal determinations**, captured alongside the
delivered evidence.
