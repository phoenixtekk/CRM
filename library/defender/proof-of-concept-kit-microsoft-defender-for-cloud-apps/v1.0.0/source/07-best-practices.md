# 7. Best Practices — Proof-of-Concept Kit: Microsoft Defender for Cloud Apps

Field-proven guidance for running a clean, safe, conclusive MDCA proof of concept.

## Keep the PoC scoped, monitor-first, and reversible
- Scope the activity policy to **pilot users only** (`MDCA PoC – Pilot Users – Pilot`) and keep it in **audit mode with no governance action**. The value is that you prove visibility without blocking anyone.
- Preview every change with `-WhatIf` first (`POCMDCA-Enable.ps1`, `POCMDCA-Teardown.ps1`).

## Benign signal only — never real exfiltration
- Use Microsoft's **sample Cloud Discovery log** and **benign policy-matching activity** exclusively. They exercise discovery and policy without moving real data.
- **Never** exfiltrate real data, connect a malicious app, or grant a risky OAuth consent to "test." A PoC proves the product surfaces the signal; it is not a data-loss exercise.

## Use the sample discovery log for a clean demo
- The **sample log** makes the PoC self-contained: it produces a realistic Shadow IT report without needing a real firewall/proxy feed, so you can demonstrate discovery immediately and tear it down cleanly.

## Keep enforcement off
- Do **not** turn on blocking or **session controls (Conditional Access App Control)** during the PoC. Session control changes the user experience in real time and requires Conditional Access wiring — prove visibility and policy first; enforcement is a production decision for the security/compliance team.

## Set the bar before you run
- Agree the **evaluation criteria** in writing first (Requirement 2.6). Feed them into `POCMDCA-Scorecard.ps1` so the verdict is objective.

## Allow warm-up before judging
- The discovery report, activity log, `CloudAppEvents`, and anomaly detections populate over **minutes to hours**. Give the pipeline time before scoring a "fail," and use `POCMDCA-Validate.ps1` to check when signal has arrived.

## Tear down completely
- Delete the policy, the discovery report, and the optional connector; resolve the `MDCA-PoC-TESTSIGNAL` alerts. Then confirm with `POCMDCA-Validate.ps1`. Keep only the scorecard.

## Keep licensing and preview facts current
- MDCA detections and session controls are license-gated, and availability changes. **Verify current plan availability in your tenant** before assuming a capability — and if session control is unlicensed, record it as "not licensed," not "failed."

## Where to go next
Once the PoC proves MDCA, natural next steps in the catalogue:
- The **Cloud App DLP / session-control governance** solution to move from audit to real governance org-wide.
- The **Defender XDR Deployment & Unified Onboarding** solution to correlate MDCA with Endpoint, Identity, and Office.
- The **Entra ID Conditional Access** solution to wire up Conditional Access App Control for session controls.
- The **Sentinel SOC/XDR integration** solution to stream MDCA into a SIEM for long-term hunting.
