# Executive Summary — Proof-of-Concept Kit: Microsoft Defender for Cloud

**White-label · Defender**

Deciding on Microsoft Defender for Cloud shouldn't rest on a slide deck. This Proof-of-Concept (PoC) Kit stands up a **scoped, safe** proof of concept in your own environment: it enables Defender for Cloud on a single **pilot subscription** (or resource group), generates **benign, simulated** test signal (Defender for Cloud's own **sample security alerts**, a deliberately-misconfigured **benign test resource** that produces a posture recommendation, and the **EICAR** test file on a pilot VM — never a real attack, exploit, or malware), demonstrates the headline **cloud security posture management (CSPM) & workload protection (CWPP)** capabilities on that signal, scores the result against your evaluation criteria, and then **cleanly tears the PoC back down**.

The kit is written for an administrator with no prior Defender experience. Everything is **pilot-scoped and reversible**: you enable Defender on one subscription, prove the value, capture a scorecard, and disable it — with no other subscription touched and no production cost surprises.

## What you get
- A plain-language **Solution Overview** of Defender for Cloud (CSPM + CWPP) and how a PoC proves it on real-but-safe signal.
- A **Requirements Guide** of the PoC-specific prerequisites (the category-wide ones live in `global-requirements-defender.md`).
- An **Implementation Guide** — exact, ordered steps to enable Defender on a pilot subscription, generate benign signal, demonstrate the detections, score, and tear down.
- Five **PowerShell scripts** (Az PowerShell / Az.Security + Microsoft Graph) with **KQL** queries: a `-WhatIf`-gated pilot enable, a **benign** test-signal helper, a demo/validate check, a criteria scorecard, and a `-WhatIf`-gated teardown.
- **Testing**, **Troubleshooting**, and **Best Practices** guides.

## What this delivers
A concrete, **in-environment proof** that Microsoft Defender for Cloud delivers CSPM & workload protection — a **Secure Score** and **recommendations** from a benign misconfiguration, a **security alert** from a sample alert and an EICAR trigger on a pilot VM, the **regulatory-compliance** dashboard populated, the events visible in the portal and hunting, and a **scorecard** mapping each observed capability to your pass/fail criteria — all torn down cleanly at the end.

## The standard deployment model
**Assess → Configure → Pilot → Validate → Expand** — here scoped as a PoC: assess readiness, enable Defender on a pilot subscription, generate benign signal, validate and score, then either expand or tear down.

## Boundary
This is an **evaluation kit**, not a production rollout. It proves Defender for Cloud on one subscription and then disables it. Multi-subscription/multi-cloud onboarding, CSPM remediation at scale, and long-term operations are separate adjacent solutions (see *Where to go next*). All test signal is **benign and simulated**. Enabling a Defender plan can incur **cost while active — verify current pricing and disable at teardown**. Remediation and regulatory determinations remain the customer's security/compliance team's.

## Effort
A competent administrator can complete the full PoC — enable, signal, validate, score, and teardown — in a short, focused engagement on one pilot subscription. Defender plans are billed while enabled, so keep the PoC short and disable at teardown. Every step is reversible.
