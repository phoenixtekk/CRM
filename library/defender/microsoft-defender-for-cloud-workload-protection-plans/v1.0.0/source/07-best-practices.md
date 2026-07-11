# 7. Best Practices — Microsoft Defender for Cloud: Workload Protection Plans (CWPP)

Field-proven guidance for keeping the workload protection deployment protective, tuned, and cost-aware.

## Enable on a pilot subscription first
- Turn the plans on for `MDC Workload Plans – Pilot Subscription – Pilot` first, validate coverage and alerts, then expand subscription-by-subscription (or via a management-group policy) in waves. Enabling everywhere at once is a cost and noise shock.

## Treat cost as a first-class decision
- Workload plans are **billed per protected resource**. Get cost approval for the pilot, track protected-resource counts with `MDCWP-Report.ps1 -Section Cost`, and expand deliberately by resource value — not blanket-on. *Verify current pricing and plan tiers.*

## Pair CWPP with CSPM, don't substitute
- Workload protection **detects** attacks; CSPM **reduces** the attack surface. Keep both — cross-reference the catalog's **Defender for Cloud — CSPM & Secure Score** solution. Fixing posture lowers the alerts CWPP has to raise.

## Provision the Servers agents properly
- Defender for Servers detection is only as good as its **agents**. Confirm the MDE integration and monitoring agent auto-provision and stay healthy, and connect non-Azure servers via **Azure Arc** so multicloud/on-prem workloads are covered too.

## Tune alerts so the SOC trusts them
- Untuned CWPP alerts become noise. Create **scoped, documented** suppression rules (`MDC Alert Suppression – Benign FP – Prod`) only for genuinely benign patterns, set sensible severities, and route high-severity alerts to the SOC. Review the tuning on a cadence.

## Keep the response workflow notify-first
- Start `MDC Workload Response – Tenant – Prod` as **notify / ticket-only**. Auto-remediation of a production workload is disruptive and belongs to the SOC's decision, made only after the alerts are trusted.

## Export for hunting and retention
- Send alerts/recommendations to `MDC Continuous Export – Workspace – Prod` (and the SIEM) so you can hunt across time and integrate with the SOC. Validate the export is flowing before relying on it.

## Defer the compliance and change decisions to the owners
- Which regulatory controls apply, production change approval, and incident-response runbooks are **the customer's compliance/operations/security determinations**. This solution delivers the technical CWPP enablement and tuning; the governance decisions stay with the owners.

## Where to go next
Once the workload plans are enabled and validated, natural next steps in the catalog:
- The **Defender for Cloud — CSPM & Secure Score** solution to strengthen the posture layer that feeds CWPP.
- The **Microsoft Defender XDR — Unified Onboarding** accelerator to correlate cloud workload alerts with Endpoint/Identity/Office/Cloud-Apps.
- The **SOC onboarding — Sentinel + Defender XDR** and **advanced KQL threat-hunting** solutions to hunt workload alerts in a SIEM.
- The **Onboarding Accelerator — Microsoft Defender for Endpoint** — MDE powers Defender for Servers detection.
