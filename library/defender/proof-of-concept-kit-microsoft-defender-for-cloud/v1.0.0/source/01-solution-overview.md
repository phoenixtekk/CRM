# 1. Solution Overview — Proof-of-Concept Kit: Microsoft Defender for Cloud

## What Microsoft Defender for Cloud is
Microsoft Defender for Cloud is Microsoft's **cloud security posture management (CSPM)** and **cloud workload protection platform (CWPP)** for Azure, AWS, GCP, and hybrid resources. It is managed from the Azure portal (`portal.azure.com` → **Microsoft Defender for Cloud`) and surfaces alerts into the unified Defender portal at `security.microsoft.com`. Its headline capabilities are:

- **Secure Score & recommendations (CSPM)** — continuous assessment of resource configuration against security best practice, with a single posture score to trend.
- **Regulatory compliance** — maps your posture to standards (e.g. Microsoft Cloud Security Benchmark and others). *Specific standards/controls may be plan-gated — verify current availability.*
- **Defender workload plans (CWPP)** — threat protection for specific resource types (Defender for Servers, Storage, SQL, Containers/AKS, Key Vault, App Service, and more). *Each plan is separately priced — verify current pricing.*
- **Security alerts** — runtime threat detections for the enabled workloads, including MDE-backed detection on servers.
- **Advanced hunting / continuous export** to a Log Analytics workspace or Sentinel.

## What a Proof-of-Concept Kit is
A PoC Kit is a **customer-runnable evaluation**, not a production rollout and not a sales demo. Its job is to answer one question — *does Defender for Cloud actually surface our cloud misconfigurations and threats?* — with evidence, safely, in your own environment. It does that by:

1. **Enabling** Defender for Cloud on a single **pilot subscription** (or resource group) — CSPM plus one workload plan.
2. **Generating benign test signal** — Defender for Cloud's built-in **sample security alerts**, a deliberately-misconfigured **benign test resource** (e.g. a storage account with public access) that produces a posture recommendation, and the **EICAR** test file on a pilot VM to raise a Defender-for-Servers alert. **No real attack, exploit, or malware is ever used.**
3. **Demonstrating** that the signal produces the expected outcomes — a recommendation and Secure Score change, a security alert, and regulatory-compliance visibility.
4. **Scoring** what you observed against your evaluation criteria.
5. **Tearing down** — deleting the test resource, disabling the Defender plan, and resolving the sample alerts.

## Why this matters
Cloud misconfigurations are the leading cause of cloud breaches, and a vendor deck can't show you what Defender for Cloud surfaces about *your* subscription. A scoped PoC replaces "trust the deck" with "watch it flag the misconfig and the threat." Because it runs on **one pilot subscription** with a **benign test resource** and is **disabled at teardown**, you get proof without a broad rollout or an open-ended bill.

## How it works
1. **Assess** readiness with `POCMDC-Enable.ps1 -WhatIf` — Azure roles, the pilot subscription, and current Defender-for-Cloud state.
2. **Configure & enable** — turn on **CSPM** and one **Defender workload plan** on the pilot subscription, and create the pilot resource group `MDC PoC – Pilot RG – Pilot`.
3. **Generate benign signal** with `POCMDC-TestSignal.ps1` — trigger sample security alerts, deploy the benign misconfigured test resource, and (optionally) drop EICAR on a pilot VM.
4. **Validate & demonstrate** with `POCMDC-Validate.ps1` — confirm the recommendation, Secure Score, security alerts, and regulatory-compliance data populated.
5. **Score** with `POCMDC-Scorecard.ps1` against your criteria.
6. **Tear down** with `POCMDC-Teardown.ps1 -WhatIf` first, then for real — delete the test resource, disable the Defender plan, resolve sample alerts.

## What you can control
- **Pilot subscription/RG** — exactly one subscription (or resource group); no other subscription is touched.
- **Which capabilities to prove** — Secure Score/recommendations, security alerts, regulatory compliance, workload protection.
- **Which Defender plan** — enable one workload plan for the PoC (kept short to control cost).
- **Scorecard criteria** — the pass/fail bar you evaluate against.
- **Teardown** — full, reversible removal, including disabling the plan to stop billing.

## Limitations (be honest with buyers)
- **Defender workload plans are billed while enabled** — the PoC keeps the window short and disables at teardown. *Verify current pricing before enabling.*
- Some standards/controls and CSPM features are **plan-gated** (e.g. Defender CSPM vs foundational CSPM). *Verify current availability in your tenant.*
- Test signal is **benign and simulated only** — sample alerts, a benign misconfiguration, and EICAR. This proves the posture/detection pipeline, not resilience to a real cloud attack.
- **Secure Score and recommendations populate over time** — allow warm-up after enabling before judging.
- This is a **PoC**, not a production rollout — it stays on one subscription and is designed to be disabled. Multi-cloud onboarding is a separate solution.
- Defender for Cloud improves posture and detection; it does not replace remediation, IaC hardening, or the security team's decisions.

## Connections and authentication used
- The **Azure portal** (`portal.azure.com` → **Microsoft Defender for Cloud**) for plans, Secure Score, recommendations, alerts, and regulatory compliance.
- **Az PowerShell** (`Az.Security`, `Az.Resources`, `Az.Storage`) for read-only discovery, enable/teardown, and validation.
- **Microsoft Graph Security** / the unified Defender portal where Defender-for-Cloud alerts correlate into incidents.
- Least-privilege roles: **Security Admin** / **Contributor** (scoped to the pilot subscription) for enable/teardown, **Security Reader** for read-only work, and **Owner** only where a plan requires it.

## The standard deployment model
> **Assess readiness → configure/enable CSPM + one workload plan on a pilot subscription → generate benign posture + threat signal → validate the detections and score → expand or tear down.** Repeatable pattern: **Assess → Configure → Pilot → Validate → Expand**, run here as a safe, reversible, cost-bounded PoC.
