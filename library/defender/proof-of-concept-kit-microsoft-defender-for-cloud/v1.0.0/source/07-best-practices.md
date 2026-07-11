# 7. Best Practices — Proof-of-Concept Kit: Microsoft Defender for Cloud

Field-proven guidance for running a clean, safe, cost-bounded Defender-for-Cloud proof of concept.

## Keep the PoC scoped and reversible
- Enable Defender on **one pilot subscription** (or resource group) only. The value is that you can disable it cleanly with no impact to other subscriptions.
- Preview every change with `-WhatIf` first (`POCMDC-Enable.ps1`, `POCMDC-Teardown.ps1`).

## Mind the cost — disable at teardown
- **Defender workload plans are billed while enabled.** Keep the PoC window short, enable only **one** workload plan, and **disable it at teardown** (`POCMDC-Teardown.ps1`). Diarise the teardown so a plan is never left on by accident. **Verify current pricing before enabling.**

## Benign signal only — never real attacks
- Use **sample security alerts**, a **benign misconfigured test resource**, and **EICAR** exclusively. They exercise CSPM and CWPP without touching real workloads.
- **Never** attack a real resource, deploy real malware, or expose real data to "test." A benign test storage account with public access is enough to raise a recommendation; sample alerts are enough to prove the alert pipeline.

## Use a disposable test resource for CSPM
- Deploy `MDC PoC Test Resource – Pilot RG – Pilot` specifically for the PoC, holding **no real data**, and delete it at teardown. This gives a clean, attributable recommendation and leaves nothing behind.

## Set the bar before you run
- Agree the **evaluation criteria** in writing first (Requirement 2.6). Feed them into `POCMDC-Scorecard.ps1` so the verdict is objective.

## Allow warm-up before judging
- Secure Score, recommendations, and regulatory-compliance data populate over **minutes to hours** after enabling. Give the pipeline time before scoring a "fail," and use `POCMDC-Validate.ps1` to check when signal has arrived.

## Tear down completely and confirm
- Delete the test resource, disable the plan (confirm **Off** to stop billing), and resolve the `MDC-PoC-TESTSIGNAL` sample alerts. Then confirm with `POCMDC-Validate.ps1`. Keep only the scorecard.

## Defer the decisions to the owners
- Whether the PoC "passed," which recommendations are "must-fix," and regulatory-mapping determinations are **the customer's** security/compliance decisions. This kit delivers the technical proof, not the verdict.

## Where to go next
Once the PoC proves Defender for Cloud, natural next steps in the catalogue:
- The **Defender for Cloud — CSPM & Secure Score Remediation** solution to operationalise posture management across subscriptions.
- A **multi-subscription / multi-cloud (AWS/GCP) onboarding** engagement to extend coverage.
- The **Defender XDR Deployment & Unified Onboarding** solution to correlate Defender-for-Cloud alerts with Endpoint, Identity, Office, and Cloud Apps.
- The **Sentinel SOC/XDR integration** solution to stream Defender-for-Cloud into a SIEM for long-term hunting.
