# 1. Solution Overview — Proof-of-Concept Kit: Microsoft Defender for Office 365

## What Microsoft Defender for Office 365 is
Microsoft Defender for Office 365 (MDO) is Microsoft's **email and collaboration security** platform, layered on top of Exchange Online Protection (EOP) and managed from the unified Defender portal at `security.microsoft.com`. Its headline capabilities are:

- **Safe Links** — time-of-click URL protection that rewrites and detonates links in mail and (where licensed) Teams/Office.
- **Safe Attachments** — sandbox detonation of attachments before delivery.
- **Anti-phishing** — impersonation and spoof protection (mailbox intelligence, user/domain impersonation).
- **Anti-spam / anti-malware** (EOP baseline) and **zero-hour auto purge (ZAP)** that retroactively removes mail found malicious after delivery.
- **Threat Explorer** and **advanced hunting** for investigation, plus **automated investigation & response (AIR)**. *Threat Explorer, Attack Simulation Training, and AIR require Defender for Office 365 **P2** — verify current availability in your tenant.*

## What a Proof-of-Concept Kit is
A PoC Kit is a **customer-runnable evaluation**, not a production rollout and not a sales demo. Its job is to answer one question — *does MDO actually catch phishing and malicious mail for our users?* — with evidence, safely, in your own tenant. It does that by:

1. **Enabling** MDO protection (a preset security policy) scoped to a small group of **pilot users** only.
2. **Generating benign test signal** — Microsoft's **Attack Simulation Training** (a safe, built-in phishing simulator), the standard **GTUBE** spam-test string, the **EICAR** attachment test file, and a benign **Safe Links** test URL. These are documented, harmless triggers. **No real phishing, malware, or malicious payload is ever used.**
3. **Demonstrating** that the signal produces the expected outcomes — Safe Links rewriting, Safe Attachments detonation, spam/phish handling, ZAP, and visibility in Threat Explorer.
4. **Scoring** what you observed against your evaluation criteria.
5. **Tearing down** — rolling the pilot scope back and clearing test artefacts.

## Why this matters
Email remains the number-one intrusion vector, and a vendor deck can't show you how MDO behaves on *your* mail flow, with *your* users and *your* policy posture. A scoped PoC replaces "trust the deck" with "watch it catch the simulation." Because it is **pilot-scoped and reversible**, the wider organisation's mail flow is untouched, and you get proof without committing to an org-wide policy change before you've seen the value.

## How it works
1. **Assess** readiness with `POCMDO-Enable.ps1 -WhatIf` — MDO plan (P1/P2), admin roles, Exchange Online mail flow, and a defined pilot user group.
2. **Configure & enable** the **Standard preset security policy** scoped **only** to `MDO PoC – Pilot Users – Pilot` (Safe Links, Safe Attachments, anti-phishing).
3. **Generate benign signal** with `POCMDO-TestSignal.ps1` — launch a Microsoft Attack Simulation phishing campaign to the pilot users and send GTUBE / EICAR / Safe Links test messages.
4. **Validate & demonstrate** with `POCMDO-Validate.ps1` — confirm Safe Links rewrote, Safe Attachments detonated, ZAP/quarantine acted, and the events appear in `EmailEvents`, `UrlClickEvents`, and Threat Explorer.
5. **Score** with `POCMDO-Scorecard.ps1` against your criteria.
6. **Tear down** with `POCMDO-Teardown.ps1 -WhatIf` first, then for real — remove the pilot scope, end the simulation, purge test messages from quarantine.

## What you can control
- **Pilot users** — exactly which mailboxes the preset policy protects; the rest of the org is untouched.
- **Which capabilities to prove** — Safe Links, Safe Attachments, anti-phish, ZAP, Threat Explorer, AIR.
- **Simulation content** — Microsoft's built-in benign phishing templates only.
- **Scorecard criteria** — the pass/fail bar you evaluate against.
- **Teardown** — full, reversible scope rollback.

## Limitations (be honest with buyers)
- MDO and several features are **license-gated** — Safe Links/Safe Attachments/anti-phish need **P1**; **Threat Explorer, Attack Simulation Training, and AIR need P2**. *Verify current plan availability in your tenant.*
- Test signal is **benign and simulated only** — Attack Simulation Training, GTUBE, EICAR, a benign test URL. This proves the protection pipeline, not resilience to a real targeted campaign.
- **ZAP and detonation** act after delivery / at click time — allow a short delay before judging.
- This is a **PoC**, not a production rollout — it stays scoped to pilot users and is designed to be rolled back. Org-wide hardening is a separate solution.
- MDO improves email security; it does not replace user training, identity hardening, or the SOC's incident-response decisions.

## Connections and authentication used
- The **unified Defender portal** (`security.microsoft.com`) for preset policies, Threat Explorer, Attack Simulation, quarantine, and Secure Score.
- **Exchange Online Management** PowerShell for preset-policy scoping and quarantine operations.
- **Microsoft Graph Security** and the advanced-hunting API (`EmailEvents`, `UrlClickEvents`, `EmailAttachmentInfo`) for read-only validation and scoring.
- Least-privilege roles: **Security Administrator** (and **Exchange Administrator** for policy scope), **Security Reader** for read-only work, **Attack Simulation Administrator** for the simulation, and **Global Administrator** only for one-time first-service activation.

## The standard deployment model
> **Assess readiness → configure/scope MDO to a pilot user group → generate benign test signal → validate the detections and score → expand or tear down.** Repeatable pattern: **Assess → Configure → Pilot → Validate → Expand**, run here as a safe, reversible PoC with remediation kept reviewable.
