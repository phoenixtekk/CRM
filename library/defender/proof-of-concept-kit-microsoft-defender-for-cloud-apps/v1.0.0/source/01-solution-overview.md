# 1. Solution Overview — Proof-of-Concept Kit: Microsoft Defender for Cloud Apps

## What Microsoft Defender for Cloud Apps is
Microsoft Defender for Cloud Apps (MDCA) is Microsoft's **cloud access security broker (CASB)**, managed from the unified Defender portal at `security.microsoft.com`. It gives visibility and control over SaaS usage. Its headline capabilities are:

- **Cloud Discovery (Shadow IT)** — discovers the cloud apps in use from firewall/proxy logs or the Defender for Endpoint integration, and scores their risk.
- **App connectors** — API connections to sanctioned SaaS (Microsoft 365, and third-party apps) for deep activity visibility and governance.
- **Policies** — activity policies, anomaly-detection policies, file/DLP policies, and OAuth-app policies that raise alerts and (optionally) govern.
- **Session controls (Conditional Access App Control)** — real-time, in-session controls (e.g. block download) for sanctioned apps. *Session control requires the appropriate plan and Entra Conditional Access — verify current availability in your tenant.*
- **Activity log & advanced hunting** over `CloudAppEvents` for investigation.

## What a Proof-of-Concept Kit is
A PoC Kit is a **customer-runnable evaluation**, not a production rollout and not a sales demo. Its job is to answer one question — *does MDCA actually give us visibility and control over cloud-app usage?* — with evidence, safely, in your own tenant. It does that by:

1. **Enabling** MDCA discovery and an **audit-mode** activity policy scoped to a small group of **pilot users** only.
2. **Generating benign test signal** — Microsoft's **sample Cloud Discovery log** (a documented, safe upload that produces a Shadow IT report) and benign, **policy-matching activity** performed by a test account (e.g. a benign download or an administrative action that the audit policy watches for). **No real data exfiltration, malicious app, or attack is ever used.**
3. **Demonstrating** that the signal produces the expected outcomes — a discovery report, a policy match, an anomaly/alert, and activity-log visibility.
4. **Scoring** what you observed against your evaluation criteria.
5. **Tearing down** — removing the policy and discovery data and rolling the scope back.

## Why this matters
Shadow IT and risky SaaS usage are invisible until something goes wrong, and a vendor deck can't show you what MDCA surfaces about *your* tenant's app usage. A scoped, **monitor-first** PoC replaces "trust the deck" with "watch it discover and flag." Because everything runs in **audit mode for pilot users only**, nothing is blocked and no production user is affected — you get proof without imposing controls before you've seen the value.

## How it works
1. **Assess** readiness with `POCMDCA-Enable.ps1 -WhatIf` — MDCA plan, admin roles, the discovery source (MDE integration or a sample log), and a defined pilot user group.
2. **Configure & enable** — turn on Cloud Discovery, and create the audit-mode activity policy `MDCA PoC Activity Policy – Pilot Users – Audit` scoped **only** to `MDCA PoC – Pilot Users – Pilot`. Optionally connect one sanctioned app in monitor mode.
3. **Generate benign signal** with `POCMDCA-TestSignal.ps1` — upload the Microsoft **sample discovery log** and perform benign, policy-matching activity as a test account.
4. **Validate & demonstrate** with `POCMDCA-Validate.ps1` — confirm the discovery report populated, the audit policy matched, an alert surfaced, and events appear in `CloudAppEvents`.
5. **Score** with `POCMDCA-Scorecard.ps1` against your criteria.
6. **Tear down** with `POCMDCA-Teardown.ps1 -WhatIf` first, then for real — remove the policy, delete the discovery report/connector, resolve test alerts.

## What you can control
- **Pilot users** — exactly which users the policy watches; no production user is affected.
- **Which capabilities to prove** — Cloud Discovery, activity policy, anomaly detection, activity-log visibility.
- **Enforcement posture** — **audit/monitor only** during the PoC; no blocking or session control.
- **Scorecard criteria** — the pass/fail bar you evaluate against.
- **Teardown** — full, reversible removal.

## Limitations (be honest with buyers)
- MDCA and several detections/session controls are **license-gated**. *Verify current plan availability in your tenant.*
- **Cloud Discovery** depends on a log source — the MDE integration or an uploaded log (the PoC uses Microsoft's **sample log** for a clean, benign demonstration).
- **Session controls (Conditional Access App Control)** require Entra Conditional Access and the appropriate plan — the PoC keeps enforcement off and proves visibility/policy, noting session control as a verify-and-optional demo.
- Test signal is **benign and simulated only** — a sample log and benign policy-matching activity. This proves the visibility/policy pipeline, not resilience to a real exfiltration.
- This is a **PoC**, not a production rollout — it stays scoped and in audit mode, and is designed to be rolled back. Org-wide governance is a separate solution.
- MDCA improves SaaS visibility and control; it does not replace identity hardening, DLP strategy, or the security team's governance decisions.

## Connections and authentication used
- The **unified Defender portal** (`security.microsoft.com` → **Cloud apps**) for discovery, connectors, policies, the activity log, and alerts.
- **Microsoft Graph Security** and the advanced-hunting API (`CloudAppEvents`, `AlertInfo`) for read-only validation and scoring.
- The **Defender for Endpoint → Cloud Apps discovery integration** (optional) or an uploaded Cloud Discovery log as the discovery source.
- Least-privilege roles: **Security Administrator** for configuration, **Security Reader** for read-only work, and **Global Administrator** only for one-time first-service activation.

## The standard deployment model
> **Assess readiness → configure/enable discovery + an audit-mode policy for a pilot user group → generate benign test signal → validate the detections and score → expand or tear down.** Repeatable pattern: **Assess → Configure → Pilot → Validate → Expand**, run here as a safe, reversible, monitor-first PoC.
